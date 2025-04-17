#!/bin/bash

# This script runs the migration to add sample campaign results data

# Navigate to the project directory
cd "$(dirname "$0")"

# Check if the supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "Error: supabase CLI is not installed. Please install it first."
    exit 1
fi

# Run the migration
echo "Running migration to add sample campaign results data..."
psql "$(supabase db connection-string)" -f supabase/migrations/20250330996000_add_sample_campaign_results_data.sql

echo "Migration completed successfully!"
