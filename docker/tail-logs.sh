#!/bin/bash
# tail-logs.sh - Follow booterizer service logs
#
# Usage: ./tail-logs.sh [service]
#
# Services: all (default), dhcp, tftp, xinetd, supervisor
#
# Examples:
#   ./tail-logs.sh          # All logs
#   ./tail-logs.sh dhcp     # DHCP logs only
#   ./tail-logs.sh tftp     # TFTP logs only

CONTAINER="booterizer"
SERVICE="${1:-all}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
    echo -e "${RED}[ERR]${NC} Container '$CONTAINER' is not running"
    echo ""
    echo "Start it with: docker-compose up -d"
    exit 1
fi

case "$SERVICE" in
    dhcp)
        echo -e "${BLUE}=== Following DHCP logs (Ctrl+C to stop) ===${NC}"
        docker exec "$CONTAINER" tail -f /var/log/supervisor/dhcpd.log /var/log/supervisor/dhcpd.err 2>/dev/null
        ;;
    tftp)
        echo -e "${BLUE}=== Following TFTP logs (Ctrl+C to stop) ===${NC}"
        docker exec "$CONTAINER" tail -f /var/log/supervisor/tftpd.log /var/log/supervisor/tftpd.err 2>/dev/null
        ;;
    xinetd|rsh)
        echo -e "${BLUE}=== Following xinetd/RSH logs (Ctrl+C to stop) ===${NC}"
        docker exec "$CONTAINER" tail -f /var/log/supervisor/xinetd.log /var/log/supervisor/xinetd.err 2>/dev/null
        ;;
    supervisor)
        echo -e "${BLUE}=== Following supervisord logs (Ctrl+C to stop) ===${NC}"
        docker exec "$CONTAINER" tail -f /var/log/supervisor/supervisord.log 2>/dev/null
        ;;
    all)
        echo -e "${BLUE}=== Following all logs (Ctrl+C to stop) ===${NC}"
        echo -e "${YELLOW}Tip: Use './tail-logs.sh dhcp' for just DHCP logs${NC}"
        echo ""
        docker exec "$CONTAINER" tail -f \
            /var/log/supervisor/dhcpd.log \
            /var/log/supervisor/dhcpd.err \
            /var/log/supervisor/tftpd.log \
            /var/log/supervisor/tftpd.err \
            /var/log/supervisor/xinetd.log \
            /var/log/supervisor/xinetd.err \
            2>/dev/null
        ;;
    *)
        echo "Usage: $0 [service]"
        echo ""
        echo "Services:"
        echo "  all        - All logs (default)"
        echo "  dhcp       - DHCP server logs"
        echo "  tftp       - TFTP server logs"
        echo "  xinetd     - xinetd/RSH logs"
        echo "  supervisor - supervisord logs"
        exit 1
        ;;
esac
