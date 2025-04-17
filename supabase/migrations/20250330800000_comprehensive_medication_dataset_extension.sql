-- Migration: Comprehensive Medication Dataset Extension
-- Creates additional medications for underrepresented specialties
-- Includes both generic and brand name versions for each medication

BEGIN;

-- Check if the function exists from previous migrations
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'insert_medication_pair'
  ) THEN
    -- Create the function if it doesn't exist
    CREATE OR REPLACE FUNCTION insert_medication_pair(
      generic_name TEXT,
      brand_names TEXT[],
      category TEXT,
      subcategory TEXT,
      specialty TEXT DEFAULT NULL,
      is_target BOOLEAN DEFAULT FALSE
    ) RETURNS VOID AS $$
    DECLARE
      brand_name TEXT;
      medication_code TEXT;
    BEGIN
      -- Insert generic version
      medication_code := 'med-' || lower(regexp_replace(generic_name, '[^a-zA-Z0-9]', '', 'g')) || '-gen';
      
      INSERT INTO medications (
        id, 
        code, 
        name, 
        category, 
        subcategory,
        specialty,
        is_brand_name, 
        is_target_medication,
        is_sample_data
      ) VALUES (
        gen_random_uuid(),
        medication_code,
        generic_name || ' (Generic)',
        category,
        subcategory,
        specialty,
        FALSE,
        is_target,
        TRUE
      ) ON CONFLICT (code) DO NOTHING;
      
      -- Insert each brand name version
      FOREACH brand_name IN ARRAY brand_names
      LOOP
        medication_code := 'med-' || lower(regexp_replace(brand_name, '[^a-zA-Z0-9]', '', 'g')) || '-brand';
        
        INSERT INTO medications (
          id, 
          code, 
          name, 
          category, 
          subcategory,
          specialty,
          generic_name,
          is_brand_name, 
          is_target_medication,
          is_sample_data
        ) VALUES (
          gen_random_uuid(),
          medication_code,
          brand_name || ' (Brand)',
          category,
          subcategory,
          specialty,
          generic_name,
          TRUE,
          is_target,
          TRUE
        ) ON CONFLICT (code) DO NOTHING;
      END LOOP;
    END;
    $$ LANGUAGE plpgsql;
  END IF;
END $$;

--------------------------------------------------------------
-- 1. DERMATOLOGY MEDICATIONS
--------------------------------------------------------------

-- Acne Treatments
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Isotretinoin',
    ARRAY['Absorica', 'Claravis', 'Zenatane'],
    'Dermatologic',
    'Acne Treatment',
    'Dermatology'
  );

  PERFORM insert_medication_pair(
    'Tretinoin',
    ARRAY['Retin-A', 'Atralin', 'Avita'],
    'Dermatologic',
    'Acne Treatment',
    'Dermatology'
  );

  PERFORM insert_medication_pair(
    'Adapalene',
    ARRAY['Differin', 'Epiduo'],
    'Dermatologic',
    'Acne Treatment',
    'Dermatology'
  );

  PERFORM insert_medication_pair(
    'Clindamycin/Benzoyl Peroxide',
    ARRAY['BenzaClin', 'Duac', 'Acanya'],
    'Dermatologic',
    'Acne Treatment',
    'Dermatology'
  );

  PERFORM insert_medication_pair(
    'Dapsone',
    ARRAY['Aczone'],
    'Dermatologic',
    'Acne Treatment',
    'Dermatology'
  );
END $$;

-- Topical Corticosteroids
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Clobetasol Propionate',
    ARRAY['Temovate', 'Clobex', 'Olux'],
    'Dermatologic',
    'Topical Corticosteroid',
    'Dermatology'
  );

  PERFORM insert_medication_pair(
    'Betamethasone Dipropionate',
    ARRAY['Diprolene', 'Diprosone'],
    'Dermatologic',
    'Topical Corticosteroid',
    'Dermatology'
  );

  PERFORM insert_medication_pair(
    'Mometasone Furoate',
    ARRAY['Elocon'],
    'Dermatologic',
    'Topical Corticosteroid',
    'Dermatology'
  );

  PERFORM insert_medication_pair(
    'Triamcinolone Acetonide',
    ARRAY['Kenalog', 'Triderm'],
    'Dermatologic',
    'Topical Corticosteroid',
    'Dermatology'
  );

  PERFORM insert_medication_pair(
    'Hydrocortisone',
    ARRAY['Cortaid', 'Cortizone-10'],
    'Dermatologic',
    'Topical Corticosteroid',
    'Dermatology'
  );
