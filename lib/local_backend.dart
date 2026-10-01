// =============================================================================
// local_backend.dart
//
// Local, offline replacement layer for Firebase.
//
// This file provides a drop-in local backend that mimics the small subset of
// the Firebase APIs previously used by the SmartConnect app:
//   * Cloud Firestore  -> LocalFirestore / LocalCollectionRef / LocalDocRef
//   * Firebase Auth    -> LocalAuth / LocalUser / LocalUserCredential
//   * Timestamp + FieldValue compatibility helpers
//
// All data is persisted as JSON inside the application documents directory,
// so the app keeps working fully offline with no Firebase project attached.
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

// -----------------------------------------------------------------------------
// Timestamp (compatibility with package:cloud_firestore)
// -----------------------------------------------------------------------------

/// A point in time, mimicking `cloud_firestore.Timestamp`.
class Timestamp implements Comparable<Timestamp> {
  final int _microseconds;

  const Timestamp._(this._microseconds);

  static Timestamp now() =>
      Timestamp.fromMicrosecondsSinceEpoch(DateTime.now().microsecondsSinceEpoch);

  static Timestamp fromDate(DateTime date) =>
      Timestamp.fromMicrosecondsSinceEpoch(date.microsecondsSinceEpoch);

  static Timestamp fromMicrosecondsSinceEpoch(int microseconds) =>
      Timestamp._(microseconds);

  static Timestamp fromMillisecondsSinceEpoch(int milliseconds) =>
      Timestamp._(milliseconds * 1000);

  DateTime toDate() => DateTime.fromMicrosecondsSinceEpoch(_microseconds);

  int get microsecondsSinceEpoch => _microseconds;

  int get millisecondsSinceEpoch => _microseconds ~/ 1000;

  @override
  int compareTo(Timestamp other) => _microseconds.compareTo(other._microseconds);

  @override
  bool operator ==(Object other) =>
      other is Timestamp && other._microseconds == _microseconds;

  @override
  int get hashCode => _microseconds.hashCode;

  @override
  String toString() =>
      'Timestamp(seconds=${_microseconds ~/ 1000000}, nanoseconds=${(_microseconds % 1000000) * 1000})';
}

// -----------------------------------------------------------------------------
// FieldValue (compatibility with package:cloud_firestore)
// -----------------------------------------------------------------------------

/// Sentinel written into documents and resolved to the current
/// [Timestamp] at write time.
class ServerTimestampSentinel {
  const ServerTimestampSentinel._();

  @override
  String toString() => 'FieldValue.serverTimestamp()';
}

/// Mimics `cloud_firestore.FieldValue` (only `serverTimestamp` is needed).
class FieldValue {
  const FieldValue._();

  static ServerTimestampSentinel serverTimestamp() =>
      const ServerTimestampSentinel._();
}

// -----------------------------------------------------------------------------
// Exceptions
// -----------------------------------------------------------------------------

/// Mimics `FirebaseAuthException` with the same error codes.
class LocalAuthException implements Exception {
  final String code;
  final String? message;

  const LocalAuthException(this.code, [this.message]);

  @override
  String toString() =>
      'LocalAuthException($code${message == null ? '' : ', $message'})';
}

// -----------------------------------------------------------------------------
// Users / credentials
// -----------------------------------------------------------------------------

class LocalUser {
  final String uid;
  final String? email;

  LocalUser({required this.uid, this.email});

  @override
  String toString() => 'LocalUser(uid: $uid, email: $email)';
}

class LocalUserCredential {
  final LocalUser user;

  LocalUserCredential(this.user);
}

// -----------------------------------------------------------------------------
// Snapshots
// -----------------------------------------------------------------------------

/// Result of a collection / query read (mimics `QuerySnapshot`).
class LocalQuerySnapshot {
  final List<LocalQueryDocSnapshot> docs;

  LocalQuerySnapshot(this.docs);

  bool get isEmpty => docs.isEmpty;
  bool get isNotEmpty => docs.isNotEmpty;
  int get size => docs.length;
}

/// Result of a single-document read (mimics `DocumentSnapshot`).
class LocalDocSnapshot {
  final String id;

  /// Collection path this document belongs to (used by [reference]).
  final String? collectionPath;

  final Map<String, dynamic>? _data;

