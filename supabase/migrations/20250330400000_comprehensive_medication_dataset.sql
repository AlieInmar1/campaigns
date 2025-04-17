-- Migration: Comprehensive Medication Dataset
-- Creates a rich dataset of approximately 1000 medications with proper categorization
-- Includes both generic and brand name versions for each medication

BEGIN;

-- Delete existing sample medications to avoid duplicates
DELETE FROM medications WHERE is_sample_data = TRUE;

-- Create a temporary function to help insert medications in bulk
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

-- Add subcategory column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'medications' AND column_name = 'subcategory'
  ) THEN
    ALTER TABLE medications ADD COLUMN subcategory TEXT;
  END IF;
END $$;

-- Add specialty column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'medications' AND column_name = 'specialty'
  ) THEN
    ALTER TABLE medications ADD COLUMN specialty TEXT;
  END IF;
END $$;

-- Add generic_name column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'medications' AND column_name = 'generic_name'
  ) THEN
    ALTER TABLE medications ADD COLUMN generic_name TEXT;
  END IF;
END $$;

-- First, insert the medications from the existing sample campaigns
DO $$
BEGIN
  -- CardioGuard medications
  PERFORM insert_medication_pair(
    'Amlodipine',
    ARRAY['CardioGuard Plus', 'CardioGuard XR'],
    'Cardiovascular',
    'Calcium Channel Blocker',
    'Cardiology',
    TRUE
  );

  -- Competitor cardiovascular medications
  PERFORM insert_medication_pair(
    'Nifedipine',
    ARRAY['Cardiomax'],
    'Cardiovascular',
    'Calcium Channel Blocker',
    'Cardiology',
    FALSE
  );

  PERFORM insert_medication_pair(
    'Verapamil',
    ARRAY['HeartShield'],
    'Cardiovascular',
    'Calcium Channel Blocker',
    'Cardiology',
    FALSE
  );

  -- NeuroBalance medications
  PERFORM insert_medication_pair(
    'Escitalopram',
    ARRAY['NeuroBalance'],
    'Psychiatric',
    'SSRI',
    'Psychiatry',
    TRUE
  );

  -- Competitor neurological medications
  PERFORM insert_medication_pair(
    'Sertraline',
    ARRAY['NeuroCare'],
    'Psychiatric',
    'SSRI',
    'Psychiatry',
    FALSE
  );

  PERFORM insert_medication_pair(
    'Fluoxetine',
    ARRAY['BrainShield'],
    'Psychiatric',
    'SSRI',
    'Psychiatry',
    FALSE
  );

  -- ImmunoTherapy medications
  PERFORM insert_medication_pair(
    'Adalimumab',
    ARRAY['ImmunoTherapy 5'],
    'Immunology',
    'TNF Inhibitor',
    'Rheumatology',
    TRUE
  );

  -- Competitor immunotherapy medications
  PERFORM insert_medication_pair(
    'Etanercept',
    ARRAY['ImmunoShield'],
    'Immunology',
    'TNF Inhibitor',
    'Rheumatology',
    FALSE
  );

  PERFORM insert_medication_pair(
    'Infliximab',
    ARRAY['ImmunoMax'],
    'Immunology',
    'TNF Inhibitor',
    'Rheumatology',
    FALSE
  );
END $$;

--------------------------------------------------------------
-- Now add a comprehensive list of medications by category
--------------------------------------------------------------

-- 1. CARDIOVASCULAR MEDICATIONS
--------------------------------------------------------------
DO $$
BEGIN
  -- ACE Inhibitors
  PERFORM insert_medication_pair(
    'Lisinopril',
    ARRAY['Prinivil', 'Zestril'],
    'Cardiovascular',
    'ACE Inhibitor',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Enalapril',
    ARRAY['Vasotec'],
    'Cardiovascular',
    'ACE Inhibitor',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Ramipril',
    ARRAY['Altace'],
    'Cardiovascular',
    'ACE Inhibitor',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Benazepril',
    ARRAY['Lotensin'],
    'Cardiovascular',
    'ACE Inhibitor',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Fosinopril',
    ARRAY['Monopril'],
    'Cardiovascular',
    'ACE Inhibitor',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Captopril',
    ARRAY['Capoten'],
    'Cardiovascular',
    'ACE Inhibitor',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Perindopril',
    ARRAY['Aceon', 'Coversyl'],
    'Cardiovascular',
    'ACE Inhibitor',
    'Cardiology'
  );
END $$;

