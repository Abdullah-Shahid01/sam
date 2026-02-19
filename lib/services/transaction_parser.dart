// lib/services/transaction_parser.dart

import '../models/parsed_transaction.dart';
import '../models/account.dart';

/// Service for parsing natural language into transaction details
class TransactionParser {
  // Keywords that indicate money coming in
  static const List<String> _inflowKeywords = [
    'add', 'added', 'received', 'got', 'deposit', 'deposited',
    'income', 'earned', 'earn', 'credit', 'credited',
    'receive', 'gain', 'gained', 'plus', 'in', 'into',
  ];

  // Keywords that indicate money going out
  static const List<String> _outflowKeywords = [
    'spent', 'spend', 'paid', 'pay', 'bought', 'buy',
    'expense', 'withdraw', 'withdrew', 'withdrawal',
    'debit', 'debited', 'minus', 'out', 'from', 'lost',
    'cost', 'purchase', 'purchased',
  ];

  // Date-related keywords
  static const Map<String, int> _relativeDays = {
    'today': 0,
    'yesterday': -1,
    'day before yesterday': -2,
  };

  // Category keywords
  static const Map<String, List<String>> _categoryKeywords = {
    'Food': ['food', 'burger', 'pizza', 'restaurant', 'lunch', 'dinner', 'breakfast', 'groceries', 'supermarket', 'kfc', 'mcdonalds', 'starbucks', 'coffee', 'cafe', 'snack', 'drink'],
    'Transport': ['transport', 'uber', 'taxi', 'bus', 'metro', 'fuel', 'petrol', 'gas', 'parking', 'careem', 'train', 'ticket'],
    'Utilities': ['utilities', 'utility', 'dewa', 'etisalat', 'du', 'internet', 'phone', 'bill', 'electricity', 'water', 'wifi', 'mobile'],
    'Rent': ['rent', 'housing', 'apartment'],
    'Salary': ['salary', 'wages', 'paycheck', 'income'],
    'Shopping': ['shopping', 'amazon', 'noon', 'clothes', 'shoes', 'mall', 'gift'],
    'Entertainment': ['entertainment', 'movie', 'cinema', 'netflix', 'game', 'fun', 'subscription'],
    'Health': ['health', 'doctor', 'pharmacy', 'medicine', 'gym', 'hospital'],
  };

  /// Parse spoken text into transaction details
  /// [text] is the transcribed speech
  /// [availableAccounts] is the list of accounts to match against
  ParsedTransaction parse(String text, List<Account> availableAccounts, {Account? defaultAccount}) {
    final lowerText = text.toLowerCase().trim();
    
    double confidence = 0.0;

    // Extract amount
    final amount = _extractAmount(lowerText);

    // Determine inflow or outflow
    final isInflow = _determineFlowType(lowerText);

    // Match account
    String? accountName = _matchAccount(lowerText, availableAccounts);
    if (accountName == null && defaultAccount != null) {
      accountName = defaultAccount.name;
    }

    // Extract date
    final date = _extractDate(lowerText);

    // Extract Category
    final category = _extractCategory(lowerText);
    // Auto-set isFixed for certain categories
    final isFixed = category == 'Rent' || category == 'Utilities'; // Simple heuristic

    // Calculate confidence based on matches
    // Amount is most important, then flow type, then account
    if (amount != null) confidence += 0.4;
    if (isInflow != null) confidence += 0.25;
    if (accountName != null) confidence += 0.25;
    if (date != null) confidence += 0.1;

    return ParsedTransaction(
      amount: amount,
      accountName: accountName,
      isInflow: isInflow,
      date: date ?? DateTime.now(),
      description: text,
      category: category ?? 'Uncategorized',
      isFixed: isFixed,
      confidence: confidence,
      rawText: text,
    );
  }

