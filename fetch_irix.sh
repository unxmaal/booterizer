#!/bin/bash
set -xeuo pipefail

# Paths to config files
SETTINGS_FILE="settings.yml"
IRIX_VERSION=$(yq '.booterizer.irixversion' "$SETTINGS_FILE")
VERSION_FILE="irix.${IRIX_VERSION}.yml"
INSTALL_MIRROR=$(yq '.booterizer.installmirror' "$SETTINGS_FILE")

# Fetch baseurls
OVERLAY_BASEURL=$(yq '.ftpurls.overlay.baseurl' "$VERSION_FILE" | sed "s|{{ installmirror }}|$INSTALL_MIRROR|g")
FOUNDATION_BASEURL=$(yq '.ftpurls.foundation.baseurl' "$VERSION_FILE" | sed "s|{{ installmirror }}|$INSTALL_MIRROR|g")
DEVEL_BASEURL=$(yq '.ftpurls.devel.baseurl' "$VERSION_FILE" | sed "s|{{ installmirror }}|$INSTALL_MIRROR|g")
EXTRAS_BASEURL=$(yq '.ftpurls.extras.baseurl' "$VERSION_FILE" | sed "s|{{ installmirror }}|$INSTALL_MIRROR|g")

# Generic download + extract function
download_and_extract() {
  local baseurl="$1"
  local filename="$2"
  local dest="$3"
  local marker="$4"

  local url="${baseurl}${filename}"
  local target_path="${dest}/${filename}"

  mkdir -p "$dest"

  if [ ! -f "$target_path" ]; then
    echo "Downloading: $filename"
    curl -fL "$url" -o "$target_path"
  else
    echo "Already downloaded: $filename"
  fi

  if [ ! -e "$dest/$marker" ]; then
    echo "Extracting: $filename"
    tar -xzf "$target_path" -C "$dest" --strip-components=1
  else
    echo "Already extracted: $filename"
  fi
}

# Overlay set
download_overlay_discs() {
  declare -A overlay_discs=(
    [disc1]="$(yq '.ftpurls.overlay.disc1' "$VERSION_FILE")"
    [disc2]="$(yq '.ftpurls.overlay.disc2' "$VERSION_FILE")"
    [disc3]="$(yq '.ftpurls.overlay.disc3' "$VERSION_FILE")"
    [apps]="$(yq '.ftpurls.overlay.apps' "$VERSION_FILE")"
    [capps]="$(yq '.ftpurls.overlay.capps' "$VERSION_FILE")"
  )

  for key in "${!overlay_discs[@]}"; do
    local file="${overlay_discs[$key]}"
    local dest="/irix/${IRIX_VERSION}/Overlay/${key}"
    local marker="CDrelnotes"
    [[ "$key" == "disc1" ]] && marker="stand/fx.ARCS"

    if [[ "$key" != "capps" || "$IRIX_VERSION" == "6.5.30" ]]; then
      download_and_extract "$OVERLAY_BASEURL" "$file" "$dest" "$marker"
    fi
  done
}

# Foundation set
download_foundation_discs() {
  declare -A foundation_discs=(
    [disc1]="$(yq '.ftpurls.foundation.disc1' "$VERSION_FILE")"
    [disc2]="$(yq '.ftpurls.foundation.disc2' "$VERSION_FILE")"
    [nfs]="$(yq '.ftpurls.foundation.nfs' "$VERSION_FILE")"
  )
  for key in "${!foundation_discs[@]}"; do
    local file="${foundation_discs[$key]}"
    local dest="/irix/Foundation/${key}"
    local marker="RELEASE.info"
    download_and_extract "$FOUNDATION_BASEURL" "$file" "$dest" "$marker"
  done
}

# Development set
download_development_tools() {
  for key in devlibs devfoundations mipspro update c cee cpp ap prodev; do
    local file="$(yq ".ftpurls.devel.${key}" "$VERSION_FILE")"
    local subdir="$key"
    [[ "$key" == "devlibs" ]] && subdir="devlibs"
    local dest="/irix/Development/${subdir}"
    local marker="CDrelnotes"
    [[ "$key" == "devlibs" ]] && marker="RELEASE.info"
    [[ "$key" == "update" ]] && marker="inst.README"
    download_and_extract "$DEVEL_BASEURL" "$file" "$dest" "$marker"
  done
}

# Extras
download_extras() {
  for key in perfcopilot sgifonts; do
    local file="$(yq ".ftpurls.extras.${key}" "$VERSION_FILE")"
    local dest="/irix/Extras/${key}"
    local marker="CDrelnotes"
    [[ "$key" == "sgifonts" ]] && marker="Text/SGI-Text.ttf"
    download_and_extract "$EXTRAS_BASEURL" "$file" "$dest" "$marker"
  done
}

main(){
    download_overlay_discs
    download_foundation_discs
    download_development_tools
    download_extras

    echo "All IRIX media downloaded and extracted."
}

main