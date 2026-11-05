import test from 'node:test';
import assert from 'node:assert/strict';
import {esc,csv,division,seasonRounds,playDate,roundsOnDate,playerCard,provisionalNet,grossLeaderboard,courseCoverage} from './domain.js';
test('course coverage counts selectable tees, unique hole distances and complete green coordinates',()=>{const c=courseCoverage([{green_front_latitude:-33,green_front_longitude:18,green_centre_latitude:-33,green_centre_longitude:18,green_back_latitude:-33,green_back_longitude:18},{green_front_latitude:0}], [{id:'a',selectable:true},{id:'b',selectable:false}], [{tee_set_id:'a',hole_number:1,distance_meters:300},{tee_set_id:'a',hole_number:1,distance_meters:300},{tee_set_id:'b',hole_number:2,distance_meters:200}]);assert.equal(c.holes,2);assert.equal(c.selectableTees,1);assert.equal(c.greenCoordinates,1);assert.equal(c.teeDistances[0].count,1);});
test('database text cannot inject markup',()=>assert.equal(esc('<img onerror="x">'), '&lt;img onerror=&quot;x&quot;&gt;'));
test('exports escape quotes and neutralise spreadsheet formulas',()=>assert.equal(csv([['=SUM(A1)', 'a"b']]), '"\'=SUM(A1)","a""b"'));
test('manual division overrides index and blank uses automatic classification',()=>{assert.equal(division({handicap:30,league:'A'}),'A');assert.equal(division({handicap:null}),'Social');assert.equal(division({handicap:18}),'B');});
test('season cutoff uses South African date and keeps input history',()=>{const rounds=[{played_at:'2025-12-31T23:00:00Z'},{played_at:'2025-12-31T18:00:00Z'}];assert.equal(seasonRounds(rounds,2026).length,1);assert.equal(rounds.length,2);});
test('play day uses scheduled South African day, even when completed after midnight',()=>{const rounds=[{scheduled_at:'2026-11-22T08:00:00Z',started_at:'2026-11-22T08:05:00Z',played_at:'2026-11-23T00:00:00Z'},{started_at:'2026-11-22T23:00:00Z'}];assert.equal(playDate(rounds[0]),'2026-11-22');assert.deepEqual(roundsOnDate(rounds,'2026-11-22'),[rounds[0]]);assert.equal(playDate(rounds[1]),'2026-11-23');assert.equal(roundsOnDate(rounds,'').length,2);});
test('player card is scoped to fourball and member and does not invent missing scores',()=>{const scores=[{round_id:'a',player_id:'p',hole_number:1,strokes:4,penalty_strokes:1,confirmed:true},{round_id:'a',player_id:'p',hole_number:3,strokes:3,confirmed:false},{round_id:'a',player_id:'q',hole_number:2,strokes:10,confirmed:true},{round_id:'b',player_id:'p',hole_number:2,strokes:10,confirmed:true}];const card=playerCard(scores,'a','p');assert.equal(card.gross,8);assert.equal(card.entered,2);assert.equal(card.confirmed,1);assert.equal(card.holes[1],null);assert.equal(playerCard(scores,'b','q').gross,null);});
test('net is withheld for incomplete, unconfirmed or missing-index cards and active rounds',()=>{const round={status:'completed'},result={handicap_index:12,net_strokes:72};assert.equal(provisionalNet(round,{entered:17,confirmed:17},result),null);assert.equal(provisionalNet(round,{entered:18,confirmed:17},result),null);assert.equal(provisionalNet(round,{entered:18,confirmed:18},{...result,handicap_index:null}),null);assert.equal(provisionalNet({status:'active'},{entered:18,confirmed:18},result),null);assert.equal(provisionalNet(round,{entered:18,confirmed:18},result),72);});
test('gross leaderboard excludes incomplete, provisional, inactive and live cards and ranks tied totals together',()=>{
 const rounds=[{id:'done',status:'completed'},{id:'live',status:'active'}];
 const players=['a','b','c','incomplete','unconfirmed','inactive'].map(id=>({round_id:'done',user_id:id,display_name:id,active:id!=='inactive'})).concat({round_id:'live',user_id:'live',display_name:'live',active:true});
 const scores=[];
 for(const p of players)for(let h=1;h<=18;h++){
  if(p.user_id==='incomplete'&&h===18)continue;
  scores.push({round_id:p.round_id,player_id:p.user_id,hole_number:h,strokes:p.user_id==='c'?5:4,penalty_strokes:0,confirmed:!(p.user_id==='unconfirmed'&&h===1)});
 }
 const rows=grossLeaderboard(rounds,players,scores);
 assert.deepEqual(rows.map(row=>[row.player.user_id,row.rank,row.card.gross]),[['a',1,72],['b',1,72],['c',3,90]]);
});
