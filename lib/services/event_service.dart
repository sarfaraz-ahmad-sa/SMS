import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/school_event.dart';

/// Firestore access for calendar events. Collection: `events`.
class EventService {
  EventService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('events');

  Future<String> addEvent(SchoolEvent e) async {
    final ref = await _col.add(e.toMap());
    return ref.id;
  }

  Future<void> deleteEvent(String id) => _col.doc(id).delete();

  /// Live stream of all events.
  Stream<List<SchoolEvent>> streamEvents() {
    return _col.snapshots().map((snap) =>
        snap.docs.map((d) => SchoolEvent.fromDoc(d.id, d.data())).toList());
  }
}
