"""Inspect the packaged release without extracting or printing credentials."""
import hashlib
import json
from pathlib import Path
import re
import sys
import zipfile

root = Path(__file__).resolve().parents[1]
apk = Path(sys.argv[1]) if len(sys.argv) > 1 else root / 'build/app/outputs/flutter-apk/app-release.apk'
membership = (root / 'lib/app/configuration/private_membership.dart').read_text()
uids = re.findall(r"privateMember[AB] = '([^']+)'", membership)
if len(uids) != 2 or not all(uids):
    raise SystemExit('The source must contain both actual member UIDs before verifying a release.')
with zipfile.ZipFile(apk) as package:
    names = set(package.namelist())
    code = package.read('lib/arm64-v8a/libapp.so')
    checks = {
        'arm64_release_code': True,
        'both_actual_uids_packaged': all(uid.encode() in code for uid in uids),
        'correct_firebase_project_packaged': b'bear-with-me-f60a3' in code,
        'emulator_project_absent': b'demo-bear-with-me' not in code,
        'bundled_font_present': 'assets/flutter_assets/assets/fonts/Nunito.ttf' in names,
        'original_sound_present': 'assets/flutter_assets/assets/audio/heart.wav' in names,
        'no_service_account_file': not any('service-account' in name.lower() or 'service_account' in name.lower() for name in names),
    }
    if not all(checks.values()):
        raise SystemExit(json.dumps(checks, indent=2))
digest = hashlib.file_digest(apk.open('rb'), 'sha256').hexdigest()
record = {'apk': apk.name, 'bytes': apk.stat().st_size, 'sha256': digest, 'checks': checks}
(root / 'artifacts/apk-verification.json').write_text(json.dumps(record, indent=2) + '\n')
(root / 'artifacts/app-release.apk.sha256').write_text(f'{digest}  app-release.apk\n')
print(json.dumps(record, indent=2))
