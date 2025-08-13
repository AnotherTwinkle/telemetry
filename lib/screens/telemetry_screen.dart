import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/telemetry_data.dart';

class TelemetryScreen extends StatefulWidget {
  const TelemetryScreen({super.key});

  @override
  State<TelemetryScreen> createState() => _TelemetryScreenState();
}

class _TelemetryScreenState extends State<TelemetryScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final telemetryData = appState.telemetryData;
        final latestData = telemetryData.isNotEmpty ? telemetryData.first : null;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Current Location Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'Current Location',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () async {
                              final success = await appState.sendCurrentLocation();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Location sent successfully'
                                          : 'Failed to send location',
                                    ),
                                    backgroundColor: success ? Colors.green : Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.send),
                            tooltip: 'Send current location',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (latestData != null) ...[
                        _buildLocationInfo('Latitude', latestData.latitude?.toString() ?? 'N/A'),
                        const SizedBox(height: 8),
                        _buildLocationInfo('Longitude', latestData.longitude?.toString() ?? 'N/A'),
                        const SizedBox(height: 8),
                        _buildLocationInfo('Last Updated', _formatDateTime(latestData.timestamp)),
                      ] else ...[
                        const Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.location_off,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'No location data available',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Location History
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (telemetryData.isNotEmpty) ...[
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            itemCount: telemetryData.length,
                            itemBuilder: (context, index) {
                              final data = telemetryData[index];
                              return _buildHistoryItem(data);
                            },
                          ),
                        ),
                      ] else ...[
                        const Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.history,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'No location history',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Actions
              ElevatedButton.icon(
                onPressed: () async {
                  final success = await appState.requestLocation();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Location request sent'
                              : 'Failed to send location request',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.location_searching),
                label: const Text('Request Location from Paired Device'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationInfo(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(': '),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(TelemetryData data) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: const Icon(Icons.location_on, color: Colors.blue),
        title: Text(
          '${data.latitude?.toStringAsFixed(6) ?? 'N/A'}, ${data.longitude?.toStringAsFixed(6) ?? 'N/A'}',
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        subtitle: Text(_formatDateTime(data.timestamp)),
        trailing: IconButton(
          onPressed: () {
            // Copy coordinates to clipboard
            final coords = '${data.latitude}, ${data.longitude}';
            // Implementation for copying to clipboard would go here
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Copied: $coords'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          icon: const Icon(Icons.copy),
          tooltip: 'Copy coordinates',
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
} 