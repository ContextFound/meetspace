import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final start = event.startAt;
    final dateStr = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final timeStr = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          event.title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          '$dateStr $timeStr · ${event.timezone}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Text(
          event.locationName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (event.address != null && event.address!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            event.address!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        if (event.description != null && event.description!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            event.description!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        const SizedBox(height: 8),
        Text(
          '${event.audience} · ${event.eventType}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (event.price != null) ...[
          const SizedBox(height: 8),
          Text(
            event.currency != null
                ? '${event.price} ${event.currency}'
                : '${event.price}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}
