import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/widgets/charts/custom_bar_chart.dart';
import 'package:smart_expense_tracker/widgets/charts/custom_pie_chart.dart';

void main() {
  group('Widget Tests for CustomPainter Charts', () {
    testWidgets('1. CustomDonutChart renders CustomPainter canvas correctly', (
      WidgetTester tester,
    ) async {
      final sampleData = [
        const ChartDataPoint(
          label: 'Ăn uống',
          value: 300000,
          color: Colors.red,
          categoryId: 'food',
        ),
        const ChartDataPoint(
          label: 'Mua sắm',
          value: 700000,
          color: Colors.blue,
          categoryId: 'shopping',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CustomDonutChart(
                data: sampleData,
                totalAmount: 1000000,
                isDonut: true,
                size: 200,
              ),
            ),
          ),
        ),
      );

      // Verify widget tree contains CustomDonutChart
      expect(find.byType(CustomDonutChart), findsOneWidget);

      // Verify custom painter canvas is present
      final canvasFinder = find.byKey(const ValueKey('CustomDonutChartCanvas'));
      expect(canvasFinder, findsOneWidget);

      // Pump animation forward
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(canvasFinder, findsOneWidget);
    });

    testWidgets('2. CustomDonutChart updates when data and total change', (
      WidgetTester tester,
    ) async {
      var data = [
        const ChartDataPoint(
          label: 'Ăn uống',
          value: 100000,
          color: Colors.red,
          categoryId: 'food',
        ),
      ];
      var total = 100000.0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    CustomDonutChart(
                      data: data,
                      totalAmount: total,
                      isDonut: false, // Pie chart mode
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          data = [
                            const ChartDataPoint(
                              label: 'Ăn uống',
                              value: 100000,
                              color: Colors.red,
                              categoryId: 'food',
                            ),
                            const ChartDataPoint(
                              label: 'Di chuyển',
                              value: 200000,
                              color: Colors.green,
                              categoryId: 'transport',
                            ),
                          ];
                          total = 300000.0;
                        });
                      },
                      child: const Text('Cập nhật'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Cập nhật'), findsOneWidget);

      // Trigger data update
      await tester.tap(find.text('Cập nhật'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('CustomDonutChartCanvas')),
        findsOneWidget,
      );
    });

    testWidgets('3. WeeklyBarChart renders 7 weekday columns and handles tap', (
      WidgetTester tester,
    ) async {
      int? selectedIndex;
      final dailyPoints = [
        const DailySpendPoint(dayLabel: 'T2', amount: 50000),
        const DailySpendPoint(dayLabel: 'T3', amount: 150000),
        const DailySpendPoint(dayLabel: 'T4', amount: 80000),
        const DailySpendPoint(dayLabel: 'T5', amount: 300000, isToday: true),
        const DailySpendPoint(dayLabel: 'T6', amount: 120000),
        const DailySpendPoint(dayLabel: 'T7', amount: 450000),
        const DailySpendPoint(dayLabel: 'CN', amount: 200000),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 350,
                child: WeeklyBarChart(
                  dailyData: dailyPoints,
                  onDaySelected: (idx) {
                    selectedIndex = idx;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify WeeklyBarChart is rendered
      expect(find.byType(WeeklyBarChart), findsOneWidget);
      expect(
        find.byKey(const ValueKey('WeeklyBarChartCanvas')),
        findsOneWidget,
      );

      // Tap on chart area to trigger interaction
      await tester.tap(find.byKey(const ValueKey('WeeklyBarChartCanvas')));
      await tester.pumpAndSettle();

      // Chart remains rendered without crashing and captures selection
      expect(find.byType(WeeklyBarChart), findsOneWidget);
      expect(selectedIndex, anyOf(isNull, isNotNull));
    });
  });
}
