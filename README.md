# ORE V3 Mining Bot

**A high-performance Solana mining bot for the ORE V3 protocol**

[![Status](https://img.shields.io/badge/Status-Production-success)]()
[![Platform](https://img.shields.io/badge/Platform-Solana-blueviolet)]()
[![Language](https://img.shields.io/badge/Language-Rust-orange)]()

---

## 💼 Professional Services – Limited Spots

This bot is fully open source and free to use.

The real value is in optimization for your specific capital, RPC setup, and risk tolerance.

I offer paid services for serious miners:

### 🚀 Complete Setup & Optimization – $1,997
- Custom configuration for your wallet and capital allocation
- RPC endpoint optimization and testing
- Performance tuning and competitive analysis
- 2 weeks of follow-up support

### ⚡ Monthly Optimization & Support – $497/month
- Ongoing strategy adjustments
- Priority support (24hr response)
- Performance monitoring and reporting
- Direct Telegram/Discord access

### 🏢 Multi-Wallet & Enterprise – Starting at $8k
- Multi-wallet orchestration (5-20+ independent instances)
- Custom strategy development for your capital and risk profile
- Advanced RPC infrastructure with redundancy and failover
- Performance optimization and ongoing tuning
- Priority support with <2hr response time
- Dedicated communication channel (Telegram/Discord)

Limited to 10 clients at a time.

📧 paragoner.dev@gmail.com  
🐦 [@paragoner1](https://twitter.com/paragoner1)  
📅 Book a call: [CALENDLY_LINK_HERE]

**🎁 Early access:** First 5 clients pay $1,497 (save $500)

---

## 🎯 Overview

This is a production-grade automated mining bot for Solana's ORE V3 protocol—a competitive proof-of-work mining game where miners stake SOL on a 5×5 grid every 60 seconds. One block wins, and SOL redistributes from losers to winners.

**The Challenge:** Competing with whales deploying 10-100x more capital in a zero-sum game.

**The Solution:** A 3-layer adaptive system using real-time on-chain data, dynamic stake sizing, and EV-based block selection to compete algorithmically rather than just with capital.

---

## 🚀 Key Features

### ⚡ Ultra-Fast Execution
- **T-3s execution:** Fetches grid data 3 seconds before round end (top-tier timing)
- **1.2s avg confirmation:** Sub-2-second transaction confirmation
- **99.8% uptime:** Production-grade reliability over 1000+ rounds
- **<2% missed rounds:** Down from 15-20% in initial versions

### 🧠 Intelligent Decision Making
- **Dynamic density-based staking:** Adjusts stake amounts based on rolling percentile thresholds
- **EV-based block selection:** Ranks all 25 blocks by expected value, not just "lowest SOL"
- **Whale concentration penalties:** Avoids blocks dominated by large stakers
- **Motherlode-aware:** Factors in 1/625 chance of 100x+ rewards

### 🔄 Adaptive System
- **Rolling 125-round history:** Thresholds adapt to changing market conditions
- **3-tier stake system:** ELEVATED (0.0125), BASELINE (0.010), REDUCED (0.0060) SOL/block
- **Auto-adjusting percentiles:** 25th/75th percentile thresholds recalculate every round
- **Zero manual tuning:** Bot adapts as competition changes

### 🛡️ Production-Grade Engineering
- **Custom RPC rate limiter:** Token-bucket algorithm prevents Helius throttling
- **Corrupted data handling:** Validates timing data, uses safe fallbacks
- **Checkpoint synchronization:** Prevents cascade delays from round skips
- **Dual-wallet support:** Run 2 bots simultaneously on independent wallets

---

## 📊 Performance Metrics

```
Execution Speed:     1.2s avg confirmation (T-3s timing)
Success Rate:        99.8% uptime, <2% missed rounds
Cycle Consistency:   54-60s cycles (vs 86s with checkpoint issues)
Adaptability:        Auto-adjusts to 3x competition swings
ROI:                 Near net-neutral (varies with SOL/ORE price fluctuations)
```

Strategy balances ORE accumulation with SOL sustainability, adapting to market conditions.

---

## 🏗️ Architecture

### Layer 1: Ultra-Lean Pipeline
```
T-20s:  Preflight check (cache Board/Miner state)
T-3s:   Fetch Grid (freshest competition data)
T-2.5s: Calculate EV for all 25 blocks
T-2s:   Build atomic transaction (checkpoint + 20 deploys)
T-1s:   Confirm (avg 1.2s with skip_preflight)
```

**Key insight:** Separate slow-changing data (Board/Miner) from fast-changing data (Grid). Cache the former, fetch the latter at the last possible moment.

### Layer 2: Dynamic Density-Based Staking
```rust
// Core metric: Miners per SOL (higher = better value)
miner_density = total_miners / total_sol

// Auto-adapting thresholds from rolling 125-round history
(p25, p75) = percentile(last_125_rounds.density)

if density > p75:    stake = 0.0125 SOL/block  // Top 25% rounds
elif density > p25:  stake = 0.010 SOL/block   // Middle 50%
else:                stake = 0.0060 SOL/block  // Bottom 25% (whale-heavy)
```

**Key insight:** React to *relative* competition, not absolute. Bot auto-adapts as market conditions change.

### Layer 3: EV-Based Block Selection
```rust
for each block:
    // Calculate expected value considering:
    // 1. Our stake across ALL blocks (affects losing pool)
    // 2. Win probability (1/25 = 4%)
    // 3. SOL reward (our_share × losing_pool × 0.9)
    // 4. ORE reward (1 ORE + 1/625 chance of motherlode)
    // 5. Whale concentration penalty
    
    ev_score = (sol_reward + ore_reward - total_stake) × 0.04 × penalty

// Select top 20 blocks by EV score
```

**Key insight:** EV must account for how our own stakes affect the calculation. Penalize whale-dominated blocks even if they have "low SOL" on paper.

---

## 🛠️ Tech Stack

**Core:**
- **Rust** - Systems programming for performance
- **Tokio** - Async runtime for concurrent RPC calls
- **Solana SDK** - Blockchain interaction and transaction building

**Optimization:**
- **Custom RPC Rate Limiter** - Token-bucket algorithm (10 RPS sustained, 30 burst)
- **Steel** - Efficient Solana account deserialization
- **Statistical Modeling** - Percentile calculations, EV analysis, rolling windows

**Infrastructure:**
- **Helius Developer Plan** - 100 RPS RPC endpoint with priority routing
- **Dual-binary compilation** - Independent operation of multiple wallets
- **Auto-restart scripts** - 24/7 reliability with health monitoring

---

## 🚀 Quick Start

### Prerequisites

- Rust (1.75+): `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`
- Solana CLI: `sh -c "$(curl -sSfL https://release.solana.com/stable/install)"`
- Helius API key: [Sign up at helius.dev](https://helius.dev)
- SOL balance: 10+ SOL recommended for initial testing

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/ore-mining-bot.git
cd ore-mining-bot

# Navigate to bot directory
cd ore/ore_world_class_bot

# Copy and configure the template
cp config/production.template.toml config/production.toml
# Edit config/production.toml:
#   - Add your Helius API key
#   - Set your keypair path (default: ~/.config/solana/id.json)

# Build the bot
cargo build --release
```

### Running the Bot

```bash
# Set environment variables
export ORE_BOT_CONFIG="config/production.toml"
export RUST_LOG=info

# Run the bot
./target/release/ore_world_class_bot
```

**Monitor output:**
- `🔷 ROUND X STARTED` - New round detected
- `💰 ELEVATED/BASELINE/REDUCED | Deploying X SOL` - Stake tier decision
- `🎯 Best 20 blocks: [...]` - Selected blocks
- `✅ Confirmed in Xs` - Transaction confirmed

**Stop the bot:**
- Press `Ctrl+C` for graceful shutdown

---

## 📁 Project Structure

```
ore-mining-bot/
├── docs/                              # Technical documentation
│   ├── TECHNICAL_OVERVIEW.md          # System design & algorithms
│   ├── ARCHITECTURE.md                # Component architecture
│   └── PERFORMANCE_ANALYSIS.md        # Data-driven performance metrics
│
├── ore/                               # Ore protocol (submodule)
│   └── ore_world_class_bot/          # Bot implementation
│       ├── src/
│       │   ├── main.rs                # Main bot loop & orchestration
│       │   ├── execution_engine.rs    # Solana RPC + transaction handling
│       │   ├── probabilistic_optimizer.rs  # Adaptive stake sizing
│       │   ├── saturation_analysis.rs      # EV calculations + block selection
│       │   ├── grid_intelligence.rs        # Grid state management
│       │   ├── rpc_rate_limiter.rs        # Custom token-bucket rate limiter
│       │   ├── monitoring.rs               # Health tracking
│       │   ├── config.rs                   # Configuration management
│       │   └── types.rs                    # Core data structures
│       ├── config/
│       │   └── production.template.toml    # Configuration template
│       └── Cargo.toml                      # Dependencies
│
├── README.md                          # This file
├── LICENSE                            # MIT License
└── .gitignore                         # Excludes keypairs, logs, configs
```

---

## 🎓 Technical Highlights

### Solana-Specific Optimizations
- **Transaction optimization:** `skip_preflight`, atomic checkpoint+deploy, zero priority fees
- **PDA derivation:** Program Derived Addresses for miner account management
- **RPC burst management:** Custom rate limiter prevents throttling under load
- **State deserialization:** Steel library for efficient on-chain data parsing

### Systems Design
- **Real-time decision making:** Sub-3-second pipeline from data fetch to confirmation
- **Async Rust patterns:** Non-blocking I/O, concurrent RPC calls, Tokio runtime
- **Statistical modeling:** Dynamic percentile thresholds, EV calculations, rolling windows
- **Edge case handling:** Corrupted timing data, RPC timeouts, checkpoint sync issues

### Production Operations
- **24/7 reliability:** Auto-restart scripts, health monitoring (100/100 score)
- **Observability:** Structured logging with performance metrics
- **Capital management:** Auto-reload support, balance tracking, burn rate monitoring
- **Multi-wallet scalability:** Dual-binary approach for independent wallet operation

---

## 📈 Evolution & Optimization

**Problem Evolution:**
1. **Initial:** "Stake on least saturated blocks" → Unprofitable (whales dominated)
2. **Iteration 1:** Time-based multipliers → Failed (market patterns shifted daily)
3. **Iteration 2:** Fixed ROI thresholds → Too rigid (skipped good rounds)
4. **Current:** Dynamic density-based system → Adapts to market automatically ✅

**Key Breakthroughs:**
- **Miner density > ROI:** Simpler metric, more predictive, auto-adapting
- **T-3s timing:** Maximum data freshness while leaving 2.5s execution buffer
- **Percentile thresholds:** Relative competition measurement vs absolute values
- **Never skip rounds:** Prevents checkpoint delays, maintains sync with blockchain

---

## 🎯 Real-World Results

**Success Metrics:**
```
Rounds Processed:    1000+ rounds continuously
Tier Distribution:   45% REDUCED, 35% BASELINE, 20% ELEVATED
Avg Competition:     1.8-3.3 SOL/block (adaptive range)
Miner Density:       355-628 miners/SOL (dynamic thresholds)
RPC Throttling:      0 errors (custom rate limiter working)
```

**Current Strategy:**
- **Goal:** Maximize ORE accumulation during price discovery phase
- **Trade-off:** Accept SOL burn to accumulate ORE tokens
- **Thesis:** ORE price appreciation (currently $400) justifies SOL burn
- **Status:** Actively mining when competition is favorable

---

## 💡 Key Takeaways

**System Engineering:**
- Building high-performance systems under Solana's constraints (400ms slots, RPC limits)
- Balancing data freshness vs execution time (T-3s timing solution)
- Handling rate limits and burst traffic (custom token-bucket rate limiter)
- Production-grade error handling (corrupted data, RPC timeouts, state synchronization)

**Algorithm Design:**
- Adaptive algorithms that require no manual tuning (percentile-based thresholds)
- Reasoning economically in zero-sum competitive environments
- Simple metrics outperform complex ones (miner density > multi-factor ROI)
- Real-time decision making with sub-3-second pipeline latency

**Production Operations:**
- 99.8% uptime with real capital at risk
- Comprehensive observability through structured logging
- Data-driven iteration (3 major strategy revisions based on performance analysis)
- Maintainability through clear separation of concerns and documentation
- Build for adaptability, not just current conditions
- Ship and learn, not perfect then ship

---

## 📚 Documentation

Comprehensive technical documentation available in the `docs/` directory:
- **[TECHNICAL_OVERVIEW.md](docs/TECHNICAL_OVERVIEW.md)** - System design and core concepts
- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - Component architecture and implementation details
- **[PERFORMANCE_ANALYSIS.md](docs/PERFORMANCE_ANALYSIS.md)** - Data-driven performance metrics

---

## 🚀 Current Status

**Production:** Active mining with ongoing optimizations  
**Performance:** 99.8% uptime, <2% missed rounds  
**Strategy:** Dynamic density-based adaptive staking  

**Last Updated:** November 2025

---

## ⚠️ Disclaimer

This is educational/portfolio software. ORE V3 mining is speculative and competitive. Performance varies with market conditions and SOL/ORE price ratios. Use at your own risk.

---

**🎯 The Bottom Line:** A system that adapts faster than the market shifts. Competing with whales using better algorithms, not just bigger capital.
