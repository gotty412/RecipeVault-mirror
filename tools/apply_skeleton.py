# tools/apply_skeleton.py
# 使い方:
#   python3 tools/apply_skeleton.py
# -------------------------------------------------
import pathlib, re, sys

root = pathlib.Path(__file__).resolve().parents[1]
src = root / 'recipe_app_flutter_skeleton.dart'
if not src.exists():
    sys.exit('❌  recipe_app_flutter_skeleton.dart が見つかりません')

text = src.read_text(encoding='utf-8')

# ── pubspec 抽出 ───────────────────────────────
pub_match = re.search(r'/\*\s*pubspec.yaml\s*\*/\n([\s\S]*?)\n//', text)
blocks = [('pubspec.yaml', pub_match.group(1))] if pub_match else []

# ── lib/ 以下を抽出 ────────────────────────────
pattern = re.compile(r'^//\s+─{5,}\s+(?P<path>[^\s]+)\s+─{5,}$', re.M)
current_path, buf = None, []
for line in text.splitlines(keepends=True):
    m = pattern.match(line)
    if m:
        if current_path:
            blocks.append((current_path, ''.join(buf)))
        current_path = m.group('path')
        buf = []
    else:
        if current_path:
            buf.append(line)
if current_path and buf:
    blocks.append((current_path, ''.join(buf)))

# ── ファイルへ書き出し ────────────────────────
for rel, body in blocks:
    dest = root / rel
    # === Guard: keep CLI‑generated firebase_options.dart intact ===
    if rel == 'lib/firebase_options.dart' and dest.exists():
        print(f'⏭️  {rel} は既に存在 → 上書きせずスキップ')
        continue
    # ============================================================
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(body.lstrip('\n'), encoding='utf-8')
    print(f'✅  {dest.relative_to(root)} を生成')

print('\n🎉  Skeleton applied!  次に flutter pub get → flutter run を実行してください')