END $$;

-- Psoriasis Medications
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Calcipotriene',
    ARRAY['Dovonex', 'Sorilux'],
    'Dermatologic',
    'Psoriasis Treatment',
    'Dermatology'
  );

  PERFORM insert_medication_pair(
    'Calcipotriene/Betamethasone',
    ARRAY['Taclonex', 'Enstilar'],
    'Dermatologic',
    'Psoriasis Treatment',
    'Dermatology'
  );

  PERFORM insert_medication_pair(
    'Methotrexate',
    ARRAY['Otrexup', 'Rasuvo', 'Trexall'],
    'Dermatologic',
    'Psoriasis Treatment',
    'Dermatology'
  );

  PERFORM insert_medication_pair(
    'Apremilast',
    ARRAY['Otezla'],
    'Dermatologic',
    'Psoriasis Treatment',
    'Dermatology'
  );

  PERFORM insert_medication_pair(
    'Secukinumab',
    ARRAY['Cosentyx'],
    'Dermatologic',
    'Psoriasis Treatment',
    'Dermatology'
  );
END $$;

-- Other Dermatologic Agents
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Tacrolimus',
    ARRAY['Protopic'],
    'Dermatologic',
    'Immunomodulator',
    'Dermatology'
  );

  PERFORM insert_medication_pair(
    'Pimecrolimus',
    ARRAY['Elidel'],
    'Dermatologic',
    'Immunomodulator',
    'Dermatology'
  );

  PERFORM insert_medication_pair(
    'Dupilumab',
    ARRAY['Dupixent'],
    'Dermatologic',
    'Monoclonal Antibody',
    'Dermatology'
  );

  PERFORM insert_medication_pair(
    'Ivermectin',
    ARRAY['Soolantra', 'Sklice'],
    'Dermatologic',
    'Antiparasitic',
    'Dermatology'
  );

  PERFORM insert_medication_pair(
    'Mupirocin',
    ARRAY['Bactroban'],
    'Dermatologic',
    'Topical Antibiotic',
    'Dermatology'
  );
END $$;

--------------------------------------------------------------
-- 2. GASTROENTEROLOGY MEDICATIONS
--------------------------------------------------------------

-- Proton Pump Inhibitors (PPIs)
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Esomeprazole',
    ARRAY['Nexium', 'Nexium 24HR'],
    'Gastrointestinal',
    'Proton Pump Inhibitor',
    'Gastroenterology'
  );

  PERFORM insert_medication_pair(
    'Lansoprazole',
    ARRAY['Prevacid', 'Prevacid 24HR'],
    'Gastrointestinal',
    'Proton Pump Inhibitor',
    'Gastroenterology'
  );

  PERFORM insert_medication_pair(
    'Dexlansoprazole',
    ARRAY['Dexilant'],
    'Gastrointestinal',
    'Proton Pump Inhibitor',
    'Gastroenterology'
  );

  PERFORM insert_medication_pair(
    'Rabeprazole',
    ARRAY['Aciphex'],
    'Gastrointestinal',
    'Proton Pump Inhibitor',
    'Gastroenterology'
  );
END $$;

-- H2 Receptor Antagonists
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Ranitidine',
    ARRAY['Zantac'],
    'Gastrointestinal',
    'H2 Receptor Antagonist',
    'Gastroenterology'
  );

  PERFORM insert_medication_pair(
    'Cimetidine',
    ARRAY['Tagamet'],
    'Gastrointestinal',
    'H2 Receptor Antagonist',
    'Gastroenterology'
  );

  PERFORM insert_medication_pair(
    'Nizatidine',
    ARRAY['Axid'],
    'Gastrointestinal',
    'H2 Receptor Antagonist',
    'Gastroenterology'
  );
END $$;

