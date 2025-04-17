/**
 * Mock Data Service
 * 
 * This service provides high-quality mock data for the application when
 * the database is unavailable or for development/testing purposes.
 */

// Mock medication categories
export const MOCK_MEDICATION_CATEGORIES = [
  'Analgesics',
  'Antibiotics',
  'Antidepressants',
  'Antidiabetics',
  'Antihistamines',
  'Antihypertensives',
  'Antivirals',
  'Bronchodilators',
  'Cardiovascular',
  'Corticosteroids',
  'Gastrointestinal',
  'Hormones',
  'Immunosuppressants',
  'Lipid-lowering',
  'Muscle Relaxants',
  'Neurological',
  'NSAIDs',
  'Psychiatric',
  'Respiratory',
  'Statins'
];

// Mock medications with realistic data
export const MOCK_MEDICATIONS = [
  // Analgesics
  { id: 'med-1', name: 'Acetaminophen', category: 'Analgesics', subcategory: 'Non-opioid', is_brand_name: false, is_target_medication: true },
  { id: 'med-2', name: 'Tylenol', category: 'Analgesics', subcategory: 'Non-opioid', is_brand_name: true, is_target_medication: false },
  { id: 'med-3', name: 'Ibuprofen', category: 'Analgesics', subcategory: 'NSAID', is_brand_name: false, is_target_medication: true },
  { id: 'med-4', name: 'Advil', category: 'Analgesics', subcategory: 'NSAID', is_brand_name: true, is_target_medication: false },
  { id: 'med-5', name: 'Naproxen', category: 'Analgesics', subcategory: 'NSAID', is_brand_name: false, is_target_medication: true },
  { id: 'med-6', name: 'Aleve', category: 'Analgesics', subcategory: 'NSAID', is_brand_name: true, is_target_medication: false },
  
  // Antibiotics
  { id: 'med-7', name: 'Amoxicillin', category: 'Antibiotics', subcategory: 'Penicillin', is_brand_name: false, is_target_medication: true },
  { id: 'med-8', name: 'Augmentin', category: 'Antibiotics', subcategory: 'Penicillin', is_brand_name: true, is_target_medication: false },
  { id: 'med-9', name: 'Azithromycin', category: 'Antibiotics', subcategory: 'Macrolide', is_brand_name: false, is_target_medication: true },
  { id: 'med-10', name: 'Zithromax', category: 'Antibiotics', subcategory: 'Macrolide', is_brand_name: true, is_target_medication: false },
  { id: 'med-11', name: 'Ciprofloxacin', category: 'Antibiotics', subcategory: 'Fluoroquinolone', is_brand_name: false, is_target_medication: true },
  { id: 'med-12', name: 'Cipro', category: 'Antibiotics', subcategory: 'Fluoroquinolone', is_brand_name: true, is_target_medication: false },
  
  // Antidepressants
  { id: 'med-13', name: 'Fluoxetine', category: 'Antidepressants', subcategory: 'SSRI', is_brand_name: false, is_target_medication: true },
  { id: 'med-14', name: 'Prozac', category: 'Antidepressants', subcategory: 'SSRI', is_brand_name: true, is_target_medication: false },
  { id: 'med-15', name: 'Sertraline', category: 'Antidepressants', subcategory: 'SSRI', is_brand_name: false, is_target_medication: true },
  { id: 'med-16', name: 'Zoloft', category: 'Antidepressants', subcategory: 'SSRI', is_brand_name: true, is_target_medication: false },
  { id: 'med-17', name: 'Venlafaxine', category: 'Antidepressants', subcategory: 'SNRI', is_brand_name: false, is_target_medication: true },
  { id: 'med-18', name: 'Effexor', category: 'Antidepressants', subcategory: 'SNRI', is_brand_name: true, is_target_medication: false },
  
  // Antidiabetics
  { id: 'med-19', name: 'Metformin', category: 'Antidiabetics', subcategory: 'Biguanide', is_brand_name: false, is_target_medication: true },
  { id: 'med-20', name: 'Glucophage', category: 'Antidiabetics', subcategory: 'Biguanide', is_brand_name: true, is_target_medication: false },
  { id: 'med-21', name: 'Glipizide', category: 'Antidiabetics', subcategory: 'Sulfonylurea', is_brand_name: false, is_target_medication: true },
  { id: 'med-22', name: 'Glucotrol', category: 'Antidiabetics', subcategory: 'Sulfonylurea', is_brand_name: true, is_target_medication: false },
  { id: 'med-23', name: 'Insulin Glargine', category: 'Antidiabetics', subcategory: 'Insulin', is_brand_name: false, is_target_medication: true },
  { id: 'med-24', name: 'Lantus', category: 'Antidiabetics', subcategory: 'Insulin', is_brand_name: true, is_target_medication: false },
  
  // Antihypertensives
  { id: 'med-25', name: 'Lisinopril', category: 'Antihypertensives', subcategory: 'ACE Inhibitor', is_brand_name: false, is_target_medication: true },
  { id: 'med-26', name: 'Prinivil', category: 'Antihypertensives', subcategory: 'ACE Inhibitor', is_brand_name: true, is_target_medication: false },
  { id: 'med-27', name: 'Losartan', category: 'Antihypertensives', subcategory: 'ARB', is_brand_name: false, is_target_medication: true },
  { id: 'med-28', name: 'Cozaar', category: 'Antihypertensives', subcategory: 'ARB', is_brand_name: true, is_target_medication: false },
  { id: 'med-29', name: 'Amlodipine', category: 'Antihypertensives', subcategory: 'Calcium Channel Blocker', is_brand_name: false, is_target_medication: true },
  { id: 'med-30', name: 'Norvasc', category: 'Antihypertensives', subcategory: 'Calcium Channel Blocker', is_brand_name: true, is_target_medication: false },
  
  // Statins
  { id: 'med-31', name: 'Atorvastatin', category: 'Statins', subcategory: 'HMG-CoA Reductase Inhibitor', is_brand_name: false, is_target_medication: true },
  { id: 'med-32', name: 'Lipitor', category: 'Statins', subcategory: 'HMG-CoA Reductase Inhibitor', is_brand_name: true, is_target_medication: false },
  { id: 'med-33', name: 'Rosuvastatin', category: 'Statins', subcategory: 'HMG-CoA Reductase Inhibitor', is_brand_name: false, is_target_medication: true },
  { id: 'med-34', name: 'Crestor', category: 'Statins', subcategory: 'HMG-CoA Reductase Inhibitor', is_brand_name: true, is_target_medication: false },
  { id: 'med-35', name: 'Simvastatin', category: 'Statins', subcategory: 'HMG-CoA Reductase Inhibitor', is_brand_name: false, is_target_medication: true },
  { id: 'med-36', name: 'Zocor', category: 'Statins', subcategory: 'HMG-CoA Reductase Inhibitor', is_brand_name: true, is_target_medication: false }
];

