import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mission_model.dart';
import '../providers/mission_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/eco_pulse_widgets.dart';

class MissionTemplatePicker extends StatefulWidget {
  final Function(Mission) onTemplateSelected;

  const MissionTemplatePicker({super.key, required this.onTemplateSelected});

  static void show(BuildContext context, {required Function(Mission) onTemplateSelected}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MissionTemplatePicker(onTemplateSelected: onTemplateSelected),
    );
  }

  @override
  State<MissionTemplatePicker> createState() => _MissionTemplatePickerState();
}

class _MissionTemplatePickerState extends State<MissionTemplatePicker> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        Provider.of<MissionProvider>(context, listen: false).fetchTemplates();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MissionProvider>(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: EcoColors.clay,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.violet.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.copy_all_rounded, color: AppTheme.violet, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mission Templates',
                        style: EcoText.displayMD(context).copyWith(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Quick-start with a saved setup',
                        style: TextStyle(color: EcoColors.ink.withValues(alpha: 0.6), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: EcoColors.ink),
                  style: IconButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.all(8)),
                ),
              ],
            ),
          ),

          Expanded(
            child: provider.isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppTheme.violet))
              : provider.templates.isEmpty 
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: provider.templates.length,
                    itemBuilder: (context, index) => _TemplateCard(
                      template: provider.templates[index],
                      onTap: () {
                        widget.onTemplateSelected(provider.templates[index]);
                        Navigator.pop(context);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.dashboard_customize_outlined, size: 64, color: Colors.black.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            'No templates yet',
            style: EcoText.displayMD(context).copyWith(
              color: EcoColors.ink.withValues(alpha: 0.4),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Save your first mission as a template to see it here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: EcoColors.ink.withValues(alpha: 0.3), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final Mission template;
  final VoidCallback onTap;

  const _TemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final category = template.categories.isNotEmpty ? template.categories.first : null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: EcoColors.clay,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      category?.icon ?? '🌱',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: EcoColors.ink),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.flag_outlined, size: 12, color: _getPriorityColor(template.priority)),
                          const SizedBox(width: 4),
                          Text(
                            '${template.priority} Priority',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _getPriorityColor(template.priority)),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.stars_rounded, size: 12, color: AppTheme.forest.withValues(alpha: 0.6)),
                          const SizedBox(width: 4),
                          Text(
                            '${template.pointsValue} pts',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.ink.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical': return Colors.red;
      case 'high': return Colors.orange;
      case 'low': return Colors.blue;
      default: return Colors.grey;
    }
  }
}
