#!/usr/bin/env bash
# 포트폴리오·이력서 PDF 생성.
#
#   ./build-pdf.sh          공개용 (전화번호 없음)
#                             -> han-jaehyuk-portfolio.pdf, resume-public.pdf
#   PHONE=010-0000-0000 ./build-pdf.sh
#                           제출용 (전화번호 포함, .gitignore 대상)
#                             -> 한재혁_포트폴리오_백엔드_2026.pdf, 한재혁_이력서_백엔드_2026.pdf
#
# 전화번호는 레포에 커밋하지 않는다. 소스에는 <!--PHONE--> 슬롯만 두고 빌드할 때 주입한다.
set -euo pipefail

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
PORT="${PORT:-5143}"
cd "$(dirname "$0")"

curl -sf -o /dev/null "http://localhost:$PORT/index.html" \
  || { echo "localhost:$PORT 에 서버가 없습니다. PORT=... 로 지정하세요."; exit 1; }

# render <소스html> <출력pdf>
render() {
  local src="$1" out="$2" target="$1"

  if [ -n "${PHONE:-}" ]; then
    target="${src%.html}.submit.html"
    python3 - "$src" "$target" "$PHONE" <<'PY'
import sys, pathlib
src, dst, phone = sys.argv[1:4]
s = pathlib.Path(src).read_text()
n = s.count('<!--PHONE-->')
assert n, f'{src}: <!--PHONE--> 슬롯 없음'
pathlib.Path(dst).write_text(
    s.replace('<!--PHONE-->', f'<a href="tel:{phone}">{phone}</a>'))
print(f'  {src}: 전화번호 {n}곳 주입')
PY
  fi

  "$CHROME" --headless --disable-gpu --no-pdf-header-footer \
    --print-to-pdf="$out" "http://localhost:$PORT/$target" 2>/dev/null

  if command -v exiftool >/dev/null 2>&1; then
    exiftool -overwrite_original -Author="한재혁" -Creator="한재혁" "$out" >/dev/null
  fi
  [ "$target" != "$src" ] && rm -f "$target"
  echo "  생성: $out ($(du -h "$out" | cut -f1), $(mdls -name kMDItemNumberOfPages -raw "$out" 2>/dev/null || echo '?')p)"
}

if [ -n "${PHONE:-}" ]; then
  render portfolio-print.html "한재혁_포트폴리오_백엔드_2026.pdf"
  render resume-public.html   "한재혁_이력서_백엔드_2026.pdf"
else
  render portfolio-print.html "han-jaehyuk-portfolio.pdf"
  render resume-public.html   "resume-public.pdf"
fi

command -v exiftool >/dev/null 2>&1 \
  || echo "  (exiftool 없음 — 작성자 메타는 HeadlessChrome UA 그대로. brew install exiftool)"
