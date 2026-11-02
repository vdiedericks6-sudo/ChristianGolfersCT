export const esc = value => String(value??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
export function division(member,a=12,b=24){if(member.visiting)return 'Social';return member.league || (member.handicap==null||member.handicap>b?'Social':member.handicap<=a?'A':'B');}
export function seasonRounds(rounds,year){return rounds.filter(r=>new Date(r.played_at||r.created_at).toLocaleDateString('en-CA',{timeZone:'Africa/Johannesburg'}).startsWith(String(year)));}
export function csv(rows){return rows.map(row=>row.map(v=>'"'+String(v??'').replace(/^[=+@\-\t\r]/,"'$&").replaceAll('"','""')+'"').join(',')).join('\r\n');}
