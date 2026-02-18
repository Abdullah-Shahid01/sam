// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'dart:io';
import '../models/account.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../widgets/dashboard_content.dart';
import '../widgets/voice_input_dialog.dart';
import '../config/theme.dart';
import 'accounts_screen.dart';
import 'transactions_screen.dart';
import 'reports_screen.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'package:intl/intl.dart';
import '../models/parsed_transaction.dart';

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

  // Note: _loadAccounts is also called via onNavigateBack when returning from child screens

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
                  icon: Icons.photo_library,
                  label: 'Photo',
                  onPressed: () {
                    setState(() => _isFabExpanded = false);
                    _showPhotoOptionsDialog(context);
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
    return AppBottomNavBar(
      currentLabel: 'Dashboard',
      onNavigateBack: _loadAccounts,
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



  void _showPhotoOptionsDialog(BuildContext context) {
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
    
    // ... 


    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text(
            'Add from Photo',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                title: const Text('Capture', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Take a photo', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Camera capture will be implemented')),
                  );
                },
              ),
              const Divider(color: Colors.white12, height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.upload_file, color: AppTheme.secondaryColor),
                title: const Text('Upload', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Choose file', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('File upload will be implemented')),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
          ],
        );
      },
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VoiceInputDialog(
        accounts: _accounts,
        onTransactionAdded: () {
          _loadAccounts();
        },
      ),
    );
  }


  void _showAddTransactionDialog(BuildContext context, {ParsedTransaction? parsedData}) {
    if (_accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create an account first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amountController = TextEditingController(
      text: parsedData?.amount?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: parsedData?.description ?? '',
    );
    DateTime selectedDate = parsedData?.date ?? DateTime.now();
    
    // account
    Account? selectedAccount;
    if (parsedData?.accountName != null) {
      try {
        selectedAccount = _accounts.firstWhere(
          (a) => a.name.toLowerCase() == parsedData!.accountName!.toLowerCase()
        );
      } catch (e) {
        selectedAccount = _accounts.first;
      }
    } else {
      selectedAccount = _accounts.first;
    }

    // flow
    bool isIncome = parsedData?.isInflow ?? true;
    
    // Category & Fixed
    String selectedCategory = parsedData?.category ?? 'Uncategorized';
    bool isFixed = parsedData?.isFixed ?? false;

    final List<String> categories = [
      'Uncategorized', 'Food', 'Transport', 'Utilities', 'Rent', 
      'Salary', 'Shopping', 'Entertainment', 'Health', 'Other'
    ];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E2A3A),
              title: const Text(
                'Add Transaction',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Date Format
                    GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1419),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white38),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Date:',
                              style: TextStyle(color: Colors.white70),
                            ),
                            Text(
                              DateFormat('MMM dd, yyyy').format(selectedDate),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Toggle In/Out
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(() => isIncome = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isIncome ? const Color(0xFF00B894) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isIncome ? Colors.transparent : Colors.white38,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Income',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(() => isIncome = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !isIncome ? const Color(0xFFFF7675) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: !isIncome ? Colors.transparent : Colors.white38,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Expense',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<Account>(
                      value: selectedAccount,
                      dropdownColor: const Color(0xFF1E2A3A),
                      decoration: const InputDecoration(
                        labelText: 'Account',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white38),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF4A90E2)),
                        ),
                      ),
                      items: _accounts.map((Account account) {
                        return DropdownMenuItem<Account>(
                          value: account,
                          child: Text(
                            account.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (Account? newValue) {
                        setDialogState(() {
                          selectedAccount = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      value: categories.contains(selectedCategory) ? selectedCategory : 'Uncategorized',
                      dropdownColor: const Color(0xFF1E2A3A),
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white38),
                        ),
                      ),
                      items: categories.map((String cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Text(cat, style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setDialogState(() {
                            selectedCategory = newValue;
                            if (newValue == 'Rent' || newValue == 'Utilities') {
                              isFixed = true;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),

                    SwitchListTile(
                      title: const Text('Fixed Cost', style: TextStyle(color: Colors.white70)),
                      value: isFixed,
                      activeColor: const Color(0xFF4A90E2),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (bool value) => setDialogState(() => isFixed = value),
                    ),
                    
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white38),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white38),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                TextButton(
                  onPressed: () async {
                    if (amountController.text.isNotEmpty && selectedAccount != null) {
                      final amount = double.tryParse(amountController.text);
                      if (amount == null) return;
                      final finalAmount = isIncome ? amount : -amount;
                      
                      final transaction = AppTransaction(
                        transactionId: DateTime.now().millisecondsSinceEpoch.toString(),
                        accountId: selectedAccount!.id!,
                        amount: finalAmount,
                        date: selectedDate,
                        description: descriptionController.text.isEmpty ? null : descriptionController.text,
                        category: selectedCategory,
                        isFixed: isFixed,
                      );
                      
                      await _databaseService.insertTransaction(transaction);
                      Navigator.pop(context);
                      _loadAccounts(); // Refresh
                    }
                  },
                  child: const Text('Add', style: TextStyle(color: Color(0xFF4A90E2))),
                ),
              ],
            );
          },
        );
      },
    );
  }
}