  LocalDocSnapshot(this.id, this._data, [this.collectionPath]);

  bool get exists => _data != null;

  /// Mimics `DocumentSnapshot.reference`.
  LocalDocRef get reference =>
      LocalDocRef(collectionPath: collectionPath ?? '', id: id);

  Map<String, dynamic>? data() =>
      _data == null ? null : Map<String, dynamic>.from(_data);

  dynamic operator [](String key) => _data?[key];
}

/// A single document inside a [LocalQuerySnapshot]
/// (mimics `QueryDocumentSnapshot`).
class LocalQueryDocSnapshot extends LocalDocSnapshot {
  LocalQueryDocSnapshot(String id, Map<String, dynamic> data,
      [String? collectionPath])
      : super(id, data, collectionPath);

  @override
  Map<String, dynamic> data() => Map<String, dynamic>.from(_data!);
}

// -----------------------------------------------------------------------------
// Queries
// -----------------------------------------------------------------------------

class _WhereClause {
  final String field;
  final String op;
  final dynamic value;

  _WhereClause(this.field, this.op, this.value);
}

class _OrderClause {
  final String field;
  final bool descending;

  _OrderClause(this.field, this.descending);
}

int _compareValues(dynamic a, dynamic b) {
  if (a is Timestamp && b is Timestamp) return a.compareTo(b);
  if (a is DateTime && b is DateTime) return a.compareTo(b);
  if (a is num && b is num) return a.compareTo(b);
  if (a is String && b is String) return a.compareTo(b);
  if (a is bool && b is bool) return (a == b) ? 0 : (a ? 1 : -1);
  return a.toString().compareTo(b.toString());
}

bool _matchesWhere(dynamic actual, _WhereClause w) {
  switch (w.op) {
    case '==':
      if (actual is Timestamp && w.value is Timestamp) {
        return actual == w.value;
      }
      return actual == w.value;
    case '!=':
      return actual != w.value;
    case '>':
      if (actual == null || w.value == null) return false;
      return _compareValues(actual, w.value) > 0;
    case '>=':
      if (actual == null || w.value == null) return false;
      return _compareValues(actual, w.value) >= 0;
    case '<':
      if (actual == null || w.value == null) return false;
      return _compareValues(actual, w.value) < 0;
    case '<=':
      if (actual == null || w.value == null) return false;
      return _compareValues(actual, w.value) <= 0;
    case 'in':
      return (w.value as List).contains(actual);
    default:
      return false;
  }
}

/// A chainable query over a collection (mimics the `Query` API).
class LocalQuery {
  final LocalCollectionRef _ref;
  final List<_WhereClause> _wheres;
  final List<_OrderClause> _orders;
  final int? _limit;

  LocalQuery._(this._ref, [List<_WhereClause>? wheres, List<_OrderClause>? orders, this._limit])
      : _wheres = wheres ?? <_WhereClause>[],
        _orders = orders ?? <_OrderClause>[];

  LocalQuery where(String field,
      {dynamic isEqualTo,
      dynamic isNotEqualTo,
      dynamic isGreaterThan,
      dynamic isGreaterThanOrEqualTo,
      dynamic isLessThan,
      dynamic isLessThanOrEqualTo,
      dynamic whereIn}) {
    final clauses = List<_WhereClause>.from(_wheres);
    void add(String op, dynamic v) {
      if (v != null) clauses.add(_WhereClause(field, op, v));
    }

    add('==', isEqualTo);
    add('!=', isNotEqualTo);
    add('>', isGreaterThan);
    add('>=', isGreaterThanOrEqualTo);
    add('<', isLessThan);
    add('<=', isLessThanOrEqualTo);
    add('in', whereIn);
    return LocalQuery._(_ref, clauses, _orders, _limit);
  }

  LocalQuery orderBy(String field, {bool descending = false}) {
    final orders = List<_OrderClause>.from(_orders)..add(_OrderClause(field, descending));
    return LocalQuery._(_ref, _wheres, orders, _limit);
  }

  LocalQuery limit(int count) => LocalQuery._(_ref, _wheres, _orders, count);

