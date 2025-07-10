import 'package:flutter/material.dart';
import '../../features/expenses/expense_model.dart';
import '../../shared/widgets/expense_summary_card.dart';
import '../../shared/utils/responsive.dart';
import '../../shared/widgets/responsive_layout.dart';

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
    
    return ResponsiveContainer(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Summary Cards Section
            ResponsiveSpacing(24),
            ResponsiveRowColumn(
              spacing: Responsive.adaptiveSpacing(context, 12),
              children: [
                Flexible(
                  child: ExpenseSummaryCard(
                    title: 'Today',
                    amount: todayTotal,
                    icon: Icons.attach_money,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
                Flexible(
                  child: ExpenseSummaryCard(
                    title: 'This Week',
                    amount: weekTotal,
                    icon: Icons.show_chart,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            
            ResponsiveSpacing(24),
            
            // Recent Expenses Section
            Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxWidth: Responsive.maxContentWidth(context),
              ),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(
                  Responsive.adaptiveSpacing(context, 16),
                ),
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
                    padding: EdgeInsets.all(
                      Responsive.cardPadding(context),
                    ),
                    child: Row(
                      children: [
                        ResponsiveText(
                          'Recent Expenses',
                          baseFontSize: 18,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        ResponsiveText(
                          '${expenses.length} total',
                          baseFontSize: 14,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  if (expenses.isEmpty)
                    _buildEmptyState(context, theme)
                  else
                    _buildExpensesList(context, theme),
                ],
              ),
            ),
            
            ResponsiveSpacing(16),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.all(
        Responsive.adaptiveSpacing(context, 40),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long,
              size: Responsive.responsiveIcon(context, 48),
              color: theme.colorScheme.secondary.withOpacity(0.2),
            ),
            ResponsiveSpacing(16),
            ResponsiveText(
              'No expenses logged yet',
              baseFontSize: 18,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            ResponsiveSpacing(8),
            ResponsiveText(
              'Try saying: "Coffee £3.50"',
              baseFontSize: 14,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesList(BuildContext context, ThemeData theme) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        vertical: Responsive.adaptiveSpacing(context, 8),
      ),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[expenses.length - 1 - index];
        return _buildExpenseListTile(context, theme, expense);
      },
    );
  }

  Widget _buildExpenseListTile(BuildContext context, ThemeData theme, Expense expense) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.cardPadding(context),
        vertical: 4,
      ),
      child: ResponsiveLayout(
        mobile: _buildMobileExpenseTile(context, theme, expense),
        tablet: _buildTabletExpenseTile(context, theme, expense),
        desktop: _buildDesktopExpenseTile(context, theme, expense),
      ),
    );
  }

  Widget _buildMobileExpenseTile(BuildContext context, ThemeData theme, Expense expense) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: Responsive.adaptiveSpacing(context, 12),
        vertical: Responsive.adaptiveSpacing(context, 8),
      ),
      leading: CircleAvatar(
        radius: Responsive.responsiveIcon(context, 20),
        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
        child: ResponsiveText(
          expense.category[0].toUpperCase(),
          baseFontSize: 14,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: ResponsiveText(
        expense.category,
        baseFontSize: 16,
        style: theme.textTheme.titleMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: ResponsiveText(
        '£${expense.amount.toStringAsFixed(2)}',
        baseFontSize: 16,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTabletExpenseTile(BuildContext context, ThemeData theme, Expense expense) {
    return Container(
      padding: EdgeInsets.all(Responsive.cardPadding(context)),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: Responsive.responsiveIcon(context, 24),
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: ResponsiveText(
              expense.category[0].toUpperCase(),
              baseFontSize: 16,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ResponsiveSpacing(16, direction: Axis.horizontal),
          Expanded(
            child: ResponsiveText(
              expense.category,
              baseFontSize: 18,
              style: theme.textTheme.titleMedium,
            ),
          ),
          ResponsiveText(
            '£${expense.amount.toStringAsFixed(2)}',
            baseFontSize: 18,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopExpenseTile(BuildContext context, ThemeData theme, Expense expense) {
    return Container(
      padding: EdgeInsets.all(Responsive.cardPadding(context)),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: Responsive.responsiveIcon(context, 56),
            height: Responsive.responsiveIcon(context, 56),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: ResponsiveText(
                expense.category[0].toUpperCase(),
                baseFontSize: 20,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ResponsiveSpacing(20, direction: Axis.horizontal),
          Expanded(
            child: ResponsiveText(
              expense.category,
              baseFontSize: 20,
              style: theme.textTheme.titleMedium,
            ),
          ),
          ResponsiveText(
            '£${expense.amount.toStringAsFixed(2)}',
            baseFontSize: 20,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
