#####################################################################################
############### Autenticacion de Clientes Linux (Deepin) contra Samba4 ##############

# 1- Instalar paquetes requeridos para el cliente
sudo apt-get install sssd heimdal-clients msktutil

# 2- Configurar Kerberos o simplemente dejarlo vacio para mas adelante configurarlo
# Editar el fichero /etc/krb5.conf

sudo /etc/krb5.conf

# Borrar todo lo que tiene y poner estas lineas, solo modificar el dominio
[libdefaults]
  default_realm = MY-DOMAIN.COM
  rdns = no
  dns_lookup_kdc = true
  dns_lookup_realm = false

# 3- Editar el fichero /etc/hosts
sudo /etc/hosts

# Adicionar las siguientes lineas, solo modificar el dominio
127.0.0.1 localhost
127.0.1.1 sysadmin-pc.my-domain.com sysadmin-pc
10.18.3.5 sysadmin-pc.domain.com sysadmin-pc

# 4- Como usuario habitual, obtenga el ticket de Kerberos del administrador del dominio:
kinit Administrator
# Administrator@sysadmin-pc's Password: 
# angelito@sysadmin-pc:~$ klist
# Credentials cache: FILE:/tmp/krb5cc_1001
#        Principal: Administrator@MY-DOMAIN.COM

#  Issued                Expires               Principal
# Jun 06 16:15:04 2019  Jun 07 08:29:53 2019  krbtgt/MY-DOMAIN.COM@MY-DOMAIN.COM

# 5- Ahora generará los tickets de Kerberos para este host, reemplazará los nombres de host para el cliente y el servidor, y nuevamente, preste atención al uso de mayúsculas:
sudo msktutil -N -c -b 'OU=MYORG, CN=COMPUTERS' -s HOST/sysadmin-pc.my-domain.com -k test.keytab --computer-name SYSADMIN-PC --upn SYSADMIN-PC$ --server my-domain.com --user-creds-only --verbose

sudo msktutil -N -c -b 'OU=MYORG, CN=COMPUTERS' -s HOST/sysadmin-pc -k test.keytab --computer-name SYSADMIN-PC  --upn SYSADMIN-PC $ --server my-domain.com --user-creds-only --verbose

# Ahora usted podra ver la maquina ya unida al dominio en su Active Directory

# 6- Destruir el tickets de Kerberos
sudo kdestroy

# 7- Copiar el fichero keytab  /etc/sssd:
sudo cp test.keytab /etc/sssd/

# 8- Crear el fichero /etc/sssd/sssd.conf con el siguiente contenido:
[sssd]

services = nss, pam
config_file_version = 2
domains = my-domain.com


[nss]

entry_negative_timeout = 0
debug_level = 5


[pam]

debug_level = 5


[domain/my-domain.com]

debug_level = 10
enumerate = false
id_provider = ad
auth_provider = ad
chpass_provider = ad
access_provider = ad
dyndns_update = false
ad_hostname = my-domain.com
ad_server = my-domain.com

ad_domain = my-domain.com
ldap_schema = ad
ldap_id_mapping = true
fallback_homedir = /home/%u
default_shell = /bin/bash
ldap_sasl_mech = gssapi
ldap_sasl_authid = SYSADMIN-PC$
krb5_keytab = /etc/sssd/test.keytab

ldap_krb5_init_creds = true


# Reemplace el dominio y los nombres de host cuando sea necesario, el parámetro krb5_keytab debe apuntar al keytab que creó y copió.

# 9- Establezca los permisos correctos para el archivo sssd.conf:
sudo chmod 0600 /etc/sssd/sssd.conf

# 10- Reiniciar el servicio SSSD
sudo service sssd restart

# 11- Editar el fichero /etc/pam.d/common-session y adicinar lo siguiente
session required pam_mkhomedir.so skel=/etc/skel umask=0077

# 12- Instalar lightdm-gtk-greeter, puesto que el lightdm que trae por defecto Deepin no permite el logueo de varios usuarios
sudo apt-get install lightdm-gtk-greeter

# 13- Editamos el fihero /etc/lightdm/lightdm.conf
sudo nano /etc/lightdm/lightdm.conf

# Modificar las lineas que tienen las que pondre aqui, que dando tal y como lo pongo yo
greeter-session=lightdm-gtk-greeter
greeter-show-manual-login=true
user-session=deepin
allow-guest=false
autologin-guest=false

# 14- Por último reiniciamos lightdm y entramos con cualquier user del dominio
sudo service lightdm restart







