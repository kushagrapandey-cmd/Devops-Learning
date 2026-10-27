// Pure deterministic lab model. This never connects to a cluster or runs a shell.
export const scenarios = {
  readiness: {
    title: 'Readiness probe failure', code: 'INC-001', severity: 'Degraded',
    symptom: 'One pod is running, but refuses new traffic.',
    signal: 'HTTP /readyz → 503. Liveness remains 200. Ready replicas: 1/2.',
    cause: 'A local maintenance marker exists in one container. The readiness probe fails, so this pod is ineligible for Service traffic.',
    diagnose: 'kubectl describe pod sentinel-a -n sentinel',
    recover: 'remove readiness marker',
    command: 'kubectl exec -n sentinel POD -- python -c \'from pathlib import Path; Path("/tmp/sentinel-not-ready").unlink(missing_ok=True)\'',
    recovery: 'Marker removed. Readiness succeeds. Both replicas can receive traffic.',
    concept: 'Readiness controls traffic eligibility; it does not restart a healthy process.',
    pods: [{name:'sentinel-a',state:'NotReady',ready:false,restarts:0},{name:'sentinel-b',state:'Running',ready:true,restarts:0}],
    errorRate: 0, latency: 82, ready: 1, resource: '64 / 128 Mi',
  },
  image: {
    title: 'Broken image release', code: 'INC-002', severity: 'Rollout stalled',
    symptom: 'The new revision cannot pull its container image.',
    signal: 'ImagePullBackOff on the new pod. Two old replicas remain ready.',
    cause: 'The image tag does not exist. With maxUnavailable: 0, the healthy old revision stays in service while the rollout stalls.',
    diagnose: 'kubectl get events -n sentinel',
    recover: 'kubectl rollout undo deployment/sentinel -n sentinel',
    command: 'kubectl rollout undo deployment/sentinel -n sentinel',
    recovery: 'Previous ReplicaSet restored. The failed revision is scaled down.',
    concept: 'A failed rollout is not an automatic rollback. The operator chooses to undo it.',
    pods: [{name:'sentinel-a',state:'Running',ready:true,restarts:0},{name:'sentinel-b',state:'Running',ready:true,restarts:0},{name:'sentinel-new',state:'ImagePullBackOff',ready:false,restarts:0}],
    errorRate: 0, latency: 42, ready: 2, resource: '64 / 128 Mi',
  },
  oom: {
    title: 'Container memory limit', code: 'INC-003', severity: 'Restarting',
    symptom: 'A container is repeatedly killed despite free memory on the host.',
    signal: 'Last State: Terminated, Reason: OOMKilled, Exit Code: 137. Restart count: 3.',
    cause: 'The process exceeded its cgroup memory limit. Low host-visible memory usage does not rule out a container OOM.',
    diagnose: 'kubectl describe pod sentinel-a -n sentinel',
    recover: 'apply reviewed memory fix',
    command: '# Investigate the allocation/leak first, then deploy a reviewed fix and verify container memory.',
    recovery: 'Simulated reviewed memory fix applied. Restarts stabilize; verify the workload before closing the incident.',
    concept: 'Investigate actual container usage and the cause. Raising limits or restarting blindly is not a diagnosis.',
    pods: [{name:'sentinel-a',state:'CrashLoopBackOff',ready:false,restarts:3},{name:'sentinel-b',state:'Running',ready:true,restarts:0}],
    errorRate: 3, latency: 115, ready: 1, resource: 'limit exceeded',
  },
  selector: {
    title: 'Service selector mismatch', code: 'INC-004', severity: 'Unavailable',
    symptom: 'Pods are healthy, but the Service has no matching backends.',
    signal: 'Deployment pods: 2/2 Ready. Service selector app=sentine1 matches zero pods.',
    cause: 'A typo in the Service selector prevents it from selecting pods labelled app=sentinel. Pod readiness alone cannot fix routing.',
    diagnose: 'kubectl get endpointslices -n sentinel',
    recover: 'restore service selector',
    command: 'kubectl apply -f k8s/service.yaml',
    recovery: 'Selector restored to app=sentinel. Ready backends are selected again.',
    concept: 'Follow the request path: Service selector → matching pods → readiness → targetPort.',
    pods: [{name:'sentinel-a',state:'Running',ready:true,restarts:0},{name:'sentinel-b',state:'Running',ready:true,restarts:0}],
    errorRate: 100, latency: 0, ready: 2, resource: '64 / 128 Mi',
  },
};

