import 'package:uuid/uuid.dart';

import '../../../../core/offline/local_database.dart';
import '../../../../core/offline/offline_schema.dart';
import '../../../../core/offline/outbox_queue.dart';
import '../../../../core/workmanager/sync_worker.dart';

class OfflineOrderRepository {
  OfflineOrderRepository({
    LocalDatabase? localDatabase,
    OutboxQueue? outboxQueue,
  }) : _database = localDatabase ?? LocalDatabase.instance,
       _outbox = outboxQueue ?? OutboxQueue(localDatabase: localDatabase);

  final LocalDatabase _database;
  final OutboxQueue _outbox;
  static const _uuid = Uuid();

  Future<String> create({
    required String customerName,
    required String status,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.insert(OrderSchema.tableName, {
        OrderSchema.id: id,
        OrderSchema.customerName: customerName,
        OrderSchema.status: status,
        OrderSchema.synced: 0,
        OrderSchema.updatedAt: now,
      });
      await _outbox.enqueue(
        entityType: 'order',
        method: MutationMethod.post,
        endpoint: '/orders',
        payload: {
          'id': id,
          'customerName': customerName,
          'status': status,
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
    return db.query(OrderSchema.tableName, orderBy: '${OrderSchema.updatedAt} DESC');
  }

  Future<void> updateStatus(String id, String status) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final db = await _database.database;
    await db.transaction((txn) async {
      final updated = await txn.update(
        OrderSchema.tableName,
        {
          OrderSchema.status: status,
          OrderSchema.synced: 0,
          OrderSchema.updatedAt: now,
        },
        where: '${OrderSchema.id} = ?',
        whereArgs: [id],
      );
      if (updated == 0) throw StateError('Order $id does not exist.');
      await _outbox.enqueue(
        entityType: 'order',
        method: MutationMethod.put,
        endpoint: '/orders/$id',
        payload: {'id': id, 'status': status, 'updatedAt': now},
        transaction: txn,
      );
    });
    await const SyncWorker().schedule();
  }

  Future<int> get pendingCount => _outbox.length;
}
