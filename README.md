# lesson_6
ДЗ. Работа с NFS
# Домашнее задание
Работа с NFS
# Исполнитель
Павел Смирнов
# Цель
научиться самостоятельно разворачивать сервис NFS и подключать к нему клиентов;

Необходимо:
  - запустить 2 виртуальных машины (сервер NFS и клиента);
  - на сервере NFS должна быть подготовлена и экспортирована директория;
  - в экспортированной директории должна быть поддиректория с именем upload с правами на запись в неё;
  - экспортированная директория должна автоматически монтироваться на клиенте при старте виртуальной машины (systemd, autofs или fstab — любым способом);
  - монтирование и работа NFS на клиенте должна быть организована с использованием NFSv3.

# Среда выполнения
  VM VirtualBox 7.0.10, OS Ubuntu 24.04.03

# Команды и их описание
# Сервер

root@srv2:~# apt list --installed|grep nfs

-- смотрим наличие пакетов, для сервера nfs-kernel-server, если их нет ставим через apt install ...

root@srv2:~# mkdir -p /srv/share/upload

-- создаем иерархию папок для опытов

root@srv2:~# chown -R nobody:nogroup /srv/share

-- меняем владельца на nobody

root@srv2:~# chmod 777 /srv/share/upload

-- меняем права на папку - все для всех

root@srv2:~# cat >> /etc/exports <<EOF
/srv/share 192.168.0.0/24(rw,sync,root_squash)
EOF

-- добавляем в файл /etc/exports запись о новой фс NFS, описываем ограничения по адресам, прописываем параметры доступа

root@srv2:~# cat /etc/exports

-- проверяем

root@srv2:~# exportfs -ra

-- экспортируем все фс из файла /etc/exports - сообщаем службам NFS

root@srv2:~# exportfs -s

-- выводим список фс о котором знают службы NFS, проверяем что наш есть

root@srv2:~# ip -br a

-- показываем ip адрес сервера

root@srv2:~# cd /srv/share/upload/

root@srv2:/srv/share/upload# touch check_file

root@srv2:/srv/share/upload# ls

-- переходим в опытную папку, создаем там тестовый файл check_file для проверки на клиенте

root@srv2:/srv/share/upload# reboot

-- после настройки клиента и успешного монтрирования нашей фс перезагружаемся для финального испытания

usr1@srv2:~$ ls /srv/share/upload/

-- смотрим что после перезагрузки файлы (check_file, client_file) на месте

usr1@srv2:~$ sudo exportfs -s

-- смотрим что после перезагрузки наша фс NFS экспортируется автоматически

usr1@srv2:~$ showmount -a

-- проверяем, активные подключения к нашей фс с других хостов

usr1@srv2:~$ cd /srv/share/upload/

usr1@srv2:/srv/share/upload$ ls -l

-- проверяем наличие финального файла

# Клиент

root@srv1:~# apt list --installed| grep nfs

-- смотрим наличие пакетов, для сервера nfs-common, если их нет ставим через apt install ...

root@srv1:~# ip -br a

-- показываем адрес клиента

root@srv1:~# showmount -e 192.168.0.110

-- смотрим какие фс доступны на сервере

root@srv1:~# mount -o vers=3 192.168.0.110:/srv/share /mnt

root@srv1:~# ls /mnt/upload/

root@srv1:~# ls -l /mnt/upload/

root@srv1:~# umount /mnt

-- проверяем монтирование в ручном режиме, добавляем параметр NFS vers=3 для использования протокола NFSv3 (по умолчанию используется v4)

root@srv1:~# echo "192.168.0.110:/srv/share/ /mnt nfs vers=3,noauto,x-systemd.automount 0 0" >> /etc/fstab

-- добавляем запись в /etc/fstab для автоматического монтирования

root@srv1:~# cat /etc/fstab

-- проверяем

root@srv1:~# systemctl daemon-reload

-- попросим службы перечитать свои конфигурации, для применения наших изменений без перезагрузки

root@srv1:~# systemctl restart remote-fs.target

-- перемонтирование всех сетевых фс

root@srv1:~# cd /mnt

root@srv1:/mnt# ls

root@srv1:/mnt# cd upload/

root@srv1:/mnt/upload# ls

root@srv1:/mnt/upload# cd /

-- проверили что наша фс доступна

root@srv1:/# mount | grep mnt

-- точка монтирования имеется с правильными параметрами

