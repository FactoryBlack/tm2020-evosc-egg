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

# Set working directory
cd /mnt/server

print_header "Trackmania 2020 + EvoSC Installation"

# Create necessary directories
print_status "Creating directory structure..."
mkdir -p server logs backups tmp

# Download Trackmania 2020 Server
print_status "Downloading Trackmania 2020 Server..."
if [ ! -f "server/TrackmaniaServer" ]; then
    curl -sSL "https://files.maniaplanet.com/tools/TrackmaniaServer_Latest.zip" -o tmp/trackmania.zip
    if [ $? -eq 0 ]; then
        print_success "Downloaded Trackmania server"
        cd server
        unzip -q ../tmp/trackmania.zip
        chmod +x TrackmaniaServer
        cd ..
        print_success "Extracted Trackmania server"
    else
        print_error "Failed to download Trackmania server"
        exit 1
    fi
else
    print_success "Trackmania server already exists"
fi

# Download EvoSC
print_status "Downloading EvoSC..."
if [ ! -d "EvoSC" ]; then
    git clone https://github.com/EvoEsports/EvoSC.git EvoSC
    if [ $? -eq 0 ]; then
        print_success "Downloaded EvoSC"
        cd EvoSC
        composer install --no-dev --optimize-autoloader
        if [ $? -eq 0 ]; then
            print_success "Installed EvoSC dependencies"
        else
            print_warning "Failed to install EvoSC dependencies, will retry on startup"
        fi
        cd ..
    else
        print_error "Failed to download EvoSC"
        exit 1
    fi
else
    print_success "EvoSC already exists"
fi

# Create default configuration files
print_status "Creating configuration files..."

# Create Trackmania dedicated server config
mkdir -p server/UserData/Config
cat > server/UserData/Config/dedicated_cfg.txt << 'EOF'
<?xml version="1.0" encoding="utf-8" ?>
<dedicated>
    <authorization_levels>
        <level>
            <name>SuperAdmin</name>
            <password>SuperAdmin</password>
        </level>
        <level>
            <name>Admin</name>
            <password>Admin</password>
        </level>
        <level>
            <name>User</name>
            <password>User</password>
        </level>
    </authorization_levels>

    <masterserver_account>
        <login></login>
        <password></password>
    </masterserver_account>

    <server_options>
        <name>My Trackmania Server</name>
        <comment>Powered by EvoSC</comment>
        <hide_server>0</hide_server>
        <max_players>32</max_players>
        <password></password>
        <max_spectators>32</max_spectators>
        <ladder_mode>forced</ladder_mode>
        <enable_p2p_upload>True</enable_p2p_upload>
        <enable_p2p_download>True</enable_p2p_download>
        <callvote_timeout>60000</callvote_timeout>
        <callvote_ratio>0.5</callvote_ratio>
        <allow_challenge_download>True</allow_challenge_download>
        <autosave_replays>False</autosave_replays>
        <autosave_validation_replays>False</autosave_validation_replays>
        <referee_password></referee_password>
        <referee_validation_mode>0</referee_validation_mode>
        <use_changing_validation_seed>False</use_changing_validation_seed>
        <disable_horns>False</disable_horns>
        <clientinputs_maxlatency>0</clientinputs_maxlatency>
    </server_options>

    <system_config>
        <connection_uploadrate>512</connection_uploadrate>
        <connection_downloadrate>8192</connection_downloadrate>
        <allow_spectator_relays>False</allow_spectator_relays>
        <peer_bandwidth>512</peer_bandwidth>
        <packet_buffer_size>32</packet_buffer_size>
        <force_ip_address></force_ip_address>
        <server_port>2350</server_port>
        <server_p2p_port>3450</server_p2p_port>
        <client_port>0</client_port>
        <bind_ip_address></bind_ip_address>
        <use_nat_upnp></use_nat_upnp>
        <gzip_level>6</gzip_level>
        <xmlrpc_port>5000</xmlrpc_port>
        <xmlrpc_allowremote>True</xmlrpc_allowremote>
        <blacklist_url></blacklist_url>
        <guestlist_filename></guestlist_filename>
        <blacklist_filename></blacklist_filename>
        <use_proxy>False</use_proxy>
        <proxy_login></proxy_login>
        <proxy_password></proxy_password>
    </system_config>
