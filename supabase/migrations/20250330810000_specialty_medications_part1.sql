-- Migration: Specialty Medications (Part 1)
-- Adds medications for Dermatology, Gastroenterology, Infectious Disease, and Nephrology
-- Uses direct inserts instead of functions for better compatibility

BEGIN;

-- First, delete any existing entries from the previous medication extensions to avoid duplicates
DELETE FROM medications 
WHERE code LIKE 'med-%' 
AND is_sample_data = TRUE 
AND (
  specialty = 'Dermatology' OR 
  specialty = 'Gastroenterology' OR 
  specialty = 'Infectious Disease' OR 
  specialty = 'Nephrology'
);

---------------------------------------
-- DERMATOLOGY MEDICATIONS
---------------------------------------

-- Acne Treatments (Generic versions)
INSERT INTO medications (
  id, code, name, category, subcategory, specialty, is_brand_name, is_target_medication, is_sample_data
) VALUES
  (gen_random_uuid(), 'med-isotretinoin-gen', 'Isotretinoin (Generic)', 'Dermatologic', 'Acne Treatment', 'Dermatology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-tretinoin-gen', 'Tretinoin (Generic)', 'Dermatologic', 'Acne Treatment', 'Dermatology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-adapalene-gen', 'Adapalene (Generic)', 'Dermatologic', 'Acne Treatment', 'Dermatology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-clindamycinbenzoylperoxide-gen', 'Clindamycin/Benzoyl Peroxide (Generic)', 'Dermatologic', 'Acne Treatment', 'Dermatology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-dapsone-gen', 'Dapsone (Generic)', 'Dermatologic', 'Acne Treatment', 'Dermatology', FALSE, FALSE, TRUE);

