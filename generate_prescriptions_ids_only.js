#!/usr/bin/env node

/**
 * Prescription Generator Script (IDs Only Version)
 * 
 * Generates prescription data using:
 * - providers1_rows.csv for provider data
 * - medications_rows.csv for medication data
 * 
 * Features:
 * - Generate prescriptions matching providers to medications by specialty
 * - Uses only IDs in the output data, no names or text fields
 * - Ensure realistic distribution of prescriptions by specialty and region
 * - Balance brand vs generic medications based on specialty preferences
 */

const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

// Configuration
const OUTPUT_DIR = './prescription_csvs';
const PROVIDERS_FILE = 'providers1_rows.csv';
const MEDICATIONS_FILE = 'medications_rows.csv';
const BATCH_ID = 1;
const MAX_ROWS_PER_FILE = 50000; // Significantly reduced to ensure files stay well under 100MB

// Enable test mode with fewer records for faster testing
const TEST_MODE = process.argv.includes('--test');

// Distribution parameters
const PRESCRIPTIONS_PER_PROVIDER = TEST_MODE ? 2 : 25;
const TOTAL_TARGET_PRESCRIPTIONS = TEST_MODE ? 1000 : 950000;

// Specialty weighting (higher = more prescriptions)
const SPECIALTY_WEIGHTS = {
  'Internal Medicine': 1.0,
  'Family Medicine': 1.0,
  'Primary Care': 0.95,
  'Cardiology': 0.85,
  'Endocrinology': 0.8,
  'Pulmonology': 0.75,
  'Neurology': 0.75,
  'Psychiatry': 0.7,
  'Gastroenterology': 0.7,
  'Dermatology': 0.65,
  'Oncology': 0.65,
  'Rheumatology': 0.6,
  'Infectious Disease': 0.6,
  'Obstetrics & Gynecology': 0.55,
  'Pediatrics': 0.55,
  'Nephrology': 0.5,
  'Urology': 0.5,
  'General Surgery': 0.45,
};

// Brand vs generic preference by specialty (0-1, higher = more brands)
const BRAND_PREFERENCES = {
  'Cardiology': 0.6,
  'Oncology': 0.7,
  'Endocrinology': 0.6,
  'Psychiatry': 0.55,
  'Neurology': 0.55,
  'Dermatology': 0.5,
  'Pulmonology': 0.5,
  'Gastroenterology': 0.45,
  'Rheumatology': 0.5,
  'Nephrology': 0.5,
  'Internal Medicine': 0.4,
  'Family Medicine': 0.35,
  'Primary Care': 0.3,
};

// Other configuration
const PATIENTS_PER_PROVIDER = 20;
const START_DATE = new Date('2023-01-01');
const END_DATE = new Date();

// Helper functions
function randomDate(start, end) {
  return new Date(start.getTime() + Math.random() * (end.getTime() - start.getTime()));
}

function formatDate(date) {
  return date.toISOString().split('T')[0];
}

function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function randomBoolean(probability = 0.5) {
  return Math.random() < probability;
}

function randomChoice(array) {
  return array[Math.floor(Math.random() * array.length)];
}

function weightedRandomIndex(weights) {
  const totalWeight = weights.reduce((sum, weight) => sum + weight, 0);
  let random = Math.random() * totalWeight;
  
  for (let i = 0; i < weights.length; i++) {
    random -= weights[i];
    if (random <= 0) return i;
  }
  
  return weights.length - 1;
}

function escapeCSV(value) {
  if (value === null || value === undefined) return '';
  
  const stringValue = String(value);
  if (stringValue.includes(',') || stringValue.includes('"') || stringValue.includes('\n')) {
    return `"${stringValue.replace(/"/g, '""')}"`;
  }
  return stringValue;
}

function generatePatientIds(count) {
  const ids = [];
  for (let i = 0; i < count; i++) {
    ids.push(uuidv4());
  }
  return ids;
}

