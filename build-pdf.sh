#!/usr/bin/env bash
# 포트폴리오 PDF 생성.
#
#   ./build-pdf.sh                       공개용 (전화번호 없음) -> han-jaehyuk-portfolio.pdf
#   PHONE=010-0000-0000 ./build-pdf.sh   제출용 (전화번호 포함) -> 한재혁_포트폴리오_백엔드_2026.pdf
#
# 전화번호는 레포에 커밋하지 않는다. 빌드할 때만 <!--PHONE--> 자리에 주입한다.
set -euo pipefail

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
SRC="portfolio-print.html"
PORT="${PORT:-5143}"
cd "$(dirname "$0")"

[ -f "$SRC" ] || { echo "$SRC 없음"; exit 1; }
curl -sf -o /dev/null "http://localhost:$PORT/$SRC" \
  || { echo "localhost:$PORT 에 서버가 없습니다. 포트를 PORT=... 로 지정하세요."; exit 1; }

if [ -n "${PHONE:-}" ]; then
  OUT="${1:-한재혁_포트폴리오_백엔드_2026.pdf}"
  WORK="portfolio-print.submit.html"          # .gitignore 대상
  # 표지와 마지막 장 두 곳의 슬롯에 주입
  python3 - "$SRC" "$WORK" "$PHONE" <<'PY'
import sys, pathlib
src, dst, phone = sys.argv[1], sys.argv[2], sys.argv[3]
s = pathlib.Path(src).read_text()
n = s.count('<!--PHONE-->')
assert n, '<!--PHONE--> 슬롯이 없습니다'
pathlib.Path(dst).write_text(s.replace('<!--PHONE-->', f'<a href="tel:{phone}">{phone}</a>'))
print(f'  전화번호 주입: {n}곳')
PY
  TARGET="$WORK"
else
  OUT="${1:-han-jaehyuk-portfolio.pdf}"
  TARGET="$SRC"
fi

"$CHROME" --headless --disable-gpu --no-pdf-header-footer \
  --print-to-pdf="$OUT" "http://localhost:$PORT/$TARGET" 2>/dev/null

# 기본값이면 작성자 메타가 HeadlessChrome UA 로 박힌다
if command -v exiftool >/dev/null 2>&1; then
  exiftool -overwrite_original -Author="한재혁" -Creator="한재혁" \
    -Title="한재혁 — Backend Engineer Portfolio" "$OUT" >/dev/null
else
  echo "  (exiftool 없음 — 작성자 메타는 그대로. brew install exiftool)"
fi

[ "${TARGET}" = "portfolio-print.submit.html" ] && rm -f "$TARGET"
echo "생성: $OUT  ($(du -h "$OUT" | cut -f1), $(mdls -name kMDItemNumberOfPages -raw "$OUT" 2>/dev/null || echo '?')p)"
