import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  static const List<CategoryModel> defaultCategories = [
    CategoryModel(
      id: 'food',
      name: 'Thực phẩm & Ăn uống',
      icon: Icons.restaurant,
      color: Color(0xFFFF6B6B),
    ),
    CategoryModel(
      id: 'shopping',
      name: 'Mua sắm & Siêu thị',
      icon: Icons.shopping_bag,
      color: Color(0xFF4ECDC4),
    ),
    CategoryModel(
      id: 'transport',
      name: 'Di chuyển & Xăng xe',
      icon: Icons.directions_car,
      color: Color(0xFF45B7D1),
    ),
    CategoryModel(
      id: 'education',
      name: 'Học tập & Sách vở',
      icon: Icons.school,
      color: Color(0xFF96CEB4),
    ),
    CategoryModel(
      id: 'bills',
      name: 'Hóa đơn & Tiện ích',
      icon: Icons.receipt_long,
      color: Color(0xFFFFBE0B),
    ),
    CategoryModel(
      id: 'entertainment',
      name: 'Giải trí & Du lịch',
      icon: Icons.flight_takeoff,
      color: Color(0xFF9D4EDD),
    ),
    CategoryModel(
      id: 'health',
      name: 'Y tế & Sức khỏe',
      icon: Icons.local_hospital,
      color: Color(0xFFFF006E),
    ),
    CategoryModel(
      id: 'other',
      name: 'Chi phí khác',
      icon: Icons.category,
      color: Color(0xFF8338EC),
    ),
  ];

  static CategoryModel findById(String id) {
    return defaultCategories.firstWhere(
      (cat) => cat.id == id,
      orElse: () => defaultCategories.last,
    );
  }

  static CategoryModel guessCategory({
    required String merchant,
    required String rawText,
  }) {
    final lower = '$merchant $rawText'.toLowerCase();

    // Food & Dining
    if (lower.contains('highland') ||
        lower.contains('the coffee house') ||
        lower.contains('phúc long') ||
        lower.contains('phuc long') ||
        lower.contains('cà phê') ||
        lower.contains('cafe') ||
        lower.contains('coffee') ||
        lower.contains('quán ăn') ||
        lower.contains('quan an') ||
        lower.contains('nhà hàng') ||
        lower.contains('nha hang') ||
        lower.contains('bún') ||
        lower.contains('bun') ||
        lower.contains('phở') ||
        lower.contains('pho') ||
        lower.contains('cơm') ||
        lower.contains('com') ||
        lower.contains('ăn trưa') ||
        lower.contains('an trua') ||
        lower.contains('ăn sáng') ||
        lower.contains('an sang') ||
        lower.contains('ăn tối') ||
        lower.contains('an toi') ||
        lower.contains('ăn uống') ||
        lower.contains('an uong') ||
        lower.contains('trà sữa') ||
        lower.contains('tra sua') ||
        lower.contains('kfc') ||
        lower.contains('lotteria') ||
        lower.contains('pizza')) {
      return findById('food');
    }

    // Shopping & Supermarket
    if (lower.contains('winmart') ||
        lower.contains('co.opmart') ||
        lower.contains('coopmart') ||
        lower.contains('bachhoaxanh') ||
        lower.contains('bách hóa xanh') ||
        lower.contains('circle k') ||
        lower.contains('seven eleven') ||
        lower.contains('7-eleven') ||
        lower.contains('siêu thị') ||
        lower.contains('sieu thi') ||
        lower.contains('shopee') ||
        lower.contains('tiki') ||
        lower.contains('lazada') ||
        lower.contains('quần áo') ||
        lower.contains('quan ao') ||
        lower.contains('thời trang') ||
        lower.contains('thoi trang')) {
      return findById('shopping');
    }

    // Transport
    if (lower.contains('grab') ||
        lower.contains('be') ||
        lower.contains('xanh sm') ||
        lower.contains('petrolimex') ||
        lower.contains('xăng') ||
        lower.contains('xang') ||
        lower.contains('vé xe') ||
        lower.contains('ve xe') ||
        lower.contains('gửi xe') ||
        lower.contains('gui xe')) {
      return findById('transport');
    }

    // Education
    if (lower.contains('học phí') ||
        lower.contains('hoc phi') ||
        lower.contains('đại học') ||
        lower.contains('dai hoc') ||
        lower.contains('trường') ||
        lower.contains('truong') ||
        lower.contains('sách') ||
        lower.contains('sach') ||
        lower.contains('nhà sách') ||
        lower.contains('nha sach') ||
        lower.contains('fahasa') ||
        lower.contains('khóa học') ||
        lower.contains('khoa hoc')) {
      return findById('education');
    }

    // Bills & Utilities
    if (lower.contains('điện lực') ||
        lower.contains('dien luc') ||
        lower.contains('evn') ||
        lower.contains('tiền nước') ||
        lower.contains('tien nuoc') ||
        lower.contains('internet') ||
        lower.contains('viettel') ||
        lower.contains('fpt') ||
        lower.contains('vnpt') ||
        lower.contains('tiền nhà') ||
        lower.contains('tien nha') ||
        lower.contains('phí dịch vụ') ||
        lower.contains('phi dich vu')) {
      return findById('bills');
    }

    // Entertainment & Travel
    if (lower.contains('cgv') ||
        lower.contains('lotte cinema') ||
        lower.contains('khách sạn') ||
        lower.contains('khach san') ||
        lower.contains('hotel') ||
        lower.contains('resort') ||
        lower.contains('vé máy bay') ||
        lower.contains('ve may bay') ||
        lower.contains('du lịch') ||
        lower.contains('du lich')) {
      return findById('entertainment');
    }

    // Health
    if (lower.contains('bệnh viện') ||
        lower.contains('benh vien') ||
        lower.contains('nhà thuốc') ||
        lower.contains('nha thuoc') ||
        lower.contains('pharmacity') ||
        lower.contains('long châu') ||
        lower.contains('long chau') ||
        lower.contains('thuốc') ||
        lower.contains('thuoc') ||
        lower.contains('khám bệnh') ||
        lower.contains('kham benh')) {
      return findById('health');
    }

    return findById('other');
  }
}
