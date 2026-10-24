import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/audit_event.dart';
import 'audit_repository.dart';

class FirestoreAuditRepository implements AuditRepository {
  FirestoreAuditRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<AuditEvent>> getEvents() async {
    final snapshot = await _firestore
        .collection('auditEvents')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map(_fromDocument).toList(growable: false);
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
    throw StateError(
      'Audit events are server-authoritative and cannot be written by the app.',
    );
  }

  AuditEvent _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final createdAt = data['createdAt'];
    return AuditEvent(
      id: document.id,
      actorId: data['actorId'] as String,
      eventType: data['eventType'] as String,
      entityType: data['entityType'] as String,
      entityId: data['entityId'] as String,
      before: data['before'] as String?,
      after: data['after'] as String,
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.parse(createdAt as String),
    );
  }
}
