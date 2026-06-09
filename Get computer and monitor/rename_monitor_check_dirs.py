import argparse
import re
from datetime import datetime
from pathlib import Path

OLD_PATTERN = re.compile(r'^(?P<day>\d{1,2})(?P<mon>[A-Za-z]{3})(?P<year>\d{4})$')
MONTH_MAP = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
}


def find_old_folders(root_path: Path):
    old_folders = []
    if not root_path.exists():
        raise FileNotFoundError(f"Path not found: {root_path}")
    if not root_path.is_dir():
        raise NotADirectoryError(f"Not a directory: {root_path}")

    for child in sorted(root_path.iterdir()):
        if not child.is_dir():
            continue
        match = OLD_PATTERN.match(child.name)
        if not match:
            continue

        mon_text = match.group('mon').lower()
        month = MONTH_MAP.get(mon_text)
        if not month:
            continue

        old_folders.append((child, match.group('day'), month, match.group('year')))

    return old_folders


def format_new_name(day: str, month: int, year: str):
    date_obj = datetime(year=int(year), month=month, day=int(day))
    return date_obj.strftime('%Y-%m-%d')


def main():
    parser = argparse.ArgumentParser(
        description='Rename old Monitor_Check folders from ddMMMyyyy to yyyy-MM-dd format.'
    )
    parser.add_argument(
        'root',
        nargs='?', 
        default=r'\\10.86.176.146\fuoit$\Monitor_Check',
        help='Root folder to scan (default: \\10.86.176.146\fuoit$\Monitor_Check)'
    )
    parser.add_argument(
        '--commit',
        action='store_true',
        help='Perform the rename. Without this flag the script only reports matching folders.'
    )

    args = parser.parse_args()
    root_path = Path(args.root)

    print(f'Scanning root path: {root_path}')
    old_folders = find_old_folders(root_path)

    if not old_folders:
        print('No old-format folders found. Nothing to rename.')
        return

    print('Found old-format folders:')
    for folder, day, month, year in old_folders:
        new_name = format_new_name(day, month, year)
        print(f'  {folder.name} -> {new_name}')

    if not args.commit:
        print('\nDry run complete. Add --commit to rename these folders.')
        return

    print('\nRenaming folders...')
    for folder, day, month, year in old_folders:
        new_name = format_new_name(day, month, year)
        new_path = folder.with_name(new_name)
        if new_path.exists():
            print(f'  Skipping {folder.name}, target already exists: {new_name}')
            continue
        folder.rename(new_path)
        print(f'  Renamed {folder.name} -> {new_name}')

    print('Done.')


if __name__ == '__main__':
    main()