-- Inflammatory Bowel Disease (IBD) Treatments
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Infliximab',
    ARRAY['Remicade', 'Inflectra', 'Renflexis'],
    'Gastrointestinal',
    'TNF Inhibitor',
    'Gastroenterology'
  );

  PERFORM insert_medication_pair(
    'Vedolizumab',
    ARRAY['Entyvio'],
    'Gastrointestinal',
    'Integrin Receptor Antagonist',
    'Gastroenterology'
  );

  PERFORM insert_medication_pair(
    'Ustekinumab',
    ARRAY['Stelara'],
    'Gastrointestinal',
    'IL-12/IL-23 Inhibitor',
    'Gastroenterology'
  );

  PERFORM insert_medication_pair(
    'Budesonide',
    ARRAY['Entocort EC', 'Uceris'],
    'Gastrointestinal',
    'Corticosteroid',
    'Gastroenterology'
  );

  PERFORM insert_medication_pair(
    'Sulfasalazine',
    ARRAY['Azulfidine'],
    'Gastrointestinal',
    'Aminosalicylate',
    'Gastroenterology'
  );

  PERFORM insert_medication_pair(
    'Balsalazide',
    ARRAY['Colazal', 'Giazo'],
    'Gastrointestinal',
    'Aminosalicylate',
    'Gastroenterology'
  );
END $$;

-- Antiemetics and Motility Agents
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Ondansetron',
    ARRAY['Zofran', 'Zuplenz'],
    'Gastrointestinal',
    'Antiemetic',
    'Gastroenterology'
  );

  PERFORM insert_medication_pair(
    'Metoclopramide',
    ARRAY['Reglan', 'Metozolv ODT'],
    'Gastrointestinal',
    'Prokinetic',
    'Gastroenterology'
  );

  PERFORM insert_medication_pair(
    'Prucalopride',
    ARRAY['Motegrity'],
    'Gastrointestinal',
    'Prokinetic',
    'Gastroenterology'
  );

  PERFORM insert_medication_pair(
    'Dicyclomine',
    ARRAY['Bentyl'],
    'Gastrointestinal',
    'Antispasmodic',
    'Gastroenterology'
  );

  PERFORM insert_medication_pair(
    'Hyoscyamine',
    ARRAY['Levsin', 'Levbid'],
    'Gastrointestinal',
    'Antispasmodic',
    'Gastroenterology'
  );
END $$;

-- Laxatives and Constipation Treatments
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Linaclotide',
    ARRAY['Linzess'],
    'Gastrointestinal',
    'Guanylate Cyclase-C Agonist',
    'Gastroenterology'
  );

  PERFORM insert_medication_pair(
    'Plecanatide',
    ARRAY['Trulance'],
    'Gastrointestinal',
    'Guanylate Cyclase-C Agonist',
    'Gastroenterology'
  );

  PERFORM insert_medication_pair(
    'Lubiprostone',
    ARRAY['Amitiza'],
    'Gastrointestinal',
    'Chloride Channel Activator',
    'Gastroenterology'
  );

  PERFORM insert_medication_pair(
    'Polyethylene Glycol',
    ARRAY['MiraLAX', 'GlycoLax'],
    'Gastrointestinal',
    'Osmotic Laxative',
    'Gastroenterology'
  );

  PERFORM insert_medication_pair(
    'Lactulose',
    ARRAY['Enulose', 'Kristalose'],
    'Gastrointestinal',
    'Osmotic Laxative',
    'Gastroenterology'
  );
END $$;

-- Antidiarrheals
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Loperamide',
    ARRAY['Imodium', 'Imodium A-D'],
    'Gastrointestinal',
    'Antidiarrheal',
    'Gastroenterology'
  );

  PERFORM insert_medication_pair(
    'Diphenoxylate/Atropine',
    ARRAY['Lomotil'],
    'Gastrointestinal',
    'Antidiarrheal',
    'Gastroenterology'
  );

  PERFORM insert_medication_pair(
    'Bismuth Subsalicylate',
    ARRAY['Pepto-Bismol', 'Kaopectate'],
    'Gastrointestinal',
    'Antidiarrheal',
    'Gastroenterology'
  );
END $$;

--------------------------------------------------------------
-- 3. INFECTIOUS DISEASE MEDICATIONS
--------------------------------------------------------------

