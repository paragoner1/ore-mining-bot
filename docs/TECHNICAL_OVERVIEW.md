# Technical Overview: ORE V2 Mining Bot

## Executive Summary

A production-grade Solana trading bot implementing advanced optimization techniques for the ORE V2 competitive mining protocol. This system demonstrates sophisticated real-time decision-making, adaptive algorithms, and high-performance blockchain interaction patterns, achieving 99.8% uptime and sub-2-second execution cycles in a zero-sum competitive environment.

---

## Problem Domain

ORE V2 is a competitive proof-of-work mining game on Solana where:
- Every 60 seconds, a new mining round begins
- Miners stake SOL on a 5×5 grid (25 blocks)
- One block wins randomly (weighted by total SOL deployed)
- Winners receive proportional shares of the losing pool + 1 ORE token
- 50% of rounds split rewards among all winners; 50% use winner-take-all
- Additional 0.16% chance of "motherlode" bonus (100x+ rewards)

**The Challenge:** Competing against well-capitalized players (10-100x more capital) in a fully transparent, zero-sum game where all participants see the same data simultaneously.

**The Solution:** Instead of competing purely on capital, leverage algorithmic advantage through superior timing, intelligent block selection, and adaptive stake sizing.

---

## System Architecture

### Layer 1: Ultra-Fast Execution Pipeline

The bot operates on an aggressive timing strategy, fetching data and executing at the last possible moment to minimize information staleness:

```
T-20s  → Preflight Check
         - Fetch Board and Miner state (slow-changing data)
         - Cache for reuse during execution
         - Validate miner is current with blockchain round

T-5s   → Wait for optimal timing window
         - Monitor blockchain round progression
         - Calculate precise execution window

T-3s   → Grid State Fetch
         - Fetch all 25 blocks' current competition levels
         - This is the critical freshness point
         - 1.9-second safety margin before round end

T-2.5s → Decision Engine
         - Calculate EV for all 25 blocks
         - Select optimal 20 blocks by EV score
         - Determine stake amounts based on density thresholds

T-2s   → Transaction Execution
         - Build atomic transaction (checkpoint + 20 deploys)
         - Send with skip_preflight for speed
         - Zero priority fees (validated to be effective)

T-1s   → Confirmation
         - Average 1.2-second confirmation time
         - 0.8-1.3s safety margin before round ends
```

**Key Architectural Decisions:**

1. **Data Segregation:** Separate slow-changing (Board/Miner) from fast-changing (Grid) data, caching the former and fetching the latter at T-3s for maximum freshness.

2. **Atomic Transactions:** Combine checkpoint (miner state update) with deploy (stake) operations to prevent state desync issues that would cause 86-second cycle delays.

3. **Skip Preflight:** Bypass preflight checks to prevent blockhash expiration during simulation, reducing confirmation time from 3.5s to 1.2s.

4. **Custom RPC Rate Limiter:** Token-bucket algorithm (10 sustained / 30 burst RPS) prevents Helius throttling while maximizing responsiveness.

---

### Layer 2: Adaptive Decision System

The bot implements a three-tier adaptive system that automatically adjusts to market conditions without manual intervention:

#### Core Metric: Miner Density

Instead of raw ROI calculations (which require price assumptions and complex formulas), the system uses a simpler, more robust metric:

```
Miner Density = Total Miners ÷ Total SOL Deployed
```

**Why this works:**
- High density = many small players competing (retail-heavy rounds)
- Low density = few large players (whale-dominated rounds)
- Directly correlates with "value" per SOL deployed
- No assumptions about ORE price needed
- Real-time, blockchain-derived metric

#### Dynamic Threshold System

The bot maintains a rolling 125-round history (≈2.3 hours) of miner density and calculates percentile thresholds in real-time:

