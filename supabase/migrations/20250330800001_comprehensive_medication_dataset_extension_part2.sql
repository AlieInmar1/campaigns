-- Migration: Comprehensive Medication Dataset Extension (Part 2)
-- Continues adding medications for underrepresented specialties
-- Completes the oncology section and adds more specialties

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
-- 5. ONCOLOGY MEDICATIONS (continued)
--------------------------------------------------------------

-- Tyrosine Kinase Inhibitors (TKIs)
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Imatinib',
    ARRAY['Gleevec', 'Glivec'],
    'Oncology',
    'Tyrosine Kinase Inhibitor',
    'Oncology'
  );

  PERFORM insert_medication_pair(
    'Dasatinib',
    ARRAY['Sprycel'],
    'Oncology',
    'Tyrosine Kinase Inhibitor',
    'Oncology'
  );

  PERFORM insert_medication_pair(
    'Nilotinib',
    ARRAY['Tasigna'],
    'Oncology',
    'Tyrosine Kinase Inhibitor',
    'Oncology'
  );

  PERFORM insert_medication_pair(
    'Erlotinib',
    ARRAY['Tarceva'],
    'Oncology',
    'EGFR Inhibitor',
    'Oncology'
  );

  PERFORM insert_medication_pair(
    'Gefitinib',
    ARRAY['Iressa'],
    'Oncology',
    'EGFR Inhibitor',
    'Oncology'
  );

  PERFORM insert_medication_pair(
    'Osimertinib',
    ARRAY['Tagrisso'],
    'Oncology',
    'EGFR Inhibitor',
    'Oncology'
  );

  PERFORM insert_medication_pair(
    'Sunitinib',
    ARRAY['Sutent'],
    'Oncology',
    'Multi-Kinase Inhibitor',
    'Oncology'
  );

  PERFORM insert_medication_pair(
    'Sorafenib',
    ARRAY['Nexavar'],
    'Oncology',
    'Multi-Kinase Inhibitor',
    'Oncology'
  );
END $$;

-- Hormone Therapy
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Tamoxifen',
    ARRAY['Nolvadex', 'Soltamox'],
    'Oncology',
    'Estrogen Receptor Modulator',
    'Oncology'
  );

  PERFORM insert_medication_pair(
    'Letrozole',
    ARRAY['Femara'],
    'Oncology',
    'Aromatase Inhibitor',
    'Oncology'
  );

  PERFORM insert_medication_pair(
    'Anastrozole',
    ARRAY['Arimidex'],
    'Oncology',
    'Aromatase Inhibitor',
    'Oncology'
  );

  PERFORM insert_medication_pair(
    'Exemestane',
    ARRAY['Aromasin'],
    'Oncology',
    'Aromatase Inhibitor',
    'Oncology'
  );

  PERFORM insert_medication_pair(
    'Fulvestrant',
    ARRAY['Faslodex'],
    'Oncology',
    'Estrogen Receptor Antagonist',
    'Oncology'
  );

  PERFORM insert_medication_pair(
    'Bicalutamide',
    ARRAY['Casodex'],
    'Oncology',
    'Androgen Receptor Antagonist',
    'Oncology'
  );

  PERFORM insert_medication_pair(
    'Enzalutamide',
    ARRAY['Xtandi'],
    'Oncology',
    'Androgen Receptor Antagonist',
    'Oncology'
  );

  PERFORM insert_medication_pair(
    'Abiraterone',
    ARRAY['Zytiga'],
    'Oncology',
    'Androgen Synthesis Inhibitor',
    'Oncology'
  );
END $$;

