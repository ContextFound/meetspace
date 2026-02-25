import 'package:flutter/material.dart';

import 'landing_screen.dart' show copyToClipboard;

class ShowKeyScreen extends StatelessWidget {
  const ShowKeyScreen({
    super.key,
    required this.apiKey,
    required this.keyPrefix,
    required this.tier,
    required this.onContinue,
  });

  final String apiKey;
  final String keyPrefix;
  final String tier;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your API key'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Save this key now. It will not be shown again.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: SelectableText(
                  apiKey,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () => copyToClipboard(
                      context,
                      apiKey,
                      'API key',
                    ),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Key prefix: $keyPrefix · Tier: $tier',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onContinue,
                  child: const Text("I've saved it — continue"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
