#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const readline = require('readline');

// Configuration - batch IDs for tracking data sources
const BATCH_ID = 1; // Use a single batch ID for all generated data

// Configuration for top specialties vs others
const TOP_SPECIALTIES = [
  'Cardiology',
  'Endocrinology',
  'Pulmonology',
  'Neurology',
  'Psychiatry',
  'Dermatology',
  'Gastroenterology',
  'Family Medicine',
  'Internal Medicine',
  'Primary Care'
];

const PRESCRIPTIONS_PER_TOP_SPECIALTY = 500;
const PRESCRIPTIONS_PER_OTHER_SPECIALTY = 10;

// Other configuration
const PATIENTS_PER_PROVIDER = 50; // We'll distribute prescriptions among these patients
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

// CSV parsing and creation helpers
function parseCSV(text) {
  const lines = text.split('\n');
  const headers = parseCSVLine(lines[0]);
  
  return lines.slice(1).filter(line => line.trim()).map(line => {
    const values = parseCSVLine(line);
    return headers.reduce((obj, header, i) => {
      obj[header.replace(/"/g, '')] = values[i]?.replace(/"/g, '') || '';
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

// Main functions
async function loadMedications() {
  try {
    const data = fs.readFileSync('medications.csv', 'utf8');
    return parseCSV(data);
  } catch (error) {
    console.error('Error loading medications:', error);
    process.exit(1);
  }
}

async function* readProvidersLineByLine() {
  const fileStream = fs.createReadStream('providers.csv');
  const rl = readline.createInterface({
    input: fileStream,
    crlfDelay: Infinity
  });
  
  let isFirstLine = true;
  let headers;
  
  for await (const line of rl) {
    if (isFirstLine) {
      headers = parseCSVLine(line).map(h => h.replace(/"/g, ''));
      isFirstLine = false;
      continue;
    }
    
    const values = parseCSVLine(line);
    const provider = headers.reduce((obj, header, i) => {
      obj[header] = values[i]?.replace(/"/g, '') || '';
      return obj;
    }, {});
    
    yield provider;
  }
}

function filterMedicationsBySpecialty(medications, specialty) {
  // Ensure medications has valid elements before filtering
  if (!medications || medications.length === 0) {
    console.warn(`No medications available to filter for specialty: ${specialty}`);
    return [];
  }
  
  // Validate that medications have IDs
  const validMedications = medications.filter(med => med && med.id);
  if (validMedications.length === 0) {
    console.warn(`No medications with valid IDs found`);
    return [];
  }
  
  // Default filter - return a reasonable number of medications instead of random filtering
  const defaultFilter = () => {
    // Return at least 10 medications or 20% of the available medications, whichever is more
    const sampleSize = Math.max(10, Math.floor(validMedications.length * 0.2));
    return validMedications.slice(0, sampleSize);
  };
  
  // Specialty-specific medication filters with fallbacks
  let filtered;
  
  switch(specialty) {
    case 'Cardiology':
      filtered = validMedications.filter(med => 
        med.category === 'Cardiovascular' || 
        (med.name && med.name.toLowerCase().includes('statin')) || 
        med.category === 'Beta Blocker' ||
        med.category === 'ACE Inhibitor' ||
        med.category === 'ARB' ||
        med.category === 'Anticoagulant');
      break;
    
    case 'Endocrinology':
      filtered = validMedications.filter(med => 
        med.category === 'Diabetes' || 
        (med.category && med.category.includes('Insulin')) ||
        (med.category && med.category.includes('Thyroid')) ||
        med.specialty === 'Endocrinology');
      break;
    
    case 'Pulmonology':
      filtered = validMedications.filter(med => 
        med.category === 'Respiratory' ||
        (med.category && med.category.includes('Beta Agonist')) ||
        med.specialty === 'Pulmonology');
      break;
    
    case 'Neurology':
      filtered = validMedications.filter(med => 
        med.category === 'Neurology' ||
        (med.category && med.category.includes('Anticonvulsant')) ||
        med.specialty === 'Neurology');
      break;
    
    case 'Psychiatry':
      filtered = validMedications.filter(med => 
        med.category === 'Psychiatric' ||
        (med.category && med.category.includes('Antidepressant')) ||
        (med.category && med.category.includes('Antipsychotic')) ||
        med.specialty === 'Psychiatry');
      break;
        
    case 'Dermatology':
      filtered = validMedications.filter(med => 
        med.category === 'Dermatologic' ||
        (med.category && med.category.includes('Topical')) ||
        med.specialty === 'Dermatology');
      break;
    
    case 'Gastroenterology':
      filtered = validMedications.filter(med => 
        med.category === 'Gastrointestinal' ||
        (med.category && med.category.includes('GI')) ||
        med.specialty === 'Gastroenterology');
      break;
    
    case 'Infectious Disease':
      filtered = validMedications.filter(med => 
        med.category === 'Antibiotic' ||
        med.category === 'Antiviral' ||
        med.category === 'Antifungal' ||
        (med.category && med.category.includes('Antimicrobial')) ||
        med.specialty === 'Infectious Disease');
      break;
    
    case 'Oncology':
      filtered = validMedications.filter(med => 
        med.category === 'Oncology' ||
        (med.category && med.category.includes('Chemotherapy')) ||
        (med.category && med.category.includes('Antineoplastic')) ||
        med.specialty === 'Oncology');
      break;
    
    case 'Family Medicine':
    case 'Internal Medicine':
    case 'Primary Care':
      // Primary care gets a wider selection
      filtered = validMedications.slice(0, Math.floor(validMedications.length * 0.6));
      break;
    
    default:
      filtered = defaultFilter();
      break;
  }
  
  // If we didn't get any medications, fall back to default
  if (!filtered || filtered.length === 0) {
    console.warn(`No matching medications found for specialty ${specialty}, using default selection`);
    filtered = defaultFilter();
  }
  
  // Ensure we have at least 5 medications to choose from
  if (filtered.length < 5) {
    const additionalNeeded = 5 - filtered.length;
    // Add some additional random medications from the valid set
    const additionalMeds = validMedications
      .filter(med => !filtered.includes(med))
      .slice(0, additionalNeeded);
    
    filtered = [...filtered, ...additionalMeds];
  }
  
  return filtered;
}

function determineBrandPreference(provider, specialty) {
  // Base preference adjusted by specialty and practice size
  let preference = 0.5; // Default
  
  // Adjust by practice size
  if (provider.practice_size === 'hospital' || provider.practice_size === 'academic') {
    preference += 0.2;
  } else if (provider.practice_size === 'large') {
    preference += 0.1;
  } else if (provider.practice_size === 'solo') {
    preference -= 0.1;
  }
  
  // Specialty-specific adjustments
  switch(specialty) {
    case 'Cardiology': preference += 0.1; break;
    case 'Endocrinology': preference += 0.15; break;
    case 'Neurology': preference += 0.15; break;
    case 'Oncology': preference += 0.25; break;
    // Add more specialty adjustments as needed
  }
  
  // Cap between 0.3 and 0.8
  return Math.min(0.8, Math.max(0.3, preference));
}

function generatePatientIds(count) {
  const patientIds = [];
  for (let i = 0; i < count; i++) {
    patientIds.push(uuidv4());
  }
  return patientIds;
}

function filterMedicationsByBrandPreference(medications, brandPreference) {
  return medications.filter(med => {
    const isBrand = med.is_brand_name === 'true';
    if (isBrand) {
      return Math.random() < brandPreference;
    } else {
      return Math.random() > brandPreference;
    }
  });
}

function calculateQuantityAndDaysSupply(medication) {
  const category = medication.category || '';
  
  // For chronic medications (usually taken daily)
  if (['Cardiovascular', 'Diabetes', 'Psychiatric', 'Endocrine'].some(c => category.includes(c))) {
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
  if (['Cardiovascular', 'Diabetes', 'Psychiatric', 'Endocrine'].some(c => category.includes(c))) {
    return 2 + Math.floor(Math.random() * 4); // 2-5 refills
  } 
  
  // For acute medications
  else {
    return Math.floor(Math.random() * 3); // 0-2 refills
  }
}

// Determine how many prescriptions to generate based on specialty
function getPrescriptionCount(specialty) {
  if (TOP_SPECIALTIES.includes(specialty)) {
    return PRESCRIPTIONS_PER_TOP_SPECIALTY;
  }
  return PRESCRIPTIONS_PER_OTHER_SPECIALTY;
}

// Main function to generate prescriptions for a provider
async function generatePrescriptionsForProvider(provider, medications, outputStream, filePrefix) {
  const providerId = provider.provider_id;
  const specialty = provider.specialty;
  
  // Skip if provider_id is missing
  if (!providerId) {
    console.warn(`Skipping provider with missing ID: ${provider}`);
    return 0;
  }
  
  // Determine brand preference and target prescription count
  const brandPreference = determineBrandPreference(provider, specialty);
  const targetCount = getPrescriptionCount(specialty);
  
  // Filter medications for this specialty
  const specialtyMedications = filterMedicationsBySpecialty(medications, specialty);
  
  // Skip if no eligible medications
  if (specialtyMedications.length === 0) {
    console.warn(`No eligible medications for provider ${providerId} in ${specialty}`);
    return 0;
  }
  
  // Filter medications by brand preference
  const eligibleMedications = filterMedicationsByBrandPreference(specialtyMedications, brandPreference);
  if (eligibleMedications.length === 0) {
    console.warn(`No eligible medications after brand filtering for ${providerId}`);
    return 0;
  }
  
  // Generate synthetic patient IDs
  const patientIds = generatePatientIds(PATIENTS_PER_PROVIDER);
  
  let prescriptionCount = 0;
  
  // Generate prescriptions for this provider
  for (let i = 0; i < targetCount; i++) {
    // Generate random patient
    const patientId = randomChoice(patientIds);
    
    // Generate random medication
    const medication = randomChoice(eligibleMedications);
    
    // Generate dates
    const prescriptionDate = randomDate(START_DATE, END_DATE);
    let fillDate = null;
    if (randomBoolean(0.9)) { // 90% chance of filling the prescription
      const fillDelay = randomInt(0, 7); // 0-7 days to fill
      fillDate = new Date(prescriptionDate);
      fillDate.setDate(fillDate.getDate() + fillDelay);
    }
    
    // Calculate quantity and days supply
    const { quantity, daysSupply } = calculateQuantityAndDaysSupply(medication);
    
    // Calculate refills
    const refills = calculateRefills(medication);
    
    // Determine if this is a new prescription (70% chance) or refill
    const isNew = randomBoolean(0.7);
    const refillNumber = isNew ? 0 : randomInt(1, 5);
    
      // Generate the CSV row with a standard UUID
      const row = [
        uuidv4(), // id as a standard UUID (no prefix)
      providerId, // provider_id
      patientId, // patient_id
      medication.id, // medication_id
      medication.name, // medication_name
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

// Constants for file size management
const MAX_FILE_SIZE_MB = 90; // Keep files under 90MB to be safe
const ESTIMATED_BYTES_PER_RECORD = 400; // Estimated average size of a prescription record
const MAX_RECORDS_PER_FILE = Math.floor((MAX_FILE_SIZE_MB * 1024 * 1024) / ESTIMATED_BYTES_PER_RECORD);

// Helper function to create a new output file
function createOutputFile(outputDir, fileIndex) {
  const outputPath = path.join(outputDir, `prescriptions_part${fileIndex}.csv`);
  const outputStream = fs.createWriteStream(outputPath);
  
  // Write CSV header
  const header = 'id,provider_id,patient_id,medication_id,medication_name,medication_category,prescription_date,fill_date,quantity,days_supply,refills,refill_number,is_new,batch_id,created_at\n';
  outputStream.write(header);
  
  return {
    stream: outputStream,
    path: outputPath,
    recordCount: 0
  };
}

// Main function to generate all prescriptions
async function generateAllPrescriptions() {
  console.log('Loading medications...');
  const medications = await loadMedications();
  console.log(`Loaded ${medications.length} medications.`);
  
  // Create output directory if it doesn't exist
  const outputDir = '.';
  
  // Get all providers first
  const providers = [];
  for await (const provider of readProvidersLineByLine()) {
    providers.push(provider);
  }
  
  console.log(`Loaded ${providers.length} providers`);
  
  // Group providers by specialty
  const specialtyGroups = {};
  for (const provider of providers) {
    const specialty = provider.specialty || 'Unknown';
    if (!specialtyGroups[specialty]) {
      specialtyGroups[specialty] = [];
    }
    specialtyGroups[specialty].push(provider);
  }
  
  // We'll organize files by specialty groups to keep related data together
  // First the top specialties (which have more data)
  const specialtyOrder = [
    // First process top specialties (more data per provider)
    ...TOP_SPECIALTIES,
    // Then other specialties
    ...Object.keys(specialtyGroups).filter(s => !TOP_SPECIALTIES.includes(s))
  ];
  
  // Process each provider
  let providerCount = 0;
  let totalPrescriptionCount = 0;
  let specialtyStats = {};
  let fileIndex = 1;
  let fileList = [];
  
  // Create first output file
  let currentFile = createOutputFile(outputDir, fileIndex);
  fileList.push(`prescriptions_part${fileIndex}.csv`);
  
  console.log('Generating prescriptions for all providers...');
  
  // Process providers by specialty groups
  for (const specialty of specialtyOrder) {
    const specialtyProviders = specialtyGroups[specialty] || [];
    if (specialtyProviders.length === 0) continue;
    
    console.log(`Processing ${specialtyProviders.length} providers for ${specialty}...`);
    
    for (const provider of specialtyProviders) {
      providerCount++;
      
      // If we're approaching the max file size, start a new file
      if (currentFile.recordCount >= MAX_RECORDS_PER_FILE) {
        // Close current file
        currentFile.stream.end();
        console.log(`Completed file ${fileIndex} with ${currentFile.recordCount.toLocaleString()} prescriptions.`);
        
        // Start new file
        fileIndex++;
        currentFile = createOutputFile(outputDir, fileIndex);
        fileList.push(`prescriptions_part${fileIndex}.csv`);
      }
      
      // Generate prescriptions for this provider
      const count = await generatePrescriptionsForProvider(
        provider, 
        medications, 
        currentFile.stream, 
        `RX${fileIndex}-`
      );
      
      totalPrescriptionCount += count;
      currentFile.recordCount += count;
      
      // Update specialty stats
      if (!specialtyStats[specialty]) {
        specialtyStats[specialty] = { providers: 0, prescriptions: 0 };
      }
      specialtyStats[specialty].providers++;
      specialtyStats[specialty].prescriptions += count;
      
      // Log progress
      if (providerCount % 100 === 0) {
        console.log(`  Processed ${providerCount} providers, generated ${totalPrescriptionCount} prescriptions so far...`);
      }
    }
  }
  
  // Close final output stream
  currentFile.stream.end();
  console.log(`Completed file ${fileIndex} with ${currentFile.recordCount.toLocaleString()} prescriptions.`);
  
  console.log('\nSummary by Specialty:');
  for (const [specialty, stats] of Object.entries(specialtyStats)) {
    const avgPerProvider = Math.round(stats.prescriptions / stats.providers);
    console.log(`${specialty}: ${stats.prescriptions.toLocaleString()} prescriptions across ${stats.providers} providers (avg ${avgPerProvider} per provider)`);
  }
  
  console.log(`\nTotal: ${totalPrescriptionCount.toLocaleString()} prescriptions across ${providerCount} providers.`);
  console.log(`\nPrescriptions saved to ${fileIndex} files:`);
  fileList.forEach(file => {
    console.log(`- ${file}`);
  });
}

// Run the script
console.log('Starting prescription CSV generation...');
generateAllPrescriptions().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
