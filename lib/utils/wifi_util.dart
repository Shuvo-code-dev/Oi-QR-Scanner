import 'package:wifi_iot/wifi_iot.dart';

class WiFiUtil {
  /// Parses WiFi string: WIFI:T:WPA;S:NetworkName;P:Password;;
  static Map<String, String> parseWiFi(String content) {
    final Map<String, String> result = {};
    if (!content.startsWith('WIFI:')) return result;

    final parts = content.substring(5).split(';');
    for (var part in parts) {
      if (part.startsWith('S:')) result['ssid'] = part.substring(2);
      if (part.startsWith('P:')) result['password'] = part.substring(2);
      if (part.startsWith('T:')) result['security'] = part.substring(2);
    }
    return result;
  }

  static Future<bool> connectToWiFi(String ssid, String? password, String? security) async {
    try {
      bool isConnected = await WiFiForIoTPlugin.connect(
        ssid,
        password: password,
        security: _parseSecurity(security),
        withInternet: true,
      );
      return isConnected;
    } catch (e) {
      return false;
    }
  }

  static NetworkSecurity _parseSecurity(String? security) {
    switch (security?.toUpperCase()) {
      case 'WPA':
      case 'WPA2':
        return NetworkSecurity.WPA;
      case 'WEP':
        return NetworkSecurity.WEP;
      default:
        return NetworkSecurity.NONE;
    }
  }
}
