#!/usr/bin/env python3
import sys
import re

def main():
    log_path = "build_output.log"
    if len(sys.argv) > 1:
        log_path = sys.argv[1]
        
    try:
        with open(log_path, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()
    except FileNotFoundError:
        print(f"Error: Log file not found at {log_path}")
        sys.exit(1)
        
    print(f"Analyzing {log_path} ({len(lines)} lines)...")
    
    # Search for lines containing errors
    error_patterns = [
        ": error:",
        "error:",
        "invalid redeclaration",
        "ambiguous use",
        "cannot find",
        "extra argument",
        "missing argument",
        "does not conform",
        "no member",
        "type of expression is ambiguous"
    ]
    
    error_indices = []
    for idx, line in enumerate(lines):
        if any(pat in line for pat in error_patterns):
            error_indices.append(idx)
            
    if not error_indices:
        print("No errors matching patterns found in build log.")
        return
        
    print(f"\nFound {len(error_indices)} lines matching error patterns.\n")
    
    # Print the full Swift file list compiled in the failed command
    # Find the command that failed. Search backwards from first error.
    failed_cmd_block = []
    first_error_idx = error_indices[0]
    
    # Scan backward to find command start marker
    start_search = max(0, first_error_idx - 1000)
    for i in range(first_error_idx, start_search, -1):
        if any(marker in lines[i] for marker in ["CompileSwiftSources", "CompileSwift normal", "swiftc", "swift-frontend"]):
            # Found a potential start. Gather the command.
            for j in range(i, min(len(lines), i + 500)):
                failed_cmd_block.append(lines[j])
                # Stop if we hit a newline or start of next phase, or the error itself
                if j > first_error_idx and (lines[j].strip() == "" or "Command SwiftCompile failed" in lines[j] or "** BUILD FAILED **" in lines[j]):
                    break
            break
            
    compiled_swift_files = set()
    if failed_cmd_block:
        for line in failed_cmd_block:
            # Extract anything that looks like a .swift file path
            matches = re.findall(r'(/[^\s\'"]+\.swift)\b', line)
            for m in matches:
                compiled_swift_files.add(m)
            matches_quoted = re.findall(r'["\']([^"\']+\.swift)["\']', line)
            for m in matches_quoted:
                compiled_swift_files.add(m)
                
    if not compiled_swift_files:
        # Fallback: scan around errors for any .swift files
        scan_start = max(0, first_error_idx - 50)
        scan_end = min(len(lines), first_error_idx + 20)
        for i in range(scan_start, scan_end):
            matches = re.findall(r'(/[^\s\'"]+\.swift)\b', lines[i])
            for m in matches:
                compiled_swift_files.add(m)
                
    if compiled_swift_files:
        print("===== COMPILED SWIFT FILES IN FAILED COMMAND =====")
        for f in sorted(compiled_swift_files):
            print(f)
        print("==================================================\n")
    else:
        print("Could not extract compiled Swift file list from build log.")
            
    # Print focused diagnostics with 10 lines before and 20 lines after
    printed_ranges = []
    
    print("===== FOCUSED DIAGNOSTICS =====")
    for idx in error_indices:
        # Check if this index is already covered
        already_printed = False
        for start, end in printed_ranges:
            if start <= idx <= end:
                already_printed = True
                break
        if already_printed:
            continue
            
        start_line = max(0, idx - 10)
        end_line = min(len(lines) - 1, idx + 20)
        printed_ranges.append((start_line, end_line))
        
        print(f"\n--- Context for error at log line {idx + 1} ---")
        for i in range(start_line, end_line + 1):
            marker = ">>> " if i == idx else "    "
            print(f"{marker}{i+1}: {lines[i].rstrip()}")
            
    print("\n===== SUMMARY OF EXACT ERRORS =====")
    # Regex pattern: filePath:line:column: error: message
    # or filePath:line: error: message
    error_regex = re.compile(r'^(.*?\.swift):(\d+):(?:(?:\d+):)?\s*error:\s*(.*)$', re.IGNORECASE)
    
    for idx in error_indices:
        line = lines[idx].strip()
        match = error_regex.search(line)
        if match:
            filepath, line_num, message = match.groups()
            print(f"File: {filepath}")
            print(f"Line: {line_num}")
            print(f"Error: {message}")
            print("-" * 50)
        else:
            # Try to match a simpler format or print the raw line
            print(f"Log Line {idx + 1}: {line}")
            print("-" * 50)
            
if __name__ == "__main__":
    main()