  LocalQuerySnapshot _execute() {
    final source = LocalBackend.instance.collectionData(_ref.path);
    var docs = source.entries
        .map((e) => LocalQueryDocSnapshot(e.key, e.value, _ref.path))
        .toList();

    for (final w in _wheres) {
      docs = docs.where((d) => _matchesWhere(d[w.field], w)).toList();
    }

    if (_orders.isNotEmpty) {
      docs.sort((a, b) {
        for (final o in _orders) {
          final av = a[o.field];
          final bv = b[o.field];
          int c;
          if (av == null && bv == null) {
            c = 0;
          } else if (av == null) {
            c = -1;
          } else if (bv == null) {
            c = 1;
          } else {
            c = _compareValues(av, bv);
          }
          if (c != 0) return o.descending ? -c : c;
        }
        return a.id.compareTo(b.id);
      });
    }

    final capped = (_limit != null && docs.length > _limit)
        ? docs.sublist(0, _limit)
        : docs;
    return LocalQuerySnapshot(List<LocalQueryDocSnapshot>.unmodifiable(capped));
  }

  Future<LocalQuerySnapshot> get() async => _execute();

  Stream<LocalQuerySnapshot> snapshots() {
    late final StreamController<LocalQuerySnapshot> controller;
    void emit() {
      if (!controller.isClosed) controller.add(_execute());
    }

    controller = StreamController<LocalQuerySnapshot>.broadcast(
      onListen: () {
        emit();
        LocalBackend.instance.addCollectionListener(_ref.path, emit);
      },
      onCancel: () => LocalBackend.instance.removeCollectionListener(_ref.path, emit),
    );
    return controller.stream;
  }
}

// -----------------------------------------------------------------------------
// References
// -----------------------------------------------------------------------------

/// Mimics `CollectionReference`.
class LocalCollectionRef {
  final String path;

  LocalCollectionRef(this.path);

  LocalDocRef doc([String? id]) {
    final docId = (id == null || id.isEmpty)
        ? LocalBackend.instance.newDocId()
        : id;
    return LocalDocRef(collectionPath: path, id: docId);
  }

  LocalQuery where(String field,
      {dynamic isEqualTo,
      dynamic isNotEqualTo,
      dynamic isGreaterThan,
      dynamic isGreaterThanOrEqualTo,
      dynamic isLessThan,
      dynamic isLessThanOrEqualTo,
      dynamic whereIn}) {
    return LocalQuery._(this).where(field,
        isEqualTo: isEqualTo,
        isNotEqualTo: isNotEqualTo,
        isGreaterThan: isGreaterThan,
        isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
        isLessThan: isLessThan,
        isLessThanOrEqualTo: isLessThanOrEqualTo,
        whereIn: whereIn);
  }

  LocalQuery orderBy(String field, {bool descending = false}) =>
      LocalQuery._(this).orderBy(field, descending: descending);

  LocalQuery limit(int count) => LocalQuery._(this).limit(count);

  Future<LocalQuerySnapshot> get() => LocalQuery._(this).get();

  Stream<LocalQuerySnapshot> snapshots() => LocalQuery._(this).snapshots();

  Future<LocalDocRef> add(Map<String, dynamic> data) async {
    final ref = doc();
    await ref.set(data);
    return ref;
  }
}

/// Mimics `DocumentReference`.
class LocalDocRef {
  final String collectionPath;
  final String id;

  LocalDocRef({required this.collectionPath, required this.id});

  String get fullPath => '$collectionPath/$id';

  /// Opens a sub-collection under this document, e.g.
  /// `users/<uid>/notifications`.
  LocalCollectionRef collection(String subPath) =>
      LocalCollectionRef('$collectionPath/$id/$subPath');

  Future<LocalDocSnapshot> get() async =>
      LocalBackend.instance.getDoc(fullPath, id);

  Future<void> set(Map<String, dynamic> data) =>
      LocalBackend.instance.setDoc(fullPath, data);

  Future<void> update(Map<String, dynamic> data) =>
      LocalBackend.instance.updateDoc(fullPath, data);

  Future<void> delete() => LocalBackend.instance.deleteDoc(fullPath);