-- Other Targeted Therapies
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Venetoclax',
    ARRAY['Venclexta'],
    'Oncology',
    'BCL-2 Inhibitor',
    'Oncology'
  );

  PERFORM insert_medication_pair(
    'Olaparib',
    ARRAY['Lynparza'],
    'Oncology',
    'PARP Inhibitor',
    'Oncology'
  );

  PERFORM insert_medication_pair(
    'Rucaparib',
    ARRAY['Rubraca'],
    'Oncology',
    'PARP Inhibitor',
    'Oncology'
  );

  PERFORM insert_medication_pair(
    'Niraparib',
    ARRAY['Zejula'],
    'Oncology',
    'PARP Inhibitor',
    'Oncology'
  );

  PERFORM insert_medication_pair(
    'Everolimus',
    ARRAY['Afinitor'],
    'Oncology',
    'mTOR Inhibitor',
    'Oncology'
  );

  PERFORM insert_medication_pair(
    'Palbociclib',
    ARRAY['Ibrance'],
    'Oncology',
    'CDK4/6 Inhibitor',
    'Oncology'
  );

  PERFORM insert_medication_pair(
    'Ribociclib',
    ARRAY['Kisqali'],
    'Oncology',
    'CDK4/6 Inhibitor',
    'Oncology'
  );

  PERFORM insert_medication_pair(
    'Abemaciclib',
    ARRAY['Verzenio'],
    'Oncology',
    'CDK4/6 Inhibitor',
    'Oncology'
  );
END $$;

--------------------------------------------------------------
-- 6. RHEUMATOLOGY MEDICATIONS
--------------------------------------------------------------

-- Disease-Modifying Antirheumatic Drugs (DMARDs)
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Hydroxychloroquine',
    ARRAY['Plaquenil'],
    'Rheumatology',
    'DMARD',
    'Rheumatology'
  );

  PERFORM insert_medication_pair(
    'Sulfasalazine',
    ARRAY['Azulfidine'],
    'Rheumatology',
    'DMARD',
    'Rheumatology'
  );

  PERFORM insert_medication_pair(
    'Leflunomide',
    ARRAY['Arava'],
    'Rheumatology',
    'DMARD',
    'Rheumatology'
  );

  PERFORM insert_medication_pair(
    'Methotrexate',
    ARRAY['Rheumatrex', 'Trexall'],
    'Rheumatology',
    'DMARD',
    'Rheumatology'
  );

  PERFORM insert_medication_pair(
    'Azathioprine',
    ARRAY['Imuran', 'Azasan'],
    'Rheumatology',
    'DMARD',
    'Rheumatology'
  );

  PERFORM insert_medication_pair(
    'Cyclosporine',
    ARRAY['Neoral', 'Gengraf'],
    'Rheumatology',
    'DMARD',
    'Rheumatology'
  );
END $$;

-- Biologic DMARDs
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Etanercept',
    ARRAY['Enbrel', 'Erelzi'],
    'Rheumatology',
    'TNF Inhibitor',
    'Rheumatology'
  );

  PERFORM insert_medication_pair(
    'Adalimumab',
    ARRAY['Humira', 'Amjevita', 'Cyltezo'],
    'Rheumatology',
    'TNF Inhibitor',
    'Rheumatology'
  );

  PERFORM insert_medication_pair(
    'Infliximab',
    ARRAY['Remicade', 'Inflectra', 'Renflexis'],
    'Rheumatology',
    'TNF Inhibitor',
    'Rheumatology'
  );

  PERFORM insert_medication_pair(
    'Certolizumab',
    ARRAY['Cimzia'],
    'Rheumatology',
    'TNF Inhibitor',
    'Rheumatology'
  );

  PERFORM insert_medication_pair(
    'Golimumab',
    ARRAY['Simponi', 'Simponi Aria'],
    'Rheumatology',
    'TNF Inhibitor',
    'Rheumatology'
  );

  PERFORM insert_medication_pair(
    'Abatacept',
    ARRAY['Orencia'],
    'Rheumatology',
    'T-Cell Costimulation Modulator',
    'Rheumatology'
  );

  PERFORM insert_medication_pair(
    'Rituximab',
    ARRAY['Rituxan', 'Truxima', 'Ruxience'],
    'Rheumatology',
    'CD20 Inhibitor',
    'Rheumatology'
  );

  PERFORM insert_medication_pair(
    'Tocilizumab',
    ARRAY['Actemra'],
    'Rheumatology',
    'IL-6 Inhibitor',
    'Rheumatology'
  );

  PERFORM insert_medication_pair(
    'Sarilumab',
    ARRAY['Kevzara'],
    'Rheumatology',
    'IL-6 Inhibitor',
    'Rheumatology'
  );

  PERFORM insert_medication_pair(
    'Anakinra',
    ARRAY['Kineret'],
    'Rheumatology',
    'IL-1 Inhibitor',
    'Rheumatology'
  );

  PERFORM insert_medication_pair(
    'Secukinumab',
    ARRAY['Cosentyx'],
    'Rheumatology',
    'IL-17 Inhibitor',
    'Rheumatology'
  );

  PERFORM insert_medication_pair(
    'Ixekizumab',
    ARRAY['Taltz'],
    'Rheumatology',
    'IL-17 Inhibitor',
    'Rheumatology'
  );

  PERFORM insert_medication_pair(
    'Ustekinumab',
    ARRAY['Stelara'],
    'Rheumatology',
    'IL-12/IL-23 Inhibitor',
    'Rheumatology'
  );
