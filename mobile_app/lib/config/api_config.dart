/// Backend connection settings for the Flutter app.
///
/// If the app cannot connect:
/// 1. Start Django with `python manage.py runserver 0.0.0.0:8000`.
/// 2. Make sure the phone and the computer use the same Wi-Fi network.
/// 3. Set the computer IPv4 address here when needed.
class ApiConfig {
  /// Computer IP address on the local network.
  /// Leave it empty only if another default host is used elsewhere.
  static const String lanHost = '192.168.100.38';

  static const int port = 8000;

  static String get apiPrefix => 'http://$lanHost:$port/api';
  static String get serverRoot => 'http://$lanHost:$port';

  static String? mediaUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    if (path.startsWith('/media/')) return '$serverRoot$path';
    final p = path.startsWith('/') ? '/media$path' : '/media/$path';
    return '$serverRoot$p';
  }
}
