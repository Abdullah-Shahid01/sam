// lib/screens/transactions_screen.dart

import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';
import 'accounts_screen.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:io';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<AppTransaction> _transactions = [];
  List<Account> _accounts = [];
  bool _isLoading = true;
  bool _isFabExpanded = false;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _transcribedText = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    final transactions = await _databaseService.getTransactions();
    final accounts = await _databaseService.getAccounts();
    if (mounted) {
      setState(() {
        _transactions = transactions;
        _accounts = accounts;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Transactions',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _transactions.isEmpty
                        ? const Center(
                            child: Text(
                              'No transactions yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white54,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _transactions.length,
                            itemBuilder: (context, index) {
                              final transaction = _transactions[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E2A3A),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateFormat('MMM dd, yyyy').format(transaction.date),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white54,
                                          ),
                                        ),
                                        Text(
                                          'AED ${transaction.amount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Account ID: ${transaction.accountId}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (transaction.description != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        transaction.description!,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        height: 300,
        child: Stack(
          alignment: Alignment.bottomRight,
          clipBehavior: Clip.none,
          children: [
            if (_isFabExpanded) ...[
              Positioned(
                bottom: 200,
                right: 0,
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
                right: 0,
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
                right: 0,
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
              bottom: 0,
              right: 0,
              child: FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _isFabExpanded = !_isFabExpanded;
                  });
                },
                backgroundColor: const Color(0xFF4A90E2),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNavBar(context),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2A3A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FloatingActionButton(
          heroTag: label,
          mini: true,
          onPressed: onPressed,
          backgroundColor: const Color(0xFF4A90E2),
          child: Icon(icon, size: 20),
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

    // For desktop testing - show manual text input as fallback
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      _showManualTextInputDialog(context);
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E2A3A),
              title: const Text(
                'Voice Input',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (!_isListening) {
                        bool available = await _speech.initialize(
                          onError: (error) {
                            print('Speech error: $error');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${error.errorMsg}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                          onStatus: (status) {
                            print('Speech status: $status');
                          },
                        );
                        
                        if (available) {
                          setDialogState(() {
                            _isListening = true;
                            _transcribedText = '';
                          });
                          
                          _speech.listen(
                            onResult: (result) {
                              print('Recognized: ${result.recognizedWords}');
                              setDialogState(() {
                                _transcribedText = result.recognizedWords;
                              });
                              setState(() {
                                _transcribedText = result.recognizedWords;
                              });
                            },
                            listenFor: const Duration(seconds: 30),
                            pauseFor: const Duration(seconds: 5),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Speech recognition not available. Please check microphone permissions.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } else {
                        setDialogState(() {
                          _isListening = false;
                        });
                        setState(() {
                          _isListening = false;
                        });
                        _speech.stop();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _isListening ? Colors.red : const Color(0xFF4A90E2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isListening ? Icons.stop : Icons.mic,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isListening ? 'Listening...' : 'Tap microphone to start',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_transcribedText.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1419),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _transcribedText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Example: "Add 500 dirhams to cash for groceries"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (_isListening) {
                      _speech.stop();
                      setState(() {
                        _isListening = false;
                      });
                    }
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                if (_transcribedText.isNotEmpty && !_isListening)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Process the transcribed text and create transaction
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Processing: $_transcribedText'),
                          backgroundColor: const Color(0xFF4A90E2),
                        ),
                      );
                    },
                    child: const Text(
                      'Process',
                      style: TextStyle(color: Color(0xFF4A90E2)),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _showManualTextInputDialog(BuildContext context) {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E2A3A),
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
                    borderSide: BorderSide(color: Color(0xFF4A90E2)),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Text(
                'Note: Voice recognition will work properly on mobile devices',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Processing: ${textController.text}'),
                      backgroundColor: const Color(0xFF4A90E2),
                    ),
                  );
                  // TODO: Process the text and create transaction
                }
              },
              child: const Text(
                'Process',
                style: TextStyle(color: Color(0xFF4A90E2)),
              ),
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
              backgroundColor: const Color(0xFF1E2A3A),
              title: const Text(
                'Add Transaction',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                isIncome = true;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isIncome
                                    ? Colors.green
                                    : const Color(0xFF0F1419),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isIncome ? Colors.green : Colors.white38,
                                ),
                              ),
                              child: const Text(
                                '+ In',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                isIncome = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: !isIncome
                                    ? Colors.red
                                    : const Color(0xFF0F1419),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: !isIncome ? Colors.red : Colors.white38,
                                ),
                              ),
                              child: const Text(
                                '- Out',
                                textAlign: TextAlign.center,
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
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white38),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF4A90E2)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white38),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF4A90E2)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    if (amountController.text.isNotEmpty && 
                        selectedAccount != null && 
                        selectedAccount!.id != null) {
                      final amount = double.parse(amountController.text);
                      final finalAmount = isIncome ? amount : -amount;
                      
                      final transaction = AppTransaction(
                        transactionId: DateTime.now().millisecondsSinceEpoch.toString(),
                        accountId: selectedAccount!.id!,
                        amount: finalAmount,
                        date: selectedDate,
                        description: descriptionController.text.isEmpty
                            ? null
                            : descriptionController.text,
                      );
                      
                      await _databaseService.insertTransaction(transaction);
                      Navigator.pop(context);
                      _loadData();
                    }
                  },
                  child: const Text(
                    'Add',
                    style: TextStyle(color: Color(0xFF4A90E2)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A3A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
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
      onTap: () {
        if (label == 'Dashboard') {
          Navigator.pop(context);
        } else if (label == 'Accounts') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AccountsScreen()),
          );
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
}