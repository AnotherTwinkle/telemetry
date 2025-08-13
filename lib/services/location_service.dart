import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/telemetry_data.dart';
import 'database_service.dart';
import 'sms_service.dart';


String formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}

class LocationService {
  /// Request location permissions
  static Future<bool> requestPermissions() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }
  
  /// Get current location
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }
      
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return null;
      }
      
      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }
  
  static String getGeoURI(String latitude, String longitude, [String label = "Location"]) {
    // Trim and validate
    final lat = latitude.trim();
    final lng = longitude.trim();

    // Return a properly formatted Google Maps link
    return "geo:$lat,$lng?q=$lat,$lng($label)";
  }

  /// Send current location to paired device
  static Future<bool> sendCurrentLocation() async {
    // return await SmsService.sendEncryptedMessage("Hello world", true);
    final position = await getCurrentLocation();
    
    if (position != null) {
      // Store in local database
      final telemetryData = TelemetryData(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );
      
      await DatabaseService.insertTelemetryData(telemetryData);
      
      // Send to paired device
      final label = "Location";
      final locationMessage = "LOC ${getGeoURI(position.latitude.toString(),  position.longitude.toString(), label)}";
      // final locationMessage = 'LOC ${position.latitude} ${position.longitude}';
      return await SmsService.sendEncryptedMessage(locationMessage, true);
    }
    
    return false;
  }
  
  /// Get latest location from database
  static Future<TelemetryData?> getLatestLocation() async {
    return await DatabaseService.getLatestTelemetryData();
  }
  
  /// Get all location history
  static Future<List<TelemetryData>> getLocationHistory() async {
    return await DatabaseService.getTelemetryData();
  }
} 
