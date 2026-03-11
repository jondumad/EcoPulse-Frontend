import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
import '../../../../models/evaluation_model.dart';
import '../../../../services/evaluation_service.dart';
import '../../../../providers/auth_provider.dart';

class EvaluationModal extends StatefulWidget {
  final VolunteerSummary volunteer;
  final int missionId;

  const EvaluationModal({super.key, required this.volunteer, required this.missionId});

  static void show(BuildContext context, VolunteerSummary volunteer, int missionId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EvaluationModal(volunteer: volunteer, missionId: missionId),
    );
  }

  @override
  State<EvaluationModal> createState() => _EvaluationModalState();
}


class _EvaluationModalState extends State<EvaluationModal> {
  final TextEditingController _commentController = TextEditingController();
  List<EvaluationCategory> _categories = [];
  final Map<int, int> _scores = {};
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    try {
      final categories = await EvaluationService.getCategories(token);
      if (mounted) {
        setState(() {
          _categories = categories;
          for (var cat in categories) {
            _scores[cat.id] = (cat.scale / 2).round();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() => _isSubmitting = true);

    try {
      final items = _scores.entries.map((e) => {'categoryId': e.key, 'score': e.value}).toList();

      await EvaluationService.submitEvaluation(
        token: token,
        evaluateeId: widget.volunteer.id,
        comments: _commentController.text,
        items: items,
        missionId: widget.missionId,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evaluation submitted successfully'),
            backgroundColor: AppTheme.forest,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          _buildHandle(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppTheme.clay,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                foregroundImage: NetworkImage(
                  'https://api.dicebear.com/7.x/avataaars/png?seed=${widget.volunteer.name}',
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Evaluating ${widget.volunteer.name}',
                    style: GoogleFonts.fraunces(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.ink,
                    ),
                  ),
                  Text(
                    'Performance Review Profile',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.ink.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(color: AppTheme.clay),
          const SizedBox(height: 16),
          ..._categories.map((cat) => _buildScoreSlider(cat)),
          const SizedBox(height: 16),
          Text(
            'FEEDBACK & OBSERVATIONS',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: AppTheme.ink.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Add qualitative remarks about impact...',
              hintStyle: GoogleFonts.inter(fontSize: 14, color: AppTheme.ink.withValues(alpha: 0.2)),
              fillColor: AppTheme.clay,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSlider(EvaluationCategory category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category.name.toUpperCase(),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
              ),
              Text(
                '${_scores[category.id]} / ${category.scale}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.forest,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (category.description != null)
            Text(
              category.description!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.ink.withValues(alpha: 0.4),
                height: 1.4,
              ),
            ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              activeTrackColor: AppTheme.forest,
              inactiveTrackColor: AppTheme.clay,
              thumbColor: Colors.white,
              overlayColor: AppTheme.forest.withValues(alpha: 0.1),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 4),
            ),
            child: Slider(
              value: _scores[category.id]!.toDouble(),
              min: 1,
              max: category.scale.toDouble(),
              divisions: category.scale - 1,
              onChanged: (val) {
                setState(() => _scores[category.id] = val.round());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppTheme.borderSubtle),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.ink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : const Text('Finalize Evaluation'),
            ),
          ),
        ],
      ),
    );
  }
}
