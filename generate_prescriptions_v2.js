#!/usr/bin/env node

/**
 * Enhanced Prescription Generator v2
 * 
 * - Uses updated providers_final.csv and medications_combined.csv
 * - Implements two-phase approach:
 *    1. Seed phase: 10 prescriptions per provider in their specialty
 *    2. Distribution phase: 900K additional prescriptions distributed by specialty
 * - Distributes prescriptions by specialty, region, generic/brand, etc.
 */

const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const readline = require('readline');

// Configuration
const BATCH_ID = 2; // Use a different batch ID for this generation
const OUTPUT_DIR = './prescription_csvs';
const PROVIDERS_FILE = 'providers1_rows.csv'; // Using the specified provider dataset
const MEDICATIONS_FILE = 'medications_rows.csv'; // Using the specified medications dataset

// Enable test mode with fewer records for faster execution
const TEST_MODE = process.argv.includes('--test');

// Distribution parameters
const SEED_PRESCRIPTIONS_PER_PROVIDER = TEST_MODE ? 5 : 10;
const TOTAL_ADDITIONAL_PRESCRIPTIONS = TEST_MODE ? 5000 : 900000;

console.log(`Running in ${TEST_MODE ? 'TEST' : 'PRODUCTION'} mode`);

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
  // Default weight for any other specialty is 0.4
};

// Regional distribution parameters (higher = more prescriptions)
const REGION_WEIGHTS = {
  'Northeast': 1.1,
  'South': 1.05,
  'Midwest': 1.0,
  'West': 0.95,
  'Northwest': 0.85,
  'Southwest': 0.9,
  'Southeast': 1.0,
  // Default weight for any region not listed is 0.8
};

// Brand vs generic preference by specialty
const BRAND_PREFERENCES = {
  'Cardiology': 0.6,       // Higher preference for brands
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
  'Primary Care': 0.3,     // Lower preference for brands
  // Default is 0.4 for any other specialty
};

// Other configuration
const PATIENTS_PER_PROVIDER = 50;
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

// Weighted random selection - returns an index from the array
function weightedRandomSelection(weights) {
  const totalWeight = weights.reduce((sum, weight) => sum + weight, 0);
  let random = Math.random() * totalWeight;
  
  for (let i = 0; i < weights.length; i++) {
    random -= weights[i];
    if (random <= 0) {
      return i;
    }
  }
  
  // Fallback in case of rounding errors
  return weights.length - 1;
}

