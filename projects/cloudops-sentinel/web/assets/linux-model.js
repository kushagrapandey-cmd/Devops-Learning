// Allowlisted teaching simulator. No shell, SSH or Azure execution.
export const labs={
 service:{title:'Application service stopped',ticket:'Application is unavailable. Find which layer failed.',required:['systemctl status sentinel','journalctl -u sentinel -n 20','curl localhost:8080/healthz'],fix:'sudo systemctl start sentinel',cause:'Process band hai. Network rule change karne se process start nahi hoga.'},
 bind:{title:'Application listening on wrong port',ticket:'VM reachable hai; application check fails.',required:['systemctl status sentinel','ss -ltn','cat /etc/sentinel-lab/app.env'],fix:'restore-config',cause:'Service running hai lekin PORT=9090 configured hai. Expected endpoint 8080 par koi listener nahi.'},
 network:{title:'Remote request blocked',ticket:'Local request works, remote request times out.',required:['curl localhost:8080/healthz','ss -ltn','az network nsg rule list'],fix:'restore-nsg',cause:'Local application healthy hai. Simulated remote path par NSG deny hai. Is exercise ka listener 0.0.0.0 hai; real baseline loopback + SSH tunnel use karta hai.'},
 patch:{title:'Planned patch maintenance',ticket:'Pending packages inspect karo, backup lo, patch aur reboot validate karo.',required:['systemctl status sentinel','df -h /','backup-config','sudo apt-get --simulate upgrade'],fix:'sudo apt-get upgrade',cause:'Prechecks aur configuration backup complete hone ke baad planned package upgrade. Config backup OS/package rollback nahi hai.'}
};
export function startLab(id='service'){if(!Object.hasOwn(labs,id))id='service';return {id,seen:[],fixed:false,patched:false,rebooted:false,verified:false,history:[]};}
export function runCommand(state,input){const s=structuredClone(state);const c=input.trim().replace(/\s+/g,' ');const lab=labs[s.id];let out='';
if(c==='help')out='Commands:\n'+[...lab.required,lab.fix,'curl localhost:8080/healthz','curl remote:8080/healthz','sudo reboot','explain'].join('\n');
else if(c==='explain')out=lab.cause+'\nInspect → diagnose → fix → verify. Guide mein actual commands aur limits diye hain.';
else if(c==='systemctl status sentinel')out=s.id==='service'&&!s.fixed?'Active: inactive (dead)':'Active: active (running)';
else if(c==='journalctl -u sentinel -n 20')out='systemd: Stopped CloudOps Sentinel. No current process. Inspect service state before changing networking.';
else if(c==='ss -ltn')out=s.id==='service'&&!s.fixed?'No listener on :8080':s.id==='bind'&&!s.fixed?'LISTEN 127.0.0.1:9090':s.id==='network'?'LISTEN 0.0.0.0:8080':'LISTEN 127.0.0.1:8080';
else if(c==='cat /etc/sentinel-lab/app.env')out='BIND=127.0.0.1\nPORT='+((s.id==='bind'&&!s.fixed)?'9090':'8080');
else if(c==='df -h /')out='Filesystem   Size Used Avail Use% Mounted on\n/dev/root     30G   8G   22G  27% /';
else if(c==='az network nsg rule list')out=s.id==='network'&&!s.fixed?'Priority 100: Deny TCP 8080 from operator; local loopback is unaffected.':'No injected deny rule.';
else if(c==='backup-config')out='Simulated app.env backup saved; checksum recorded. Only application configuration is covered.';
else if(c==='sudo apt-get --simulate upgrade')out='SIMULATION: 3 example packages would be upgraded. No packages changed. Real counts vary.';
else if(c==='sudo reboot'){
 if(s.id!=='patch'||!s.patched)out='No planned reboot stage. Investigate first.';
 else{s.rebooted=true;out='Simulated reboot completed; systemd enabled service restarted. Run the HTTP check.';}
}
else if(c===lab.fix){const missing=lab.required.filter(x=>!s.seen.includes(x));if(missing.length)out='Evidence missing. Run:\n'+missing.join('\n');else if(s.id==='patch'){s.patched=true;out='Simulated packages upgraded. Reboot required. Run sudo reboot, then validate HTTP.';}else{s.fixed=true;out=s.id==='network'?'NSG restored in simulation. Verify curl remote:8080/healthz.':'Simulated fix applied. Incident stays open until curl localhost:8080/healthz succeeds.';}}
else if(c==='curl remote:8080/healthz'){
 if(s.id!=='network')out='Remote check belongs to the network assignment.';
 else if(!s.fixed)out='Remote connection timed out: injected NSG deny.';
 else{s.verified=true;out='Remote HTTP 200. Recovery verified.';}
}
else if(c==='curl localhost:8080/healthz'){
 const healthy=(s.id==='network'||s.fixed||(s.id==='patch'&&(!s.patched||s.rebooted)));
 out=healthy?'HTTP 200 {"status":"alive"}':'curl: connection refused';
 if(((s.fixed&&s.id!=='network')||(s.id==='patch'&&s.patched&&s.rebooted))&&healthy){s.verified=true;out+='\nRecovery verified.';}
 if(s.id==='network'&&!s.fixed)out+='\nLocal success does not prove remote reachability.';
}
else out='Unsupported command. Type help. Pipes, arbitrary paths and shell execution are not supported.';
if(lab.required.includes(c)&&!s.seen.includes(c))s.seen.push(c);
s.history.push({command:c,output:out});s.history=s.history.slice(-60);return {state:s,output:out};}
