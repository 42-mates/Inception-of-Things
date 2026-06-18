
vagrant destroy -f

virsh list --all
virsh -c qemu:///system list --all

virsh destroy p1_akurochkS
virsh undefine p1_akurochkS --remove-all-storage

virsh destroy p1_akurochkSW
virsh undefine p1_akurochkSW --remove-all-storage

virsh -c qemu:///system destroy p1_akurochkS
virsh -c qemu:///system undefine p1_akurochkS --remove-all-storage

virsh -c qemu:///system destroy p1_akurochkSW
virsh -c qemu:///system undefine p1_akurochkSW --remove-all-storage

vagrant destroy -f

rm -rf .vagrant
rm -rf node-token