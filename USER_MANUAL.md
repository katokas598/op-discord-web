# 📚 User Manual - DiscordSer Bot

## 🚀 Getting Started

### For Windows Users:
1. Double-click `start_bot.bat` - setup and run bot
2. Double-click `start_dashboard.bat` - run web panel

### For Linux/Ubuntu Users:
1. Run `./start_bot.sh` - setup and run bot
2. Run `./start_dashboard.sh` - run web panel

## 📋 What You Need

1. **Python 3.8+** 
2. **Discord Bot Token** - get from https://discord.com/developers/applications
3. **Discord Server ID** - enable Developer Mode in Discord and copy server ID

## 🌐 Web Panel

After starting the panel is available at `http://localhost:8000`

**Features:**
- View and moderate members
- Manage tickets and complaints
- View moderation logs
- Configure custom commands
- Server statistics

## 🤖 Bot Commands

### Basic Commands
- `!ping` - check bot status
- `!cmds` - show command list
- `!serverinfo` - server information
- `!userinfo [@user]` - user information
- `!invite` - create server invite

### Moderation (Admin Only)
- `!ban @user [reason]` - ban user
- `!unban <id>` - unban by ID
- `!kick @user [reason]` - kick user  
- `!mute @user [time] [reason]` - mute user (10m, 1h, 1d)
- `!unmute @user` - unmute user
- `!warn @user [reason]` - give warning
- `!warns [@user]` - show warnings
- `!clearwarns @user` - clear warnings
- `!clear <amount>` - delete messages (1-1000)
- `!lock` / `!unlock` - lock/unlock channel

### Tickets
- `!ticket [category]` - create ticket
- `!closeticket` - close ticket (moderators only)

## ⚙️ Configuration

All settings are stored in `config.json`:

```json
{
  "discord_token": "YOUR_BOT_TOKEN",
  "prefix": "!",
  "guild_id": "YOUR_SERVER_ID", 
  "admin_ids": [123456789],
  "max_warns": 3,
  "ticket_categories": ["Support", "Complaints", "Suggestions"],
  "dashboard_domain": "your-domain.com",
  "dashboard_host": "0.0.0.0",
  "dashboard_port": 8000
}
```

## 🔧 Required Bot Permissions

When adding bot to server give it these permissions:
- Manage Messages
- Kick Members
- Ban Members  
- Manage Channels
- Manage Permissions
- Read Message History
- Send Messages

## 🆘 Troubleshooting

### "Invalid Token" Error
- Check token correctness in config.json
- Make sure token is not a placeholder like "YOUR_DISCORD_TOKEN_HERE"
- Get new token from Discord Developer Portal

### "Missing Permissions" Error  
- Check bot permissions on server
- Make sure bot role is higher than moderated roles

### Web Panel Not Opening
- Check port 8000 is not occupied
- Make sure dashboard_server.py is running
- Try different browser

### Encoding Issues in Console
- This is normal for Windows, functionality is not affected
- Use .bat files for startup

## 📖 For Detailed Setup

- Windows: See README.md
- Ubuntu: See UBUNTU_INSTALL.md or QUICK_START_UBUNTU.md

---

**DiscordSer Bot v2.0** - Full-featured Discord server management bot