#!/usr/bin/env node

/**
 * Fix Providers CSV
 * 
 * This script properly formats providers_final.csv into a new file
 * that can be used with our prescription generation script.
 */

const fs = require('fs');

// Input and output files
const INPUT_FILE = 'providers_final.csv';
const OUTPUT_FILE = 'providers_fixed.csv';

// Fix the providers CSV file
function fixProvidersCSV() {
  console.log(`Reading providers from ${INPUT_FILE}...`);
  
  // Check if file exists
  if (!fs.existsSync(INPUT_FILE)) {
    console.error(`File not found: ${INPUT_FILE}`);
    process.exit(1);
  }
  
  // Read the file
  const content = fs.readFileSync(INPUT_FILE, 'utf8');
  const lines = content.split('\n').filter(line => line.trim());
  
  // Create output file with proper headers
  const outputStream = fs.createWriteStream(OUTPUT_FILE);
  outputStream.write('id,npi,specialty,region,created_at\n');
  
  // Process each data line
  let processed = 0;
  let skipped = 0;
  
  for (let i = 1; i < lines.length; i++) {
    const line = lines[i];
    
    try {
      // Extract ID - assuming it's a UUID at the start
      const uuidMatch = line.match(/^([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/i);
      if (!uuidMatch) {
        console.warn(`Line ${i}: No UUID found`);
        skipped++;
        continue;
      }
      
      const id = uuidMatch[1];
      // Get remainder after removing UUID
      let remaining = line.substring(id.length);
      
      // Extract NPI (10 digits after UUID)
      const npiMatch = remaining.match(/^(\d{10})/);
      if (!npiMatch) {
        console.warn(`Line ${i}: No NPI found`);
        skipped++;
        continue;
      }
      
      const npi = npiMatch[1];
      // Get remainder after removing NPI
      remaining = remaining.substring(npi.length);
      
      // Extract specialty between quotes
      const specialtyMatch = remaining.match(/,"([^"]+)"/);
      if (!specialtyMatch) {
        console.warn(`Line ${i}: No specialty found`);
        skipped++;
        continue;
      }
      
      const specialty = specialtyMatch[1];
      // Get remainder after removing specialty
      remaining = remaining.substring(specialtyMatch[0].length);
      
      // Extract region between quotes
      const regionMatch = remaining.match(/,"([^"]+)"/);
      if (!regionMatch) {
        console.warn(`Line ${i}: No region found`);
        skipped++;
        continue;
      }
      
      const region = regionMatch[1];
      // Get remainder after removing region
      remaining = remaining.substring(regionMatch[0].length);
      
      // Extract timestamp
      const timestampMatch = remaining.match(/(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+)/);
      if (!timestampMatch) {
        console.warn(`Line ${i}: No timestamp found`);
        skipped++;
        continue;
      }
      
      const timestamp = timestampMatch[1];
      
      // Write as properly formatted CSV
      const csvLine = `${id},${npi},"${specialty}","${region}",${timestamp}\n`;
      outputStream.write(csvLine);
      
      processed++;
      
      if (processed % 1000 === 0) {
        console.log(`Processed ${processed} providers so far...`);
      }
    } catch (err) {
      console.warn(`Error processing line ${i}: ${err.message}`);
      skipped++;
    }
  }
  
  outputStream.end();
  
  console.log(`Processed ${processed} providers (skipped ${skipped})`);
  console.log(`Fixed providers CSV saved to ${OUTPUT_FILE}`);
}

// Run the function
fixProvidersCSV();
