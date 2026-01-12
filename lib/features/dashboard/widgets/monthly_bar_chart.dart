import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MonthlyBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> monthlyTrend;
  final bool isLoading;

  const MonthlyBarChart({
    super.key,
    required this.monthlyTrend,
    this.isLoading = false,
  });

  double _getMaxYValue() {
    if (monthlyTrend.isEmpty) return 10000;

    double max = 0;
    for (var month in monthlyTrend) {
      final income = (month['income'] as num).toDouble();
      final expense = (month['expense'] as num).toDouble();
      if (income > max) max = income;
      if (expense > max) max = expense;
    }

    return max * 1.2; // Add 20% padding
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(monthlyTrend.length, (index) {
      final monthData = monthlyTrend[index];
      final income = (monthData['income'] as num).toDouble();
      final expense = (monthData['expense'] as num).toDouble();

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: income,
            color: Colors.green[400],
            width: 12,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: expense,
            color: Colors.red[400],
            width: 12,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
        barsSpace: 4,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Income vs Expense',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              SizedBox(
                height: 300,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue[400]!,
                    ),
                  ),
                ),
              )
            else if (monthlyTrend.isEmpty)
              SizedBox(
                height: 60,
                child: Center(
                  child: Text(
                    'No transactions yet. Add data to see the trend.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              SizedBox(
                height: 300,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxYValue(),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => Colors.grey[800]!,
                        tooltipBorderRadius: const BorderRadius.all(
                          Radius.circular(8),
                        ),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final isIncome = rodIndex == 0;
                          return BarTooltipItem(
                            '${isIncome ? 'Income' : 'Expense'}: ৳${rod.toY.toStringAsFixed(0)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < monthlyTrend.length) {
                              return Text(
                                monthlyTrend[index]['month'],
                                style: const TextStyle(fontSize: 10),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '৳${(value / 1000).toStringAsFixed(0)}K',
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: _buildBarGroups(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
