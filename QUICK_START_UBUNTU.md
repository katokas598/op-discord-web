# 🚀 Quick Start Guide for Ubuntu Server

## ⚡ Super Quick Start (One Command)

```bash
curl -sSL https://raw.githubusercontent.com/katokas598/op-discord-web/master/install_ubuntu.sh | sudo bash
```

## 📖 Step by Step Installation

### 1. Upload Files to Server

**Method A: Via SCP (Recommended)**
```bash
# On your Windows computer (PowerShell)
scp -r "F:\bot-2.0-main" username@your-server-ip:/tmp/

# On Ubuntu server
sudo cp -r /tmp/bot-2.0-main /opt/
```

**Method B: Via Git Clone**
```bash
git clone https://github.com/katokas598/op-discord-web.git
cd op-discord-web
```

### 2. Run Auto-installer

```bash
sudo chmod +x install_ubuntu.sh
sudo ./install_ubuntu.sh
```

### 3. Configure Bot

```bash
# Switch to bot user
sudo su - discordbot
cd ~/bot-2.0-main

# Run setup wizard
python3 setup.py
```

**What to enter:**
- **Discord Token**: Get from https://discord.com/developers/applications
- **Prefix**: `!` (or any other)
- **Guild ID**: Your Discord server ID
- **Admin IDs**: Your Discord ID (comma separated)
- **Dashboard Domain**: Your domain (optional)

### 4. Start Services

```bash
# Exit from discordbot user
exit

# Start services
sudo systemctl start discordbot.service
sudo systemctl start discordbot-dashboard.service

# Check status
sudo systemctl status discordbot.service
sudo systemctl status discordbot-dashboard.service
```

## 🔧 Management Commands

After installation use `discordbot` command:

```bash
discordbot start      # Start services
discordbot stop       # Stop services
discordbot restart    # Restart services
discordbot status     # Check status
discordbot logs       # View logs
discordbot update     # Update bot
```

## 🌐 Access Web Panel

- **Local**: http://localhost or http://server-ip
- **With Domain**: https://yourdomain.com

## 📊 Monitoring

```bash
# Real-time logs
sudo journalctl -u discordbot.service -f

# System status
htop

# Port usage
sudo netstat -tulpn | grep :8000
```

## 🆘 Troubleshooting

### Bot won't start:
```bash
# Check logs
sudo journalctl -u discordbot.service --no-pager -l

# Check configuration
sudo -u discordbot bash -c "cd /home/discordbot/bot-2.0-main && python3 validate_config.py"
```

### Panel not accessible:
```bash
# Check status
sudo systemctl status discordbot-dashboard.service

# Check Nginx
sudo nginx -t
sudo systemctl status nginx
```

---

✅ **After these steps your Discord bot will run 24/7 on Ubuntu!**