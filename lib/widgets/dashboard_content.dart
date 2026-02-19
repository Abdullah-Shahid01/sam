// lib/widgets/dashboard_content.dart

import 'package:flutter/material.dart';
import '../models/account.dart';

class DashboardContent extends StatelessWidget {
  final List<Account> accounts;

  const DashboardContent({super.key, required this.accounts});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 32),
        if (accounts.isEmpty)
          Center(
            child: Column(
              children: [
                const SizedBox(height: 60),
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 64,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No accounts yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create your first account to get started',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          )
        else
          _buildAccountsGrid(),
      ],
    );
  }

  Widget _buildAccountsGrid() {
    if (accounts.length <= 2) {
      return Row(
        children: [
          for (int i = 0; i < accounts.length; i++) ...[
            Expanded(child: _buildAccountCard(accounts[i], i)),
            if (i < accounts.length - 1) const SizedBox(width: 16),
          ],
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildAccountCard(accounts[0], 0)),
              const SizedBox(width: 16),
              Expanded(child: _buildAccountCard(accounts[1], 1)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (accounts.length > 2)
                Expanded(child: _buildAccountCard(accounts[2], 2)),
              if (accounts.length > 3) ...[
                const SizedBox(width: 16),
                Expanded(child: _buildAccountCard(accounts[3], 3)),
              ],
            ],
          ),
        ],
      );
    }
  }

  Widget _buildAccountCard(Account account, int index) {
    final gradients = [
      const LinearGradient(
        colors: [Color(0xFF6C5CE7), Color(0xFF5F4DD1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFF00B894), Color(0xFF00A383)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFFFF6B9D), Color(0xFFF06595)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFFFD79A8), Color(0xFFF8A5C2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ];

    final icons = [
      Icons.account_balance_wallet,
      Icons.account_balance,
      Icons.credit_card,
      Icons.receipt_long,
    ];

    final gradient = gradients[index % gradients.length];
    final icon = _getIconForAccountType(account.type, icons[index % icons.length]);
    final shadowColor = gradient.colors.first;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            account.name,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'AED ${account.balance.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForAccountType(AccountType type, IconData defaultIcon) {
    switch (type) {
      case AccountType.asset:
        return Icons.account_balance_wallet;
      case AccountType.liability:
        return Icons.credit_card;
    }
  }
}