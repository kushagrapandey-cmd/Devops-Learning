# Linux VM lab — Hinglish mein build, diagnose, patch aur recover

## Kya banaya, kyun banaya?

Server ko ek building samjho. Azure VM building hai; Linux operating system uska management; systemd supervisor; Python application andar ka service counter; port us counter ka door. NSG building ke bahar ka traffic gate hai. Gate kholne se band counter start nahi hota. Isi liye hum layer-by-layer evidence dekhte hain.

Website `/linux.html` ek teaching simulator hai: typed commands, distinct output, evidence checklist, guarded recovery, command history aur export. Koi actual shell/SSH execute nahi hota. Linux scripts actual Ubuntu VM par run hote hain. Azure resources is update mein create nahi kiye gaye.

## 1. Browser mein kya test karna hai?

[Linux workbench](https://cloudops-sentinel-three.vercel.app/linux.html) kholo. Assignment choose karo; terminal mein `help` type karo. Ek-ek command ka output padho. `explain` conceptual help deta hai; fix ko evidence checks ke bina run karoge toh missing commands milenge. Correct fix ke baad bhi incident tabhi close hota hai jab validation command succeeds.

| Assignment | Evidence | Fix | Verification |
|---|---|---|---|
| Service stopped | systemctl, journalctl, localhost curl | `sudo systemctl start sentinel` | localhost curl |
| Wrong port | systemctl, ss, app.env | `restore-config` | localhost curl |
| Remote blocked | localhost curl, ss, NSG rules | `restore-nsg` | `curl remote:8080/healthz` |
| Patching | service state, free disk, backup, upgrade simulation | `sudo apt-get upgrade` | simulated `sudo reboot`, then localhost curl |

`restore-config`, `restore-nsg`, `backup-config` aur `remote` hostname simulator shortcuts hain, real OS commands nahi. Real mappings neeche hain. NSG command ka real form resource-group/name arguments maangta hai; simulator abbreviated form accept karta hai. Real patching har baar reboot require nahi karti; simulator learning ke liye reboot-required case choose karta hai.

Arrow Up/Down se command history milegi. Exported JSON mein simulation label hai. Assignment change/reset evidence clear karta hai. Original Kubernetes lab separate page par available hai.

## 2. Ubuntu par actual application install karo

Use a dedicated Ubuntu 24.04 VM; host mein systemd, python3, curl, git, iproute2 aur sudo chahiye. WSL par systemd enabled hona chahiye; bina systemd ke Python-only path use karo. Installer account, /opt, /etc aur a systemd unit create karta hai, isliye shared production server par mat chalao.

```bash
git clone https://github.com/kushagrapandey-cmd/Devops-Learning.git
cd Devops-Learning/projects/cloudops-sentinel
sudo bash linux/install.sh --install-dedicated-lab
sudo systemctl status sentinel --no-pager
curl -fsS http://127.0.0.1:8080/healthz
bash linux/inspect.sh
```

Expected: service active, JSON `alive`. Port busy ho toh install verification fail hogi: `ss -ltn` aur journal inspect karo, arbitrary process kill mat karo.

### Code ka meaning

`linux/install.sh`: explicit flag aur root check → service user create → Python package `/opt/sentinel` mein copy → baseline config write only if missing → unit install → daemon-reload → enable/start → HTTP check. Re-running installer existing configuration overwrite nahi karta.

`linux/sentinel.service`:

- `User=sentinel`: application root permissions se nahi chalti.
- `WorkingDirectory=/opt/sentinel`: Python ko package yahan milta hai.
- `EnvironmentFile`: BIND/PORT code change kiye bina configure hote hain.
- `ExecStart`: `/usr/bin/python3 -m sentinel.server` module run karta hai.
- `Restart=on-failure`: process crash par restart; intentional systemctl stop ko undo nahi karta.
- `WantedBy=multi-user.target` + enable: machine boot ke baad service start.
- `ProtectSystem=strict`, `ProtectHome`, `NoNewPrivileges`: service ko filesystem/privilege access limit karte hain.
- `PrivateTmp`: service ka isolated temporary directory; host se marker touch karna is unit ke private /tmp ko affect nahi karega.

`BIND=127.0.0.1` ka matlab app sirf VM ke andar accessible hai. Ye intentional baseline hai. Browser access ke liye SSH tunnel use karenge; public 8080 rule required nahi.

## 3. Service failure create aur recover

```bash
sudo systemctl stop sentinel
systemctl is-active sentinel
curl --max-time 5 http://127.0.0.1:8080/healthz
sudo journalctl -u sentinel -n 20 --no-pager
sudo systemctl start sentinel
curl -fsS http://127.0.0.1:8080/healthz
```

Inactive + refused connection expected fault evidence hai. Stop/start controlled service outage hai, physical power outage nahi. `systemctl enable` aur `start` alag hain: enable next boot ke liye; start current session ke liye.

## 4. Wrong configuration aur actual restore

```bash
sudo bash linux/config-backup.sh backup
# Printed /var/backups/sentinel-lab/app.env.XXXXXX path note karo.
sudo sed -i 's/PORT=8080/PORT=9090/' /etc/sentinel-lab/app.env
sudo systemctl restart sentinel
ss -ltn
curl --max-time 5 http://127.0.0.1:8080/healthz
sudo bash linux/config-backup.sh restore /var/backups/sentinel-lab/app.env.YOUR_SUFFIX --restore-lab-config
```

Expected: service active lekin 9090 listener; 8080 refused. Restore helper baseline BIND/PORT validate karke config install, service restart aur HTTP check karta hai. Backup SHA256 content integrity compare karne ka tool hai; encryption ya full disaster recovery nahi. Is backup mein packages, OS, disks aur data included nahi. Baseline se different configuration restore deliberately rejected hai.

## 5. Patching ko maintenance workflow samjho

```bash
sudo systemctl status sentinel --no-pager
df -h /
sudo bash linux/config-backup.sh backup
bash linux/patch.sh plan
# Review window, recovery plan and package list first:
sudo bash linux/patch.sh apply --maintenance-approved
```

`plan` = apt-get simulation; installed packages change nahi hote, local apt metadata stale ho sakta hai. `apply` HTTP precheck → apt-get update → interactive apt-get upgrade → service/HTTP postcheck → reboot-required message. `upgrade` all eligible upgrades hai, security-only policy ya major Ubuntu release upgrade nahi. Package prompts ko read karo. APT lock ho toh investigate/wait; script lock files delete nahi karta.

Service restarts package upgrades ke dauran possible hain. App.env backup package rollback provide nahi karta. Important workloads ke liye tested VM/application recovery plan aur maintenance window chahiye.

Script automatic reboot nahi karta. Agar `/var/run/reboot-required` present hai toh dedicated lab par saved work ke baad explicitly:

```bash
sudo reboot
# SSH reconnect hone ke baad:
uptime
uname -r
systemctl is-enabled sentinel
systemctl is-active sentinel
curl -fsS http://127.0.0.1:8080/healthz
```

Reboot se SSH disconnect expected hai. SSH wapas aana aur app healthy hona alag validation hai. Ubuntu unattended security updates background mein bhi run kar sakte hain; scripts unhe disable nahi karte.

## 6. Real Azure VM: infrastructure as code

Optional paid lab. `azure/linux-vm/main.bicep` creates VNet (10.42.0.0/16), subnet (10.42.1.0/24), NIC, Standard static public IP, NSG and SSH-key-only Ubuntu 24.04 VM. Default size Standard_B2s; region capacity/quotas vary. Only operator public /32 gets explicit SSH ingress. Azure default NSG rules still exist; this is not total VNet isolation. No public app-port allow rule. VM/disk/public IP can cost money; stopped/deallocated VM does not remove all charges.

```bash
az login
export AZURE_SUBSCRIPTION_ID='YOUR-ID'
az account set --subscription "$AZURE_SUBSCRIPTION_ID"
export RESOURCE_GROUP='rg-sentinel-linux-lab'
az group create -n "$RESOURCE_GROUP" -l centralindia --tags project=cloudops-sentinel
export OPERATOR_CIDR='YOUR-PUBLIC-IP/32'
export SSH_PUBLIC_KEY_FILE="$HOME/.ssh/id_ed25519.pub"
# Generate your own key with ssh-keygen if needed. Never upload private key.
bash azure/linux-vm/deploy.sh what-if
bash azure/linux-vm/deploy.sh --create-billable-resources
az deployment group show -g "$RESOURCE_GROUP" -n main --query properties.outputs
```

What-if needs Azure permission and an existing group; it is not an offline test. VM creation does not install the app automatically. SSH in, clone source and run installer from step 2. Record the commit used.

```bash
ssh -L 18080:127.0.0.1:8080 labadmin@YOUR_VM_IP
# Your laptop, second terminal:
curl http://127.0.0.1:18080/healthz
```

Tunnel carries laptop localhost:18080 through SSH to VM localhost:8080. Python never needs a public listener. Verify SSH host key using trusted Azure information; do not disable host-key verification.

### NSG diagnosis without locking yourself out

```bash
az network nsg rule list -g "$RESOURCE_GROUP" --nsg-name sentinel-linux-nsg -o table
```

Simulator uses a hypothetical public app-port path to teach local-vs-remote troubleshooting; real baseline uses SSH tunnel. Do not inject SSH-deny rules into your only management path. If local curl works but laptop access fails, check tunnel process, SSH reachability, public IP/source /32, NSG, VM bind address and OS firewall. Network rule changes do not start stopped services.

### Cleanup

```bash
az resource list -g "$RESOURCE_GROUP" -o table
bash azure/cleanup.sh "--delete-$RESOURCE_GROUP"
az group exists -n "$RESOURCE_GROUP"
```

Verify current subscription before cleanup. Use only this dedicated tagged group. Expected eventually false. Retained/external resources need separate inspection; don't delete unrelated groups. This module does not implement data-disk expansion, Azure Backup or multi-VM availability; those are later labs.

## 7. Khud se build karne ka order

1. Python endpoint manually run karo aur curl response samjho.
2. Environment variable PORT change karke observe karo.
3. Unit file manually read/write karo: user, directory, command, boot behavior.
4. Stop/start + wrong-port failures reproduce aur evidence note karo.
5. Config backup, restore aur checksum inspect karo.
6. Simulated upgrades read karo; dedicated VM par maintenance perform karo.
7. Bicep resource references trace karo: VM → NIC → subnet + public IP + NSG.
8. Fresh resource group mein reproduce karo, then cleanup verify karo.

Browser implementation: `linux-model.js` pure state transitions/command allowlist hai; `linux-app.js` typed input ko model tak pass karke textContent se output render karta hai. Model commands ko OS shell mein pass nahi karta. Evidence collection and final verification separate states hain. Tests premature fixes aur local-only NSG verification ko reject karte hain.

## References checked 28 October 2026

- https://learn.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-bicep
- https://learn.microsoft.com/en-us/azure/virtual-machines/linux/linux-vm-connect
- https://documentation.ubuntu.com/security/security-updates/

Verification limits are in evidence/VERIFICATION.md. Bicep compilation does not prove subscription deployment; simulated patching does not prove OS patch success.
