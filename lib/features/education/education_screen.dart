import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Financial Literacy')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        children: [
          // Introduction Card
          _buildIntroCard(),
          const SizedBox(height: AppTheme.spacingM),

          // Budgeting Section
          _buildSectionCard(
            icon: Icons.account_balance_wallet,
            iconColor: AppTheme.primaryColor,
            title: 'Budgeting Basics',
            articles: [
              _ArticleData(
                title: '50/30/20 Rule',
                subtitle: 'Simple budgeting framework',
                content: '''
The 50/30/20 rule is a simple budgeting method that divides your after-tax income into three categories:

• 50% for Needs: Essential expenses like rent, groceries, utilities, insurance, and minimum debt payments.

• 30% for Wants: Non-essential spending like dining out, entertainment, hobbies, and subscriptions.

• 20% for Savings: Emergency fund, retirement contributions, debt repayment beyond minimums, and investments.

This framework helps you maintain a balanced financial life while building wealth over time.
''',
              ),
              _ArticleData(
                title: 'Zero-Based Budgeting',
                subtitle: 'Every dollar has a purpose',
                content: '''
Zero-based budgeting means assigning every dollar of your income to a specific category until you have zero left to budget.

Steps to create a zero-based budget:
1. Calculate your monthly income
2. List all expenses (fixed and variable)
3. Assign money to each category
4. Adjust until income minus expenses equals zero

This method ensures you're intentional with every dollar and helps identify unnecessary spending.
''',
              ),
              _ArticleData(
                title: 'Track Your Spending',
                subtitle: 'Awareness is the first step',
                content: '''
Tracking your spending is crucial for financial success:

• Reveals spending patterns you might not notice
• Helps identify areas where you can cut back
• Keeps you accountable to your budget
• Prevents lifestyle inflation

Use this app to track every transaction, no matter how small. Review your spending weekly and adjust as needed.
''',
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),

          // Saving Strategies Section
          _buildSectionCard(
            icon: Icons.savings,
            iconColor: AppTheme.accentColor,
            title: 'Saving Strategies',
            articles: [
              _ArticleData(
                title: 'Emergency Fund',
                subtitle: 'Your financial safety net',
                content: '''
An emergency fund is money set aside to cover unexpected expenses or financial emergencies.

How much to save:
• Beginner: \$1,000 as a starter emergency fund
• Intermediate: 3 months of expenses
• Advanced: 6-12 months of expenses

Where to keep it:
• High-yield savings account
• Money market account
• Easily accessible but separate from checking

Start small if needed - even \$25/month adds up over time!
''',
              ),
              _ArticleData(
                title: 'Pay Yourself First',
                subtitle: 'Automate your savings',
                content: '''
"Pay yourself first" means saving money before spending on anything else.

How to implement:
1. Set up automatic transfers to savings on payday
2. Treat savings like a bill you must pay
3. Start with 10% of income, increase gradually
4. Don't wait until "there's money left over"

This simple strategy ensures you consistently build wealth regardless of spending temptations.
''',
              ),
              _ArticleData(
                title: 'Reduce Unnecessary Expenses',
                subtitle: 'Find money to save',
                content: '''
Small cuts in daily spending can lead to big savings:

• Coffee: Make at home, save \$5/day = \$1,825/year
• Subscriptions: Cancel unused services
• Dining out: Cook more meals at home
• Shopping: Use 24-hour rule for non-essentials
• Insurance: Shop around annually
• Phone/Internet: Negotiate better rates

Challenge: Find 3 expenses to reduce this month and redirect that money to savings!
''',
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),

          // Debt Management Section
          _buildSectionCard(
            icon: Icons.trending_down,
            iconColor: AppTheme.errorColor,
            title: 'Debt Management',
            articles: [
              _ArticleData(
                title: 'Debt Avalanche vs Snowball',
                subtitle: 'Two proven payoff methods',
                content: '''
Debt Avalanche Method:
• Pay minimums on all debts
• Put extra money toward highest interest rate debt
• Saves more money in interest
• Best for logical, math-focused people

Debt Snowball Method:
• Pay minimums on all debts
• Put extra money toward smallest balance
• Quick wins boost motivation
• Best for those needing psychological wins

Choose the method that keeps you motivated to stick with it!
''',
              ),
              _ArticleData(
                title: 'Good Debt vs Bad Debt',
                subtitle: 'Not all debt is equal',
                content: '''
Good Debt:
• Low interest rates
• Builds wealth or assets
• Examples: mortgage, student loans, business loans
• Has potential for positive ROI

Bad Debt:
• High interest rates (>10%)
• Depreciating assets
• Examples: credit card debt, payday loans, car loans
• No wealth-building potential

Focus on eliminating bad debt first while managing good debt responsibly.
''',
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),

          // Investment Basics Section
          _buildSectionCard(
            icon: Icons.show_chart,
            iconColor: AppTheme.warningColor,
            title: 'Investment Basics',
            articles: [
              _ArticleData(
                title: 'Start Early, Benefit from Compound Interest',
                subtitle: 'Time is your best asset',
                content: '''
Compound interest is earning interest on your interest. The earlier you start, the more your money grows.

Example:
• \$100/month from age 25-65 at 7% = \$264,012
• \$100/month from age 35-65 at 7% = \$122,709
• Difference: \$141,303 (only 10 years difference!)

Key takeaways:
• Start investing as early as possible
• Consistency matters more than amount
• Let time do the heavy lifting
• Don't try to time the market
''',
              ),
              _ArticleData(
                title: 'Diversification',
                subtitle: 'Don\'t put all eggs in one basket',
                content: '''
Diversification means spreading investments across different assets to reduce risk.

Why diversify:
• Reduces impact of any single investment failing
• Balances risk and reward
• Smooths out portfolio volatility
• Protects against market downturns

How to diversify:
• Different asset classes (stocks, bonds, real estate)
• Different sectors (tech, healthcare, finance)
• Different geographies (domestic, international)
• Index funds for instant diversification
''',
              ),
              _ArticleData(
                title: 'Risk vs Reward',
                subtitle: 'Understanding your tolerance',
                content: '''
Every investment has trade-offs between risk and potential reward:

Low Risk, Low Reward:
• Savings accounts, CDs, bonds
• Safe but slow growth
• Good for short-term goals

Medium Risk, Medium Reward:
• Index funds, balanced portfolios
• Moderate volatility
• Good for long-term wealth building

High Risk, High Reward:
• Individual stocks, cryptocurrencies
• High volatility
• Only for money you can afford to lose

Match investments to your goals, timeline, and comfort level with risk.
''',
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),

          // Financial Goals Section
          _buildSectionCard(
            icon: Icons.flag,
            iconColor: AppTheme.successColor,
            title: 'Setting Financial Goals',
            articles: [
              _ArticleData(
                title: 'SMART Goals',
                subtitle: 'Make goals achievable',
                content: '''
Make your financial goals SMART:

Specific: "Save \$10,000" not "Save more money"
Measurable: Track progress with numbers
Achievable: Realistic given your income/expenses
Relevant: Aligns with your life priorities
Time-bound: Set a deadline

Example:
"I will save \$10,000 for a house down payment by saving \$400/month for 25 months by reducing dining out and entertainment expenses."
''',
              ),
              _ArticleData(
                title: 'Short, Medium, and Long-Term Goals',
                subtitle: 'Balance different timeframes',
                content: '''
Short-term (1 year):
• Emergency fund
• Vacation
• Small purchases
• Strategy: Savings account

Medium-term (1-5 years):
• House down payment
• Car purchase
• Wedding
• Strategy: Conservative investments

Long-term (5+ years):
• Retirement
• Children's education
• Financial independence
• Strategy: Aggressive investments

Balance all three for complete financial health.
''',
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Card(
      color: AppTheme.primaryLight.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          children: [
            Icon(Icons.school, size: 48, color: AppTheme.primaryColor),
            const SizedBox(height: AppTheme.spacingM),
            const Text(
              'Welcome to Financial Literacy',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingS),
            const Text(
              'Learn essential money management skills to build a secure financial future. Tap any topic below to expand and read more.',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<_ArticleData> articles,
  }) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingS),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...articles.map((article) => _ArticleExpansionTile(article: article)),
        ],
      ),
    );
  }
}

class _ArticleData {
  final String title;
  final String subtitle;
  final String content;

  _ArticleData({
    required this.title,
    required this.subtitle,
    required this.content,
  });
}

class _ArticleExpansionTile extends StatelessWidget {
  final _ArticleData article;

  const _ArticleExpansionTile({required this.article});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      childrenPadding: const EdgeInsets.all(AppTheme.spacingM),
      title: Text(
        article.title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        article.subtitle,
        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          child: Text(
            article.content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