-- Angiotensin II Receptor Blockers (ARBs)
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Losartan',
    ARRAY['Cozaar'],
    'Cardiovascular',
    'ARB',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Valsartan',
    ARRAY['Diovan'],
    'Cardiovascular',
    'ARB',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Olmesartan',
    ARRAY['Benicar'],
    'Cardiovascular',
    'ARB',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Irbesartan',
    ARRAY['Avapro'],
    'Cardiovascular',
    'ARB',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Candesartan',
    ARRAY['Atacand'],
    'Cardiovascular',
    'ARB',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Telmisartan',
    ARRAY['Micardis'],
    'Cardiovascular',
    'ARB',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Azilsartan',
    ARRAY['Edarbi'],
    'Cardiovascular',
    'ARB',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Eprosartan',
    ARRAY['Teveten'],
    'Cardiovascular',
    'ARB',
    'Cardiology'
  );
END $$;

-- Beta Blockers
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Metoprolol',
    ARRAY['Lopressor', 'Toprol XL'],
    'Cardiovascular',
    'Beta Blocker',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Atenolol',
    ARRAY['Tenormin'],
    'Cardiovascular',
    'Beta Blocker',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Carvedilol',
    ARRAY['Coreg'],
    'Cardiovascular',
    'Beta Blocker',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Propranolol',
    ARRAY['Inderal', 'InnoPran XL'],
    'Cardiovascular',
    'Beta Blocker',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Bisoprolol',
    ARRAY['Zebeta'],
    'Cardiovascular',
    'Beta Blocker',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Nebivolol',
    ARRAY['Bystolic'],
    'Cardiovascular',
    'Beta Blocker',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Labetalol',
    ARRAY['Trandate', 'Normodyne'],
    'Cardiovascular',
    'Beta Blocker',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Sotalol',
    ARRAY['Betapace', 'Sorine'],
    'Cardiovascular',
    'Beta Blocker',
    'Cardiology'
  );
END $$;

-- Calcium Channel Blockers
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Diltiazem',
    ARRAY['Cardizem', 'Tiazac'],
    'Cardiovascular',
    'Calcium Channel Blocker',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Felodipine',
    ARRAY['Plendil'],
    'Cardiovascular',
    'Calcium Channel Blocker',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Nicardipine',
    ARRAY['Cardene'],
    'Cardiovascular',
    'Calcium Channel Blocker',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Nifedipine',
    ARRAY['Procardia', 'Adalat'],
    'Cardiovascular',
    'Calcium Channel Blocker',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Nimodipine',
    ARRAY['Nimotop'],
    'Cardiovascular',
    'Calcium Channel Blocker',
    'Neurology'
  );

  PERFORM insert_medication_pair(
    'Isradipine',
    ARRAY['DynaCirc'],
    'Cardiovascular',
    'Calcium Channel Blocker',
    'Cardiology'
  );
END $$;

-- Diuretics
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Hydrochlorothiazide',
    ARRAY['Microzide'],
    'Cardiovascular',
    'Thiazide Diuretic',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Chlorthalidone',
    ARRAY['Thalitone'],
    'Cardiovascular',
    'Thiazide Diuretic',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Indapamide',
    ARRAY['Lozol'],
    'Cardiovascular',
    'Thiazide Diuretic',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Furosemide',
    ARRAY['Lasix'],
    'Cardiovascular',
    'Loop Diuretic',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Bumetanide',
    ARRAY['Bumex'],
    'Cardiovascular',
    'Loop Diuretic',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Torsemide',
    ARRAY['Demadex'],
    'Cardiovascular',
    'Loop Diuretic',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Spironolactone',
    ARRAY['Aldactone'],
    'Cardiovascular',
    'Potassium-Sparing Diuretic',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Eplerenone',
    ARRAY['Inspra'],
    'Cardiovascular',
    'Potassium-Sparing Diuretic',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Triamterene',
    ARRAY['Dyrenium'],
    'Cardiovascular',
    'Potassium-Sparing Diuretic',
    'Cardiology'
  );
END $$;

-- Statins
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Atorvastatin',
    ARRAY['Lipitor'],
    'Cardiovascular',
    'Statin',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Rosuvastatin',
    ARRAY['Crestor'],
    'Cardiovascular',
    'Statin',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Simvastatin',
    ARRAY['Zocor'],
    'Cardiovascular',
    'Statin',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Pravastatin',
    ARRAY['Pravachol'],
    'Cardiovascular',
    'Statin',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Lovastatin',
    ARRAY['Mevacor', 'Altoprev'],
    'Cardiovascular',
    'Statin',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Fluvastatin',
    ARRAY['Lescol'],
    'Cardiovascular',
    'Statin',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Pitavastatin',
    ARRAY['Livalo', 'Zypitamag'],
    'Cardiovascular',
    'Statin',
    'Cardiology'
  );
