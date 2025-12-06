# VPN Configuration Directory

This directory contains AirVPN OpenVPN configuration files for anonymous bot operation.

## Setup Instructions

### 1. Create Separate Devices (Recommended)

AirVPN supports **Device Management** - create separate devices for production and staging:

**Why separate devices?**
- Independent credentials per environment
- Revoke one device without affecting others
- Better audit logs (track which environment connects when)
- Security isolation

**Steps:**
1. Login to [AirVPN Client Area](https://airvpn.org/client/)
2. Go to **Devices** section
3. Click **"Create New Device"**
4. Create devices:
   - Device name: `telegram-bot-production`
   - Device name: `telegram-bot-staging`
5. Each device gets unique **Username** and **Password**
6. Save credentials securely (different .env files)

### 2. Get AirVPN Configuration

**For each environment (prod/staging):**

1. Login to [AirVPN](https://airvpn.org/)
2. Go to [Config Generator](https://airvpn.org/generator/)
3. Select settings:
   - **Protocol**: OpenVPN
   - **Port**: 443 UDP (recommended) or 443 TCP
   - **Keys/Certs**: Enable "Separate keys/certs"
   - **Device**: Select your device (e.g., `telegram-bot-production`)
   - **Server**: Choose a server with **port forwarding support**
     - Check server details page for port forwarding availability
     - Recommended: Servers in Netherlands, Romania, or Switzerland
4. Download the generated config file

### 3. Install Configurations and Certificates

AirVPN provides certificates when downloading the config. Extract the downloaded ZIP:

**File structure:**
```
vpn/
├── README.md
├── airvpn.conf           # OpenVPN config
└── certs/
    ├── user.crt          # User certificate
    ├── user.key          # Private key (SENSITIVE!)
    ├── ca.crt            # Certificate Authority
    └── ta.key            # TLS authentication key
```

**Setup:**
```bash
# Create certs directory
mkdir -p vpn/certs

# Extract certificates from AirVPN download
unzip AirVPN_*.zip -d /tmp/airvpn

# Copy files to vpn directory
cp /tmp/airvpn/*.conf vpn/airvpn.conf
cp /tmp/airvpn/user.crt vpn/certs/
cp /tmp/airvpn/user.key vpn/certs/
cp /tmp/airvpn/ca.crt vpn/certs/
cp /tmp/airvpn/ta.key vpn/certs/

# CRITICAL: Set strict file permissions
chmod 600 vpn/certs/*.key              # Private keys: owner read/write only
chmod 644 vpn/certs/*.crt              # Certificates: owner read/write, group/others read
chmod 600 vpn/airvpn.conf              # Config: owner read/write only
chmod 700 vpn/certs                    # Directory: owner access only

# Verify permissions
ls -la vpn/certs/
# Expected:
# drwx------  user.key (600)
# -rw-r--r--  user.crt (644)
# -rw-r--r--  ca.crt (644)
# drwx------  ta.key (600)
```

### 4. Update OpenVPN Config

Edit `vpn/airvpn.conf` to use certificate paths that work inside the Gluetun container:

```conf
# Find these lines and update paths:
cert /gluetun/certs/user.crt
key /gluetun/certs/user.key
ca /gluetun/certs/ca.crt
tls-auth /gluetun/certs/ta.key 1
```

**Important**: Paths must start with `/gluetun/certs/` (Docker mount point).

### 5. Verify Configuration

Check that `vpn/airvpn.conf` contains:
```
client
dev tun
proto udp
remote <server>.airvpn.org 443
cert /gluetun/certs/user.crt
key /gluetun/certs/user.key
ca /gluetun/certs/ca.crt
tls-auth /gluetun/certs/ta.key 1
```

### 6. Configure Environment Variables

**Certificate-based auth (RECOMMENDED):**

Leave `AIRVPN_USERNAME` and `AIRVPN_PASSWORD` **empty** in `.env`:
```bash
# Certificate-based auth - leave empty
AIRVPN_USERNAME=
AIRVPN_PASSWORD=
```

**Username/Password auth (Alternative):**

Only use if NOT using certificates:
```bash
AIRVPN_USERNAME=telegram-bot-production_user
AIRVPN_PASSWORD=your_password
```

## Port Allocation

To allow parallel operation of Production and Staging environments (with and without VPN), the following port allocation is used:

**Port Assignment:**
```
Production (no VPN):    Bot: 5000, Redis: 6379
Production (VPN):       Bot: 5100, Redis: 6479
Staging (no VPN):       Bot: 5001, Redis: 6380
Staging (VPN):          Bot: 5101, Redis: 6480
Development (VPN):      Bot: 5001, Redis: 6379
```

**Container Names:**
- Production VPN: `shopbot-gluetun-prod-vpn`, `shopbot-prod-vpn`, `shopbot-redis-prod-vpn`
- Staging VPN: `shopbot-gluetun-stg-vpn`, `shopbot-stg-vpn`, `shopbot-redis-stg-vpn`
- Development VPN: `shopbot-gluetun-dev-vpn`, `shopbot-dev-vpn`, `shopbot-redis-dev-vpn`

**Migration from old setup:**
If you already have a configured `docker-compose.prod-vpn.yml` with old ports (5000/6379), run:
```bash
bash vpn/migrate-prod-vpn-ports.sh
```

This will automatically update:
- Container names → add `-prod-vpn` suffix
- Port 5000 → 5100
- Port 6379 → 6479
- WEBAPP_PORT in .env

## Port Forwarding

AirVPN provides static port forwarding, but it must be configured manually (Gluetun's automatic port forwarding doesn't support custom providers).

**Setup:**

1. **Get your forwarded port from AirVPN:**
   - Login to [AirVPN](https://airvpn.org/)
   - Go to [Ports Section](https://airvpn.org/ports/)
   - Request a forwarded port if you don't have one
   - Note the port number (e.g., `51234`)

2. **Update docker-compose to expose the port:**

   Edit `docker-compose.prod-vpn.yml`:
   ```yaml
   gluetun:
     ports:
       - "5100:5100"        # Bot port
       - "6479:6379"        # Redis
       - "51234:51234"      # Add your AirVPN forwarded port here
   ```

3. **Update Firewall rules:**
   ```yaml
   environment:
     - FIREWALL_VPN_INPUT_PORTS=5100,51234  # Add forwarded port
   ```

4. **Get VPN exit IP:**
   ```bash
   docker-compose -f docker-compose.prod-vpn.yml exec gluetun wget -qO- https://api.ipify.org
   ```

5. **Webhook URL:**
   ```
   https://<vpn-exit-ip>.sslip.io:51234/
   ```
   Or use internal Caddy reverse proxy on port 5100 (HTTPS via Caddy on port 443)

## Security Considerations

### File Permissions (CRITICAL)

**Private keys MUST have restrictive permissions:**
```bash
# Check current permissions
ls -la vpn/certs/

# Fix if needed
chmod 700 vpn/                         # Directory: owner only
chmod 700 vpn/certs/                   # Certs directory: owner only
chmod 600 vpn/certs/*.key              # Private keys: owner read/write only
chmod 600 vpn/airvpn.conf              # Config: owner read/write only
chmod 644 vpn/certs/*.crt              # Certificates: owner read/write, others read

# Verify (should show -rw------- for .key files)
stat -c '%a %n' vpn/certs/*
```

**Why this matters:**
- Private keys with wrong permissions → SSH/OpenVPN will refuse to use them
- Other users on the system could read your keys
- Compromised keys = full VPN access as your device

**Production checklist:**
- [ ] `vpn/certs/*.key` has 600 permissions
- [ ] `vpn/certs/` directory has 700 permissions
- [ ] `.env` file has 600 permissions
- [ ] No keys committed to git
- [ ] Regular key rotation schedule

### Kill Switch
Gluetun includes a built-in kill switch:
- If VPN connection drops, ALL network traffic is blocked
- Bot cannot leak real IP address
- Containers restart automatically when VPN reconnects

### Firewall Rules
Configured in docker-compose:
```yaml
- FIREWALL_OUTBOUND_SUBNETS=172.16.0.0/12,192.168.0.0/16,10.0.0.0/8
- FIREWALL_VPN_INPUT_PORTS=5000
```

### Config File Security
- Never commit `airvpn.conf` to git (added to .gitignore)
- Never commit certificates to git (added to .gitignore)
- Store credentials securely (Vault, AWS Secrets Manager in production)
- Rotate device credentials if compromised
- Use separate devices for prod/staging
- Revoke old devices in AirVPN Client Area

## Troubleshooting

### VPN not connecting
```bash
# Check Gluetun logs
docker-compose -f docker-compose.prod-vpn.yml logs -f gluetun

# Common issues:
# - Invalid credentials → Check AIRVPN_USERNAME/PASSWORD in .env
# - Config file not found → Verify ./vpn/airvpn.conf exists
# - Port blocked → Try different protocol (UDP vs TCP)
```

### Check VPN status
```bash
# Check if VPN is connected
docker-compose -f docker-compose.prod-vpn.yml exec gluetun wget -qO- https://api.ipify.org

# Should show AirVPN exit IP, NOT your real IP
```

### Port forwarding not working
```bash
# Check if port was assigned
docker-compose -f docker-compose.prod-vpn.yml exec gluetun cat /tmp/gluetun/forwarded_port

# If empty, try:
# 1. Use different AirVPN server (must support port forwarding)
# 2. Check AirVPN status page for server availability
# 3. Restart containers
```

### Test webhook from outside
```bash
# Get VPN IP and forwarded port
VPN_IP=$(docker-compose -f docker-compose.prod-vpn.yml exec gluetun wget -qO- https://api.ipify.org)
VPN_PORT=$(docker-compose -f docker-compose.prod-vpn.yml exec gluetun cat /tmp/gluetun/forwarded_port)

# Test health endpoint
curl https://${VPN_IP}.sslip.io:${VPN_PORT}/health
```

## File Structure

```
vpn/
├── README.md           # This file
├── airvpn.conf         # Your OpenVPN config (gitignored)
└── .gitkeep            # Keeps directory in git
```

## References

- AirVPN Documentation: https://airvpn.org/forums/
- Gluetun Documentation: https://github.com/qdm12/gluetun
- Port Forwarding Guide: https://airvpn.org/forums/topic/9684-how-to-forward-ports/

## Support

If you encounter issues:
1. Check Gluetun logs first
2. Verify AirVPN credentials
3. Test VPN connection manually with OpenVPN client
4. Contact AirVPN support for server-specific issues