  /// Extract category based on keywords
  String? _extractCategory(String text) {
    for (final entry in _categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (text.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return null;
  }

  /// Extract numeric amount from text
  double? _extractAmount(String text) {
    // Try to find numbers in the text
    // Match patterns like: 500, 1000, 1,000, 1000.50, $500, AED 500
    final patterns = [
      // Currency with amount: $500, AED 500, etc.
      RegExp(r'(?:[$£€¥]|aed|usd|inr|pkr)\s*(\d+(?:,\d{3})*(?:\.\d{1,2})?)', caseSensitive: false),
      // Amount with currency: 500 AED, etc.
      RegExp(r'(\d+(?:,\d{3})*(?:\.\d{1,2})?)\s*(?:[$£€¥]|aed|usd|inr|pkr|dollars?|dirhams?|rupees?)', caseSensitive: false),
      // Plain numbers
      RegExp(r'(\d+(?:,\d{3})*(?:\.\d{1,2})?)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final numStr = match.group(1)!.replaceAll(',', '');
        final value = double.tryParse(numStr);
        if (value != null && value > 0) {
          return value;
        }
      }
    }

    // Try to parse word numbers
    return _parseWordNumber(text);
  }

  /// Parse written numbers like "five hundred"
  double? _parseWordNumber(String text) {
    final wordNumbers = {
      'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4,
      'five': 5, 'six': 6, 'seven': 7, 'eight': 8, 'nine': 9,
      'ten': 10, 'eleven': 11, 'twelve': 12, 'thirteen': 13,
      'fourteen': 14, 'fifteen': 15, 'sixteen': 16, 'seventeen': 17,
      'eighteen': 18, 'nineteen': 19, 'twenty': 20, 'thirty': 30,
      'forty': 40, 'fifty': 50, 'sixty': 60, 'seventy': 70,
      'eighty': 80, 'ninety': 90,
    };

    final multipliers = {
      'hundred': 100,
      'thousand': 1000,
      'k': 1000,
      'lac': 100000,
      'lakh': 100000,
      'million': 1000000,
    };

    final words = text.split(RegExp(r'\s+'));
    double result = 0;
    double current = 0;

    for (final word in words) {
      if (wordNumbers.containsKey(word)) {
        current += wordNumbers[word]!;
      } else if (multipliers.containsKey(word)) {
        if (current == 0) current = 1;
        current *= multipliers[word]!;
        result += current;
        current = 0;
      }
    }

    result += current;
    return result > 0 ? result : null;
  }

  /// Determine if the transaction is inflow or outflow
  bool? _determineFlowType(String text) {
    final words = text.split(RegExp(r'\s+'));

    int inflowScore = 0;
    int outflowScore = 0;

    for (final word in words) {
      if (_inflowKeywords.contains(word)) {
        inflowScore++;
      }
      if (_outflowKeywords.contains(word)) {
        outflowScore++;
      }
    }

    if (inflowScore > outflowScore) return true;
    if (outflowScore > inflowScore) return false;
    return null; // Ambiguous
  }

  /// Match account name from available accounts
  String? _matchAccount(String text, List<Account> accounts) {
    if (accounts.isEmpty) return null;

    // Direct match first
    for (final account in accounts) {
      if (text.contains(account.name.toLowerCase())) {
        return account.name;
      }
    }

    // Fuzzy match - check if any word is similar to account name
    final words = text.split(RegExp(r'\s+'));
    for (final account in accounts) {
      final accountWords = account.name.toLowerCase().split(RegExp(r'\s+'));
      for (final word in words) {
        for (final accountWord in accountWords) {
          if (_isSimilar(word, accountWord)) {
            return account.name;
          }
        }
      }
    }

    return null;
  }

  /// Check if two strings are similar (simple edit distance check)
  bool _isSimilar(String a, String b) {
    if (a == b) return true;
    if (a.length < 3 || b.length < 3) return false;
    
    // Check if one contains the other
    if (a.contains(b) || b.contains(a)) return true;

    // Check if they share a significant prefix
    final minLen = a.length < b.length ? a.length : b.length;
    int matchingChars = 0;
    for (int i = 0; i < minLen; i++) {
      if (a[i] == b[i]) {
        matchingChars++;
      } else {
        break;
      }
    }

    return matchingChars >= minLen * 0.7;
  }

  /// Extract date from text
  DateTime? _extractDate(String text) {
    // Check for relative dates
    for (final entry in _relativeDays.entries) {
      if (text.contains(entry.key)) {
        return DateTime.now().add(Duration(days: entry.value));
      }
    }

    // Check for day names
    final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    for (int i = 0; i < dayNames.length; i++) {
      if (text.contains(dayNames[i])) {
        // Find the most recent occurrence of that day
        final now = DateTime.now();
        final currentWeekday = now.weekday;
        final targetWeekday = i + 1; // DateTime weekday is 1-7
        
        int daysAgo = currentWeekday - targetWeekday;
        if (daysAgo <= 0) daysAgo += 7;
        
        return now.subtract(Duration(days: daysAgo));
      }
    }
    
    // Check for "on [Day] [Month]" format (e.g. "on 5th of November" or "on 5 November")
    // Simple regex for "d/dd Month"
    final monthNames = {
      'january': 1, 'february': 2, 'march': 3, 'april': 4, 'may': 5, 'june': 6,
      'july': 7, 'august': 8, 'september': 9, 'october': 10, 'november': 11, 'december': 12,
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'jun': 6, 'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
    };
    
    // Pattern: number (st/nd/rd/th)? (of)? month
    final datePattern = RegExp(r'(\d{1,2})(?:st|nd|rd|th)?\s+(?:of\s+)?([a-z]+)');
    final matches = datePattern.allMatches(text);
    
    for (final match in matches) {
      final dayStr = match.group(1);
      final monthStr = match.group(2)?.toLowerCase();
      
      if (dayStr != null && monthNames.containsKey(monthStr)) {
        final day = int.parse(dayStr);
        final month = monthNames[monthStr]!;
        final now = DateTime.now();
        // Assume current year unless it puts date in future, then past year? 
        // Or assume past logic? "on 5th November" usually means the last one.
        
        DateTime candidate = DateTime(now.year, month, day);
        if (candidate.isAfter(now)) {
          candidate = DateTime(now.year - 1, month, day);
        }
        return candidate;
      }
    }

    return null; // Default to today in the caller
  }
}