END $$;

-- JAK Inhibitors
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Tofacitinib',
    ARRAY['Xeljanz', 'Xeljanz XR'],
    'Rheumatology',
    'JAK Inhibitor',
    'Rheumatology'
  );

  PERFORM insert_medication_pair(
    'Baricitinib',
    ARRAY['Olumiant'],
    'Rheumatology',
    'JAK Inhibitor',
    'Rheumatology'
  );

  PERFORM insert_medication_pair(
    'Upadacitinib',
    ARRAY['Rinvoq'],
    'Rheumatology',
    'JAK Inhibitor',
    'Rheumatology'
  );
END $$;

-- Gout Medications
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Allopurinol',
    ARRAY['Zyloprim', 'Aloprim'],
    'Rheumatology',
    'Xanthine Oxidase Inhibitor',
    'Rheumatology'
  );

  PERFORM insert_medication_pair(
    'Febuxostat',
    ARRAY['Uloric'],
    'Rheumatology',
    'Xanthine Oxidase Inhibitor',
    'Rheumatology'
  );

  PERFORM insert_medication_pair(
    'Colchicine',
    ARRAY['Colcrys', 'Mitigare'],
    'Rheumatology',
    'Anti-Inflammatory',
    'Rheumatology'
  );

  PERFORM insert_medication_pair(
    'Probenecid',
    ARRAY['Probalan'],
    'Rheumatology',
    'Uricosuric',
    'Rheumatology'
  );
END $$;

--------------------------------------------------------------
-- 7. UROLOGY MEDICATIONS
--------------------------------------------------------------

-- Benign Prostatic Hyperplasia (BPH) Treatments
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Tamsulosin',
    ARRAY['Flomax'],
    'Urology',
    'Alpha Blocker',
    'Urology'
  );

  PERFORM insert_medication_pair(
    'Alfuzosin',
    ARRAY['Uroxatral'],
    'Urology',
    'Alpha Blocker',
    'Urology'
  );

  PERFORM insert_medication_pair(
    'Silodosin',
    ARRAY['Rapaflo'],
    'Urology',
    'Alpha Blocker',
    'Urology'
  );

  PERFORM insert_medication_pair(
    'Doxazosin',
    ARRAY['Cardura'],
    'Urology',
    'Alpha Blocker',
    'Urology'
  );

  PERFORM insert_medication_pair(
    'Terazosin',
    ARRAY['Hytrin'],
    'Urology',
    'Alpha Blocker',
    'Urology'
  );

  PERFORM insert_medication_pair(
    'Finasteride',
    ARRAY['Proscar', 'Propecia'],
    'Urology',
    '5-Alpha-Reductase Inhibitor',
    'Urology'
  );

  PERFORM insert_medication_pair(
    'Dutasteride',
    ARRAY['Avodart'],
    'Urology',
    '5-Alpha-Reductase Inhibitor',
    'Urology'
  );

  PERFORM insert_medication_pair(
    'Tadalafil',
    ARRAY['Cialis'],
    'Urology',
    'PDE5 Inhibitor',
    'Urology'
  );
