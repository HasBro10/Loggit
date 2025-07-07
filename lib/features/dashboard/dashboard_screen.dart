import 'package:flutter/material.dart';
import '../../features/expenses/expense_model.dart';
import '../../shared/widgets/expense_summary_card.dart';

class DashboardScreen extends StatelessWidget {
  final List<Expense> expenses;
  const DashboardScreen({super.key, required this.expenses});

  double get totalExpenses {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double get todayTotal {
    final now = DateTime.now();
    return expenses
        .where(
          (e) =>
              e.timestamp.year == now.year &&
              e.timestamp.month == now.month &&
              e.timestamp.day == now.day,
        )
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get weekTotal {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return expenses
        .where((e) {
          final d = e.timestamp;
          return d.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
              d.isBefore(now.add(const Duration(days: 1)));
        })
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: ExpenseSummaryCard(
                    title: 'Today',
                    amount: todayTotal,
                    icon: Icons.attach_money,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ExpenseSummaryCard(
                    title: 'This Week',
                    amount: weekTotal,
                    icon: Icons.show_chart,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        Text(
                          'Recent Expenses',
                          style: theme.textTheme.titleMedium,
                        ),
                        const Spacer(),
                        Text(
                          '${expenses.length} total',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (expenses.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 48,
                              color: theme.colorScheme.secondary.withOpacity(
                                0.2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No expenses logged yet',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try saying: "Coffee £3.50"',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.secondary.withOpacity(
                                  0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final expense = expenses[expenses.length - 1 - index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary
                                .withOpacity(0.1),
                            child: Text(
                              expense.category[0].toUpperCase(),
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            expense.category,
                            style: theme.textTheme.titleMedium,
                          ),
                          trailing: Text(
                            '£${expense.amount.toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        );
                      },
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
