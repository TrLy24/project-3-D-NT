import '../models/category_model.dart';
import '../models/ocr_result.dart';

class HeuristicRegexExtractor {
  /// Extract structured transaction data from raw OCR text
  static OcrExtractedData extract(String rawText) {
    final cleanedText = _preprocessText(rawText);
    final lines = cleanedText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final merchant = extractMerchant(lines, cleanedText);
    final amount = extractAmount(lines, cleanedText);
    final date = extractDate(lines, cleanedText);
    final category = CategoryModel.guessCategory(
      merchant: merchant,
      rawText: cleanedText,
    );

    double confidence = 0.5;
    if (amount > 0) {
      confidence += 0.25;
    }
    if (merchant.isNotEmpty && merchant != 'Giao dịch chưa đặt tên') {
      confidence += 0.15;
    }
    if (cleanedText.contains('/') || cleanedText.contains('-')) {
      confidence += 0.1;
    }

    return OcrExtractedData(
      merchant: merchant,
      amount: amount,
      date: date,
      rawText: rawText,
      categoryId: category.id,
      confidence: confidence.clamp(0.0, 1.0),
      extractedLines: lines,
    );
  }

  /// Normalize and clean noise from raw OCR output
  static String _preprocessText(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();
  }

  /// Extract monetary amount using heuristic rules & regex
  static double extractAmount(List<String> lines, String fullText) {
    // 1. High priority: Lines containing explicit Total/Amount keywords
    final totalKeywords = RegExp(
      r'(tổng\s*tiền|tổng\s*cộng|thành\s*tiền|thanh\s*toán|số\s*tiền|tổng\s*thanh\s*toán|amount|total|grand\s*total|tiền\s*mặt|tổng\s*chi)',
      caseSensitive: false,
    );

    // Negative keywords to avoid change, discount, points, phone numbers
    final negativeKeywords = RegExp(
      r'(tiền\s*thừa|tiền\s*thối|giảm\s*giá|chiết\s*khấu|điểm|tích\s*lũy|mã\s*giao\s*dịch|sđt|điện\s*thoại|stk|tài\s*khoản)',
      caseSensitive: false,
    );

    // Check lines matching total keywords first
    for (final line in lines) {
      if (totalKeywords.hasMatch(line) && !negativeKeywords.hasMatch(line)) {
        final parsed = _findAmountsInString(line);
        if (parsed.isNotEmpty) {
          // Return the largest plausible amount in this total line
          return parsed.reduce((a, b) => a > b ? a : b);
        }
      }
    }

    // 2. Medium priority: Check lines following a total keyword line
    for (int i = 0; i < lines.length - 1; i++) {
      if (totalKeywords.hasMatch(lines[i]) &&
          !negativeKeywords.hasMatch(lines[i])) {
        final nextLineAmounts = _findAmountsInString(lines[i + 1]);
        if (nextLineAmounts.isNotEmpty) {
          return nextLineAmounts.reduce((a, b) => a > b ? a : b);
        }
      }
    }

    // 3. Fallback: Search all lines for currency markers (VND, VNĐ, đ, k)
    final currencyPattern = RegExp(
      r'(\d{1,3}(?:[.,\s]\d{3})+(?:[.,]\d+)?|\d+)\s*(?:vnd|vnđ|đ|d|k)\b',
      caseSensitive: false,
    );

    final currencyMatches = currencyPattern.allMatches(fullText);
    final candidateAmounts = <double>[];
    for (final match in currencyMatches) {
      final token = match.group(0)!;
      final parsed = _findAmountsInString(token);
      candidateAmounts.addAll(parsed);
    }

    if (candidateAmounts.isNotEmpty) {
      // Filter out absurdly high numbers (like account/phone numbers)
      final valid = candidateAmounts
          .where((a) => a >= 1000 && a <= 500000000)
          .toList();
      if (valid.isNotEmpty) {
        return valid.reduce((a, b) => a > b ? a : b);
      }
    }

    // 4. Last fallback: amounts without a currency marker, excluding dates and IDs.
    final excludedContext = RegExp(
      r'(ngày|ngay|thời\s*gian|thoi\s*gian|date|time|mã\s*(gd|giao\s*dịch)|'
      r'ma\s*(gd|giao\s*dich)|tài\s*khoản|tai\s*khoan|sđt|điện\s*thoại|dien\s*thoai)',
      caseSensitive: false,
    );
    final allNumbers = <double>[];
    for (final line in lines) {
      if (excludedContext.hasMatch(line) || negativeKeywords.hasMatch(line)) {
        continue;
      }
      allNumbers.addAll(_findAmountsInString(line));
    }
    final plausible = allNumbers
        .where((a) => a >= 1000 && a <= 100000000)
        .toList();
    if (plausible.isNotEmpty) {
      return plausible.reduce((a, b) => a > b ? a : b);
    }

    return 0.0;
  }

