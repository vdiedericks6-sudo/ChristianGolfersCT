import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:christian_golfers/features/scorecard/data/score_outbox.dart';
import 'package:christian_golfers/features/scorecard/domain/hole_score.dart';

HoleScore saved(QueuedScore q) => HoleScore(roundId:q.roundId, playerId:q.playerId, holeNumber:q.holeNumber, strokes:q.strokes, putts:q.putts, penaltyStrokes:q.penaltyStrokes, confirmed:true, updatedAt:DateTime.now());

Future<void> waitUntil(bool Function() done) async {
  for (var i = 0; i < 100 && !done(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(done(), isTrue);
}

void main() {
  test('pending survives a controller restart and is never sent for another account', () async {
    final store=MemoryScoreQueueStore();
    var actor='alice';
    final first=ScoreOutbox(store:store,currentActor:()=>actor,send:(_)=>Future.error(StateError('offline')));
    await first.ready;
    await first.enqueue(actorId:'alice',roundId:'round',playerId:'bob',holeNumber:1,strokes:4,putts:2,penaltyStrokes:1,expectedExists:false);
    final queued=first.pendingForRound('alice','round').single;
    expect(queued.status,QueuedScoreStatus.pending);
    first.dispose();
    actor='other';
    final sent=<QueuedScore>[];
    final second=ScoreOutbox(store:store,currentActor:()=>actor,send:(q)async{sent.add(q); return saved(q);});
    await second.ready;
    await second.sync();
    expect(sent,isEmpty);
    expect(second.pendingForRound('alice','round').single.id,queued.id);
    actor='alice';
    await second.sync();
    await waitUntil(()=>sent.isNotEmpty);
    expect(sent.single.id,queued.id);
    expect(second.pendingForRound('alice','round'),isEmpty);
    second.dispose();
  });

  test('conflicts retain the original score until explicitly rebased', () async {
    final store=MemoryScoreQueueStore();
    var fail=true;
    final sent=<QueuedScore>[];
    final outbox=ScoreOutbox(store:store,currentActor:()=> 'alice',send:(q)async{
      sent.add(q);
      if(fail) throw const PostgrestException(message:'Changed on another device',code:'40001');
      return saved(q);
    });
    await outbox.ready;
    await outbox.enqueue(actorId:'alice',roundId:'round',playerId:'bob',holeNumber:1,strokes:4,putts:2,penaltyStrokes:0,expectedExists:false);
    await waitUntil(()=>outbox.pendingForRound('alice','round').single.status==QueuedScoreStatus.blocked);
    final old=outbox.pendingForRound('alice','round').single;
    expect(old.strokes,4);
    await expectLater(outbox.enqueue(actorId:'alice',roundId:'round',playerId:'bob',holeNumber:1,strokes:5,putts:2,penaltyStrokes:0,expectedExists:false),throwsStateError);
    fail=false;
    final version=DateTime.utc(2026,11,3,12);
    await outbox.retryBlocked(old.id,expectedExists:true,expectedUpdatedAt:version);
    await waitUntil(()=>outbox.pendingForRound('alice','round').isEmpty);
    expect(sent.last.id,isNot(old.id));
    expect(sent.last.expectedUpdatedAt,version);
    expect(sent.last.strokes,4);
    outbox.dispose();
  });

  test('uncertain network failure retains same request id for retry', () async {
    final store=MemoryScoreQueueStore();
    final sent=<String>[];
    var connected=false;
    final outbox=ScoreOutbox(store:store,currentActor:()=> 'alice',send:(q)async{
      sent.add(q.id);
      if(!connected) throw TimeoutException('acknowledgement lost');
      return saved(q);
    });
    await outbox.ready;
    await outbox.enqueue(actorId:'alice',roundId:'r',playerId:'alice',holeNumber:1,strokes:4,putts:2,penaltyStrokes:0,expectedExists:false);
    await waitUntil(()=>sent.isNotEmpty);
    final id=sent.first;
    connected=true;
    await outbox.sync();
    await waitUntil(()=>outbox.pendingForRound('alice','r').isEmpty);
    expect(sent.last,id);
    outbox.dispose();
  });
}
