-- Migration: Comprehensive Medication Dataset (Part 2)
-- Continuation of medication dataset adding more categories and completing the transaction

BEGIN;

-- First make sure the function exists from part 1
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'insert_medication_pair'
  ) THEN
    -- Create the function if it doesn't exist (which it should from part 1)
    CREATE OR REPLACE FUNCTION insert_medication_pair(
      generic_name TEXT,
      brand_names TEXT[],
      category TEXT,
      subcategory TEXT,
      specialty TEXT DEFAULT NULL,
      is_target BOOLEAN DEFAULT FALSE
    ) RETURNS VOID AS $func$
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
    $func$ LANGUAGE plpgsql;
  END IF;
END $$;

-- Continuing from Part 1 with more DPP-4 Inhibitors
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Alogliptin',
    ARRAY['Nesina'],
    'Diabetes',
    'DPP-4 Inhibitor',
    'Endocrinology'
  );

  -- GLP-1 Receptor Agonists
  PERFORM insert_medication_pair(
    'Semaglutide',
    ARRAY['Ozempic', 'Wegovy', 'Rybelsus'],
    'Diabetes',
    'GLP-1 Receptor Agonist',
    'Endocrinology'
  );

  PERFORM insert_medication_pair(
    'Dulaglutide',
    ARRAY['Trulicity'],
    'Diabetes',
    'GLP-1 Receptor Agonist',
    'Endocrinology'
  );

  PERFORM insert_medication_pair(
    'Liraglutide',
    ARRAY['Victoza', 'Saxenda'],
    'Diabetes',
    'GLP-1 Receptor Agonist',
    'Endocrinology'
  );

  PERFORM insert_medication_pair(
    'Exenatide',
    ARRAY['Byetta', 'Bydureon'],
    'Diabetes',
    'GLP-1 Receptor Agonist',
    'Endocrinology'
  );

  PERFORM insert_medication_pair(
    'Lixisenatide',
    ARRAY['Adlyxin'],
    'Diabetes',
    'GLP-1 Receptor Agonist',
    'Endocrinology'
  );

  PERFORM insert_medication_pair(
    'Tirzepatide',
    ARRAY['Mounjaro', 'Zepbound'],
    'Diabetes',
    'GLP-1/GIP Dual Agonist',
    'Endocrinology'
  );
END $$;

-- SGLT-2 Inhibitors
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Empagliflozin',
    ARRAY['Jardiance'],
    'Diabetes',
    'SGLT-2 Inhibitor',
    'Endocrinology'
  );

  PERFORM insert_medication_pair(
    'Dapagliflozin',
    ARRAY['Farxiga', 'Xigduo XR'],
    'Diabetes',
    'SGLT-2 Inhibitor',
    'Endocrinology'
  );

  PERFORM insert_medication_pair(
    'Canagliflozin',
    ARRAY['Invokana', 'Invokamet'],
    'Diabetes',
    'SGLT-2 Inhibitor',
    'Endocrinology'
  );

  PERFORM insert_medication_pair(
    'Ertugliflozin',
    ARRAY['Steglatro', 'Segluromet'],
    'Diabetes',
    'SGLT-2 Inhibitor',
    'Endocrinology'
  );
END $$;

