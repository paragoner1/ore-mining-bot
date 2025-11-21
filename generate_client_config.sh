#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════
# PARAGONER ORE MINER - CLIENT CONFIG GENERATOR
# ═══════════════════════════════════════════════════════════════════════
#
# Usage: ./generate_client_config.sh <email> <tier>
#
# Example: ./generate_client_config.sh john@example.com pro
#
# ═══════════════════════════════════════════════════════════════════════

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <client_email> <tier>"
    echo "Example: $0 john@example.com pro"
    echo ""
    echo "Valid tiers: starter, pro, enterprise"
    exit 1
fi

CLIENT_EMAIL="$1"
CLIENT_TIER="$2"

# Generate unique license ID (8 random hex characters)
LICENSE_ID=$(openssl rand -hex 4)

# Get current date
ISSUE_DATE=$(date +%Y-%m-%d)

# Output filename
OUTPUT_FILE="client_configs/config_${LICENSE_ID}.toml"

# Create output directory if it doesn't exist
mkdir -p client_configs

# Copy template and replace placeholders
cp ore/ore_world_class_bot/config/client_template.toml "$OUTPUT_FILE"

# Replace placeholders (works on both macOS and Linux)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/CLIENT_ID_PLACEHOLDER/$LICENSE_ID/g" "$OUTPUT_FILE"
    sed -i '' "s/CLIENT_EMAIL_PLACEHOLDER/$CLIENT_EMAIL/g" "$OUTPUT_FILE"
    sed -i '' "s/CLIENT_TIER_PLACEHOLDER/$CLIENT_TIER/g" "$OUTPUT_FILE"
    sed -i '' "s/ISSUE_DATE_PLACEHOLDER/$ISSUE_DATE/g" "$OUTPUT_FILE"
else
    # Linux
    sed -i "s/CLIENT_ID_PLACEHOLDER/$LICENSE_ID/g" "$OUTPUT_FILE"
    sed -i "s/CLIENT_EMAIL_PLACEHOLDER/$CLIENT_EMAIL/g" "$OUTPUT_FILE"
    sed -i "s/CLIENT_TIER_PLACEHOLDER/$CLIENT_TIER/g" "$OUTPUT_FILE"
    sed -i "s/ISSUE_DATE_PLACEHOLDER/$ISSUE_DATE/g" "$OUTPUT_FILE"
fi

# Log the issuance
echo "$ISSUE_DATE,$LICENSE_ID,$CLIENT_EMAIL,$CLIENT_TIER" >> client_configs/license_registry.csv

echo "═══════════════════════════════════════════════════════════════════════"
echo "✅ CLIENT CONFIG GENERATED"
echo "═══════════════════════════════════════════════════════════════════════"
echo ""
echo "License ID:    $LICENSE_ID"
echo "Client Email:  $CLIENT_EMAIL"
echo "Tier:          $CLIENT_TIER"
echo "Issue Date:    $ISSUE_DATE"
echo ""
echo "Output File:   $OUTPUT_FILE"
echo ""
echo "═══════════════════════════════════════════════════════════════════════"
echo "NEXT STEPS:"
echo "═══════════════════════════════════════════════════════════════════════"
echo ""
echo "1. Send $OUTPUT_FILE to $CLIENT_EMAIL"
echo "2. Include PROPRIETARY_LICENSE.txt"
echo "3. Include setup instructions"
echo "4. Log recorded in client_configs/license_registry.csv"
echo ""
echo "═══════════════════════════════════════════════════════════════════════"

