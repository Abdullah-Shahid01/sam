// lib/widgets/voice_input_dialog.dart

import 'package:flutter/material.dart';
import '../services/voice_service.dart';
import '../services/transaction_parser.dart';
import '../services/database_service.dart';
import '../models/parsed_transaction.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';

/// Dialog for voice input transaction creation
class VoiceInputDialog extends StatefulWidget {
  final List<Account> accounts;
  final VoidCallback? onTransactionAdded;

  const VoiceInputDialog({
    super.key,
    required this.accounts,
    this.onTransactionAdded,
  });

  @override
  State<VoiceInputDialog> createState() => _VoiceInputDialogState();
}

class _VoiceInputDialogState extends State<VoiceInputDialog>
    with SingleTickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();
  final TransactionParser _parser = TransactionParser();
  final DatabaseService _databaseService = DatabaseService();

  bool _isListening = false;
  bool _isProcessing = false;
  String _transcribedText = '';
  ParsedTransaction? _parsedTransaction;
  String? _errorMessage;
  late AnimationController _pulseController;

  // Editable fields for confirmation
  Account? _selectedAccount;
  bool _isInflow = true;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _textInputController = TextEditingController(); // For manual text input
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _initializeVoice();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _amountController.dispose();
    _textInputController.dispose();
    _voiceService.stopListening();
    super.dispose();
  }

  Future<void> _initializeVoice() async {
    final available = await _voiceService.initialize();
    if (!available && mounted) {
      setState(() {
        _errorMessage = 'Speech recognition is not available on this device';
      });
    }
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _transcribedText = '';
      _parsedTransaction = null;
      _errorMessage = null;
    });

    await _voiceService.startListening(
      onResult: (text, isFinal) {
         if (mounted) {
          setState(() {
            _transcribedText = text;
          });

          if (isFinal) {
            // Auto-stop listening when we have the final result
            _voiceService.stopListening();
            setState(() {
              _isListening = false;
            });
            _processTranscription();
          }
        }
      },
      onListeningStateChanged: (isListening) {
        if (mounted) {
          setState(() {
            _isListening = isListening;
          });
          
          // Auto-process if listening stopped and we have text
          if (!isListening && _transcribedText.isNotEmpty && !_isProcessing && _parsedTransaction == null) {
            _processTranscription();
          }
        }
      },
    );
  }

  Future<void> _stopListening() async {
    await _voiceService.stopListening();
    setState(() {
      _isListening = false;
    });

    if (_transcribedText.isNotEmpty) {
      _processTranscription();
    }
  }

  void _processTranscription() {
    setState(() {
      _isProcessing = true;
    });

    final parsed = _parser.parse(_transcribedText, widget.accounts);

    setState(() {
      _parsedTransaction = parsed;
      _isProcessing = false;

      // Pre-fill editable fields
      if (parsed.amount != null) {
        _amountController.text = parsed.amount!.toStringAsFixed(2);
      }
      if (parsed.isInflow != null) {
        _isInflow = parsed.isInflow!;
      }
      if (parsed.date != null) {
        _selectedDate = parsed.date!;
      }
      if (parsed.accountName != null) {
        _selectedAccount = widget.accounts.firstWhere(
          (a) => a.name.toLowerCase() == parsed.accountName!.toLowerCase(),
          orElse: () => widget.accounts.first,
        );
      } else if (widget.accounts.isNotEmpty) {
        _selectedAccount = widget.accounts.first;
      }
    });
  }

  void _showTextInputDialog() {
    _textInputController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2A3A),
        title: const Text(
          'Type Your Input',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Type what you would say, e.g.:\n"Add 500 to cash"\n"Spent 200 from bank yesterday"',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textInputController,
              style: const TextStyle(color: Colors.white),
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Add 500 to cash...',
                hintStyle: TextStyle(color: Colors.white38),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white38),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF4A90E2)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (_textInputController.text.isNotEmpty) {
                setState(() {
                  _transcribedText = _textInputController.text;
                  _errorMessage = null;
                });
                _processTranscription();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A90E2)),
            child: const Text('Parse', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTransaction() async {
    if (_selectedAccount == null || _amountController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all required fields';
      });
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid amount';
      });
      return;
    }

    final finalAmount = _isInflow ? amount : -amount;

    final transaction = AppTransaction(
      transactionId: DateTime.now().millisecondsSinceEpoch.toString(),
      accountId: _selectedAccount!.id!,
      amount: finalAmount,
      date: _selectedDate,
      description: _transcribedText.isNotEmpty ? _transcribedText : null,
    );

    await _databaseService.insertTransaction(transaction);
    widget.onTransactionAdded?.call();

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E2A3A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Voice Input',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Microphone button
              _buildMicrophoneButton(),
              const SizedBox(height: 16),

              // Status text
              Text(
                _isListening
                    ? 'Listening...'
                    : _isProcessing
                        ? 'Processing...'
                        : _transcribedText.isEmpty
                            ? 'Tap microphone to start'
                            : 'Tap microphone to try again',
                style: const TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 8),

              // Type instead button (for testing without mic)
              TextButton.icon(
                onPressed: _showTextInputDialog,
                icon: const Icon(Icons.keyboard, size: 18, color: Color(0xFF4A90E2)),
                label: const Text(
                  'Type instead',
                  style: TextStyle(color: Color(0xFF4A90E2)),
                ),
              ),
              const SizedBox(height: 16),

              // Transcribed text
              if (_transcribedText.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1419),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'You said:',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _transcribedText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Parsed transaction form
              if (_parsedTransaction != null) ...[
                _buildTransactionForm(),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white38),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A90E2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Add Transaction',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMicrophoneButton() {
    return GestureDetector(
      onTap: _isListening ? _stopListening : _startListening,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isListening
                  ? Colors.red.withOpacity(0.2)
                  : const Color(0xFF4A90E2).withOpacity(0.2),
              boxShadow: _isListening
                  ? [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3 * _pulseController.value),
                        blurRadius: 20 + (20 * _pulseController.value),
                        spreadRadius: 5 + (5 * _pulseController.value),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening ? Colors.red : const Color(0xFF4A90E2),
                ),
                child: Icon(
                  _isListening ? Icons.stop : Icons.mic,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1419),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4A90E2).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Confidence indicator
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF4A90E2), size: 16),
              const SizedBox(width: 8),
              Text(
                'Confidence: ${(_parsedTransaction!.confidence * 100).toInt()}%',
                style: TextStyle(
                  color: _parsedTransaction!.confidence > 0.7
                      ? Colors.green
                      : _parsedTransaction!.confidence > 0.4
                          ? Colors.orange
                          : Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // In/Out toggle
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isInflow = true),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isInflow ? Colors.green : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isInflow ? Colors.green : Colors.white38,
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
                  onTap: () => setState(() => _isInflow = false),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: !_isInflow ? Colors.red : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: !_isInflow ? Colors.red : Colors.white38,
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

          // Account dropdown
          DropdownButtonFormField<Account>(
            value: _selectedAccount,
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
            items: widget.accounts.map((Account account) {
              return DropdownMenuItem<Account>(
                value: account,
                child: Text(
                  account.name,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: (Account? value) {
              setState(() => _selectedAccount = value);
            },
          ),
          const SizedBox(height: 16),

          // Amount field
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Amount',
              labelStyle: TextStyle(color: Colors.white70),
              prefixText: 'AED ',
              prefixStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white38),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF4A90E2)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Date picker
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white38),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Date',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    DateFormat('MMM dd, yyyy').format(_selectedDate),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
