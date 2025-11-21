# 🚀 ORE Miner Setup Guide

**Complete beginner-friendly guide to get mining in 20 minutes**

This guide assumes zero prior experience with Rust or Solana development. Follow every step exactly.

---

## ✅ Prerequisites

### 1. Install Rust

**macOS/Linux:**
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
```

**Windows:**
Download and run: https://rustup.rs/

**Verify installation:**
```bash
rustc --version
# Should show: rustc 1.75.0 or higher
```

### 2. Install Solana CLI

**macOS/Linux:**
```bash
sh -c "$(curl -sSfL https://release.solana.com/stable/install)"
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
```

**Windows:**
```powershell
cmd /c "curl https://release.solana.com/stable/solana-install-init-x86_64-pc-windows-msvc.exe --output C:\solana-install-tmp\solana-install-init.exe --create-dirs"
```

**Verify installation:**
```bash
solana --version
# Should show: solana-cli 1.18.0 or higher
```

### 3. Get a Helius RPC API Key

1. Visit: https://helius.dev
2. Sign up for free (Developer plan)
3. Create a new project
4. Copy your API key (starts with a long hex string)

**Why Helius?**
- Free tier: 100 requests/second
- Priority routing for faster confirmations
- Required for production-grade mining

---

## 💰 Wallet Setup

### Option A: Create New Wallet (Recommended for Testing)

```bash
# Create new keypair
solana-keygen new --outfile ~/.config/solana/mining-wallet.json

# View your wallet address
solana-keygen pubkey ~/.config/solana/mining-wallet.json

# Fund it with SOL (minimum 10 SOL for testing)
# Use a CEX like Coinbase, Binance, or Phantom wallet to send SOL
```

### Option B: Use Existing Wallet

```bash
# If you have an existing keypair file, note its path
# Common locations:
#   ~/.config/solana/id.json (default Solana CLI)
#   ~/.config/solana/devnet.json
#   ~/my-wallet.json

# SECURITY WARNING: NEVER share your keypair file or commit it to git
```

**Required Balance:**
- **Minimum:** 5 SOL (testing)
- **Recommended:** 20+ SOL (production mining)
- **Ideal:** 50+ SOL (sustained operation)

---

## 🔧 Bot Installation

### 1. Clone the Repository

```bash
# Clone the repo
git clone https://github.com/paragoner1/ore-mining-bot.git
cd ore-mining-bot

# Navigate to the bot directory
cd ore/ore_world_class_bot
```

### 2. Configure the Bot

```bash
# Copy the template config
cp config/production.template.toml config/production.toml

# Open the config file in your editor
nano config/production.toml  # or use vim, VS Code, etc.
```

**Edit these 3 critical fields:**

```toml
[solana]
# Replace YOUR_API_KEY_HERE with your Helius API key
rpc_url = "https://mainnet.helius-rpc.com?api-key=YOUR_API_KEY_HERE"

# Set your keypair path (use absolute path)
keypair_path = "/Users/yourname/.config/solana/mining-wallet.json"  # macOS/Linux
# OR
keypair_path = "C:\\Users\\YourName\\.config\\solana\\mining-wallet.json"  # Windows

[mining]
# Leave default for now (0.010 SOL per block)
base_stake = 0.010
```

**Save the file** (`Ctrl+X`, then `Y`, then `Enter` in nano)

### 3. Build the Bot

```bash
# Build in release mode (optimized for performance)
cargo build --release

# This will take 5-10 minutes on first build
# Grab coffee ☕
```

**Expected output:**
```
   Compiling ore_world_class_bot v0.1.0
    Finished release [optimized] target(s) in 8m 23s
```

### 4. Initialize Your Miner Account

**IMPORTANT:** Before mining, you need to register your wallet with the ORE program.

```bash
# Set your wallet as the default
solana config set --keypair ~/.config/solana/mining-wallet.json

# Check your balance
solana balance

# Register with the ORE program (one-time setup)
# This creates your miner PDA (Program Derived Address)
cargo run --release --bin ore -- register

# Expected output: "Miner account created successfully"
```

---

## 🏃 Running the Bot

### Quick Start (Foreground)

```bash
# Set environment variables
export ORE_BOT_CONFIG="config/production.toml"
export RUST_LOG=info

