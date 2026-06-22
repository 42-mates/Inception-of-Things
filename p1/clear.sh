echo "Scanning VMs..."

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

rm -rf node-token
rm -rf logs.txt

echo "Scanning VirtualBox VMs..."

# VBoxManage list vms

VBoxManage list vms | while read -r line; do
    name=$(echo "$line" | cut -d\" -f2)
    uuid=$(echo "$line" | awk -F'[{}]' '{print $2}')

    # Skip empty lines
    if [ -z "$uuid" ]; then
        continue
    fi

    # Detect inaccessible VMs
    if [[ "$name" == "<inaccessible>" || "$name" == "akurochkS" || "$name" == "akurochkSW" ]]; then
        echo "Removing inaccessible VM: $uuid"

        VBoxManage unregistervm "$uuid" --delete 2>/dev/null || true
    fi
done

echo "Scanning Vagrant VMs..."
vagrant destroy -f
rm -rf .vagrant

echo "Cleanup complete."

sudo bash ../clean_vm.sh