-- Insulins
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Insulin Glargine',
    ARRAY['Lantus', 'Toujeo', 'Basaglar'],
    'Diabetes',
    'Long-Acting Insulin',
    'Endocrinology'
  );

  PERFORM insert_medication_pair(
    'Insulin Detemir',
    ARRAY['Levemir'],
    'Diabetes',
    'Long-Acting Insulin',
    'Endocrinology'
  );

  PERFORM insert_medication_pair(
    'Insulin Degludec',
    ARRAY['Tresiba'],
    'Diabetes',
    'Ultra-Long-Acting Insulin',
    'Endocrinology'
  );

  PERFORM insert_medication_pair(
    'Insulin Aspart',
    ARRAY['NovoLog', 'Fiasp'],
    'Diabetes',
    'Rapid-Acting Insulin',
    'Endocrinology'
  );

  PERFORM insert_medication_pair(
    'Insulin Lispro',
    ARRAY['Humalog', 'Admelog'],
    'Diabetes',
    'Rapid-Acting Insulin',
    'Endocrinology'
  );

  PERFORM insert_medication_pair(
    'Insulin Glulisine',
    ARRAY['Apidra'],
    'Diabetes',
    'Rapid-Acting Insulin',
    'Endocrinology'
  );

  PERFORM insert_medication_pair(
    'NPH Insulin',
    ARRAY['Humulin N', 'Novolin N'],
    'Diabetes',
    'Intermediate-Acting Insulin',
    'Endocrinology'
  );

  PERFORM insert_medication_pair(
    'Regular Insulin',
    ARRAY['Humulin R', 'Novolin R'],
    'Diabetes',
    'Short-Acting Insulin',
    'Endocrinology'
  );
END $$;

-- 4. RESPIRATORY MEDICATIONS
--------------------------------------------------------------

-- Short-acting Beta Agonists
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Albuterol',
    ARRAY['ProAir HFA', 'Ventolin HFA', 'Proventil HFA'],
    'Respiratory',
    'Short-Acting Beta Agonist',
    'Pulmonology'
  );

  PERFORM insert_medication_pair(
    'Levalbuterol',
    ARRAY['Xopenex', 'Xopenex HFA'],
    'Respiratory',
    'Short-Acting Beta Agonist',
    'Pulmonology'
  );

  -- Long-acting Beta Agonists
  PERFORM insert_medication_pair(
    'Salmeterol',
    ARRAY['Serevent'],
    'Respiratory',
    'Long-Acting Beta Agonist',
    'Pulmonology'
  );

  PERFORM insert_medication_pair(
    'Formoterol',
    ARRAY['Foradil', 'Perforomist'],
    'Respiratory',
    'Long-Acting Beta Agonist',
    'Pulmonology'
  );

  PERFORM insert_medication_pair(
    'Olodaterol',
    ARRAY['Striverdi Respimat'],
    'Respiratory',
    'Long-Acting Beta Agonist',
    'Pulmonology'
  );
END $$;

-- Inhaled Corticosteroids
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Fluticasone',
    ARRAY['Flovent', 'Arnuity Ellipta'],
    'Respiratory',
    'Inhaled Corticosteroid',
    'Pulmonology'
  );

  PERFORM insert_medication_pair(
    'Budesonide',
    ARRAY['Pulmicort'],
    'Respiratory',
    'Inhaled Corticosteroid',
    'Pulmonology'
  );

  PERFORM insert_medication_pair(
    'Mometasone',
    ARRAY['Asmanex'],
    'Respiratory',
    'Inhaled Corticosteroid',
    'Pulmonology'
  );

  PERFORM insert_medication_pair(
    'Beclomethasone',
    ARRAY['QVAR'],
    'Respiratory',
    'Inhaled Corticosteroid',
    'Pulmonology'
  );

  PERFORM insert_medication_pair(
    'Ciclesonide',
    ARRAY['Alvesco'],
    'Respiratory',
    'Inhaled Corticosteroid',
    'Pulmonology'
  );
END $$;

-- Anticholinergics
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Tiotropium',
    ARRAY['Spiriva'],
    'Respiratory',
    'Long-Acting Anticholinergic',
    'Pulmonology'
  );

  PERFORM insert_medication_pair(
    'Umeclidinium',
    ARRAY['Incruse Ellipta'],
    'Respiratory',
    'Long-Acting Anticholinergic',
    'Pulmonology'
  );

  PERFORM insert_medication_pair(
    'Aclidinium',
    ARRAY['Tudorza Pressair'],
    'Respiratory',
    'Long-Acting Anticholinergic',
    'Pulmonology'
  );

  PERFORM insert_medication_pair(
    'Ipratropium',
    ARRAY['Atrovent HFA'],
    'Respiratory',
    'Short-Acting Anticholinergic',
    'Pulmonology'
  );
