import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_expense_tracker/main.dart';
import 'package:smart_expense_tracker/providers/ai_advisor_provider.dart';
import 'package:smart_expense_tracker/providers/expense_provider.dart';
import 'package:smart_expense_tracker/providers/scanner_provider.dart';

void main() {
  test('legacy Gemini API key is removed from secure storage', () async {
    FlutterSecureStorage.setMockInitialValues({
      'gemini_api_key': 'old-test-key',
    });

    final provider = AiAdvisorProvider();
    await provider.initialize();

    expect(
      await const FlutterSecureStorage().read(key: 'gemini_api_key'),
      isNull,
    );
  });

  testWidgets('SmartExpenseApp launches and displays dashboard tabs', (
    WidgetTester tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ExpenseProvider()),
          ChangeNotifierProvider(create: (_) => ScannerProvider()),
          ChangeNotifierProvider(create: (_) => AiAdvisorProvider()),
        ],
        child: const SmartExpenseApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify app title in AppBar
    expect(find.text('Smart Expense & OCR'), findsOneWidget);

    // Verify navigation tabs
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Biểu đồ'), findsOneWidget);
    expect(find.text('Trợ lý AI'), findsOneWidget);

    // Verify action buttons
    expect(find.text('Quét OCR'), findsOneWidget);
    expect(find.text('Nhập tay'), findsOneWidget);

    expect(find.byTooltip('Chuyển sang giao diện tối'), findsOneWidget);
    await tester.tap(find.byTooltip('Chuyển sang giao diện tối'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    await tester.tap(find.text('Biểu đồ'));
    await tester.pumpAndSettle();
  });
}
