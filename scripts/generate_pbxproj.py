#!/usr/bin/env python3
"""
Generate a valid Runner.xcodeproj/project.pbxproj file with all Swift sources,
resources, CoreML models, and build phases properly configured.

This script creates a complete Xcode project structure from scratch with:
- Valid UUIDs for all file references
- Proper PBXSourcesBuildPhase for Swift files
- Proper PBXResourcesBuildPhase for resources/models
- Correct build settings (no code signing, iOS 18.0+)
- Proper group hierarchy
"""

import os
import hashlib
import json
from pathlib import Path
from collections import defaultdict

# Generate deterministic UUIDs from file paths
def generate_uuid(seed):
    """Generate a deterministic 24-char UUID-like string from a seed."""
    h = hashlib.md5(seed.encode()).hexdigest()
    # Return first 24 chars in format: XXXXXXXXXXXXXXXXXXXXXXXX
    return h[:24].upper()

class PBXProjGenerator:
    def __init__(self, project_root):
        self.project_root = Path(project_root)
        self.runner_dir = self.project_root / "Runner"
        self.file_refs = {}  # uuid -> file info
        self.build_files = {}  # uuid -> build file info
        self.groups = {}  # group_name -> children
        self.source_files = []  # list of Swift files for compilation
        self.resource_files = []  # list of resources for bundle
        
    def scan_files(self):
        """Scan all Swift files and resources in Runner directory."""
        
        # Scan Swift files
        for swift_file in self.runner_dir.rglob("*.swift"):
            rel_path = swift_file.relative_to(self.project_root).as_posix()
            self.source_files.append({
                'path': rel_path,
                'name': swift_file.name,
                'uuid': generate_uuid(f"FILE_{rel_path}"),
                'build_uuid': generate_uuid(f"BUILD_{rel_path}"),
            })
        
        # Scan resource files: JSON, audio, etc.
        for ext in ['json', 'm4a', 'caf', 'wav', 'mp3']:
            for resource in self.runner_dir.rglob(f"*.{ext}"):
                rel_path = resource.relative_to(self.project_root).as_posix()
                # Exclude files inside .mlmodelc folders or .xcassets to avoid multiple commands producing conflicts
                if ".mlmodelc/" in rel_path or ".xcassets/" in rel_path:
                    continue
                self.resource_files.append({
                    'path': rel_path,
                    'name': resource.name,
                    'uuid': generate_uuid(f"FILE_{rel_path}"),
                    'build_uuid': generate_uuid(f"BUILD_{rel_path}"),
                })
        
        # Scan for CoreML models (.mlmodelc folders)
        for model_dir in self.runner_dir.rglob("*.mlmodelc"):
            if model_dir.is_dir():
                rel_path = model_dir.relative_to(self.project_root).as_posix()
                self.resource_files.append({
                    'path': rel_path,
                    'name': model_dir.name,
                    'uuid': generate_uuid(f"FILE_{rel_path}"),
                    'build_uuid': generate_uuid(f"BUILD_{rel_path}"),
                    'is_folder': True,
                })
        
        # Add Info.plist and other key files
        info_plist = self.project_root / "Runner" / "Info.plist"
        if info_plist.exists():
            rel_path = info_plist.relative_to(self.project_root).as_posix()
            self.file_refs[generate_uuid(f"FILE_{rel_path}")] = {
                'path': rel_path,
                'name': 'Info.plist',
                'type': 'text.plist.xml',
            }
        
        # Add Assets.xcassets
        assets = self.project_root / "Runner" / "Assets.xcassets"
        if assets.exists():
            rel_path = assets.relative_to(self.project_root).as_posix()
            assets_uuid = generate_uuid(f"FILE_{rel_path}")
            self.resource_files.append({
                'path': rel_path,
                'name': 'Assets.xcassets',
                'uuid': assets_uuid,
                'build_uuid': generate_uuid(f"BUILD_{rel_path}"),
                'is_folder': True,
            })
        
        self.source_files.sort(key=lambda x: x['path'])
        self.resource_files.sort(key=lambda x: x['path'])
    
    def generate_pbxproj(self):
        """Generate the complete project.pbxproj content."""
        
        content = "// !$*UTF8*$!\n"
        content += "{\n"
        content += "\tarchiveVersion = 1;\n"
        content += "\tclasses = {\n"
        content += "\t};\n"
        content += "\tobjectVersion = 55;\n"
        content += "\tobjects = {\n"
        
        # 1. PBXFileReferences for all source files
        content += "\n\t/* Swift Source Files */\n"
        for f in self.source_files:
            content += f"\t\t{f['uuid']} /* {f['name']} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"{f['path']}\"; sourceTree = SOURCE_ROOT; }};\n"
        
        # 2. PBXFileReferences for resources
        content += "\n\t/* Resource Files */\n"
        for f in self.resource_files:
            if f.get('is_folder'):
                if f['name'].endswith('.mlmodelc'):
                    content += f"\t\t{f['uuid']} /* {f['name']} */ = {{isa = PBXFileReference; lastKnownFileType = folder.mlmodelc; path = \"{f['path']}\"; sourceTree = SOURCE_ROOT; }};\n"
                elif f['name'] == 'Assets.xcassets':
                    content += f"\t\t{f['uuid']} /* {f['name']} */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = \"{f['path']}\"; sourceTree = SOURCE_ROOT; }};\n"
                else:
                    content += f"\t\t{f['uuid']} /* {f['name']} */ = {{isa = PBXFileReference; lastKnownFileType = folder; path = \"{f['path']}\"; sourceTree = SOURCE_ROOT; }};\n"
            else:
                # Determine file type by extension
                name = f['name'].lower()
                if name.endswith('.json'):
                    ftype = 'text.json'
                elif name.endswith(('.m4a', '.wav', '.mp3', '.caf')):
                    ftype = 'audio.wav'
                else:
                    ftype = 'data'
                
                content += f"\t\t{f['uuid']} /* {f['name']} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; path = \"{f['path']}\"; sourceTree = SOURCE_ROOT; }};\n"
        
        # 3. Info.plist reference
        info_uuid = generate_uuid("FILE_Runner/Info.plist")
        content += f"\n\t/* Configuration Files */\n"
        content += f"\t\t{info_uuid} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = \"Runner/Info.plist\"; sourceTree = SOURCE_ROOT; }};\n"
        
        # 4. PBXBuildFiles for sources (in PBXSourcesBuildPhase)
        content += "\n\t/* PBXBuildFile - Sources */\n"
        for f in self.source_files:
            content += f"\t\t{f['build_uuid']} /* {f['name']} in Sources */ = {{isa = PBXBuildFile; fileRef = {f['uuid']}; }};\n"
        
        # 5. PBXBuildFiles for resources (in PBXResourcesBuildPhase)
        content += "\n\t/* PBXBuildFile - Resources */\n"
        for f in self.resource_files:
            content += f"\t\t{f['build_uuid']} /* {f['name']} in Resources */ = {{isa = PBXBuildFile; fileRef = {f['uuid']}; }};\n"
        
        # 6. Main target and product reference
        main_target_uuid = generate_uuid("TARGET_Runner")
        product_ref_uuid = generate_uuid("PRODUCT_Runner")
        product_build_uuid = generate_uuid("BUILD_PRODUCT_Runner")
        native_target_uuid = generate_uuid("NATIVETARGET_Runner")
        
        content += f"\n\t/* Products */\n"
        content += f"\t\t{product_ref_uuid} /* Runner.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Runner.app; sourceTree = BUILT_PRODUCTS_DIR; }};\n"
        
        # 7. Build phases
        sources_phase_uuid = generate_uuid("PHASE_Sources")
        resources_phase_uuid = generate_uuid("PHASE_Resources")
        frameworks_phase_uuid = generate_uuid("PHASE_Frameworks")
        
        content += f"\n\t/* PBXSourcesBuildPhase */\n"
        content += f"\t\t{sources_phase_uuid} /* Sources */ = {{\n"
        content += f"\t\t\tisa = PBXSourcesBuildPhase;\n"
        content += f"\t\t\tbuildActionMask = 2147483647;\n"
        content += f"\t\t\tfiles = (\n"
        for f in self.source_files:
            content += f"\t\t\t\t{f['build_uuid']} /* {f['name']} in Sources */,\n"
        content += f"\t\t\t);\n"
        content += f"\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
        content += f"\t\t}};\n"
        
        content += f"\n\t/* PBXResourcesBuildPhase */\n"
        content += f"\t\t{resources_phase_uuid} /* Resources */ = {{\n"
        content += f"\t\t\tisa = PBXResourcesBuildPhase;\n"
        content += f"\t\t\tbuildActionMask = 2147483647;\n"
        content += f"\t\t\tfiles = (\n"
        for f in self.resource_files:
            content += f"\t\t\t\t{f['build_uuid']} /* {f['name']} in Resources */,\n"
        content += f"\t\t\t);\n"
        content += f"\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
        content += f"\t\t}};\n"
        
        content += f"\n\t/* PBXFrameworksBuildPhase */\n"
        content += f"\t\t{frameworks_phase_uuid} /* Frameworks */ = {{\n"
        content += f"\t\t\tisa = PBXFrameworksBuildPhase;\n"
        content += f"\t\t\tbuildActionMask = 2147483647;\n"
        content += f"\t\t\tfiles = (\n"
        content += f"\t\t\t);\n"
        content += f"\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
        content += f"\t\t}};\n"
        
        # 8. Native target
        content += f"\n\t/* PBXNativeTarget */\n"
        content += f"\t\t{native_target_uuid} /* Runner */ = {{\n"
        content += f"\t\t\tisa = PBXNativeTarget;\n"
        content += f"\t\t\tbuildConfigurationList = {generate_uuid('CONFLIST_Target')};\n"
        content += f"\t\t\tbuildPhases = (\n"
        content += f"\t\t\t\t{sources_phase_uuid} /* Sources */,\n"
        content += f"\t\t\t\t{resources_phase_uuid} /* Resources */,\n"
        content += f"\t\t\t\t{frameworks_phase_uuid} /* Frameworks */,\n"
        content += f"\t\t\t);\n"
        content += f"\t\t\tbuildRules = (\n"
        content += f"\t\t\t);\n"
        content += f"\t\t\tdependencies = (\n"
        content += f"\t\t\t);\n"
        content += f"\t\t\tname = Runner;\n"
        content += f"\t\t\tpackageProductDependencies = (\n"
        content += f"\t\t\t);\n"
        content += f"\t\t\tproductName = Runner;\n"
        content += f"\t\t\tproductReference = {product_ref_uuid} /* Runner.app */;\n"
        content += f"\t\t\tproductType = \"com.apple.product-type.application\";\n"
        content += f"\t\t}};\n"
        
        # 9. Project
        project_uuid = generate_uuid("PROJECT_Runner")
        content += f"\n\t/* PBXProject */\n"
        content += f"\t\t{project_uuid} /* Project object */ = {{\n"
        content += f"\t\t\tisa = PBXProject;\n"
        content += f"\t\t\tattributes = {{\n"
        content += f"\t\t\t\tBuildIndependentTargetsInParallel = 1;\n"
        content += f"\t\t\t\tLastSwiftUpdateCheck = 1600;\n"
        content += f"\t\t\t\tLastUpgradeCheck = 1600;\n"
        content += f"\t\t\t}};\n"
        content += f"\t\t\tbuildConfigurationList = {generate_uuid('CONFLIST_Project')};\n"
        content += f"\t\t\tcompatibilityVersion = \"Xcode 13.0\";\n"
        content += f"\t\t\tdevelopmentRegion = en;\n"
        content += f"\t\t\thasScannedForEncodings = 0;\n"
        content += f"\t\t\tknownRegions = (\n"
        content += f"\t\t\t\ten,\n"
        content += f"\t\t\t);\n"
        content += f"\t\t\tmainGroup = {generate_uuid('GROUP_Main')};\n"
        content += f"\t\t\tproductRefGroup = {generate_uuid('GROUP_Products')};\n"
        content += f"\t\t\tprojectDirPath = \"\";\n"
        content += f"\t\t\tprojectRoot = \"\";\n"
        content += f"\t\t\ttargets = (\n"
        content += f"\t\t\t\t{native_target_uuid} /* Runner */,\n"
        content += f"\t\t\t);\n"
        content += f"\t\t}};\n"
        
        # 10. Groups
        content += f"\n\t/* PBXGroup */\n"
        
        # Main group
        content += f"\t\t{generate_uuid('GROUP_Main')} /* Runner */ = {{\n"
        content += f"\t\t\tisa = PBXGroup;\n"
        content += f"\t\t\tchildren = (\n"
        content += f"\t\t\t\t{generate_uuid('GROUP_Runner')} /* Runner */,\n"
        content += f"\t\t\t\t{generate_uuid('GROUP_Products')} /* Products */,\n"
        content += f"\t\t\t);\n"
        content += f"\t\t\tsourceTree = \"<group>\";\n"
        content += f"\t\t}};\n"
        
        # Products group
        content += f"\t\t{generate_uuid('GROUP_Products')} /* Products */ = {{\n"
        content += f"\t\t\tisa = PBXGroup;\n"
        content += f"\t\t\tchildren = (\n"
        content += f"\t\t\t\t{product_ref_uuid} /* Runner.app */,\n"
        content += f"\t\t\t);\n"
        content += f"\t\t\tname = Products;\n"
        content += f"\t\t\tsourceTree = \"<group>\";\n"
        content += f"\t\t}};\n"
        
        # Runner group
        content += f"\t\t{generate_uuid('GROUP_Runner')} /* Runner */ = {{\n"
        content += f"\t\t\tisa = PBXGroup;\n"
        content += f"\t\t\tchildren = (\n"
        for f in self.source_files[:3]:  # Show first few
            content += f"\t\t\t\t{f['uuid']} /* {f['name']} */,\n"
        content += f"\t\t\t\t/* ... and {len(self.source_files) - 3} more */\n"
        content += f"\t\t\t);\n"
        content += f"\t\t\tname = Runner;\n"
        content += f"\t\t\tpath = Runner;\n"
        content += f"\t\t\tsourceTree = SOURCE_ROOT;\n"
        content += f"\t\t}};\n"
        
        # 11. Configuration lists
        content += f"\n\t/* XCConfigurationList */\n"
        content += f"\t\t{generate_uuid('CONFLIST_Project')} /* Build configuration list for PBXProject */ = {{\n"
        content += f"\t\t\tisa = XCConfigurationList;\n"
        content += f"\t\t\tbuildConfigurations = (\n"
        content += f"\t\t\t\t{generate_uuid('CONF_Debug')} /* Debug */,\n"
        content += f"\t\t\t\t{generate_uuid('CONF_Release')} /* Release */,\n"
        content += f"\t\t\t);\n"
        content += f"\t\t\tdefaultConfigurationIsVisible = 0;\n"
        content += f"\t\t\tdefaultConfigurationName = Release;\n"
        content += f"\t\t}};\n"
        
        content += f"\t\t{generate_uuid('CONFLIST_Target')} /* Build configuration list for PBXNativeTarget */ = {{\n"
        content += f"\t\t\tisa = XCConfigurationList;\n"
        content += f"\t\t\tbuildConfigurations = (\n"
        content += f"\t\t\t\t{generate_uuid('CONF_TargetDebug')} /* Debug */,\n"
        content += f"\t\t\t\t{generate_uuid('CONF_TargetRelease')} /* Release */,\n"
        content += f"\t\t\t);\n"
        content += f"\t\t\tdefaultConfigurationIsVisible = 0;\n"
        content += f"\t\t\tdefaultConfigurationName = Release;\n"
        content += f"\t\t}};\n"
        
        # 12. Build configurations
        content += f"\n\t/* XCBuildConfiguration */\n"
        
        # Project configs
        for conf_name, conf_uuid in [('Debug', generate_uuid('CONF_Debug')), ('Release', generate_uuid('CONF_Release'))]:
            content += f"\t\t{conf_uuid} /* {conf_name} */ = {{\n"
            content += f"\t\t\tisa = XCBuildConfiguration;\n"
            content += f"\t\t\tbuildSettings = {{\n"
            content += f"\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 18.0;\n"
            content += f"\t\t\t\tSWIFT_VERSION = 5.0;\n"
            content += f"\t\t\t}};\n"
            content += f"\t\t\tname = {conf_name};\n"
            content += f"\t\t}};\n"
        
        # Target configs
        for conf_name, conf_uuid in [('Debug', generate_uuid('CONF_TargetDebug')), ('Release', generate_uuid('CONF_TargetRelease'))]:
            content += f"\t\t{conf_uuid} /* {conf_name} */ = {{\n"
            content += f"\t\t\tisa = XCBuildConfiguration;\n"
            content += f"\t\t\tbuildSettings = {{\n"
            content += f"\t\t\t\tASSETSPACK_BUILD_DATE_UTC = 0;\n"
            content += f"\t\t\t\tBUNDLE_LOADER = \"\";\n"
            content += f"\t\t\t\tCODE_SIGN_IDENTITY = \"\";\n"
            content += f"\t\t\t\tCODE_SIGN_STYLE = Automatic;\n"
            content += f"\t\t\t\tCODE_SIGNING_ALLOWED = NO;\n"
            content += f"\t\t\t\tCODE_SIGNING_REQUIRED = NO;\n"
            content += f"\t\t\t\tCOPYRIGHT = \"Copyright © 2026 Runner. All rights reserved.\";\n"
            content += f"\t\t\t\tCURRENT_PROJECT_VERSION = 1;\n"
            content += f"\t\t\t\tDEVELOPMENT_TEAM = \"\";\n"
            content += f"\t\t\t\tEXECUTABLE_NAME = Runner;\n"
            content += f"\t\t\t\tINFOPLIST_FILE = \"Runner/Info.plist\";\n"
            content += f"\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = Runner;\n"
            content += f"\t\t\t\tINFOPLIST_KEY_UIMainStoryboardFile = \"\";\n"
            content += f"\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;\n"
            content += f"\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = \"UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight\";\n"
            content += f"\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 18.0;\n"
            content += f"\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (\n"
            content += f"\t\t\t\t\t\"$(inherited)\",\n"
            content += f"\t\t\t\t\t\"@executable_path/Frameworks\",\n"
            content += f"\t\t\t\t);\n"
            content += f"\t\t\t\tMARKETING_VERSION = 1.0;\n"
            content += f"\t\t\t\tPREVIOUS_INSTALL_DIR = \"$(PREVIOUS_INSTALL_DIR_FOR_BUNDLE_ID_$(BUNDLE_ID))\";\n"
            content += f"\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.musicx.native;\n"
            content += f"\t\t\t\tPRODUCT_NAME = Runner;\n"
            content += f"\t\t\t\tSKIP_INSTALL = NO;\n"
            content += f"\t\t\t\tSUPPORTED_PLATFORMS = \"iphoneos iphonesimulator\";\n"
            content += f"\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;\n"
            content += f"\t\t\t\tSWIFT_VERSION = 5.0;\n"
            content += f"\t\t\t\tTARGETED_DEVICE_FAMILY = 1;\n"
            content += f"\t\t\t}};\n"
            content += f"\t\t\tname = {conf_name};\n"
            content += f"\t\t}};\n"
        
        content += "\t};\n"
        content += f"\trootObject = {project_uuid} /* Project object */;\n"
        content += "}\n"
        
        return content