END $$;

-- Erectile Dysfunction Medications
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Sildenafil',
    ARRAY['Viagra', 'Revatio'],
    'Urology',
    'PDE5 Inhibitor',
    'Urology'
  );

  PERFORM insert_medication_pair(
    'Vardenafil',
    ARRAY['Levitra', 'Staxyn'],
    'Urology',
    'PDE5 Inhibitor',
    'Urology'
  );

  PERFORM insert_medication_pair(
    'Avanafil',
    ARRAY['Stendra'],
    'Urology',
    'PDE5 Inhibitor',
    'Urology'
  );
END $$;

-- Overactive Bladder Treatments
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Oxybutynin',
    ARRAY['Ditropan', 'Oxytrol'],
    'Urology',
    'Anticholinergic',
    'Urology'
  );

  PERFORM insert_medication_pair(
    'Tolterodine',
    ARRAY['Detrol', 'Detrol LA'],
    'Urology',
    'Anticholinergic',
    'Urology'
  );

  PERFORM insert_medication_pair(
    'Solifenacin',
    ARRAY['Vesicare'],
    'Urology',
    'Anticholinergic',
    'Urology'
  );

  PERFORM insert_medication_pair(
    'Darifenacin',
    ARRAY['Enablex'],
    'Urology',
    'Anticholinergic',
    'Urology'
  );

  PERFORM insert_medication_pair(
    'Fesoterodine',
    ARRAY['Toviaz'],
    'Urology',
    'Anticholinergic',
    'Urology'
  );

  PERFORM insert_medication_pair(
    'Trospium',
    ARRAY['Sanctura'],
    'Urology',
    'Anticholinergic',
    'Urology'
  );

  PERFORM insert_medication_pair(
    'Mirabegron',
    ARRAY['Myrbetriq'],
    'Urology',
    'Beta-3 Adrenergic Agonist',
    'Urology'
  );
END $$;

-- Urinary Tract Infection Treatments
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Phenazopyridine',
    ARRAY['Pyridium', 'AZO'],
    'Urology',
    'Urinary Analgesic',
    'Urology'
  );

  PERFORM insert_medication_pair(
    'Fosfomycin',
    ARRAY['Monurol'],
    'Urology',
    'Antibiotic',
    'Urology'
  );
END $$;

--------------------------------------------------------------
-- 8. OB/GYN MEDICATIONS
--------------------------------------------------------------

-- Hormonal Contraceptives
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Ethinyl Estradiol/Norethindrone',
    ARRAY['Junel', 'Loestrin', 'Microgestin'],
    'OB/GYN',
    'Oral Contraceptive',
    'OB/GYN'
  );

  PERFORM insert_medication_pair(
    'Ethinyl Estradiol/Levonorgestrel',
    ARRAY['Aviane', 'Seasonique', 'Alesse'],
    'OB/GYN',
    'Oral Contraceptive',
    'OB/GYN'
  );

  PERFORM insert_medication_pair(
    'Ethinyl Estradiol/Drospirenone',
    ARRAY['Yaz', 'Yasmin', 'Ocella'],
    'OB/GYN',
    'Oral Contraceptive',
    'OB/GYN'
  );

  PERFORM insert_medication_pair(
    'Ethinyl Estradiol/Desogestrel',
    ARRAY['Kariva', 'Mircette'],
    'OB/GYN',
    'Oral Contraceptive',
    'OB/GYN'
  );

  PERFORM insert_medication_pair(
    'Etonogestrel',
    ARRAY['Nexplanon'],
    'OB/GYN',
    'Implantable Contraceptive',
    'OB/GYN'
  );

  PERFORM insert_medication_pair(
    'Levonorgestrel IUD',
    ARRAY['Mirena', 'Kyleena', 'Skyla'],
    'OB/GYN',
    'Intrauterine Device',
    'OB/GYN'
  );

  PERFORM insert_medication_pair(
    'Medroxyprogesterone Acetate',
    ARRAY['Depo-Provera'],
    'OB/GYN',
    'Injectable Contraceptive',
    'OB/GYN'
  );