// Helper function to parse CSV data properly
function parseCSV(data) {
  const lines = data.split('\n').filter(line => line.trim());
  if (lines.length === 0) return { headers: [], rows: [] };
  
  // Parse header
  const headerLine = lines[0];
  const headers = parseCSVRow(headerLine);
  
  // Parse rows
  const rows = [];
  for (let i = 1; i < lines.length; i++) {
    if (!lines[i].trim()) continue;
    const values = parseCSVRow(lines[i]);
    
    // Create object with column names as keys
    const row = {};
    for (let j = 0; j < headers.length; j++) {
      if (j < values.length) {
        row[headers[j]] = values[j];
      } else {
        row[headers[j]] = '';
      }
    }
    rows.push(row);
  }
  
  return { headers, rows };
}

// Helper function to parse a single CSV row respecting quoted fields
function parseCSVRow(row) {
  const values = [];
  let currentValue = '';
  let inQuotes = false;
  
  for (let i = 0; i < row.length; i++) {
    const char = row[i];
    
    if (char === '"') {
      if (inQuotes && i + 1 < row.length && row[i + 1] === '"') {
        // Double quotes inside quoted string - add a single quote
        currentValue += '"';
        i++; // Skip the next quote
      } else {
        // Toggle quote status
        inQuotes = !inQuotes;
      }
    } else if (char === ',' && !inQuotes) {
      // End of field
      values.push(currentValue);
      currentValue = '';
    } else {
      currentValue += char;
    }
  }
  
  // Add the last value
  values.push(currentValue);
  return values;
}

// Read and parse CSV files - Using proper CSV parsing
async function loadMedications() {
  console.log(`Loading medications from ${MEDICATIONS_FILE}...`);
  
  if (!fs.existsSync(MEDICATIONS_FILE)) {
    throw new Error(`Medication file ${MEDICATIONS_FILE} not found`);
  }
  
  const data = fs.readFileSync(MEDICATIONS_FILE, 'utf8');
  const { headers, rows } = parseCSV(data);
  
  console.log(`Medication headers found: ${headers.join(', ')}`);
  
  if (rows.length === 0) {
    throw new Error('No medication data found');
  }
  
  // Verify required columns
  if (!headers.includes('id')) {
    throw new Error('Medication CSV must have an "id" column');
  }
  
  // Transform rows into medication objects
  const medications = rows.map(row => ({
    id: row.id,
    name: row.medication_name || '',
    ndc: row.medication_ndc || '',
    is_brand: (row.brand_generic || '').toLowerCase() === 'brand',
    is_brand_name: (row.brand_generic || '').toLowerCase() === 'brand' ? 'true' : 'false',
    category: row.category || '',
    specialty: row.specialty || '',
    brand_generic: row.brand_generic || ''
  }));
  
  console.log(`Successfully loaded ${medications.length} medications`);
  
  if (medications.length === 0) {
    throw new Error('No valid medications could be loaded');
  }
  
  return medications;
}

async function loadProviders() {
  console.log(`Loading providers from ${PROVIDERS_FILE}...`);
  
  if (!fs.existsSync(PROVIDERS_FILE)) {
    throw new Error(`Provider file ${PROVIDERS_FILE} not found`);
  }
  
  const data = fs.readFileSync(PROVIDERS_FILE, 'utf8');
  const { headers, rows } = parseCSV(data);
  
  console.log(`Provider headers found: ${headers.join(', ')}`);
  
  if (rows.length === 0) {
    throw new Error('No provider data found');
  }
  
  // Verify required columns
  if (!headers.includes('id')) {
    throw new Error('Provider CSV must have an "id" column');
  }
  
  // Transform rows into provider objects
  const providers = rows.filter(row => row.id && row.specialty).map(row => ({
    id: row.id,
    npi: row.npi || '',
    specialty: row.specialty || '',
    region: row.region || '',
    created_at: row.created_at || ''
  }));
  
  console.log(`Successfully loaded ${providers.length} providers`);
  
  if (providers.length === 0) {
    throw new Error('No valid providers could be loaded');
  }
  
  return providers;
}

