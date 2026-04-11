import 'package:flutter/material.dart';
import 'package:octopusmanage/l10n/app_localizations.dart';
import 'package:octopusmanage/services/api_service.dart';
import 'package:octopusmanage/services/octopus_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WaitTimeUnit { ms, s, auto }

const kWaitTimeUnitKey = 'wait_time_unit';

class AppProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  late final OctopusApi api;

  bool _initialized = false;
  bool _loading = true;
  String? _error;
  AppLocale _locale = AppLocale.en;
  bool? _bootstrapped;
  WaitTimeUnit _waitTimeUnit = WaitTimeUnit.auto;

  bool get initialized => _initialized;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _apiService.isLoggedIn;
  bool get isConfigured => _apiService.isConfigured;
  String get baseUrl => _apiService.baseUrl;
  AppLocale get locale => _locale;
  bool? get bootstrapped => _bootstrapped;
  bool get needsBootstrap => _bootstrapped == false;
  WaitTimeUnit get waitTimeUnit => _waitTimeUnit;

  Locale get flutterLocale =>
      AppLocalizations.localeMap[_locale] ?? const Locale('en');
  AppLocalizations get loc => AppLocalizations(_locale);

  AppProvider() {
    _apiService.onUnauthorized = () {
      notifyListeners();
    };
    api = OctopusApi(_apiService);
    _init();
  }

  Future<void> _init() async {
    _loading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocale = prefs.getString(kLocaleKey);
      if (savedLocale != null) {
        _locale = AppLocale.values.firstWhere(
          (e) => e.name == savedLocale,
          orElse: () => AppLocale.en,
        );
      } else {
        final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
        _locale = AppLocalizations.fromLocale(systemLocale);
      }
      final savedWaitUnit = prefs.getString(kWaitTimeUnitKey);
      if (savedWaitUnit != null) {
        _waitTimeUnit = WaitTimeUnit.values.firstWhere(
          (e) => e.name == savedWaitUnit,
          orElse: () => WaitTimeUnit.auto,
        );
      }
      await _apiService.loadSavedState();
      _initialized = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> setWaitTimeUnit(WaitTimeUnit unit) async {
    _waitTimeUnit = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kWaitTimeUnitKey, unit.name);
    notifyListeners();
  }

  Future<void> setLocale(AppLocale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kLocaleKey, locale.name);
    notifyListeners();
  }

  Future<bool> login(
    String username,
    String password, {
    bool rememberMe = true,
  }) async {
    try {
      final data = await api.login(
        username,
        password,
        expire: rememberMe ? -1 : 0,
      );
      final token = data['token'] as String? ?? '';
      if (token.isNotEmpty) {
        await _apiService.setToken(token);
        _bootstrapped = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> checkBootstrapStatus() async {
    try {
      final data = await api.checkBootstrap();
      _bootstrapped = data['initialized'] == true;
    } catch (e) {
      _bootstrapped = null;
    }
    notifyListeners();
  }

  Future<bool> createAdmin(String username, String password) async {
    try {
      final success = await api.createAdmin(username, password);
      if (success) {
        _bootstrapped = true;
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> setBaseUrl(String url) async {
    await _apiService.setBaseUrl(url);
    _bootstrapped = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await _apiService.logout();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
