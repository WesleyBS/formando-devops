#!/bin/bash #apenas para habilitar as cores

timedatectl set-timezone America/Fortaleza

#=======================================================================

[Desafio 1] - # Kernel e Boot loader

shutdown -r now
# Espere reiniciar e na tela de boot, presione E
# No arquivo que aparecer troque "ro" por "rw init=/sysroot/bin/sh"
# Salve o arquivo com "Ctrl + x"
# No prompt que aparecerá, troque a senha do root e reinicie o SO
chroot /sysroot
passwd
touch ./autorelabel
exit
reboot

# Entre com a nova senha do root. Altere a senha do vagrant e inclua-o no sudoers
passwd vagrant
echo "vagrant ALL=(ALL)       ALL" >> /etc/sudoers
su vagrant
sudo cat /etc/sudoers

#=======================================================================

[Desafio 2] - # Usuários

sudo groupadd getup -g 2222
sudo useradd getup -u 1111 -g 2222 --groups bin
sudo echo 'getup ALL=NOPASSWD:ALL' >> /etc/sudoers
su getup
sudo cat /etc/sudoers


#=======================================================================

[Desafio 3] - # SSH

[3.2]
# No client
ssh-keygen -t ecdsa
ssh-copy-id -i ~/.ssh/id_ecdsa.pub vagrant@192.168.15.110
ssh vagrant@192.168.15.110

[3.1]
#No servidor
sudo sed -i "s/PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
sudo sed -i "s/#PubkeyAuthentication yes/PubkeyAuthentication yes/" /etc/ssh/sshd_config
sudo systemctl restart sshd

[3.3]
# No cliente (troquei o carriage-return "\r" pelo o newline "\n", deletando as linhas em branco logo em seguida)
base64 -d id_rsa-desafio-linux-devel.gz.b64 | gzip -d > id_rsa
chmod 600 id_rsa
sed -i "s/\\r/\\n/g" id_rsa && sed -i '/^$/d' id_rsa

# No servidor
sudo tail -n 50 /var/log/secure
sudo chown -R vagrant. /home/devel/.ssh/
sudo chmod 600 /home/devel/.ssh/authorized_keys

# No cliente
ssh -i id_rsa devel@192.168.15.110


#=======================================================================

[Desafio 4] - # Systemd

sudo nginx -t
sudo sed -i "s/root \/usr\/share\/nginx\/html/root \/usr\/share\/nginx\/html;/" /etc/nginx/nginx.conf
sudo nginx -t
sudo systemctl restart nginx
sudo journalctl -u nginx
sudo sed -i "s/ExecStart=\/usr\/sbin\/nginx -BROKEN/ExecStart=\/usr\/sbin\/nginx/" /usr/lib/systemd/system/nginx.service
sudo ss -tlnp
sudo sed -i "s/90/80/g" /etc/nginx/nginx.conf
sudo nginx -t
sudo systemctl reload nginx
sudo ss -tlnp
curl http://127.0.0.1
# Duas palavrinhas pra você: para, béns!

#=======================================================================

[Desafio 5] - # SSL

[5.1]
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout server.key

#Country Name (2 letter code) [XX]:BR
#State or Province Name (full name) []:Maranhao
#Locality Name (eg, city) [Default City]:Sao Luis
#Organization Name (eg, company) [Default Company Ltd]:
#Organizational Unit Name (eg, section) []:
#Common Name (eg, your name or your server's hostname) []:desafio.local
#Email Address []:wesley@formandodevops.com

sudo openssl req -x509 -new -nodes -key server.key -sha256 -days 1825 -out server.crt

#Country Name (2 letter code) [XX]:BR
#State or Province Name (full name) []:Maranhao
#Locality Name (eg, city) [Default City]:Sao Luis
#Organization Name (eg, company) [Default Company Ltd]:
#Organizational Unit Name (eg, section) []:
#Common Name (eg, your name or your server's hostname) []:www.desafio.local
#Email Address []:wesley@formandodevops.com

sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048 #contorna o problema de diffie-hellman

[5.2]
sudo su
cat << EOF >> /etc/nginx/nginx.conf

    server {
        listen       443 ssl http2;
        listen       [::]:443 ssl http2;
        server_name  www.desafio.local;
        root         /usr/share/nginx/html;
        ssl_certificate "/etc/pki/nginx/server.crt";
        ssl_certificate_key "/etc/pki/nginx/private/server.key";
        ssl_dhparam "/etc/ssl/certs/dhparam.pem";
    }
EOF

su vagrant

sudo nginx -t
sudo mkdir /etc/pki/nginx/
sudo mkdir /etc/pki/nginx/private/

