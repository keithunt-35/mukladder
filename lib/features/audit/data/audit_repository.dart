import '../domain/audit_event.dart';

abstract interface class AuditRepository {
  Future<List<AuditEvent>> getEvents();

  Future<AuditEvent> recordEvent({
    required String actorId,
    required String eventType,
    required String entityType,
    required String entityId,
    required String? before,
    required String after,
    required DateTime createdAt,
  });
}
