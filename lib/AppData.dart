class AppData {
  // Private constructor
  AppData._internal();

  // Singleton instance
  static final AppData _instance = AppData._internal();

  // Factory constructor to return the same instance
  factory AppData() => _instance;

  // Your display number
  int displayNumber = 0;
}