</dedicated>
EOF

# Create EvoSC database config
mkdir -p EvoSC/config
cat > EvoSC/config/database.config.json << 'EOF'
{
    "default": "mysql",
    "connections": {
        "mysql": {
            "driver": "mysql",
            "host": "localhost",
            "port": 3306,
            "database": "evosc",
            "username": "root",
            "password": "",
            "charset": "utf8mb4",
            "collation": "utf8mb4_unicode_ci",
            "prefix": "evosc_",
            "strict": false
        }
    }
}
EOF

# Create EvoSC server config
cat > EvoSC/config/server.config.json << 'EOF'
{
    "server": {
        "ip": "localhost",
        "port": 5000,
        "rpc": {
            "login": "SuperAdmin",
            "password": "SuperAdmin"
        }
    },
    "controller": {
        "default-matchsettings": "tracklist.txt"
    }
}
EOF

# Create default tracklist
mkdir -p server/UserData/Maps/MatchSettings
cat > server/UserData/Maps/MatchSettings/tracklist.txt << 'EOF'
<?xml version="1.0" encoding="utf-8" ?>
<playlist>
    <gameinfos>
        <game_mode>0</game_mode>
        <chat_time>10000</chat_time>
        <finishtimeout>1</finishtimeout>
        <allwarmupduration>0</allwarmupduration>
        <disablerespawn>0</disablerespawn>
        <forceshowallopponents>0</forceshowallopponents>
        <rounds_pointslimit>30</rounds_pointslimit>
        <rounds_usenewrules>0</rounds_usenewrules>
        <rounds_forcedlaps>0</rounds_forcedlaps>
        <rounds_pointslimitnewrules>5</rounds_pointslimitnewrules>
        <team_pointslimit>50</team_pointslimit>
        <team_maxpoints>6</team_maxpoints>
        <team_usenewrules>0</team_usenewrules>
        <team_pointslimitnewrules>5</team_pointslimitnewrules>
        <timeattack_limit>300000</timeattack_limit>
        <timeattack_synchstartperiod>0</timeattack_synchstartperiod>
        <laps_nblaps>5</laps_nblaps>
        <laps_timelimit>0</laps_timelimit>
        <cup_pointslimit>100</cup_pointslimit>
        <cup_roundsperchallenge>5</cup_roundsperchallenge>
        <cup_nbwinners>3</cup_nbwinners>
        <cup_warmupduration>2</cup_warmupduration>
    </gameinfos>
    <hotseat>
        <game_mode>0</game_mode>
        <time_limit>300000</time_limit>
        <rounds_count>5</rounds_count>
    </hotseat>
    <filter>
        <is_lan>1</is_lan>
        <is_internet>1</is_internet>
        <is_solo>0</is_solo>
        <is_hotseat>0</is_hotseat>
        <sort_index>1000</sort_index>
        <random_map_order>0</random_map_order>
    </filter>
</playlist>
EOF

# Download startup script from repository
print_status "Downloading startup script..."
curl -sSL "https://raw.githubusercontent.com/FactoryBlack/tm2020-evosc-egg/main/start.sh" -o start.sh
if [ $? -eq 0 ]; then
    chmod +x start.sh
    print_success "Startup script downloaded and made executable"
else
    print_error "Failed to download startup script"
    exit 1
fi

# Clean up temporary files
rm -rf tmp

print_header "Installation Complete"
print_success "Trackmania 2020 server installed"
print_success "EvoSC controller installed"
print_success "Configuration files created"
print_success "Startup script created"
print_status "Ready to start server with: ./start.sh"

exit 0
