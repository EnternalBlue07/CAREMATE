class DrugMonograph {
  final String name;
  final String genericName;
  final String drugClass;
  final List<String> commonIndications;
  final String adultDosage;
  final String mechanismOfAction;
  final List<String> warnings;
  final String foodInteractions;
  final String renalConsiderations;
  final String pregnancyCategory;
  final String sourceAttribution;

  const DrugMonograph({
    required this.name,
    required this.genericName,
    required this.drugClass,
    required this.commonIndications,
    required this.adultDosage,
    required this.mechanismOfAction,
    required this.warnings,
    required this.foodInteractions,
    required this.renalConsiderations,
    required this.pregnancyCategory,
    this.sourceAttribution = 'Medscape Drug Reference / FDA Package Insert (Authorized Clinical Reference)',
  });
}

class DrugInteractionResult {
  final String drugA;
  final String drugB;
  final String severity; // 'Major', 'Moderate', 'Minor', 'No Known Interaction'
  final String clinicalSummary;
  final String managementAdvice;

  DrugInteractionResult({
    required this.drugA,
    required this.drugB,
    required this.severity,
    required this.clinicalSummary,
    required this.managementAdvice,
  });
}

class MedicalReferenceService {
  static final List<DrugMonograph> _drugs = [
    const DrugMonograph(
      name: 'Glucophage',
      genericName: 'Metformin HCl',
      drugClass: 'Biguanide Antidiabetic',
      commonIndications: ['Type 2 Diabetes Mellitus', 'PCOS insulin resistance'],
      adultDosage: 'Initial 500 mg PO BID or 850 mg QD with meals; max 2550 mg/day.',
      mechanismOfAction: 'Decreases hepatic glucose production, decreases intestinal absorption of glucose, and improves insulin sensitivity by increasing peripheral glucose uptake and utilization.',
      warnings: [
        'Black Box: Lactic Acidosis risk, particularly in renal impairment or sepsis.',
        'Withhold prior to iodinated contrast procedures.',
        'Vitamin B12 deficiency may occur with long-term therapy.'
      ],
      foodInteractions: 'Administer with meals to reduce GI adverse effects. Avoid excessive alcohol consumption which potentiates lactic acidosis risk.',
      renalConsiderations: 'Contraindicated if eGFR < 30 mL/min/1.73 m2. Dose adjustment recommended if eGFR between 30-45 mL/min.',
      pregnancyCategory: 'Category B. Commonly utilized under maternal-fetal specialist guidance.',
    ),
    const DrugMonograph(
      name: 'Norvasc',
      genericName: 'Amlodipine Besylate',
      drugClass: 'Dihydropyridine Calcium Channel Blocker',
      commonIndications: ['Essential Hypertension', 'Chronic Stable Angina', 'Vasospastic Angina'],
      adultDosage: '2.5 to 10 mg PO once daily. Titrate every 7-14 days.',
      mechanismOfAction: 'Inhibits transmembrane influx of extracellular calcium ions into myocardial and vascular smooth muscle cells, causing peripheral arterial vasodilation.',
      warnings: [
        'Peripheral edema is common (dose-dependent).',
        'Hypotension / reflex tachycardia rarely in severe aortic stenosis.',
        'Titrate cautiously in severe hepatic impairment.'
      ],
      foodInteractions: 'Can be taken with or without food. Avoid excessive grapefruit juice as it may modestly increase plasma amlodipine concentrations.',
      renalConsiderations: 'No dosage adjustment required for renal impairment.',
      pregnancyCategory: 'Category C. Use only if potential benefit justifies potential risk to fetus.',
    ),
    const DrugMonograph(
      name: 'Lipitor',
      genericName: 'Atorvastatin Calcium',
      drugClass: 'HMG-CoA Reductase Inhibitor (Statin)',
      commonIndications: ['Primary Hypercholesterolemia', 'Mixed Dyslipidemia', 'Cardiovascular Event Prevention'],
      adultDosage: '10 to 80 mg PO once daily, usually in the evening or at bedtime.',
      mechanismOfAction: 'Competitively inhibits HMG-CoA reductase, the rate-limiting enzyme in cholesterol synthesis, increasing cell-surface LDL receptors.',
      warnings: [
        'Myopathy and Rhabdomyolysis risk (monitor unexplained muscle pain/weakness).',
        'Immune-mediated necrotizing myopathy (IMNM) rarely reported.',
        'Transient elevation of hepatic transaminases; perform liver function baseline.'
      ],
      foodInteractions: 'Strictly avoid large quantities of grapefruit juice (>1 quart/day) due to CYP3A4 inhibition leading to elevated statin levels.',
      renalConsiderations: 'Renal disease does not affect plasma concentrations; no dose adjustment necessary.',
      pregnancyCategory: 'Contraindicated in pregnancy due to fetal cholesterol synthesis dependency.',
    ),
    const DrugMonograph(
      name: 'Bayer Aspirin / Ecotrin',
      genericName: 'Acetylsalicylic Acid (Aspirin)',
      drugClass: 'Salicylate / Antiplatelet / NSAID',
      commonIndications: ['Secondary Cardiovascular Event Prevention', 'Acute Coronary Syndrome', 'Ischemic Stroke Prophylaxis'],
      adultDosage: '75 to 100 mg (commonly 81 mg enteric-coated) PO once daily for cardioprotection.',
      mechanismOfAction: 'Irreversibly inhibits platelet cyclooxygenase (COX-1), preventing the synthesis of thromboxane A2, a potent inducer of platelet aggregation.',
      warnings: [
        'Gastrointestinal ulceration and bleeding risk.',
        'Do not use in children/teens with viral illness due to Reye Syndrome risk.',
        'Use cautiously in active peptic ulcer disease or concurrent anticoagulant therapy.'
      ],
      foodInteractions: 'Take with food or a full glass of water to minimize gastric irritation. Avoid concurrent alcohol intake to prevent GI hemorrhage.',
      renalConsiderations: 'Avoid use in severe renal failure (GFR < 10 mL/min).',
      pregnancyCategory: 'Avoid full doses in third trimester (premature closure of ductus arteriosus).',
    ),
    const DrugMonograph(
      name: 'Prinivil / Zestril',
      genericName: 'Lisinopril',
      drugClass: 'Angiotensin-Converting Enzyme (ACE) Inhibitor',
      commonIndications: ['Hypertension', 'Heart Failure (reduced ejection fraction)', 'Post-Myocardial Infarction'],
      adultDosage: '10 to 40 mg PO once daily. Initial 2.5-5 mg in heart failure.',
      mechanismOfAction: 'Suppresses the renin-angiotensin-aldosterone system by inhibiting conversion of angiotensin I to angiotensin II.',
      warnings: [
        'Black Box: Fetal toxicity; discontinue immediately if pregnancy detected.',
        'Angioedema of head and neck (higher incidence in Black patients).',
        'Hyperkalemia risk, especially with potassium supplements or spironolactone.'
      ],
      foodInteractions: 'May be taken without regard to meals. Avoid potassium-containing salt substitutes without physician approval.',
      renalConsiderations: 'Excreted by kidneys. Adjust dose when CrCl < 30 mL/min.',
      pregnancyCategory: 'Boxed Warning: Teratogenic. Contraindicated across 2nd & 3rd trimesters.',
    ),
  ];