  Stream<LocalDocSnapshot> snapshots() {
    late final StreamController<LocalDocSnapshot> controller;
    void emit() {
      if (!controller.isClosed) {
        controller.add(LocalBackend.instance.getDoc(fullPath, id));
      }
    }

    controller = StreamController<LocalDocSnapshot>.broadcast(
      onListen: () {
        emit();
        LocalBackend.instance.addDocListener(fullPath, emit);
      },
      onCancel: () => LocalBackend.instance.removeDocListener(fullPath, emit),
    );
    return controller.stream;
  }

  @override
  bool operator ==(Object other) =>
      other is LocalDocRef && other.fullPath == fullPath;

  @override
  int get hashCode => fullPath.hashCode;

  @override
  String toString() => 'LocalDocRef($fullPath)';
}

/// Mimics `WriteBatch`.
class LocalWriteBatch {
  final List<Future<void> Function()> _operations = [];

  void set(LocalDocRef ref, Map<String, dynamic> data) =>
      _operations.add(() => ref.set(data));

  void update(LocalDocRef ref, Map<String, dynamic> data) =>
      _operations.add(() => ref.update(data));

  void delete(LocalDocRef ref) => _operations.add(() => ref.delete());

  Future<void> commit() async {
    for (final op in _operations) {
      await op();
    }
    _operations.clear();
  }
}

/// Mimics `FirebaseFirestore.instance`.
class LocalFirestore {
  static final LocalFirestore instance = LocalFirestore._();

  LocalFirestore._();

  LocalCollectionRef collection(String path) => LocalCollectionRef(path);

  LocalWriteBatch batch() => LocalWriteBatch();
}

// -----------------------------------------------------------------------------
// Auth
// -----------------------------------------------------------------------------

/// Mimics `FirebaseAuth.instance`, backed by the local `users` collection.
///
/// A built-in administrator account is seeded on first run:
///   username: admin
///   password: admin
class LocalAuth {
  static final LocalAuth instance = LocalAuth._();

  LocalAuth._();

  LocalUser? _currentUser;

  LocalUser? get currentUser => _currentUser;

  void _restoreSession(String uid) {
    final users = LocalBackend.instance.collectionData('users');
    final data = users[uid];
    if (data == null) return;
    _currentUser =
        LocalUser(uid: uid, email: data['email']?.toString());
  }

  Future<LocalUserCredential> signInWithEmailAndPassword(
      {required String email, required String password}) async {
    await LocalBackend.ensureReady();
    final users = LocalBackend.instance.collectionData('users');

    String? matchedUid;
    for (final entry in users.entries) {
      final storedEmail =
          (entry.value['email'] ?? '').toString().trim().toLowerCase();
      if (storedEmail.isNotEmpty && storedEmail == email.trim().toLowerCase()) {
        matchedUid = entry.key;
        break;
      }
    }

    if (matchedUid == null) {
      throw const LocalAuthException('user-not-found');
    }

    final data = users[matchedUid]!;
    if ((data['password'] ?? '').toString() != password) {
      throw const LocalAuthException('wrong-password');
    }

    _currentUser = LocalUser(uid: matchedUid, email: email);
    LocalBackend.instance.setCurrentUid(matchedUid);
    return LocalUserCredential(_currentUser!);
  }

  Future<LocalUserCredential> createUserWithEmailAndPassword(
      {required String email, required String password}) async {
    await LocalBackend.ensureReady();
    final users = LocalBackend.instance.collectionData('users');

    for (final data in users.values) {
      final storedEmail =
          (data['email'] ?? '').toString().trim().toLowerCase();
      if (storedEmail.isNotEmpty && storedEmail == email.trim().toLowerCase()) {
        throw const LocalAuthException('email-already-in-use');
      }
    }

    if (password.length < 5) {
      throw const LocalAuthException('weak-password');
    }

    final uid = LocalBackend.instance.newDocId();
    _currentUser = LocalUser(uid: uid, email: email);
    LocalBackend.instance.setCurrentUid(uid);
    return LocalUserCredential(_currentUser!);
  }

  Future<void> signOut() async {
    _currentUser = null;
    LocalBackend.instance.setCurrentUid(null);
  }
}

// -----------------------------------------------------------------------------
// Backend core
// -----------------------------------------------------------------------------

/// The local persistence engine: stores every collection as
/// `collections/<path>/<docId> -> data` and writes the whole dataset as a
/// single JSON document in the application documents directory.
class LocalBackend {
  static final LocalBackend instance = LocalBackend._();

