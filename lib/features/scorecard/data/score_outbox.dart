import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/hole_score.dart';

enum QueuedScoreStatus { pending, blocked }

/// A single immutable, idempotent score submission. The original actor and
/// server version travel with the payload, even after a device restart.
class QueuedScore {
  const QueuedScore({
    required this.id, required this.actorId, required this.roundId,
    required this.playerId, required this.holeNumber, required this.strokes,
    required this.putts, required this.penaltyStrokes, required this.sandShots,
    required this.fairway, required this.greenInRegulation,
    required this.expectedExists, required this.expectedUpdatedAt,
    required this.status, this.error,
  });
  final String id, actorId, roundId, playerId;
  final int holeNumber, strokes, putts, penaltyStrokes, sandShots;
  final String? fairway;
  final bool? greenInRegulation;
  final bool expectedExists;
  final DateTime? expectedUpdatedAt;
  final QueuedScoreStatus status;
  final String? error;

  Map<String, Object?> toMap() => {
    'id': id, 'actor_id': actorId, 'round_id': roundId,
    'player_id': playerId, 'hole_number': holeNumber, 'strokes': strokes,
    'putts': putts, 'penalty_strokes': penaltyStrokes, 'sand_shots': sandShots,
    'fairway': fairway, 'green_in_regulation': greenInRegulation,
    'expected_exists': expectedExists,
    'expected_updated_at': expectedUpdatedAt?.toUtc().toIso8601String(),
    'status': status.name, 'error': error,
  };
  factory QueuedScore.fromMap(Map<String, dynamic> m) => QueuedScore(
    id: m['id'] as String, actorId: m['actor_id'] as String,
    roundId: m['round_id'] as String, playerId: m['player_id'] as String,
    holeNumber: m['hole_number'] as int, strokes: m['strokes'] as int,
    putts: m['putts'] as int, penaltyStrokes: m['penalty_strokes'] as int,
    sandShots: m['sand_shots'] as int, fairway: m['fairway'] as String?,
    greenInRegulation: m['green_in_regulation'] as bool?,
    expectedExists: m['expected_exists'] as bool,
    expectedUpdatedAt: m['expected_updated_at'] == null ? null :
      DateTime.parse(m['expected_updated_at'] as String),
    status: m['status'] == 'blocked' ? QueuedScoreStatus.blocked : QueuedScoreStatus.pending,
    error: m['error'] as String?,
  );
  QueuedScore blocked(String message) => QueuedScore.fromMap({
    ...toMap(), 'status': 'blocked', 'error': message,
  });
}

abstract class ScoreQueueStore {
  Future<List<QueuedScore>> readAll();
  Future<void> add(QueuedScore entry);
  Future<void> replace(QueuedScore entry);
  Future<void> rebase(String oldId, QueuedScore entry);
  Future<void> remove(String id);
  Future<List<HoleScore>?> readScores(String actorId, String roundId);
  Future<void> writeScores(String actorId, String roundId, List<HoleScore> scores);
}

/// Device-only SQLite; changes are committed before the UI reports a save.
class SqliteScoreQueueStore implements ScoreQueueStore {
  Future<Database>? _database;
  Future<Database> get database => _database ??= _open();
  Future<Database> _open() async {
    final base = await getDatabasesPath();
    return openDatabase('$base/cgct_scores.db', version: 1, onCreate: (db, _) async {
      await db.execute('CREATE TABLE outbox (id TEXT PRIMARY KEY, actor TEXT NOT NULL, round_id TEXT NOT NULL, player_id TEXT NOT NULL, hole INTEGER NOT NULL, payload TEXT NOT NULL, UNIQUE(actor,round_id,player_id,hole))');
      await db.execute('CREATE TABLE score_cache (actor TEXT NOT NULL, round_id TEXT NOT NULL, payload TEXT NOT NULL, PRIMARY KEY(actor,round_id))');
    });
  }
  @override
  Future<List<QueuedScore>> readAll() async => (await (await database).query('outbox', orderBy: 'rowid')).map((r) => QueuedScore.fromMap(jsonDecode(r['payload'] as String) as Map<String, dynamic>)).toList();
  @override
  Future<void> add(QueuedScore q) async {
    await (await database).insert('outbox', {'id':q.id,'actor':q.actorId,'round_id':q.roundId,'player_id':q.playerId,'hole':q.holeNumber,'payload':jsonEncode(q.toMap())}, conflictAlgorithm: ConflictAlgorithm.abort);
  }
  @override
  Future<void> replace(QueuedScore q) async {
    await (await database).update('outbox', {'payload':jsonEncode(q.toMap())}, where:'id = ?',whereArgs:[q.id]);
  }
  @override
  Future<void> rebase(String oldId,QueuedScore q) async {
    await (await database).transaction((tx) async {
      if(await tx.delete('outbox',where:'id = ?',whereArgs:[oldId])!=1) throw StateError('Score no longer available.');
      await tx.insert('outbox',{'id':q.id,'actor':q.actorId,'round_id':q.roundId,'player_id':q.playerId,'hole':q.holeNumber,'payload':jsonEncode(q.toMap())});
    });
  }
  @override
  Future<void> remove(String id) async { await (await database).delete('outbox',where:'id = ?',whereArgs:[id]); }
  @override
  Future<List<HoleScore>?> readScores(String actorId, String roundId) async {
    final rows=await (await database).query('score_cache',where:'actor = ? AND round_id = ?',whereArgs:[actorId,roundId]);
    if (rows.isEmpty) return null;
    return (jsonDecode(rows.first['payload'] as String) as List).map((e)=>HoleScore.fromJson(Map<String,dynamic>.from(e as Map))).toList();
  }
  @override
  Future<void> writeScores(String actorId, String roundId, List<HoleScore> scores) async {
    await (await database).insert('score_cache', {'actor':actorId,'round_id':roundId,'payload':jsonEncode(scores.map(_scoreJson).toList())}, conflictAlgorithm:ConflictAlgorithm.replace);
  }
}

