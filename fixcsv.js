#!/usr/bin/env node

/**
 * Simple CSV parser for providers_final.csv
 */

const fs = require('fs');

const srcFile = 'providers_final.csv';
const outFile = 'providers_fixed.csv';

// Create new file with correct header
fs.writeFileSync(outFile, 'id,npi,specialty,region,created_at\n');

// Read file content and process
const content = fs.readFileSync(srcFile, 'utf8');
const lines = content.split('\n');

// Skip header
let count = 0;
for (let i = 1; i < lines.length; i++) {
  const line = lines[i].trim();
  if (!line) continue;
  
  // Try to extract data using simple string operations
  try {
    // First 36 chars should be the UUID
    const id = line.substring(0, 36);
    if (!id.match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)) {
      continue;
    }
    
    // Next 10 chars should be the NPI
    const npi = line.substring(36, 46);
    if (!npi.match(/^\d{10}$/)) {
      continue;
    }
    
    // Rest has quotes around the specialty and region
    const rest = line.substring(46);
    
    // Find first quote and match until second quote for specialty
    const firstQuote = rest.indexOf('"');
    if (firstQuote === -1) continue;
    
    const secondQuote = rest.indexOf('"', firstQuote + 1);
    if (secondQuote === -1) continue;
    
    const specialty = rest.substring(firstQuote + 1, secondQuote);
    
    // Find next quotes for region
    const thirdQuote = rest.indexOf('"', secondQuote + 1);
    if (thirdQuote === -1) continue;
    
    const fourthQuote = rest.indexOf('"', thirdQuote + 1);
    if (fourthQuote === -1) continue;
    
    const region = rest.substring(thirdQuote + 1, fourthQuote);
    
    // Rest should be timestamp
    const timestamp = rest.substring(fourthQuote + 1);
    if (!timestamp.match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)) {
      continue;
    }
    
    // Write fixed CSV line
    fs.appendFileSync(outFile, `${id},${npi},"${specialty}","${region}",${timestamp}\n`);
    count++;
    
    if (count % 1000 === 0) {
      console.log(`Processed ${count} providers...`);
    }
  } catch (err) {
    // Skip problematic lines
    console.warn(`Error with line ${i}: ${err.message}`);
  }
}

console.log(`Successfully processed ${count} providers to ${outFile}`);
