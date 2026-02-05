// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'dart:io';
import '../models/account.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../widgets/dashboard_content.dart';
import '../config/theme.dart';
import 'accounts_screen.dart';
import 'transactions_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isFabExpanded = false;
  final DatabaseService _databaseService = DatabaseService();
  List<Account> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final accounts = await _databaseService.getAccounts();
    if (mounted) {
      setState(() {
        _accounts = accounts;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: const DashboardContent(),
        ),
      ),
      floatingActionButton: SizedBox(
        height: 300,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            if (_isFabExpanded) ...[
              Positioned(
                bottom: 200,
                child: _buildSmallFab(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onPressed: () {
                    setState(() => _isFabExpanded = false);
                    // TODO: Implement camera
                  },
                ),
              ),
              Positioned(
                bottom: 140,
                child: _buildSmallFab(
                  icon: Icons.mic,
                  label: 'Voice',
                  onPressed: () {
                    setState(() => _isFabExpanded = false);
                    _showVoiceInputDialog(context);
                  },
                ),
              ),
              Positioned(
                bottom: 80,
                child: _buildSmallFab(
                  icon: Icons.edit,
                  label: 'Manual',
                  onPressed: () {
                    setState(() => _isFabExpanded = false);
                    _showAddTransactionDialog(context);
                  },
                ),
              ),
            ],
            Positioned(
              bottom: 20,
              child: FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _isFabExpanded = !_isFabExpanded;
                  });
                },
                backgroundColor: AppTheme.primaryColor,
                elevation: 8,
                child: AnimatedRotation(
                  duration: const Duration(milliseconds: 300),
                  turns: _isFabExpanded ? 0.375 : 0,
                  child: const Icon(
                    Icons.add,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, Icons.dashboard_outlined, 'Dashboard'),
              _buildNavItem(context, Icons.account_balance_wallet_outlined, 'Accounts'),
              _buildNavItem(context, Icons.receipt_long_outlined, 'Transactions'),
              _buildNavItem(context, Icons.pie_chart_outline, 'Reports'),
              _buildNavItem(context, Icons.settings_outlined, 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label) {
    return GestureDetector(
      onTap: () async {
        if (label == 'Accounts') {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AccountsScreen()),
          );
          _loadAccounts();
        } else if (label == 'Transactions') {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TransactionsScreen()),
          );
          _loadAccounts();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallFab({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: AppTheme.purpleGradient,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        FloatingActionButton(
          heroTag: label,
          mini: true,
          elevation: 6,
          onPressed: onPressed,
          backgroundColor: AppTheme.primaryColor,
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ],
    );
  }

  void _showVoiceInputDialog(BuildContext context) {
    if (_accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create an account first before adding transactions'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      _showManualTextInputDialog(context);
      return;
    }

    // Voice input dialog for mobile
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice input will be implemented for mobile'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showManualTextInputDialog(BuildContext context) {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text(
            'Voice Input (Desktop Test Mode)',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Type what you would say:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Add 500 dirhams to cash for groceries',
                  hintStyle: TextStyle(color: Colors.white38),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Processing: ${textController.text}'),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  );
                }
              },
              child: const Text('Process', style: TextStyle(color: AppTheme.primaryColor)),
            ),
          ],
        );
      },
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    if (_accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create an account first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    Account? selectedAccount = _accounts.first;
    bool isIncome = true;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceColor,
              title: const Text('Add Transaction', style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Date picker, In/Out toggle, Account dropdown, Amount, Description
                    // ... (keeping the same dialog content as before)
                    const Text('Transaction form would go here', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Add', style: TextStyle(color: AppTheme.primaryColor)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}