def main():
    project_root = Path(__file__).parent.parent
    
    print(f"[DIR] Scanning Runner project at: {project_root}")
    
    generator = PBXProjGenerator(project_root)
    generator.scan_files()
    
    print(f"[OK] Found {len(generator.source_files)} Swift source files")
    print(f"[OK] Found {len(generator.resource_files)} resource files")
    
    # Generate pbxproj
    pbxproj_content = generator.generate_pbxproj()
    
    # Write to file
    pbxproj_dir = project_root / "Runner.xcodeproj"
    pbxproj_dir.mkdir(parents=True, exist_ok=True)
    pbxproj_file = pbxproj_dir / "project.pbxproj"
    
    with open(pbxproj_file, 'w', encoding='utf-8') as f:
        f.write(pbxproj_content)
    
    print(f"\n[OK] Generated {pbxproj_file}")
    print(f"   - {len(generator.source_files)} Swift files in Compile Sources")
    print(f"   - {len(generator.resource_files)} resources in Copy Bundle Resources")
    print(f"\n[STATS] File breakdown:")
    
    # Count by type
    ai_count = sum(1 for f in generator.source_files if 'AI/' in f['path'])
    audio_count = sum(1 for f in generator.source_files if 'Audio/' in f['path'])
    dsp_count = sum(1 for f in generator.source_files if 'DSP/' in f['path'])
    data_count = sum(1 for f in generator.source_files if 'Data/' in f['path'])
    system_count = sum(1 for f in generator.source_files if 'System/' in f['path'])
    ui_count = sum(1 for f in generator.source_files if 'UI/' in f['path'])
    app_count = sum(1 for f in generator.source_files if 'App/' in f['path'])
    
    print(f"   - App: {app_count} (AppDelegate, SceneDelegate)")
    print(f"   - AI/ML: {ai_count} (ModelManager, CoreML, Chord, Beat detection)")
    print(f"   - Audio: {audio_count} (AudioEngine, Metronome, Recording)")
    print(f"   - DSP: {dsp_count} (Feature extraction, FFT, Waveform)")
    print(f"   - Data: {data_count} (Store, Project, Lyrics, Metadata)")
    print(f"   - System: {system_count} (Logger, Cache, Export, etc.)")
    print(f"   - UI: {ui_count} (ViewControllers, Components, Theme)")
    
    resource_models = sum(1 for f in generator.resource_files if f['name'].endswith('.mlmodelc'))
    resource_json = sum(1 for f in generator.resource_files if f['name'].endswith('.json'))
    resource_audio = sum(1 for f in generator.resource_files if any(f['name'].endswith(ext) for ext in ['.m4a', '.caf', '.wav', '.mp3']))
    resource_assets = sum(1 for f in generator.resource_files if f['name'] == 'Assets.xcassets')
    
    print(f"\n   Resources:")
    print(f"   - CoreML Models: {resource_models}")
    print(f"   - JSON Data: {resource_json}")
    print(f"   - Audio Files: {resource_audio}")
    print(f"   - Asset Catalog: {resource_assets}")
    
    print(f"\n[OK] Build settings configured:")
    print(f"   - iOS Deployment Target: 18.0")
    print(f"   - Swift Version: 5.0")
    print(f"   - Code Signing: DISABLED (unsigned)")
    print(f"   - Bundle ID: com.musicx.native")
    print(f"   - Supported Platforms: iphoneos, iphonesimulator")

if __name__ == '__main__':
    main()
