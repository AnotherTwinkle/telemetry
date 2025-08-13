import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/telemetry_data.dart';
import '../models/app_config.dart';
import '../services/database_service.dart';
import '../services/sms_service.dart';
import '../services/location_service.dart';

class AppState extends ChangeNotifier {
  List<Message> _messages = [];
  List<TelemetryData> _telemetryData = [];
  AppConfig _config = AppConfig();
  bool _isLoading = false;
  
  // Getters
  List<Message> get messages => _messages;
  List<TelemetryData> get telemetryData => _telemetryData;
  AppConfig get config => _config;
  bool get isLoading => _isLoading;


  VoidCallback? onNewMessages;

  // Initialize app state
  Future<void> initialize() async {
    _setLoading(true);
    
    try {
      // Load config
      _config = await DatabaseService.getAppConfig();
      
      // Load messages
      await loadMessages();
      
      // Load telemetry data
      await loadTelemetryData();
      
      // Request permissions
      await _requestPermissions();
      // Start SMS listener
      SmsService.startListeningForIncomingMessages(this);
      print("Incoming messages are now being recieved");
    } catch (e) {
      print('Error initializing app state: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Load messages from database
  Future<void> loadMessages() async {
    try {
      _messages = await DatabaseService.getMessages();
      for (var msg in _messages) {
        print("${msg.timestamp} ${msg.content}");
      }
      notifyListeners();
      if (onNewMessages != null) {
        onNewMessages!();
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
  }
  
  // Load telemetry data from database
  Future<void> loadTelemetryData() async {
    try {
      _telemetryData = await DatabaseService.getTelemetryData();
      notifyListeners();
    } catch (e) {
      print('Error loading telemetry data: $e');
    }
  }
  
  // Send a message
  Future<bool> sendMessage(String content) async {
    try {
      final success = await SmsService.sendEncryptedMessage(content, false);
      if (success) {
        await loadMessages();
      }
      return success;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }
  
  // Send a command
  Future<bool> sendCommand(String command) async {
    try {
      final success = await SmsService.sendEncryptedMessage(command, true);
      if (success) {
        await loadMessages();
      }
      return success;
    } catch (e) {
      print('Error sending command: $e');
      return false;
    }
  }
  
  // Request location from paired device
  Future<bool> requestLocation() async {
    return await sendCommand('SEND LOC');
    this.loadMessages();
  }
  
  // Send current location
  Future<bool> sendCurrentLocation() async {
    try {
      final success = await LocationService.sendCurrentLocation();
      if (success) {
        await loadTelemetryData();
      }
      return success;
    } catch (e) {
      print('Error sending location: $e');
      return false;
    }
  }
  
  // Update app config
  Future<void> updateConfig(AppConfig newConfig) async {
    try {
      await DatabaseService.updateAppConfig(newConfig);
      _config = newConfig;
      notifyListeners();
    } catch (e) {
      print('Error updating config: $e');
    }
  }
  
  // Request permissions
  Future<void> _requestPermissions() async {
    await SmsService.requestPermissions();
    await LocationService.requestPermissions();
  }
  
  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
} 