-- Acne Treatments (Brand versions)
INSERT INTO medications (
  id, code, name, category, subcategory, specialty, generic_name, is_brand_name, is_target_medication, is_sample_data
) VALUES
  (gen_random_uuid(), 'med-absorica-brand', 'Absorica (Brand)', 'Dermatologic', 'Acne Treatment', 'Dermatology', 'Isotretinoin', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-claravis-brand', 'Claravis (Brand)', 'Dermatologic', 'Acne Treatment', 'Dermatology', 'Isotretinoin', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-zenatane-brand', 'Zenatane (Brand)', 'Dermatologic', 'Acne Treatment', 'Dermatology', 'Isotretinoin', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-retin-a-brand', 'Retin-A (Brand)', 'Dermatologic', 'Acne Treatment', 'Dermatology', 'Tretinoin', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-atralin-brand', 'Atralin (Brand)', 'Dermatologic', 'Acne Treatment', 'Dermatology', 'Tretinoin', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-avita-brand', 'Avita (Brand)', 'Dermatologic', 'Acne Treatment', 'Dermatology', 'Tretinoin', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-differin-brand', 'Differin (Brand)', 'Dermatologic', 'Acne Treatment', 'Dermatology', 'Adapalene', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-epiduo-brand', 'Epiduo (Brand)', 'Dermatologic', 'Acne Treatment', 'Dermatology', 'Adapalene', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-benzaclin-brand', 'BenzaClin (Brand)', 'Dermatologic', 'Acne Treatment', 'Dermatology', 'Clindamycin/Benzoyl Peroxide', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-duac-brand', 'Duac (Brand)', 'Dermatologic', 'Acne Treatment', 'Dermatology', 'Clindamycin/Benzoyl Peroxide', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-acanya-brand', 'Acanya (Brand)', 'Dermatologic', 'Acne Treatment', 'Dermatology', 'Clindamycin/Benzoyl Peroxide', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-aczone-brand', 'Aczone (Brand)', 'Dermatologic', 'Acne Treatment', 'Dermatology', 'Dapsone', TRUE, FALSE, TRUE);

-- Topical Corticosteroids (Generic versions)
INSERT INTO medications (
  id, code, name, category, subcategory, specialty, is_brand_name, is_target_medication, is_sample_data
) VALUES
  (gen_random_uuid(), 'med-clobetasolpropionate-gen', 'Clobetasol Propionate (Generic)', 'Dermatologic', 'Topical Corticosteroid', 'Dermatology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-betamethasonedipropionate-gen', 'Betamethasone Dipropionate (Generic)', 'Dermatologic', 'Topical Corticosteroid', 'Dermatology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-mometasonefuroate-gen', 'Mometasone Furoate (Generic)', 'Dermatologic', 'Topical Corticosteroid', 'Dermatology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-triamcinoloneacetonide-gen', 'Triamcinolone Acetonide (Generic)', 'Dermatologic', 'Topical Corticosteroid', 'Dermatology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-hydrocortisone-gen', 'Hydrocortisone (Generic)', 'Dermatologic', 'Topical Corticosteroid', 'Dermatology', FALSE, FALSE, TRUE);

-- Topical Corticosteroids (Brand versions)
INSERT INTO medications (
  id, code, name, category, subcategory, specialty, generic_name, is_brand_name, is_target_medication, is_sample_data
) VALUES
  (gen_random_uuid(), 'med-temovate-brand', 'Temovate (Brand)', 'Dermatologic', 'Topical Corticosteroid', 'Dermatology', 'Clobetasol Propionate', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-clobex-brand', 'Clobex (Brand)', 'Dermatologic', 'Topical Corticosteroid', 'Dermatology', 'Clobetasol Propionate', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-olux-brand', 'Olux (Brand)', 'Dermatologic', 'Topical Corticosteroid', 'Dermatology', 'Clobetasol Propionate', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-diprolene-brand', 'Diprolene (Brand)', 'Dermatologic', 'Topical Corticosteroid', 'Dermatology', 'Betamethasone Dipropionate', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-diprosone-brand', 'Diprosone (Brand)', 'Dermatologic', 'Topical Corticosteroid', 'Dermatology', 'Betamethasone Dipropionate', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-elocon-brand', 'Elocon (Brand)', 'Dermatologic', 'Topical Corticosteroid', 'Dermatology', 'Mometasone Furoate', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-kenalog-brand', 'Kenalog (Brand)', 'Dermatologic', 'Topical Corticosteroid', 'Dermatology', 'Triamcinolone Acetonide', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-triderm-brand', 'Triderm (Brand)', 'Dermatologic', 'Topical Corticosteroid', 'Dermatology', 'Triamcinolone Acetonide', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-cortaid-brand', 'Cortaid (Brand)', 'Dermatologic', 'Topical Corticosteroid', 'Dermatology', 'Hydrocortisone', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-cortizone-10-brand', 'Cortizone-10 (Brand)', 'Dermatologic', 'Topical Corticosteroid', 'Dermatology', 'Hydrocortisone', TRUE, FALSE, TRUE);

-- Psoriasis Medications (Generic versions)
INSERT INTO medications (
  id, code, name, category, subcategory, specialty, is_brand_name, is_target_medication, is_sample_data
) VALUES
  (gen_random_uuid(), 'med-calcipotriene-gen', 'Calcipotriene (Generic)', 'Dermatologic', 'Psoriasis Treatment', 'Dermatology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-calcipotrienebetamethasone-gen', 'Calcipotriene/Betamethasone (Generic)', 'Dermatologic', 'Psoriasis Treatment', 'Dermatology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-methotrexate-gen', 'Methotrexate (Generic)', 'Dermatologic', 'Psoriasis Treatment', 'Dermatology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-apremilast-gen', 'Apremilast (Generic)', 'Dermatologic', 'Psoriasis Treatment', 'Dermatology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-secukinumab-gen', 'Secukinumab (Generic)', 'Dermatologic', 'Psoriasis Treatment', 'Dermatology', FALSE, FALSE, TRUE);

-- Psoriasis Medications (Brand versions)
INSERT INTO medications (
  id, code, name, category, subcategory, specialty, generic_name, is_brand_name, is_target_medication, is_sample_data
) VALUES
  (gen_random_uuid(), 'med-dovonex-brand', 'Dovonex (Brand)', 'Dermatologic', 'Psoriasis Treatment', 'Dermatology', 'Calcipotriene', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-sorilux-brand', 'Sorilux (Brand)', 'Dermatologic', 'Psoriasis Treatment', 'Dermatology', 'Calcipotriene', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-taclonex-brand', 'Taclonex (Brand)', 'Dermatologic', 'Psoriasis Treatment', 'Dermatology', 'Calcipotriene/Betamethasone', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-enstilar-brand', 'Enstilar (Brand)', 'Dermatologic', 'Psoriasis Treatment', 'Dermatology', 'Calcipotriene/Betamethasone', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-otrexup-brand', 'Otrexup (Brand)', 'Dermatologic', 'Psoriasis Treatment', 'Dermatology', 'Methotrexate', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-rasuvo-brand', 'Rasuvo (Brand)', 'Dermatologic', 'Psoriasis Treatment', 'Dermatology', 'Methotrexate', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-trexall-brand', 'Trexall (Brand)', 'Dermatologic', 'Psoriasis Treatment', 'Dermatology', 'Methotrexate', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-otezla-brand', 'Otezla (Brand)', 'Dermatologic', 'Psoriasis Treatment', 'Dermatology', 'Apremilast', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-cosentyx-brand', 'Cosentyx (Brand)', 'Dermatologic', 'Psoriasis Treatment', 'Dermatology', 'Secukinumab', TRUE, FALSE, TRUE);

-- Other Dermatologic Agents (Generic versions)
INSERT INTO medications (
  id, code, name, category, subcategory, specialty, is_brand_name, is_target_medication, is_sample_data
) VALUES
  (gen_random_uuid(), 'med-tacrolimus-gen', 'Tacrolimus (Generic)', 'Dermatologic', 'Immunomodulator', 'Dermatology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-pimecrolimus-gen', 'Pimecrolimus (Generic)', 'Dermatologic', 'Immunomodulator', 'Dermatology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-dupilumab-gen', 'Dupilumab (Generic)', 'Dermatologic', 'Monoclonal Antibody', 'Dermatology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-ivermectin-gen', 'Ivermectin (Generic)', 'Dermatologic', 'Antiparasitic', 'Dermatology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-mupirocin-gen', 'Mupirocin (Generic)', 'Dermatologic', 'Topical Antibiotic', 'Dermatology', FALSE, FALSE, TRUE);

-- Other Dermatologic Agents (Brand versions)
INSERT INTO medications (
  id, code, name, category, subcategory, specialty, generic_name, is_brand_name, is_target_medication, is_sample_data
) VALUES
  (gen_random_uuid(), 'med-protopic-brand', 'Protopic (Brand)', 'Dermatologic', 'Immunomodulator', 'Dermatology', 'Tacrolimus', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-elidel-brand', 'Elidel (Brand)', 'Dermatologic', 'Immunomodulator', 'Dermatology', 'Pimecrolimus', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-dupixent-brand', 'Dupixent (Brand)', 'Dermatologic', 'Monoclonal Antibody', 'Dermatology', 'Dupilumab', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-soolantra-brand', 'Soolantra (Brand)', 'Dermatologic', 'Antiparasitic', 'Dermatology', 'Ivermectin', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-sklice-brand', 'Sklice (Brand)', 'Dermatologic', 'Antiparasitic', 'Dermatology', 'Ivermectin', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-bactroban-brand', 'Bactroban (Brand)', 'Dermatologic', 'Topical Antibiotic', 'Dermatology', 'Mupirocin', TRUE, FALSE, TRUE);

---------------------------------------
-- GASTROENTEROLOGY MEDICATIONS
---------------------------------------

-- Proton Pump Inhibitors (Generic versions)
INSERT INTO medications (
  id, code, name, category, subcategory, specialty, is_brand_name, is_target_medication, is_sample_data
) VALUES
  (gen_random_uuid(), 'med-esomeprazole-gen', 'Esomeprazole (Generic)', 'Gastrointestinal', 'Proton Pump Inhibitor', 'Gastroenterology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-lansoprazole-gen', 'Lansoprazole (Generic)', 'Gastrointestinal', 'Proton Pump Inhibitor', 'Gastroenterology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-dexlansoprazole-gen', 'Dexlansoprazole (Generic)', 'Gastrointestinal', 'Proton Pump Inhibitor', 'Gastroenterology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-rabeprazole-gen', 'Rabeprazole (Generic)', 'Gastrointestinal', 'Proton Pump Inhibitor', 'Gastroenterology', FALSE, FALSE, TRUE);

-- Proton Pump Inhibitors (Brand versions)
INSERT INTO medications (
  id, code, name, category, subcategory, specialty, generic_name, is_brand_name, is_target_medication, is_sample_data
) VALUES
  (gen_random_uuid(), 'med-nexium-brand', 'Nexium (Brand)', 'Gastrointestinal', 'Proton Pump Inhibitor', 'Gastroenterology', 'Esomeprazole', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-nexium24hr-brand', 'Nexium 24HR (Brand)', 'Gastrointestinal', 'Proton Pump Inhibitor', 'Gastroenterology', 'Esomeprazole', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-prevacid-brand', 'Prevacid (Brand)', 'Gastrointestinal', 'Proton Pump Inhibitor', 'Gastroenterology', 'Lansoprazole', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-prevacid24hr-brand', 'Prevacid 24HR (Brand)', 'Gastrointestinal', 'Proton Pump Inhibitor', 'Gastroenterology', 'Lansoprazole', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-dexilant-brand', 'Dexilant (Brand)', 'Gastrointestinal', 'Proton Pump Inhibitor', 'Gastroenterology', 'Dexlansoprazole', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-aciphex-brand', 'Aciphex (Brand)', 'Gastrointestinal', 'Proton Pump Inhibitor', 'Gastroenterology', 'Rabeprazole', TRUE, FALSE, TRUE);

-- H2 Receptor Antagonists (Generic versions)
INSERT INTO medications (
  id, code, name, category, subcategory, specialty, is_brand_name, is_target_medication, is_sample_data
) VALUES
  (gen_random_uuid(), 'med-ranitidine-gen', 'Ranitidine (Generic)', 'Gastrointestinal', 'H2 Receptor Antagonist', 'Gastroenterology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-cimetidine-gen', 'Cimetidine (Generic)', 'Gastrointestinal', 'H2 Receptor Antagonist', 'Gastroenterology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-nizatidine-gen', 'Nizatidine (Generic)', 'Gastrointestinal', 'H2 Receptor Antagonist', 'Gastroenterology', FALSE, FALSE, TRUE);

-- H2 Receptor Antagonists (Brand versions)
INSERT INTO medications (
  id, code, name, category, subcategory, specialty, generic_name, is_brand_name, is_target_medication, is_sample_data
) VALUES
  (gen_random_uuid(), 'med-zantac-brand', 'Zantac (Brand)', 'Gastrointestinal', 'H2 Receptor Antagonist', 'Gastroenterology', 'Ranitidine', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-tagamet-brand', 'Tagamet (Brand)', 'Gastrointestinal', 'H2 Receptor Antagonist', 'Gastroenterology', 'Cimetidine', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-axid-brand', 'Axid (Brand)', 'Gastrointestinal', 'H2 Receptor Antagonist', 'Gastroenterology', 'Nizatidine', TRUE, FALSE, TRUE);

-- Inflammatory Bowel Disease (IBD) Treatments (Generic versions)
INSERT INTO medications (
  id, code, name, category, subcategory, specialty, is_brand_name, is_target_medication, is_sample_data
) VALUES
  (gen_random_uuid(), 'med-infliximab-gen', 'Infliximab (Generic)', 'Gastrointestinal', 'TNF Inhibitor', 'Gastroenterology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-vedolizumab-gen', 'Vedolizumab (Generic)', 'Gastrointestinal', 'Integrin Receptor Antagonist', 'Gastroenterology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-ustekinumab-gen', 'Ustekinumab (Generic)', 'Gastrointestinal', 'IL-12/IL-23 Inhibitor', 'Gastroenterology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-budesonide-gen', 'Budesonide (Generic)', 'Gastrointestinal', 'Corticosteroid', 'Gastroenterology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-sulfasalazine-gen', 'Sulfasalazine (Generic)', 'Gastrointestinal', 'Aminosalicylate', 'Gastroenterology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-balsalazide-gen', 'Balsalazide (Generic)', 'Gastrointestinal', 'Aminosalicylate', 'Gastroenterology', FALSE, FALSE, TRUE);

-- Inflammatory Bowel Disease (IBD) Treatments (Brand versions)
INSERT INTO medications (
  id, code, name, category, subcategory, specialty, generic_name, is_brand_name, is_target_medication, is_sample_data
) VALUES
  (gen_random_uuid(), 'med-remicade-brand', 'Remicade (Brand)', 'Gastrointestinal', 'TNF Inhibitor', 'Gastroenterology', 'Infliximab', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-inflectra-brand', 'Inflectra (Brand)', 'Gastrointestinal', 'TNF Inhibitor', 'Gastroenterology', 'Infliximab', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-renflexis-brand', 'Renflexis (Brand)', 'Gastrointestinal', 'TNF Inhibitor', 'Gastroenterology', 'Infliximab', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-entyvio-brand', 'Entyvio (Brand)', 'Gastrointestinal', 'Integrin Receptor Antagonist', 'Gastroenterology', 'Vedolizumab', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-stelara-brand', 'Stelara (Brand)', 'Gastrointestinal', 'IL-12/IL-23 Inhibitor', 'Gastroenterology', 'Ustekinumab', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-entocortec-brand', 'Entocort EC (Brand)', 'Gastrointestinal', 'Corticosteroid', 'Gastroenterology', 'Budesonide', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-uceris-brand', 'Uceris (Brand)', 'Gastrointestinal', 'Corticosteroid', 'Gastroenterology', 'Budesonide', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-azulfidine-brand', 'Azulfidine (Brand)', 'Gastrointestinal', 'Aminosalicylate', 'Gastroenterology', 'Sulfasalazine', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-colazal-brand', 'Colazal (Brand)', 'Gastrointestinal', 'Aminosalicylate', 'Gastroenterology', 'Balsalazide', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-giazo-brand', 'Giazo (Brand)', 'Gastrointestinal', 'Aminosalicylate', 'Gastroenterology', 'Balsalazide', TRUE, FALSE, TRUE);

-- Antiemetics and Motility Agents (Generic versions)
INSERT INTO medications (
  id, code, name, category, subcategory, specialty, is_brand_name, is_target_medication, is_sample_data
) VALUES
  (gen_random_uuid(), 'med-ondansetron-gen', 'Ondansetron (Generic)', 'Gastrointestinal', 'Antiemetic', 'Gastroenterology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-metoclopramide-gen', 'Metoclopramide (Generic)', 'Gastrointestinal', 'Prokinetic', 'Gastroenterology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-prucalopride-gen', 'Prucalopride (Generic)', 'Gastrointestinal', 'Prokinetic', 'Gastroenterology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-dicyclomine-gen', 'Dicyclomine (Generic)', 'Gastrointestinal', 'Antispasmodic', 'Gastroenterology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-hyoscyamine-gen', 'Hyoscyamine (Generic)', 'Gastrointestinal', 'Antispasmodic', 'Gastroenterology', FALSE, FALSE, TRUE);

-- Antiemetics and Motility Agents (Brand versions)
INSERT INTO medications (
  id, code, name, category, subcategory, specialty, generic_name, is_brand_name, is_target_medication, is_sample_data
) VALUES
  (gen_random_uuid(), 'med-zofran-brand', 'Zofran (Brand)', 'Gastrointestinal', 'Antiemetic', 'Gastroenterology', 'Ondansetron', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-zuplenz-brand', 'Zuplenz (Brand)', 'Gastrointestinal', 'Antiemetic', 'Gastroenterology', 'Ondansetron', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-reglan-brand', 'Reglan (Brand)', 'Gastrointestinal', 'Prokinetic', 'Gastroenterology', 'Metoclopramide', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-metozolvodt-brand', 'Metozolv ODT (Brand)', 'Gastrointestinal', 'Prokinetic', 'Gastroenterology', 'Metoclopramide', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-motegrity-brand', 'Motegrity (Brand)', 'Gastrointestinal', 'Prokinetic', 'Gastroenterology', 'Prucalopride', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-bentyl-brand', 'Bentyl (Brand)', 'Gastrointestinal', 'Antispasmodic', 'Gastroenterology', 'Dicyclomine', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-levsin-brand', 'Levsin (Brand)', 'Gastrointestinal', 'Antispasmodic', 'Gastroenterology', 'Hyoscyamine', TRUE, FALSE, TRUE),
  (gen_random_uuid(), 'med-levbid-brand', 'Levbid (Brand)', 'Gastrointestinal', 'Antispasmodic', 'Gastroenterology', 'Hyoscyamine', TRUE, FALSE, TRUE);

-- Laxatives and Constipation Treatments (Generic versions)
INSERT INTO medications (
  id, code, name, category, subcategory, specialty, is_brand_name, is_target_medication, is_sample_data
) VALUES
  (gen_random_uuid(), 'med-linaclotide-gen', 'Linaclotide (Generic)', 'Gastrointestinal', 'Guanylate Cyclase-C Agonist', 'Gastroenterology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-plecanatide-gen', 'Plecanatide (Generic)', 'Gastrointestinal', 'Guanylate Cyclase-C Agonist', 'Gastroenterology', FALSE, FALSE, TRUE),
  (gen_random_uuid(), 'med-lubiprostone-gen', 'Lubiprostone (Generic)', 'Gastrointestinal', 'Chloride Channel Activator',