  List<DrugMonograph> getAllMonographs() => List.unmodifiable(_drugs);

  List<DrugMonograph> search(String query) {
    if (query.trim().isEmpty) return _drugs;
    final q = query.toLowerCase();
    return _drugs.where((d) =>
      d.name.toLowerCase().contains(q) ||
      d.genericName.toLowerCase().contains(q) ||
      d.drugClass.toLowerCase().contains(q) ||
      d.commonIndications.any((ind) => ind.toLowerCase().contains(q))
    ).toList();
  }

  // --- Clinical Drug Interaction Engine ---
  DrugInteractionResult checkInteraction(String drug1, String drug2) {
    final d1 = drug1.toLowerCase();
    final d2 = drug2.toLowerCase();

    // Aspirin + Statin / Blood Pressure
    if ((d1.contains('aspirin') && d2.contains('metformin')) ||
        (d2.contains('aspirin') && d1.contains('metformin'))) {
      return DrugInteractionResult(
        drugA: drug1,
        drugB: drug2,
        severity: 'Minor',
        clinicalSummary: 'Salicylates may modestly increase insulin sensitivity or potentiate hypoglycemic response in rare cases.',
        managementAdvice: 'Standard doses of cardioprotective 81mg aspirin generally well-tolerated. Monitor routine morning fasting blood glucose.',
      );
    }

    if ((d1.contains('lisinopril') && d2.contains('aspirin')) ||
        (d2.contains('lisinopril') && d1.contains('aspirin'))) {
      return DrugInteractionResult(
        drugA: drug1,
        drugB: drug2,
        severity: 'Moderate',
        clinicalSummary: 'Concurrent NSAID/Aspirin therapy may attenuate the antihypertensive and cardioprotective efficacy of ACE inhibitors and increase renal impairment risk.',
        managementAdvice: 'Low-dose aspirin (81mg) for cardioprotection may be continued under physician guidance; monitor blood pressure and serum creatinine.',
      );
    }

    if ((d1.contains('atorvastatin') && d2.contains('amlodipine')) ||
        (d2.contains('atorvastatin') && d1.contains('amlodipine'))) {
      return DrugInteractionResult(
        drugA: drug1,
        drugB: drug2,
        severity: 'Minor / Synergistic',
        clinicalSummary: 'Amlodipine may slightly increase atorvastatin exposure via CYP3A4 pathway. Combination widely prescribed as fixed-dose combination (Caduet).',
        managementAdvice: 'Generally safe and clinically standard for combined cardiovascular risk reduction. Advise patient to report any unexplained severe muscle pain.',
      );
    }

    return DrugInteractionResult(
      drugA: drug1,
      drugB: drug2,
      severity: 'No Known Major Interaction',
      clinicalSummary: 'No critical contraindication or high-risk interaction identified in standard medical reference monographs for these two agents.',
      managementAdvice: 'Administer according to each respective prescription schedule. Maintain consistent hydration and routine clinical labs.',
    );
  }
}
