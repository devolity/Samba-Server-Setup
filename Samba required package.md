yum -y epel-release

yum -y install wget gcc vim git gdb libxml2 libxslt python-devel gnutls-devel libacl-devel openldap-devel libldap2-dev openssl  


wget https://download.samba.org/pub/samba/samba-4.3.3.tar.gz

tar xvf samba-4.3.3.tar.gz

cd samba-4.3.3

./configure; make; make install


libgnutls-dev