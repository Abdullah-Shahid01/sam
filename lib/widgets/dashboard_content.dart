// lib/widgets/dashboard_content.dart

import 'package:flutter/material.dart';

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

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
        Row(
          children: [
            Expanded(
              child: _buildAccountCard(
                context,
                title: 'Cash',
                amount: 'AED 2,500',
                icon: Icons.account_balance_wallet,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFF5F4DD1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shadowColor: const Color(0xFF6C5CE7),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAccountCard(
                context,
                title: 'Bank Balance',
                amount: 'AED 5,000',
                icon: Icons.account_balance,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00B894), Color(0xFF00A383)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shadowColor: const Color(0xFF00B894),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildAccountCard(
                context,
                title: 'Credit Card',
                amount: 'AED 1,250',
                icon: Icons.credit_card,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B9D), Color(0xFFF06595)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shadowColor: const Color(0xFFFF6B9D),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAccountCard(
                context,
                title: 'Receivables',
                amount: 'AED 2,700',
                icon: Icons.receipt_long,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFD79A8), Color(0xFFF8A5C2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shadowColor: const Color(0xFFFD79A8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountCard(
    BuildContext context, {
    required String title,
    required String amount,
    required IconData icon,
    required LinearGradient gradient,
    required Color shadowColor,
  }) {
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
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
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
}