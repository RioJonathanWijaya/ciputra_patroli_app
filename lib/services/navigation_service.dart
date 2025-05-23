import 'dart:developer';
import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static BuildContext? get context => navigatorKey.currentContext;

  static Future<dynamic> pushNamed(String routeName,
      {Object? arguments}) async {
    return navigatorKey.currentState
        ?.pushNamed(routeName, arguments: arguments);
  }

  static Future<dynamic> pushReplacementNamed(String routeName,
      {Object? arguments}) async {
    return navigatorKey.currentState
        ?.pushReplacementNamed(routeName, arguments: arguments);
  }

  static Future<dynamic> pushNamedAndRemoveUntil(String routeName,
      {Object? arguments}) async {
    return navigatorKey.currentState?.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  static Future<dynamic> pop([dynamic result]) async {
    return navigatorKey.currentState?.pop(result);
  }

  static bool canPop() {
    return navigatorKey.currentState?.canPop() ?? false;
  }

  static Future<bool> maybePop<T extends Object?>([T? result]) async {
    return await navigatorKey.currentState?.maybePop<T>(result) ?? false;
  }

  static void popUntil(String routeName) {
    navigatorKey.currentState?.popUntil((route) {
      return route.settings.name == routeName;
    });
  }

  static Future<dynamic> navigateTo(String routeName,
      {Object? arguments, bool clearStack = false}) async {
    if (clearStack) {
      return pushNamedAndRemoveUntil(routeName, arguments: arguments);
    }
    return pushNamed(routeName, arguments: arguments);
  }
}
