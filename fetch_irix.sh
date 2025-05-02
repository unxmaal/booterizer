#!/bin/bash
set -xeuo pipefail

# Paths to config files
SETTINGS_FILE="settings.yml"
IRIX_VERSION=$(yq eval '.booterizer.irixversion' "$SETTINGS_FILE")
VERSION_FILE="irix.${IRIX_VERSION}.yml"
INSTALL_MIRROR=$(yq eval '.booterizer.installmirror' "$SETTINGS_FILE")

# Fetch baseurls
OVERLAY_BASEURL=$(yq eval '.ftpurls.overlay.baseurl' "$VERSION_FILE" | sed "s|{{ installmirror }}|$INSTALL_MIRROR|g")
FOUNDATION_BASEURL=$(yq eval '.ftpurls.foundation.baseurl' "$VERSION_FILE" | sed "s|{{ installmirror }}|$INSTALL_MIRROR|g")
DEVEL_BASEURL=$(yq eval '.ftpurls.devel.baseurl' "$VERSION_FILE" | sed "s|{{ installmirror }}|$INSTALL_MIRROR|g")
EXTRAS_BASEURL=$(yq eval '.ftpurls.extras.baseurl' "$VERSION_FILE" | sed "s|{{ installmirror }}|$INSTALL_MIRROR|g")

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
    case "$filename" in
      *.tar.gz)
        echo "Extracting .tar.gz: $filename"
        tar -xzf "$target_path" -C "$dest" --strip-components=1
        ;;
      *.tar)
        echo "Extracting .tar: $filename"
        tar -xf "$target_path" -C "$dest" --strip-components=1
        ;;
      *)
        echo "Skipping extraction for unsupported file: $filename"
        ;;
    esac
  else
    echo "Already extracted: $filename"
  fi
}

# Overlay set
download_overlay_discs() {
  declare -A overlay_discs=(
    [disc1]="$(yq eval '.ftpurls.overlay.disc1' "$VERSION_FILE")"
    [disc2]="$(yq eval '.ftpurls.overlay.disc2' "$VERSION_FILE")"
    [disc3]="$(yq eval '.ftpurls.overlay.disc3' "$VERSION_FILE")"
    [apps]="$(yq eval '.ftpurls.overlay.apps' "$VERSION_FILE")"
    [capps]="$(yq eval '.ftpurls.overlay.capps' "$VERSION_FILE")"
  )

  for key in "${!overlay_discs[@]}"; do
    local file="${overlay_discs[$key]}"
    local dest="/srv/irix/${IRIX_VERSION}/Overlay/${key}"
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
    [disc1]="$(yq eval '.ftpurls.foundation.disc1' "$VERSION_FILE")"
    [disc2]="$(yq eval '.ftpurls.foundation.disc2' "$VERSION_FILE")"
    [nfs]="$(yq eval '.ftpurls.foundation.nfs' "$VERSION_FILE")"
  )
  for key in "${!foundation_discs[@]}"; do
    local file="${foundation_discs[$key]}"
    local dest="/srv/irix/Foundation/${key}"
    local marker="RELEASE.info"
    download_and_extract "$FOUNDATION_BASEURL" "$file" "$dest" "$marker"
  done
}

# Development set
download_development_tools() {
  for key in devlibs devfoundations mipspro update c cee cpp ap prodev; do
    local file="$(yq eval ".ftpurls.devel.${key}" "$VERSION_FILE")"
    local subdir="$key"
    [[ "$key" == "devlibs" ]] && subdir="devlibs"
    local dest="/srv/irix/Development/${subdir}"
    local marker="CDrelnotes"
    [[ "$key" == "devlibs" ]] && marker="RELEASE.info"
    [[ "$key" == "update" ]] && marker="inst.README"
    download_and_extract "$DEVEL_BASEURL" "$file" "$dest" "$marker"
  done
}

# Extras
download_extras() {
  for key in perfcopilot sgifonts; do
    local file="$(yq eval ".ftpurls.extras.${key}" "$VERSION_FILE")"
    local dest="/srv/irix/Extras/${key}"
    local marker="CDrelnotes"
    [[ "$key" == "sgifonts" ]] && marker="Text/SGI-Text.ttf"
    download_and_extract "$EXTRAS_BASEURL" "$file" "$dest" "$marker"
  done
}

# Entry point
download_overlay_discs
download_foundation_discs
download_development_tools
download_extras

echo "All IRIX media downloaded and extracted."
