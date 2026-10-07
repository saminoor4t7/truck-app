import 'package:uuid/uuid.dart';

import '../../../../core/offline/local_database.dart';
import '../../../../core/offline/offline_schema.dart';
import '../../../../core/offline/outbox_queue.dart';
import '../../../../core/workmanager/sync_worker.dart';

class OfflineManifestRepository {
  OfflineManifestRepository({
    LocalDatabase? localDatabase,
    OutboxQueue? outboxQueue,
  }) : _database = localDatabase ?? LocalDatabase.instance,
       _outbox = outboxQueue ?? OutboxQueue(localDatabase: localDatabase);

  final LocalDatabase _database;
  final OutboxQueue _outbox;
  static const _uuid = Uuid();

  Future<String> create({
    required String routeCode,
    required int totalStops,
  }) async {
    if (totalStops < 0) {
      throw ArgumentError.value(totalStops, 'totalStops', 'Must be non-negative');
    }
    final id = _uuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.insert(ManifestSchema.tableName, {
        ManifestSchema.id: id,
        ManifestSchema.routeCode: routeCode,
        ManifestSchema.totalStops: totalStops,
        ManifestSchema.synced: 0,
        ManifestSchema.updatedAt: now,
      });
      await _outbox.enqueue(
        entityType: 'manifest',
        method: MutationMethod.post,
        endpoint: '/manifests',
        payload: {
          'id': id,
          'routeCode': routeCode,
          'totalStops': totalStops,
          'updatedAt': now,
        },
        transaction: txn,
      );
    });
    await const SyncWorker().schedule();
    return id;
  }

  Future<List<Map<String, Object?>>> list() async {
    final db = await _database.database;
    return db.query(
      ManifestSchema.tableName,
      orderBy: '${ManifestSchema.updatedAt} DESC',
    );
  }
}