sudo cp server.crt /etc/pki/ca-trust/source/anchors/server.crt
sudo cp server.crt /etc/pki/nginx/server.crt
sudo cp server.key /etc/pki/nginx/private/server.key

sudo update-ca-trust force-enable
sudo update-ca-trust extract

sudo su
echo "127.0.0.1 desafio.local" >> /etc/hosts
echo "127.0.0.1 www.desafio.local" >> /etc/hosts
su vagrant

sudo systemctl reload nginx
curl https://www.desafio.local
#Duas palavrinhas pra você: para, béns!

#=======================================================================

[Desafio 6] - REDE

[6.1]
# ping não demonstrou problemas

ping 8.8.8.8

#PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
#64 bytes from 8.8.8.8: icmp_seq=1 ttl=63 time=581 ms
#64 bytes from 8.8.8.8: icmp_seq=2 ttl=63 time=61.7 ms
#64 bytes from 8.8.8.8: icmp_seq=3 ttl=63 time=59.9 ms
#64 bytes from 8.8.8.8: icmp_seq=4 ttl=63 time=60.0 ms
#^C
#--- 8.8.8.8 ping statistics ---
#4 packets transmitted, 4 received, 0% packet loss, time 3002ms
#rtt min/avg/max/mdev = 59.860/190.676/581.138/225.434 ms

[6.2]
curl -i https://httpbin.org/response-headers?hello=world

#HTTP/2 200 
#date: Wed, 07 Sep 2022 04:02:46 GMT
#content-type: application/json
#content-length: 89
#server: gunicorn/19.9.0
#hello: world
#access-control-allow-origin: *
#access-control-allow-credentials: true
#
#{
#  "Content-Length": "89", 
#  "Content-Type": "application/json", 
#  "hello": "world"
#}

#=======================================================================

[Desafio 7] - Logs

touch /etc/logrotate.d/nginx

sudo su
cat << EOF >> /etc/logrotate.d/nginx
/var/log/nginx/*.log {
	weekly
        missingok
        rotate 4
	dateext
        compress
        create 0640 nginx adm
}
EOF
su vagrant

sudo logrotate -f /etc/logrotate.d/nginx

touch /etc/cron.daily/logrotate

sudo su
cat << EOF >> /etc/cron.daily/logrotate
#!/bin/sh

# skip in favour of systemd timer
if [ -d /run/systemd/system ]; then
    exit 0
fi

# this cronjob persists removals (but not purges)
if [ ! -x /usr/sbin/logrotate ]; then
    exit 0
fi

/usr/sbin/logrotate /etc/logrotate.conf
EXITVALUE=$?
if [ $EXITVALUE != 0 ]; then
    /usr/bin/logger -t logrotate "ALERT exited abnormally with [$EXITVALUE]"
fi
exit $EXITVALUE
EOF
su vagrant

crontab -e
25 6    * * *   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.daily )
crontab -l -u vagrant
#25 6    * * *   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.daily )
systemctl restart crond

#=======================================================================

[Desafio 8] - Filesystem

[8.1]
sudo su
cfdisk /dev/sdb
> /dev/sdb1
Resize
5G
Write
yes
Quit

pvs
pvresize /dev/sdb1
lvs
lvextend -l +100%FREE /dev/mapper/data_vg-data_lv
lvs
resize2fs /dev/mapper/data_vg-data_lv
df -h | egrep -v "*tmpfs*"
#Filesystem                   Size  Used Avail Use% Mounted on
#/dev/mapper/cl_centos8-root  125G  2.7G  123G   3% /
#/dev/mapper/data_vg-data_lv  5.0G  4.0M  4.7G   1% /data
#/dev/sda1                   1014M  203M  812M  20% /boot

[8.2]
sudo su
cfdisk /dev/sdb
> Free Size
New
5G
primary
Type
8e
Write
yes
Quit

mkfs.exit4 /dev/sdb2

[8.3]
sudo su
yum search xfs
yum install -y xfsprogs.x86_64
mkfs.xfs /dev/sdc

lsblk -o NAME,SIZE,MOUNTPOINT,FSTYPE
#NAME                 SIZE MOUNTPOINT FSTYPE
#sda                  128G            
#|-sda1                 1G /boot      xfs
#`-sda2               127G            LVM2_member
#  |-cl_centos8-root  125G /          xfs
#  `-cl_centos8-swap  2.1G [SWAP]     swap
#sdb                   10G            
#|-sdb1                 5G            LVM2_member
#| `-data_vg-data_lv 1020M /data      ext4
#`-sdb2                 5G            ext4
#sdc                   10Gi	      xfs

shutdown -h now #VAAAAAI
