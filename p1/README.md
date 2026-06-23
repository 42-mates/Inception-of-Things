# Part 1: K3s and Vagrant

This project provisions a minimal Kubernetes cluster using K3s on two Debian VMs managed by Vagrant and VirtualBox

## Quick Start

Use command `vagrant up` in `/p1` directory

This boots two VMs:
| VM name   | Role          | IP             |
|-----------|---------------|----------------|
| <login>S  | Control-plane	| 192.168.56.110 |
| <login>SW | Worker/Agent  | 192.168.56.111 |

## Verification

1. **SSH into the server**  
No password should be required

```bash
vagrant ssh <login>S
```

2. **Check node status**
```bash
kubectl get nodes -o wide
...
NAME        STATUS   ROLES   AGE   VERSION     INTERNAL-IP
<login>S    Ready    XXX     Xm    vXXX+k3s1   192.168.56.110
<login>SW   Ready    XXX     Xm    vXXX+k3s1   192.168.56.111
```

3. **Check system pods**  
All pods should show Running status
```bash
kubectl get pods -A
```

## Basic Checklist
- `vagrant up` completes without errors
- `vagrant ssh <login>S` — no password required
- `vagrant ssh <login>SW` — no password required
- Server IP is `192.168.56.110`
- Worker IP is `192.168.56.111`
- `kubectl get nodes` shows both nodes as Ready
- Server has role control-plane / master
- `kubectl get pods -A` shows no CrashLoopBackOff

## Useful Commands
| Command                      | Info                     |
|------------------------------|--------------------------|
| `vagrant up`                 | Create and provision VMs |
| `vagrant halt`               | Stop VMs                 |
| `vagrant destroy -f`         | Delete VMs               |
| `vagrant ssh <name>`         | SSH into a VM            |
| `vagrant status`             | Show VM states           |
| `vagrant provision`          | Re-run provisioners      |
| `vagrant ssh <login>SW`      | SSH to worker            |
| `journalctl -u k3s -f`       | View K3s server logs     |
| `journalctl -u k3s-agent -f` | View K3s agent logs      |


Delete vm if exist

```bash
VBoxManage list vms
...
VBoxManage unregistervm akurochkS --delete
```

```bash
virsh list --all
virsh -c qemu:///system list --all

# virsh destroy p1_akurochkS
# virsh undefine p1_akurochkS --remove-all-storage

# virsh destroy p1_akurochkSW
# virsh undefine p1_akurochkSW --remove-all-storage

# virsh -c qemu:///system destroy p1_akurochkS
# virsh -c qemu:///system undefine p1_akurochkS --remove-all-storage

# virsh -c qemu:///system destroy p1_akurochkSW
# virsh -c qemu:///system undefine p1_akurochkSW --remove-all-storage
```


Free CPU
```bash
sudo modprobe -r kvm_intel kvm_amd kvm

sudo nano /etc/modprobe.d/blacklist-kvm.conf
# add:
# blacklist kvm
# blacklist kvm_intel
# blacklist kvm_amd
```

```bash
vagrant up 2>&1 | tee -a logs.txt
VAGRANT_LOG=debug vagrant up 2>&1 | tee -a logs.txt
VAGRANT_LOG=info vagrant up 2>&1 | tee -a logs.txt
```

```bash
vagrant plugin install vagrant-vbguest
```