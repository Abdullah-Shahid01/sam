import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../config/theme.dart';

class ExpensePieChart extends StatefulWidget {
  final Map<String, double> data;
  final bool animate;

  const ExpensePieChart({
    super.key,
    required this.data,
    this.animate = true,
  });

  @override
  State<ExpensePieChart> createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends State<ExpensePieChart> {
  int touchedIndex = -1;

  final List<Color> _colors = [
    const Color(0xFF6C5CE7), // Primary
    const Color(0xFF00B894), // Secondary
    const Color(0xFFFF7675), // Red
    const Color(0xFFE17055), // Orange
    const Color(0xFFFDCB6E), // Yellow
    const Color(0xFF0984E3), // Blue
    const Color(0xFFD63031), // Dark Red
    const Color(0xFF636E72), // Grey
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No expenses to show',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    final total = widget.data.values.fold(0.0, (sum, item) => sum + item);
    final entries = widget.data.entries.toList();
    // Sort by value desc
    entries.sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.3,
          child: Row(
            children: [
              const SizedBox(height: 18),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                                touchedIndex = -1;
                                return;
                            }
                            touchedIndex = pieTouchResponse
                                .touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: List.generate(entries.length, (i) {
                        final isTouched = i == touchedIndex;
                        final fontSize = isTouched ? 20.0 : 16.0;
                        final radius = isTouched ? 110.0 : 100.0;
                        final entry = entries[i];
                        final percentage = (entry.value / total * 100).toStringAsFixed(1);
                        final color = _colors[i % _colors.length];

                        return PieChartSectionData(
                          color: color,
                          value: entry.value,
                          title: isTouched ? '${entry.key}\n$percentage%' : '$percentage%',
                          radius: radius,
                          titleStyle: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                          badgeWidget: isTouched ? _buildBadge(entry.key, entry.value, color) : null,
                          badgePositionPercentageOffset: 1.2,
                        );
                      }),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 28),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Total',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'AED ${total.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildBadge(String category, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 4,
          ),
        ],
      ),
      child: Text(
        '$category: ${amount.toStringAsFixed(0)}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