const healthyPods = () => ['a','b'].map(id=>({name:`sentinel-${id}`,state:'Running',ready:true,restarts:0}));
const event = (step, message) => ({step,message});
export const initialState = () => ({version:1, scenario:'readiness', phase:'healthy', history:[event(1,'Lab initialized. Two simulated replicas are ready.')], attempts:0});
export function transition(state, action) {
  const next = structuredClone(state);
  const append = message => next.history.push(event(next.history.length + 1,message));
  switch (action.type) {
    case 'select':
      if (!(action.scenario in scenarios)) return state;
      if (['injected','diagnosed'].includes(state.phase)) return state;
      next.scenario = action.scenario; next.phase = 'healthy'; next.attempts = 0;
      append(`Selected: ${scenarios[action.scenario].title}.`); break;
    case 'inject':
      if (!['healthy','recovered'].includes(state.phase)) return state;
      next.phase='injected'; next.attempts=0; append(`Failure injected: ${scenarios[state.scenario].symptom}`); break;
    case 'diagnose':
      if (state.phase!=='injected') return state;
      next.phase='diagnosed'; append(`Evidence collected: ${scenarios[state.scenario].signal}`); break;
    case 'recover':
      if (state.phase!=='diagnosed') return state;
      next.phase='recovered'; append(scenarios[state.scenario].recovery); break;
    case 'reset': return initialState();
    default: return state;
  }
  next.history = next.history.slice(-40);
  return next;
}
export function view(state) {
  const fault = ['injected','diagnosed'].includes(state.phase);
  const selected = scenarios[state.scenario];
  return {fault, selected, pods:fault ? selected.pods : healthyPods(), ready:fault?selected.ready:2,
    errorRate:fault?selected.errorRate:0, latency:fault?selected.latency:42,
    endpoints:fault && state.scenario==='selector'?0:(fault?selected.ready:2),
    memory:fault?selected.resource:'64 / 128 Mi'};
}
export function restore(raw) {
  try {
    const value=JSON.parse(raw);
    if(value.version!==1 || !Object.hasOwn(scenarios,value.scenario) || !['healthy','injected','diagnosed','recovered'].includes(value.phase)) return initialState();
    // Stored history is intentionally rebuilt; arbitrary stored strings are not trusted.
    return {...initialState(),scenario:value.scenario,phase:value.phase,
      history:[event(1,`Restored ${value.scenario} lab in ${value.phase} state.`)]};
  } catch { return initialState(); }
}
export function execute(state, raw) {
  const command=raw.trim().replace(/\s+/g,' ');
  const available=view(state);
  if(command==='help') return {state,output:'Commands: help | kubectl get pods -n sentinel | kubectl get events -n sentinel | kubectl describe pod sentinel-a -n sentinel | kubectl get endpointslices -n sentinel | diagnose | recover | reset'};
  if(command==='reset') return {state:transition(state,{type:'reset'}),output:'Lab reset. No cloud resources were changed.'};
  if(command==='kubectl get pods -n sentinel') return {state,output:available.pods.map(p=>`${p.name}   ${p.ready?'1/1':'0/1'}   ${p.state}   restarts=${p.restarts}`).join('\n')};
  if(command==='diagnose' || command===available.selected.diagnose) return {state:transition(state,{type:'diagnose'}),output:available.fault?available.selected.signal:'No active failure. Inject a scenario first.'};
  if(command==='kubectl get events -n sentinel' || command==='kubectl describe pod sentinel-a -n sentinel' || command==='kubectl get endpointslices -n sentinel') {
    return {state,output:available.fault?available.selected.signal:'Two replicas are ready; no active incident.'};
  }
  if(command==='recover' || command===available.selected.recover) {
    if(state.phase!=='diagnosed') return {state,output:'Collect evidence with diagnose before recovery.'};
    return {state:transition(state,{type:'recover'}),output:available.selected.recovery};
  }
  return {state,output:'Unsupported command. Type help. This terminal simulates an allowlisted set of commands; it does not run a shell.'};
}