Map<String, Object?> _scoreJson(HoleScore s) => {
  'round_id':s.roundId, 'player_id':s.playerId, 'hole_number':s.holeNumber,
  'strokes':s.strokes,'putts':s.putts,'penalty_strokes':s.penaltyStrokes,
  'sand_shots':s.sandShots,'fairway':s.fairway,'green_in_regulation':s.greenInRegulation,
  'confirmed':s.confirmed,'updated_at':s.updatedAt?.toUtc().toIso8601String(),
};

/// Test/demo storage does not claim survival across process restarts.
class MemoryScoreQueueStore implements ScoreQueueStore {
  final Map<String,QueuedScore> items={};
  final Map<String,List<HoleScore>> snapshots={};
  @override
  Future<List<QueuedScore>> readAll() async => items.values.toList();
  @override
  Future<void> add(QueuedScore q) async {
    if (items.values.any((s)=>s.actorId==q.actorId && s.roundId==q.roundId && s.playerId==q.playerId && s.holeNumber==q.holeNumber)) throw StateError('This score is already waiting to sync.');
    items[q.id]=q;
  }
  @override
  Future<void> replace(QueuedScore q) async { if(items.containsKey(q.id))items[q.id]=q; }
  @override
  Future<void> rebase(String oldId,QueuedScore q) async {
    if(!items.containsKey(oldId)) throw StateError('Score no longer available.');
    items.remove(oldId); items[q.id]=q;
  }
  @override
  Future<void> remove(String id) async { items.remove(id); }
  @override
  Future<List<HoleScore>?> readScores(String actorId,String roundId) async => snapshots['$actorId/$roundId'];
  @override
  Future<void> writeScores(String actorId,String roundId,List<HoleScore> scores) async { snapshots['$actorId/$roundId']=List.of(scores); }
}

typedef ScoreSender = Future<HoleScore> Function(QueuedScore score);

