#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${WHITE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

# Cleanup function
cleanup() {
    print_warning "Shutting down services..."
    
    if [ ! -z "$EVOSC_PID" ] && kill -0 $EVOSC_PID 2>/dev/null; then
        print_status "Stopping EvoSC..."
        kill -TERM $EVOSC_PID
        wait $EVOSC_PID 2>/dev/null
        print_success "EvoSC stopped"
    fi
    
    if [ ! -z "$TM_PID" ] && kill -0 $TM_PID 2>/dev/null; then
        print_status "Stopping Trackmania server..."
        kill -TERM $TM_PID
        wait $TM_PID 2>/dev/null
        print_success "Trackmania server stopped"
    fi
    
    print_success "Shutdown complete"
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

print_header "Starting Trackmania 2020 + EvoSC Server"

# Apply configuration from environment variables if Pelican parsing failed
apply_manual_config() {
    print_warning "Applying manual configuration fallback..."
    
    # Update Trackmania config
    if [ ! -z "$SERVER_NAME" ]; then
        xmlstarlet ed -L -u "//server_options/name" -v "$SERVER_NAME" server/UserData/Config/dedicated_cfg.txt 2>/dev/null || true
    fi
    
    if [ ! -z "$MAX_PLAYER" ]; then
        xmlstarlet ed -L -u "//server_options/max_players" -v "$MAX_PLAYER" server/UserData/Config/dedicated_cfg.txt 2>/dev/null || true
    fi
    
    if [ ! -z "$MAX_SPECTATORS" ]; then
        xmlstarlet ed -L -u "//server_options/max_spectators" -v "$MAX_SPECTATORS" server/UserData/Config/dedicated_cfg.txt 2>/dev/null || true
    fi
    
    if [ ! -z "$RPC_PORT" ]; then
        xmlstarlet ed -L -u "//system_config/xmlrpc_port" -v "$RPC_PORT" server/UserData/Config/dedicated_cfg.txt 2>/dev/null || true
    fi
    
    if [ ! -z "$MASTER_LOGIN" ]; then
        xmlstarlet ed -L -u "//masterserver_account/login" -v "$MASTER_LOGIN" server/UserData/Config/dedicated_cfg.txt 2>/dev/null || true
    fi
    
    if [ ! -z "$MASTER_PASSWORD" ]; then
        xmlstarlet ed -L -u "//masterserver_account/password" -v "$MASTER_PASSWORD" server/UserData/Config/dedicated_cfg.txt 2>/dev/null || true
    fi
    
    # Update EvoSC database config
    if [ -f "EvoSC/config/database.config.json" ]; then
        if [ ! -z "$DB_HOST" ]; then
            jq --arg host "$DB_HOST" '.connections.mysql.host = $host' EvoSC/config/database.config.json > tmp/db_config.json && mv tmp/db_config.json EvoSC/config/database.config.json
        fi
        
        if [ ! -z "$DB_NAME" ]; then
            jq --arg db "$DB_NAME" '.connections.mysql.database = $db' EvoSC/config/database.config.json > tmp/db_config.json && mv tmp/db_config.json EvoSC/config/database.config.json
        fi
        
        if [ ! -z "$DB_USER" ]; then
            jq --arg user "$DB_USER" '.connections.mysql.username = $user' EvoSC/config/database.config.json > tmp/db_config.json && mv tmp/db_config.json EvoSC/config/database.config.json
        fi
        
        if [ ! -z "$DB_PASSWORD" ]; then
            jq --arg pass "$DB_PASSWORD" '.connections.mysql.password = $pass' EvoSC/config/database.config.json > tmp/db_config.json && mv tmp/db_config.json EvoSC/config/database.config.json
        fi
    fi
    
    # Update EvoSC server config
    if [ -f "EvoSC/config/server.config.json" ]; then
        if [ ! -z "$RPC_PORT" ]; then
            jq --arg port "$RPC_PORT" '.server.port = ($port | tonumber)' EvoSC/config/server.config.json > tmp/server_config.json && mv tmp/server_config.json EvoSC/config/server.config.json
        fi
        
        if [ ! -z "$RPC_LOGIN" ]; then
            jq --arg login "$RPC_LOGIN" '.server.rpc.login = $login' EvoSC/config/server.config.json > tmp/server_config.json && mv tmp/server_config.json EvoSC/config/server.config.json
        fi
        
        if [ ! -z "$RPC_PASSWORD" ]; then
            jq --arg pass "$RPC_PASSWORD" '.server.rpc.password = $pass' EvoSC/config/server.config.json > tmp/server_config.json && mv tmp/server_config.json EvoSC/config/server.config.json
        fi
    fi
    
    print_success "Manual configuration applied"
}

# Check if Pelican parsing worked, if not apply manual config
if [ ! -z "$SERVER_NAME" ] || [ ! -z "$DB_HOST" ]; then
    apply_manual_config
fi

# Start Trackmania server
print_status "Starting Trackmania 2020 server..."
cd server
./TrackmaniaServer /dedicated_cfg=dedicated_cfg.txt /game_settings=MatchSettings/tracklist.txt > ../logs/trackmania.log 2>&1 &
TM_PID=$!
cd ..

# Wait for Trackmania to start
sleep 5

if kill -0 $TM_PID 2>/dev/null; then
    print_success "Trackmania server started (PID: $TM_PID)"
else
    print_error "Failed to start Trackmania server"
    exit 1
fi

# Install EvoSC dependencies if needed
if [ ! -d "EvoSC/vendor" ]; then
    print_status "Installing EvoSC dependencies..."
    cd EvoSC
    composer install --no-dev --optimize-autoloader > ../logs/composer.log 2>&1
    cd ..
fi

# Start EvoSC
print_status "Starting EvoSC controller..."
cd EvoSC
php evosc > ../logs/evosc.log 2>&1 &
EVOSC_PID=$!
cd ..

# Wait for EvoSC to start
sleep 3

if kill -0 $EVOSC_PID 2>/dev/null; then
    print_success "EvoSC controller started (PID: $EVOSC_PID)"
else
    print_warning "EvoSC may have failed to start, check logs"
fi

print_header "Server Status"
print_success "Trackmania 2020 server is running"
print_success "EvoSC controller is running"
print_status "Server port: ${SERVER_PORT:-2350}"
print_status "RPC port: ${RPC_PORT:-5000}"
print_status "Type !help for available commands"

# Console input handler
handle_console_input() {
    while read -r input; do
        case "$input" in
            "!stop"|"stop"|"quit"|"exit")
                print_status "Stop command received"
                cleanup
                ;;
            "!status"|"status")
                print_header "Service Status"
                if kill -0 $TM_PID 2>/dev/null; then
                    print_success "Trackmania server: Running (PID: $TM_PID)"
                else
                    print_error "Trackmania server: Not running"
                fi
                
                if kill -0 $EVOSC_PID 2>/dev/null; then
                    print_success "EvoSC controller: Running (PID: $EVOSC_PID)"
                else
                    print_error "EvoSC controller: Not running"
                fi
                ;;
            "!logs")
                print_header "Recent Logs"
                if [ -f "logs/trackmania.log" ]; then
                    echo -e "${CYAN}Trackmania logs:${NC}"
                    tail -10 logs/trackmania.log
                fi
                if [ -f "logs/evosc.log" ]; then
                    echo -e "${CYAN}EvoSC logs:${NC}"
                    tail -10 logs/evosc.log
                fi
                ;;
            "!help")
                print_header "Available Commands"
                echo -e "${GREEN}!stop, stop, quit, exit${NC} - Stop the server"
                echo -e "${GREEN}!status, status${NC} - Show service status"
                echo -e "${GREEN}!logs${NC} - Show recent server logs"
                echo -e "${GREEN}!help${NC} - Show this help message"
                ;;
            *)
                if [ ! -z "$input" ]; then
                    print_warning "Unknown command: $input (type !help for available commands)"
                fi
                ;;
        esac
    done
}

# Start console input handler in background
handle_console_input &
CONSOLE_PID=$!

# Monitor processes
while true; do
    # Check if Trackmania is still running
    if ! kill -0 $TM_PID 2>/dev/null; then
        print_error "Trackmania server has stopped unexpectedly"
        cleanup
    fi
    
    # Check if EvoSC is still running (optional, as it might restart itself)
    if ! kill -0 $EVOSC_PID 2>/dev/null; then
        print_warning "EvoSC controller has stopped, attempting restart..."
        cd EvoSC
        php evosc > ../logs/evosc.log 2>&1 &
        EVOSC_PID=$!
        cd ..
        sleep 2
        if kill -0 $EVOSC_PID 2>/dev/null; then
            print_success "EvoSC controller restarted (PID: $EVOSC_PID)"
        fi
    fi
    
    sleep 10
done
