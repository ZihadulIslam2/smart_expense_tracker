import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CategoryPieChart extends StatelessWidget {
  final Map<String, double> categorySpending;
  final bool isLoading;

  const CategoryPieChart({
    super.key,
    required this.categorySpending,
    this.isLoading = false,
  });

  List<PieChartSectionData> _buildPieSections() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
      Colors.pink,
      Colors.indigo,
    ];

    final total = categorySpending.values.fold(
      0.0,
      (sum, amount) => sum + amount,
    );

    List<PieChartSectionData> sections = [];
    int colorIndex = 0;

    categorySpending.forEach((category, amount) {
      final percentage = (amount / total) * 100;

      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: amount,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 100,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );

      colorIndex++;
    });

    return sections;
  }

  Widget _buildCategoryLegend() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
      Colors.pink,
      Colors.indigo,
    ];

    List<String> categories = categorySpending.keys.toList();
    int colorIndex = 0;

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: categories.map((category) {
        final color = colors[colorIndex % colors.length];
        final amount = categorySpending[category]!;
        colorIndex++;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$category: ৳${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
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
              'Spending by Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              SizedBox(
                height: 250,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue[400]!,
                    ),
                  ),
                ),
              )
            else if (categorySpending.isEmpty)
              SizedBox(
                height: 60,
                child: Center(
                  child: Text(
                    'No expense data yet. Add expenses to see the chart.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else ...[
              SizedBox(
                height: 250,
                child: PieChart(
                  PieChartData(
                    sections: _buildPieSections(),
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildCategoryLegend(),
            ],
          ],
        ),
      ),
    );
  }
}
