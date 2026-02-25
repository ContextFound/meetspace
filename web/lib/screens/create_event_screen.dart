import 'package:flutter/material.dart';

import '../api/client.dart';
import '../models/event.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({
    super.key,
    required this.client,
    required this.onCreated,
  });

  final MeetSpaceApiClient client;
  final VoidCallback onCreated;

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController(text: '37.7749');
  final _lngController = TextEditingController(text: '-122.4194');
  final _urlController = TextEditingController();
  final _priceController = TextEditingController();
  final _timezoneController = TextEditingController(text: 'America/Los_Angeles');

  DateTime _startAt = DateTime.now().add(const Duration(days: 1));
  DateTime? _endAt;
  Audience _audience = Audience.adults;
  EventType _eventType = EventType.meetup;
  String? _currency;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationNameController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _urlController.dispose();
    _priceController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _error = null;
    if (!_formKey.currentState!.validate()) return;
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    if (lat == null || lng == null) {
      setState(() => _error = 'Enter valid lat and lng');
      return;
    }
    double? price;
    if (_priceController.text.trim().isNotEmpty) {
      price = double.tryParse(_priceController.text.trim());
      if (price == null || price < 0) {
        setState(() => _error = 'Enter a valid price (0 or positive)');
        return;
      }
      if (_currency == null || _currency!.isEmpty) {
        setState(() => _error = 'Currency is required when price is set');
        return;
      }
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.client.createEvent(EventCreate(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        startAt: _startAt,
        endAt: _endAt,
        timezone: _timezoneController.text.trim(),
        locationName: _locationNameController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        lat: lat,
        lng: lng,
        url: _urlController.text.trim().isEmpty
            ? null
            : _urlController.text.trim(),
        price: price,
        currency: price != null ? (_currency ?? 'USD') : null,
        audience: _audience,
        eventType: _eventType,
      ));
      if (!mounted) return;
      widget.onCreated();
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.statusCode == 403
            ? 'Your key does not have permission to create events.'
            : e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create event'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Start: ${_startAt.toIso8601String().substring(0, 16)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                trailing: TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startAt,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (date == null || !context.mounted) return;
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_startAt),
                    );
                    if (time == null || !context.mounted) return;
                    setState(() {
                      _startAt = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  },
                  child: const Text('Pick'),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _endAt == null
                      ? 'End: (optional)'
                      : 'End: ${_endAt!.toIso8601String().substring(0, 16)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                trailing: TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endAt ?? _startAt,
                      firstDate: _startAt,
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (date == null || !context.mounted) return;
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _endAt != null
                          ? TimeOfDay.fromDateTime(_endAt!)
                          : TimeOfDay.fromDateTime(_startAt),
                    );
                    if (time == null || !context.mounted) return;
                    setState(() {
                      _endAt = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  },
                  child: Text(_endAt == null ? 'Set' : 'Change'),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timezoneController,
                decoration: InputDecoration(
                  labelText: 'Timezone (IANA)',
                  border: const OutlineInputBorder(),
                  hintText: 'America/Los_Angeles',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationNameController,
                decoration: const InputDecoration(
                  labelText: 'Location name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      decoration: const InputDecoration(
                        labelText: 'Lat',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      decoration: const InputDecoration(
                        labelText: 'Lng',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (optional, 0 = free)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _currency,
                decoration: const InputDecoration(
                  labelText: 'Currency (if price set)',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                  DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                ],
                onChanged: (v) => setState(() => _currency = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Audience>(
                value: _audience,
                decoration: const InputDecoration(
                  labelText: 'Audience',
                  border: OutlineInputBorder(),
                ),
                items: Audience.values
                    .map((a) => DropdownMenuItem(
                          value: a,
                          child: Text(a.name),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _audience = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<EventType>(
                value: _eventType,
                decoration: const InputDecoration(
                  labelText: 'Event type',
                  border: OutlineInputBorder(),
                ),
                items: EventType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.name),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _eventType = v!),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create event'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
