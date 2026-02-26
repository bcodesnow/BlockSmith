"""
Fix bare LF corruption in block-containing .md files.

Previous versions of SyncEngine::replaceBlockInFile injected bare \n
into CRLF files. This script:
  1. Backs up blocks.db.json
  2. Scans all .md files listed in blocks.db.json sourceFile + project dirs
  3. Fixes bare \n inside blocks → \r\n (matching surrounding file)
  4. Normalizes blocks.db.json content to strip trailing newlines

Usage: python tools/fix_block_crlf.py [--dry-run]
"""

import json, re, shutil, sys, os, glob
from datetime import datetime

DRY_RUN = "--dry-run" in sys.argv

DB_PATH = os.path.expandvars(
    r"%LOCALAPPDATA%\BlockSmith\BlockSmith\blocks.db.json"
)

# Directories to scan for .md files containing blocks
SCAN_DIRS = [
    r"C:\Projects",
]

def find_md_files():
    """Find all .md files under scan dirs."""
    files = set()
    for d in SCAN_DIRS:
        for f in glob.glob(os.path.join(d, "**", "*.md"), recursive=True):
            files.add(os.path.normpath(f))
    return sorted(files)

def fix_file(fpath):
    """Fix bare LF inside CRLF files within block markers. Returns True if modified."""
    with open(fpath, "rb") as f:
        raw = f.read()

    # Only fix CRLF files that also have bare LFs
    crlf_count = raw.count(b"\r\n")
    total_lf = raw.count(b"\n")
    bare_lf = total_lf - crlf_count

    if crlf_count == 0 or bare_lf == 0:
        return False  # pure LF file or no bare LFs

    # Check if file contains any blocks
    if b"<!-- block:" not in raw:
        return False

    # Strategy: within block regions, replace bare \n with \r\n
    text = raw.decode("utf-8", errors="replace")

    block_rx = re.compile(
        r"(<!-- block:\s*.+?\s*\[id:[a-f0-9]+\]\s*-->)\r?\n"
        r"([\s\S]*?)\r?\n"
        r"(<!-- /block:[a-f0-9]+ -->)"
    )

    def fix_block(m):
        open_tag = m.group(1)
        content = m.group(2)
        close_tag = m.group(3)

        # Normalize content: strip \r, then convert \n to \r\n
        content = content.replace("\r", "")
        # Strip trailing newlines from content (registry doesn't have them)
        content = content.rstrip("\n")
        content = content.replace("\n", "\r\n")

        return open_tag + "\r\n" + content + "\r\n" + close_tag

    fixed = block_rx.sub(fix_block, text)

    if fixed == text:
        return False

    if not DRY_RUN:
        with open(fpath, "wb") as f:
            f.write(fixed.encode("utf-8"))

    return True

def fix_db():
    """Normalize blocks.db.json: strip trailing newlines from content, ensure LF only."""
    if not os.path.exists(DB_PATH):
        print(f"DB not found: {DB_PATH}")
        return False

    # Backup
    backup = DB_PATH + f".backup-{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    if not DRY_RUN:
        shutil.copy2(DB_PATH, backup)
    print(f"Backed up DB to: {backup}")

    with open(DB_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)

    modified = False
    for bid, block in data.get("blocks", {}).items():
        content = block.get("content", "")
        clean = content.replace("\r", "").rstrip("\n")
        if clean != content:
            print(f"  DB fix: block {bid} ({block.get('name', '?')})")
            block["content"] = clean
            modified = True

    if modified and not DRY_RUN:
        with open(DB_PATH, "w", encoding="utf-8", newline="\n") as f:
            json.dump(data, f, indent=4, ensure_ascii=False)
            f.write("\n")

    return modified

def main():
    if DRY_RUN:
        print("=== DRY RUN (no files will be modified) ===\n")

    # Fix DB first
    print("--- Fixing blocks.db.json ---")
    db_fixed = fix_db()
    print(f"  {'Fixed' if db_fixed else 'Already clean'}\n")

    # Fix files
    print("--- Scanning .md files ---")
    md_files = find_md_files()
    print(f"  Found {len(md_files)} .md files\n")

    fixed_count = 0
    for fpath in md_files:
        if fix_file(fpath):
            print(f"  Fixed: {fpath}")
            fixed_count += 1

    print(f"\n--- Done: {fixed_count} file(s) fixed ---")
    if DRY_RUN:
        print("(dry run — no changes written)")

if __name__ == "__main__":
    main()
