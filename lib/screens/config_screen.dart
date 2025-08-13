import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/app_config.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pairedNumberController = TextEditingController();
  final _passkeyController = TextEditingController();
  final _pairedAliasController = TextEditingController();

  bool _autoDeleteSms = false;
  bool _showDataContentInChat = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConfig();
    });
  }

  @override
  void dispose() {
    _pairedNumberController.dispose();
    _passkeyController.dispose();
    super.dispose();
  }

  void _loadConfig() {
    final config = context.read<AppState>().config;
    _pairedNumberController.text = config.pairedNumber ?? '';
    _pairedAliasController.text = config.pairedAlias ?? '';
    _passkeyController.text = config.passkey ?? '';
    setState(() {
      _autoDeleteSms = config.autoDeleteSms;
      _showDataContentInChat = config.showDataContentInChat;
    });
  }

  Future<void> _saveConfig() async {
    if (_formKey.currentState!.validate()) {
      final newConfig = AppConfig(
        pairedNumber: _pairedNumberController.text.trim(),
        pairedAlias : _pairedAliasController.text.trim(),
        passkey: _passkeyController.text.trim(),
        autoDeleteSms: _autoDeleteSms,
        showDataContentInChat : _showDataContentInChat,
      );

      await context.read<AppState>().updateConfig(newConfig);


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
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
                      'Pair Configuration',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pairedNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Paired Phone Number',
                        hintText: '+1234567890',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pairedAliasController,
                      decoration: const InputDecoration(
                        labelText: 'Paired Alias',
                        hintText: 'Kop pona!',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a valid alias';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passkeyController,
                      decoration: const InputDecoration(
                        labelText: 'Encryption Passkey',
                        hintText: 'Enter a secure passkey',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a passkey';
                        }
                        if (value.length < 4) {
                          return 'Passkey must be at least 4 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SMS Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Auto-delete SMS'),
                      subtitle: const Text(
                        'Automatically delete sent and received SMS messages (Need default app)',
                      ),
                      value: _autoDeleteSms,
                      onChanged: (value) {
                        setState(() {
                          _autoDeleteSms = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title : const Text("Show data SMS in chat"),
                      subtitle : const Text(
                        "Show updates/commands etc as text",
                        ),
                      value : _showDataContentInChat,
                      onChanged : (value) {
                        setState(() {
                           _showDataContentInChat = value;
                          });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saveConfig,
              icon: const Icon(Icons.save),
              label: const Text('Save Configuration'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            Consumer<AppState>(
              builder: (context, appState, child) {
                final config = appState.config;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildStatusItem(
                          'Paired Number',
                          config.pairedNumber ?? 'Not set',
                          config.pairedNumber != null ? Colors.green : Colors.red,
                        ),
                        _buildStatusItem(
                          "Paired Alias",
                          config.pairedAlias ?? 'Not set',
                          config.pairedAlias != null ? Colors.green : Colors.red,
                        ),
                        _buildStatusItem(
                          'Passkey',
                          config.passkey != null ? 'Set' : 'Not set',
                          config.passkey != null ? Colors.green : Colors.red,
                        ),
                        _buildStatusItem(
                          'Auto-delete SMS',
                          config.autoDeleteSms ? 'Enabled' : 'Disabled',
                          config.autoDeleteSms ? Colors.orange : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 