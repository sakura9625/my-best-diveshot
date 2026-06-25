class AppConfig {
  static const bool isDeveloperMode = true;
  static bool get isProUser => isDeveloperMode || _isPurchased;
  static bool _isPurchased = false;
  static void setPurchased(bool value) {
    _isPurchased = value;
  }
}