  /// Parses numeric values with Vietnamese thousands separator (dots, commas, spaces) or "k" suffix
  static List<double> _findAmountsInString(String str) {
    final results = <double>[];

    // Case 1: Short notation with k/K (e.g. 150k -> 150,000)
    final kRegex = RegExp(r'(\d+(?:[.,]\d+)?)\s*[kK]\b');
    for (final m in kRegex.allMatches(str)) {
      final valStr = m.group(1)!.replaceAll(',', '.');
      final val = double.tryParse(valStr);
      if (val != null) {
        results.add(val * 1000);
      }
    }

    // Case 2: Standard Vietnamese currency formatted e.g. 150.000 or 150,000 or 150 000
    // Optional minus sign for bank debits: -150,000 VND
    final standardRegex = RegExp(
      r'[+-]?\s*(\d{1,3}(?:[.,\s]\d{3})+(?:[.,]\d{1,2})?|\d{4,9})',
    );
    for (final m in standardRegex.allMatches(str)) {
      String cleanStr = m.group(1)!;

      // Handle space separator
      cleanStr = cleanStr.replaceAll(' ', '');

      // Detect separator: if dots are thousands e.g. 150.000
      if (cleanStr.contains('.') && !cleanStr.contains(',')) {
        // e.g. 150.000 -> 150000
        cleanStr = cleanStr.replaceAll('.', '');
      } else if (cleanStr.contains(',') && !cleanStr.contains('.')) {
        // e.g. 150,000 -> 150000
        cleanStr = cleanStr.replaceAll(',', '');
      } else if (cleanStr.contains('.') && cleanStr.contains(',')) {
        // Format: 150.000,00 or 150,000.00
        if (cleanStr.lastIndexOf(',') > cleanStr.lastIndexOf('.')) {
          // European/VN style: 150.000,50
          cleanStr = cleanStr.replaceAll('.', '').replaceAll(',', '.');
        } else {
          // US style: 150,000.50
          cleanStr = cleanStr.replaceAll(',', '');
        }
      }

      final numVal = double.tryParse(cleanStr);
      if (numVal != null && numVal > 0) {
        // Exclude phone numbers (> 9 digits starting with 0) or account numbers
        if (cleanStr.length >= 10 && cleanStr.startsWith('0')) {
          continue;
        }
        results.add(numVal);
      }
    }

    return results;
  }

  /// Extract transaction date (DD/MM/YYYY, DD-MM-YYYY, YYYY-MM-DD, etc.)
  static DateTime extractDate(List<String> lines, String fullText) {
    // 1. Lines with explicit date keywords
    final dateKeywords = RegExp(
      r'(ngày|thời\s*gian|date|time|ngày\s*lập|ngày\s*gd|giao\s*dịch)',
      caseSensitive: false,
    );
    for (final line in lines) {
      if (dateKeywords.hasMatch(line)) {
        final parsed = _parseDateFromText(line);
        if (parsed != null) return parsed;
      }
    }

    // 2. Scan entire text
    final generalParsed = _parseDateFromText(fullText);
    if (generalParsed != null) return generalParsed;

    // Fallback: Current date
    return DateTime.now();
  }