// Mock specialties with realistic data
export const MOCK_SPECIALTIES = [
  'Allergy & Immunology',
  'Anesthesiology',
  'Cardiology',
  'Dermatology',
  'Emergency Medicine',
  'Endocrinology',
  'Family Medicine',
  'Gastroenterology',
  'Geriatrics',
  'Hematology',
  'Infectious Disease',
  'Internal Medicine',
  'Nephrology',
  'Neurology',
  'Obstetrics & Gynecology',
  'Oncology',
  'Ophthalmology',
  'Orthopedics',
  'Otolaryngology',
  'Pediatrics',
  'Physical Medicine',
  'Psychiatry',
  'Pulmonology',
  'Radiology',
  'Rheumatology',
  'Surgery',
  'Urology'
];

// Mock regions with realistic data
export const MOCK_REGIONS = [
  { id: 'region-1', name: 'Northeast', type: 'Region' },
  { id: 'region-2', name: 'Mid-Atlantic', type: 'Region' },
  { id: 'region-3', name: 'Southeast', type: 'Region' },
  { id: 'region-4', name: 'Midwest', type: 'Region' },
  { id: 'region-5', name: 'Southwest', type: 'Region' },
  { id: 'region-6', name: 'West', type: 'Region' },
  { id: 'region-7', name: 'Northwest', type: 'Region' },
  { id: 'region-8', name: 'New York', type: 'State' },
  { id: 'region-9', name: 'California', type: 'State' },
  { id: 'region-10', name: 'Texas', type: 'State' },
  { id: 'region-11', name: 'Florida', type: 'State' },
  { id: 'region-12', name: 'Illinois', type: 'State' },
  { id: 'region-13', name: 'Pennsylvania', type: 'State' },
  { id: 'region-14', name: 'Ohio', type: 'State' },
  { id: 'region-15', name: 'Georgia', type: 'State' },
  { id: 'region-16', name: 'North Carolina', type: 'State' },
  { id: 'region-17', name: 'Michigan', type: 'State' },
  { id: 'region-18', name: 'New Jersey', type: 'State' },
  { id: 'region-19', name: 'Virginia', type: 'State' },
  { id: 'region-20', name: 'Washington', type: 'State' }
];

// Mock provider data - with a realistic dataset size
export const generateMockProviders = (count: number = 150000) => {
  const providers = [];
  
  for (let i = 1; i <= count; i++) {
    const specialty = MOCK_SPECIALTIES[Math.floor(Math.random() * MOCK_SPECIALTIES.length)];
    const region = MOCK_REGIONS[Math.floor(Math.random() * MOCK_REGIONS.length)];
    const gender = Math.random() > 0.5 ? 'male' : 'female';
    const firstName = gender === 'male' 
      ? ['James', 'John', 'Robert', 'Michael', 'William', 'David', 'Richard', 'Joseph', 'Thomas', 'Charles'][Math.floor(Math.random() * 10)]
      : ['Mary', 'Patricia', 'Jennifer', 'Linda', 'Elizabeth', 'Barbara', 'Susan', 'Jessica', 'Sarah', 'Karen'][Math.floor(Math.random() * 10)];
    const lastName = ['Smith', 'Johnson', 'Williams', 'Jones', 'Brown', 'Davis', 'Miller', 'Wilson', 'Moore', 'Taylor'][Math.floor(Math.random() * 10)];
    
    providers.push({
      id: `provider-${i}`,
      provider_id: `provider-${i}`,
      npi: `${1000000000 + i}`,
      name: `Dr. ${firstName} ${lastName}`,
      specialty: specialty,
      region: region.name,
      geographic_area: region.name,
      gender: gender,
      prescription_count: Math.floor(Math.random() * 500) + 50
    });
  }
  
  return providers;
};