// CSV parsing and creation helpers
function parseCSV(text) {
  const lines = text.split('\n');
  const headers = parseCSVLine(lines[0]);
  
  return lines.slice(1).filter(line => line.trim()).map(line => {
    const values = parseCSVLine(line);
    return headers.reduce((obj, header, i) => {
      obj[header.trim().replace(/"/g, '')] = values[i]?.replace(/"/g, '') || '';
      return obj;
    }, {});
  });
}

function parseCSVLine(line) {
  const result = [];
  let current = '';
  let inQuotes = false;
  
  for (let i = 0; i < line.length; i++) {
    const char = line[i];
    
    if (char === '"') {
      inQuotes = !inQuotes;
    } else if (char === ',' && !inQuotes) {
      result.push(current);
      current = '';
    } else {
      current += char;
    }
  }
  
  if (current) {
    result.push(current);
  }
  
  return result;
}

function escapeCSV(value) {
  if (value === null || value === undefined) {
    return '';
  }
  
  const stringValue = String(value);
  if (stringValue.includes(',') || stringValue.includes('"') || stringValue.includes('\n')) {
    return `"${stringValue.replace(/"/g, '""')}"`;
  }
  return stringValue;
}

/**
 * Fixes the provider CSV data by adding commas between fields
 * This is due to a formatting issue in the providers_final.csv
 */
function fixProviderLine(line) {
  if (!line) return null;

  // Skip the header row
  if (line.startsWith('id')) {
    return 'id,npi,specialty,region,created_at';
  }

  // Find the UUIDv4 pattern at the start
  const uuidMatch = line.match(/^([0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12})/i);
  if (!uuidMatch) return null;

  const id = uuidMatch[1];
  // Remove UUID from line
  let remaining = line.substring(id.length);

  // Extract NPI (next 10 digits)
  const npiMatch = remaining.match(/^(\d{10})/);
  if (!npiMatch) return null;
  
  const npi = npiMatch[1];
  // Remove NPI from remaining
  remaining = remaining.substring(npi.length);

  // Extract the created_at timestamp at the end
  const timestampMatch = remaining.match(/(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z?)$/);
  if (!timestampMatch) return null;
  
  const timestamp = timestampMatch[1];
  // Remove timestamp from remaining
  remaining = remaining.substring(0, remaining.length - timestamp.length);

  // Extract specialty and region from what's left
  // Regions are known values we can match
  const regions = ['Northeast', 'Northwest', 'South', 'West', 'Midwest', 'Southeast', 'Southwest'];
  let specialty = '';
  let region = '';

  for (const r of regions) {
    if (remaining.endsWith(r)) {
      region = r;
      specialty = remaining.substring(0, remaining.length - r.length);
      break;
    }
  }

  if (!region || !specialty) return null;

  // Return properly formatted CSV line
  return `${id},${npi},${specialty},${region},${timestamp}`;
}

// File reading functions
async function loadMedications() {
  try {
    console.log(`Loading medications from ${MEDICATIONS_FILE}...`);
    
    // Read file directly and parse it line by line for better control
    const data = fs.readFileSync(MEDICATIONS_FILE, 'utf8');
    const lines = data.split('\n').filter(line => line.trim());
    
    if (lines.length === 0) {
      throw new Error('Medications file is empty');
    }
    
    const medications = [];
    
    // Process each line
    for (let i = 1; i < lines.length; i++) { // Skip header
      const line = lines[i];
      
      try {
        // Extract the ID (UUID) first
        const idMatch = line.match(/^([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/);
        if (!idMatch) continue;
        
        const id = idMatch[1];
        let rest = line.substring(id.length);
        
        // Extract the medication name (usually in quotes)
        const nameEndIndex = rest.indexOf('"', 1);
        if (nameEndIndex === -1) continue;
        
        const medicationName = rest.substring(1, nameEndIndex);
        rest = rest.substring(nameEndIndex + 1);
        
        // Extract NDC code
        const ndcEndIndex = rest.indexOf('"', 1);
        if (ndcEndIndex === -1) continue;
        
        const medicationNdc = rest.substring(1, ndcEndIndex);
        rest = rest.substring(ndcEndIndex + 1);
        
        // Extract brand/generic
        const brandEndIndex = rest.indexOf('"', 1);
        if (brandEndIndex === -1) continue;
        
        const brandGeneric = rest.substring(1, brandEndIndex);
        rest = rest.substring(brandEndIndex + 1);
        
        // Extract category
        const categoryEndIndex = rest.indexOf('"', 1);
        if (categoryEndIndex === -1) continue;
        
        const category = rest.substring(1, categoryEndIndex);
        rest = rest.substring(categoryEndIndex + 1);
        
        // Extract specialty 
        const specialtyEndIndex = rest.indexOf('"', 1);
        if (specialtyEndIndex === -1) continue;
        
        const specialty = rest.substring(1, specialtyEndIndex);
        
        // Map to our expected medication object format
        medications.push({
          id,
          name: medicationName,
          medication_name: medicationName, // For compatibility
          medication_ndc: medicationNdc,
          is_brand_name: brandGeneric.toLowerCase() === 'brand' ? 'true' : 'false',
          brand_generic: brandGeneric,
          category,
          specialty
        });
        
        if (medications.length % 100 === 0) {
          console.log(`  Loaded ${medications.length} medications...`);
        }
      } catch (err) {
        console.warn(`Error parsing medication on line ${i}: ${err.message}`);
      }
    }
    
    console.log(`Successfully parsed ${medications.length} valid medications`);
    
    if (medications.length === 0) {
      throw new Error('No valid medications could be parsed from the file');
    }
    
    return medications;
  } catch (error) {
    console.error('Error loading medications:', error);
    process.exit(1);
  }
}

async function loadProviders() {
  try {
    console.log(`Loading providers from ${PROVIDERS_FILE}...`);
    const providers = [];
    
    // First check if the file exists
    if (!fs.existsSync(PROVIDERS_FILE)) {
      console.error(`Provider file ${PROVIDERS_FILE} not found`);
      process.exit(1);
    }
    
    // Read the entire file content
    const fileContent = fs.readFileSync(PROVIDERS_FILE, 'utf8');
    const lines = fileContent.split('\n').filter(line => line.trim());
    
    if (lines.length === 0) {
      console.error(`Provider file ${PROVIDERS_FILE} is empty`);
      process.exit(1);
    }
    
    // Skip the header line
    console.log(`Processing provider data from ${lines.length-1} lines...`);
    
    // Process each data line (skip the header)
    for (let i = 1; i < lines.length; i++) {
      const line = lines[i];
      if (!line.trim()) continue;
      
      try {
        // Extract UUID (first 36 characters)
        const id = line.substring(0, 36);
        if (!id.match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)) {
          console.warn(`Skipping line ${i}, invalid UUID: ${id}`);
          continue;
        }
        
        // Extract NPI (next 10 digits)
        const npi = line.substring(36, 46);
        if (!npi.match(/^\d{10}$/)) {
          console.warn(`Skipping line ${i}, invalid NPI: ${npi}`);
          continue;
        }
        
        // Find the specialty (enclosed in quotes)
        const specialtyStart = line.indexOf('"', 46) + 1;
        if (specialtyStart <= 0) {
          console.warn(`Skipping line ${i}, cannot find specialty start`);
          continue;
        }
        
        const specialtyEnd = line.indexOf('"', specialtyStart);
        if (specialtyEnd <= specialtyStart) {
          console.warn(`Skipping line ${i}, cannot find specialty end`);
          continue;
        }
        
        const specialty = line.substring(specialtyStart, specialtyEnd);
        
        // Find region after specialty
        const regionStart = specialtyEnd + 1;
        
        // Check for region from our known list
        const regions = Object.keys(REGION_WEIGHTS);
        let region = '';
        
        for (const r of regions) {
          if (line.indexOf(r, regionStart) > 0) {
            region = r;
            break;
          }
        }
        
        if (!region) {
          console.warn(`Skipping line ${i}, cannot find valid region`);
          continue;
        }
        
        // Extract timestamp at the end (format: YYYY-MM-DD HH:MM:SS.ssssss+00)
        const timestampRegex = /(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+\+\d{2})/;
        const timestampMatch = line.match(timestampRegex);
        
        if (!timestampMatch) {
          console.warn(`Skipping line ${i}, cannot extract timestamp`);
          continue;
        }
        
        const timestamp = timestampMatch[1];
        
        // Create the provider object
        const provider = {
          id,
          provider_id: id, // Add provider_id for compatibility with existing code
          npi,
          specialty,
          region,
          created_at: timestamp
        };
        
        providers.push(provider);
        
        // Log progress
        if (providers.length % 1000 === 0) {
          console.log(`  Loaded ${providers.length} providers...`);
        }
      } catch (err) {
        console.warn(`Error processing line ${i}: ${err.message}`);
      }
    }
    
    console.log(`Successfully loaded ${providers.length} providers.`);
    
    if (providers.length === 0) {
      console.error(`No valid providers found in ${PROVIDERS_FILE}`);
      process.exit(1);
    }
    
    return providers;
  } catch (error) {
    console.error('Error loading providers:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

// Data processing functions
function filterMedicationsBySpecialty(medications, specialty) {
  if (!medications || medications.length === 0) {
    console.warn(`No medications available to filter for specialty: ${specialty}`);
    return [];
  }
  
  const validMedications = medications.filter(med => med && med.id);
  if (validMedications.length === 0) {
    console.warn(`No medications with valid IDs found`);
    return [];
  }
  
  // Default filter returns a reasonable sample of medications
  const defaultFilter = () => {
    const sampleSize = Math.max(10, Math.floor(validMedications.length * 0.2));
    return validMedications.slice(0, sampleSize);
  };
  
  // Primary filter by specialty field if it exists
  let filtered = validMedications.filter(med => 
    med.specialty && med.specialty.toLowerCase() === specialty.toLowerCase()
  );
  
  // If we don't have enough, use category field as a secondary filter
  if (filtered.length < 10) {
    const categoryFiltered = [];
    
    // Specialty to category mapping
    switch(specialty.toLowerCase()) {
      case 'cardiology':
        categoryFiltered.push(...validMedications.filter(med => 
          ['cardiovascular', 'antihypertensive', 'statin', 'beta blocker', 
           'ace inhibitor', 'arb', 'anticoagulant'].some(c => 
             med.category && med.category.toLowerCase().includes(c))));
        break;
      
      case 'endocrinology':
        categoryFiltered.push(...validMedications.filter(med => 
          ['diabetes', 'insulin', 'thyroid', 'hormone', 'endocrine'].some(c => 
             med.category && med.category.toLowerCase().includes(c))));
        break;
      
      case 'pulmonology':
        categoryFiltered.push(...validMedications.filter(med => 
          ['respiratory', 'inhaler', 'bronchodilator', 'beta agonist', 
           'corticosteroid', 'pulmonary'].some(c => 
             med.category && med.category.toLowerCase().includes(c))));
        break;
      
      case 'neurology':
        categoryFiltered.push(...validMedications.filter(med => 
          ['neurology', 'anticonvulsant', 'anti-seizure', 'multiple sclerosis',
           'migraine', 'parkinsons'].some(c => 
             med.category && med.category.toLowerCase().includes(c))));
        break;
      
      case 'psychiatry':
        categoryFiltered.push(...validMedications.filter(med => 
          ['psychiatric', 'antidepressant', 'antipsychotic', 'ssri', 'mood stabilizer',
           'anti-anxiety', 'adhd'].some(c => 
             med.category && med.category.toLowerCase().includes(c))));
        break;
      
      case 'dermatology':
        categoryFiltered.push(...validMedications.filter(med => 
          ['dermatologic', 'topical', 'skin', 'acne', 'psoriasis', 'eczema'].some(c => 
             med.category && med.category.toLowerCase().includes(c))));
        break;
      
      case 'gastroenterology':
        categoryFiltered.push(...validMedications.filter(med => 
          ['gastrointestinal', 'gi', 'acid reducer', 'ppi', 'antacid',
           'laxative', 'ibs', 'crohns'].some(c => 
             med.category && med.category.toLowerCase().includes(c))));
        break;
      
      case 'infectious disease':
        categoryFiltered.push(...validMedications.filter(med => 
          ['antibiotic', 'antiviral', 'antifungal', 'antimicrobial',
           'antiparasitic', 'hiv'].some(c => 
             med.category && med.category.toLowerCase().includes(c))));
        break;
      
      case 'oncology':
        categoryFiltered.push(...validMedications.filter(med => 
          ['oncology', 'chemotherapy', 'antineoplastic', 'cancer',
           'immunotherapy'].some(c => 
             med.category && med.category.toLowerCase().includes(c))));
        break;
      
      case 'rheumatology':
        categoryFiltered.push(...validMedications.filter(med => 
          ['rheumatology', 'dmard', 'antirheumatic', 'arthritis', 'lupus',
           'autoimmune', 'immunosuppressant'].some(c => 
             med.category && med.category.toLowerCase().includes(c))));
        break;
        
      case 'nephrology':
        categoryFiltered.push(...validMedications.filter(med => 
          ['kidney', 'renal', 'diuretic', 'nephrology'].some(c => 
             med.category && med.category.toLowerCase().includes(c))));
        break;
        
      case 'urology':
        categoryFiltered.push(...validMedications.filter(med => 
          ['urology', 'prostate', 'erectile', 'bladder', 'overactive'].some(c => 
             med.category && med.category.toLowerCase().includes(c))));
        break;
        
      case 'obstetrics & gynecology':
      case 'obgyn':
        categoryFiltered.push(...validMedications.filter(med => 
          ['contraceptive', 'hormone replacement', 'hrt', 'fertility',
           'menopause', 'gynecology'].some(c => 
             med.category && med.category.toLowerCase().includes(c))));
        break;
        
      case 'internal medicine':
      case 'family medicine':
      case 'primary care':
        // Primary care gets a wider selection across common categories
        categoryFiltered.push(...validMedications.filter(med => 
          ['antihypertensive', 'antibiotic', 'antidepressant', 'diabetes',
           'cholesterol', 'analgesic', 'nsaid', 'vaccine', 'vitamin'].some(c => 
             med.category && med.category.toLowerCase().includes(c))));
        break;
      
      default:
        // No specific category mapping, keep the specialty match only
        break;
    }
    
    // Merge specialty matches with category matches
    filtered = [...new Set([...filtered, ...categoryFiltered])];
  }
  
  // If we still don't have enough, use default filter
  if (filtered.length < 5) {
    console.warn(`Insufficient medications for ${specialty}, using default selection`);
    filtered = defaultFilter();
  }
  
  return filtered;
}

function determineBrandPreference(provider, specialty) {
  // Get base preference from specialty mapping
  let preference = BRAND_PREFERENCES[specialty] || 0.4;
  
  // Adjust by region (some regions have higher brand preference)
  const region = provider.region;
  if (region === 'Northeast' || region === 'South') {
    preference += 0.05;
  } else if (region === 'Midwest' || region === 'West') {
    preference -= 0.05;
  }
  
  // Cap between 0.2 and 0.8
  return Math.min(0.8, Math.max(0.2, preference));
}

function generatePatientIds(count) {
  const patientIds = [];
  for (let i = 0; i < count; i++) {
    patientIds.push(uuidv4());
  }
  return patientIds;
}

function filterMedicationsByBrandPreference(medications, brandPreference) {
  // For specialty seed set, we want exact control over brand/generic ratio
  const branded = medications.filter(med => med.is_brand_name === 'true');
  const generic = medications.filter(med => med.is_brand_name !== 'true');
  
  // If we don't have both types, return all
  if (branded.length === 0 || generic.length === 0) {
    return medications;
  }
  
  // Calculate how many of each to include
  const totalNeeded = Math.min(medications.length, 20); // Cap at 20 options
  const brandCount = Math.round(totalNeeded * brandPreference);
  const genericCount = totalNeeded - brandCount;
  
  // Get random samples of each type
  const selectedBranded = branded.sort(() => 0.5 - Math.random()).slice(0, brandCount);
  const selectedGeneric = generic.sort(() => 0.5 - Math.random()).slice(0, genericCount);
  
  // Combine and return
  return [...selectedBranded, ...selectedGeneric];
}

function calculateQuantityAndDaysSupply(medication) {
  const category = medication.category || '';
  
  // For chronic medications (usually taken daily)
  if (['cardiovascular', 'diabetes', 'psychiatric', 'endocrine', 'antihypertensive', 
       'statin', 'anti-diabetic', 'thyroid'].some(c => 
       category.toLowerCase().includes(c))) {
    const options = [30, 60, 90];
    const days = options[Math.floor(Math.random() * options.length)];
    return { quantity: days, daysSupply: days };
  } 
  
  // For acute medications
  else {
    const quantity = 10 + Math.floor(Math.random() * 20);
    const daysSupply = 5 + Math.floor(Math.random() * 10);
    return { quantity, daysSupply };
  }
}

function calculateRefills(medication) {
  const category = medication.category || '';
  
  // For chronic medications
  if (['cardiovascular', 'diabetes', 'psychiatric', 'endocrine', 'antihypertensive', 
       'statin', 'anti-diabetic', 'thyroid'].some(c => 
       category.toLowerCase().includes(c))) {
    return 2 + Math.floor(Math.random() * 4); // 2-5 refills
  } 
  
  // For acute medications
  else {
    return Math.floor(Math.random() * 3); // 0-2 refills
  }
}

// Phase 1: Generate seed prescriptions (10 per provider in their specialty)
async function generateSeedPrescriptionsForProvider(provider, medications, outputStream) {
  const providerId = provider.id;
  const specialty = provider.specialty;
  
  // Skip if provider ID is missing
  if (!providerId) {
    console.warn(`Skipping provider with missing ID: ${JSON.stringify(provider)}`);
    return 0;
  }
  
  // Determine brand preference based on specialty and region
  const brandPreference = determineBrandPreference(provider, specialty);
  
  // Filter medications for this specialty
  const specialtyMedications = filterMedicationsBySpecialty(medications, specialty);
  
  // Skip if no eligible medications
  if (specialtyMedications.length === 0) {
    console.warn(`No eligible medications for provider ${providerId} in ${specialty}`);
    return 0;
  }
  
  // Filter medications by brand preference
  const eligibleMedications = filterMedicationsByBrandPreference(
    specialtyMedications, 
    brandPreference
  );
  
  if (eligibleMedications.length === 0) {
    console.warn(`No eligible medications after brand filtering for ${providerId}`);
    return 0;
  }
  
  // Generate synthetic patient IDs
  const patientIds = generatePatientIds(PATIENTS_PER_PROVIDER);
  
  let prescriptionCount = 0;
  
  // Generate exactly SEED_PRESCRIPTIONS_PER_PROVIDER prescriptions
  for (let i = 0; i < SEED_PRESCRIPTIONS_PER_PROVIDER; i++) {
    // Ensure a good distribution of medications
    const medicationIndex = i % eligibleMedications.length;
    const medication = eligibleMedications[medicationIndex];
    
    // Generate random patient
    const patientId = randomChoice(patientIds);
    
    // Generate dates
    const prescriptionDate = randomDate(START_DATE, END_DATE);
    let fillDate = null;
    if (randomBoolean(0.95)) { // 95% chance of filling the prescription
      const fillDelay = randomInt(0, 5); // 0-5 days to fill
      fillDate = new Date(prescriptionDate);
      fillDate.setDate(fillDate.getDate() + fillDelay);
    }
    
    // Calculate quantity and days supply
    const { quantity, daysSupply } = calculateQuantityAndDaysSupply(medication);
    
    // Calculate refills
    const refills = calculateRefills(medication);
    
    // Determine if this is a new prescription (80% chance) or refill
    const isNew = randomBoolean(0.8);
    const refillNumber = isNew ? 0 : randomInt(1, 3);
    
    // Generate the CSV row with a standard UUID
    const row = [
      uuidv4(), // id as a standard UUID
      providerId, // provider_id
      patientId, // patient_id
      medication.id, // medication_id
      medication.medication_name || medication.name, // medication_name
      medication.category, // medication_category
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
    
    // Write to CSV
    outputStream.write(row + '\n');
    
    prescriptionCount++;
  }
  
  return prescriptionCount;
}

// Phase 2: Generate distribution prescriptions (900K total, distributed by specialty and region)
async function generateDistributionPrescriptions(
  providers, 
  medications, 
  outputStream, 
  targetCount
) {
  // Calculate weights for each provider based on specialty and region
  const providerWeights = providers.map(provider => {
    const specialty = provider.specialty;
    const region = provider.region;
    
    // Base weight from specialty
    let weight = SPECIALTY_WEIGHTS[specialty] || 0.4;
    
    // Adjust by region
    weight *= REGION_WEIGHTS[region] || 0.8;
    
    return weight;
  });
