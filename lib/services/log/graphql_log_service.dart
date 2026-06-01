import 'package:flutter/foundation.dart';

class GraphqlLogEntry {
  GraphqlLogEntry({required this.timestamp, required this.request, required this.response, required this.isError});

  final DateTime timestamp;
  final String request;
  final String response;
  final bool isError;
}

class GraphqlLogService {
  static const int _maxEntries = 200;

  static final ValueNotifier<List<GraphqlLogEntry>> _entries = ValueNotifier([]);

  static ValueListenable<List<GraphqlLogEntry>> get entries => _entries;

  static void add({
    required String request,
    required String response,
    required DateTime timestamp,
    required bool isError,
  }) {
    final next = List<GraphqlLogEntry>.from(_entries.value)
      ..insert(
        0,
        GraphqlLogEntry(
          timestamp: timestamp,
          request: request,
          response: response,
          isError: isError,
        ),
      );

    if (next.length > _maxEntries) {
      next.removeRange(_maxEntries, next.length);
    }

    _entries.value = next;
  }

  static void clear() {
    _entries.value = [];
  }
}