// Mock data service functions
export const mockDataService = {
  // Get medication categories
  getMedicationCategories: async (): Promise<string[]> => {
    console.log('Using mock medication categories');
    return MOCK_MEDICATION_CATEGORIES;
  },
  
  // Get medications by category
  getMedicationsByCategory: async (category?: string): Promise<any[]> => {
    console.log(`Using mock medications${category ? ` for category: ${category}` : ''}`);
    
    if (category) {
      return MOCK_MEDICATIONS.filter(med => med.category === category);
    }
    
    return MOCK_MEDICATIONS;
  },
  
  // Get all specialties
  getSpecialties: async (): Promise<string[]> => {
    console.log('Using mock specialties');
    return MOCK_SPECIALTIES;
  },
  
  // Get all regions
  getRegions: async (): Promise<any[]> => {
    console.log('Using mock regions');
    return MOCK_REGIONS;
  },
  
  // Get providers by filter
  getProvidersByFilter: async (filter: any): Promise<string[]> => {
    console.log('Using mock providers with filter:', filter);
    
    // Generate a set of mock providers - we'll use a smaller subset for performance
    // but scale the results to simulate a larger database
    const sampleProviders = generateMockProviders(1000);
    
    // Apply filters
    let filteredProviders = sampleProviders;
    
    // Filter by specialty
    if (filter.specialties?.length) {
      filteredProviders = filteredProviders.filter(provider => 
        filter.specialties.includes(provider.specialty)
      );
    }
    
    // Filter by region
    if (filter.regions?.length) {
      filteredProviders = filteredProviders.filter(provider => 
        filter.regions.includes(provider.region) || filter.regions.includes(provider.geographic_area)
      );
    }
    
    // Filter by gender
    if (filter.gender && filter.gender !== 'all') {
      filteredProviders = filteredProviders.filter(provider => 
        provider.gender === filter.gender
      );
    }
    
  // Filter by medications (simulate providers who prescribe these medications)
  if (filter.medicationIds?.length) {
    // Increase the filter ratio as more medications are added (opposite of previous logic)
    // This ensures adding more medications increases the provider count
    const filterRatio = 0.5 + (0.1 * Math.min(filter.medicationIds.length, 5));
    filteredProviders = filteredProviders.filter(() => Math.random() < filterRatio);
  }
    
    // Filter by excluded medications (simulate providers who don't prescribe these medications)
    if (filter.excludedMedicationIds?.length) {
      // Randomly filter out some providers to simulate excluded medication filtering
      const filterRatio = 0.9 - (0.05 * Math.min(filter.excludedMedicationIds.length, 5));
      filteredProviders = filteredProviders.filter(() => Math.random() < filterRatio);
    }
    
    // Return just the IDs, but scale up to simulate a larger database
    const scaleFactor = 150; // 1000 * 150 = 150,000 total providers
    
    // Get the IDs from our filtered sample
    const sampleIds = filteredProviders.map(provider => provider.id);
    
    // For a realistic result, we'll return the actual sample IDs plus generate additional IDs
    // to reach the scaled count
    const totalCount = Math.min(250000, Math.round(sampleIds.length * scaleFactor));
    const additionalCount = totalCount - sampleIds.length;
    
    if (additionalCount <= 0) {
      return sampleIds;
    }
    
    // Generate additional IDs
    const additionalIds = Array.from({ length: additionalCount }, (_, i) => 
      `provider-${sampleIds.length + i + 1}`
    );
    
    return [...sampleIds, ...additionalIds];
  },
  
  // Get provider details
  getProviderDetails: async (providerIds: string[]): Promise<any[]> => {
    console.log(`Getting details for ${providerIds.length} providers`);
    
    // Generate a set of mock providers - just enough to cover the requested IDs
    const allProviders = generateMockProviders(Math.max(1000, providerIds.length));
    
    // Filter to just the requested providers
    const providers = allProviders.filter(provider => 
      providerIds.includes(provider.id)
    );
    
    // If we don't have enough providers, generate some more
    if (providers.length < providerIds.length) {
      const missingCount = providerIds.length - providers.length;
      const additionalProviders = generateMockProviders(missingCount).map((provider, index) => ({
        ...provider,
        id: providerIds[providers.length + index],
        provider_id: providerIds[providers.length + index]
      }));
      
      return [...providers, ...additionalProviders];
    }
    
    return providers;
  },
  
  // Estimate provider count
  estimateProviderCount: async (filter: any): Promise<number> => {
    console.log('Estimating provider count with filter:', filter);
    
    // Get provider IDs and return the count
    const providerIds = await mockDataService.getProvidersByFilter(filter);
    return providerIds.length;
  }
};
