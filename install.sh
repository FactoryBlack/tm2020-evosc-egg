#!/bin/bash
set -euo pipefail

# Trackmania 2020 + EvoSC Installation Script
# For Pterodactyl/Pelican Panel

echo ">>> [$(date)] Starting Trackmania 2020 + EvoSC installation..."

# Update packages
echo ">>> Updating packages..."
apk update && apk upgrade

# Create directory structure
echo ">>> Creating directory structure..."
mkdir -p logs backups tmp server EvoSC
chmod 750 logs backups tmp

# Download Trackmania Server
echo ">>> Downloading Trackmania Server..."
curl -sSL -o TrackmaniaServer.zip "http://files.v04.maniaplanet.com/server/TrackmaniaServer_Latest.zip"

# Extract Trackmania Server
echo ">>> Extracting Trackmania Server..."
unzip -q -o TrackmaniaServer.zip -d server
rm TrackmaniaServer.zip

# Setup Trackmania server
echo ">>> Setting up Trackmania server..."
cd server
chmod +x TrackmaniaServer
rm -f TrackmaniaServer.exe

# Move default config (let Pelican handle variable substitution)
mv UserData/Config/dedicated_cfg.default.txt UserData/Config/dedicated_cfg.txt || true

# Create basic tracklist
echo ">>> Creating default tracklist..."
cat > UserData/Maps/MatchSettings/tracklist.txt << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<playlist>
    <gameinfos>
        <game_mode>0</game_mode>
        <chat_time>10000</chat_time>
        <finishtimeout>1</finishtimeout>
        <rounds_pointslimit>30</rounds_pointslimit>
        <timeattack_limit>300000</timeattack_limit>
        <laps_nblaps>3</laps_nblaps>
    </gameinfos>
    
    <filter>
        <is_lan_mode>false</is_lan_mode>
        <is_internet_mode>true</is_internet_mode>
        <is_solo_mode>false</is_solo_mode>
        <sort_index>1000</sort_index>
        <random_map_order>false</random_map_order>
    </filter>
</playlist>
EOF

chmod 640 UserData/Maps/MatchSettings/tracklist.txt

cd ..

# Install EvoSC
echo ">>> Installing EvoSC..."
git clone --depth 1 --branch master https://github.com/EvoTM/EvoSC.git
cd EvoSC
composer install --no-dev --no-interaction --optimize-autoloader --ignore-platform-reqs

# Create required directories
mkdir -p logs cache config

# Create default configs (Pelican will handle substitution)
cat > config/database.config.json << 'EOF'
{
    "host": "localhost",
    "db": "evosc",
    "user": "root",
    "password": "",
    "prefix": "evosc_"
}
EOF

cat > config/server.config.json << 'EOF'
{
    "ip": "localhost",
    "port": "5000",
    "rpc": {
        "login": "SuperAdmin",
        "password": "SuperAdmin"
    },
    "default-matchsettings": "tracklist.txt"
}
EOF

