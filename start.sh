#!/bin/bash
set -euo pipefail

# ANSI Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ASCII Art Banner
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
    echo -e "║                ${GRAY}XML FALLBACK HANDLING${WHITE}                       ║"
    echo -e "║                                                              ║"
    echo -e "║  ${GREEN}✓${WHITE} Secure Process Management   ${GREEN}✓${WHITE} Unified Console Control  ║"
    echo -e "║  ${GREEN}✓${WHITE} Pelican XML Parser          ${GREEN}✓${WHITE} Pelican JSON Parser       ║"
    echo -e "║  ${GREEN}✓${WHITE} EvoSC Best Practices        ${GREEN}✓${WHITE} Production Monitoring     ║"
    echo -e "╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Create required directories
mkdir -p logs backups tmp

# Validate environment variables
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

# Enhanced logging functions
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

# CRITICAL: Check if Pelican XML parsing worked, if not, fix it manually
fix_xml_config() {
    log "Checking and fixing XML configuration..."
    
    local config_file="server/UserData/Config/dedicated_cfg.txt"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "dedicated_cfg.txt not found!"
        return 1
    fi
    
    # Check if Pelican did its job by looking for our server name
    if grep -q "${SERVER_NAME}" "$config_file" 2>/dev/null; then
        log_success "Pelican XML parsing worked! Server name found: ${GREEN}${SERVER_NAME}${NC}"
        return 0
    fi
    
    # Check if template variables are still there (Pelican failed)
    if grep -q "{{server.build.env" "$config_file" 2>/dev/null; then
        log_warning "Pelican XML parsing failed - template variables still present"
        log "Applying manual XML configuration as fallback..."
        
        # Manual XML configuration using sed (more reliable than xmlstarlet)
        sed -i "s|<name>.*</name>|<name>${SERVER_NAME}</name>|g" "$config_file"
        sed -i "s|<server_port>.*</server_port>|<server_port>${SERVER_PORT:-2350}</server_port>|g" "$config_file"
        sed -i "s|<xmlrpc_port>.*</xmlrpc_port>|<xmlrpc_port>${RPC_PORT}</xmlrpc_port>|g" "$config_file"
        sed -i "s|<xmlrpc_allowremote>.*</xmlrpc_allowremote>|<xmlrpc_allowremote>True</xmlrpc_allowremote>|g" "$config_file"
        sed -i "s|<max_players>.*</max_players>|<max_players>${MAX_PLAYER:-32}</max_players>|g" "$config_file"
        sed -i "s|<max_spectators>.*</max_spectators>|<max_spectators>${MAX_SPECTATORS:-32}</max_spectators>|g" "$config_file"
        
        # Handle optional fields
        if [[ -n "${FORCE_IP_ADDRESS:-}" ]]; then
            sed -i "s|<force_ip_address>.*</force_ip_address>|<force_ip_address>${FORCE_IP_ADDRESS}</force_ip_address>|g" "$config_file"
        fi
        
        if [[ -n "${MASTER_LOGIN:-}" ]]; then
            sed -i "s|<login>.*</login>|<login>${MASTER_LOGIN}</login>|g" "$config_file"
        fi
        
        if [[ -n "${MASTER_PASSWORD:-}" ]]; then
            sed -i "s|<password>.*</password>|<password>${MASTER_PASSWORD}</password>|g" "$config_file"
        fi
        
        log_success "Manual XML configuration applied successfully"
        
        # Verify the fix worked
        if grep -q "${SERVER_NAME}" "$config_file" 2>/dev/null; then
            log_success "Verification passed - Server name is now set"
            return 0
        else
            log_error "Manual XML fix failed!"
            return 1
        fi
    else
        log_error "Unknown XML parsing issue - no template variables found but server name missing"
        return 1
    fi
}