-- Antibiotics - Penicillins
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Amoxicillin',
    ARRAY['Amoxil', 'Trimox'],
    'Antibiotic',
    'Penicillin',
    'Infectious Disease'
  );

  PERFORM insert_medication_pair(
    'Amoxicillin/Clavulanate',
    ARRAY['Augmentin', 'Augmentin XR'],
    'Antibiotic',
    'Penicillin',
    'Infectious Disease'
  );

  PERFORM insert_medication_pair(
    'Piperacillin/Tazobactam',
    ARRAY['Zosyn'],
    'Antibiotic',
    'Penicillin',
    'Infectious Disease'
  );
END $$;

-- Antibiotics - Cephalosporins
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Cephalexin',
    ARRAY['Keflex'],
    'Antibiotic',
    'Cephalosporin',
    'Infectious Disease'
  );

  PERFORM insert_medication_pair(
    'Cefuroxime',
    ARRAY['Ceftin', 'Zinacef'],
    'Antibiotic',
    'Cephalosporin',
    'Infectious Disease'
  );

  PERFORM insert_medication_pair(
    'Ceftriaxone',
    ARRAY['Rocephin'],
    'Antibiotic',
    'Cephalosporin',
    'Infectious Disease'
  );

  PERFORM insert_medication_pair(
    'Cefdinir',
    ARRAY['Omnicef'],
    'Antibiotic',
    'Cephalosporin',
    'Infectious Disease'
  );

  PERFORM insert_medication_pair(
    'Cefepime',
    ARRAY['Maxipime'],
    'Antibiotic',
    'Cephalosporin',
    'Infectious Disease'
  );
END $$;

-- Antibiotics - Fluoroquinolones
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Ciprofloxacin',
    ARRAY['Cipro', 'Cipro XR'],
    'Antibiotic',
    'Fluoroquinolone',
    'Infectious Disease'
  );

  PERFORM insert_medication_pair(
    'Levofloxacin',
    ARRAY['Levaquin'],
    'Antibiotic',
    'Fluoroquinolone',
    'Infectious Disease'
  );

  PERFORM insert_medication_pair(
    'Moxifloxacin',
    ARRAY['Avelox'],
    'Antibiotic',
    'Fluoroquinolone',
    'Infectious Disease'
  );
END $$;

-- Antibiotics - Macrolides
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Azithromycin',
    ARRAY['Zithromax', 'Z-Pak'],
    'Antibiotic',
    'Macrolide',
    'Infectious Disease'
  );

  PERFORM insert_medication_pair(
    'Clarithromycin',
    ARRAY['Biaxin', 'Biaxin XL'],
    'Antibiotic',
    'Macrolide',
    'Infectious Disease'
  );

  PERFORM insert_medication_pair(
    'Erythromycin',
    ARRAY['Ery-Tab', 'Erythrocin'],
    'Antibiotic',
    'Macrolide',
    'Infectious Disease'
  );
END $$;

-- Antibiotics - Other
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Doxycycline',
    ARRAY['Vibramycin', 'Oracea', 'Doryx'],
    'Antibiotic',
    'Tetracycline',
    'Infectious Disease'
  );

  PERFORM insert_medication_pair(
    'Minocycline',
    ARRAY['Minocin', 'Solodyn'],
    'Antibiotic',
    'Tetracycline',
    'Infectious Disease'
  );

  PERFORM insert_medication_pair(
    'Trimethoprim/Sulfamethoxazole',
    ARRAY['Bactrim', 'Septra'],
    'Antibiotic',
    'Sulfonamide',
    'Infectious Disease'
  );

  PERFORM insert_medication_pair(
    'Clindamycin',
    ARRAY['Cleocin'],
    'Antibiotic',
    'Lincosamide',
    'Infectious Disease'
  );

  PERFORM insert_medication_pair(
    'Linezolid',
    ARRAY['Zyvox'],
    'Antibiotic',
    'Oxazolidinone',
    'Infectious Disease'
  );

  PERFORM insert_medication_pair(
    'Metronidazole',
    ARRAY['Flagyl', 'Flagyl ER'],
    'Antibiotic',
    'Nitroimidazole',
    'Infectious Disease'
  );

  PERFORM insert_medication_pair(
    'Nitrofurantoin',
    ARRAY['Macrobid', 'Macrodantin'],
    'Antibiotic',
    'Nitrofuran',
    'Infectious Disease'
  );
