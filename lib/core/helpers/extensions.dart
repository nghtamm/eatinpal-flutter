import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension ContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  MediaQueryData get mq => MediaQuery.of(this);
  double get screenWidth => mq.size.width;
  double get screenHeight => mq.size.height;
  EdgeInsets get padding => mq.padding;
}

extension GoRouterX on GoRouter {
  void popUntil(String path) {
    while (canPop()) {
      pop();
    }
  }
}

extension StringX on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  bool get isEmail {
    return RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }
}

extension DateTimeX on DateTime {
  String get toDateString {
    return '${day.toString().padLeft(2, '0')}/'
        '${month.toString().padLeft(2, '0')}/'
        '${year.toString().padLeft(4, '0')}';
  }

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
}

extension NumX on num {
  String get kcal => '${toStringAsFixed(0)} kcal';
  String get gram => '${toStringAsFixed(1)}g';
}
