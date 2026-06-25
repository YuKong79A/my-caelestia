#!/usr/bin/env bash
set -euo pipefail

icons_dir="${XDG_DATA_HOME:-$HOME/.local/share}/icons"
source_theme="${CAELESTIA_PAPIRUS_SOURCE:-/usr/share/icons/Papirus-Dark}"
theme_name="${CAELESTIA_ICON_THEME:-Papirus-caelestia-dark}"
theme_dir="$icons_dir/$theme_name"
stamp_file="$theme_dir/.caelestia-accent"
template_version="4"
version_file="$theme_dir/.caelestia-template-version"
gtk3_css="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/gtk.css"
gtk4_css="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0/gtk.css"

accent=""
accent_fg=""
for css in "$gtk3_css" "$gtk4_css"; do
  if [[ -r "$css" ]]; then
    accent="$(sed -nE 's/^@define-color[[:space:]]+accent_color[[:space:]]+(#[0-9A-Fa-f]{6});/\1/p' "$css" | head -n 1)"
    accent_fg="$(sed -nE 's/^@define-color[[:space:]]+accent_fg_color[[:space:]]+(#[0-9A-Fa-f]{6});/\1/p' "$css" | head -n 1)"
    [[ -n "$accent" ]] && break
  fi
done

if [[ ! "$accent" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
  echo "sync-papirus-icons: could not read accent_color from GTK css" >&2
  exit 1
fi

if [[ ! "$accent_fg" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
  accent_fg="#ffffff"
fi

if [[ ! -d "$source_theme" ]]; then
  echo "sync-papirus-icons: missing source theme $source_theme" >&2
  exit 1
fi

dark_accent="$(
  ACCENT="$accent" perl -e '
    my $hex = $ENV{ACCENT};
    $hex =~ s/^#//;
    my @rgb = map { hex($_) } ($hex =~ /(..)(..)(..)/);
    printf "#%02x%02x%02x\n", map { int($_ * 0.78 + 0.5) } @rgb;
  '
)"

if [[ -r "$stamp_file" ]] && [[ -r "$version_file" ]] && [[ "$(cat "$stamp_file")" == "$accent" ]] && [[ "$(cat "$version_file")" == "$template_version" ]]; then
  exit 0
fi

rm -rf "$theme_dir"
mkdir -p "$theme_dir"

printf '%s\n' \
  '[Icon Theme]' \
  'Name=Papirus Caelestia Dark' \
  'Comment=Papirus-Dark core folder icons colored by Caelestia' \
  'Inherits=Papirus-Dark,breeze-dark,hicolor' \
  'Example=folder' \
  'FollowsColorScheme=true' \
  '' > "$theme_dir/index.theme"

directories=()

icon_names=(
  desktop.svg
  folder.svg
  folder-blue.svg
  folder-blue-open.svg
  folder-desktop.svg
  folder-documents.svg
  folder-download.svg
  folder-music.svg
  folder-open.svg
  folder-pictures.svg
  folder-projects.svg
  folder-publicshare.svg
  folder-templates.svg
  folder-video.svg
  folder-videos.svg
  folder-videos-open.svg
  user-desktop.svg
)

find_expr=()
for name in "${icon_names[@]}"; do
  if ((${#find_expr[@]} > 0)); then
    find_expr+=(-o)
  fi
  find_expr+=(-name "$name")
done

while IFS= read -r -d '' file; do
  rel="${file#$source_theme/}"
  rel_dir="${rel%/*}"
  mkdir -p "$theme_dir/$rel_dir"
  cp -L "$file" "$theme_dir/$rel"
  directories+=("$rel_dir")
done < <(find -L "$source_theme" -type f -path '*/places/*' \( "${find_expr[@]}" \) -print0)

mapfile -t directories < <(printf '%s\n' "${directories[@]}" | sort -u)

if ((${#directories[@]} > 0)); then
  IFS=,
  printf 'Directories=%s\n\n' "${directories[*]}" >> "$theme_dir/index.theme"
  unset IFS
fi

for rel in "${directories[@]}"; do
  size="${rel%%x*}"
  if [[ "$size" =~ ^[0-9]+$ ]]; then
    printf '[%s]\nContext=Places\nSize=%s\nType=Fixed\n\n' "$rel" "$size" >> "$theme_dir/index.theme"
  fi
done

printf '%s\n' "$template_version" > "$version_file"

while IFS= read -r -d '' file; do
  ACCENT="$accent" ACCENT_FG="$accent_fg" DARK_ACCENT="$dark_accent" perl -0pi -e '
    s/#(?:5294e2|4285f4|a9cae8)/$ENV{ACCENT}/gi;
    s/#(?:4877b1|849eb5)/$ENV{DARK_ACCENT}/gi;
    s/#1d344f/$ENV{ACCENT_FG}/gi;
    s/(\.ColorScheme-Highlight\s*\{[^}]*?color:)#[0-9A-Fa-f]{6}/$1$ENV{ACCENT}/g;
  ' "$file"
done < <(find "$theme_dir" -type f -name '*.svg' -print0)

printf '%s\n' "$accent" > "$stamp_file"

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -q "$theme_dir" >/dev/null 2>&1 || true
fi

for gtk_dir in "${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0" "${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0"; do
  mkdir -p "$gtk_dir"
  settings="$gtk_dir/settings.ini"
  if [[ -f "$settings" ]]; then
    if grep -q '^gtk-icon-theme-name=' "$settings"; then
      sed -i "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=$theme_name/" "$settings"
    else
      printf '\ngtk-icon-theme-name=%s\n' "$theme_name" >> "$settings"
    fi
  else
    printf '[Settings]\ngtk-icon-theme-name=%s\n' "$theme_name" > "$settings"
  fi
done

if command -v gsettings >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.interface icon-theme "$theme_name" >/dev/null 2>&1 || true
fi