END $$;

-- Other Lipid Lowering Agents
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Ezetimibe',
    ARRAY['Zetia'],
    'Cardiovascular',
    'Cholesterol Absorption Inhibitor',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Fenofibrate',
    ARRAY['Tricor', 'Antara', 'Fenoglide'],
    'Cardiovascular',
    'Fibrate',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Gemfibrozil',
    ARRAY['Lopid'],
    'Cardiovascular',
    'Fibrate',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Alirocumab',
    ARRAY['Praluent'],
    'Cardiovascular',
    'PCSK9 Inhibitor',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Evolocumab',
    ARRAY['Repatha'],
    'Cardiovascular',
    'PCSK9 Inhibitor',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Icosapent Ethyl',
    ARRAY['Vascepa'],
    'Cardiovascular',
    'Omega-3 Fatty Acid',
    'Cardiology'
  );
END $$;

-- Anticoagulants and Antiplatelets
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Warfarin',
    ARRAY['Coumadin', 'Jantoven'],
    'Cardiovascular',
    'Vitamin K Antagonist',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Apixaban',
    ARRAY['Eliquis'],
    'Cardiovascular',
    'Direct Factor Xa Inhibitor',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Rivaroxaban',
    ARRAY['Xarelto'],
    'Cardiovascular',
    'Direct Factor Xa Inhibitor',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Dabigatran',
    ARRAY['Pradaxa'],
    'Cardiovascular',
    'Direct Thrombin Inhibitor',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Edoxaban',
    ARRAY['Savaysa'],
    'Cardiovascular',
    'Direct Factor Xa Inhibitor',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Clopidogrel',
    ARRAY['Plavix'],
    'Cardiovascular',
    'P2Y12 Inhibitor',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Prasugrel',
    ARRAY['Effient'],
    'Cardiovascular',
    'P2Y12 Inhibitor',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Ticagrelor',
    ARRAY['Brilinta'],
    'Cardiovascular',
    'P2Y12 Inhibitor',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Cilostazol',
    ARRAY['Pletal'],
    'Cardiovascular',
    'Phosphodiesterase Inhibitor',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Dipyridamole',
    ARRAY['Persantine'],
    'Cardiovascular',
    'Antiplatelet',
    'Cardiology'
  );
END $$;

-- Antiarrhythmics
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Amiodarone',
    ARRAY['Pacerone', 'Cordarone'],
    'Cardiovascular',
    'Class III Antiarrhythmic',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Flecainide',
    ARRAY['Tambocor'],
    'Cardiovascular',
    'Class IC Antiarrhythmic',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Propafenone',
    ARRAY['Rythmol'],
    'Cardiovascular',
    'Class IC Antiarrhythmic',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Dronedarone',
    ARRAY['Multaq'],
    'Cardiovascular',
    'Class III Antiarrhythmic',
    'Cardiology'
  );

  PERFORM insert_medication_pair(
    'Disopyramide',
    ARRAY['Norpace'],
    'Cardiovascular',
    'Class IA Antiarrhythmic',
    'Cardiology'
  );
END $$;

-- 2. PSYCHIATRIC MEDICATIONS
--------------------------------------------------------------

-- SSRIs (Selective Serotonin Reuptake Inhibitors)
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Citalopram',
    ARRAY['Celexa'],
    'Psychiatric',
    'SSRI',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Paroxetine',
    ARRAY['Paxil', 'Pexeva'],
    'Psychiatric',
    'SSRI',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Fluvoxamine',
    ARRAY['Luvox'],
    'Psychiatric',
    'SSRI',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Vilazodone',
    ARRAY['Viibryd'],
    'Psychiatric',
    'SSRI',
    'Psychiatry'
  );
END $$;

-- SNRIs (Serotonin and Norepinephrine Reuptake Inhibitors)
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Venlafaxine',
    ARRAY['Effexor XR'],
    'Psychiatric',
    'SNRI',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Duloxetine',
    ARRAY['Cymbalta'],
    'Psychiatric',
    'SNRI',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Desvenlafaxine',
    ARRAY['Pristiq', 'Khedezla'],
    'Psychiatric',
    'SNRI',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Levomilnacipran',
    ARRAY['Fetzima'],
    'Psychiatric',
    'SNRI',
    'Psychiatry'
  );
END $$;

-- Atypical Antidepressants
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Bupropion',
    ARRAY['Wellbutrin', 'Zyban', 'Aplenzin'],
    'Psychiatric',
    'Atypical Antidepressant',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Mirtazapine',
    ARRAY['Remeron'],
    'Psychiatric',
    'Atypical Antidepressant',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Trazodone',
    ARRAY['Desyrel', 'Oleptro'],
    'Psychiatric',
    'Atypical Antidepressant',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Vortioxetine',
    ARRAY['Trintellix'],
    'Psychiatric',
    'Multimodal Antidepressant',
    'Psychiatry'
  );