class ScoreOutbox extends ChangeNotifier {
  ScoreOutbox({required this.store, required this.send, required this.currentActor, this.retryInterval=const Duration(seconds: 15)}) {
    ready = _initialize();
  }
  final ScoreQueueStore store;
  final ScoreSender send;
  final String? Function() currentActor;
  final Duration retryInterval;
  late final Future<void> ready;
  List<QueuedScore> _items=[];
  Timer? _timer;
  bool _syncing=false, _disposed=false;
  Future<void> _initialize() async {
    _items=await store.readAll();
    _notify();
    _timer=Timer.periodic(retryInterval, (_) => unawaited(sync()));
    unawaited(sync());
  }
  void _notify(){ if(!_disposed) notifyListeners(); }
  List<QueuedScore> pendingForRound(String actorId,String roundId) => _items.where((s)=>s.actorId==actorId && s.roundId==roundId).toList(growable:false);
  Future<void> enqueue({
    required String actorId,required String roundId,required String playerId,
    required int holeNumber,required int strokes,required int putts,
    required int penaltyStrokes,required bool expectedExists,
    DateTime? expectedUpdatedAt,int sandShots=0,String? fairway,bool? greenInRegulation,
  }) async {
    await ready;
    if(actorId.isEmpty || currentActor()!=actorId) throw StateError('Sign in with the same account to save a score.');
    if(holeNumber<1 || holeNumber>18 || strokes<1 || strokes>20 || putts<0 || putts>10 || penaltyStrokes<0 || penaltyStrokes>10 || sandShots<0 || sandShots>10) throw ArgumentError('Invalid score.');
    if(expectedExists && expectedUpdatedAt==null) throw StateError('Cannot safely save without the score version. Reload when online.');
    if(_items.any((s)=>s.actorId==actorId && s.roundId==roundId && s.playerId==playerId && s.holeNumber==holeNumber)) throw StateError('This score is already waiting to sync. Review it after syncing.');
    final q=QueuedScore(id:_uuid(),actorId:actorId,roundId:roundId,playerId:playerId,holeNumber:holeNumber,strokes:strokes,putts:putts,penaltyStrokes:penaltyStrokes,sandShots:sandShots,fairway:fairway,greenInRegulation:greenInRegulation,expectedExists:expectedExists,expectedUpdatedAt:expectedUpdatedAt,status:QueuedScoreStatus.pending);
    await store.add(q);
    _items.add(q); _notify();
    unawaited(sync());
  }
  Future<void> sync() async {
    await ready;
    if(_syncing || _disposed) return;
    _syncing=true;
    try {
      for(final q in List<QueuedScore>.of(_items)) {
        if(_disposed) break;
        if(currentActor()!=q.actorId) continue;
        if(q.status==QueuedScoreStatus.blocked) continue;
        try {
          final saved = await send(q).timeout(const Duration(seconds: 15));
          final cached = await store.readScores(q.actorId,q.roundId) ?? <HoleScore>[];
          cached.removeWhere((s)=>s.playerId==saved.playerId && s.holeNumber==saved.holeNumber);
          cached.add(saved);
          await store.writeScores(q.actorId,q.roundId,cached);
          await store.remove(q.id);
          _items.removeWhere((s)=>s.id==q.id); _notify();
        } on PostgrestException catch(e) {
          if(const {'40001','42501','22023','23514','P0001'}.contains(e.code)) {
            final blocked=q.blocked(e.message);
            await store.replace(blocked);
            final index=_items.indexWhere((s)=>s.id==q.id);
            if(index>=0) _items[index]=blocked;
            _notify();
            continue;
          }
          break;
        } catch(_) {
          // Network failures and uncertain acknowledgements retain the same
          // request id; the server's receipt makes retry safe.
          break;
        }
      }
    } finally { _syncing=false; }
  }
  Future<void> discard(String id) async {
    await ready;
    final item=_items.where((q)=>q.id==id).firstOrNull;
    if(item==null || item.actorId!=currentActor() || item.status!=QueuedScoreStatus.blocked) throw StateError('Only a blocked score can be discarded after review.');
    if(_syncing) throw StateError('Wait for synchronisation to finish.');
    await store.remove(id); _items.removeWhere((q)=>q.id==id); _notify();
  }
  Future<void> retryBlocked(String id,{required bool expectedExists,DateTime? expectedUpdatedAt}) async {
    await ready;
    final item=_items.where((q)=>q.id==id).firstOrNull;
    if(item==null || item.actorId!=currentActor() || item.status!=QueuedScoreStatus.blocked) throw StateError('Blocked score unavailable for this account.');
    if(_syncing) throw StateError('Wait for synchronisation to finish.');
    if(expectedExists && expectedUpdatedAt==null) throw StateError('Reload the score before retrying.');
    // A changed baseline is a new idempotent request, explicitly approved by
    // the golfer after reviewing the latest server score.
    final updated=QueuedScore.fromMap({...item.toMap(),'id':_uuid(),'expected_exists':expectedExists,'expected_updated_at':expectedUpdatedAt?.toUtc().toIso8601String(),'status':'pending','error':null});
    await store.rebase(item.id,updated);
    final index=_items.indexWhere((q)=>q.id==id);
    if(index>=0) _items[index]=updated;
    _notify(); unawaited(sync());
  }
  @override
  void dispose(){_disposed=true;_timer?.cancel();super.dispose();}
}

String _uuid(){
  final random=Random.secure(); final bytes=List<int>.generate(16,(_)=>random.nextInt(256));
  bytes[6]=(bytes[6]&15)|64; bytes[8]=(bytes[8]&63)|128;
  final s=bytes.map((b)=>b.toRadixString(16).padLeft(2,'0')).join();
  return '${s.substring(0,8)}-${s.substring(8,12)}-${s.substring(12,16)}-${s.substring(16,20)}-${s.substring(20)}';
}
