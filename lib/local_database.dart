import 'dart:async';
import 'dart:math';

class Timestamp {
  final DateTime _value;
  Timestamp._(this._value);
  factory Timestamp.now() => Timestamp._(DateTime.now());
  factory Timestamp.fromDate(DateTime value) => Timestamp._(value);
  DateTime toDate() => _value;
}

class FieldValue {
  const FieldValue._();
  static FieldValue serverTimestamp() => FieldValue._();
}

class DocumentSnapshot {
  final String id;
  final Map<String, dynamic>? _data;
  DocumentSnapshot(this.id, Map<String, dynamic>? data)
    : _data = data == null ? null : Map<String, dynamic>.from(data);
  bool get exists => _data != null;
  Map<String, dynamic>? data() =>
      _data == null ? null : Map<String, dynamic>.from(_data!);
  dynamic operator [](String key) => _data?[key];
  DocumentReference get reference => DocumentReference('', id);
}

class QuerySnapshot {
  final List<DocumentSnapshot> docs;
  QuerySnapshot(this.docs);
}

class DocumentReference {
  final String collectionName;
  final String id;
  DocumentReference(this.collectionName, this.id);
  Future<DocumentSnapshot> get() async =>
      LocalDatabase.instance._get(collectionName, id);
  Stream<DocumentSnapshot> snapshots() =>
      LocalDatabase.instance._docStream(collectionName, id);
  Future<void> set(Map<String, dynamic> data) async =>
      LocalDatabase.instance._set(collectionName, id, data);
  Future<void> update(Map<String, dynamic> data) async =>
      LocalDatabase.instance._update(collectionName, id, data);
  Future<void> delete() async =>
      LocalDatabase.instance._delete(collectionName, id);
  Query collection(String name) => Query('$collectionName/$id/$name');
}

class Query {
  final String collectionName;
  final List<_Filter> _filters;
  String? _orderField;
  bool _descending = false;
  int? _limit;
  Query(this.collectionName, [this._filters = const []]);
  Query where(
    String field, {
    dynamic isEqualTo,
    dynamic isGreaterThanOrEqualTo,
    dynamic isLessThan,
  }) {
    return Query(collectionName, [
        ..._filters,
        _Filter(field, isEqualTo, isGreaterThanOrEqualTo, isLessThan),
      ])
      .._orderField = _orderField
      .._descending = _descending
      .._limit = _limit;
  }

  Query orderBy(String field, {bool descending = false}) => this
    .._orderField = field
    .._descending = descending;
  Query limit(int value) => this.._limit = value;
  DocumentReference doc([String? id]) =>
      DocumentReference(collectionName, id ?? LocalDatabase.instance._id());
  Future<DocumentReference> add(Map<String, dynamic> data) async {
    final ref = doc();
    await ref.set(data);
    return ref;
  }

  Future<QuerySnapshot> get() async => LocalDatabase.instance._query(this);
  Stream<QuerySnapshot> snapshots() =>
      LocalDatabase.instance._queryStream(this);
}

class _Filter {
  final String field;
  final dynamic equals;
  final dynamic gte;
  final dynamic lt;
  _Filter(this.field, this.equals, this.gte, this.lt);
}

class WriteBatch {
  final List<Future<void> Function()> _writes = [];
  void set(DocumentReference ref, Map<String, dynamic> data) =>
      _writes.add(() => ref.set(data));
  void update(DocumentReference ref, Map<String, dynamic> data) =>
      _writes.add(() => ref.update(data));
  void delete(DocumentReference ref) => _writes.add(ref.delete);
  Future<void> commit() async {
    for (final write in _writes) await write();
  }
}

class LocalDatabase {
  LocalDatabase._() {
    _seed();
  }
  static final instance = LocalDatabase._();
  final Map<String, Map<String, Map<String, dynamic>>> _store = {};
  final Map<String, StreamController<QuerySnapshot>> _streams = {};
  final Map<String, StreamController<DocumentSnapshot>> _docStreams = {};
  int _sequence = 0;

