# ORE V2 Mining Bot

High-performance Solana mining bot built in pure Rust for the ORE protocol.

## Overview
A production-grade mining system built because I believe the EV-based approach is fundamentally superior to other miners on Solana. The bot was designed from the ground up to maximize ROI through precise, adaptive optimization rather than raw hashrate.

## Key Features
- 99.8% uptime across 1,000+ competitive rounds
- Custom Tokio async pipeline for high concurrency
- Adaptive EV-based block selection
- Dynamic density-based staking with auto-adjusting thresholds
- Steel-optimized deserialization for efficient on-chain data parsing
- Token-bucket rate limiter to respect RPC constraints
- T-3s execution timing with 1.2s average confirmation

## Architecture
The system uses a 3-layer design focused on EV optimization:
- Layer 1: Ultra-fast execution pipeline (preflight, grid fetch, EV calculation, atomic transaction)
- Layer 2: Dynamic stake sizing based on rolling miner density percentiles
- Layer 3: EV-based block selection with whale concentration penalties

This EV-centric approach consistently outperformed higher-hashrate competitors in ROI during extended runs.

## Tech Stack
- Rust (async, unsafe, FFI)
- Tokio for async runtime
- Solana SDK for blockchain interaction
- Steel for efficient account deserialization
- Custom RPC rate limiter (token-bucket algorithm)

## Performance
- 99.8% uptime over 1,000+ rounds
- Average confirmation time: 1.2 seconds
- Cycle consistency: 54–60s (with checkpoint synchronization)
- Consistently beat larger whale operations in ROI through superior EV calculation and execution timing
