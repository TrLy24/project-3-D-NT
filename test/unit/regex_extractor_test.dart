import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/services/regex_extractor.dart';

void main() {
  group('HeuristicRegexExtractor Unit Tests (TDD)', () {
    test('1. Bóc tách hóa đơn chuyển khoản Vietcombank Digibank', () {
      const vcbOcrText = '''
        VIETCOMBANK VCB DIGIBANK
        GIAO DỊCH THÀNH CÔNG
        Số tiền: 150,000 VND
        Ngày thực hiện: 15/10/2026 14:25:30
        Người thụ hưởng: NGUYEN VAN A
        Nội dung: Tien an trua
        Mã giao dịch: 9283748291
      ''';

      final result = HeuristicRegexExtractor.extract(vcbOcrText);

      expect(result.amount, equals(150000.0));
      expect(result.date.day, equals(15));
      expect(result.date.month, equals(10));
      expect(result.date.year, equals(2026));
      expect(result.merchant, contains('Vietcombank'));
      expect(result.categoryId, equals('food'));
    });

    test('2. Bóc tách thông báo giao dịch Ví MoMo', () {
      const momoOcrText = '''
        Ví MoMo
        Chuyển tiền thành công
        -50,000 đ
        Số tiền: 50.000đ
        Thời gian: 20/09/2026 09:12
        Tài khoản nhận: Cà phê Phúc Long
        Mã GD: 2026092012345
      ''';

      final result = HeuristicRegexExtractor.extract(momoOcrText);

      expect(result.amount, equals(50000.0));
      expect(result.date.day, equals(20));
      expect(result.date.month, equals(9));
      expect(result.date.year, equals(2026));
      expect(result.merchant, equals('Ví MoMo'));
      expect(result.categoryId, equals('food'));
    });

    test('3. Bóc tách hóa đơn siêu thị WinMart nhiều mặt hàng', () {
      const winMartOcrText = '''
        SIÊU THỊ WINMART+
        ĐC: 123 Cầu Giấy, Hà Nội
        Sữa tươi Vinamilk: 38,000
        Bánh mì sandwich: 22,000
        Thịt heo xay: 85,500
        Tiền hàng: 145,500
        Thuế VAT: 11,640
        TỔNG CỘNG: 157,140 VND
        Tiền khách đưa: 200,000
        Tiền thừa: 42,860
        Ngày lập: 05/10/2026 18:45
      ''';

      final result = HeuristicRegexExtractor.extract(winMartOcrText);

      expect(result.amount, equals(157140.0));
      expect(result.date.day, equals(5));
      expect(result.date.month, equals(10));
      expect(result.date.year, equals(2026));
      expect(result.merchant, contains('WinMart'));
      expect(result.categoryId, equals('shopping'));
    });

    test('4. Bóc tách hóa đơn Highlands Coffee', () {
      const highlandsOcrText = '''
        HIGHLANDS COFFEE
        Phiếu thanh toán
        1x Freeze Trà xanh (L): 69,000
        1x Phin sữa đá (M): 39,000
        Tổng thanh toán: 108.000 đ
        Ngày: 12/10/2026
        Giờ: 10:30 AM
      ''';

      final result = HeuristicRegexExtractor.extract(highlandsOcrText);

      expect(result.amount, equals(108000.0));
      expect(result.date.day, equals(12));
      expect(result.date.month, equals(10));
      expect(result.date.year, equals(2026));
      expect(result.merchant, equals('Highlands Coffee'));
      expect(result.categoryId, equals('food'));
    });

    test('5. Bóc tách biến động số dư MB Bank (định dạng YYYY-MM-DD)', () {
      const mbBankOcrText = '''
        MB BANK
        Thông báo biến động số dư
        Tài khoản: 0987654321
        Số tiền GD: -2,500,000 VND
        Thời gian: 2026-10-01 08:30:00
        Nội dung: Học phí Đại học FPT kỳ Fall 2026
      ''';

      final result = HeuristicRegexExtractor.extract(mbBankOcrText);

      expect(result.amount, equals(2500000.0));
      expect(result.date.day, equals(1));
      expect(result.date.month, equals(10));
      expect(result.date.year, equals(2026));
      expect(result.merchant, contains('MB Bank'));
      expect(result.categoryId, equals('education'));
    });

    test('6. Bóc tách định dạng viết tắt "k" (VD: 85k)', () {
      const shortOcrText = '''
        Cơm tấm Sài Gòn
        Thành tiền: 85k
        Ngày: 22-09-2026
      ''';

      final result = HeuristicRegexExtractor.extract(shortOcrText);

      expect(result.amount, equals(85000.0));
      expect(result.date.day, equals(22));
      expect(result.date.month, equals(9));
      expect(result.date.year, equals(2026));
      expect(result.categoryId, equals('food'));
    });

    test(
      '7. Bóc tách ảnh chụp OCR bị lỗi khoảng trắng và dấu chấm (noise)',
      () {
        const noisyOcrText = '''
        NHÀ THUỐC PHARMACITY
        Hoa don ban le
        Tong thanh toan: 250 000 d
        Ngay: 24.09.2026
      ''';

        final result = HeuristicRegexExtractor.extract(noisyOcrText);

        expect(result.amount, equals(250000.0));
        expect(result.date.day, equals(24));
        expect(result.date.month, equals(9));
        expect(result.date.year, equals(2026));
        expect(result.merchant, contains('Pharmacity'));
        expect(result.categoryId, equals('health'));
      },
    );

    test('8. Xử lý OCR với định dạng ngày DD-MM-YYYY', () {
      const text = '''
        Xăng dầu Petrolimex
        Số tiền: 120.000 VND
        Ngày giao dịch: 30-08-2026
      ''';

      final result = HeuristicRegexExtractor.extract(text);

      expect(result.amount, equals(120000.0));
      expect(result.date.day, equals(30));
      expect(result.date.month, equals(8));
      expect(result.date.year, equals(2026));
      expect(result.merchant, contains('Petrolimex'));
      expect(result.categoryId, equals('transport'));
    });

    test('9. Giữ đúng giao dịch ngân hàng âm và bỏ qua số tài khoản', () {
      const text = '''
        TECHCOMBANK
        Tài khoản: 0987654321
        Số tiền giao dịch: -85,000 VND
        Thời gian: 2026-09-22 08:10:00
      ''';

      final result = HeuristicRegexExtractor.extract(text);

      expect(result.amount, equals(85000.0));
      expect(result.date, DateTime(2026, 9, 22));
      expect(result.merchant, equals('Techcombank'));
    });

    test('10. Không chấp nhận ngày không tồn tại trong lịch', () {
      final today = DateTime.now();
      const text = '''
        Hóa đơn mẫu
        Tổng tiền: 25,000 VND
        Ngày giao dịch: 31/02/2026
      ''';

      final result = HeuristicRegexExtractor.extract(text);

      expect(result.amount, equals(25000.0));
      expect(result.date.year, equals(today.year));
      expect(result.date.month, equals(today.month));
      expect(result.date.day, equals(today.day));
    });

    test('11. OCR mờ không tự bịa ra số tiền', () {
      const text = '''
        CUA HANG
        So tien: 1O0,OOO VND
        Ngay: 2?/1O/2026
      ''';

      final result = HeuristicRegexExtractor.extract(text);

      expect(result.amount, equals(0.0));
    });
  });
}