  Query collection(String name) => Query(name);
  WriteBatch batch() => WriteBatch();
  DocumentReference _ref(String collection, String id) =>
      DocumentReference(collection, id);
  String _id() =>
      '${DateTime.now().microsecondsSinceEpoch}_${_sequence++}_${Random().nextInt(9999)}';
  void _seed() {
    _store['users'] = {
      'admin-uid': {
        'username': 'admin',
        'full_name': 'Administrator',
        'role': 'admin',
        'is_active': true,
        'status': 'active',
        'phone_number': 'admin',
      },
    };
  }

  Map<String, Map<String, dynamic>> _collection(String name) =>
      _store.putIfAbsent(name, () => {});
  Future<DocumentSnapshot> _get(String c, String id) async =>
      DocumentSnapshot(id, _collection(c)[id]);
  Future<void> _set(String c, String id, Map<String, dynamic> data) async {
    _collection(c)[id] = _normalise(data);
    _notify(c, id);
  }

  Future<void> _update(String c, String id, Map<String, dynamic> data) async {
    final current = _collection(c)[id] ?? {};
    current.addAll(_normalise(data));
    _collection(c)[id] = current;
    _notify(c, id);
  }

  Future<void> _delete(String c, String id) async {
    _collection(c).remove(id);
    _notify(c, id);
  }

  Map<String, dynamic> _normalise(Map<String, dynamic> data) =>
      data.map((k, v) => MapEntry(k, v is FieldValue ? Timestamp.now() : v));
  QuerySnapshot _query(Query q) {
    var docs = _collection(q.collectionName).entries
        .map((e) => DocumentSnapshot(e.key, e.value))
        .where(
          (d) => q._filters.every((f) {
            final v = d[f.field];
            if (f.equals != null && v != f.equals) return false;
            if (f.gte != null && _compare(v, f.gte) < 0) return false;
            if (f.lt != null && _compare(v, f.lt) >= 0) return false;
            return true;
          }),
        )
        .toList();
    if (q._orderField != null)
      docs.sort(
        (a, b) =>
            _compare(a[q._orderField!], b[q._orderField!]) *
            (q._descending ? -1 : 1),
      );
    if (q._limit != null && docs.length > q._limit!)
      docs = docs.take(q._limit!).toList();
    return QuerySnapshot(docs);
  }

  int _compare(dynamic a, dynamic b) {
    final av = a is Timestamp ? a.toDate() : a;
    final bv = b is Timestamp ? b.toDate() : b;
    if (av is Comparable && bv is Comparable) return av.compareTo(bv);
    return av.toString().compareTo(bv.toString());
  }

  Stream<QuerySnapshot> _queryStream(Query q) {
    final key = q.collectionName;
    final controller = _streams.putIfAbsent(
      key,
      () => StreamController<QuerySnapshot>.broadcast(),
    );
    return Stream<QuerySnapshot>.multi((multi) {
      multi.add(_query(q));
      final sub = controller.stream.listen((_) => multi.add(_query(q)));
      multi.onCancel = sub.cancel;
    });
  }

  Stream<DocumentSnapshot> _docStream(String c, String id) {
    final key = '$c/$id';
    final controller = _docStreams.putIfAbsent(
      key,
      () => StreamController<DocumentSnapshot>.broadcast(),
    );
    return Stream<DocumentSnapshot>.multi((multi) {
      _get(c, id).then(multi.add);
      final sub = controller.stream.listen((_) => _get(c, id).then(multi.add));
      multi.onCancel = sub.cancel;
    });
  }

  void _notify(String c, String id) {
    _streams[c]?.add(_query(Query(c)));
    _docStreams['$c/$id']?.add(DocumentSnapshot(id, _collection(c)[id]));
  }
}
