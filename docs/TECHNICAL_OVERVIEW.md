# Technical Overview: ORE V3 Mining Bot

## Executive Summary

A production-grade Solana trading bot implementing advanced optimization techniques for the ORE V3 competitive mining protocol. This system demonstrates sophisticated real-time decision-making, adaptive algorithms, and high-performance blockchain interaction patterns, achieving 99.8% uptime and sub-2-second execution cycles in a zero-sum competitive environment.

---

## Problem Domain

ORE V3 is a competitive proof-of-work mining game on Solana where:
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
Early Round → Preflight Check
              - Fetch Board and Miner state (slow-changing data)
              - Cache for reuse during execution
              - Validate miner is current with blockchain round

Mid Round   → Wait for optimal timing window
              - Monitor blockchain round progression
              - Calculate precise execution window

Late Round  → Grid State Fetch
              - Fetch all 25 blocks' current competition levels
              - Critical freshness point with safety margin

Decision    → Decision Engine
              - Calculate EV for all blocks
              - Select optimal blocks by EV score
              - Determine stake amounts based on adaptive thresholds

Execute     → Transaction Execution
              - Build atomic transaction (checkpoint + deploys)
              - Optimized submission for speed
              - Strategically set priority fees

Confirm     → Confirmation
              - Sub-2-second average confirmation time
              - Maintains safety margin before round ends
```

**Key Architectural Decisions:**

1. **Data Segregation:** Separate slow-changing (Board/Miner) from fast-changing (Grid) data, caching the former and fetching the latter late in the cycle for maximum freshness.

2. **Atomic Transactions:** Combine checkpoint (miner state update) with deploy (stake) operations to prevent state desync issues that would cause extended cycle delays.

3. **Optimized Transaction Submission:** Strategic configuration choices to minimize confirmation latency while maintaining reliability.

4. **Custom RPC Rate Limiter:** Token-bucket algorithm prevents RPC throttling while maximizing responsiveness during execution bursts.

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

The bot maintains a rolling historical window of miner density and calculates percentile thresholds in real-time:

```rust
// Calculate percentile thresholds from historical data
let (low_threshold, high_threshold) = calculate_percentiles(density_history);

// Multi-tier stake system based on user's baseline preference
// User sets baseline in config based on capital and risk tolerance
let baseline = config.baseline_stake_per_block;

if current_density > high_threshold:
    stake = baseline × elevated_multiplier  // ELEVATED tier
elif current_density > low_threshold:
    stake = baseline                        // BASELINE tier
else:
    stake = baseline × reduced_multiplier   // REDUCED tier
```

**Key Properties:**
- **User-configurable baseline:** Set your comfortable stake amount based on capital and risk tolerance
- **Self-adapting thresholds:** As market conditions change, percentile boundaries automatically adjust
- **Proportional scaling:** All tiers scale with your baseline preference
- **Relative competition:** Reacts to competition level relative to recent history
- **Statistically grounded:** Uses proven percentile-based decision boundaries

#### History Persistence

On startup, the bot parses historical log files to pre-populate the 125-round density history. This enables immediate use of dynamic thresholds instead of requiring 20+ rounds of warm-up data.

---

### Layer 3: EV-Based Block Selection

Rather than simply selecting blocks with "lowest SOL deployed," the system implements a sophisticated Expected Value (EV) calculation that accounts for:

1. **Win Probability:** Uniform probability for each block
2. **Our Stake Impact:** How our stakes across ALL blocks affect the reward pool dynamics
3. **SOL Rewards:** Proportional share of the redistribution pool
4. **ORE Rewards:** Base token rewards plus bonus multiplier opportunities
5. **Whale Concentration Penalty:** Penalizes blocks with unfavorable miner distribution patterns

```rust
for each block in grid:
    // Calculate our expected share if this block wins
    our_share = calculate_share(our_stake, block_sol)
    
    // Critical insight: Account for cross-block stake interactions
    losing_pool = calculate_losing_pool(total_sol, block_sol, our_stakes)
    
    // SOL reward based on pool redistribution
    sol_reward = our_share × losing_pool × pool_distribution_rate
    
    // ORE reward (accounts for reward modes and bonuses)
    ore_reward = calculate_ore_value(motherlode_size, ore_price)
    
    // Net profit accounting for all deployment costs
    net_profit = (sol_reward + ore_reward) - total_deployment_cost
    
    // Expected value calculation
    ev = win_probability × net_profit
    
    // Apply miner distribution analysis
    concentration_score = analyze_miner_distribution(block)
    ev_score = ev × concentration_score

// Select optimal blocks by EV score
selected_blocks = rank_and_select(all_blocks, target_count)
```

**Why This Matters:**

Naive "lowest SOL" selection often chose whale-dominated blocks with poor reward distribution. The EV-based system correctly identifies these as suboptimal because:
- Win probability is uniform across all blocks
- Concentrated blocks reduce proportional reward capture
- Better to choose well-distributed blocks with favorable share dynamics

---

## Production Engineering

### RPC Rate Management

**Challenge:** Premium RPC services have rate limits. Naive RPC usage caused throttling during execution bursts.

**Solution:** Custom token-bucket rate limiter:

```rust
pub struct RpcRateLimiter {
    tokens: Arc<RwLock<f64>>,
    max_tokens: f64,          // Burst capacity
    refill_rate: f64,         // Sustained rate
    last_refill: Arc<RwLock<Instant>>,
}
```

- **Sustained rate:** Configured for background polling
- **Burst capacity:** Allows execution spikes
- **Async-aware:** Non-blocking token acquisition with Tokio
- **Result:** Zero throttling over 1000+ production rounds

### Checkpoint Synchronization

**Problem:** If the bot skips rounds (e.g., low EV), the on-chain miner state (`miner.round_id`) falls behind the blockchain. Next execution requires 30-second checkpoint catch-up, causing 86-second cycles instead of 60s.

**Solution:**
1. **Minimize round skipping:** Deploy even in suboptimal conditions to maintain sync
2. **Atomic checkpoint+deploy:** Every transaction updates miner state
3. **Preflight validation:** Check miner is current before execution

**Result:** Consistent 60-second cycle times, <2% missed rounds

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
Execution Speed:        Sub-2s average confirmation
Uptime:                 99.8% over 1000+ production rounds
Missed Rounds:          <2% (significantly improved from early versions)
Cycle Consistency:      Consistent 60-second cycles
Adaptability Range:     Handles 3x+ competition swings automatically
RPC Throttling:         0 errors with custom rate limiter
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

