import 'package:flutter/material.dart';
import 'package:octopusmanage/l10n/app_localizations.dart';
import 'package:octopusmanage/services/api_service.dart';
import 'package:octopusmanage/services/octopus_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WaitTimeUnit { ms, s, auto }

const kWaitTimeUnitKey = 'wait_time_unit';
const kAutoRefreshEnabledKey = 'auto_refresh_enabled';
const kAutoRefreshIntervalSecondsKey = 'auto_refresh_interval_seconds';

class AppProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  late final OctopusApi api;
  SharedPreferences? _prefs;

  bool _initialized = false;
  bool _loading = true;
  String? _error;
  AppLocale _locale = AppLocale.en;
  bool? _bootstrapped;
  WaitTimeUnit _waitTimeUnit = WaitTimeUnit.auto;
  bool _autoRefreshEnabled = false;
  int _autoRefreshIntervalSeconds = 30;

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
  bool get autoRefreshEnabled => _autoRefreshEnabled;
  int get autoRefreshIntervalSeconds => _autoRefreshIntervalSeconds;

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
      _prefs = await SharedPreferences.getInstance();
      final savedLocale = _prefs!.getString(kLocaleKey);
      if (savedLocale != null) {
        _locale = AppLocale.values.firstWhere(
          (e) => e.name == savedLocale,
          orElse: () => AppLocale.en,
        );
      } else {
        final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
        _locale = AppLocalizations.fromLocale(systemLocale);
      }
      final savedWaitUnit = _prefs!.getString(kWaitTimeUnitKey);
      if (savedWaitUnit != null) {
        _waitTimeUnit = WaitTimeUnit.values.firstWhere(
          (e) => e.name == savedWaitUnit,
          orElse: () => WaitTimeUnit.auto,
        );
      }
      _autoRefreshEnabled = _prefs!.getBool(kAutoRefreshEnabledKey) ?? false;
      _autoRefreshIntervalSeconds = _normalizeAutoRefreshInterval(
        _prefs!.getInt(kAutoRefreshIntervalSecondsKey) ?? 30,
      );
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
    await _prefs?.setString(kWaitTimeUnitKey, unit.name);
    notifyListeners();
  }

  Future<void> setAutoRefreshEnabled(bool enabled) async {
    _autoRefreshEnabled = enabled;
    await _prefs?.setBool(kAutoRefreshEnabledKey, enabled);
    notifyListeners();
  }

  Future<void> setAutoRefreshIntervalSeconds(int seconds) async {
    _autoRefreshIntervalSeconds = _normalizeAutoRefreshInterval(seconds);
    await _prefs?.setInt(
      kAutoRefreshIntervalSecondsKey,
      _autoRefreshIntervalSeconds,
    );
    notifyListeners();
  }

  Future<void> setLocale(AppLocale locale) async {
    _locale = locale;
    await _prefs?.setString(kLocaleKey, locale.name);
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
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<bool> createAdmin(String username, String password) async {
    try {
      final success = await api.createAdmin(username, password);
      if (success) {
        _bootstrapped = true;
        notifyListeners();
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

  int _normalizeAutoRefreshInterval(int seconds) {
    switch (seconds) {
      case 15:
      case 30:
      case 60:
        return seconds;
      default:
        return 30;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _apiService.onUnauthorized = null;
    super.dispose();
  }
}