END $$;

-- Combination Inhalers
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Fluticasone/Salmeterol',
    ARRAY['Advair', 'Wixela Inhub', 'AirDuo'],
    'Respiratory',
    'ICS/LABA Combination',
    'Pulmonology'
  );

  PERFORM insert_medication_pair(
    'Budesonide/Formoterol',
    ARRAY['Symbicort'],
    'Respiratory',
    'ICS/LABA Combination',
    'Pulmonology'
  );

  PERFORM insert_medication_pair(
    'Mometasone/Formoterol',
    ARRAY['Dulera'],
    'Respiratory',
    'ICS/LABA Combination',
    'Pulmonology'
  );

  PERFORM insert_medication_pair(
    'Fluticasone/Vilanterol',
    ARRAY['Breo Ellipta'],
    'Respiratory',
    'ICS/LABA Combination',
    'Pulmonology'
  );

  PERFORM insert_medication_pair(
    'Fluticasone/Umeclidinium/Vilanterol',
    ARRAY['Trelegy Ellipta'],
    'Respiratory',
    'Triple Combination Inhaler',
    'Pulmonology'
  );

  PERFORM insert_medication_pair(
    'Tiotropium/Olodaterol',
    ARRAY['Stiolto Respimat'],
    'Respiratory',
    'LAMA/LABA Combination',
    'Pulmonology'
  );

  PERFORM insert_medication_pair(
    'Umeclidinium/Vilanterol',
    ARRAY['Anoro Ellipta'],
    'Respiratory',
    'LAMA/LABA Combination',
    'Pulmonology'
  );
END $$;

-- Leukotriene Modifiers
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Montelukast',
    ARRAY['Singulair'],
    'Respiratory',
    'Leukotriene Receptor Antagonist',
    'Pulmonology'
  );

  PERFORM insert_medication_pair(
    'Zafirlukast',
    ARRAY['Accolate'],
    'Respiratory',
    'Leukotriene Receptor Antagonist',
    'Pulmonology'
  );

  PERFORM insert_medication_pair(
    'Zileuton',
    ARRAY['Zyflo'],
    'Respiratory',
    '5-Lipoxygenase Inhibitor',
    'Pulmonology'
  );
END $$;

-- 5. NEUROLOGICAL MEDICATIONS
--------------------------------------------------------------

-- Anti-epileptics
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Levetiracetam',
    ARRAY['Keppra', 'Keppra XR', 'Spritam'],
    'Neurology',
    'Anticonvulsant',
    'Neurology'
  );

  PERFORM insert_medication_pair(
    'Topiramate',
    ARRAY['Topamax', 'Trokendi XR', 'Qudexy XR'],
    'Neurology',
    'Anticonvulsant',
    'Neurology'
  );

  PERFORM insert_medication_pair(
    'Gabapentin',
    ARRAY['Neurontin', 'Gralise', 'Horizant'],
    'Neurology',
    'Anticonvulsant',
    'Neurology'
  );

  PERFORM insert_medication_pair(
    'Pregabalin',
    ARRAY['Lyrica', 'Lyrica CR'],
    'Neurology',
    'Anticonvulsant',
    'Neurology'
  );

  PERFORM insert_medication_pair(
    'Phenytoin',
    ARRAY['Dilantin', 'Phenytek'],
    'Neurology',
    'Anticonvulsant',
    'Neurology'
  );

  PERFORM insert_medication_pair(
    'Lacosamide',
    ARRAY['Vimpat'],
    'Neurology',
    'Anticonvulsant',
    'Neurology'
  );

  PERFORM insert_medication_pair(
    'Divalproex Sodium',
    ARRAY['Depakote', 'Depakote ER'],
    'Neurology',
    'Anticonvulsant',
    'Neurology'
  );
