#!/usr/bin/env bash
# Gera todos os ícones do app a partir de branding/glyph.svg.
# Requer rsvg-convert (librsvg). Uso: tool/gen_icons.sh
set -euo pipefail
cd "$(dirname "$0")/.."

BG='#00796B' # mesma semente do tema (lib/app/theme.dart)
GLYPH=$(sed -n '/<g /,/<\/svg>/p' branding/glyph.svg | sed '$d')
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Ícone cheio (iOS e asset do app): fundo sem cantos, o sistema arredonda.
cat > "$TMP/full.svg" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" viewBox="12 12 84 84">
  <rect x="0" y="0" width="108" height="108" fill="$BG"/>
$GLYPH
</svg>
SVG
# Ícone legado do Android (antes do 8.0): quadrado arredondado.
cat > "$TMP/legacy.svg" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" viewBox="18 18 72 72">
  <rect x="20" y="20" width="68" height="68" rx="15" fill="$BG"/>
$GLYPH
</svg>
SVG
# Notificação: só o símbolo, ocupando o quadro.
sed 's/viewBox="0 0 108 108"/viewBox="22 22 64 64"/' branding/glyph.svg > "$TMP/notif.svg"

png() { rsvg-convert -w "$2" -h "$2" "$1" -o "$3"; }
RES=android/app/src/main/res
for pair in mdpi:1 hdpi:1.5 xhdpi:2 xxhdpi:3 xxxhdpi:4; do
  d=${pair%%:*}; s=${pair##*:}
  px() { python3 -c "print(round($1*$s))"; }
  mkdir -p "$RES/mipmap-$d" "$RES/drawable-$d"
  png "$TMP/legacy.svg" "$(px 48)" "$RES/mipmap-$d/ic_launcher.png"
  png branding/glyph.svg "$(px 108)" "$RES/mipmap-$d/ic_launcher_foreground.png"
  png "$TMP/notif.svg" "$(px 24)" "$RES/drawable-$d/ic_notification.png"
done

IOS=ios/Runner/Assets.xcassets/AppIcon.appiconset
for f in "$IOS"/Icon-App-*.png; do
  name=$(basename "$f" .png)            # Icon-App-83.5x83.5@2x
  size=${name#Icon-App-}; size=${size%%x*}
  scale=${name##*@}; scale=${scale%x}
  # iOS não aceita transparência: achata sobre o fundo.
  rsvg-convert -w "$(python3 -c "print(round($size*$scale))")" -b "$BG" "$TMP/full.svg" -o "$f"
done

mkdir -p assets/branding
png "$TMP/full.svg" 256 assets/branding/logo.png
echo "Ícones gerados."
