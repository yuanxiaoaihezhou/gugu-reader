#!/bin/bash

set -e

cd "$(dirname "$0")"

READER_FONT_STYLES=("Regular" "Italic" "Bold" "BoldItalic")
NOTOSERIF_FONT_SIZES=(12 14 16 18)
NOTOSANS_FONT_SIZES=(12 14 16 18)
OPENDYSLEXIC_FONT_SIZES=(8 10 12 14)

for size in ${NOTOSERIF_FONT_SIZES[@]}; do
  for style in ${READER_FONT_STYLES[@]}; do
    font_name="notoserif_${size}_$(echo $style | tr '[:upper:]' '[:lower:]')"
    font_path="../builtinFonts/source/NotoSerif/NotoSerif-${style}.ttf"
    output_path="../builtinFonts/${font_name}.h"
    python fontconvert.py $font_name $size $font_path --2bit --compress --pnum > $output_path
    echo "Generated $output_path"
  done
done

for size in ${NOTOSANS_FONT_SIZES[@]}; do
  for style in ${READER_FONT_STYLES[@]}; do
    font_name="notosans_${size}_$(echo $style | tr '[:upper:]' '[:lower:]')"
    font_path="../builtinFonts/source/NotoSans/NotoSans-${style}.ttf"
    output_path="../builtinFonts/${font_name}.h"
    python fontconvert.py $font_name $size $font_path --2bit --compress --pnum > $output_path
    echo "Generated $output_path"
  done
done

for size in ${OPENDYSLEXIC_FONT_SIZES[@]}; do
  for style in ${READER_FONT_STYLES[@]}; do
    font_name="opendyslexic_${size}_$(echo $style | tr '[:upper:]' '[:lower:]')"
    font_path="../builtinFonts/source/OpenDyslexic/OpenDyslexic-${style}.otf"
    output_path="../builtinFonts/${font_name}.h"
    python fontconvert.py $font_name $size $font_path --2bit --compress > $output_path
    echo "Generated $output_path"
  done
done

UI_FONT_SIZES=(10 12)
UI_FONT_STYLES=("Regular" "Bold")

# CJK (Simplified Chinese) UI support:
# The UI fonts must include the ~330 unique CJK codepoints used by the Chinese
# translation (lib/I18n/translations/chinese_simplified.yaml).
#
# To regenerate with CJK support, extract NotoSansCJK SC from the system TTC:
#   python3 -c "
#   from fontTools.ttLib import TTCollection
#   ttc = TTCollection('/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc')
#   ttc.fonts[2].save('NotoSansCJKSC-Regular.ttf')   # index 2 = SC (Simplified)
#   ttc = TTCollection('/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc')
#   ttc.fonts[2].save('NotoSansCJKSC-Bold.ttf')
#   "
# Then regenerate with the --additional-intervals flags for all CJK codepoints
# found by running:
#   python3 scripts/gen_i18n.py --dump-charset ZH
# or extract them from chinese_simplified.yaml manually.
# The NotoSansCJKSC-*.ttf files are NOT committed (too large); only the
# generated .h files are tracked.
#
# If the CJK source font is available alongside the Ubuntu source fonts,
# the CJK_FONT_AVAILABLE flag below enables CJK generation automatically.
CJK_FONT_DIR="$(dirname "$0")/../builtinFonts/source/NotoSansCJKSC"
CJK_REGULAR="${CJK_FONT_DIR}/NotoSansCJKSC-Regular.ttf"
CJK_BOLD="${CJK_FONT_DIR}/NotoSansCJKSC-Bold.ttf"
CJK_INTERVALS="$(cat "$(dirname "$0")/cjk_ui_intervals.txt" 2>/dev/null || true)"

for size in ${UI_FONT_SIZES[@]}; do
  for style in ${UI_FONT_STYLES[@]}; do
    font_name="ubuntu_${size}_$(echo $style | tr '[:upper:]' '[:lower:]')"
    font_path="../builtinFonts/source/Ubuntu/Ubuntu-${style}.ttf"
    output_path="../builtinFonts/${font_name}.h"
    if [ "$style" = "Regular" ] && [ -f "$CJK_REGULAR" ] && [ -n "$CJK_INTERVALS" ]; then
      eval python fontconvert.py $font_name $size $font_path "$CJK_REGULAR" $CJK_INTERVALS > $output_path
    elif [ "$style" = "Bold" ] && [ -f "$CJK_BOLD" ] && [ -n "$CJK_INTERVALS" ]; then
      eval python fontconvert.py $font_name $size $font_path "$CJK_BOLD" $CJK_INTERVALS > $output_path
    else
      python fontconvert.py $font_name $size $font_path > $output_path
    fi
    echo "Generated $output_path"
  done
done

python fontconvert.py notosans_8_regular 8 ../builtinFonts/source/NotoSans/NotoSans-Regular.ttf > ../builtinFonts/notosans_8_regular.h

echo ""
echo "Running compression verification..."
python verify_compression.py ../builtinFonts/