END $$;

-- Migraine Medications
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Sumatriptan',
    ARRAY['Imitrex', 'Onzetra Xsail', 'Zembrace SymTouch'],
    'Neurology',
    'Triptan',
    'Neurology'
  );

  PERFORM insert_medication_pair(
    'Rizatriptan',
    ARRAY['Maxalt', 'Maxalt-MLT'],
    'Neurology',
    'Triptan',
    'Neurology'
  );

  PERFORM insert_medication_pair(
    'Eletriptan',
    ARRAY['Relpax'],
    'Neurology',
    'Triptan',
    'Neurology'
  );

  PERFORM insert_medication_pair(
    'Erenumab',
    ARRAY['Aimovig'],
    'Neurology',
    'CGRP Receptor Antagonist',
    'Neurology'
  );

  PERFORM insert_medication_pair(
    'Galcanezumab',
    ARRAY['Emgality'],
    'Neurology',
    'CGRP Receptor Antagonist',
    'Neurology'
  );

  PERFORM insert_medication_pair(
    'Fremanezumab',
    ARRAY['Ajovy'],
    'Neurology',
    'CGRP Receptor Antagonist',
    'Neurology'
  );
END $$;

-- Parkinson's Disease Medications
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Levodopa/Carbidopa',
    ARRAY['Sinemet', 'Rytary', 'Duopa'],
    'Neurology',
    'Dopamine Precursor',
    'Neurology'
  );

  PERFORM insert_medication_pair(
    'Pramipexole',
    ARRAY['Mirapex', 'Mirapex ER'],
    'Neurology',
    'Dopamine Agonist',
    'Neurology'
  );

  PERFORM insert_medication_pair(
    'Ropinirole',
    ARRAY['Requip', 'Requip XL'],
    'Neurology',
    'Dopamine Agonist',
    'Neurology'
  );

  PERFORM insert_medication_pair(
    'Rotigotine',
    ARRAY['Neupro'],
    'Neurology',
    'Dopamine Agonist',
    'Neurology'
  );

  PERFORM insert_medication_pair(
    'Rasagiline',
    ARRAY['Azilect'],
    'Neurology',
    'MAO-B Inhibitor',
    'Neurology'
  );

  PERFORM insert_medication_pair(
    'Selegiline',
    ARRAY['Eldepryl', 'Zelapar'],
    'Neurology',
    'MAO-B Inhibitor',
    'Neurology'
  );
END $$;

-- Multiple Sclerosis Medications
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Dimethyl Fumarate',
    ARRAY['Tecfidera'],
    'Neurology',
    'MS Medication',
    'Neurology'
  );

  PERFORM insert_medication_pair(
    'Fingolimod',
    ARRAY['Gilenya'],
    'Neurology',
    'MS Medication',
    'Neurology'
  );

  PERFORM insert_medication_pair(
    'Ocrelizumab',
    ARRAY['Ocrevus'],
    'Neurology',
    'MS Medication',
    'Neurology'
  );

  PERFORM insert_medication_pair(
    'Natalizumab',
    ARRAY['Tysabri'],
    'Neurology',
    'MS Medication',
    'Neurology'
  );

  PERFORM insert_medication_pair(
    'Glatiramer Acetate',
    ARRAY['Copaxone', 'Glatopa'],
    'Neurology',
    'MS Medication',
    'Neurology'
  );
END $$;

-- Clean up temporary function if necessary
-- DO $$ BEGIN DROP FUNCTION IF EXISTS insert_medication_pair; END $$;

-- Count the total number of medications added
SELECT COUNT(*) AS total_medications FROM medications WHERE is_sample_data = TRUE;

-- Count by category
SELECT category, COUNT(*) AS medication_count 
FROM medications 
WHERE is_sample_data = TRUE 
GROUP BY category 
ORDER BY medication_count DESC;

-- End the transaction
COMMIT;
