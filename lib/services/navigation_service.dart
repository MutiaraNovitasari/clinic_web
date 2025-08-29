import 'package:flutter/material.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<dynamic> navigateTo(String routeName) {
    return navigatorKey.currentState!.pushNamed(routeName);
  }

  void replaceTo(String routeName) {
    navigatorKey.currentState!.pushReplacementNamed(routeName);
  }

  bool canPop() {
    return navigatorKey.currentState!.canPop();
  }

  void goBack() {
    if (canPop()) {
      navigatorKey.currentState!.pop();
    }
  }
}

// ✅ Instance global — bisa dipakai di seluruh app
final NavigationService navigationService = NavigationService();