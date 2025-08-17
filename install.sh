#!/bin/bash

# Set working directory
cd /mnt/server

# Install required packages
apt update
apt install -y curl unzip git composer php php-cli php-json php-mbstring php-curl php-xml php-mysqli php-pdo php-pdo-mysql php-zip

# Create necessary directories
mkdir -p logs backups tmp

# Download Trackmania 2020 Server (original working URL)
echo "Downloading Trackmania 2020 Server..."
curl -sSL -o TrackmaniaServer.zip "http://files.v04.maniaplanet.com/server/TrackmaniaServer_Latest.zip"
unzip -q -o TrackmaniaServer.zip -d server
chmod +x server/TrackmaniaServer
rm TrackmaniaServer.zip

# Download EvoSC (original working repository)
echo "Downloading EvoSC..."
git clone --depth 1 --branch master https://github.com/EvoTM/EvoSC.git

# Install EvoSC dependencies
cd EvoSC
composer install --no-dev --optimize-autoloader
cd ..

# Create default configuration files with Pelican template variables
echo "Creating configuration files..."

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
        <login>{{MASTER_LOGIN}}</login>
        <password>{{MASTER_PASSWORD}}</password>
    </masterserver_account>

    <server_options>
        <name>{{SERVER_NAME}}</name>
        <comment>Powered by EvoSC</comment>
        <hide_server>0</hide_server>
        <max_players>{{MAX_PLAYER}}</max_players>
        <password></password>
        <max_spectators>{{MAX_SPECTATORS}}</max_spectators>
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
        <force_ip_address>{{FORCE_IP_ADDRESS}}</force_ip_address>
        <server_port>{{SERVER_PORT}}</server_port>
        <server_p2p_port>3450</server_p2p_port>
        <client_port>0</client_port>
        <bind_ip_address></bind_ip_address>
        <use_nat_upnp></use_nat_upnp>
        <gzip_level>6</gzip_level>
        <xmlrpc_port>{{RPC_PORT}}</xmlrpc_port>
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
            "host": "{{DB_HOST}}",
            "port": 3306,
            "database": "{{DB_NAME}}",
            "username": "{{DB_USER}}",
            "password": "{{DB_PASSWORD}}",
            "charset": "utf8mb4",
            "collation": "utf8mb4_unicode_ci",
            "prefix": "{{DB_PREFIX}}",
            "strict": false
        }
    }
}
EOF

# Create EvoSC server config
cat > EvoSC/config/server.config.json << 'EOF'
{
    "server": {
        "ip": "{{RPC_IP}}",
        "port": {{RPC_PORT}},
        "rpc": {
            "login": "{{RPC_LOGIN}}",
            "password": "{{RPC_PASSWORD}}"
        }
    },
    "controller": {
        "default-matchsettings": "{{DEFAULT_MATCHSETTINGS}}"
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

echo "Installation complete!"
exit 0