END $$;

-- Antiviral Medications
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Acyclovir',
    ARRAY['Zovirax'],
    'Antiviral',
    'Herpes Treatment',
    'Infectious Disease'
  );

  PERFORM insert_medication_pair(
    'Valacyclovir',
    ARRAY['Valtrex'],
    'Antiviral',
    'Herpes Treatment',
    'Infectious Disease'
  );

  PERFORM insert_medication_pair(
    'Famciclovir',
    ARRAY['Famvir'],
    'Antiviral',
    'Herpes Treatment',
    'Infectious Disease'
  );

  PERFORM insert_medication_pair(
    'Oseltamivir',
    ARRAY['Tamiflu'],
    'Antiviral',
    'Influenza Treatment',
    'Infectious Disease'
  );

  PERFORM insert_medication_pair(
    'Baloxavir',
    ARRAY['Xofluza'],
    'Antiviral',
    'Influenza Treatment',
    'Infectious Disease'
  );

  PERFORM insert_medication_pair(
    'Tenofovir Disoproxil',
    ARRAY['Viread'],
    'Antiviral',
    'HIV/HBV Treatment',
    'Infectious Disease'
  );

  PERFORM insert_medication_pair(
    'Tenofovir Alafenamide',
    ARRAY['Vemlidy'],
    'Antiviral',
    'HIV/HBV Treatment',
    'Infectious Disease'
  );
END $$;

-- Antifungal Medications
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Fluconazole',
    ARRAY['Diflucan'],
    'Antifungal',
    'Azole',
    'Infectious Disease'
  );

  PERFORM insert_medication_pair(
    'Itraconazole',
    ARRAY['Sporanox', 'Onmel'],
    'Antifungal',
    'Azole',
    'Infectious Disease'
  );

  PERFORM insert_medication_pair(
    'Voriconazole',
    ARRAY['Vfend'],
    'Antifungal',
    'Azole',
    'Infectious Disease'
  );

  PERFORM insert_medication_pair(
    'Posaconazole',
    ARRAY['Noxafil'],
    'Antifungal',
    'Azole',
    'Infectious Disease'
  );

  PERFORM insert_medication_pair(
    'Terbinafine',
    ARRAY['Lamisil'],
    'Antifungal',
    'Allylamine',
    'Infectious Disease'
  );
END $$;

--------------------------------------------------------------
-- 4. NEPHROLOGY MEDICATIONS
--------------------------------------------------------------

-- Diuretics
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Metolazone',
    ARRAY['Zaroxolyn'],
    'Nephrology',
    'Thiazide-like Diuretic',
    'Nephrology'
  );

  PERFORM insert_medication_pair(
    'Ethacrynic Acid',
    ARRAY['Edecrin'],
    'Nephrology',
    'Loop Diuretic',
    'Nephrology'
  );

  PERFORM insert_medication_pair(
    'Amiloride',
    ARRAY['Midamor'],
    'Nephrology',
    'Potassium-Sparing Diuretic',
    'Nephrology'
  );
END $$;

-- Electrolyte Supplements
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Potassium Chloride',
    ARRAY['K-Dur', 'Klor-Con', 'K-Tab'],
    'Nephrology',
    'Electrolyte Supplement',
    'Nephrology'
  );

  PERFORM insert_medication_pair(
    'Sodium Polystyrene Sulfonate',
    ARRAY['Kayexalate', 'SPS'],
    'Nephrology',
    'Potassium Binder',
    'Nephrology'
  );

  PERFORM insert_medication_pair(
    'Patiromer',
    ARRAY['Veltassa'],
    'Nephrology',
    'Potassium Binder',
    'Nephrology'
  );

  PERFORM insert_medication_pair(
    'Sodium Zirconium Cyclosilicate',
    ARRAY['Lokelma'],
    'Nephrology',
    'Potassium Binder',
    'Nephrology'
  );
END $$;

