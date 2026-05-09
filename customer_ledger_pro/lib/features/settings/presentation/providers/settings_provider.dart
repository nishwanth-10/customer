import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_ledger_pro/core/storage/local_storage.dart';

class AppSettings {
  final bool isDarkMode;
  final String language;
  final bool pushNotifications;

  const AppSettings({
    this.isDarkMode = false,
    this.language = 'en',
    this.pushNotifications = true,
  });

  AppSettings copyWith({bool? isDarkMode, String? language, bool? pushNotifications}) => AppSettings(
        isDarkMode: isDarkMode ?? this.isDarkMode,
        language: language ?? this.language,
        pushNotifications: pushNotifications ?? this.pushNotifications,
      );
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    return AppSettings(
      isDarkMode: LocalStorage.getSetting<bool>('dark_mode') ?? false,
      language: LocalStorage.getSetting<String>('language') ?? 'en',
      pushNotifications: LocalStorage.getSetting<bool>('push_notifications') ?? true,
    );
  }

  void setDarkMode(bool value) {
    LocalStorage.setSetting('dark_mode', value);
    state = state.copyWith(isDarkMode: value);
  }

  void setLanguage(String value) {
    LocalStorage.setSetting('language', value);
    state = state.copyWith(language: value);
  }

  void setPushNotifications(bool value) {
    LocalStorage.setSetting('push_notifications', value);
    state = state.copyWith(pushNotifications: value);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
