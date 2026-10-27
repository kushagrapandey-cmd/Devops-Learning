import {scenarios,initialState,restore,transition,view,execute} from './model.js';
let state;try{state=restore(localStorage.getItem('sentinel-lab'));}catch{state=initialState();}
const $=id=>document.getElementById(id);
function render(){const v=view(state);$('metrics').innerHTML=`<div class="metric"><small>READY REPLICAS · SIMULATED</small><strong>${v.ready} / 2</strong></div><div class="metric"><small>SERVICE BACKENDS</small><strong>${v.endpoints}</strong></div><div class="metric"><small>ILLUSTRATIVE ERROR RATE</small><strong>${v.errorRate}%</strong></div>`;
$('scenarios').replaceChildren(...Object.entries(scenarios).map(([key,item])=>{const b=document.createElement('button');b.className='scenario';b.textContent=item.title;b.setAttribute('aria-pressed',String(key===state.scenario));b.disabled=v.fault;b.onclick=()=>act({type:'select',scenario:key});return b;}));
$('pods').replaceChildren(...v.pods.map(p=>{const row=document.createElement('div');row.className='pod';const name=document.createElement('span');name.textContent=p.name;const status=document.createElement('span');status.className=p.ready?'good':'bad';status.textContent=p.state;row.append(name,status);return row;}));
$('phase').textContent=`Lab state: ${state.phase} · ${v.selected.code}`;
$('inject').disabled=v.fault;$('diagnose').disabled=state.phase!=='injected';$('recover').disabled=state.phase!=='diagnosed';
$('explanation').replaceChildren();const heading=document.createElement('h3');heading.textContent=state.phase==='diagnosed'?'Root cause':state.phase==='recovered'?'Recovery verified in simulation':'What to investigate';const p=document.createElement('p');p.textContent=state.phase==='diagnosed'?v.selected.cause:state.phase==='recovered'?v.selected.concept:v.selected.symptom;$('explanation').append(heading,p);
$('history').replaceChildren(...state.history.map(e=>{const li=document.createElement('li');li.textContent=e.message;return li;}));try{localStorage.setItem('sentinel-lab',JSON.stringify(state));}catch{}
}
function act(action){state=transition(state,action);render();}
for(const name of ['inject','diagnose','recover','reset'])$(name).onclick=()=>act({type:name});
$('terminal').onsubmit=e=>{e.preventDefault();const result=execute(state,$('command').value);state=result.state;$('output').textContent=result.output;render();};
$('export').onclick=()=>{const blob=new Blob([JSON.stringify({project:'CloudOps Sentinel',mode:'browser simulation, not live infrastructure',exportedAt:new Date().toISOString(),...state},null,2)],{type:'application/json'});const url=URL.createObjectURL(blob);const a=document.createElement('a');a.href=url;a.download='sentinel-incident.json';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);};
render();