  LocalBackend._();

  static Future<void>? _initFuture;
  static bool _initialized = false;

  Map<String, Map<String, Map<String, dynamic>>> _collections = {};
  String? _currentUid;
  String? _filePath;
  Timer? _saveTimer;
  final Random _random = Random();
  final Map<String, List<void Function()>> _listeners = {};

  /// Must be awaited once from `main()` before `runApp`.
  static Future<void> init() => ensureReady();

  /// Lazily initialises the backend (safe to call multiple times).
  static Future<void> ensureReady() =>
      _initFuture ??= instance._initInternal();

  Future<void> _initInternal() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _filePath =
          '${dir.path}${Platform.pathSeparator}smartconnect_local_data.json';
    } catch (_) {
      // Unsupported platform (e.g. flutter test): keep everything in memory.
      _filePath = null;
    }
    _loadFromDisk();
    _ensureSeedData();
    if (_currentUid != null) {
      LocalAuth.instance._restoreSession(_currentUid!);
    }
  }

  // ---------------------------------------------------------------------------
  // Seed data
  // ---------------------------------------------------------------------------

  void _ensureSeedData() {
    final users = collectionData('users');
    var changed = false;

    if (!users.containsKey('admin')) {
      users['admin'] = {
        'uid': 'admin',
        'username': 'admin',
        'full_name': 'Administrator',
        'phone_number': 'admin',
        'email': 'admin@smartconnect.tz',
        'password': 'admin',
        'role': 'admin',
        'is_admin': true,
        'is_active': true,
        'status': 'active',
        'created_at': Timestamp.now(),
      };
      changed = true;
    }

    if (changed) scheduleSave();
  }

  // ---------------------------------------------------------------------------
  // Public accessors
  // ---------------------------------------------------------------------------

  Map<String, Map<String, dynamic>> collectionData(String path) =>
      _collections.putIfAbsent(path, () => <String, Map<String, dynamic>>{});

  String newDocId() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final rnd = String.fromCharCodes(
      List.generate(12, (_) => chars.codeUnitAt(_random.nextInt(chars.length))),
    );
    return '$ts$rnd';
  }

  String? get currentUid => _currentUid;

  void setCurrentUid(String? uid) {
    _currentUid = uid;
    scheduleSave();
  }

  // ---------------------------------------------------------------------------
  // Document operations
  // ---------------------------------------------------------------------------

  LocalDocSnapshot getDoc(String fullPath, String id) {
    final slash = fullPath.lastIndexOf('/');
    final colPath = fullPath.substring(0, slash);
    final data = _collections[colPath]?[id];
    return LocalDocSnapshot(
        id, data == null ? null : Map<String, dynamic>.from(data), colPath);
  }

  Future<void> setDoc(String fullPath, Map<String, dynamic> data) async {
    final slash = fullPath.lastIndexOf('/');
    final colPath = fullPath.substring(0, slash);
    final id = fullPath.substring(slash + 1);
    final col = collectionData(colPath);
    final existing = col[id] ?? <String, dynamic>{};
    // Merge semantics keep existing fields (e.g. credentials stored by other
    // flows) intact when a screen rewrites a profile document.
    existing.addAll(_resolveSentinels(data));
    col[id] = existing;
    _notifyCollection(colPath);
    _notifyDoc(fullPath);
    scheduleSave();
  }

  Future<void> updateDoc(String fullPath, Map<String, dynamic> data) async {
    final slash = fullPath.lastIndexOf('/');
    final colPath = fullPath.substring(0, slash);
    final id = fullPath.substring(slash + 1);
    final col = collectionData(colPath);
    final existing = col[id] ?? <String, dynamic>{};
    _applyUpdate(existing, _resolveSentinels(data));
    col[id] = existing;
    _notifyCollection(colPath);
    _notifyDoc(fullPath);
    scheduleSave();
  }

  Future<void> deleteDoc(String fullPath) async {
    final slash = fullPath.lastIndexOf('/');
    final colPath = fullPath.substring(0, slash);
    final id = fullPath.substring(slash + 1);
    _collections[colPath]?.remove(id);
    _notifyCollection(colPath);
    _notifyDoc(fullPath);
    scheduleSave();
  }

  void _applyUpdate(Map<String, dynamic> target, Map<String, dynamic> patch) {
    patch.forEach((key, value) {
      if (key.contains('.')) {
        final parts = key.split('.');
        Map<String, dynamic> cursor = target;
        for (var i = 0; i < parts.length - 1; i++) {
          final next = cursor[parts[i]];
          if (next is Map<String, dynamic>) {
            cursor = next;
          } else {
            final fresh = <String, dynamic>{};
            cursor[parts[i]] = fresh;
            cursor = fresh;
          }
        }
        cursor[parts.last] = value;
      } else {
        target[key] = value;
      }
    });
  }

  Map<String, dynamic> _resolveSentinels(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is ServerTimestampSentinel) {
        return MapEntry(key, Timestamp.now());
      }
      if (value is Map<String, dynamic>) {
        return MapEntry(key, _resolveSentinels(value));
      }
      return MapEntry(key, value);
    });
  }

  // ---------------------------------------------------------------------------
  // Listener registry
  // ---------------------------------------------------------------------------

  void addCollectionListener(String path, void Function() callback) {
    _listeners.putIfAbsent('col:$path', () => []).add(callback);
  }

  void removeCollectionListener(String path, void Function() callback) {
    _listeners['col:$path']?.remove(callback);
  }

  void addDocListener(String fullPath, void Function() callback) {
    _listeners.putIfAbsent('doc:$fullPath', () => []).add(callback);
  }

  void removeDocListener(String fullPath, void Function() callback) {
    _listeners['doc:$fullPath']?.remove(callback);
  }

  void _notifyCollection(String path) {
    final list = List<void Function()>.from(_listeners['col:$path'] ?? const []);
    for (final cb in list) {
      cb();
    }
  }

  void _notifyDoc(String fullPath) {
    final list =
        List<void Function()>.from(_listeners['doc:$fullPath'] ?? const []);
    for (final cb in list) {
      cb();
    }
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  void scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 150), _flushToDisk);
  }

  dynamic _encode(dynamic value) {
    if (value is Timestamp) {
      return {'__type__': 'timestamp', 'us': value.microsecondsSinceEpoch};
    }
    if (value is DateTime) {
      return {'__type__': 'datetime', 'us': value.microsecondsSinceEpoch};
    }
    if (value is Map<String, dynamic>) {
      return value.map((k, v) => MapEntry(k, _encode(v)));
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _encode(v)));
    }
    if (value is List) {
      return value.map(_encode).toList();
    }
    return value;
  }

  dynamic _decode(dynamic value) {
    if (value is Map) {
      final type = value['__type__'];
      if (type == 'timestamp') {
        return Timestamp.fromMicrosecondsSinceEpoch(value['us'] as int);
      }
      if (type == 'datetime') {
        return DateTime.fromMicrosecondsSinceEpoch(value['us'] as int);
      }
      return value.map((k, v) => MapEntry(k.toString(), _decode(v)));
    }
    if (value is List) {
      return value.map(_decode).toList();
    }
    return value;
  }

  void _loadFromDisk() {
    if (_filePath == null) return;
    try {
      final file = File(_filePath!);
      if (!file.existsSync()) return;
      final raw = jsonDecode(file.readAsStringSync());
      if (raw is! Map) return;
      final cols = _decode(raw['collections']);
      if (cols is Map) {
        _collections = cols.map((key, value) => MapEntry(
              key.toString(),
              (value as Map).map((docId, docData) => MapEntry(
                    docId.toString(),
                    Map<String, dynamic>.from(docData as Map),
                  )),
            ));
      }
      _currentUid = raw['current_uid']?.toString();
    } catch (_) {
      // Corrupted store: start clean rather than crash the app.
      _collections = {};
      _currentUid = null;
    }
  }

  void _flushToDisk() {
    _saveTimer = null;
    if (_filePath == null) return;
    try {
      final payload = {
        'version': 1,
        'current_uid': _currentUid,
        'collections': _encode(_collections),
      };
      final file = File(_filePath!);
      final tmp = File('${file.path}.tmp');
      tmp.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(payload),
        flush: true,
      );
      if (file.existsSync()) file.deleteSync();
      tmp.renameSync(file.path);
    } catch (_) {
      // Persistence is best-effort; the in-memory store keeps working.
    }
  }
}
