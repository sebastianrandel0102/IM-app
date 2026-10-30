"""Package the reproducible source, honoring Git ignores and excluding keys."""
from pathlib import Path
import subprocess
import zipfile

root = Path(__file__).resolve().parents[1]
files = subprocess.check_output(
    ['git', 'ls-files', '--cached', '--others', '--exclude-standard', '-z'],
    cwd=root,
).decode('utf-8').split('\0')
destination = root / 'artifacts' / 'Bear-With-Me-source.zip'
destination.parent.mkdir(exist_ok=True)
with zipfile.ZipFile(destination, 'w', compression=zipfile.ZIP_DEFLATED) as bundle:
    for relative in sorted(set(filter(None, files))):
        path = root / relative
        if path.suffix.lower() in {'.jks', '.keystore', '.apk', '.zip'} or path.name == 'key.properties':
            continue
        if path.is_file():
            bundle.write(path, relative)
print(f'Source archive created: {destination}')