// Filter medications by specialty
function getMedicationsForSpecialty(medications, specialty) {
  // First try to match by exact specialty
  let filtered = medications.filter(med => 
    med.specialty && med.specialty.toLowerCase() === specialty.toLowerCase()
  );
  
  // If not enough, use category-based filtering for common specialties
  if (filtered.length < 5) {
    const categoryKeywords = {
      'cardiology': ['cardiovascular', 'antihypertensive', 'statin', 'beta blocker', 
                   'ace inhibitor', 'arb', 'anticoagulant'],
      'endocrinology': ['diabetes', 'insulin', 'thyroid', 'hormone', 'endocrine'],
      'pulmonology': ['respiratory', 'inhaler', 'bronchodilator', 'beta agonist', 
                     'corticosteroid', 'pulmonary'],
      'neurology': ['neurology', 'anticonvulsant', 'anti-seizure', 'multiple sclerosis',
                  'migraine', 'parkinsons'],
      'psychiatry': ['psychiatric', 'antidepressant', 'antipsychotic', 'ssri', 'mood stabilizer',
                   'anti-anxiety', 'adhd'],
      'dermatology': ['dermatologic', 'topical', 'skin', 'acne', 'psoriasis', 'eczema'],
      'gastroenterology': ['gastrointestinal', 'gi', 'acid reducer', 'ppi', 'antacid',
                         'laxative', 'ibs', 'crohns'],
      'infectious disease': ['antibiotic', 'antiviral', 'antifungal', 'antimicrobial',
                           'antiparasitic', 'hiv'],
      'oncology': ['oncology', 'chemotherapy', 'antineoplastic', 'cancer', 'immunotherapy'],
      'rheumatology': ['rheumatology', 'dmard', 'antirheumatic', 'arthritis', 'lupus',
                     'autoimmune', 'immunosuppressant'],
      'nephrology': ['kidney', 'renal', 'diuretic', 'nephrology'],
      'urology': ['urology', 'prostate', 'erectile', 'bladder', 'overactive'],
      'obstetrics & gynecology': ['contraceptive', 'hormone replacement', 'hrt', 'fertility',
                                'menopause', 'gynecology'],
      'internal medicine': ['antihypertensive', 'antibiotic', 'antidepressant', 'diabetes',
                          'cholesterol', 'analgesic', 'nsaid', 'vaccine', 'vitamin'],
      'family medicine': ['antihypertensive', 'antibiotic', 'antidepressant', 'diabetes',
                        'cholesterol', 'analgesic', 'nsaid', 'vaccine', 'vitamin'],
      'primary care': ['antihypertensive', 'antibiotic', 'antidepressant', 'diabetes',
                     'cholesterol', 'analgesic', 'nsaid', 'vaccine', 'vitamin'],
    };
    
    const keywords = categoryKeywords[specialty.toLowerCase()] || [];
    
    if (keywords.length > 0) {
      const categoryMatches = medications.filter(med => 
        med.category && keywords.some(kw => med.category.toLowerCase().includes(kw))
      );
      
      // Combine with specialty matches
      filtered = [...new Set([...filtered, ...categoryMatches])];
    }
  }
  
  // If still not enough, just take a sample of all medications
  if (filtered.length < 5) {
    console.warn(`Not enough medications for ${specialty}, using generic selection`);
    const sampleSize = Math.min(medications.length, 20);
    filtered = medications.slice(0, sampleSize);
  }
  
  return filtered;
}

// Filter medications by brand preference
function filterByBrandPreference(medications, brandPreference) {
  const branded = medications.filter(med => med.is_brand);
  const generic = medications.filter(med => !med.is_brand);
  
  // If we don't have both, return what we have
  if (branded.length === 0 || generic.length === 0) {
    return medications;
  }
  
  // Calculate how many of each to include
  const total = Math.min(medications.length, 20); // Cap at 20 options
  const brandCount = Math.round(total * brandPreference);
  const genericCount = total - brandCount;
  
  // Get random samples
  const selectedBranded = branded
    .sort(() => 0.5 - Math.random())
    .slice(0, brandCount);
    
  const selectedGeneric = generic
    .sort(() => 0.5 - Math.random())
    .slice(0, genericCount);
  
  return [...selectedBranded, ...selectedGeneric];
}

