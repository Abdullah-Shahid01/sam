import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../config/theme.dart';

class IncomeExpenseBarChart extends StatelessWidget {
  final Map<String, Map<String, double>> data; // Month -> {'income': x, 'expense': y}

  const IncomeExpenseBarChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();

    final keys = data.keys.toList(); // List of months (e.g., 'Jan', 'Feb')
    
    // Calculate max Y for scale
    double maxY = 0;
    for (var v in data.values) {
      if (v['income']! > maxY) maxY = v['income']!;
      if (v['expense']! > maxY) maxY = v['expense']!;
    }
    maxY = maxY * 1.2; // Add breathing room

    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: AppTheme.surfaceColor,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                 String label = rodIndex == 0 ? 'Income' : 'Expense';
                 return BarTooltipItem(
                   '$label\n${rod.toY.toStringAsFixed(0)}',
                   const TextStyle(
                     color: Colors.white,
                     fontWeight: FontWeight.bold,
                   ),
                 );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value >= keys.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      keys[value.toInt()],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false), // Hide left axis numbers for cleanliness
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white12,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(data.length, (index) {
            final key = keys[index];
            final income = data[key]!['income'] ?? 0.0;
            final expense = data[key]!['expense'] ?? 0.0;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: income,
                  color: AppTheme.secondaryColor,
                  width: 12,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
                BarChartRodData(
                  toY: expense,
                  color: AppTheme.errorColor,
                  width: 12,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
