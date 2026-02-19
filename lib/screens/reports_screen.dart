import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/charts/expense_pie_chart.dart';
import '../widgets/charts/income_expense_bar_chart.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'transactions_screen.dart';
import '../models/transaction.dart';
import '../services/csv_export_service.dart';

import '../services/database_service.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime.now(),
  );
  bool _excludeFixed = false;
  bool _isLoading = true;

  Map<String, double> _expenseData = {};
  Map<String, Map<String, double>> _barData = {};
  List<AppTransaction> _topSpenders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load Pie Chart Data
      final expenses = await _databaseService.getExpensesByCategory(
        _selectedDateRange.start, 
        _selectedDateRange.end, 
        excludeFixed: _excludeFixed
      );
      
      // Load Bar Chart Data
      final days = _selectedDateRange.end.difference(_selectedDateRange.start).inDays;
      String groupBy = days <= 31 ? 'day' : 'month';
      
      final barData = await _databaseService.getTrendData(
        _selectedDateRange.start,
        _selectedDateRange.end,
        groupBy: groupBy
      );

      // Load Top Spenders
      final topSpenders = await _databaseService.getTopSpenders(
        _selectedDateRange.start,
        _selectedDateRange.end
      );

      if (mounted) {
        setState(() {
          _expenseData = expenses;
          _barData = barData;
          _topSpenders = topSpenders;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading report data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF4A90E2),
              onPrimary: Colors.white,
              surface: Color(0xFF1E2A3A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      _loadData();
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
                  ExpensePieChart(
                    data: _expenseData,
                    onCategoryTap: (category) {
                       Navigator.push(
                         context,
                         MaterialPageRoute(
                           builder: (_) => TransactionsScreen(
                             startDate: _selectedDateRange.start,
                             endDate: _selectedDateRange.end,
                             category: category,
                           ),
                         ),
                       );
                    },
                  ),
                  
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

                  const SizedBox(height: 40),
                  
                  if (_topSpenders.isNotEmpty) ...[
                    const Text(
                      'Hall of Shame 🏆',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2A3A),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _topSpenders.length,
                        separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                        itemBuilder: (context, index) {
                          final tx = _topSpenders[index];
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF2D3748),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.attach_money, color: Colors.white70, size: 20),
                            ),
                            title: Text(
                              tx.description ?? 'Expense',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              DateFormat('MMM d').format(tx.date),
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                            trailing: Text(
                              'AED ${tx.amount.abs().toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Color(0xFFFF7675),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Reports',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E2A3A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: IconButton(
            icon: const Icon(Icons.download, color: Colors.white70),
            tooltip: 'Export CSV',
            onPressed: () async {
              if (_isLoading) return;
              
              // Fetch all transactions for this period
              final allTransactions = await _databaseService.getTransactions(
                startDate: _selectedDateRange.start,
                endDate: _selectedDateRange.end,
              );
              
              final accounts = await _databaseService.getAccounts();
              
              if (mounted) {
                await CsvExportService().exportCsv(
                  context, 
                  allTransactions, 
                  accounts: accounts
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        InkWell(
          onTap: _selectDateRange,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2A3A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFF4A90E2), size: 16),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('MMM d').format(_selectedDateRange.start)} - ${DateFormat('MMM d').format(_selectedDateRange.end)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_drop_down, color: Colors.white54),
              ],
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Exclude Recurring', style: TextStyle(color: Colors.white70)),
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

}