root@srv1:/# cd /mnt/upload/

root@srv1:/mnt/upload# ls

root@srv1:/mnt/upload# touch client_file

root@srv1:/mnt/upload# ls

-- создаем client_file для проверки его на сервере, паралельно видим check_file

root@srv1:/mnt/upload# reboot

-- перезагружаемся для финального испытания

usr1@srv1:~$ showmount -e 192.168.0.110

-- смотрим что сервер по прежнему предоставляет нашу фс для подключения

usr1@srv1:~$ showmount -a 192.168.0.110

-- список активных сессий оказался пустым

usr1@srv1:~$ cd /mnt

usr1@srv1:/mnt$ ls

usr1@srv1:/mnt$ showmount -a 192.168.0.110

-- после первого входа после перезагрузки в точку монтирования все заработало

usr1@srv1:/mnt$ cd upload/

usr1@srv1:/mnt/upload$ mount | grep mnt

-- смотрим, что наша точка монтирования на месте, с правильными параметрами

usr1@srv1:/mnt/upload$ ls

usr1@srv1:/mnt/upload$ touch final_check

usr1@srv1:/mnt/upload$ ls -l

-- создаем финальный файл для проверки видимости его на сервере

# Протокол сервер

login as: usr1
usr1@192.168.0.110's password:
Welcome to Ubuntu 24.04.3 LTS (GNU/Linux 6.8.0-136-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Wed Jul 22 06:56:48 PM UTC 2026

  System load:    0.1              Processes:               353
  Usage of /home: 0.0% of 1.90GB   Users logged in:         0
  Memory usage:   7%               IPv4 address for enp0s3: 192.168.0.110
  Swap usage:     0%

 * Strictly confined Kubernetes makes edge and IoT secure. Learn how MicroK8s
   just raised the bar for easy, resilient and secure K8s cluster deployment.

   https://ubuntu.com/engage/secure-kubernetes-at-the-edge

Expanded Security Maintenance for Applications is not enabled.

56 updates can be applied immediately.
1 of these updates is a standard security update.
To see these additional updates run: apt list --upgradable

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status


Last login: Tue Jul 21 21:24:59 2026 from 192.168.0.106
usr1@srv2:~$ sudo -i
[sudo] password for usr1:
root@srv2:~#
root@srv2:~# apt list --installed|grep nfs

WARNING: apt does not have a stable CLI interface. Use with caution in scripts.

libnfsidmap1/noble-updates,now 1:2.6.4-3ubuntu5.1 amd64 [installed,automatic]
nfs-common/noble-updates,now 1:2.6.4-3ubuntu5.1 amd64 [installed]
nfs-kernel-server/noble-updates,now 1:2.6.4-3ubuntu5.1 amd64 [installed]
root@srv2:~# mkdir -p /srv/share/upload
root@srv2:~# chown -R nobody:nogroup /srv/share
root@srv2:~# chmod 777 /srv/share/upload
root@srv2:~# ls -l /srv/share
total 4
drwxrwxrwx 2 nobody nogroup 4096 Jul 22 19:01 upload
root@srv2:~# cat >> /etc/exports <<EOF
/srv/share 192.168.0.0/24(rw,sync,root_squash)
EOF
root@srv2:~# cat /etc/exports
# /etc/exports: the access control list for filesystems which may be exported
#               to NFS clients.  See exports(5).
#
# Example for NFSv2 and NFSv3:
# /srv/homes       hostname1(rw,sync,no_subtree_check) hostname2(ro,sync,no_subtree_check)
#
# Example for NFSv4:
# /srv/nfs4        gss/krb5i(rw,sync,fsid=0,crossmnt,no_subtree_check)
# /srv/nfs4/homes  gss/krb5i(rw,sync,no_subtree_check)
#
/srv/share 192.168.0.0/24(rw,sync,root_squash)
root@srv2:~# exportfs -ra
exportfs: /etc/exports [1]: Neither 'subtree_check' or 'no_subtree_check' specified for export "192.168.0.0/24:/srv/share".
  Assuming default behaviour ('no_subtree_check').
  NOTE: this default has changed since nfs-utils version 1.0.x

root@srv2:~# exportfs -s
/srv/share  192.168.0.0/24(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
root@srv2:~# ip -br a
lo               UNKNOWN        127.0.0.1/8 ::1/128
enp0s3           UP             192.168.0.110/24 fe80::a00:27ff:fecd:1321/64
root@srv2:~# cd /srv/share/upload/
root@srv2:/srv/share/upload# touch check_file
root@srv2:/srv/share/upload# ls
check_file  client_file
root@srv2:/srv/share/upload# reboot

Broadcast message from root@srv2 on pts/1 (Wed 2026-07-22 19:30:37 UTC):

The system will reboot now!

root@srv2:/srv/share/upload#
login as: usr1
usr1@192.168.0.110's password:
Welcome to Ubuntu 24.04.3 LTS (GNU/Linux 6.8.0-136-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Wed Jul 22 07:33:36 PM UTC 2026

  System load:    0.65             Processes:               366
  Usage of /home: 0.0% of 1.90GB   Users logged in:         0
  Memory usage:   7%               IPv4 address for enp0s3: 192.168.0.110
  Swap usage:     0%

 * Strictly confined Kubernetes makes edge and IoT secure. Learn how MicroK8s
   just raised the bar for easy, resilient and secure K8s cluster deployment.

   https://ubuntu.com/engage/secure-kubernetes-at-the-edge

Expanded Security Maintenance for Applications is not enabled.

65 updates can be applied immediately.
11 of these updates are standard security updates.
To see these additional updates run: apt list --upgradable

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status


Last login: Wed Jul 22 19:24:35 2026 from 192.168.0.106
usr1@srv2:~$ ls /srv/share/upload/
check_file  client_file
usr1@srv2:~$ sudo exportfs -s
[sudo] password for usr1:
/srv/share  192.168.0.0/24(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
usr1@srv2:~$ showmount -a
All mount points on srv2:
192.168.0.111:/srv/share
usr1@srv2:~$ pwd
/home/usr1
usr1@srv2:~$ cd /srv/share//upload/
usr1@srv2:/srv/share/upload$ ls -l
total 0
-rw-r--r-- 1 root   root    0 Jul 22 19:17 check_file
-rw-r--r-- 1 nobody nogroup 0 Jul 22 19:18 client_file
-rw-rw-r-- 1 usr1   usr1    0 Jul 22 19:42 final_check
usr1@srv2:/srv/share/upload$


# Протокол клиент

login as: usr1
usr1@192.168.0.111's password:
Welcome to Ubuntu 24.04.3 LTS (GNU/Linux 6.8.0-136-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Wed Jul 22 07:09:11 PM UTC 2026

  System load:    0.08             Processes:               353
  Usage of /home: 0.0% of 1.90GB   Users logged in:         0
  Memory usage:   7%               IPv4 address for enp0s3: 192.168.0.111
  Swap usage:     0%

 * Strictly confined Kubernetes makes edge and IoT secure. Learn how MicroK8s
   just raised the bar for easy, resilient and secure K8s cluster deployment.

   https://ubuntu.com/engage/secure-kubernetes-at-the-edge

Expanded Security Maintenance for Applications is not enabled.

56 updates can be applied immediately.
1 of these updates is a standard security update.
To see these additional updates run: apt list --upgradable

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status


Last login: Tue Jul 21 21:40:51 2026 from 192.168.0.106
usr1@srv1:~$ sudo -i
[sudo] password for usr1:
root@srv1:~#
root@srv1:~# apt list --installed| grep nfs

WARNING: apt does not have a stable CLI interface. Use with caution in scripts.

libnfsidmap1/noble-updates,now 1:2.6.4-3ubuntu5.1 amd64 [installed,automatic]
nfs-common/noble-updates,now 1:2.6.4-3ubuntu5.1 amd64 [installed]
nfs-kernel-server/noble-updates,now 1:2.6.4-3ubuntu5.1 amd64 [installed]
root@srv1:~#
root@srv1:~# ip -br a
lo               UNKNOWN        127.0.0.1/8 ::1/128
enp0s3           UP             192.168.0.111/24 fe80::a00:27ff:fe23:b27a/64
root@srv1:~# showmount -e 192.168.0.110
Export list for 192.168.0.110:
/srv/share 192.168.0.0/24
root@srv1:~# mount -o vers=3 192.168.0.110:/srv/share /mnt
root@srv1:~# ls /mnt/upload/
root@srv1:~# ls -l /mnt/upload/
total 0
root@srv1:~# umount /mnt
root@srv1:~# echo "192.168.0.110:/srv/share/ /mnt nfs vers=3,noauto,x-systemd.automount 0 0" >> /etc/fstab
root@srv1:~# cat /etc/fstab
# /etc/fstab: static file system information.
#
# Use 'blkid' to print the universally unique identifier for a
# device; this may be used with UUID= as a more robust way to name devices
# that works even if disks are added and removed. See fstab(5).
#
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
# / was on /dev/ubuntu-vg/ubuntu-lv during curtin installation
/dev/disk/by-id/dm-uuid-LVM-rBf62w25QuqaIQN6BALHRP6eamaBlS5f6dIYp1zCtFs8OxpqwrwoaMid4gcl525g / ext4 defaults 0 1
# /boot was on /dev/sda2 during curtin installation
/dev/disk/by-uuid/caca99bb-0ad5-4d9a-885b-5e9c2ec88ff9 /boot ext4 defaults 0 1
/swap.img       none    swap    sw      0       0
#UUID="05e1b359-14dd-4a3b-af8d-2050ea769ff0" /raid/part1 ext4 defaults 0 2
UUID="96f7dbf0-fee6-4819-84f0-fd378ba190e0"  /var ext4 defaults 0 0
UUID="22680638-fa21-4446-8527-b9fd5d830fff"  /home ext4 defaults 0 0
192.168.0.110:/srv/share/ /mnt nfs vers=3,noauto,x-systemd.automount 0 0
root@srv1:~# systemctl daemon-reload
root@srv1:~# systemctl restart remote-fs.target
root@srv1:~# cd /mnt
root@srv1:/mnt# ls
upload
root@srv1:/mnt# cd upload/
root@srv1:/mnt/upload# ls
root@srv1:/mnt/upload# cd /
root@srv1:/# mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=74,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=13396)
192.168.0.110:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,mountaddr=192.168.0.110,mountvers=3,mountport=35753,mountproto=udp,local_lock=none,addr=192.168.0.110)
root@srv1:/# cd /mnt/upload/
root@srv1:/mnt/upload# ls
check_file
root@srv1:/mnt/upload# touch client_file
root@srv1:/mnt/upload# ls
check_file  client_file
root@srv1:/mnt/upload# reboot

Broadcast message from root@srv1 on pts/1 (Wed 2026-07-22 19:39:05 UTC):

The system will reboot now!

root@srv1:/mnt/upload#
login as: usr1
usr1@192.168.0.111's password:
Welcome to Ubuntu 24.04.3 LTS (GNU/Linux 6.8.0-136-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Wed Jul 22 07:41:09 PM UTC 2026

  System load:    0.92             Processes:               367
  Usage of /home: 0.0% of 1.90GB   Users logged in:         1
  Memory usage:   7%               IPv4 address for enp0s3: 192.168.0.111
  Swap usage:     0%

 * Strictly confined Kubernetes makes edge and IoT secure. Learn how MicroK8s
   just raised the bar for easy, resilient and secure K8s cluster deployment.

   https://ubuntu.com/engage/secure-kubernetes-at-the-edge

Expanded Security Maintenance for Applications is not enabled.

56 updates can be applied immediately.
1 of these updates is a standard security update.
To see these additional updates run: apt list --upgradable

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status


Last login: Wed Jul 22 19:26:06 2026 from 192.168.0.106
usr1@srv1:~$ showmount -e 192.168.0.110
Export list for 192.168.0.110:
/srv/share 192.168.0.0/24
usr1@srv1:~$ showmount -a 192.168.0.110
All mount points on 192.168.0.110:
usr1@srv1:~$ cd /mnt
usr1@srv1:/mnt$ ls
upload
usr1@srv1:/mnt$ showmount -a 192.168.0.110
All mount points on 192.168.0.110:
192.168.0.111:/srv/share
usr1@srv1:/mnt$ cd upload/
usr1@srv1:/mnt/upload$ mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=71,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=5011)
192.168.0.110:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,mountaddr=192.168.0.110,mountvers=3,mountport=60003,mountproto=udp,local_lock=none,addr=192.168.0.110)
usr1@srv1:/mnt/upload$ ls
check_file  client_file
usr1@srv1:/mnt/upload$ touch final_check
usr1@srv1:/mnt/upload$ ls -l
total 0
-rw-r--r-- 1 root   root    0 Jul 22 19:17 check_file
-rw-r--r-- 1 nobody nogroup 0 Jul 22 19:18 client_file
-rw-rw-r-- 1 usr1   usr1    0 Jul 22 19:42 final_check
usr1@srv1:/mnt/upload$