# Run the bot
./target/release/ore_world_class_bot
```

**You should see:**
```
🔍 Wallet: 7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU
🔍 Miner PDA: 9sgCSZ6Tji17zFPJcKYKS59AuRNo5NV7FTTFo2i589nu
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔷 ROUND 12345 STARTED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⏰ Waiting 45s → T-3s...
⚡ T-3s: Fetching grid...
💰 ✅ BASELINE | Deploying 0.200 SOL (0.0100/block × 20)
🎯 Best 20 blocks: [0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
✅ Confirmed in 1.2s
```

**Stop the bot:**
- Press `Ctrl+C` for graceful shutdown

### Production Mode (Background)

**macOS/Linux:**
```bash
# Run in background with auto-restart
nohup ./target/release/ore_world_class_bot > bot.log 2>&1 &

# Check if it's running
ps aux | grep ore_world_class_bot

# View logs in real-time
tail -f bot.log

# Stop the bot
pkill ore_world_class_bot
```

**Windows:**
```powershell
# Run in background
Start-Process -NoNewWindow -FilePath ".\target\release\ore_world_class_bot.exe" -RedirectStandardOutput "bot.log"

# View logs
Get-Content bot.log -Wait

# Stop the bot
Stop-Process -Name "ore_world_class_bot"
```

---

## 📊 Monitoring Your Bot

### Key Log Messages

| Message | Meaning |
|---------|---------|
| `🔷 ROUND X STARTED` | New 60-second round detected |
| `💰 🚀 ELEVATED` | High miner density, staking 0.0125 SOL/block |
| `💰 ✅ BASELINE` | Normal competition, staking 0.010 SOL/block |
| `💰 ⚠️ REDUCED` | Whale-heavy round, staking 0.006 SOL/block |
| `✅ Confirmed in X.Xs` | Transaction confirmed successfully |
| `⏭️ SKIPPING ROUND` | Round skipped (too competitive or error) |

### Health Checks

```bash
# Check SOL balance
solana balance

# Check recent transactions
solana transaction-history $(solana-keygen pubkey ~/.config/solana/mining-wallet.json) --limit 10

# Check bot is running
ps aux | grep ore_world_class_bot  # macOS/Linux
Get-Process ore_world_class_bot    # Windows
```

### Performance Expectations

**Normal Operation:**
- Cycle time: 54-60 seconds per round
- Confirmation time: 1-2 seconds
- Missed rounds: <2%
- Strategy: Adapts every round (ELEVATED/BASELINE/REDUCED)

**SOL Burn Rate:**
- Low competition: ~0.120 SOL/round (20 blocks × 0.006)
- Normal competition: ~0.200 SOL/round (20 blocks × 0.010)
- High competition: ~0.250 SOL/round (20 blocks × 0.0125)

**ORE Accumulation:**
- Varies based on wins and motherlode hits
- Check your miner balance: `cargo run --release --bin ore -- balance`

---

## 🔧 Troubleshooting

### Error: "blockhash not found"

**Cause:** Helius RPC overloaded or rate limited

**Fix:**
```toml
# In config/production.toml, try backup RPC
rpc_url = "https://api.mainnet-beta.solana.com"
```

### Error: "miner account not found"

**Cause:** You didn't register your miner account

**Fix:**
```bash
cargo run --release --bin ore -- register
```

### Error: "insufficient funds"

**Cause:** Your wallet balance is too low

**Fix:**
```bash
# Check balance
solana balance

# Add more SOL (send from CEX or another wallet)
```

### Error: "RPC rate limit exceeded"

**Cause:** Helius free tier limit exceeded (100 RPS)

**Fix:**
- The bot has a built-in rate limiter (10 RPS sustained, 30 burst)
- This should NOT happen in normal operation
- If it persists, upgrade to Helius paid tier ($99/mo for 1000 RPS)

### Error: "Transport error"

**Cause:** Network connectivity issue

**Fix:**
```bash
# Check internet connection
ping google.com

# Check Solana cluster status
solana cluster-version

# Restart the bot
pkill ore_world_class_bot
./target/release/ore_world_class_bot
```

### Bot Stops After a Few Rounds

**Cause:** Checkpoint fell behind, causing transaction errors

**Fix:**
- This is normal if you skip many rounds
- The bot will auto-recover in 1-2 rounds
- If it persists, restart the bot

### Confirmation Times >5 Seconds

**Cause:** Network congestion or Helius routing issue

**Fix:**
```toml
# Try the Helius sender endpoint (ultra-low latency)
rpc_sender_url = "https://sender.helius-rpc.com/fast?api-key=YOUR_API_KEY"
```

### Bot Shows 0% Win Rate

**Cause:** This is NORMAL. ORE mining is competitive.

**Reality Check:**
- Staking on 20/25 blocks = 80% coverage
- Win probability per block = 4% (1/25)
- Expected wins per round: 0.8 blocks (not guaranteed)
- Many rounds you won't win anything
- ROI comes from occasional wins + motherlode hits

---

## 🎛️ Advanced Configuration

### Adjust Stake Amounts

```toml
[mining]
# Stake MORE (aggressive - for low competition)
base_stake = 0.015

# Stake LESS (conservative - for high competition)
base_stake = 0.005
```

**Note:** The bot auto-adjusts based on competition. You rarely need to change this.

### Enable Priority Fees

```toml
[solana]
# Add priority fee (micro-lamports per compute unit)
priority_fee_micro_lamports = 5000000  # 0.005 SOL priority fee
```

**When to use:**
- During extreme network congestion
- If confirmations consistently take >3 seconds

**Trade-off:** Faster confirmations, but higher cost per transaction

### Custom RPC Endpoints

```toml
[solana]
# Primary RPC
rpc_url = "https://mainnet.helius-rpc.com?api-key=YOUR_KEY"

# Optional: Dedicated sender endpoint (ultra-low latency)
rpc_sender_url = "https://sender.helius-rpc.com/fast?api-key=YOUR_KEY"
```

### Logging Levels

```bash
# Minimal output (errors only)
export RUST_LOG=error

# Normal output (recommended)
export RUST_LOG=info

# Verbose output (debugging)
export RUST_LOG=debug

# Maximum verbosity (troubleshooting)
export RUST_LOG=trace
```

---

## 🆘 Getting Help

### Self-Service Resources

1. **Read the technical docs:**
   - [TECHNICAL_OVERVIEW.md](docs/TECHNICAL_OVERVIEW.md)
   - [ARCHITECTURE.md](docs/ARCHITECTURE.md)
   - [PERFORMANCE_ANALYSIS.md](docs/PERFORMANCE_ANALYSIS.md)

2. **Check GitHub Issues:**
   - https://github.com/paragoner1/ore-mining-bot/issues

3. **ORE Protocol Docs:**
   - https://ore.supply/docs

### Paid Support

**Can't figure it out? Stuck on setup? Want custom optimization?**

I offer professional setup and optimization services:

- **🚀 Complete Setup & Optimization** – $1,997
  - I'll do the entire setup for you
  - Custom config for your capital and goals
  - 2 weeks of support included

- **⚡ Monthly Support** – $497/month
  - Ongoing optimization as market changes
  - 24hr response time
  - Direct Telegram/Discord access

📧 paragoner.dev@gmail.com  
🐦 [@paragoner1](https://twitter.com/paragoner1)  
📅 [Book a consultation](CALENDLY_LINK_HERE)

**🎁 First 5 clients save $500 ($1,497 instead of $1,997)**

---

## ✅ Final Checklist

Before going to production, verify:

- [ ] Helius API key is valid
- [ ] Wallet has 20+ SOL
- [ ] Miner account is registered (`cargo run -- register`)
- [ ] Config file is saved with correct paths
- [ ] Bot runs without errors for 10+ rounds
- [ ] You understand the SOL burn rate
- [ ] You have auto-restart set up (for 24/7 operation)

---

## 🎉 You're Ready!

If you followed this guide, you should be mining successfully.

**Expected Results:**
- 99.8% uptime
- <2% missed rounds
- 54-60 second cycle times
- Adaptive stake sizing every round

**Remember:** ORE mining is competitive and speculative. Performance varies with market conditions.

Good luck, miner! ⛏️

---

**Built by [@paragoner1](https://twitter.com/paragoner1) · November 2025**

