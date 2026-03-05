import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/client.dart';
import '../models/event.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({
    super.key,
    required this.eventId,
    required this.client,
  });

  final String eventId;
  final MeetSpaceApiClient client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event'),
      ),
      body: FutureBuilder<EventResponse>(
        future: client.getEvent(eventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }
          final event = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _EventDetailContent(event: event),
          );
        },
      ),
    );
  }
}

class _EventDetailContent extends StatelessWidget {
  const _EventDetailContent({required this.event});

  final EventResponse event;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDate(DateTime dt) =>
      '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodySmall!.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 1.0,
    );

    final startDate = _formatDate(event.startAt);
    final startTime = _formatTime(event.startAt);

    String dateTimeDisplay = '$startDate $startTime';
    if (event.endAt != null) {
      final endDate = _formatDate(event.endAt!);
      final endTime = _formatTime(event.endAt!);
      dateTimeDisplay += endDate == startDate
          ? ' - $endTime'
          : ' - $endDate $endTime';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(event.title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),

        _LabeledField(
          label: 'DATE & TIME',
          labelStyle: labelStyle,
          child: Text(
            '$dateTimeDisplay  ·  ${event.timezone}',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 20),

        _LabeledField(
          label: 'LOCATION',
          labelStyle: labelStyle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.locationName, style: theme.textTheme.bodyMedium),
              if (event.address != null && event.address!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(event.address!, style: theme.textTheme.bodySmall),
                ),
            ],
          ),
        ),

        if (event.description != null && event.description!.isNotEmpty) ...[
          const SizedBox(height: 20),
          _LabeledField(
            label: 'DESCRIPTION',
            labelStyle: labelStyle,
            child: Text(event.description!, style: theme.textTheme.bodyMedium),
          ),
        ],

        const SizedBox(height: 20),
        _LabeledField(
          label: 'AUDIENCE',
          labelStyle: labelStyle,
          child: Text(
            _capitalize(event.audience),
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 20),
        _LabeledField(
          label: 'EVENT TYPE',
          labelStyle: labelStyle,
          child: Text(
            _capitalize(event.eventType),
            style: theme.textTheme.bodyMedium,
          ),
        ),

        if (event.cost != null && event.cost!.isNotEmpty) ...[
          const SizedBox(height: 20),
          _LabeledField(
            label: 'COST',
            labelStyle: labelStyle,
            child: Text(event.cost!, style: theme.textTheme.bodyMedium),
          ),
        ],

        if (event.url != null && event.url!.isNotEmpty) ...[
          const SizedBox(height: 20),
          _LabeledField(
            label: 'LINK',
            labelStyle: labelStyle,
            child: GestureDetector(
              onTap: () => launchUrl(
                Uri.parse(event.url!),
                mode: LaunchMode.externalApplication,
              ),
              child: Text(
                event.url!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.labelStyle,
    required this.child,
  });

  final String label;
  final TextStyle labelStyle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