// Generate prescriptions for a provider
async function generatePrescriptionsForProvider(
  provider, 
  medications, 
  outputStream, 
  count
) {
  const providerId = provider.id;
  const specialty = provider.specialty;
  
  // Get medications appropriate for this specialty
  const specialtyMedications = getMedicationsForSpecialty(medications, specialty);
  
  if (specialtyMedications.length === 0) {
    console.warn(`No medications available for provider ${providerId} (${specialty})`);
    return 0;
  }
  
  // Apply brand preference based on specialty
  const brandPreference = BRAND_PREFERENCES[specialty] || 0.4;
  const eligibleMedications = filterByBrandPreference(specialtyMedications, brandPreference);
  
  if (eligibleMedications.length === 0) {
    console.warn(`No eligible medications after brand filtering for ${providerId}`);
    return 0;
  }
  
  // Generate patient IDs for this provider
  const patientIds = generatePatientIds(PATIENTS_PER_PROVIDER);
  
  let prescriptionCount = 0;
  
  // Generate prescriptions
  for (let i = 0; i < count; i++) {
    // Pick medication rotating through available ones
    const medicationIndex = i % eligibleMedications.length;
    const medication = eligibleMedications[medicationIndex];
    
    // Random patient
    const patientId = randomChoice(patientIds);
    
    // Generate dates
    const prescriptionDate = randomDate(START_DATE, END_DATE);
    
    // 95% chance of filling the prescription
    let fillDate = null;
    if (randomBoolean(0.95)) {
      const fillDelay = randomInt(0, 5); // 0-5 days
      fillDate = new Date(prescriptionDate);
      fillDate.setDate(fillDate.getDate() + fillDelay);
    }
    
    // Calculate supply - chronic vs acute
    let quantity, daysSupply;
    const isChronic = randomBoolean(0.7); // 70% chance of chronic medication
    
    if (isChronic) {
      const days = randomChoice([30, 60, 90]);
      quantity = days;
      daysSupply = days;
    } else {
      quantity = 10 + Math.floor(Math.random() * 20);
      daysSupply = 5 + Math.floor(Math.random() * 10);
    }
    
    // Calculate refills
    const refills = isChronic ? randomInt(2, 5) : randomInt(0, 2);
    
    // Is this new or a refill?
    const isNew = randomBoolean(0.8); // 80% chance of new prescription
    const refillNumber = isNew ? 0 : randomInt(1, 3);
    
    // Create CSV row - IDs only version (no medication_name or medication_category)
    const row = [
      uuidv4(), // id
      providerId, // provider_id
      patientId, // patient_id
      medication.id, // medication_id
      formatDate(prescriptionDate), // prescription_date
      fillDate ? formatDate(fillDate) : '', // fill_date
      quantity, // quantity
      daysSupply, // days_supply
      refills, // refills
      refillNumber, // refill_number
      isNew, // is_new
      BATCH_ID, // batch_id
      new Date().toISOString() // created_at
    ].map(escapeCSV).join(',');
    
    // Write to output
    outputStream.write(row + '\n');
    prescriptionCount++;
  }
  
  return prescriptionCount;
}

// Function to create a new output file
function createOutputFile(fileIndex, timestamp) {
  const outputPath = path.join(OUTPUT_DIR, `prescriptions_ids_only_${timestamp}_part${fileIndex}.csv`);
  const outputStream = fs.createWriteStream(outputPath);
  
  // Write header
  const header = 'id,provider_id,patient_id,medication_id,prescription_date,fill_date,quantity,days_supply,refills,refill_number,is_new,batch_id,created_at\n';
  outputStream.write(header);
  
  return { outputStream, outputPath };
}

