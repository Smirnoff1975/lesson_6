apt install nfs-common

grep "/srv/share" /etc/fstab

if [ $? -ne 0 ]; then
echo "192.168.0.110:/srv/share/ /mnt nfs vers=3,noauto,x-systemd.automount 0 0" >> /etc/fstab
fi

systemctl daemon-reload
systemctl restart remote-fs.target

cd /mnt
