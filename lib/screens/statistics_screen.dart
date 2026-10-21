import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/category_model.dart';
import '../providers/expense_provider.dart';
import '../widgets/charts/custom_pie_chart.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isDonutMode = true;
  int? _selectedCategoryIndex;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final total = provider.totalSpend;
    final chartData = provider.donutChartData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân tích Chi tiêu'),
        actions: [
          IconButton(
            icon: Icon(
              _isDonutMode ? Icons.pie_chart_outline : Icons.donut_large,
              color: AppColors.primary,
            ),
            tooltip: _isDonutMode
                ? 'Chuyển sang Pie Chart'
                : 'Chuyển sang Donut Chart',
            onPressed: () {
              setState(() => _isDonutMode = !_isDonutMode);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Time Filter Segmented Control
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildFilterTab(provider, TimeFilter.week, 'Tuần này'),
                _buildFilterTab(provider, TimeFilter.month, 'Tháng này'),
                _buildFilterTab(provider, TimeFilter.year, 'Năm nay'),
                _buildFilterTab(provider, TimeFilter.all, 'Tất cả'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // CustomPainter Chart Container
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 8,
                    children: [
                      Text(
                        _isDonutMode
                            ? 'Biểu đồ Bánh vòng (Donut)'
                            : 'Biểu đồ Tròn (Pie)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Canvas CustomPainter',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Chart View
                  Center(
                    child: CustomDonutChart(
                      data: chartData,
                      totalAmount: total,
                      isDonut: _isDonutMode,
                      size: 240,
                      onSegmentSelected: (index) {
                        setState(() => _selectedCategoryIndex = index);
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'Chạm vào từng phần để xem chi tiết danh mục',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Category Breakdown Header
          const Text(
            'Chi tiết theo danh mục',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Category Breakdown List
          if (chartData.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Chưa có chi tiêu trong khoảng thời gian này'),
              ),
            )
          else
            ...chartData.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = _selectedCategoryIndex == index;
              final percentage = total > 0 ? (item.value / total) * 100 : 0.0;
              final category = CategoryModel.findById(item.categoryId);
              final formatter = NumberFormat('#,###', 'vi_VN');

              return Card(
                color: isSelected
                    ? item.color.withValues(alpha: 0.08)
                    : Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isSelected
                        ? item.color
                        : Theme.of(context).colorScheme.outlineVariant,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              category.icon,
                              color: item.color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${percentage.toStringAsFixed(1)}% ngân sách',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${formatter.format(item.value.round())} ₫',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: total > 0 ? (item.value / total) : 0,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(item.color),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFilterTab(
    ExpenseProvider provider,
    TimeFilter filter,
    String label,
  ) {
    final isSelected = provider.timeFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setTimeFilter(filter),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.surface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? AppColors.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
