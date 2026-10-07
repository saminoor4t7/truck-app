import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'local_database.dart';
import 'offline_schema.dart';
import '../workmanager/sync_worker.dart';

enum MutationMethod { post, put }

class ActionLog {
  const ActionLog({
    required this.id,
    required this.entityType,
    required this.method,
    required this.endpoint,
    required this.payload,
    required this.createdAt,
    required this.attempts,
    this.lastError,
  });

  final String id;
  final String entityType;
  final MutationMethod method;
  final String endpoint;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attempts;
  final String? lastError;

  factory ActionLog.fromMap(Map<String, Object?> row) => ActionLog(
    id: row[ActionLogSchema.id]! as String,
    entityType: row[ActionLogSchema.entityType]! as String,
    method: MutationMethod.values.byName(
      row[ActionLogSchema.method]! as String,
    ),
    endpoint: row[ActionLogSchema.endpoint]! as String,
    payload:
        jsonDecode(row[ActionLogSchema.payload]! as String)
            as Map<String, dynamic>,
    createdAt: DateTime.parse(row[ActionLogSchema.createdAt]! as String),
    attempts: row[ActionLogSchema.attempts]! as int,
    lastError: row[ActionLogSchema.lastError] as String?,
  );
}

class OutboxQueue {
  OutboxQueue({LocalDatabase? localDatabase})
    : _localDatabase = localDatabase ?? LocalDatabase.instance;

  final LocalDatabase _localDatabase;
  static const _uuid = Uuid();

  Future<ActionLog> enqueue({
    required String entityType,
    required MutationMethod method,
    required String endpoint,
    required Map<String, dynamic> payload,
    DatabaseExecutor? transaction,
  }) async {
    if (!endpoint.startsWith('/')) {
      throw ArgumentError.value(endpoint, 'endpoint', 'Must begin with "/"');
    }
    final action = ActionLog(
      id: _uuid.v4(),
      entityType: entityType,
      method: method,
      endpoint: endpoint,
      payload: payload,
      createdAt: DateTime.now().toUtc(),
      attempts: 0,
    );
    final executor = transaction ?? await _localDatabase.database;
    await executor.insert(ActionLogSchema.tableName, {
      ActionLogSchema.id: action.id,
      ActionLogSchema.entityType: action.entityType,
      ActionLogSchema.method: action.method.name,
      ActionLogSchema.endpoint: action.endpoint,
      ActionLogSchema.payload: jsonEncode(action.payload),
      ActionLogSchema.attempts: 0,
      ActionLogSchema.createdAt: action.createdAt.toIso8601String(),
    });
    if (transaction == null) await const SyncWorker().schedule();
    return action;
  }

  Future<List<ActionLog>> pending() async {
    final db = await _localDatabase.database;
    final rows = await db.query(
      ActionLogSchema.tableName,
      orderBy: '${ActionLogSchema.createdAt} ASC',
    );
    return rows.map(ActionLog.fromMap).toList(growable: false);
  }

  Future<void> markComplete(String id) async {
    final db = await _localDatabase.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        ActionLogSchema.tableName,
        columns: [ActionLogSchema.entityType, ActionLogSchema.payload],
        where: '${ActionLogSchema.id} = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return;
      final row = rows.single;
      final entityType = row[ActionLogSchema.entityType] as String;
      final payload =
          jsonDecode(row[ActionLogSchema.payload]! as String)
              as Map<String, dynamic>;
      final table = switch (entityType) {
        'order' => OrderSchema.tableName,
        'manifest' => ManifestSchema.tableName,
        _ => null,
      };
      if (table != null && payload['id'] is String) {
        await txn.delete(
          ActionLogSchema.tableName,
          where: '${ActionLogSchema.id} = ?',
          whereArgs: [id],
        );
        final pendingRows = await txn.query(
          ActionLogSchema.tableName,
          columns: [ActionLogSchema.payload],
          where: '${ActionLogSchema.entityType} = ?',
          whereArgs: [entityType],
        );
        final hasMoreForEntity = pendingRows.any((pending) {
          final pendingPayload =
              jsonDecode(pending[ActionLogSchema.payload]! as String)
                  as Map<String, dynamic>;
          return pendingPayload['id'] == payload['id'];
        });
        await txn.update(
          table,
          {OrderSchema.synced: hasMoreForEntity ? 0 : 1},
          where: 'id = ?',
          whereArgs: [payload['id']],
        );
      } else {
        await txn.delete(
          ActionLogSchema.tableName,
          where: '${ActionLogSchema.id} = ?',
          whereArgs: [id],
        );
      }
    });
  }

  Future<void> markFailed(ActionLog action, Object error) async {
    final db = await _localDatabase.database;
    await db.update(
      ActionLogSchema.tableName,
      {
        ActionLogSchema.attempts: action.attempts + 1,
        ActionLogSchema.lastError: error.toString(),
      },
      where: '${ActionLogSchema.id} = ?',
      whereArgs: [action.id],
    );
  }

  Future<int> get length async {
    final db = await _localDatabase.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM ${ActionLogSchema.tableName}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
