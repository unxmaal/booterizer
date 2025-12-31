#!/bin/bash
# fetch-media.sh - Download IRIX installation media
#
# Downloads IRIX installation files from the SGI archive mirror
# and extracts them into the correct directory structure.
#
# Usage:
#   ./fetch-media.sh [options]
#
# Options:
#   -v, --version   IRIX version: 6.5.30 (default), 6.5.22
#   -p, --preset    Download preset: minimal, standard (default), full
#   -m, --mirror    Mirror URL (default: https://sgi-irix.s3.amazonaws.com)
#   -d, --dest      Destination directory (default: /srv/irix)
#   -h, --help      Show this help message
#
# Presets:
#   minimal   - Only overlay disc1 and foundation disc1 (enough to boot and partition)
#   standard  - Overlay discs 1-3, apps, foundation discs 1-2, NFS
#   full      - Standard + development tools + extras

set -e

# Defaults
IRIX_VERSION="6.5.30"
PRESET="standard"
MIRROR="https://sgi-irix.s3.amazonaws.com"
DEST="/srv/irix"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
header() { echo -e "\n${BLUE}=== $1 ===${NC}"; }

usage() {
    head -30 "$0" | grep -E "^#" | sed 's/^# //' | sed 's/^#//'
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version) IRIX_VERSION="$2"; shift 2 ;;
        -p|--preset) PRESET="$2"; shift 2 ;;
        -m|--mirror) MIRROR="$2"; shift 2 ;;
        -d|--dest) DEST="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) log_error "Unknown option: $1"; usage ;;
    esac
done

# Validate version
case "$IRIX_VERSION" in
    6.5.30|6.5.22) ;;
    *) log_error "Unsupported IRIX version: $IRIX_VERSION (supported: 6.5.30, 6.5.22)"; exit 1 ;;
esac

# Validate preset
case "$PRESET" in
    minimal|standard|full) ;;
    *) log_error "Unknown preset: $PRESET (supported: minimal, standard, full)"; exit 1 ;;
esac

header "IRIX Media Fetch"
echo "Version:     $IRIX_VERSION"
echo "Preset:      $PRESET"
echo "Mirror:      $MIRROR"
echo "Destination: $DEST"
echo ""

# Check for wget or curl
if command -v wget &>/dev/null; then
    DOWNLOADER="wget"
elif command -v curl &>/dev/null; then
    DOWNLOADER="curl"
else
    log_error "Neither wget nor curl found. Please install one."
    exit 1
fi
log_info "Using $DOWNLOADER for downloads"

# Create destination directory
mkdir -p "$DEST"

# Function to download and extract a file
fetch_and_extract() {
    local url="$1"
    local dest_dir="$2"
    local filename
    filename=$(basename "$url")
    local dest_file="${dest_dir}/${filename}"

    mkdir -p "$dest_dir"

    # Check if already extracted (look for dist directory or known file)
    if [[ -d "${dest_dir}/dist" ]] || [[ -f "${dest_dir}/RELEASE.info" ]] || [[ -f "${dest_dir}/CDrelnotes" ]]; then
        log_info "Already extracted: $dest_dir"
        return 0
    fi

    # Download if not present
    if [[ ! -f "$dest_file" ]]; then
        log_info "Downloading: $filename"
        if [[ "$DOWNLOADER" == "wget" ]]; then
            wget -c -q --show-progress -O "$dest_file" "$url" || {
                log_error "Failed to download: $url"
                rm -f "$dest_file"
                return 1
            }
        else
            curl -L -C - -# -o "$dest_file" "$url" || {
                log_error "Failed to download: $url"
                rm -f "$dest_file"
                return 1
            }
        fi
    else
        log_info "Already downloaded: $filename"
    fi

    # Extract
    log_info "Extracting: $filename"
    if [[ "$filename" == *.tar.gz ]] || [[ "$filename" == *.tgz ]]; then
        tar -xzf "$dest_file" -C "$dest_dir" --strip-components=1
    elif [[ "$filename" == *.tar ]]; then
        tar -xf "$dest_file" -C "$dest_dir" --strip-components=1
    else
        log_error "Unknown archive format: $filename"
        return 1
    fi

    # Optionally remove archive to save space
    # rm -f "$dest_file"

    log_info "Extracted: $dest_dir"
}

# Define URLs based on version
FOUNDATION_BASE="${MIRROR}/irix-6.5/network-installs"
OVERLAY_BASE="${MIRROR}/irix-6.5/network-installs/irix-${IRIX_VERSION}"
DEVEL_BASE="${MIRROR}/development/mipspro-74"
EXTRAS_BASE="${MIRROR}/extras"

# Track what to download based on preset
declare -a DOWNLOADS

# Minimal preset: just enough to boot and partition
add_minimal() {
    DOWNLOADS+=(
        "${OVERLAY_BASE}/disc1.tar.gz|${DEST}/${IRIX_VERSION}/Overlay/disc1"
        "${FOUNDATION_BASE}/foundation1.tar.gz|${DEST}/Foundation/disc1"
    )
}

