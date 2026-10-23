import 'package:flutter/material.dart';
import '../services/medical_reference_service.dart';
import '../core/theme/app_theme.dart';

class MedicalReferenceScreen extends StatefulWidget {
  const MedicalReferenceScreen({super.key});

  @override
  State<MedicalReferenceScreen> createState() => _MedicalReferenceScreenState();
}

class _MedicalReferenceScreenState extends State<MedicalReferenceScreen> {
  final MedicalReferenceService _service = MedicalReferenceService();
  final TextEditingController _searchController = TextEditingController();

  List<DrugMonograph> _filtered = [];
  String _interactionDrugA = 'Metformin HCl';
  String _interactionDrugB = 'Aspirin Low Dose';
  DrugInteractionResult? _interactionResult;

  @override
  void initState() {
    super.initState();
    _filtered = _service.getAllMonographs();
    _runInteractionCheck();
  }

  void _runInteractionCheck() {
    setState(() {
      _interactionResult = _service.checkInteraction(_interactionDrugA, _interactionDrugB);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Medical Reference & Safety', style: TextStyle(fontWeight: FontWeight.w800)),
          bottom: const TabBar(
            indicatorColor: AppTheme.primaryTeal,
            labelColor: AppTheme.primaryTeal,
            tabs: [
              Tab(text: 'Drug Monographs'),
              Tab(text: 'Interaction Checker'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Monographs
            _buildMonographsTab(isDark),

            // Tab 2: Interaction Checker
            _buildInteractionTab(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMonographsTab(bool isDark) {
    return Column(
      children: [
        // Attribution notice banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppTheme.tealLight.withOpacity(0.5),
          child: const Row(
            children: [
              Icon(Icons.verified_user_rounded, size: 14, color: AppTheme.primaryTealDark),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Authorized Clinical Reference • Medscape & FDA Drug Monographs',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryTealDark),
                ),
              ),
            ],
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search drug, class, or indication (e.g. Statin, BP, Metformin)...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryTeal),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) {
              setState(() {
                _filtered = _service.search(val);
              });
            },
          ),
        ),

        Expanded(
          child: _filtered.isEmpty
              ? const Center(child: Text('No monograph matching query.'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: _filtered.length,
                  itemBuilder: (context, index) {
                    final drug = _filtered[index];
                    return _buildDrugMonographCard(drug, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDrugMonographCard(DrugMonograph drug, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryTeal.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.medical_information_rounded, color: AppTheme.primaryTealDark, size: 22),
        ),
        title: Text(drug.genericName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        subtitle: Text('${drug.name} • ${drug.drugClass}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(),
          _buildMonographRow('Indications', drug.commonIndications.join(', ')),
          _buildMonographRow('Adult Dosage', drug.adultDosage),
          _buildMonographRow('Mechanism', drug.mechanismOfAction),
          _buildMonographRow('Food Interaction', drug.foodInteractions, isWarning: true),
          _buildMonographRow('Renal Adjustment', drug.renalConsiderations),
          _buildMonographRow('Pregnancy', drug.pregnancyCategory),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2).withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.statusFailed.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 14, color: AppTheme.statusFailed),
                    SizedBox(width: 4),
                    Text('Clinical Box Warnings:', style: TextStyle(color: AppTheme.statusFailed, fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                for (final w in drug.warnings)
                  Text('• $w', style: const TextStyle(fontSize: 11, color: Color(0xFF991B1B))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              drug.sourceAttribution,
              style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonographRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isWarning ? Colors.amber.shade900 : Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionTab(bool isDark) {
    final drugOptions = [
      'Metformin HCl',
      'Amlodipine Besylate',
      'Atorvastatin Calcium',
      'Aspirin Low Dose',
      'Lisinopril',
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Clinical Drug-Drug Interaction Checker',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 4),
        const Text(
          'Evaluate pharmacokinetic & pharmacodynamic interactions across active prescriptions.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Drug Selectors
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _interactionDrugA,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Primary Agent'),
                items: drugOptions.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    _interactionDrugA = val;
                    _runInteractionCheck();
                  }
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.sync_alt_rounded, color: AppTheme.primaryTeal),
            ),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _interactionDrugB,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Concurrent Agent'),
                items: drugOptions.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    _interactionDrugB = val;
                    _runInteractionCheck();
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Result Card
        if (_interactionResult != null) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF152238) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _interactionResult!.severity.contains('Moderate')
                    ? AppTheme.statusWarning
                    : (_interactionResult!.severity.contains('Major') ? AppTheme.statusFailed : AppTheme.primaryTeal),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_interactionResult!.drugA} + ${_interactionResult!.drugB}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _interactionResult!.severity.contains('Moderate')
                            ? Colors.amber.withOpacity(0.15)
                            : AppTheme.tealLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _interactionResult!.severity,
                        style: TextStyle(
                          color: _interactionResult!.severity.contains('Moderate') ? Colors.amber.shade900 : AppTheme.primaryTealDark,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Clinical Assessment:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(_interactionResult!.clinicalSummary, style: const TextStyle(fontSize: 13, height: 1.4)),
                const SizedBox(height: 12),
                const Text('Management Advice:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(_interactionResult!.managementAdvice, style: const TextStyle(fontSize: 13, height: 1.4)),
                const SizedBox(height: 14),
                const Divider(),
                const Text(
                  'Source: Medscape Multi-Drug Interaction Engine & Clinical Pharmacology Monograph',
                  style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
