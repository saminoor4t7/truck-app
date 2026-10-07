import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'outbox_queue.dart';

class OutboxProcessor {
  OutboxProcessor({
    required this.queue,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final OutboxQueue queue;
  final http.Client _client;
  static const _apiBaseUrlKey = 'sync_api_base_url';

  static Future<void> setApiBaseUrl(String baseUrl) async {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null || !uri.hasAuthority || !const {'http', 'https'}.contains(uri.scheme)) {
      throw ArgumentError.value(baseUrl, 'baseUrl', 'Expected an absolute HTTP(S) URL');
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_apiBaseUrlKey, baseUrl.replaceFirst(RegExp(r'/$'), ''));
  }

  static Future<String?> getApiBaseUrl() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_apiBaseUrlKey);
  }

  Future<int> processPending() async {
    final baseUrl = await getApiBaseUrl();
    if (baseUrl == null || baseUrl.isEmpty) {
      throw StateError('Set the sync API base URL before syncing the outbox.');
    }
    var completed = 0;
    for (final action in await queue.pending()) {
      try {
        final uri = Uri.parse('$baseUrl${action.endpoint}');
        final request = http.Request(
          action.method == MutationMethod.post ? 'POST' : 'PUT',
          uri,
        )
          ..headers.addAll({
            'content-type': 'application/json',
            'idempotency-key': action.id,
          })
          ..body = jsonEncode(action.payload);
        final response = await _client.send(request).timeout(
              const Duration(seconds: 20),
            );
            await response.stream.drain<void>();
            if (response.statusCode < 200 || response.statusCode >= 300) {
          throw http.ClientException(
            'Sync ${action.id} failed with HTTP ${response.statusCode}',
            uri,
          );
        }
        await queue.markComplete(action.id);
        completed++;
      } catch (error) {
        await queue.markFailed(action, error);
        rethrow;
      }
    }
    return completed;
  }

  void close() => _client.close();
}
