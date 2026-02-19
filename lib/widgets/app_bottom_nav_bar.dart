
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../screens/accounts_screen.dart';
import '../screens/transactions_screen.dart';
import '../screens/reports_screen.dart';

class AppBottomNavBar extends StatefulWidget {
  final String currentLabel;
  final VoidCallback? onNavigateBack;

  const AppBottomNavBar({
    super.key,
    required this.currentLabel,
    this.onNavigateBack,
  });

  @override
  State<AppBottomNavBar> createState() => _AppBottomNavBarState();
}

class _AppBottomNavBarState extends State<AppBottomNavBar> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
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
              Expanded(child: _buildNavItem(context, Icons.dashboard_outlined, 'Dashboard')),
              Expanded(child: _buildNavItem(context, Icons.account_balance_wallet_outlined, 'Accounts')),
              Expanded(child: _buildNavItem(context, Icons.receipt_long_outlined, 'Transactions')),
              Expanded(child: _buildNavItem(context, Icons.pie_chart_outline, 'Reports')),
              Expanded(child: _buildNavItem(context, Icons.settings_outlined, 'Settings')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label) {
    final bool isActive = widget.currentLabel == label;
    final Color color = isActive ? AppTheme.primaryColor : Colors.white;
    final FontWeight weight = isActive ? FontWeight.bold : FontWeight.normal;

    return GestureDetector(
      onTap: () => _handleNavigation(context, label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color, fontWeight: weight),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
              textScaler: const TextScaler.linear(1.0),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, String targetLabel) {
    if (targetLabel == widget.currentLabel) return;
    if (_isNavigating) return; // Prevent double-tap

    setState(() => _isNavigating = true);

    if (targetLabel == 'Dashboard') {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return; // Widget will be disposed, no need to reset _isNavigating
    }

    if (targetLabel == 'Settings') {
      setState(() => _isNavigating = false);
      return;
    }

    Widget screen;
    switch (targetLabel) {
      case 'Accounts':
        screen = const AccountsScreen();
        break;
      case 'Transactions':
        screen = const TransactionsScreen();
        break;
      case 'Reports':
        screen = const ReportsScreen();
        break;
      default:
        setState(() => _isNavigating = false);
        return;
    }

    if (widget.currentLabel == 'Dashboard') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      ).then((_) {
        if (mounted) {
          setState(() => _isNavigating = false);
        }
        widget.onNavigateBack?.call();
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    }
  }
}