END $$;

-- Hormone Replacement Therapy
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Conjugated Estrogens',
    ARRAY['Premarin'],
    'OB/GYN',
    'Hormone Replacement',
    'OB/GYN'
  );

  PERFORM insert_medication_pair(
    'Estradiol',
    ARRAY['Estrace', 'Vivelle-Dot', 'Climara'],
    'OB/GYN',
    'Hormone Replacement',
    'OB/GYN'
  );

  PERFORM insert_medication_pair(
    'Estradiol/Norethindrone',
    ARRAY['Activella', 'CombiPatch'],
    'OB/GYN',
    'Hormone Replacement',
    'OB/GYN'
  );

  PERFORM insert_medication_pair(
    'Conjugated Estrogens/Medroxyprogesterone',
    ARRAY['Prempro', 'Premphase'],
    'OB/GYN',
    'Hormone Replacement',
    'OB/GYN'
  );
END $$;

-- Treatments for Gynecological Conditions
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Clomiphene',
    ARRAY['Clomid', 'Serophene'],
    'OB/GYN',
    'Fertility Treatment',
    'OB/GYN'
  );

  PERFORM insert_medication_pair(
    'Letrozole for Fertility',
    ARRAY['Femara'],
    'OB/GYN',
    'Fertility Treatment',
    'OB/GYN'
  );

  PERFORM insert_medication_pair(
    'Dienogest',
    ARRAY['Visanne'],
    'OB/GYN',
    'Endometriosis Treatment',
    'OB/GYN'
  );

  PERFORM insert_medication_pair(
    'Elagolix',
    ARRAY['Orilissa'],
    'OB/GYN',
    'Endometriosis Treatment',
    'OB/GYN'
  );

  PERFORM insert_medication_pair(
    'Ospemifene',
    ARRAY['Osphena'],
    'OB/GYN',
    'Dyspareunia Treatment',
    'OB/GYN'
  );

  PERFORM insert_medication_pair(
    'Prasterone',
    ARRAY['Intrarosa'],
    'OB/GYN',
    'Dyspareunia Treatment',
    'OB/GYN'
  );
END $$;

-- Pregnancy-Related Medications
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Prenatal Vitamins',
    ARRAY['PreNatal 19', 'Vitafol', 'CitraNatal'],
    'OB/GYN',
    'Prenatal Supplement',
    'OB/GYN'
  );

  PERFORM insert_medication_pair(
    'Hydroxyprogesterone Caproate',
    ARRAY['Makena'],
    'OB/GYN',
    'Preterm Birth Prevention',
    'OB/GYN'
  );

  PERFORM insert_medication_pair(
    'Terbutaline',
    ARRAY['Brethine'],
    'OB/GYN',
    'Tocolytic',
    'OB/GYN'
  );

  PERFORM insert_medication_pair(
    'Magnesium Sulfate',
    ARRAY['Magnesium Sulfate Injection'],
    'OB/GYN',
    'Tocolytic/Eclampsia Treatment',
    'OB/GYN'
  );

  PERFORM insert_medication_pair(
    'Methylergonovine',
    ARRAY['Methergine'],
    'OB/GYN',
    'Postpartum Hemorrhage',
    'OB/GYN'
  );
