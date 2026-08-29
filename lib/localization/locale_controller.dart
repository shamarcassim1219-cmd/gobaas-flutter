import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';

/// Holds the current language and notifies every listening screen
/// to rebuild when it changes - the Provider/ChangeNotifier
/// equivalent of the web apps calling applyLanguageToDom() after
/// localStorage.setItem("mybaas_lang", ...).
///
/// Locked once a real (non-guest) account is loaded: a Sri Lankan
/// mobile account keeps whatever language it was set to at
/// registration, and an international (email) account is always
/// English - see [lockForAccount].
class LocaleController extends ChangeNotifier {
  static const _prefsKey = 'mybaas_lang';

  String _langCode = 'en';
  bool _locked = false;

  String get langCode => _langCode;
  bool get isLocked => _locked;

  String t(String key) => AppLocalizations.t(key, _langCode);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _langCode = prefs.getString(_prefsKey) ?? 'en';
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (_locked) return;
    _langCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, code);
  }

  /// Called once a real account is loaded (mobile or email). An
  /// international (email, no mobile) account is always English -
  /// there is no reason to offer Sinhala/Tamil to someone outside
  /// Sri Lanka. A local (mobile) account keeps its current choice,
  /// but the picker locks either way once this is called, matching
  /// "language cannot be changed once logged in".
  Future<void> lockForAccount({required bool isInternational}) async {
    if (isInternational && _langCode != 'en') {
      await setUnlockedThenLock('en');
    } else {
      _locked = true;
      notifyListeners();
    }
  }

  /// Internal helper - sets the language while still unlocked, then
  /// locks it, used only by [lockForAccount] for the international
  /// force-to-English case above.
  Future<void> setUnlockedThenLock(String code) async {
    _langCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, code);
    _locked = true;
    notifyListeners();
  }

  /// Called on logout - a fresh guest session should be able to
  /// pick a language again.
  void unlock() {
    _locked = false;
    notifyListeners();
  }
}
