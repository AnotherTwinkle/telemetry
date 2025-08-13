import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/app_state.dart';

import '../models/app_config.dart';
import '../models/message.dart';

import '../services/encryption_service.dart';
import '../services/location_service.dart';

import '../main.dart';

int SMS_MAX_CHARACTER_LIMIT = 130;

class GeoLinkifier extends Linkifier {
  const GeoLinkifier();

  @override
  List<LinkifyElement> parse(List<LinkifyElement> elements, LinkifyOptions options) {
    final List<LinkifyElement> result = [];

    for (final element in elements) {
      if (element is TextElement) {
        final pattern = RegExp(r'(geo:[^\s]+)', caseSensitive: false);
        final matches = pattern.allMatches(element.text);

        if (matches.isEmpty) {
          result.add(element);
        } else {
          int start = 0;
          for (final match in matches) {
            if (match.start > start) {
              result.add(TextElement(element.text.substring(start, match.start)));
            }
            result.add(LinkableElement(match.group(0)!, match.group(0)!));
            start = match.end;
          }
          if (start < element.text.length) {
            result.add(TextElement(element.text.substring(start)));
          }
        }
      } else {
        result.add(element);
      }
    }
    return result;
  }
}

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen>{
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() async {
    // This is called when you return to this screen
    // print('MessagingScreen: didPopNext called - screen regained focus');
    await context.read<AppState>().loadMessages();
    // print('MessagingScreen: finished loading messages');
    setState(() {});
  }

  void showSnackError(String content) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(content),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void sendMessageAfterHook(bool success) {
    // Called after input is sent over to telephony
    if (mounted) {
      if (success) {
        _scrollToBottom();
      } else {
        showSnackError("Failed to send message. Check configuration please.");
      }
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();

    if (message.length >= SMS_MAX_CHARACTER_LIMIT) {
      showSnackError("Message exceeds $SMS_MAX_CHARACTER_LIMIT character limit.");
    }
    else if (EncryptionService.hasForbiddenCharacter(message)){
      showSnackError("Message has a forbidden character. Please only use basic alphanumeric.");
    }
    else if (message.isNotEmpty) {
      _messageController.clear();
      final success = await context.read<AppState>().sendMessage(message);
      sendMessageAfterHook(success);
    }
  }

  Future<void> _requestLocation() async {
    final success = await context.read<AppState>().requestLocation();
    sendMessageAfterHook(success);
  }

  @override
  void initState() {
    super.initState();

    final appState = Provider.of<AppState>(context, listen: false);
    appState.onNewMessages = () {
      _scrollToBottom();
    };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final config = appState.config;
        final messages = appState.messages;

        if (config.pairedNumber == null || config.passkey == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.message_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Configure your pair settings first',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Go to Config to set up your paired number and passkey',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          resizeToAvoidBottomInset: true, // important!
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: messages.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Start a conversation with your paired device',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          addAutomaticKeepAlives : false,
                          reverse: true,   // <-- add reverse here
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[messages.length - 1 - index]; // reverse indexing
                            return _buildMessageBubble(message, config);
                          },
                        ),
                ),
                _buildMessageInput(),
              ],
            ),
          ),
        );
      },
    );

  }

  Widget _buildMessageBubble(Message message, AppConfig config) {
    final content = !message.isEncrypted ? message.content : (
            EncryptionService.decrypt(EncryptionService.removeHeader(message.content), config.passkey ?? '')
      );
    final isFromMe = message.isFromMe;

     return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // if (!isFromMe) ...[
          //   CircleAvatar(
          //     radius: 16,
          //     backgroundColor: Colors.blue,
          //     child: Text(
          //       (config.pairedAlias != null) ? "${config.pairedAlias}"[0].toUpperCase() : message.sender[0].toUpperCase(),
          //       style: const TextStyle(
          //         color: Colors.white,
          //         fontWeight: FontWeight.bold,
          //       ),
          //     ),
          //   ),
          //   const SizedBox(width: 8),
          // ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isFromMe
                    ? Theme.of(context).colorScheme.inversePrimary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isFromMe) ...[
                    Text(
                      (config.pairedAlias != null) ? "${config.pairedAlias}" : message.sender,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isFromMe ? Colors.white : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
            Linkify(
              text: content,
              style: TextStyle(
                color: isFromMe ? Colors.white : null,
              ),
              linkStyle: const TextStyle(
                color: Colors.lightBlueAccent,
               decoration: TextDecoration.none,
              ),
              linkifiers: const [
                UrlLinkifier(),
                EmailLinkifier(),
                GeoLinkifier(), // 👈 custom geo: link detection
              ],
              onOpen: (link) async {
                final uri = Uri.parse(link.url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication, // opens in Google Maps directly
                  );
                } else {
                  throw Exception("Could not launch $uri");
                }
              },
            ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isFromMe ? Colors.white70 : Colors.grey,
                        ),
                      ),
                      if (message.isEncrypted) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.lock,
                          size: 12,
                          color: isFromMe ? Colors.white70 : Colors.grey,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          // if (isFromMe) ...[
          //   const SizedBox(width: 8),
          //   CircleAvatar(
          //     radius: 16,
          //     backgroundColor: Colors.green,
          //     child: const Icon(
          //       Icons.person,
          //       color: Colors.white,
          //       size: 16,
          //     ),
          //   ),
          // ],
        ],
      ),
    );
  }
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed : _requestLocation,
            icon : const Icon(Icons.not_listed_location_sharp),
            style : IconButton.styleFrom(
              backgroundColor : Theme.of(context).colorScheme.primary,
              foregroundColor : Colors.white,
              ),
            ),
          const SizedBox(width : 8),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    if (messageDate == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
} 