# Standard preset: full OS installation
add_standard() {
    add_minimal
    DOWNLOADS+=(
        "${OVERLAY_BASE}/disc2.tar.gz|${DEST}/${IRIX_VERSION}/Overlay/disc2"
        "${OVERLAY_BASE}/disc3.tar.gz|${DEST}/${IRIX_VERSION}/Overlay/disc3"
        "${OVERLAY_BASE}/apps.tar.gz|${DEST}/${IRIX_VERSION}/Overlay/apps"
        "${FOUNDATION_BASE}/foundation2.tar.gz|${DEST}/Foundation/disc2"
        "${FOUNDATION_BASE}/onc3nfs.tar.gz|${DEST}/Foundation/nfs"
    )
    # capps only exists for 6.5.30
    if [[ "$IRIX_VERSION" == "6.5.30" ]]; then
        DOWNLOADS+=("${OVERLAY_BASE}/capps.tar.gz|${DEST}/${IRIX_VERSION}/Overlay/capps")
    fi
}

# Full preset: everything including development tools
add_full() {
    add_standard
    DOWNLOADS+=(
        "${DEVEL_BASE}/developmentlibraries.tar.gz|${DEST}/Development/devlibs"
        "${DEVEL_BASE}/devf_13.tar.gz|${DEST}/Development/devfoundations"
        "${DEVEL_BASE}/mipspro-7.4.3m.tar|${DEST}/Development/mipspro"
        "${DEVEL_BASE}/mipspro744update.tar.gz|${DEST}/Development/mipspro_update"
        "${DEVEL_BASE}/mipspro_c.tar.gz|${DEST}/Development/mipspro_c"
        "${DEVEL_BASE}/mipspro_cee.tar.gz|${DEST}/Development/mipspro_cee"
        "${DEVEL_BASE}/mipspro_cpp.tar.gz|${DEST}/Development/mipspro_cpp"
        "${DEVEL_BASE}/mipsproap.tar.gz|${DEST}/Development/mipspro_ap"
        "${DEVEL_BASE}/prodev.tar.gz|${DEST}/Development/prodev"
        "${EXTRAS_BASE}/perfcopilot.tar.gz|${DEST}/Extras/perfcopilot"
        "${EXTRAS_BASE}/sgipostscriptfonts.tar.gz|${DEST}/Extras/sgifonts"
    )
}

# Build download list based on preset
case "$PRESET" in
    minimal) add_minimal ;;
    standard) add_standard ;;
    full) add_full ;;
esac

# Show what will be downloaded
header "Download Plan"
echo "Files to download/extract:"
for item in "${DOWNLOADS[@]}"; do
    url="${item%%|*}"
    dest="${item##*|}"
    filename=$(basename "$url")
    echo "  $filename -> $dest"
done
echo ""
echo "Total: ${#DOWNLOADS[@]} archives"
echo ""

# Confirm
read -p "Proceed with download? [Y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    log_warn "Aborted by user"
    exit 0
fi

# Download and extract each file
header "Downloading and Extracting"
FAILED=0
for item in "${DOWNLOADS[@]}"; do
    url="${item%%|*}"
    dest="${item##*|}"

    fetch_and_extract "$url" "$dest" || ((FAILED++))
done

# Generate selections file
header "Generating Selections File"
SELECTIONS_FILE="${DEST}/selections"
echo "# Auto-generated list of installation sources" > "$SELECTIONS_FILE"
echo "# Generated by fetch-media.sh on $(date)" >> "$SELECTIONS_FILE"
echo "# Load in inst with: Admin > load booterizer:selections" >> "$SELECTIONS_FILE"
echo "" >> "$SELECTIONS_FILE"

# Find all dist directories
DIST_COUNT=0
find "$DEST" -type d -name "dist" 2>/dev/null | sort | while read -r distdir; do
    # Convert to path relative to DEST, with leading /
    relpath="${distdir#$DEST}"
    echo "from booterizer:${relpath}" >> "$SELECTIONS_FILE"
    ((DIST_COUNT++)) || true
done

DIST_COUNT=$(grep -c "^from" "$SELECTIONS_FILE" || echo 0)
log_info "Generated selections file with $DIST_COUNT sources"

# Generate commands file
header "Generating Commands File"
COMMANDS_FILE="${DEST}/commands"
cat > "$COMMANDS_FILE" << 'EOF'
# Automated inst commands
# Generated by fetch-media.sh
# Source in inst with: Admin > source booterizer:commands
return
keep *
install standard
keep incompleteoverlays
conflicts
go
EOF
log_info "Generated commands file"

# Summary
header "Summary"
if [[ $FAILED -eq 0 ]]; then
    log_info "All downloads completed successfully!"
else
    log_warn "$FAILED downloads failed"
fi

echo ""
echo "Media directory: $DEST"
echo "Dist directories found: $DIST_COUNT"
echo ""
echo "Boot images:"
ls -la "${DEST}/${IRIX_VERSION}/Overlay/disc1/stand/fx"* 2>/dev/null | sed 's/^/  /' || echo "  (not found)"
echo ""
echo "Next steps:"
echo "  1. Start the container:"
echo "     SGI_MAC=08:00:69:xx:xx:xx docker-compose up -d"
echo ""
echo "  2. On SGI PROM:"
echo "     setenv netaddr 172.16.42.2"
echo "     bootp():/${IRIX_VERSION}/Overlay/disc1/stand/fx.64"
