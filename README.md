# Copy with Hash Check (Windows Batch)

A Windows batch script that copies files from a source folder to a destination folder and verifies integrity using SHA-256 hashes:

- If destination file does not exist: copy it
- If destination file exists and hashes match: skip
- If destination file exists and hashes differ: overwrite

## Requirements
- Windows (includes `certutil` by default)

## Configure
Edit these variables at the top of the script:

- `SOURCE`
- `DEST`
- `HASHALG` (default SHA256)

## Run
Double-click the `.bat` file or run from cmd:

```bat
copy_with_hash_check.bat
