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

# Apply configuration fallbacks (original working approach with sed)
apply_config_fallbacks() {
    print_status "Applying configuration fallbacks..."
    
    # Trackmania config fallbacks using sed (original working method)
    if [ ! -z "$SERVER_NAME" ]; then
        sed -i "s/{{SERVER_NAME}}/$SERVER_NAME/g" server/UserData/Config/dedicated_cfg.txt
    fi
    
    if [ ! -z "$MAX_PLAYER" ]; then
        sed -i "s/{{MAX_PLAYER}}/$MAX_PLAYER/g" server/UserData/Config/dedicated_cfg.txt
    fi
    
    if [ ! -z "$MAX_SPECTATORS" ]; then
        sed -i "s/{{MAX_SPECTATORS}}/$MAX_SPECTATORS/g" server/UserData/Config/dedicated_cfg.txt
    fi
    
    if [ ! -z "$SERVER_PORT" ]; then
        sed -i "s/{{SERVER_PORT}}/$SERVER_PORT/g" server/UserData/Config/dedicated_cfg.txt
    fi
    
    if [ ! -z "$RPC_PORT" ]; then
        sed -i "s/{{RPC_PORT}}/$RPC_PORT/g" server/UserData/Config/dedicated_cfg.txt
    fi
    
    if [ ! -z "$MASTER_LOGIN" ]; then
        sed -i "s/{{MASTER_LOGIN}}/$MASTER_LOGIN/g" server/UserData/Config/dedicated_cfg.txt
    fi
    
    if [ ! -z "$MASTER_PASSWORD" ]; then
        sed -i "s/{{MASTER_PASSWORD}}/$MASTER_PASSWORD/g" server/UserData/Config/dedicated_cfg.txt
    fi
    
    if [ ! -z "$FORCE_IP_ADDRESS" ]; then
        sed -i "s/{{FORCE_IP_ADDRESS}}/$FORCE_IP_ADDRESS/g" server/UserData/Config/dedicated_cfg.txt
    fi
    
    # EvoSC database config fallbacks using sed
    if [ ! -z "$DB_HOST" ]; then
        sed -i "s/{{DB_HOST}}/$DB_HOST/g" EvoSC/config/database.config.json
    fi
    
    if [ ! -z "$DB_NAME" ]; then
        sed -i "s/{{DB_NAME}}/$DB_NAME/g" EvoSC/config/database.config.json
    fi
    
    if [ ! -z "$DB_USER" ]; then
        sed -i "s/{{DB_USER}}/$DB_USER/g" EvoSC/config/database.config.json
    fi
    
    if [ ! -z "$DB_PASSWORD" ]; then
        sed -i "s/{{DB_PASSWORD}}/$DB_PASSWORD/g" EvoSC/config/database.config.json
    fi
    
    if [ ! -z "$DB_PREFIX" ]; then
        sed -i "s/{{DB_PREFIX}}/$DB_PREFIX/g" EvoSC/config/database.config.json
    fi
    
    # EvoSC server config fallbacks using sed
    if [ ! -z "$RPC_IP" ]; then
        sed -i "s/{{RPC_IP}}/$RPC_IP/g" EvoSC/config/server.config.json
    fi
    
    if [ ! -z "$RPC_PORT" ]; then
        sed -i "s/{{RPC_PORT}}/$RPC_PORT/g" EvoSC/config/server.config.json
    fi
    
    if [ ! -z "$RPC_LOGIN" ]; then
        sed -i "s/{{RPC_LOGIN}}/$RPC_LOGIN/g" EvoSC/config/server.config.json
    fi
    
    if [ ! -z "$RPC_PASSWORD" ]; then
        sed -i "s/{{RPC_PASSWORD}}/$RPC_PASSWORD/g" EvoSC/config/server.config.json
    fi
    
    if [ ! -z "$DEFAULT_MATCHSETTINGS" ]; then
        sed -i "s/{{DEFAULT_MATCHSETTINGS}}/$DEFAULT_MATCHSETTINGS/g" EvoSC/config/server.config.json
    fi
    
    print_success "Configuration fallbacks applied"
}

# Apply configuration fallbacks
apply_config_fallbacks

# Console input handler (keeping the nice shared console feature)
handle_console_input() {
    while read -r input; do
        case "$input" in
            "!stop"|"stop"|"quit"|"exit")
                print_status "Stop command received"
                exit 0
                ;;
            "!status"|"status")
                print_header "Service Status"
                print_success "Server is running"
                ;;
            "!logs")
                print_header "Recent Logs"
                if [ -f "logs/trackmania.log" ]; then
                    echo -e "${CYAN}Trackmania logs:${NC}"
                    tail -10 logs/trackmania.log 2>/dev/null || echo "No logs available"
                fi
                if [ -f "logs/evosc.log" ]; then
                    echo -e "${CYAN}EvoSC logs:${NC}"
                    tail -10 logs/evosc.log 2>/dev/null || echo "No logs available"
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

print_success "Configuration applied"
print_status "Starting Trackmania server..."

# Start console input handler in background (keeping shared console)
handle_console_input &

# Find the correct EvoSC entry point
cd EvoSC
print_success "EvoSC controller started"
print_status "Type !help for available commands"

# Check for different possible EvoSC entry points
if [ -f "evosc" ]; then
    exec php evosc
elif [ -f "evosc.php" ]; then
    exec php evosc.php
elif [ -f "index.php" ]; then
    exec php index.php
elif [ -f "core/bootstrap.php" ]; then
    exec php core/bootstrap.php
else
    print_error "Could not find EvoSC entry point"
    ls -la
    exit 1
fi