chmod 640 config/*.json
chmod 755 logs cache

cd ..

# Create startup script
echo ">>> Creating startup script..."
cat > start.sh << 'EOF'
#!/bin/bash
set -euo pipefail

# ANSI Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Banner
show_banner() {
    echo -e "${CYAN}"
    cat << 'BANNER'
    ____  ___________________    ___________   _____ 
   / __ \/ ____/ ___/_  __/ /   / ____/ ___/  / ___/
  / /_/ / __/  \__ \ / / / /   / __/  \__ \   \__ \ 
 / _, _/ /___ ___/ // / / /___/ /___ ___/ /  ___/ / 
/_/ |_/_____//____//_/ /_____/_____//____/  /____/  
                                                    
BANNER
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════╗"
    echo -e "║              ${YELLOW}Trackmania 2020 + EvoSC Server${WHITE}                ║"
    echo -e "║                    ${CYAN}Production Ready${WHITE}                        ║"
    echo -e "╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Create required directories
mkdir -p logs backups tmp

# Logging functions
log() {
    echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $*" | tee -a logs/server.log
}

log_success() {
    echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ${GREEN}✓${NC} $*" | tee -a logs/server.log
}

log_warning() {
    echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ${YELLOW}⚠${NC} $*" | tee -a logs/server.log
}

log_error() {
    echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ${RED}✗${NC} $*" | tee -a logs/server.log
}

# Validate environment
validate_env() {
    local required_vars=("SERVER_NAME" "RPC_PORT")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        echo -e "${RED}ERROR: Missing required environment variables:${NC}"
        printf "${RED}  - %s${NC}\n" "${missing_vars[@]}"
        exit 1
    fi
}

# Start EvoSC when Trackmania is ready
start_evosc_when_ready() {
    log "Starting EvoSC monitor..."
    
    local max_attempts=60
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if ss -tuln | grep -q ":${RPC_PORT} "; then
            log_success "Trackmania RPC ready, starting EvoSC..."
            cd EvoSC
            php esc run --no-logo &>/dev/null &
            EVOSC_PID=$!
            log_success "EvoSC started with PID: $EVOSC_PID"
            cd ..
            return 0
        fi
        sleep 1
        ((attempt++))
    done
    
    log_warning "Trackmania RPC not ready after $max_attempts seconds"
    return 1
}

# Console handler
handle_console() {
    log "Console handler ready. Type ${YELLOW}!help${NC} for commands."
    
    while IFS= read -r input; do
        case "$input" in
            "!stop"|"stop"|"quit"|"exit")
                log "Received ${RED}stop${NC} command - shutting down gracefully"
                cleanup
                exit 0
                ;;
            "!status"|"status")
                show_status
                ;;
            "!logs")
                echo -e "${YELLOW}=== Recent Server Logs ===${NC}"
                tail -n 20 logs/server.log 2>/dev/null || echo "No logs available"
                ;;
            "!help")
                show_help
                ;;
            *)
                log "Command: ${CYAN}$input${NC}"
                ;;
        esac
    done
}

# Show status
show_status() {
    echo -e "${YELLOW}╔══════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║            Server Status             ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════╝${NC}"
    
    if pgrep -f "TrackmaniaServer" >/dev/null; then
        echo -e "Trackmania: ${GREEN}●${NC} ${WHITE}RUNNING${NC} (PID: $(pgrep -f TrackmaniaServer))"
    else
        echo -e "Trackmania: ${RED}●${NC} ${WHITE}STOPPED${NC}"
    fi
    
    if [[ -n "${EVOSC_PID:-}" ]] && kill -0 "$EVOSC_PID" 2>/dev/null; then
        echo -e "EvoSC:      ${GREEN}●${NC} ${WHITE}RUNNING${NC} (PID: $EVOSC_PID)"
    else
        echo -e "EvoSC:      ${RED}●${NC} ${WHITE}STOPPED${NC}"
    fi
    echo ""
}

# Show help
show_help() {
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║                    Console Commands                          ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${GREEN}!stop${NC}, ${GREEN}stop${NC}, ${GREEN}quit${NC}, ${GREEN}exit${NC}  - Stop server gracefully"
    echo -e "${GREEN}!status${NC}, ${GREEN}status${NC}          - Show service status"
    echo -e "${GREEN}!logs${NC}                    - Show recent server logs"
    echo -e "${GREEN}!help${NC}                    - Show this help"
    echo ""
}

# Cleanup
cleanup() {
    log "Shutting down services..."
    
    if [[ -n "${EVOSC_PID:-}" ]]; then
        kill -TERM "$EVOSC_PID" 2>/dev/null || true
        sleep 2
        kill -KILL "$EVOSC_PID" 2>/dev/null || true
    fi
    
    if [[ -n "${CONSOLE_PID:-}" ]]; then
        kill -TERM "$CONSOLE_PID" 2>/dev/null || true
    fi
    
    log_success "Cleanup complete"
}

# Signal handling
trap cleanup SIGTERM SIGINT

# Main execution
main() {
    show_banner
    validate_env
    
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║                    Server Information                        ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
    log "Server: ${GREEN}${SERVER_NAME}${NC}"
    log "Players: ${GREEN}${MAX_PLAYER:-32}${NC}"
    log "RPC Port: ${GREEN}${RPC_PORT}${NC}"
    echo ""
    
    # Start console handler in background
    handle_console &
    CONSOLE_PID=$!
    
    # Start EvoSC monitor in background
    start_evosc_when_ready &
    
    # Start Trackmania in foreground
    log "Starting Trackmania server..."
    cd server
    exec ./TrackmaniaServer \
        /title=Trackmania \
        /game_Settings=MatchSettings/${DEFAULT_MATCHSETTINGS:-tracklist.txt} \
        /dedicated_cfg=dedicated_cfg.txt \
        /nodaemon
}

main "$@"
EOF

chmod +x start.sh

# Set file permissions
echo ">>> Setting file permissions..."
find . -type f -name "*.sh" -exec chmod 750 {} \;
find . -type f -name "*.json" -exec chmod 640 {} \; 2>/dev/null || true

echo ">>> Installation completed successfully!"
echo ">>> ✓ Trackmania 2020 server installed"
echo ">>> ✓ EvoSC controller installed"
echo ">>> ✓ Production-ready startup script created"
echo ">>> ✓ Unified console with colorful commands"
echo ""
echo ">>> Server ready to start!"

exit 0
