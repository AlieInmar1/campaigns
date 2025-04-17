#!/usr/bin/env node

/**
 * Manual Provider Data Generator
 * 
 * This script generates a properly formatted provider dataset with
 * good representation across specialties and regions
 */

const fs = require('fs');
const { v4: uuidv4 } = require('uuid');

// Output file
const OUTPUT_FILE = 'providers_synthetic.csv';

// Configuration
const PROVIDERS_PER_SPECIALTY_PER_REGION = 100; // 100 providers for each specialty in each region

// Define specialties we want to include
const SPECIALTIES = [
  'Internal Medicine',
  'Family Medicine',
  'Primary Care',
  'Cardiology',
  'Endocrinology',
  'Pulmonology',
  'Neurology',
  'Psychiatry',
  'Gastroenterology',
  'Dermatology',
  'Oncology',
  'Rheumatology',
  'Infectious Disease',
  'Obstetrics & Gynecology',
  'Pediatrics',
  'Nephrology',
  'Urology',
  'General Surgery'
];

// Define regions to include
const REGIONS = [
  'Northeast',
  'Northwest',
  'South',
  'West',
  'Midwest',
  'Southeast',
  'Southwest'
];

// Generate a 10-digit NPI
function generateNPI() {
  return Math.floor(1000000000 + Math.random() * 9000000000).toString();
}

// Generate the provider dataset
function generateProviders() {
  console.log(`Generating synthetic provider dataset...`);
  
  // Create output file with header
  const outputStream = fs.createWriteStream(OUTPUT_FILE);
  outputStream.write('id,npi,specialty,region,created_at\n');
  
  let providerCount = 0;
  
  // Generate providers for each specialty and region
  for (const specialty of SPECIALTIES) {
    for (const region of REGIONS) {
      for (let i = 0; i < PROVIDERS_PER_SPECIALTY_PER_REGION; i++) {
        // Generate a provider
        const id = uuidv4();
        const npi = generateNPI();
        const timestamp = new Date().toISOString();
        
        // Write to CSV
        const csvLine = `${id},${npi},"${specialty}","${region}",${timestamp}\n`;
        outputStream.write(csvLine);
        
        providerCount++;
      }
      
      // Log progress
      console.log(`Generated ${PROVIDERS_PER_SPECIALTY_PER_REGION} providers for ${specialty} in ${region}`);
    }
  }
  
  outputStream.end();
  
  console.log(`Successfully generated ${providerCount} providers to ${OUTPUT_FILE}`);
  return providerCount;
}

// Run the function
const count = generateProviders();
console.log(`Total providers created: ${count}`);
