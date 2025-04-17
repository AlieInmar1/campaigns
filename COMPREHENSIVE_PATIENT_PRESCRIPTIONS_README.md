# Comprehensive Patient Prescriptions Dataset

This document explains the comprehensive patient prescriptions dataset created by the migration file `supabase/migrations/20250330700000_comprehensive_patient_prescriptions.sql`.

## Overview

The patient prescriptions dataset creates realistic prescription data with the following characteristics:

- **~1000 prescriptions per provider** (varying by prescribing volume)
- **~75 patients per provider** (carefully distributed to maintain realistic patterns)
- **Uses existing patients from the database** (no new patient generation)
- **Specialty-appropriate medications** (providers prescribe medications relevant to their specialty)
- **Generic vs. brand name preferences** (varies by provider based on specialty and practice size)
- **Realistic refill patterns** (with appropriate refill counts for chronic vs. acute medications)
- **Realistic patient distribution** (patients don't see multiple providers in the same specialty)

## Key Features of the Dataset

### Provider Behavior Modeling

- **Specialty-Specific Prescribing**: Cardiologists prescribe cardiovascular medications, psychiatrists prescribe psychiatric medications, etc.
- **Brand vs. Generic Preferences**: Some specialties and practice types tend to prescribe more brand-name medications
- **Volume-Based Distribution**: Providers marked as "high volume" prescribe more medications than "low volume" providers
- **Realistic Refill Patterns**: Chronic medications receive more refills than acute medications

### Patient Assignment Logic

- Patients are pre-assigned to specialties, ensuring no patient sees multiple providers in the same specialty
- Geographic distribution is considered (patients typically see providers in their region)
- Each provider has approximately 75 patients, with variations based on prescribing volume

### Medication Logic

- Medications are matched to provider specialties
- Chronic vs. acute medications have different patterns for:
  - Quantity (30/60/90 day supplies for chronic vs. smaller quantities for acute)
  - Refills (more refills for chronic medications)
  - Days supply (aligned with quantity for chronic medications)

### Prescription Date Patterns

- Realistic date distribution over the past two years
- 90% of prescriptions are filled (with realistic fill date delays)
- 70% are new prescriptions, 30% are refills

## Data Generation Process

1. **Patient Selection**: Uses existing patients from the database (assumes ~100K patients already exist)
2. **Specialty Mapping**: Pre-assigns patients to specialties to maintain realistic distribution
3. **Geographic Matching**: Prioritizes matching patients to providers in the same geographic region
4. **Provider Processing**: Processes each provider to determine their prescribing preferences and patterns
5. **Medication Selection**: For each provider, identifies appropriate medications for their specialty
6. **Prescription Generation**: Creates realistic prescriptions with appropriate parameters
7. **Index Creation**: Adds indexes to optimize query performance

## Schema Details

The patient_prescriptions table includes:

- `id`: UUID primary key
- `provider_id`: Link to the provider (TEXT)
- `patient_id`: Link to the patient (UUID)
- `medication_id`: Medication identifier (TEXT)
- `medication_name`: Medication name (TEXT)
- `medication_category`: Medication category (TEXT)
- `prescription_date`: When prescribed (DATE)
- `fill_date`: When filled (DATE, can be NULL)
- `quantity`: Amount prescribed (INTEGER)
- `days_supply`: Days the supply should last (INTEGER)
- `refills`: Number of refills authorized (INTEGER)
- `refill_number`: Which refill this represents (0 for new, 1+ for refills)
- `is_new`: Whether this is a new prescription (BOOLEAN)
- `created_at`: Record creation timestamp

## Usage Notes

This dataset provides a comprehensive foundation for:

- Testing provider filtering functionality
- Analyzing prescription patterns by specialty
- Building medication adherence metrics
- Developing marketing campaign targeting strategies
- Visualizing prescription trends over time

The data is designed to be realistic while maintaining appropriate constraints and distributions that reflect real-world prescribing patterns.
