# Prescription CSV Generator

This utility generates synthetic patient prescription data for all providers in the database. It's designed to work with the sample medications and providers data to produce realistic prescription records for import into Supabase.

## Overview

The generator creates an optimized prescription dataset with variable prescription counts:
- **Top 10 Specialties**: Each provider gets 500 prescriptions
  - Cardiology, Endocrinology, Pulmonology, Neurology, Psychiatry
  - Dermatology, Gastroenterology, Family Medicine, Internal Medicine, Primary Care
- **All Other Specialties**: Each provider gets 10 prescriptions
- Output is split into multiple files, each under 90MB for easier import
- Files are organized by specialty to keep related data together
- Medications are tailored to match each provider's specialty
- Patient assignments are distributed across ~50 patients per provider
- Brand vs. generic preferences adjust based on specialty and practice size
- Realistic medication quantities and refill patterns

## Specialty-Specific Medication Selection

The generator intelligently filters medications based on provider specialty:

- **Cardiology**: Cardiovascular medications, statins, beta blockers, ACE inhibitors, ARBs, anticoagulants
- **Endocrinology**: Diabetes medications, insulin, thyroid medications
- **Pulmonology**: Respiratory medications, beta agonists
- **Neurology**: Neurological medications, anticonvulsants
- **Psychiatry**: Psychiatric medications, antidepressants, antipsychotics
- **Dermatology**: Dermatologic medications, topicals
- **Gastroenterology**: Gastrointestinal medications
- **Infectious Disease**: Antibiotics, antivirals, antifungals, antimicrobials
- **Oncology**: Cancer treatments, chemotherapy, antineoplastics
- **Primary Care**: Wider range of common medications

## Prerequisites

- Node.js installed (v14 or higher recommended)
- The `medications.csv` and `providers.csv` files in the same directory as this script

## Installation

1. Make sure you have the required CSV files in the project directory:
   - `medications.csv`
   - `providers.csv`

2. Install dependencies:
   ```bash
   npm install
   ```

## Usage

Run the generator:

```bash
node generate_prescription_csvs.js
```

This will:
1. Read the medications and providers data
2. Generate varying numbers of prescriptions based on specialty
3. Create multiple CSV files (each under 90MB) with prescription data
4. Provide detailed statistics on prescriptions by specialty

## Output

The script generates:

- **CSV Files**: Multiple files (each <90MB) to improve manageability:
  - `prescriptions_part1.csv`, `prescriptions_part2.csv`, etc.
  - Files use standard UUID format compatible with PostgreSQL
  - Files are organized by specialty for more logical grouping
- **Console Output**: Statistical breakdown of prescriptions by specialty

## Importing to Supabase

1. Go to your Supabase project dashboard
2. Navigate to the Database section
3. Select the `patient_prescriptions` table
4. Use the "Import Data" option to import each file separately:
   - Import files in sequence: `prescriptions_part1.csv`, then `prescriptions_part2.csv`, etc.
   - Each file will be automatically assigned unique IDs to prevent collisions

## Customization

You can modify the script to:
- Adjust the prescription count for top specialties (`PRESCRIPTIONS_PER_TOP_SPECIALTY`)
- Adjust the prescription count for other specialties (`PRESCRIPTIONS_PER_OTHER_SPECIALTY`)
- Change the maximum file size (`MAX_FILE_SIZE_MB`)
- Change the number of patients per provider (`PATIENTS_PER_PROVIDER`)
- Change date ranges for prescriptions
- Modify specialty-specific logic for medication selection
- Add more specialties to the top specialties list

## Troubleshooting

- **File Not Found Errors**: Ensure `medications.csv` and `providers.csv` are in the same directory as the script
- **Memory Issues**: For very large datasets, you may need to adjust Node's memory allocation with `--max-old-space-size=4096`
- **CSV Parse Errors**: Check that input CSV files follow standard CSV format with quoted fields if they contain commas
- **Duplicate Key Errors**: The script prefixes IDs with unique file identifiers to avoid UUID collisions
- **Long Processing Time**: This script generates a large volume of data and may take 5-10 minutes to run