# Fix JSON configs if needed
fix_json_configs() {
    log "Checking and fixing JSON configurations..."
    
    # Fix database config
    local db_config="EvoSC/config/database.config.json"
    if [[ -f "$db_config" ]]; then
        if grep -q "{{server.build.env" "$db_config" 2>/dev/null; then
            log_warning "JSON parsing failed for database config, applying manual fix..."
            
            # Create new database config
            cat > "$db_config" << EOF
{
    "host": "${DB_HOST:-localhost}",
    "db": "${DB_NAME:-evosc}",
    "user": "${DB_USER:-root}",
    "password": "${DB_PASSWORD:-}",
    "prefix": "${DB_PREFIX:-evosc_}"
}
EOF
            log_success "Database config fixed manually"
        else
            log_success "Database config appears to be correctly parsed"
        fi
    fi
    
    # Fix server config
    local server_config="EvoSC/config/server.config.json"
    if [[ -f "$server_config" ]]; then
        if grep -q "{{server.build.env" "$server_config" 2>/dev/null; then
            log_warning "JSON parsing failed for server config, applying manual fix..."
            
            # Create new server config
            cat > "$server_config" << EOF
{
    "ip": "${RPC_IP:-localhost}",
    "port": "${RPC_PORT:-5000}",
    "rpc": {
        "login": "${RPC_LOGIN:-SuperAdmin}",
        "password": "${RPC_PASSWORD:-SuperAdmin}"
    },
    "default-matchsettings": "${DEFAULT_MATCHSETTINGS:-tracklist.txt}"
}
EOF
            log_success "Server config fixed manually"
        else
            log_success "Server config appears to be correctly parsed"
        fi
    fi
}

# Enhanced console handler
handle_console() {
    log "Console handler ready. Type ${YELLOW}!help${NC} for commands."
    
    while IFS= read -r input; do
        case "$input" in
            "!stop"|"stop"|"quit"|"exit")
                log "Received ${RED}stop${NC} command - shutting down gracefully"
                cleanup
                exit 0
                ;;
            "!restart"|"restart")
                log "Restart requested - use ${YELLOW}panel restart function${NC}"
                ;;
            "!status"|"status")
                show_status
                ;;
            "!logs")
                echo -e "${YELLOW}=== Recent Server Logs ===${NC}"
                tail -n 20 logs/server.log 2>/dev/null || echo "No logs available"
                ;;
            "!config")
                echo -e "${YELLOW}=== Configuration Check ===${NC}"
                fix_xml_config
                fix_json_configs
                ;;
            "!help")
                show_help
                ;;
            *)
                log "Command: ${MAGENTA}$input${NC}"
                ;;
        esac
    done
}

# Enhanced status display
show_status() {
    echo -e "${YELLOW}╔══════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║            Server Status             ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════╝${NC}"
    
    if pgrep -f "TrackmaniaServer" >/dev/null; then
        echo -e "Trackmania: ${GREEN}●${NC} ${BOLD}RUNNING${NC} (PID: $(pgrep -f TrackmaniaServer))"
    else
        echo -e "Trackmania: ${RED}●${NC} ${BOLD}STOPPED${NC}"
    fi
    
    echo -e "Parsers:    ${YELLOW}●${NC} ${BOLD}PELICAN + FALLBACK${NC}"
    echo ""
}

# Enhanced help
show_help() {
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║                    Console Commands                          ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${GREEN}!stop${NC}, ${GREEN}stop${NC}, ${GREEN}quit${NC}, ${GREEN}exit${NC}  - Stop server gracefully"
    echo -e "${GREEN}!restart${NC}, ${GREEN}restart${NC}        - Request restart (use panel)"
    echo -e "${GREEN}!status${NC}, ${GREEN}status${NC}          - Show service status"
    echo -e "${GREEN}!logs${NC}                    - Show recent server logs"
    echo -e "${GREEN}!config${NC}                 - Check and fix configurations"
    echo -e "${GREEN}!help${NC}                    - Show this help"
    echo ""
}

# Enhanced cleanup
cleanup() {
    log "Shutting down services gracefully..."
    log_success "Cleanup complete"
}

# Signal handling
trap cleanup SIGTERM SIGINT

# Main execution
main() {
    show_banner
    
    validate_env
    
    log "Server: ${GREEN}${SERVER_NAME}${NC}"
    log "Players: ${GREEN}${MAX_PLAYER:-32}${NC}"
    log "RPC Port: ${GREEN}${RPC_PORT}${NC}"
    
    # CRITICAL: Fix configurations before starting anything
    fix_xml_config || {
        log_error "Failed to fix XML configuration - server cannot start"
        exit 1
    }
    
    fix_json_configs
    
    # Start console handler in background
    handle_console &
    CONSOLE_PID=$!
    
    # Start Trackmania in foreground (SECURE - NO BACKGROUNDING)
    log "Starting Trackmania server..."
    cd server
    exec ./TrackmaniaServer \
        /title=Trackmania \
        /game_Settings=MatchSettings/tracklist.txt \
        /dedicated_cfg=dedicated_cfg.txt \
        /nodaemon
}

# Initialize
main "$@"