```rust
// Calculate 25th and 75th percentiles from history
let (p25, p75) = calculate_percentiles(last_125_rounds.density);

// 3-tier stake system
if current_density > p75:
    stake = 0.0125 SOL/block  // ELEVATED (top 25% rounds)
elif current_density > p25:
    stake = 0.010 SOL/block   // BASELINE (middle 50%)
else:
    stake = 0.006 SOL/block   // REDUCED (bottom 25%, whale-heavy)
```

**Key Properties:**
- **Self-adapting:** As market conditions change, thresholds automatically adjust
- **Relative competition:** Reacts to competition level relative to recent history
- **No manual tuning:** Zero configuration required as market evolves
- **Statistically grounded:** Uses proven percentile-based decision boundaries

#### History Persistence

On startup, the bot parses historical log files to pre-populate the 125-round density history. This enables immediate use of dynamic thresholds instead of requiring 20+ rounds of warm-up data.

---

### Layer 3: EV-Based Block Selection

Rather than simply selecting the 20 blocks with "lowest SOL deployed," the system implements a sophisticated Expected Value (EV) calculation that accounts for:

1. **Win Probability:** 1/25 (4%) for each block
2. **Our Stake Impact:** How our stakes across ALL blocks affect the losing pool
3. **SOL Rewards:** Proportional share of 90% of losing pool
4. **ORE Rewards:** Base 1 ORE + 1/625 chance of motherlode bonus
5. **Whale Concentration Penalty:** Penalizes blocks with high SOL-per-miner ratios

```rust
for each block in grid:
    // Calculate our share if this block wins
    our_share = our_stake / (block_sol + our_stake)
    
    // Critical insight: Our OTHER stakes become part of losing pool
    our_stakes_on_other_blocks = (num_blocks - 1) × our_stake
    losing_pool = total_sol - block_sol + our_stakes_on_other_blocks
    
    // SOL reward (90% of losing pool goes to winners)
    sol_reward = our_share × losing_pool × 0.9
    
    // ORE reward (accounts for split vs WTA + motherlode)
    ore_reward = calculate_ore_value(motherlode_size, ore_price)
    
    // Net profit (must subtract ALL our stakes, not just this block)
    net_profit = (sol_reward + ore_reward) - total_our_stake
    
    // Expected value
    ev = 0.04 × net_profit
    
    // Apply whale concentration penalty
    if miners == 0:
        penalty = 0.1  // Suspicious empty block
    elif sol_per_miner > 0.01:
        penalty = 0.5  // Whale-dominated
    elif sol_per_miner > 0.005:
        penalty = 0.8  // Moderately concentrated
    else:
        penalty = 1.0  // Distributed competition
    
    ev_score = ev × penalty

// Select top 20 blocks by EV score
selected_blocks = sort_by_ev_score(all_blocks)[0:20]
```

**Why This Matters:**

Early versions used naive "lowest SOL" selection, which often chose whale-dominated blocks (e.g., one player staking 0.05 SOL alone). The EV-based system correctly identifies these as poor choices because:
- Win probability is uniform (1/25)
- Whale captures most of the rewards if that block wins
- Better to choose evenly distributed blocks where we capture more share

---

## Production Engineering

### RPC Rate Management

**Challenge:** Helius Developer plan limits to 100 RPS with burst tolerance. Naive RPC usage caused throttling (429 errors) during T-3s execution burst.

**Solution:** Custom token-bucket rate limiter:

```rust
pub struct RpcRateLimiter {
    tokens: Arc<RwLock<f64>>,
    max_tokens: f64,          // 30 (burst capacity)
    refill_rate: f64,         // 10 per second (sustained)
    last_refill: Arc<RwLock<Instant>>,
}
```

- **Sustained:** 10 RPS for background polling
- **Burst:** 30 tokens for T-3s execution spike
- **Async-aware:** Non-blocking token acquisition with Tokio
- **Result:** Zero throttling over 1000+ production rounds

### Checkpoint Synchronization

**Problem:** If the bot skips rounds (e.g., low EV), the on-chain miner state (`miner.round_id`) falls behind the blockchain. Next execution requires 30-second checkpoint catch-up, causing 86-second cycles instead of 60s.

