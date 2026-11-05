export const esc = value => String(value??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
export function division(member,a=12,b=24){if(member.visiting)return 'Social';return member.league || (member.handicap==null||member.handicap>b?'Social':member.handicap<=a?'A':'B');}
export function seasonRounds(rounds,year){return rounds.filter(r=>new Date(r.played_at||r.created_at).toLocaleDateString('en-CA',{timeZone:'Africa/Johannesburg'}).startsWith(String(year)));}
// A round belongs to its scheduled/start day, even if it is completed after midnight.
export function playDate(round){const value=round.scheduled_at||round.started_at||round.played_at||round.created_at;return value?new Date(value).toLocaleDateString('en-CA',{timeZone:'Africa/Johannesburg'}):'';}
export function roundsOnDate(rounds,day){return day?rounds.filter(round=>playDate(round)===day):rounds;}
export function playerCard(scores,roundId,playerId){
 const holes=Array(18).fill(null);
 for(const score of scores){if(score.round_id===roundId&&score.player_id===playerId&&score.hole_number>=1&&score.hole_number<=18)holes[score.hole_number-1]=score;}
 const entered=holes.filter(Boolean);
 return {holes,entered:entered.length,confirmed:entered.filter(s=>s.confirmed).length,gross:entered.length?entered.reduce((sum,s)=>sum+Number(s.strokes)+Number(s.penalty_strokes||0),0):null};
}
// A stored net can be computed from incomplete or unconfirmed holes by older
// server versions. Do not present it unless the full card is confirmed.
export function provisionalNet(round,card,result){return round.status==='completed'&&card.entered===18&&card.confirmed===18&&result?.handicap_index!=null?result.net_strokes??null:null;}
// Rank only submitted, complete and confirmed cards. This is a gross-stroke
// view for review, not a claim that a competition prize has been awarded.
export function grossLeaderboard(rounds,players,scores){
 const byId=new Map(rounds.map(round=>[round.id,round]));
 const rows=[];
 for(const player of players){
  const round=byId.get(player.round_id);
  if(!round||round.status!=='completed'||player.active===false)continue;
  const card=playerCard(scores,round.id,player.user_id);
  if(card.entered!==18||card.confirmed!==18||!Number.isFinite(card.gross))continue;
  rows.push({round,player,card});
 }
 rows.sort((a,b)=>a.card.gross-b.card.gross||String(a.player.display_name??'').localeCompare(String(b.player.display_name??'')));
 let rank=0,previous;
 return rows.map((row,index)=>{if(row.card.gross!==previous)rank=index+1;previous=row.card.gross;return {...row,rank};});
}
export function csv(rows){return rows.map(row=>row.map(v=>'"'+String(v??'').replace(/^[=+@\-\t\r]/,"'$&").replaceAll('"','""')+'"').join(',')).join('\r\n');}