-- Phosphate Binders
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Sevelamer',
    ARRAY['Renvela', 'Renagel'],
    'Nephrology',
    'Phosphate Binder',
    'Nephrology'
  );

  PERFORM insert_medication_pair(
    'Lanthanum Carbonate',
    ARRAY['Fosrenol'],
    'Nephrology',
    'Phosphate Binder',
    'Nephrology'
  );

  PERFORM insert_medication_pair(
    'Calcium Acetate',
    ARRAY['PhosLo', 'Eliphos'],
    'Nephrology',
    'Phosphate Binder',
    'Nephrology'
  );

  PERFORM insert_medication_pair(
    'Ferric Citrate',
    ARRAY['Auryxia'],
    'Nephrology',
    'Phosphate Binder',
    'Nephrology'
  );
END $$;

-- Renal Anemia Treatments
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Epoetin Alfa',
    ARRAY['Epogen', 'Procrit'],
    'Nephrology',
    'Erythropoiesis-Stimulating Agent',
    'Nephrology'
  );

  PERFORM insert_medication_pair(
    'Darbepoetin Alfa',
    ARRAY['Aranesp'],
    'Nephrology',
    'Erythropoiesis-Stimulating Agent',
    'Nephrology'
  );

  PERFORM insert_medication_pair(
    'Methoxy Polyethylene Glycol-Epoetin Beta',
    ARRAY['Mircera'],
    'Nephrology',
    'Erythropoiesis-Stimulating Agent',
    'Nephrology'
  );

  PERFORM insert_medication_pair(
    'Iron Sucrose',
    ARRAY['Venofer'],
    'Nephrology',
    'Iron Supplement',
    'Nephrology'
  );

  PERFORM insert_medication_pair(
    'Ferric Gluconate',
    ARRAY['Ferrlecit'],
    'Nephrology',
    'Iron Supplement',
    'Nephrology'
  );

  PERFORM insert_medication_pair(
    'Ferumoxytol',
    ARRAY['Feraheme'],
    'Nephrology',
    'Iron Supplement',
    'Nephrology'
  );
END $$;

-- Other Nephrology Medications
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Cinacalcet',
    ARRAY['Sensipar'],
    'Nephrology',
    'Calcimimetic',
    'Nephrology'
  );

  PERFORM insert_medication_pair(
    'Etelcalcetide',
    ARRAY['Parsabiv'],
    'Nephrology',
    'Calcimimetic',
    'Nephrology'
  );

  PERFORM insert_medication_pair(
    'Tolvaptan',
    ARRAY['Samsca', 'Jynarque'],
    'Nephrology',
    'Vasopressin Antagonist',
    'Nephrology'
  );

  PERFORM insert_medication_pair(
    'Paricalcitol',
    ARRAY['Zemplar'],
    'Nephrology',
    'Vitamin D Analog',
    'Nephrology'
  );

  PERFORM insert_medication_pair(
    'Calcitriol',
    ARRAY['Rocaltrol'],
    'Nephrology',
    'Vitamin D Analog',
    'Nephrology'
  );
END $$;

--------------------------------------------------------------
-- 5. ONCOLOGY MEDICATIONS
--------------------------------------------------------------

-- Oral Chemotherapy Agents
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Capecitabine',
    ARRAY['Xeloda'],
    'Oncology',
    'Antimetabolite',
    'Oncology'
  );

  PERFORM insert_medication_pair(
    'Lenalidomide',
    ARRAY['Revlimid'],
    'Oncology',
    'Immunomodulator',
    'Oncology'
  );

  PERFORM insert_medication_pair(
    'Pomalidomide',
    ARRAY['Pomalyst'],
    'Oncology',
    'Immunomodulator',
    'Oncology'
  );

  PERFORM insert_medication_pair(
    'Ibrutinib',
    ARRAY['Imbruvica'],
    'Oncology',
    'Kinase Inhibitor',
    'Oncology'
  );

  PERFORM insert_medication_pair(
    'Acalabrutinib',
    ARRAY['Calquence'],
    'Oncology',
    'Kinase Inhibitor',
    'Oncology'
  );
END $$;

-- Tyrosine Kinase Inhibitors (TKIs)
DO $$
BEGIN
  PERFORM insert_medication_pair(
    '
