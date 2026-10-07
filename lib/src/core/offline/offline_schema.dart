class OrderSchema {
  static const tableName = 'orders';
  static const id = 'id';
  static const customerName = 'customer_name';
  static const status = 'status';
  static const synced = 'synced';
  static const updatedAt = 'updated_at';
}

class ManifestSchema {
  static const tableName = 'manifests';
  static const id = 'id';
  static const routeCode = 'route_code';
  static const totalStops = 'total_stops';
  static const synced = 'synced';
  static const updatedAt = 'updated_at';
}

class ActionLogSchema {
  static const tableName = 'action_logs';
  static const id = 'id';
  static const entityType = 'entity_type';
  static const method = 'method';
  static const endpoint = 'endpoint';
  static const payload = 'payload';
  static const attempts = 'attempts';
  static const lastError = 'last_error';
  static const createdAt = 'created_at';
}
