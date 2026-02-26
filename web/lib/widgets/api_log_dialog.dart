import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/client.dart';

String formatApiLogEntry(ApiLogEntry entry) {
  final buf = StringBuffer();
  buf.writeln('${entry.method} ${entry.url}');
  buf.writeln('Status: ${entry.statusCode ?? 'ERROR'}');
  buf.writeln('Time: ${entry.duration.inMilliseconds} ms');
  if (entry.requestBody != null) {
    buf.writeln();
    buf.writeln('--- Request ---');
    try {
      buf.writeln(
          const JsonEncoder.withIndent('  ').convert(jsonDecode(entry.requestBody!)));
    } catch (_) {
      buf.writeln(entry.requestBody);
    }
  }
  if (entry.responseBody != null) {
    buf.writeln();
    buf.writeln('--- Response ---');
    try {
      buf.writeln(
          const JsonEncoder.withIndent('  ').convert(jsonDecode(entry.responseBody!)));
    } catch (_) {
      buf.writeln(entry.responseBody);
    }
  }
  if (entry.error != null) {
    buf.writeln();
    buf.writeln('--- Error ---');
    buf.writeln(entry.error);
  }
  return buf.toString();
}

void copyToClipboard(BuildContext context, String text, String label) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$label copied')),
  );
}

void showApiLogDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const ApiLogDialog(),
  );
}

class ApiLogDialog extends StatelessWidget {
  const ApiLogDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = ApiLog.instance.entries;
    final last = entries.isNotEmpty ? entries.first : null;
    final lastFormatted = last != null ? formatApiLogEntry(last) : null;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 8, 0),
              child: Row(
                children: [
                  Text('API calls',
                      style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  if (entries.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        ApiLog.instance.clear();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Clear'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (last == null)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text('No API calls recorded yet.'),
              )
            else
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Text('Last call',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          tooltip: 'Copy to clipboard',
                          onPressed: () => copyToClipboard(
                              context, lastFormatted!, 'Last API call'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: SelectableText(
                        lastFormatted!,
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                    if (entries.length > 1) ...[
                      const SizedBox(height: 24),
                      Text('History',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...entries.skip(1).map(
                            (e) => ApiLogEntryTile(entry: e),
                          ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ApiLogEntryTile extends StatelessWidget {
  const ApiLogEntryTile({super.key, required this.entry});

  final ApiLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final statusColor = entry.statusCode == null
        ? Colors.red
        : entry.statusCode! < 300
            ? Colors.green
            : entry.statusCode! < 500
                ? Colors.orange
                : Colors.red;
    final path = Uri.tryParse(entry.url)?.path ?? entry.url;
    final time =
        '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
        '${entry.timestamp.minute.toString().padLeft(2, '0')}:'
        '${entry.timestamp.second.toString().padLeft(2, '0')}';
    final formatted = formatApiLogEntry(entry);

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          entry.statusCode?.toString() ?? 'ERR',
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      title: Text(
        '${entry.method} $path',
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '$time  ·  ${entry.duration.inMilliseconds} ms',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: const Icon(Icons.copy, size: 16),
            tooltip: 'Copy to clipboard',
            onPressed: () => copyToClipboard(context, formatted, 'API call'),
          ),
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(0, 0, 0, 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: SelectableText(
            formatted,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    );
  }
}
