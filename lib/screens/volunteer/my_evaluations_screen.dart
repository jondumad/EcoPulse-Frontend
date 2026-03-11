import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/evaluation_model.dart';
import '../../services/evaluation_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/eco_app_bar.dart';
import '../../widgets/eco_pulse_widgets.dart';
import '../../widgets/atoms/eco_card.dart';

class MyEvaluationsScreen extends StatefulWidget {
  const MyEvaluationsScreen({super.key});

  @override
  State<MyEvaluationsScreen> createState() => _MyEvaluationsScreenState();
}

class _MyEvaluationsScreenState extends State<MyEvaluationsScreen> with TickerProviderStateMixin {
  late AnimationController _chartController;
  late AnimationController _listController;
  List<EvaluationSession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _listController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000)
    );
    _fetchData();
  }

  Future<void> _fetchData() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    try {
      final sessions = await EvaluationService.getMyEvaluations(token);
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
        _chartController.forward();
        _listController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _chartController.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EcoPulseLayout(
      appBar: const EcoAppBar(title: 'My Impact Profile'),
      child: RefreshIndicator(
        onRefresh: _fetchData,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: _isLoading 
                    ? const AspectRatio(aspectRatio: 1.5, child: Center(child: CircularProgressIndicator()))
                    : _buildImpactRadarCard(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const EcoSectionHeader(title: 'Historical Impact Timeline'),
                      const SizedBox(height: 8),
                      Text(
                        'Aggregated feedback and performance benchmarks over time.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.ink.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (_sessions.isEmpty && !_isLoading)
                         _buildEmptyTimeline()
                      else
                        ...List.generate(_sessions.length, (i) => _buildTimelineItem(i)),
                      const SizedBox(height: 100),
                    ],
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactRadarCard() {
    if (_sessions.isEmpty) return const SizedBox.shrink();

    // Aggregate scores per category for radar
    final Map<String, List<int>> aggregated = {};
    for (var session in _sessions) {
      for (var item in session.items) {
        final name = item.category?.name ?? 'Trait';
        aggregated[name] = (aggregated[name] ?? [])..add(item.score);
      }
    }

    final List<RadarEntry> radarEntries = [];
    final List<String> labels = [];
    
    aggregated.forEach((name, scores) {
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      radarEntries.add(RadarEntry(value: avg));
      labels.add(name);
    });

    if (radarEntries.length < 3) {
      while(radarEntries.length < 3) {
        radarEntries.add(const RadarEntry(value: 3));
        labels.add("Dimension X");
      }
    }

    return EcoPulseCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          color: AppTheme.ink,
          child: Stack(
            children: [
              Positioned(
                top: -50, right: -50,
                child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [AppTheme.violet.withValues(alpha: 0.15), Colors.transparent]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Impact Radar'.toUpperCase(),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                color: AppTheme.amber,
                              ),
                            ),
                            Text(
                              'FIELD PROFICIENCY',
                              style: GoogleFonts.fraunces(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.radar_rounded, color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    AnimatedBuilder(
                      animation: _chartController,
                      builder: (context, child) {
                        return AspectRatio(
                          aspectRatio: 1.5,
                          child: RadarChart(
                            RadarChartData(
                              radarShape: RadarShape.polygon,
                              dataSets: [
                                RadarDataSet(
                                  fillColor: AppTheme.forest.withValues(alpha: 0.4),
                                  borderColor: AppTheme.forest,
                                  entryRadius: 3,
                                  borderWidth: 2,
                                  dataEntries: radarEntries,
                                ),
                              ],
                              radarBackgroundColor: Colors.transparent,
                              gridBorderData: const BorderSide(color: Colors.white10, width: 1),
                              tickBorderData: const BorderSide(color: Colors.white10, width: 1),
                              ticksTextStyle: const TextStyle(color: Colors.transparent),
                              getTitle: (index, angle) {
                                return RadarChartTitle(
                                  text: labels[index % labels.length],
                                  angle: angle,
                                );
                              },
                              titlePositionPercentageOffset: 0.15,
                              titleTextStyle: GoogleFonts.jetBrainsMono(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: Colors.white70,
                              ),
                            ),
                            duration: const Duration(milliseconds: 1500),
                            curve: Curves.easeOutQuart,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(int index) {
    final session = _sessions[index];
    final animation = CurvedAnimation(
      curve: Interval((index * 0.1).clamp(0, 1), 1, curve: Curves.easeOutCubic),
      parent: _listController,
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - animation.value)),
          child: Opacity(opacity: animation.value, child: child),
        );
      },
      child: IntrinsicHeight(
        child: Row(
          children: [
            Column(
              children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.violet, border: Border.all(color: Colors.white, width: 2)),
                ),
                Expanded(child: Container(width: 2, color: AppTheme.violet.withValues(alpha: 0.16), margin: const EdgeInsets.symmetric(vertical: 8))),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMMM dd, yyyy').format(session.createdAt).toUpperCase(),
                      style: GoogleFonts.jetBrainsMono(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.ink.withValues(alpha: 0.4)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (session.missionTitle != null) ...[
                            Text(
                              session.missionTitle!.toUpperCase(),
                              style: GoogleFonts.fraunces(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.ink,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'SESSION BY ${session.evaluatorName?.toUpperCase() ?? "COORDINATOR"}',
                                style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.forest),
                              ),
                              const Icon(Icons.verified_rounded, size: 16, color: AppTheme.forest),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (session.comments != null)
                             Text(
                               '"${session.comments}"',
                               style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.ink, height: 1.5, fontStyle: FontStyle.italic),
                             ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: session.items.map((it) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: AppTheme.clay, borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                '${it.category?.name ?? "Trait"}: ${it.score}',
                                style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.inkSecondary),
                              ),
                            )).toList(),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTimeline() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.clay.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.history_toggle_off_rounded, size: 48, color: AppTheme.inkTertiary),
            const SizedBox(height: 16),
            Text('No evaluations yet', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.inkSecondary)),
            const SizedBox(height: 4),
            Text('Wait for a coordinator review.', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.inkTertiary)),
          ],
        ),
      ),
    );
  }
}
