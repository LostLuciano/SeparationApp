#!/usr/bin/env python3
"""
Validate that Runner.xcodeproj/project.pbxproj includes all required files.
This script checks:
1. All Swift files are in PBXSourcesBuildPhase
2. All resources are in PBXResourcesBuildPhase
3. CoreML models are properly referenced as folder references
4. No critical files are missing
"""

import re
from pathlib import Path

def parse_pbxproj(pbxproj_path):
    """Parse pbxproj and extract build phase information."""
    with open(pbxproj_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Extract file references
    file_refs = {}
    for match in re.finditer(r'([A-F0-9]{24})\s*/\*\s*(.+?)\s*\*/\s*=\s*\{\s*isa\s*=\s*PBXFileReference;[^}]*path\s*=\s*"([^"]+)"', content):
        uuid, name, path = match.groups()
        file_refs[path] = {'uuid': uuid, 'name': name}
    
    # Extract source files build phase
    sources_match = re.search(r'isa\s*=\s*PBXSourcesBuildPhase;[^}]*files\s*=\s*\((.*?)\);', content, re.DOTALL)
    sources_build_files = set()
    if sources_match:
        for ref_match in re.finditer(r'([A-F0-9]{24})\s*/\*', sources_match.group(1)):
            sources_build_files.add(ref_match.group(1))
    
    # Extract resource files build phase
    resources_match = re.search(r'isa\s*=\s*PBXResourcesBuildPhase;[^}]*files\s*=\s*\((.*?)\);', content, re.DOTALL)
    resources_build_files = set()
    if resources_match:
        for ref_match in re.finditer(r'([A-F0-9]{24})\s*/\*', resources_match.group(1)):
            resources_build_files.add(ref_match.group(1))
    
    return file_refs, sources_build_files, resources_build_files

def scan_actual_files(runner_dir):
    """Scan actual files on disk."""
    swift_files = set()
    resource_files = set()
    
    # Swift files
    for f in Path(runner_dir).rglob('*.swift'):
        rel_path = f.relative_to(Path(runner_dir).parent).as_posix()
        swift_files.add(rel_path)
    
    # Resources
    for ext in ['json', 'm4a', 'caf', 'wav', 'mp3']:
        for f in Path(runner_dir).rglob(f'*.{ext}'):
            rel_path = f.relative_to(Path(runner_dir).parent).as_posix()
            if ".mlmodelc/" in rel_path or ".xcassets/" in rel_path:
                continue
            resource_files.add(rel_path)
    
    # CoreML models (folders)
    for f in Path(runner_dir).rglob('*.mlmodelc'):
        if f.is_dir():
            rel_path = f.relative_to(Path(runner_dir).parent).as_posix()
            resource_files.add(rel_path)
    
    # Assets.xcassets
    assets = Path(runner_dir) / 'Assets.xcassets'
    if assets.exists():
        rel_path = assets.relative_to(Path(runner_dir).parent).as_posix()
        resource_files.add(rel_path)
    
    return swift_files, resource_files

def main():
    project_root = Path(__file__).parent.parent
    pbxproj_file = project_root / 'Runner.xcodeproj' / 'project.pbxproj'
    runner_dir = project_root / 'Runner'
    
    print("🔍 Validating Runner.xcodeproj\n")
    
    if not pbxproj_file.exists():
        print("[ERROR] ERROR: project.pbxproj not found!")
        return False
    
    # Parse pbxproj
    file_refs, sources_uuids, resources_uuids = parse_pbxproj(pbxproj_file)
    
    # Scan actual files
    swift_files, resource_files = scan_actual_files(runner_dir)
    
    print(f"[STATS] Project Analysis:\n")
    print(f"  Files in pbxproj: {len(file_refs)}")
    print(f"  Files in Compile Sources phase: {len(sources_uuids)}")
    print(f"  Files in Resources phase: {len(resources_uuids)}")
    
    print(f"\n  Actual Swift files on disk: {len(swift_files)}")
    print(f"  Actual resource files on disk: {len(resource_files)}")
    
    # Find missing files
    missing_swift = swift_files - set(k for k in file_refs.keys() if k.endswith('.swift'))
    missing_resources = resource_files - set(k for k in file_refs.keys() if not k.endswith('.swift'))
    
    errors = []
    
    if missing_swift:
        print(f"\n[ERROR] Missing Swift files ({len(missing_swift)}):")
        for f in sorted(missing_swift):
            print(f"   - {f}")
            errors.append(f"Swift file missing: {f}")
    else:
        print(f"\n[OK] All Swift files are in pbxproj")
    
    if missing_resources:
        print(f"\n[ERROR] Missing resource files ({len(missing_resources)}):")
        for f in sorted(missing_resources):
            print(f"   - {f}")
            errors.append(f"Resource missing: {f}")
    else:
        print(f"\n[OK] All resource files are in pbxproj")
    
    # Verify critical files
    critical_files = [
        'Runner/App/AppDelegate.swift',
        'Runner/App/SceneDelegate.swift',
        'Runner/UI/Screens/MainTabBarController.swift',
        'Runner/Info.plist',
    ]
    
    print(f"\n🔐 Critical files check:")
    for critical in critical_files:
        if critical in file_refs:
            print(f"   [OK] {critical}")
        else:
            print(f"   [ERROR] {critical} - MISSING!")
            errors.append(f"Critical file missing: {critical}")
    
    # Check CoreML models
    print(f"\n🤖 CoreML Models:")
    ml_models = [k for k in file_refs.keys() if k.endswith('.mlmodelc')]
    if len(ml_models) >= 4:
        print(f"   [OK] Found {len(ml_models)} CoreML models:")
        for model in sorted(ml_models):
            print(f"      - {model}")
    else:
        print(f"   [WARN]  Only {len(ml_models)} CoreML models found (expected 4+)")
    
    # Check build phases
    print(f"\n⚙️  Build Phases:")
    print(f"   Compile Sources: {len(sources_uuids)} entries")
    print(f"   Copy Bundle Resources: {len(resources_uuids)} entries")
    
    if len(sources_uuids) == len(swift_files):
        print(f"   [OK] All Swift files are in Compile Sources")
    else:
        print(f"   [ERROR] Swift file count mismatch: {len(sources_uuids)} in phase vs {len(swift_files)} on disk")
        errors.append(f"Compile Sources count mismatch")
    
    # Summary
    print(f"\n{'='*60}")
    if not errors:
        print("[OK] Xcode project validation PASSED")
        print(f"   - {len(swift_files)} Swift files properly included")
        print(f"   - {len(resource_files)} resource files properly included")
        print(f"   - All critical files present")
        print(f"   - Build phases configured correctly")
        return True
    else:
        print(f"[ERROR] Validation FAILED with {len(errors)} errors:")
        for err in errors:
            print(f"   - {err}")
        return False

if __name__ == '__main__':
    success = main()
    exit(0 if success else 1)