// Main execution function
async function main() {
  console.log(`Starting prescription generation (IDs only)...`);
  console.log(`Mode: ${TEST_MODE ? 'TEST' : 'PRODUCTION'}`);
  
  try {
    // Load data
    const medications = await loadMedications();
    const providers = await loadProviders();
    
    // Create output directory if needed
    if (!fs.existsSync(OUTPUT_DIR)) {
      fs.mkdirSync(OUTPUT_DIR, { recursive: true });
    }
    
    // File management variables
    const timestamp = Date.now();
    let fileIndex = 1;
    let currentRowCount = 0;
    let outputFiles = [];
    
    // Create first output file
    let { outputStream, outputPath } = createOutputFile(fileIndex, timestamp);
    outputFiles.push(outputPath);
    
    // Generate prescriptions for each provider (base amount)
    console.log(`Generating ${PRESCRIPTIONS_PER_PROVIDER} prescriptions per provider...`);
    let totalCount = 0;
    let providerCount = 0;
    
    const maxProviders = TEST_MODE ? 50 : providers.length;
    const batchSize = 50; // Process in batches
    
    for (let i = 0; i < Math.min(providers.length, maxProviders); i += batchSize) {
      const batch = providers.slice(i, i + batchSize);
      
      for (const provider of batch) {
        // Check if we need to create a new file
        if (currentRowCount >= MAX_ROWS_PER_FILE) {
          // Close current file
          outputStream.end();
          
          // Create new file
          fileIndex++;
          const newFile = createOutputFile(fileIndex, timestamp);
          outputStream = newFile.outputStream;
          outputFiles.push(newFile.outputPath);
          currentRowCount = 0;
          
          console.log(`  Created new output file: ${newFile.outputPath}`);
        }
        
        const count = await generatePrescriptionsForProvider(
          provider,
          medications,
          outputStream,
          PRESCRIPTIONS_PER_PROVIDER
        );
        
        totalCount += count;
        currentRowCount += count;
        providerCount++;
        
        if (providerCount % 100 === 0) {
          console.log(`  Processed ${providerCount} providers, generated ${totalCount} prescriptions (current file: ${currentRowCount} rows)`);
        }
      }
    }
    
    // Generate additional prescriptions if needed to reach target
    const additionalNeeded = Math.max(0, TOTAL_TARGET_PRESCRIPTIONS - totalCount);
    
    if (additionalNeeded > 0) {
      console.log(`\nGenerating ${additionalNeeded} additional prescriptions to reach target...`);
      
      // Calculate weights for providers based on specialty
      const weights = providers.slice(0, maxProviders).map(p => SPECIALTY_WEIGHTS[p.specialty] || 0.4);
      let additionalCount = 0;
      
      // Generate in batches
      const BATCH_SIZE = 10000;
      const batches = Math.ceil(additionalNeeded / BATCH_SIZE);
      
      for (let batch = 0; batch < batches; batch++) {
        const batchSize = Math.min(BATCH_SIZE, additionalNeeded - additionalCount);
        
        for (let i = 0; i < batchSize; i++) {
          // Check if we need to create a new file
          if (currentRowCount >= MAX_ROWS_PER_FILE) {
            // Close current file
            outputStream.end();
            
            // Create new file
            fileIndex++;
            const newFile = createOutputFile(fileIndex, timestamp);
            outputStream = newFile.outputStream;
            outputFiles.push(newFile.outputPath);
            currentRowCount = 0;
            
            console.log(`  Created new output file: ${newFile.outputPath}`);
          }
          
          // Weighted selection of provider
          const providerIndex = weightedRandomIndex(weights);
          const provider = providers[providerIndex];
          
          // Generate just one prescription
          const count = await generatePrescriptionsForProvider(
            provider,
            medications,
            outputStream,
            1
          );
          
          additionalCount += count;
          currentRowCount += count;
          
          if (additionalCount % 10000 === 0) {
            console.log(`  Generated ${additionalCount}/${additionalNeeded} additional prescriptions (current file: ${currentRowCount} rows)`);
          }
        }
      }
      
      console.log(`Completed additional prescriptions: ${additionalCount}`);
      totalCount += additionalCount;
    }
    
    // Close the output stream
    outputStream.end();
    
    console.log(`\nGeneration complete!`);
    console.log(`Total prescriptions: ${totalCount}`);
    console.log(`Output saved to ${fileIndex} files:`);
    outputFiles.forEach(file => console.log(`  - ${file}`));
    
  } catch (error) {
    console.error(`Error: ${error.message}`);
    console.error(error.stack);
    process.exit(1);
  }
}

// Run the main function
main().catch(err => {
  console.error('Unhandled error:', err);
  process.exit(1);
});
