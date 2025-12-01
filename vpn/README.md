# VPN Configuration Directory

This directory contains AirVPN OpenVPN configuration files for anonymous bot operation.

## Setup Instructions

### 1. Get AirVPN Configuration

1. Login to [AirVPN](https://airvpn.org/)
2. Go to [Config Generator](https://airvpn.org/generator/)
3. Select settings:
   - **Protocol**: OpenVPN
   - **Port**: 443 UDP (recommended) or 443 TCP
   - **Keys/Certs**: Enable "Separate keys/certs"
   - **Server**: Choose a server with **port forwarding support**
     - Check server details page for port forwarding availability
     - Recommended: Servers in Netherlands, Romania, or Switzerland
4. Download the generated config file

### 2. Install Configuration

Save the downloaded config file as:
```
./vpn/airvpn.conf
```

**Important**: The file MUST be named `airvpn.conf` (referenced in docker-compose-*-vpn.yml files).

### 3. Verify Configuration

Check that the file contains:
```
client
dev tun
proto udp
remote <server>.airvpn.org 443
...
```

### 4. Get OpenVPN Credentials

Your OpenVPN credentials are different from your website login:

1. Go to [AirVPN Client Area](https://airvpn.org/client/)
2. Find section: **OpenVPN Credentials**
3. Copy:
   - **Username**: `AIRVPN_USERNAME` (in .env)
   - **Password**: `AIRVPN_PASSWORD` (in .env)

### 5. Update Environment Variables

In your `.env` file:
```bash
AIRVPN_USERNAME=your_openvpn_username
AIRVPN_PASSWORD=your_openvpn_password
```

## Port Forwarding

AirVPN automatically assigns a forwarded port when you connect. This port is used for incoming webhook connections.

**How it works:**
1. Bot starts → Gluetun connects to AirVPN
2. AirVPN assigns a random port (e.g., 51234)
3. Port stored in: `/tmp/gluetun/forwarded_port` (inside container)
4. Check with: `docker-compose -f docker-compose.prod-vpn.yml exec gluetun cat /tmp/gluetun/forwarded_port`

**Webhook URL:**
```
https://<vpn-exit-ip>.sslip.io:<forwarded-port>/
```

Get VPN exit IP:
```bash
docker-compose -f docker-compose.prod-vpn.yml exec gluetun wget -qO- https://api.ipify.org
```

## Security Considerations

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
- Store credentials securely (Vault, AWS Secrets Manager in production)
- Rotate credentials if compromised

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
