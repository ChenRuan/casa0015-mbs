import 'dart:io' show Platform;

class Secrets {
  static String get googleMapsApiKey => Platform.environment['GOOGLE_MAPS_API_KEY']!;
}