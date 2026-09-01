#!/usr/bin/env python3
import os
import sys
import tempfile
import zipfile


def main():
    if len(sys.argv) != 4:
        raise SystemExit("usage: replace_zip_entry.py ARCHIVE SOURCE ENTRY")

    archive_path, source_path, entry_name = sys.argv[1:]
    archive_dir = os.path.dirname(os.path.abspath(archive_path))

    with tempfile.NamedTemporaryFile(dir=archive_dir, delete=False) as temporary:
        temporary_path = temporary.name

    try:
        with zipfile.ZipFile(archive_path, "r") as source_archive:
            with zipfile.ZipFile(temporary_path, "w") as target_archive:
                for item in source_archive.infolist():
                    if item.filename != entry_name:
                        target_archive.writestr(item, source_archive.read(item.filename))

                target_archive.write(
                    source_path,
                    entry_name,
                    compress_type=zipfile.ZIP_DEFLATED
                )

        os.replace(temporary_path, archive_path)
    finally:
        if os.path.exists(temporary_path):
            os.unlink(temporary_path)


if __name__ == "__main__":
    main()