  static DateTime? _parseDateFromText(String text) {
    // Patterns:
    // DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY
    final dmyRegex = RegExp(
      r'\b(0?[1-9]|[12][0-9]|3[01])[\/\-\.](0?[1-9]|1[012])[\/\-\.](20\d\d)\b',
    );
    final dmyMatch = dmyRegex.firstMatch(text);
    if (dmyMatch != null) {
      final day = int.parse(dmyMatch.group(1)!);
      final month = int.parse(dmyMatch.group(2)!);
      final year = int.parse(dmyMatch.group(3)!);
      return _validatedDate(year, month, day);
    }

    // YYYY-MM-DD or YYYY/MM/DD
    final ymdRegex = RegExp(
      r'\b(20\d\d)[\/\-\.](0?[1-9]|1[012])[\/\-\.](0?[1-9]|[12][0-9]|3[01])\b',
    );
    final ymdMatch = ymdRegex.firstMatch(text);
    if (ymdMatch != null) {
      final year = int.parse(ymdMatch.group(1)!);
      final month = int.parse(ymdMatch.group(2)!);
      final day = int.parse(ymdMatch.group(3)!);
      return _validatedDate(year, month, day);
    }

    // Short year: DD/MM/YY
    final shortYearRegex = RegExp(
      r'\b(0?[1-9]|[12][0-9]|3[01])[\/\-\.](0?[1-9]|1[012])[\/\-\.]([2-9]\d)\b',
    );
    final shortMatch = shortYearRegex.firstMatch(text);
    if (shortMatch != null) {
      final day = int.parse(shortMatch.group(1)!);
      final month = int.parse(shortMatch.group(2)!);
      final year = 2000 + int.parse(shortMatch.group(3)!);
      return _validatedDate(year, month, day);
    }

    return null;
  }

  static DateTime? _validatedDate(int year, int month, int day) {
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  /// Extract merchant or bank name
  static String extractMerchant(List<String> lines, String fullText) {
    final lowerText = fullText.toLowerCase();

    // 1. Recognized Brands & Banks
    final knownBrands = {
      'vietcombank': 'Vietcombank',
      'vcb digibank': 'Vietcombank',
      'techcombank': 'Techcombank',
      'mbbank': 'MB Bank',
      'mb bank': 'MB Bank',
      'momo': 'Ví MoMo',
      'zalopay': 'ZaloPay',
      'shopeepay': 'ShopeePay',
      'vnpay': 'VNPay',
      'vpbank': 'VPBank',
      'bidv': 'BIDV',
      'vietinbank': 'VietinBank',
      'agribank': 'Agribank',
      'tpbank': 'TPBank',
      'acb': 'ACB Bank',
      'winmart+': 'Siêu thị WinMart+',
      'winmart': 'Siêu thị WinMart',
      'co.opmart': 'Siêu thị Co.opmart',
      'coopmart': 'Siêu thị Co.opmart',
      'bách hóa xanh': 'Bách Hóa Xanh',
      'circle k': 'Circle K',
      '7-eleven': '7-Eleven',
      'seven eleven': '7-Eleven',
      'family mart': 'FamilyMart',
      'familymart': 'FamilyMart',
      'highlands coffee': 'Highlands Coffee',
      'highland coffee': 'Highlands Coffee',
      'the coffee house': 'The Coffee House',
      'phúc long': 'Phúc Long Coffee & Tea',
      'phuc long': 'Phúc Long Coffee & Tea',
      'starbucks': 'Starbucks Coffee',
      'kfc': 'KFC Vietnam',
      'lotteria': 'Lotteria',
      'mcdonald': "McDonald's",
      'pizza company': 'The Pizza Company',
      'fahasa': 'Nhà sách Fahasa',
      'pharmacity': 'Nhà thuốc Pharmacity',
      'long châu': 'Nhà thuốc Long Châu',
      'grab': 'Grab Vietnam',
      'be': 'Be Group',
      'xanh sm': 'Xanh SM',
      'petrolimex': 'Cây xăng Petrolimex',
    };

    for (final entry in knownBrands.entries) {
      if (lowerText.contains(entry.key)) {
        return entry.value;
      }
    }

    // 2. Check top lines of receipt for merchant name
    final excludeHeader = RegExp(
      r'(hóa\s*đơn|phiếu|biên\s*lai|receipt|invoice|cộng\s*hòa|việt\s*nam|độc\s*lập|chuyển\s*khoản|giao\s*dịch|thông\s*báo|thành\s*công)',
      caseSensitive: false,
    );

    for (int i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i];
      if (line.length >= 3 &&
          line.length <= 40 &&
          !excludeHeader.hasMatch(line)) {
        // If line doesn't contain mostly numbers/symbols
        if (RegExp(r'[a-zA-Z\u00C0-\u1EF9]{3,}').hasMatch(line)) {
          return line;
        }
      }
    }

    return 'Hóa đơn mua sắm';
  }
}
