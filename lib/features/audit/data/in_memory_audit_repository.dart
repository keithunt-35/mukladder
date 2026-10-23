import '../domain/audit_event.dart';
import 'audit_repository.dart';

class InMemoryAuditRepository implements AuditRepository {
  final List<AuditEvent> _events = [];

  @override
  Future<List<AuditEvent>> getEvents() async {
    return List.unmodifiable(_events);
  }

  @override
  Future<AuditEvent> recordEvent({
    required String actorId,
    required String eventType,
    required String entityType,
    required String entityId,
    required String? before,
    required String after,
    required DateTime createdAt,
  }) async {
    final event = AuditEvent(
      id: 'audit-${_events.length + 1}',
      actorId: actorId,
      eventType: eventType,
      entityType: entityType,
      entityId: entityId,
      before: before,
      after: after,
      createdAt: createdAt,
    );
    _events.add(event);
    return event;
  }
}
