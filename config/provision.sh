#!/bin/sh -eux
# eux

THIS_SCRIPT="$0" #>/dev/null 2>&1  
THIS_DIR="$(dirname $0)"
DB_PASSWD="mutillidae"
php_ver="7.4"
mySQL_ver="5.8"

install_file() {
  DEST_FILE=$1
  SOURCE_FILE="/vagrant/config/skel/${DEST_FILE}"
  mkdir -p "$(dirname ${DEST_FILE})"
  cp "${SOURCE_FILE}" "${DEST_FILE}"
}

apt_update() {
  apt update 
  echo
}

install_git() {
  apt install -y git 
}

install_apache() {
  apt install -y apache2 apache2-utils
}

tweak_apache_dir_conf() {
  install_file /etc/apache2/mods-enabled/dir.conf 
  systemctl restart apache2
}

install_mysql() {
#  echo "mysql-server-${mySQL_ver} mysql-server/root_password password \"''\"" | debconf-set-selections
#  echo "mysql-server-${mySQL_ver} mysql-server/root_password_again password \"''\"" | debconf-set-selections
  echo  "mysql-server-${mySQL_ver} mysql-server/root_password password $DB_PASSWD" | debconf-set-selections
  echo  "mysql-server-${mySQL_ver} mysql-server/root_password_again password $DB_PASSWD" | debconf-set-selections

  apt install -y mysql-server php-mysql 
  

  # Definition de la base de donnees 
    #echo "innodb_use_sys_malloc = 0" >> /etc/mysql/mysqld.cnf

   sudo systemctl restart mysql
   #sudo mysqld --initialize-insecure
 # Connect as root use with empty passwd to set up the database and the password
   mysql -u root -p$DB_PASSWD < /vagrant/Mutillidae.sql
}

install_php() {
# Installation des paquets
  apt install -y php${php_ver} php${php_ver}-mysql php-pear php${php_ver}-gd php${php_ver}-curl php${php_ver}-mbstring
  # Referentiel pour mcrypt
  printf "\n" | sudo add-apt-repository ppa:ondrej/php
  apt install -y mcrypt
  php_version=$(php -r \@phpinfo\(\)\; | grep 'PHP Version' -m 1 |cut -d" " -f4 |cut -d"." -f1-2)
# Activation du module mcrypt
  bash -c "echo extension=mcrypt.so > /etc/php/${php_version}/cli/php.ini" 
# Activation des erreurs PHP
  sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/${php_version}/apache2/php.ini
  sed -i "s/display_errors = .*/display_errors = On/" /etc/php/${php_version}/apache2/php.ini
  sudo systemctl restart apache2
}

install_phpinfo() {
  echo '<?php phpinfo(); ?>' > /var/www/html/phpinfo.php 
}

test_php() {
  curl http://localhost/phpinfo.php |grep PHP
  if [ $? -ne 0 ]; then
    echo "Problem with phpinfo.php..."
    exit 1
  fi
}

pull_latest_mutillidae() {
  GIT_REPO="git://git.code.sf.net/p/mutillidae/git"

  if [ ! -d "/vagrant/external/mutillidae" ]; then
    cd /vagrant/external
    git clone "${GIT_REPO}" mutillidae
  else
    cd /vagrant/external/mutillidae
    git remote set-url origin "${GIT_REPO}"
    git fetch
    git checkout master
    git reset --hard origin/master
  fi
}

install_mutillidae() {
  rm -rf /var/www/html/mutillidae
  apt install -y dos2unix mlocate
  find /vagrant/external/mutillidae -type f  -regex ".*\.\(php\|html\|inc\)" -exec dos2unix {} \;
  cp -R /vagrant/external/mutillidae /var/www/html/mutillidae
}


show_message() {
  echo
  echo "Now browse to http://localhost:4321/mutillidae/set-up-database.php"
}

apt_update
install_git 
install_apache 
tweak_apache_dir_conf
install_mysql  
install_php
install_phpinfo
test_php
pull_latest_mutillidae
install_mutillidae
show_message