**Solution:**
1. **Never skip rounds:** Even in negative EV scenarios, deploy minimal stake (0.004 SOL × 20 blocks)
2. **Atomic checkpoint+deploy:** Every transaction updates miner state
3. **Preflight validation:** Check miner is current before execution

**Result:** 54-60s consistent cycle times, <2% missed rounds

### Corrupted Timing Data Handling

**Issue:** During round transitions, Solana can return `u64::MAX` for `end_slot`, causing timing calculation to overflow and skip rounds.

**Solution:**
```rust
if timing.end_slot == u64::MAX || timing.end_slot < current_slot {
    warn!("Corrupted timing data detected - using safe fallback");
    return Err(anyhow!("Invalid round timing"));
}
```

Validate all timing data before calculations, fail gracefully, and retry on next poll cycle.

---

## Performance Metrics

```
Execution Speed:        1.2s avg confirmation (T-3s timing)
Uptime:                 99.8% (8 failures in 1000+ rounds)
Missed Rounds:          <2% (down from 15-20% in v1)
Cycle Consistency:      54-60s (vs 86s with checkpoint issues)
Capital Deployed:       ~$47K/day (293 SOL at $160/SOL)
Adaptability Range:     Handles 3x competition swings automatically
RPC Throttling:         0 errors (with custom rate limiter)
```

**Current Trade-off:**
- Negative SOL ROI (-25%/round average) in current high-competition market
- Positive ORE accumulation during price discovery phase
- Strategy optimizes for ORE maximization, not SOL sustainability
- Thresholds tuned for aggressive accumulation during market growth

---

## Key Technical Achievements

### Solana-Specific Optimizations
- Program Derived Address (PDA) derivation for miner account management
- Atomic transaction composition (checkpoint + multiple deploy instructions)
- `skip_preflight` optimization for 2.3x faster confirmations
- Zero priority fees (validated effective through transaction monitoring)
- Efficient on-chain state deserialization using Steel library

### Systems Programming
- Async Rust with Tokio runtime for concurrent RPC operations
- Lock-free concurrent data structures (DashMap, RwLock)
- Rolling window statistical calculations (percentiles, moving averages)
- Token-bucket rate limiting algorithm
- Non-blocking I/O throughout execution pipeline

### Algorithm Design
- Dynamic percentile-based threshold adaptation
- Multi-factor EV scoring with penalty weights
- History persistence and warm-start from log files
- Real-time statistical modeling without external data dependencies

---

## Future Optimization Opportunities

1. **Machine Learning Integration:** Train on 10K+ historical rounds to predict optimal density thresholds
2. **Cross-Block Correlation Analysis:** Identify patterns in which blocks tend to win together
3. **Latency Optimization:** Move to dedicated bare-metal server closer to Solana validators
4. **Dynamic ORE Price Integration:** Fetch real-time ORE/SOL price for more accurate EV calculations
5. **Multi-Strategy Portfolio:** Run multiple strategies simultaneously with different risk profiles

---

## Technical Stack

**Core:**
- Rust (systems programming for performance and safety)
- Tokio (async runtime)
- Solana SDK (blockchain interaction)

**Optimization:**
- Custom RPC rate limiter (token-bucket)
- Steel (efficient account deserialization)
- Statistical libraries (percentile calculations, distributions)

**Infrastructure:**
- Helius Developer RPC (100 RPS, priority routing)
- Git submodules (ore protocol)
- TOML configuration (environment-specific settings)

---

## Conclusion

This system demonstrates production-grade software engineering applied to a competitive algorithmic trading environment. The architecture prioritizes:

1. **Speed:** Sub-2-second execution with T-3s timing
2. **Reliability:** 99.8% uptime through robust error handling
3. **Adaptability:** Self-tuning thresholds that track market conditions
4. **Intelligence:** Sophisticated EV calculations vs naive heuristics

The result is a bot that competes algorithmically rather than purely on capital, achieving consistent performance in a zero-sum game against well-funded competitors.

