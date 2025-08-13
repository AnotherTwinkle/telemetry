import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/message.dart';

class CommandsScreen extends StatefulWidget {
  const CommandsScreen({super.key});

  @override
  State<CommandsScreen> createState() => _CommandsScreenState();
}

class _CommandsScreenState extends State<CommandsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final config = appState.config;

        if (config.pairedNumber == null || config.passkey == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.terminal_outlined,
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

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Available Commands',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Send commands to your paired device. Commands are encrypted and sent via SMS.',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Location Commands
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Location Commands',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildCommandButton(
                        'Request Location',
                        'SEND LOC',
                        'Request immediate location from paired device',
                        Icons.location_searching,
                        () async {
                          final success = await appState.requestLocation();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Location request sent successfully'
                                      : 'Failed to send location request',
                                ),
                                backgroundColor: success ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildCommandButton(
                        'Start Location Tracking',
                        'TRANSPOND START "SEND LOC" 60',
                        'Request location every 60 seconds',
                        Icons.track_changes,
                        () async {
                          final success = await appState.sendCommand('TRANSPOND START "SEND LOC" 60');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Location tracking started'
                                      : 'Failed to start location tracking',
                                ),
                                backgroundColor: success ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildCommandButton(
                        'Stop Location Tracking',
                        'TRANSPOND STOP',
                        'Stop automatic location tracking',
                        Icons.stop,
                        () async {
                          final success = await appState.sendCommand('TRANSPOND STOP');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Location tracking stopped'
                                      : 'Failed to stop location tracking',
                                ),
                                backgroundColor: success ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Custom Commands
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.code, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            'Custom Commands',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Send custom commands to your paired device. These will be processed as data messages.',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCustomCommandInput(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Command History
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Command History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCommandHistory(appState),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommandButton(
    String title,
    String command,
    String description,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 4),
            Text(
              'Command: $command',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: onPressed,
          child: const Text('Send'),
        ),
      ),
    );
  }

  Widget _buildCustomCommandInput() {
    final commandController = TextEditingController();
    
    return Column(
      children: [
        TextField(
          controller: commandController,
          decoration: const InputDecoration(
            labelText: 'Custom Command',
            hintText: 'Enter your custom command...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.terminal),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () async {
            final command = commandController.text.trim();
            if (command.isNotEmpty) {
              final success = await context.read<AppState>().sendCommand(command);
              commandController.clear();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Custom command sent successfully'
                          : 'Failed to send custom command',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.send),
          label: const Text('Send Custom Command'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildCommandHistory(AppState appState) {
    final commandMessages = appState.messages
        .where((message) => message.type == MessageType.command && message.isFromMe)
        .toList();

    if (commandMessages.isEmpty) {
      return const Center(
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              'No commands sent yet',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        itemCount: commandMessages.length,
        itemBuilder: (context, index) {
          final message = commandMessages[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              leading: const Icon(Icons.terminal, color: Colors.orange),
              title: Text(message.content),
              subtitle: Text(_formatDateTime(message.timestamp)),
              trailing: const Icon(Icons.lock, color: Colors.green),
            ),
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
} 