END $$;

--------------------------------------------------------------
-- 9. ORTHOPEDICS MEDICATIONS
--------------------------------------------------------------

-- Pain and Anti-inflammatory Medications
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Diclofenac',
    ARRAY['Voltaren', 'Pennsaid', 'Zipsor'],
    'Orthopedics',
    'NSAID',
    'Orthopedics'
  );

  PERFORM insert_medication_pair(
    'Meloxicam',
    ARRAY['Mobic'],
    'Orthopedics',
    'NSAID',
    'Orthopedics'
  );

  PERFORM insert_medication_pair(
    'Tramadol',
    ARRAY['Ultram', 'ConZip'],
    'Orthopedics',
    'Analgesic',
    'Orthopedics'
  );

  PERFORM insert_medication_pair(
    'Celecoxib',
    ARRAY['Celebrex'],
    'Orthopedics',
    'COX-2 Inhibitor',
    'Orthopedics'
  );
END $$;

-- Bone Medications
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Alendronate',
    ARRAY['Fosamax'],
    'Orthopedics',
    'Bisphosphonate',
    'Orthopedics'
  );

  PERFORM insert_medication_pair(
    'Risedronate',
    ARRAY['Actonel', 'Atelvia'],
    'Orthopedics',
    'Bisphosphonate',
    'Orthopedics'
  );

  PERFORM insert_medication_pair(
    'Ibandronate',
    ARRAY['Boniva'],
    'Orthopedics',
    'Bisphosphonate',
    'Orthopedics'
  );

  PERFORM insert_medication_pair(
    'Zoledronic Acid',
    ARRAY['Reclast', 'Zometa'],
    'Orthopedics',
    'Bisphosphonate',
    'Orthopedics'
  );

  PERFORM insert_medication_pair(
    'Denosumab',
    ARRAY['Prolia', 'Xgeva'],
    'Orthopedics',
    'RANK Ligand Inhibitor',
    'Orthopedics'
  );

  PERFORM insert_medication_pair(
    'Teriparatide',
    ARRAY['Forteo'],
    'Orthopedics',
    'Parathyroid Hormone Analog',
    'Orthopedics'
  );

  PERFORM insert_medication_pair(
    'Abaloparatide',
    ARRAY['Tymlos'],
    'Orthopedics',
    'Parathyroid Hormone-Related Protein Analog',
    'Orthopedics'
  );

  PERFORM insert_medication_pair(
    'Romosozumab',
    ARRAY['Evenity'],
    'Orthopedics',
    'Sclerostin Inhibitor',
    'Orthopedics'
  );
END $$;

-- Muscle Relaxants
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Cyclobenzaprine',
    ARRAY['Flexeril', 'Amrix'],
    'Orthopedics',
    'Muscle Relaxant',
    'Orthopedics'
  );

  PERFORM insert_medication_pair(
    'Methocarbamol',
    ARRAY['Robaxin'],
    'Orthopedics',
    'Muscle Relaxant',
    'Orthopedics'
  );

  PERFORM insert_medication_pair(
    'Tizanidine',
    ARRAY['Zanaflex'],
    'Orthopedics',
    'Muscle Relaxant',
    'Orthopedics'
  );

  PERFORM insert_medication_pair(
    'Baclofen',
    ARRAY['Lioresal', 'Gablofen'],
    'Orthopedics',
    'Muscle Relaxant',
    'Orthopedics'
  );

  PERFORM insert_medication_pair(
    'Carisoprodol',
    ARRAY['Soma'],
    'Orthopedics',
    'Muscle Relaxant',
    'Orthopedics'
  );
END $$;

-- Joint Injections
DO $$
BEGIN
  PERFORM insert_medication_pair(
    'Hyaluronic Acid',
    ARRAY['Synvisc', 'Orthovisc', 'Euflexxa'],
    'Orthopedics',
    'Visc
