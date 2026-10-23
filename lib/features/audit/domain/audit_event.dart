class AuditEvent {
  const AuditEvent({
    required this.id,
    required this.actorId,
    required this.eventType,
    required this.entityType,
    required this.entityId,
    required this.before,
    required this.after,
    required this.createdAt,
  });

  final String id;
  final String actorId;
  final String eventType;
  final String entityType;
  final String entityId;
  final String? before;
  final String after;
  final DateTime createdAt;
}
