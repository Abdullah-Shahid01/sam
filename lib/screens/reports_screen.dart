import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/charts/expense_pie_chart.dart';
import '../widgets/charts/income_expense_bar_chart.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'dashboard_screen.dart'; // For navigation overrides if needed, or just standard nav structure

import '../services/database_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  
  String _selectedPeriod = 'This Month';
  bool _excludeFixed = false;
  bool _isLoading = true;

  Map<String, double> _expenseData = {};
  Map<String, Map<String, double>> _barData = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final range = _getDateRange(_selectedPeriod);
      
      // Load Pie Chart Data
      final expenses = await _databaseService.getExpensesByCategory(
        range.start, 
        range.end, 
        excludeFixed: _excludeFixed
      );
      
      // Load Bar Chart Data (Trend)
      // If period is <= 1 month, show daily trend. Else show monthly trend.
      String groupBy = 'month';
      if (_selectedPeriod == 'This Month' || _selectedPeriod == 'Last Month') {
        groupBy = 'day';
      }
      
      final barData = await _databaseService.getTrendData(
        range.start,
        range.end,
        groupBy: groupBy
      );

      if (mounted) {
        setState(() {
          _expenseData = expenses;
          _barData = barData;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading report data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  DateTimeRange _getDateRange(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'This Month':
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      case 'Last Month':
        final start = DateTime(now.year, now.month - 1, 1);
        final end = DateTime(now.year, now.month, 0); // Last day of prev month
        return DateTimeRange(start: start, end: end);
      case '3 Months':
        return DateTimeRange(
          start: DateTime(now.year, now.month - 2, 1),
          end: now,
        );
      case 'Year':
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: now,
        );
      default:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildFilterRow(),
                  const SizedBox(height: 32),
                  
                  const Text(
                    'Expense Breakdown',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ExpensePieChart(data: _expenseData),
                  
                  const SizedBox(height: 40),
                  
                  const Text(
                    'Income vs Expense Trend',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  IncomeExpenseBarChart(data: _barData),
                ],
              ),
            ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildHeader() {
    return const Text(
      'Reports',
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildFilterRow() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        DropdownButton<String>(
          value: _selectedPeriod,
          dropdownColor: AppTheme.surfaceColor,
          underline: Container(),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          items: ['This Month', 'Last Month', '3 Months', 'Year']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedPeriod = val);
              _loadData();
            }
          },
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Exclude Fixed', style: TextStyle(color: Colors.white70)),
            Switch(
              value: _excludeFixed,
              activeColor: AppTheme.primaryColor,
              onChanged: (val) {
                setState(() => _excludeFixed = val);
                _loadData();
              },
            ),
          ],
        ),
      ],
    );
  }

  // Copied from DashboardScreen for consistency in this standalone verification phase.
  // In production, we should refactor BottomNavBar to a shared widget.
  Widget _buildBottomNavBar(BuildContext context) {
    return const AppBottomNavBar(
      currentLabel: 'Reports',
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label) {
    // Legacy method - can be removed or left if used elsewhere (it's not)
    // But since I am replacing _buildBottomNavBar which calls it, this code is now dead.
    // I will just replace the _buildBottomNavBar method block.
    return const SizedBox(); 
  }
}
