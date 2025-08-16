# Trackmania 2020 + EvoSC Server

Production-ready Trackmania 2020 server with EvoSC controller for Pterodactyl/Pelican Panel.

## Features

- ✅ **Trackmania 2020 Dedicated Server**
- ✅ **EvoSC Server Controller** 
- ✅ **Unified Console Interface**
- ✅ **Production-Ready Logging**
- ✅ **Graceful Shutdown Handling**
- ✅ **Automatic Service Management**
- ✅ **Colorful Status Display**

## Quick Setup

### 1. Create Pterodactyl Egg

In your Pterodactyl admin panel, create a new egg with these settings:

**Basic Settings:**
- Name: `Trackmania 2020 + EvoSC`
- Author: `your-email@example.com`
- Docker Image: `dogre/ptero:prod` (or your custom image)
- Startup Command: `./start.sh`

**File Configuration:**
\`\`\`json
{
    "server/UserData/Config/dedicated_cfg.txt": {
        "parser": "xml",
        "find": {
            "name": "{{server.build.env.SERVER_NAME}}",
            "server_port": "{{server.build.default.port}}",
            "xmlrpc_port": "{{server.build.env.RPC_PORT}}",
            "xmlrpc_allowremote": "True",
            "force_ip_address": "{{server.build.env.FORCE_IP_ADDRESS}}",
            "max_players": "{{server.build.env.MAX_PLAYER}}",
            "max_spectators": "{{server.build.env.MAX_SPECTATORS}}",
            "login": "{{server.build.env.MASTER_LOGIN}}",
            "password": "{{server.build.env.MASTER_PASSWORD}}"
        }
    },
    "EvoSC/config/database.config.json": {
        "parser": "json",
        "find": {
            "host": "{{server.build.env.DB_HOST}}",
            "db": "{{server.build.env.DB_NAME}}",
            "user": "{{server.build.env.DB_USER}}",
            "password": "{{server.build.env.DB_PASSWORD}}",
            "prefix": "{{server.build.env.DB_PREFIX}}"
        }
    },
    "EvoSC/config/server.config.json": {
        "parser": "json",
        "find": {
            "ip": "{{server.build.env.RPC_IP}}",
            "port": "{{server.build.env.RPC_PORT}}",
            "rpc.login": "{{server.build.env.RPC_LOGIN}}",
            "rpc.password": "{{server.build.env.RPC_PASSWORD}}",
            "default-matchsettings": "{{server.build.env.DEFAULT_MATCHSETTINGS}}"
        }
    }
}
\`\`\`

**Startup Configuration:**
\`\`\`json
{
    "done": "Type !help for available commands"
}
\`\`\`

**Stop Command:** `!stop`

### 2. Environment Variables

Add these variables to your egg:

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `SERVER_NAME` | Server name in browser | `My Trackmania Server` | ✅ |
| `MAX_PLAYER` | Maximum players | `32` | ✅ |
| `MAX_SPECTATORS` | Maximum spectators | `32` | ✅ |
| `MASTER_LOGIN` | Trackmania account login | `` | ❌ |
| `MASTER_PASSWORD` | Trackmania account password | `` | ❌ |
| `DB_HOST` | Database hostname | `` | ✅ |
| `DB_NAME` | Database name | `evosc` | ✅ |
| `DB_USER` | Database username | `` | ✅ |
| `DB_PASSWORD` | Database password | `` | ❌ |
| `DB_PREFIX` | Database table prefix | `evosc_` | ❌ |
| `RPC_LOGIN` | XML-RPC username | `SuperAdmin` | ✅ |
| `RPC_PASSWORD` | XML-RPC password | `SuperAdmin` | ✅ |
| `RPC_IP` | XML-RPC IP address | `localhost` | ✅ |
| `RPC_PORT` | XML-RPC port | `5000` | ✅ |
| `FORCE_IP_ADDRESS` | Force specific IP | `` | ❌ |
| `DEFAULT_MATCHSETTINGS` | Default match settings | `tracklist.txt` | ✅ |

### 3. Installation Script

Copy the contents of `install.sh` into the egg's installation script field.

## Console Commands

The server provides a unified console interface:

- `!stop`, `stop`, `quit`, `exit` - Stop server gracefully
- `!status`, `status` - Show service status
- `!logs` - Show recent server logs
- `!help` - Show available commands

## File Structure

\`\`\`
/home/container/
├── server/                 # Trackmania server files
│   ├── TrackmaniaServer   # Server executable
│   └── UserData/          # Server configuration
├── EvoSC/                 # EvoSC controller
│   ├── config/           # EvoSC configuration
│   └── logs/             # EvoSC logs
├── logs/                 # Server logs
├── backups/              # Automatic backups
└── start.sh              # Startup script
\`\`\`

## Troubleshooting

### Server Won't Start
1. Check environment variables are set correctly
2. Verify database connection details
3. Check logs: `!logs` command

### EvoSC Connection Issues
1. Verify RPC_PORT matches between Trackmania and EvoSC
2. Check RPC_LOGIN and RPC_PASSWORD are correct
3. Ensure database is accessible

### Performance Issues
1. Monitor resource usage
2. Check for map loading errors
3. Verify network connectivity

## Security Notes

- Change default RPC_PASSWORD from `SuperAdmin`
- Use strong database passwords
- Limit database user permissions
- Keep server updated

## Support

For issues and support:
1. Check server logs first
2. Verify configuration matches documentation
3. Test with minimal configuration

## License

This project is provided as-is for educational and production use.