END $$;

-- Antipsychotics
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Risperidone',
    ARRAY['Risperdal'],
    'Psychiatric',
    'Atypical Antipsychotic',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Quetiapine',
    ARRAY['Seroquel'],
    'Psychiatric',
    'Atypical Antipsychotic',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Olanzapine',
    ARRAY['Zyprexa'],
    'Psychiatric',
    'Atypical Antipsychotic',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Aripiprazole',
    ARRAY['Abilify', 'Aristada'],
    'Psychiatric',
    'Atypical Antipsychotic',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Ziprasidone',
    ARRAY['Geodon'],
    'Psychiatric',
    'Atypical Antipsychotic',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Lurasidone',
    ARRAY['Latuda'],
    'Psychiatric',
    'Atypical Antipsychotic',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Paliperidone',
    ARRAY['Invega', 'Invega Sustenna'],
    'Psychiatric',
    'Atypical Antipsychotic',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Cariprazine',
    ARRAY['Vraylar'],
    'Psychiatric',
    'Atypical Antipsychotic',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Brexpiprazole',
    ARRAY['Rexulti'],
    'Psychiatric',
    'Atypical Antipsychotic',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Clozapine',
    ARRAY['Clozaril', 'FazaClo'],
    'Psychiatric',
    'Atypical Antipsychotic',
    'Psychiatry'
  );
END $$;

-- Mood Stabilizers
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Lithium Carbonate',
    ARRAY['Lithobid', 'Eskalith'],
    'Psychiatric',
    'Mood Stabilizer',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Lamotrigine',
    ARRAY['Lamictal'],
    'Psychiatric',
    'Mood Stabilizer',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Valproic Acid',
    ARRAY['Depakote', 'Depakene'],
    'Psychiatric',
    'Mood Stabilizer',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Carbamazepine',
    ARRAY['Tegretol', 'Carbatrol', 'Equetro'],
    'Psychiatric',
    'Mood Stabilizer',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Oxcarbazepine',
    ARRAY['Trileptal', 'Oxtellar XR'],
    'Psychiatric',
    'Mood Stabilizer',
    'Psychiatry'
  );
END $$;

-- Anxiolytics
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Alprazolam',
    ARRAY['Xanax', 'Xanax XR'],
    'Psychiatric',
    'Benzodiazepine',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Lorazepam',
    ARRAY['Ativan'],
    'Psychiatric',
    'Benzodiazepine',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Clonazepam',
    ARRAY['Klonopin'],
    'Psychiatric',
    'Benzodiazepine',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Diazepam',
    ARRAY['Valium'],
    'Psychiatric',
    'Benzodiazepine',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Buspirone',
    ARRAY['BuSpar'],
    'Psychiatric',
    'Anxiolytic',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Hydroxyzine',
    ARRAY['Vistaril', 'Atarax'],
    'Psychiatric',
    'Anxiolytic',
    'Psychiatry'
  );
END $$;

-- ADHD Medications
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Methylphenidate',
    ARRAY['Ritalin', 'Concerta', 'Metadate', 'Daytrana'],
    'Psychiatric',
    'CNS Stimulant',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Amphetamine/Dextroamphetamine',
    ARRAY['Adderall', 'Adderall XR', 'Mydayis'],
    'Psychiatric',
    'CNS Stimulant',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Lisdexamfetamine',
    ARRAY['Vyvanse'],
    'Psychiatric',
    'CNS Stimulant',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Atomoxetine',
    ARRAY['Strattera'],
    'Psychiatric',
    'Non-Stimulant ADHD Medication',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Guanfacine',
    ARRAY['Intuniv', 'Tenex'],
    'Psychiatric',
    'Non-Stimulant ADHD Medication',
    'Psychiatry'
  );

  PERFORM insert_medication_pair(
    'Clonidine',
    ARRAY['Kapvay', 'Catapres'],
    'Psychiatric',
    'Non-Stimulant ADHD Medication',
    'Psychiatry'
  );
END $$;

-- 3. DIABETES MEDICATIONS
--------------------------------------------------------------

-- Biguanides
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Metformin',
    ARRAY['Glucophage', 'Glucophage XR', 'Fortamet', 'Glumetza', 'Riomet'],
    'Diabetes',
    'Biguanide',
    'Endocrinology'
  );
END $$;

-- Sulfonylureas
DO $$
BEGIN
  PERFORM insert
