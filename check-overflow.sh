#!/usr/bin/env bash
# .pdf-page 를 height 고정 -> min-height 로 바꾸고 overflow 를 풀어 렌더한다.
# 297mm 를 넘는 페이지가 있으면 그 페이지가 둘로 쪼개져 총 페이지 수가 6 을 넘는다.
# (평소에는 overflow:hidden 이 조용히 잘라내므로 6p 로 보여 발견되지 않는다)
set -euo pipefail
cd "$(dirname "$0")"
cp portfolio-print.css /tmp/_pp.bak
sed -i '' -e 's/^  height: 297mm;$/  min-height: 297mm;/' \
          -e 's/^  overflow: hidden;$/  overflow: visible;/' portfolio-print.css
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --disable-gpu \
  --no-pdf-header-footer --print-to-pdf=/tmp/_ovf.pdf \
  "http://localhost:${PORT:-5143}/portfolio-print.html" 2>/dev/null
cp /tmp/_pp.bak portfolio-print.css
n=$(exiftool -s3 -PageCount /tmp/_ovf.pdf)
if [ "$n" = "6" ]; then
  echo "  넘침 없음 (6p)"
else
  echo "  ⚠ 넘침: 확장 렌더 ${n}p (6p 기대) — 어느 페이지가 297mm 초과"
fi
rm -f /tmp/_ovf.pdf /tmp/_pp.bak
