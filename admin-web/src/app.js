import {createClient} from '@supabase/supabase-js';
import config from './config.json';
import {googleSignInOptions,finishGoogleSignIn} from './oauth.js';
import {esc,division,seasonRounds,csv,playDate,roundsOnDate,playerCard,provisionalNet} from './domain.js';
const client=createClient(config.url,config.key,{auth:{storage:sessionStorage,persistSession:true,autoRefreshToken:true,detectSessionInUrl:false,flowType:'pkce'}});
const root=document.querySelector('#app'),dialog=document.querySelector('#editor');
let data=null,section='Overview',query='',year=new Date().getFullYear(),playDay=playDate({created_at:new Date().toISOString()}),demo=false,busy=false;
const sections=['Overview','Members','Leagues','Rounds','Courses','Operations','Merchandise','Feedback','Audit','Administrators'];
const icons=['◈','♙','⚑','◷','⌖','▤','◇','✎','≡','⚿'];
const money=x=>new Intl.NumberFormat('en-ZA',{style:'currency',currency:'ZAR'}).format(Number(x||0));
const date=x=>x?new Intl.DateTimeFormat('en-ZA',{dateStyle:'medium',timeStyle:'short',timeZone:'Africa/Johannesburg'}).format(new Date(x)):'—';
const pill=x=>`<span class="pill">${esc(x)}</span>`;
const btn=(text,action,id='',primary=false)=>`<button ${demo&&['edit','new','schedule','invite','order','score'].includes(action)?'disabled':''} class="${primary?'primary':''}" data-action="${action}" data-id="${esc(id)}">${esc(text)}</button>`;
function toast(message){document.querySelector('#toast').textContent=message;setTimeout(()=>document.querySelector('#toast').textContent='',5500);}
async function checked(request){const result=await request;if(result.error)throw result.error;return result.data;}
function login(message=''){
 data=null;root.innerHTML=`<div class="login"><section class="loginhero"><div class="eyebrow">Christian Golfers Cape Town</div><h1>Good stewardship.<br>Great fellowship.</h1><p>One place to care for your members,<br>manage your leagues and keep the game moving.</p></section><section class="loginpanel"><form id="login"><img src="logo.jpeg" alt="Christian Golfers Cape Town"><div class="eyebrow">Administration</div><h1>Welcome back.</h1><p class="muted">Sign in with your allowlisted app administrator account.</p><button type="button" class="google-signin" data-action="google">Continue with Google</button><p class="muted signin-divider">or sign in with email</p><label for="email">Email address</label><input id="email" name="email" type="email" autocomplete="username" required><label for="password">Password</label><input id="password" name="password" type="password" autocomplete="current-password" required><p class="error" id="login-error" role="alert">${esc(message)}</p><button class="primary" type="submit">Sign in securely →</button><button type="button" data-action="demo">Preview layout · sample data</button><p class="muted">Access is checked on the server. Your session is kept in this browser tab.</p></form></section></div>`;
 document.querySelector('#login').onsubmit=async e=>{e.preventDefault();const b=e.target.querySelector('button[type=submit]');b.disabled=true;try{const f=new FormData(e.target);await checked(client.auth.signInWithPassword({email:f.get('email'),password:f.get('password')}));demo=false;await load();}catch(error){document.querySelector('#login-error').textContent=error.message;b.disabled=false;}};
}
async function load(){
 if(demo){render();return;}
 const allowed=await checked(client.rpc('is_admin'));if(!allowed){await client.auth.signOut();login('This account is not on the administrator allowlist.');return;}
 const [dashboard,members,products,orders,tasks,audit,courses,accessDirectory,feedback]=await Promise.all([
  checked(client.rpc('admin_league_dashboard')),checked(client.rpc('admin_portal_members')),
  checked(client.from('admin_products').select('*').order('name')),
  checked(client.from('admin_orders').select('*').order('created_at',{ascending:false}).limit(1000)),
  checked(client.from('admin_tasks').select('*').order('due_date')),
  checked(client.from('admin_audit').select('*').order('created_at',{ascending:false}).limit(200)),
  checked(client.from('courses').select('id,name,province,city,active,playable,data_status').order('name')),
  checked(client.rpc('portal_admin_access_directory')),
  checked(client.from('member_test_feedback').select('id,reporter_id,category,description,app_version,created_at').order('created_at',{ascending:false}).limit(200))]);
 data={...dashboard,members,products,orders,tasks,audit,courses,accessDirectory,feedback};
 if(section==='Administrators'&&!accessDirectory)section='Overview';
 render();
}
function table(headers,rows){return `<div class="tablewrap"><table><thead><tr>${headers.map(h=>`<th>${esc(h)}</th>`).join('')}</tr></thead><tbody>${rows.length?rows.map(r=>`<tr>${r.map(c=>`<td>${c}</td>`).join('')}</tr>`).join(''):`<tr><td colspan="${headers.length}" class="empty">No records to show.</td></tr>`}</tbody></table></div>`;}
const search=items=>items.filter(x=>JSON.stringify(x).toLowerCase().includes(query.toLowerCase()));
const memberName=id=>data.members.find(m=>m.id===id)?.display_name||'Unknown member';
const league=m=>division(m,data.league_a_max_handicap,data.league_b_max_handicap);
function stat(label,value,note){return `<div class="stat"><span class="muted">${label}</span><span class="value">${esc(value)}</span><small>${note}</small></div>`;}
function roundTable(rounds){return table(['Course / tee time','Host','Progress',''],rounds.map(r=>[`${esc(r.course_name)}<small>${date(r.scheduled_at||r.played_at)}</small>`,esc(r.host_name),pill(r.status==='active'?`Hole ${r.current_hole}`:r.status),btn('View scorecard','round',r.id)]));}
function render(){
 if(!data)return;const rounds=seasonRounds(data.rounds,year),completed=rounds.filter(r=>r.status==='completed');
 root.innerHTML=`${demo?'<div class="sample">SAMPLE DATA · Preview only. Editing is disabled.</div>':''}<div class="layout"><aside><div class="brand"><img src="logo.jpeg" alt="CGCT logo"><div><strong>Christian Golfers</strong><small>CAPE TOWN · ADMIN</small></div></div><nav aria-label="Administration sections">${sections.filter(s=>s!=='Administrators'||data.accessDirectory).map((s,i)=>`<button class="${section===s?'active':''}" data-action="nav" data-id="${s}"><span>${icons[i]}</span>${s}</button>`).join('')}</nav><footer><p>Faith. Fellowship. Fairways.</p><p>Private administration portal<br>Version 2</p>${btn('Sign out','logout')}</footer></aside><main><header class="topbar"><span class="muted">Clubhouse / <strong>${section}</strong></span><div>${btn('Refresh data','refresh')} ${btn(demo?'Exit preview':'Sign out','logout')}</div></header><div class="eyebrow">Your club, connected</div><h1>${section==='Overview'?'The clubhouse overview.':section}</h1><p class="muted">${({Overview:'A clear picture of your people, rounds and day-to-day operations.',Members:'Manage member records, handicap indexes and league assignments.',Leagues:'Membership by division and season performance, with history preserved.',Rounds:'Schedule fourballs and inspect every recorded score.',Courses:'Course availability and data coverage across South Africa.',Operations:'Keep the team aligned on the work that needs doing.',Merchandise:'Catalogue, stock and a manual order ledger. Prices in South African rand.',Feedback:'Read reports submitted by members during testing.',Administrators:'Manage administrator access for the mobile app and portal.',Audit:'Who changed what, when and why. Portal edits are recorded on the server.'})[section]}</p><div id="content"></div></main></div>`;
 const content=document.querySelector('#content');let html='';
 if(section==='Overview'){
  html=`<section class="hero"><div><div class="eyebrow">Faith • fellowship • fairways</div><h2>More time for the people.<br>Less time managing the details.</h2><p>Your members, leagues and group operations, together in one secure workspace.</p>${btn('Manage members','nav','Members',true)}</div><div class="stamp">CHRISTIAN<br>GOLFERS<br>CAPE TOWN</div></section><div class="stats">${stat('Registered members',data.members.length,`${data.members.filter(m=>m.membership_status==='active').length} active membership records`)}${stat('Rounds this year',rounds.length,`${completed.length} completed · ${year}`)}${stat('On the course',data.rounds.filter(r=>r.status==='active').length,'Active fourballs')}${stat('Open operations',data.tasks.filter(t=>t.status!=='done').length,'Tasks awaiting completion')}</div><div class="grid"><section class="card"><div class="sectionhead"><h2>Upcoming & live rounds</h2>${btn('View all','nav','Rounds')}</div>${roundTable(data.rounds.filter(r=>r.status!=='completed').slice(0,5))}</section><section class="card"><h2>Our fellowship</h2><p class="muted">Current membership by league</p>${['A','B','Social'].map(l=>{const n=data.members.filter(m=>league(m)===l).length;return `<div class="barrow"><span>${l==='Social'?l:'League '+l}</span><div class="bar"><i style="width:${100*n/Math.max(1,data.members.length)}%"></i></div><strong>${n}</strong></div>`;}).join('')}<div class="notice">Official season competition points await your approved points schedule.</div></section></div>`;
 }else if(section==='Members'){
  html=toolbar(btn('Invite member','invite','',true)+btn('Export CSV','export'))+table(['Member','Handicap index','League','Membership',''],search(data.members).map(m=>[`${esc(m.display_name)}<small>${esc(m.email)}</small>`,esc(m.handicap??'Not recorded'),pill(league(m)),esc(m.membership_status),btn('Edit member','edit',m.id)]));
 }else if(section==='Leagues'){
  html=`<div class="toolbar"><label for="season">Season</label><select id="season">${Array.from(new Set([year,...data.rounds.map(r=>new Date(r.played_at||r.created_at).getFullYear())])).sort((a,b)=>b-a).map(y=>`<option ${y===year?'selected':''}>${y}</option>`).join('')}</select>${btn('Edit assignments','nav','Members')}</div><div class="notice">Competition points are not calculated until the official schedule is configured. Below: completed-round statistics, not official standings. League assignments shown are current, not historical snapshots.</div>`;
  const ids=new Set(completed.map(r=>r.id));html+=table(['Member','Current league','Completed rounds','Average gross','Best gross'],data.members.map(m=>{const rs=data.results.filter(r=>r.player_id===m.id&&ids.has(r.round_id));return [esc(m.display_name),pill(league(m)),rs.length,rs.length?(rs.reduce((s,r)=>s+r.gross_strokes,0)/rs.length).toFixed(1):'—',rs.length?Math.min(...rs.map(r=>r.gross_strokes)):'—'];}));
 }else if(section==='Rounds'){
  const matching=roundsOnDate(search(data.rounds),playDay), ids=new Set(matching.map(r=>r.id));
  const players=data.players.filter(p=>ids.has(p.round_id));
  html=toolbar(btn('Schedule fourball','schedule','',true)+btn('Export day scores','export-rounds'))
   +`<div class="toolbar"><label for="play-day">Play date (South Africa)</label><input id="play-day" type="date" value="${esc(playDay)}"><button data-action="all-rounds">All dates</button><button data-action="today-rounds">Today</button></div>`
   +`<div class="notice">${playDay?'Showing fourballs scheduled or started on '+esc(playDay):'Showing all dates'}. Scores appear after they sync to the database; use Refresh data for the latest. Gross is provisional while holes are missing or unconfirmed. Net is provisional and uses the round's shared tee, not each player's tee; verify handicaps and results before prize giving. Net is hidden for incomplete or unconfirmed cards.</div>`
   +`<div class="sectionhead"><h2>Fourballs (${matching.length})</h2></div>`+roundTable(matching)
   +`<div class="sectionhead" style="margin-top:28px"><h2>Player scores (${players.length})</h2></div>`
   +table(['Player','Fourball / course','Round status','Holes entered','Confirmed','Gross so far','Net (shared tee, provisional)',''],players.map(p=>{
     const r=matching.find(x=>x.id===p.round_id),card=playerCard(data.scores,p.round_id,p.user_id),result=data.results.find(x=>x.round_id===p.round_id&&x.player_id===p.user_id);
     return [esc(p.display_name),`${esc(r.course_name)}<small>${esc(r.host_name)} · ${date(r.scheduled_at||r.started_at||r.played_at)}</small>`,pill(r.status),card.entered,`${card.confirmed}/${card.entered}`,card.gross??'—',provisionalNet(r,card,result)??'—',btn('View card','round',r.id)+(r.status==='active'?` ${btn('Enter score','score',`${r.id}|${p.user_id}`)}`:'')];
   }));
 }else if(section==='Courses'){html=toolbar('')+table(['Course','Province','Availability','Data status'],search(data.courses).map(c=>[esc(c.name),esc(c.province),pill(c.active?(c.playable?'Round-ready':'Directory only'):'Inactive'),esc(c.data_status||'Not verified')]))+'<div class="notice">Course imports and verified tee / hole data are maintained through reviewed migrations. Missing imagery and ratings are not fabricated.</div>';
 }else if(section==='Operations'){html=toolbar(btn('New task','new','',true))+table(['Task','Owner','Due','Status',''],search(data.tasks).map(t=>[esc(t.title),esc(memberName(t.owner_id)),esc(t.due_date||'—'),pill(t.status),btn('Edit','edit',t.id)]));
 }else if(section==='Merchandise'){
  html=`<div class="stats">${stat('Catalogue items',data.products.length,'Products and variants')}${stat('Units in stock',data.products.reduce((s,p)=>s+p.stock,0),'Available stock after reservations')}${stat('Pending orders',data.orders.filter(o=>o.status==='pending').length,'Payment not confirmed')}${stat('Recorded sales',money(data.orders.filter(o=>['paid','fulfilled'].includes(o.status)).reduce((s,o)=>s+o.quantity*o.unit_price,0)),'Manual ledger · not reconciled payments')}</div><div class="toolbar">${btn('Add product','new','',true)}${btn('Record order','order')}</div>`+table(['Product / SKU','Price','Available','Status',''],data.products.map(p=>[`${esc(p.name)}<small>${esc(p.sku)}</small>`,money(p.price),p.stock,pill(p.active?'Active':'Archived'),btn('Edit','edit',p.id)]));
  html+='<h2>Order ledger</h2>'+table(['Member','Product','Quantity / total','Status',''],data.orders.map(o=>[esc(memberName(o.member_id)),esc(data.products.find(p=>p.id===o.product_id)?.name||'Unknown'),`${o.quantity} · ${money(o.quantity*o.unit_price)}`,pill(o.status),btn('Update','order',o.id)]))+'<div class="notice">New orders reserve stock. Cancellation restores it once. Marking an order paid is a manual record, not a payment transaction. Latest 1,000 orders shown.</div>';
 }else if(section==='Feedback'){html=table(['Received','Member','Area','Version','Feedback'],data.feedback.map(f=>[date(f.created_at),esc(memberName(f.reporter_id)),pill(f.category),esc(f.app_version),esc(f.description)]))+'<p class="muted">Latest 200 submissions. Members choose what to send.</p>';
 }else if(section==='Administrators'&&data.accessDirectory){
  const current=data.accessDirectory.filter(member=>member.admin);
  html='<p>Choose a registered member with a verified email. Only the owner can grant or revoke administrator access.</p>'
    +'<div class="notice">This website also uses private Sites sharing. Give a new administrator viewer access in the site’s sharing settings so they can reach the portal login.</div>'
    +btn('Add administrator','grant-admin','',true)
    +table(['Administrator','Email','Access',''],current.map(member=>[
      esc(member.name||'Member'),esc(member.email),pill(member.owner?'Owner':'Administrator'),
      member.owner?'Protected':btn('Revoke access','revoke-admin',member.id)
    ]));
 }else if(section==='Audit'){html=table(['When','Administrator','Record','Reason',''],data.audit.map(a=>[date(a.created_at),esc(memberName(a.actor)),esc(a.entity),esc(a.reason),btn('Details','audit',String(a.id))]))+'<p class="muted">Latest 200 portal edits. Existing app operations and scheduling use their existing records and are not included in this audit list.</p>';}
 content.innerHTML=html;
 const q=document.querySelector('#search');if(q){q.value=query;q.oninput=e=>{query=e.target.value;const pos=q.selectionStart;render();document.querySelector('#search').focus();document.querySelector('#search').setSelectionRange(pos,pos);};}
 const s=document.querySelector('#season');if(s)s.onchange=e=>{year=Number(e.target.value);render();};
 const d=document.querySelector('#play-day');if(d)d.onchange=e=>{playDay=e.target.value;render();};
}
function toolbar(actions){return `<div class="toolbar"><input id="search" type="search" aria-label="Search ${section}" placeholder="Search ${section.toLowerCase()}…">${actions}</div>`;}
function field(name,label,value='',type='text',options=null,required=true){return `<div><label for="f-${name}">${esc(label)}</label>${options?`<select id="f-${name}" name="${name}" ${required?'required':''}>${options.map(([v,l])=>`<option value="${esc(v)}" ${String(v)===String(value??'')?'selected':''}>${esc(l)}</option>`).join('')}</select>`:`<input id="f-${name}" name="${name}" type="${type}" value="${esc(value)}" ${required?'required':''} ${type==='number'?'step="any"':''}>`}</div>`;}
function form(title,fields,submit,help=''){
 dialog.innerHTML=`<form><header><h2>${esc(title)}</h2><button type="button" data-action="close" aria-label="Close">×</button></header>${help?`<p class="muted">${esc(help)}</p>`:''}<div class="fields">${fields}</div><p class="error" role="alert" id="form-error"></p><div class="actions"><button type="button" data-action="close">Cancel</button><button class="primary" type="submit">Save changes</button></div></form>`;dialog.showModal();
 dialog.querySelector('form').onsubmit=async e=>{e.preventDefault();if(busy||demo)return;busy=true;dialog.querySelectorAll('button').forEach(b=>b.disabled=true);try{await submit(Object.fromEntries(new FormData(e.target)));dialog.close();await load();toast('Changes saved.');}catch(error){dialog.querySelector('#form-error').textContent=error.message||'Unable to save. Retry after checking your connection.';}finally{busy=false;dialog.querySelectorAll('button').forEach(b=>b.disabled=false);}};
}
const reason=()=>field('reason','Reason for change');
async function edit(id){
 const kind=section==='Members'?'member':section==='Operations'?'task':'product';
 const list=kind==='member'?data.members:kind==='task'?data.tasks:data.products;
 const record=list.find(x=>x.id===id)||{id:crypto.randomUUID()};let fields='';
 if(kind==='member')fields=field('display_name','Full name',record.display_name)+field('handicap','Handicap index',record.handicap,'number',null,false)+field('source','Handicap source',record.source,'text',null,false)+field('league','League assignment',record.league,'text',[['','Automatic by handicap'],['A','League A'],['B','League B'],['Social','Social']])+field('membership_status','Membership status',record.membership_status,'text',[['active','Active'],['inactive','Inactive']])+field('visiting','Visiting golfer',String(record.visiting),'text',[['false','No'],['true','Yes']]);
 if(kind==='task')fields=field('title','Task',record.title)+field('owner_id','Responsible member',record.owner_id,'text',[['','Unassigned'],...data.members.map(m=>[m.id,m.display_name])],false)+field('due_date','Due date',record.due_date,'date',null,false)+field('status','Status',record.status||'todo','text',[['todo','To do'],['doing','In progress'],['done','Done']])+field('note','Notes',record.note,'text',null,false);
 if(kind==='product')fields=field('name','Product / variant',record.name)+field('sku','SKU',record.sku)+field('price','Unit price (ZAR)',record.price??0,'number')+field('stock','Available stock',record.stock??0,'number')+field('active','Catalogue status',String(record.active??true),'text',[['true','Active'],['false','Archived']]);
 form(kind==='member'?'Edit member':id?'Edit '+kind:'New '+kind,fields+reason(),async values=>{const {reason,...r}=values;if(kind==='member'&&r.handicap!==''&&(!Number.isFinite(Number(r.handicap))||Number(r.handicap)<-10||Number(r.handicap)>54||!r.source.trim()))throw Error('Handicap must be -10 to 54 with a recorded source.');await checked(client.rpc('admin_portal_save',{p_kind:kind,p_record:{...r,id:record.id},p_reason:reason}));},kind==='member'?'Membership status is an administrative record; inactive does not disable app sign-in. League override takes priority over handicap-based classification.':'');
}
function order(id){const o=data.orders.find(o=>o.id===id);const key=o?.id||crypto.randomUUID();const opts=data.members.map(m=>[m.id,m.display_name]);const fields=o?field('status','Order status',o.status,'text',['pending','paid','fulfilled','cancelled'].map(x=>[x,x])):field('member_id','Member','','text',opts)+field('product_id','Product','','text',data.products.filter(p=>p.active).map(p=>[p.id,`${p.name} · ${money(p.price)}`]))+field('quantity','Quantity',1,'number');form(o?'Update order':'Record order',fields+field('note','Reference / notes',o?.note,'text',null,false)+reason(),async values=>{const {reason,...r}=values;await checked(client.rpc('admin_portal_save',{p_kind:'order',p_record:{...r,id:key,status:r.status||'pending'},p_reason:reason}));},'Manual order ledger. No payment is collected. New orders reserve stock.');}
async function schedule(){
 const token=crypto.randomUUID();form('Schedule a fourball',field('course','Course','','text',[['','Choose course'],...data.courses.filter(c=>c.active&&c.playable).map(c=>[c.id,c.name])])+field('tee','Tee','','text',[['','Choose course first']])+field('when','Local tee time','','datetime-local')+[0,1,2,3].map(i=>field('player'+i,i===0?'Host':'Player '+(i+1),'','text',[['','Select member'],...data.members.map(m=>[m.id,m.display_name])],i===0)).join(''),async v=>{const players=[v.player0,v.player1,v.player2,v.player3].filter(Boolean);if(new Set(players).size!==players.length)throw Error('Select different members.');await checked(client.rpc('admin_schedule_fourball',{p_course_id:v.course,p_tee_set_id:v.tee,p_scheduled_at:new Date(v.when).toISOString(),p_player_ids:players,p_request_key:token}));},'Time uses this browser’s local timezone. The selected host starts the round in the app. This does not book a tee time with the course.');
 dialog.querySelector('[name=course]').onchange=async e=>{const course=e.target.value;const tees=await checked(client.from('tee_sets').select('id,name').eq('course_id',course).eq('selectable',true));if(dialog.querySelector('[name=course]')?.value===course)dialog.querySelector('[name=tee]').innerHTML='<option value="">Select tee</option>'+tees.map(t=>`<option value="${esc(t.id)}">${esc(t.name)}</option>`).join('');};
}
function showRound(id){
 const r=data.rounds.find(r=>r.id===id);if(!r)return;
 const players=data.players.filter(p=>p.round_id===id);
 dialog.innerHTML=`<header><h2>${esc(r.course_name)}</h2>${btn('Close','close')}</header><p>${date(r.scheduled_at||r.started_at||r.played_at)} · ${esc(r.tee_set_name)} · ${esc(r.status)} · Hole ${esc(r.current_hole)}</p>`
  +table(['Player',...Array.from({length:18},(_,i)=>i+1),'Holes','Confirmed','Gross so far','Net (shared tee, provisional)',''],players.map(p=>{
    const card=playerCard(data.scores,id,p.user_id),result=data.results.find(x=>x.round_id===id&&x.player_id===p.user_id);
    return [esc(p.display_name),...card.holes.map(s=>s?`<span title="${esc(`${s.confirmed?'Confirmed':'Unconfirmed'} · ${s.putts??'—'} putts · ${s.penalty_strokes||0} penalties`)}">${Number(s.strokes)+Number(s.penalty_strokes||0)}${s.confirmed?'':'*'}</span>`:'—'),card.entered,`${card.confirmed}/${card.entered}`,card.gross??'—',provisionalNet(r,card,result)??'—',r.status==='active'?btn('Enter score','score',`${id}|${p.user_id}`):''];
  }))+'<p class="muted">* Unconfirmed hole; — indicates no score. Gross includes recorded penalty strokes and is provisional for incomplete or unconfirmed cards. Net is provisional, uses the shared round tee and is hidden without 18 confirmed holes and a handicap index. Verify results before prize giving. Score editing is available only while the round is active.</p>';
 dialog.showModal();
}
function editScore(id){
 const [roundId,playerId]=id.split('|'),round=data.rounds.find(r=>r.id===roundId),player=data.players.find(p=>p.round_id===roundId&&p.user_id===playerId);
 if(!round||!player||round.status!=='active')throw Error('Only active rounds can be edited.');
 if(dialog.open)dialog.close();
 let expectedExists=false,expectedUpdatedAt=null;
 form(`Enter score · ${player.display_name}`,field('hole','Hole',round.current_hole||1,'text',Array.from({length:18},(_,i)=>[String(i+1),`Hole ${i+1}`]))+field('strokes','Strokes excluding penalties','','number')+field('putts','Putts',0,'number')+field('penalties','Penalty strokes',0,'number')+reason(),async v=>{
   const stroke=Number(v.strokes),putts=Number(v.putts),penalties=Number(v.penalties),hole=Number(v.hole);
   if(!Number.isInteger(stroke)||stroke<1||stroke>20||!Number.isInteger(putts)||putts<0||putts>10||!Number.isInteger(penalties)||penalties<0||penalties>10)throw Error('Enter whole strokes 1–20, putts 0–10 and penalties 0–10.');
   await checked(client.rpc('admin_save_hole_score',{p_round_id:roundId,p_player_id:playerId,p_hole_number:hole,p_strokes:stroke,p_putts:putts,p_penalty_strokes:penalties,p_reason:v.reason,p_expected_updated_at:expectedUpdatedAt,p_expected_exists:expectedExists}));
 },'Scores and corrections are saved to the shared round. Enter a reason for the audit trail. If the score changed after loading, saving is rejected; close this form and refresh to review the newer score.');
 const updateHole=()=>{const score=data.scores.find(s=>s.round_id===roundId&&s.player_id===playerId&&s.hole_number===Number(dialog.querySelector('[name=hole]').value));expectedExists=!!score;expectedUpdatedAt=score?.updated_at??null;for(const [name,value] of Object.entries({strokes:score?.strokes??'',putts:score?.putts??0,penalties:score?.penalty_strokes??0}))dialog.querySelector(`[name=${name}]`).value=value;};
 dialog.querySelector('[name=hole]').onchange=updateHole;updateHole();
}
root.addEventListener('click',action);dialog.addEventListener('click',action);dialog.addEventListener('cancel',e=>{if(busy)e.preventDefault();});
async function action(e){const b=e.target.closest('[data-action]');if(!b||b.disabled)return;const a=b.dataset.action,id=b.dataset.id;try{
 if(a==='google'){b.disabled=true;b.textContent='Connecting to Google…';try{await checked(client.auth.signInWithOAuth(googleSignInOptions(location.origin)));}catch(error){login(error.message||'Could not start Google sign-in. Please try again.');}return;}
 if(a==='nav'){section=id;query='';render();}if(a==='logout'){demo=false;dialog.close();await client.auth.signOut();login();}
 if(a==='refresh')await load();if(a==='close'&&!busy)dialog.close();if(a==='edit'||a==='new')await edit(id);
 if(a==='all-rounds'){playDay='';render();}if(a==='today-rounds'){playDay=playDate({created_at:new Date().toISOString()});render();}
 if(a==='grant-admin'||a==='revoke-admin'){
  if(demo||!Array.isArray(data?.accessDirectory))return;
  const grant=a==='grant-admin';
  const options=data.accessDirectory.filter(member=>grant?!member.admin:member.id===id&&member.admin&&!member.owner)
    .map(member=>[member.id,(member.name||'Member')+' · '+member.email]);
  if(!options.length){toast('No eligible members. Invite a golfer under Members and have them complete registration first.');return;}
  const selector=grant?[['','Choose a verified member'],...options]:options;
  form(grant?'Add administrator':'Revoke administrator access',
    field('member','Member',grant?'':id,'text',selector)+reason(),
    async values=>{await checked(client.rpc('portal_set_admin_access',{
      p_member_id:values.member,p_grant:grant,p_reason:values.reason
    }));},grant?'Saving grants this member league, membership and operations administration in the app and portal.':'Saving removes administrative access in both the app and portal. The member account and scores are retained.');
 }
 if(a==='order')order(id);if(a==='schedule')await schedule();if(a==='round')showRound(id);if(a==='score')editScore(id);
 if(a==='audit'){const audit=data.audit.find(x=>String(x.id)===id);dialog.innerHTML=`<header><h2>Change details</h2>${btn('Close','close')}</header><pre>${esc(JSON.stringify(audit,null,2))}</pre>`;dialog.showModal();}
 if(a==='invite')form('Invite member',field('displayName','Full name')+field('email','Email address','','email'),async v=>{await checked(client.functions.invoke('admin-invite-member',{body:v}));},'Saving sends an invitation email with the app sign-in link.');
 if(a==='export'){const blob=new Blob([csv([['Name','Email','Handicap','League','Membership'],...data.members.map(m=>[m.display_name,m.email,m.handicap,league(m),m.membership_status])])],{type:'text/csv;charset=utf-8'});const link=document.createElement('a');link.href=URL.createObjectURL(blob);link.download='cgct-members.csv';link.click();setTimeout(()=>URL.revokeObjectURL(link.href),1000);}
 if(a==='export-rounds'){
  const rounds=roundsOnDate(search(data.rounds),playDay),ids=new Set(rounds.map(r=>r.id));
  const rows=data.players.filter(p=>ids.has(p.round_id)).map(p=>{const r=rounds.find(x=>x.id===p.round_id),card=playerCard(data.scores,p.round_id,p.user_id),result=data.results.find(x=>x.round_id===p.round_id&&x.player_id===p.user_id);return [playDate(r),r.course_name,r.host_name,r.status,p.display_name,...card.holes.map(s=>s?Number(s.strokes)+Number(s.penalty_strokes||0):''),card.entered,card.confirmed,card.gross??'',provisionalNet(r,card,result)??''];});
  const blob=new Blob([csv([['Play date','Course','Host','Round status','Player',...Array.from({length:18},(_,i)=>`Hole ${i+1}`),'Holes entered','Confirmed holes','Gross so far','Net provisional - shared tee'],...rows])],{type:'text/csv;charset=utf-8'});const link=document.createElement('a');link.href=URL.createObjectURL(blob);link.download=`cgct-scores-${playDay||'all-dates'}.csv`;link.click();setTimeout(()=>URL.revokeObjectURL(link.href),1000);
 }
 if(a==='demo'){demo=true;data={members:[{id:'sample',display_name:'Sample golfer',email:'sample@example.test',handicap:14.2,league:'B',membership_status:'active'}],rounds:[],players:[],scores:[],results:[],products:[],orders:[],tasks:[],audit:[],courses:[],feedback:[],league_a_max_handicap:12,league_b_max_handicap:24};render();}
 }catch(error){toast(error.message||'Unable to complete action.');}}
client.auth.onAuthStateChange(event=>{if(event==='SIGNED_OUT'&&!demo){data=null;dialog.close();login();}});
try{await finishGoogleSignIn(client.auth,location.href,url=>history.replaceState(null,'',url));const {data:{session}}=await client.auth.getSession();if(session)await load();else login();}catch(error){login(error.message);}
