import 'package:another_telephony/telephony.dart';
import 'database_service.dart';
import 'location_service.dart';
import 'encryption_service.dart';
import '../models/message.dart';
import '../models/telemetry_data.dart';
import '../models/app_config.dart';
import '../providers/app_state.dart';
import 'package:flutter/material.dart';

// WARNING :
  // This service stores sent messages with - Encryption applied
  // This service stores receieved messages with - Decryptioin not applied
  // Changing the passkey will then fuck up everything in the view
  // As decryption is done on UI level

// HEADERS ARE NOT REMOVED IN DATABASE. SHOULD CHANGE IN FUTURE
// ALL MESSAGES ARE PUSHED TO DATABASE, database checking should be UI SIDe


@pragma('vm:entry-point')
class SmsService {
  static final Telephony telephony = Telephony.instance;

  static Future<bool> requestPermissions() async {
    return await telephony.requestPhoneAndSmsPermissions ?? false;
  }

  static Future<bool> sendSms(String phoneNumber, String message) async {
    try {
      await telephony.sendSms(
        to: phoneNumber,
        message: message,
      ); 

      return true;
    } catch (e) {
      print('Error sending SMS: $e');
      return false;
    }
  }

  static Future<bool> sendEncryptedMessage(String content, bool isDataMessage) async {
    print("<Inside function call sendEncryptedMessage>");
    print("content : $content | isDataMessage : $isDataMessage");

    final config = await DatabaseService.getAppConfig();
    if (config.pairedNumber == null || config.passkey == null) {
      print("<return> : false in config check");
      print("-> pairedNumber : ${config.pairedNumber}");
      print("-> passkey : ${config.passkey}");
      return false;
    }

    final encryptedContent = EncryptionService.encrypt(content, config.passkey!);
    final messageWithHeader = EncryptionService.addHeader(encryptedContent, isDataMessage);

    print("encryptedContent : $encryptedContent");
    print("messageWithHeader : $messageWithHeader");

    final success = await sendSms(config.pairedNumber!, messageWithHeader);
    if (success) {
      final message = Message(
        sender: 'Me',
        content: encryptedContent,
        isEncrypted: true,
        isFromMe: true,
        timestamp: DateTime.now(),
        type: isDataMessage ? MessageType.command : MessageType.userMessage,
      );

      DatabaseService.insertMessage(message); // todo : in future all messages will be pushed to database service
    }
    return success;
  }

  static void startListeningForIncomingMessages(AppState appState) {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage sms) async {
        await _handleForegroundMessage(sms, appState);
      },
      onBackgroundMessage: _handleBackgroundMessage, 
    );
  }

  static Future<void> _handleMessage(SmsMessage sms) async {
    // Will handle sms insertion into DB. Will not handle UI updates, those must be dispatched by 
    // respective handlers.

    print("<Inside function call _handleMessage>");
    final config = await DatabaseService.getAppConfig();
    final sender = sms.address ?? '';
    final content = sms.body ?? '';

    if (config.pairedNumber == null || sender != config.pairedNumber) {
      return;
    }

    final hasHeader = EncryptionService.hasAppHeader(content);
    print("Header found? ${hasHeader}");

    if (hasHeader) {
      final contentWithoutHeader = EncryptionService.removeHeader(content);
      final decryptedContent = EncryptionService.decrypt(contentWithoutHeader, config.passkey ?? '');
      final isDataMessage = EncryptionService.isDataMessage(content);
      final messageType = isDataMessage ? MessageType.update : MessageType.userMessage;

      print("contentWithoutHeader : $contentWithoutHeader");
      print("decryptedContent : $decryptedContent");
      print("isDataMessage : $isDataMessage");

      final message = Message(
          sender: sender,
          content: content,
          isEncrypted: true,
          isFromMe: false,
          timestamp: DateTime.now(),
          type: messageType,
        );

      if (isDataMessage) {
        await _processDataMessage(decryptedContent); // todo : in future the whole message object should be parsed
      }

      DatabaseService.insertMessage(message); // todo : in future all messages will be pushed to database service
    } else {
        // It's a normal message
        final message = Message(
          sender: sender,
          content: content,
          isEncrypted: false,
          isFromMe: false,
          timestamp: DateTime.now(),
          type: MessageType.userMessage,
        );
        await DatabaseService.insertMessage(message);
    }
  }

  static Future<void> _handleForegroundMessage(SmsMessage sms, AppState appState) async {
    await _handleMessage(sms);
    await appState.loadMessages();
    await appState.loadTelemetryData();

    return;
  }

  @pragma('vm:entry-point')
  static Future<void> _handleBackgroundMessage(SmsMessage sms) async {
    // For background, you may want to rehydrate app state or use a static config
    // For now, just print for debug
    print('Received SMS in background: ${sms.address}: ${sms.body}');
    await _handleMessage(sms);
    // You can implement background DB insert here if needed
  }

  static Future<void> _processDataMessage(String content) async {
    if (content.startsWith('LOC ')) {
      final parts = content.split(' ');
      if (parts.length >= 3) {
        final lat = double.tryParse(parts[1]);
        final long = double.tryParse(parts[2]);
        if (lat != null && long != null) {
          final telemetryData = TelemetryData(
            latitude: lat,
            longitude: long,
            timestamp: DateTime.now(),
          );
          await DatabaseService.insertTelemetryData(telemetryData);
        }
      }
    } else if (content == 'SEND LOC') {
      await LocationService.sendCurrentLocation();
    }
  }
} 