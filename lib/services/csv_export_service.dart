
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/transaction.dart';
import '../models/account.dart'; // Assuming we might need account lookup if we only have ID, but AppTransaction has accountId. 
// Ideally we should pass accounts map or join it, but for now let's just export what we have.

class CsvExportService {
  
  String generateCsv(List<AppTransaction> transactions, {List<Account>? accounts}) {
    // Header
    final buffer = StringBuffer();
    buffer.writeln('Date,Amount,Category,Description,Account,Type');

    // Account Map for easier lookup
    final Map<int, String> accountNames = {};
    if (accounts != null) {
      for (var a in accounts) {
        if (a.id != null) accountNames[a.id!] = a.name;
      }
    }

    // Rows
    for (var tx in transactions) {
      final date = DateFormat('yyyy-MM-dd HH:mm').format(tx.date);
      final amount = tx.amount.toStringAsFixed(2);
      final category = _escape(tx.category ?? 'Uncategorized');
      final description = _escape(tx.description ?? '');
      final accountName = _escape(accountNames[tx.accountId] ?? 'Account ${tx.accountId}');
      final type = tx.amount < 0 ? 'Expense' : 'Income';

      buffer.writeln('$date,$amount,$category,$description,$accountName,$type');
    }

    return buffer.toString();
  }

  String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  Future<void> exportCsv(BuildContext context, List<AppTransaction> transactions, {List<Account>? accounts}) async {
    try {
      final csvData = generateCsv(transactions, accounts: accounts);
      final fileName = 'sam_report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Desktop: Use FilePicker to save
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Report CSV',
          fileName: fileName,
          allowedExtensions: ['csv'],
          type: FileType.custom,
        );

        if (outputFile != null) {
           final file = File(outputFile);
           await file.writeAsString(csvData);
           _showSnack(context, 'Report saved to $outputFile');
        }
      } else {
        // Mobile: Save to Downloads folder (visible in Files app)
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          // Fallback to app documents dir
          final directory = await getApplicationDocumentsDirectory();
          final path = '${directory.path}/$fileName';
          final file = File(path);
          await file.writeAsString(csvData);
          _showSnack(context, 'Report saved to $path');
        } else {
          final path = '${downloadsDir.path}/$fileName';
          final file = File(path);
          await file.writeAsString(csvData);
          _showSnack(context, 'Report saved to Downloads 📁');
        }
      }
    } catch (e) {
      _showSnack(context, 'Error exporting CSV: $e', isError: true);
    }
  }

  void _showSnack(BuildContext context, String message, {bool isError = false}) {
    if (!context.mounted) return; // Check if mounted before showing snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF4A90E2),
      ),
    );
  }
}
