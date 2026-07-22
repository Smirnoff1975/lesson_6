apt install nfs-kernel-server

mkdir -p /srv/share/upload
chown -R nobody:nogroup /srv/share
chmod 777 /srv/share/upload

grep "/srv/share" /etc/exports

if [ $? -ne 0 ]; then
cat >> /etc/exports <<EOF
/srv/share 192.168.0.0/24(rw,sync,root_squash)
EOF
fi

exportfs -ra
