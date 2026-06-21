import 'package:flutter/material.dart';
import 'app_theme.dart';

enum DebtAction { receivable, payable, receivedPayment, paidPayment }

extension DebtActionText on DebtAction {
  String get label {
    switch (this) {
      case DebtAction.receivable:
        return 'لي عنده';
      case DebtAction.payable:
        return 'علي له';
      case DebtAction.receivedPayment:
        return 'تسديد منه';
      case DebtAction.paidPayment:
        return 'تسديد مني';
    }
  }

  String get shortLabel {
    switch (this) {
      case DebtAction.receivable:
        return 'دين له';
      case DebtAction.payable:
        return 'دين علي';
      case DebtAction.receivedPayment:
        return 'تسديد منه';
      case DebtAction.paidPayment:
        return 'تسديد مني';
    }
  }

  String get helper {
    switch (this) {
      case DebtAction.receivable:
        return 'أعطيته مبلغًا، وهو الآن مدين لك.';
      case DebtAction.payable:
        return 'أخذت منه مبلغًا، وأنت الآن مدين له.';
      case DebtAction.receivedPayment:
        return 'دفع لك جزءًا مما عليه.';
      case DebtAction.paidPayment:
        return 'دفعت له جزءًا مما عليك.';
    }
  }

  double signedAmount(double amount) {
    switch (this) {
      case DebtAction.receivable:
        return amount;
      case DebtAction.payable:
        return -amount;
      case DebtAction.receivedPayment:
        return -amount;
      case DebtAction.paidPayment:
        return amount;
    }
  }

  Color get color {
    switch (this) {
      case DebtAction.receivable:
        return AppColors.success;
      case DebtAction.payable:
        return AppColors.danger;
      case DebtAction.receivedPayment:
        return AppColors.teal;
      case DebtAction.paidPayment:
        return AppColors.goldDark;
    }
  }

  IconData get icon {
    switch (this) {
      case DebtAction.receivable:
        return Icons.south_west_rounded;
      case DebtAction.payable:
        return Icons.north_east_rounded;
      case DebtAction.receivedPayment:
        return Icons.payments_rounded;
      case DebtAction.paidPayment:
        return Icons.outbox_rounded;
    }
  }
}

class DebtEntry {
  const DebtEntry({
    required this.id,
    required this.person,
    required this.phone,
    required this.action,
    required this.amount,
    required this.date,
    required this.note,
  });

  final String id;
  final String person;
  final String phone;
  final DebtAction action;
  final double amount;
  final DateTime date;
  final String note;

  double get signedAmount => action.signedAmount(amount);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'person': person,
      'phone': phone,
      'action': action.name,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory DebtEntry.fromJson(Map<String, dynamic> map) {
    return DebtEntry(
      id: map['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      person: map['person'] as String? ?? 'بدون اسم',
      phone: map['phone'] as String? ?? '',
      action: DebtAction.values.firstWhere(
        (item) => item.name == map['action'],
        orElse: () => DebtAction.receivable,
      ),
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      note: map['note'] as String? ?? '',
    );
  }
}

class PersonSummary {
  PersonSummary({
    required this.name,
    required this.phone,
    required this.balance,
    required this.count,
    required this.lastDate,
  });

  final String name;
  final String phone;
  final double balance;
  final int count;
  final DateTime lastDate;
}

class LedgerLine {
  const LedgerLine({required this.entry, required this.balance});

  final DebtEntry entry;
  final double balance;
}

String reminderText(PersonSummary person) {
  if (person.balance == 0) {
    return 'مرحبًا ${person.name}، حسابنا مسدد بالكامل ولا يوجد مبلغ قائم. شكرًا لك.';
  }
  if (person.balance > 0) {
    return 'مرحبًا ${person.name}، للتذكير يوجد مبلغ ${formatMoney(person.balance)} مستحق لي. شكرًا لك.';
  }
  return 'مرحبًا ${person.name}، للتذكير يوجد مبلغ ${formatMoney(person.balance.abs())} مستحق لك علي. شكرًا لك.';
}

String formatMoney(double value) {
  final sign = value < 0 ? '-' : '';
  final absValue = value.abs();
  final isWhole = absValue == absValue.roundToDouble();
  final number = isWhole ? absValue.toStringAsFixed(0) : absValue.toStringAsFixed(2);
  final withSeparators = _groupThousands(number);
  return '$sign$withSeparators د.أ';
}

String _groupThousands(String number) {
  final parts = number.split('.');
  final intPart = parts[0];
  final buffer = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
    buffer.write(intPart[i]);
  }
  if (parts.length > 1) {
    buffer.write('.${parts[1]}');
  }
  return buffer.toString();
}

const _months = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];

String formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String formatDateLong(DateTime date) {
  return '${date.day} ${_months[date.month - 1]} ${date.year}';
}
