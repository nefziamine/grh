import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/stb_theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class RHDashboard extends StatefulWidget {
  const RHDashboard({super.key});

  @override
  State<RHDashboard> createState() => _RHDashboardState();
}

class _RHDashboardState extends State<RHDashboard> {
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await ApiService.get(ApiConfig.dashboardStats, forceRefresh: true);
      if (result['success'] == true && mounted) {
        setState(() {
          _stats = result['data'] ?? {};
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = result['message'] ?? 'Erreur inconnue';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Row(mainAxisSize: MainAxisSize.min, children: [ Image.asset('assets/images/Logo_STB.png', height: 40), const SizedBox(width: 12), const Text('Tableau de Bord') ])),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: STBColors.danger, size: 48),
                      const SizedBox(height: 16),
                      Text('Impossible de charger les données', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(_errorMessage!, textAlign: TextAlign.center, style: GoogleFonts.inter(color: STBColors.textSecondary)),
                      const SizedBox(height: 24),
                      ElevatedButton(onPressed: _loadStats, child: const Text('Réessayer')),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Absence trend chart
                    _buildChartCard('Tendance des absences', _buildAbsenceTrendChart()),
                    const SizedBox(height: 16),
                    // Tardiness trend chart
                    _buildChartCard('Tendance des retards', _buildRetardTrendChart()),
                    const SizedBox(height: 16),
                    // Leave type distribution
                    _buildChartCard('Répartition des congés', _buildCongeTypePieChart()),
                    const SizedBox(height: 16),
                    // Department distribution hidden as requested
                    // _buildChartCard('Répartition par département', _buildDepartementChart()),
                    // const SizedBox(height: 16),
                    // Top absents (Only for RH)
                    if (AuthService.currentUser?.role == 'rh' || AuthService.currentUser?.role == 'admin') ...[
                      _buildTopAbsentsCard(),
                      const SizedBox(height: 16),
                    ],
                    // Credits summary hidden for security as requested
                    /*
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [STBColors.gradientStart, STBColors.gradientEnd]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Crédits actifs', style: GoogleFonts.inter(fontSize: 14, color: STBColors.white.withValues(alpha: 0.8))),
                              const SizedBox(height: 4),
                              Text('${(_stats['montant_credits_actifs'] ?? 0).toStringAsFixed(2)} TND', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: STBColors.white)),
                            ],
                          ),
                          Icon(Icons.account_balance, size: 40, color: STBColors.white.withValues(alpha: 0.3)),
                        ],
                      ),
                    ),
                    */
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: STBColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }

  Widget _buildAbsenceTrendChart() {
    final List trend = (_stats['absence_trend'] as List?) ?? [];
    if (trend.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, color: STBColors.textSecondary.withValues(alpha: 0.3), size: 40),
            const SizedBox(height: 8),
            Text('Aucune donnée disponible', style: GoogleFonts.inter(color: STBColors.textSecondary)),
          ],
        ),
      );
    }

    return BarChart(
      key: ValueKey('absence_chart_${trend.length}_${_stats.hashCode}'),
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (trend.map((e) => (double.tryParse(e['count']?.toString() ?? '0') ?? 0.0)).toList().fold(0.0, (a, b) => a > b ? a : b) * 1.5).clamp(5, double.infinity),
        barGroups: trend.asMap().entries.map((entry) {
          final count = double.tryParse(entry.value['count']?.toString() ?? '0') ?? 0.0;
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: count,
                color: STBColors.danger,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                backDrawRodData: BackgroundBarChartRodData(show: true, toY: 5, color: STBColors.divider.withValues(alpha: 0.5)),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
            if (value.toInt() < trend.length) {
              return Padding(padding: const EdgeInsets.only(top: 8), child: Text(trend[value.toInt()]['month'].toString().substring(0, 3), style: GoogleFonts.inter(fontSize: 10, color: STBColors.textSecondary)));
            }
            return const Text('');
          })),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, m) => Text('${v.toInt()}', style: GoogleFonts.inter(fontSize: 10, color: STBColors.textSecondary)))),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1, getDrawingHorizontalLine: (v) => FlLine(color: STBColors.divider, strokeWidth: 0.5)),
      ),
    );
  }

  Widget _buildRetardTrendChart() {
    final List trend = (_stats['retard_trend'] as List?) ?? [];
    if (trend.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, color: STBColors.textSecondary.withValues(alpha: 0.3), size: 40),
            const SizedBox(height: 8),
            Text('Aucun retard enregistré', style: GoogleFonts.inter(color: STBColors.textSecondary)),
          ],
        ),
      );
    }

    return LineChart(
      key: ValueKey('retard_chart_${trend.length}_${_stats.hashCode}'),
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: trend.asMap().entries.map((e) {
              final count = double.tryParse(e.value['count']?.toString() ?? '0') ?? 0.0;
              return FlSpot(e.key.toDouble(), count);
            }).toList(),
            isCurved: true,
            color: STBColors.warning,
            barWidth: 3,
            dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: STBColors.warning, strokeWidth: 2, strokeColor: STBColors.white)),
            belowBarData: BarAreaData(show: true, color: STBColors.warning.withValues(alpha: 0.1)),
          ),
        ],
        maxY: (trend.map((e) => (double.tryParse(e['count']?.toString() ?? '0') ?? 0.0)).toList().fold(0.0, (a, b) => a > b ? a : b) * 1.5).clamp(5, double.infinity),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
            if (value.toInt() < trend.length) {
              final monthStr = trend[value.toInt()]['month']?.toString() ?? '';
              final shortMonth = monthStr.length > 3 ? monthStr.substring(0, 3) : monthStr;
              return Padding(padding: const EdgeInsets.only(top: 8), child: Text(shortMonth, style: GoogleFonts.inter(fontSize: 10, color: STBColors.textSecondary)));
            }
            return const Text('');
          })),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, m) => Text('${v.toInt()}', style: GoogleFonts.inter(fontSize: 10, color: STBColors.textSecondary)))),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: STBColors.divider, strokeWidth: 0.5)),
      ),
    );
  }

  Widget _buildCongeTypePieChart() {
    final types = (_stats['conge_types'] as List?) ?? [];
    if (types.isEmpty) return Center(child: Text('Aucune donnée', style: GoogleFonts.inter(color: STBColors.textSecondary)));

    final colors = [STBColors.primaryBlue, STBColors.primaryGreen, STBColors.warning, STBColors.danger, STBColors.info];

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: types.asMap().entries.map((entry) {
                return PieChartSectionData(
                  value: (double.tryParse(entry.value['count'].toString()) ?? 0.0),
                  color: colors[entry.key % colors.length],
                  title: '${entry.value['count']}',
                  radius: 60,
                  titleStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: STBColors.white),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 30,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: types.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[entry.key % colors.length], borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 6),
                  Text(entry.value['type_conge']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 11, color: STBColors.textSecondary)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDepartementChart() {
    final depts = (_stats['departements'] as List?) ?? [];
    if (depts.isEmpty) return Center(child: Text('Aucune donnée', style: GoogleFonts.inter(color: STBColors.textSecondary)));

    return Column(
      children: depts.map((dept) {
        final count = int.tryParse(dept['count'].toString()) ?? 0;
        final total = (_stats['total_employees'] ?? 1);
        final pct = total > 0 ? count / total : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dept['departement']?.toString() ?? 'N/A', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
                  Text('$count', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: STBColors.primaryBlue)),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(value: pct, backgroundColor: STBColors.divider, valueColor: AlwaysStoppedAnimation(STBColors.primaryBlue), minHeight: 6, borderRadius: BorderRadius.circular(3)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopAbsentsCard() {
    final topAbsents = (_stats['top_absents'] as List?) ?? [];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: STBColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: STBColors.danger, size: 20),
              const SizedBox(width: 8),
              Text('Top absences (année)', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          if (topAbsents.isEmpty)
            Text('Aucune donnée', style: GoogleFonts.inter(color: STBColors.textSecondary))
          else
            ...topAbsents.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text('${e['prenom']} ${e['nom']}', style: GoogleFonts.inter(fontSize: 13))),
                  Text('${e['matricule']}', style: GoogleFonts.inter(fontSize: 12, color: STBColors.textSecondary)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: STBColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text('${e['total_absences']}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: STBColors.danger)),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }
}
