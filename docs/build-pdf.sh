#!/bin/sh
# EXERCISES.md -> docs/EXERCISES.pdf (A4). Braucht pandoc und Google Chrome (macOS).
set -e
cd "$(dirname "$0")/.."
T=$(mktemp -d)
pandoc EXERCISES.md -f gfm -s --metadata pagetitle="Übungen – gPlug Workshop" -c docs/pdf.css \
  --embed-resources -o "$T/ex.html"
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu \
  --no-pdf-header-footer --print-to-pdf=docs/EXERCISES.pdf "file://$T/ex.html" >/dev/null 2>&1
rm -rf "$T"
echo "docs/EXERCISES.pdf"
