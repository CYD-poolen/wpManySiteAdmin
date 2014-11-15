#!/bin/bash

if [[ $# != 2 || $S1 == "-h" || $S1 == "--help" ]]
then
	echo "Usage: "
	echo "	$0 userName fullURL"
	exit 1
fi

# cd to script dir
cd "$(dirname $0)"

userName=$1
fullURL=$2
userPassword=$(echo -n $RANDOM | md5sum | awk {'print $1'})
wpAdminPassword=$(echo -n $RANDOM | md5sum | awk {'print $1'})
userDir=/srv/$fullURL
installDir=$userDir/wordpress

# Create user in Linux and MySQL
useradd -p $(echo $userPassword | openssl passwd -1 -stdin) $userName

echo "Please enter root password for MYSQL"
mysql --user=root -p -e "create database $userName;
CREATE USER '$userName'@localhost IDENTIFIED BY '$userPassword';
GRANT ALL PRIVILEGES ON $userName . * TO '$userName'@'localhost';"
echo ""

# Create folders for socket and WP
mkdir -p $intallDir
mkdir -p $userDir/socket
chown -R $userName:www-data $userDir
chmod -R 750 $userDir
chmod -R g+s $userDir

echo "Installing Wordpress + AD-plugin"
# Install Wordpress + AD plugin using wp-cli
su - $userName -c "cd $installDir 
wp core download --locale=sv_SE
wp core config --dbname=$userName --dbuser=$userName --dbpass=$userPassword --locale=sv_SE
wp core install --url=$fullURL --title='$userName website' --admin_user=cydadmin --admin_password=$wpAdminPassword --admin_email=admin@cyd.liu.se
wp plugin install active-directory-integration
wp plugin activate active-directory-integration"
echo ""

# Create config files for nginx and uwsgi
./nginx.bash $userName $fullURL
./php5-fpm.bash $userName $fullURL

echo ""
echo "This is the password for MySQL- and system user $userName:"
echo $userPassword
echo ""

echo "This is the password for WP-administrator-user cydadmin:"
echo $wpAdminPassword
echo ""

