# Magento 2

Magento is leading enterprise-class e-commerce platform built on open-source technology combining powerful features with flexibility and user-friendly interface.

With features like Engaging Shopping Experiences, Flexible Modular Architecture and Enterprise-grade Scalability and Performance Magento is a platform of choice for most online merchants.

In this tutorial, we will show you how to install Magento 2 on an Ubuntu 18.04 VPS with MySQL, PHP-FPM 7.2, Varnish as a full page cache, Nginx as SSL termination and Redis for session storage and page caching.

## Update the system packages and install the unzip utility
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install unzip -y
```

## Installing Nginx
Nginx pronounced “engine x” is a free, open-source, high-performance HTTP and reverse proxy server responsible for handling the load of some of the largest sites on the Internet. Nginx can be used as a standalone web server, and as a reverse proxy for Apache and other web servers. Compared to Apache, Nginx can handle a much large number of concurrent connections and has a smaller memory footprint per connection.

Nginx packages are available in the default Ubuntu repositories. The installation is pretty straightforward.
```bash
sudo apt install nginx
```
Once the installation is completed, Nginx service will start automatically. You can check the status of the service with the following command:
```bash
sudo systemctl status nginx
```
The output will look something like this:
```bash
nginx.service - A high performance web server and a reverse proxy server
Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
Active: active (running) since Sun 2018-04-29 06:43:26 UTC; 8s ago
Docs: man:nginx(8)
Process: 3091 ExecStart=/usr/sbin/nginx -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
Process: 3080 ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
Main PID: 3095 (nginx)
Tasks: 2 (limit: 507)
CGroup: /system.slice/nginx.service
           ├─3095 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
           └─3097 nginx: worker process
```
### Configuring firewall
Assuming you are using UFW to manage your firewall, you'll need to open HTTP (80) and HTTPS (443) ports. You can do that by enabling the ‘Nginx Full’ profile which includes rules for both ports:
```bash
sudo ufw allow 'Nginx Full'
```

To verify the status type:
```bash
sudo ufw status
```
The output will look something like the following:
```bash
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
Nginx Full                 ALLOW       Anywhere
22/tcp (v6)                ALLOW       Anywhere (v6)
Nginx Full (v6)            ALLOW       Anywhere (v6)
```
### Test the Installation
You can test your new Nginx installation open http://YOUR_IP in your browser of choice, and you will be presented with the default Nginx landing page as shown on the image below:
<Coming!>

## Set Up Nginx Server Blocks
Nginx Server Blocks allows you to run more than one website on a single machine. With Server Blocks, you can specify the site document root (the directory which contains the website files), create a separate security policy for each site, use different SSL certificates for each site and much more.

Let's create the root directory for our domain example.com:
```bash
sudo mkdir -p /var/www/example.com/public_html
```
For testing purposes we will create an index.html file inside the domain's document root directory.
Open your editor and create the demo file:
```bash
nano /var/www/example.com/public_html/index.html
```
```bash
<!DOCTYPE html>
<html lang="en" dir="ltr">
  <head>
    <meta charset="utf-8">
    <title>Welcome to example.com</title>
  </head>
  <body>
    <h1>Success! example.com home page!</h1>
  </body>
</html>
```
In this guide, we are running the commands as sudo user and the newly created files and directories are owned by the root user.

To avoid any permission issues we can change the ownership of the domain document root directory to the Nginx user (www-data):
```bash
sudo chown -R www-data: /var/www/example.com
```
### Create a Server Block
By default on Ubuntu systems, Nginx server blocks configuration files are stored in /etc/nginx/sites-available directory, which are enabled through symbolic links to the /etc/nginx/sites-enabled/ directory.

Create the following server block file:

```bash
/etc/nginx/sites-available/example.com
```
```bash
server {
    listen 80;
    listen [::]:80;

    root /var/www/example.com/public_html;

    index index.html;

    server_name example.com www.example.com;

    access_log /var/log/nginx/example.com.access.log;
    error_log /var/log/nginx/example.com.error.log;

    location / {
        try_files $uri $uri/ =404;
    }
}
```
You can name the configuration file as you like but usually it is best to use the domain name.

To enable the new server block file we need to create a symbolic link from the file to the sites-enabled directory, which is read by Nginx during startup:
```bash
sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/
```
Test the Nginx configuration for correct syntax:
```bash
sudo nginx -t
```
If there are no errors the output will look like this:
```bash
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```
Restart the Nginx service for the changes to take effect:
```bash
sudo systemctl restart nginx
```
Finally to verify the server block is working as expected open http://example.com in your browser of choice, and you will see something like this: 
![Image](https://raw.githubusercontent.com/kapatheus/magento2/master/nginx-screenshot.jpg)

## Secure Nginx with Let's Encrypt
Let's Encrypt is a free and open certificate authority developed by the Internet Security Research Group (ISRG). Certificates issued by Let's Encrypt are trusted by almost all browsers today.

### Install Certbot
Certbot is a fully featured and easy to use tool that can automate the tasks for obtaining and renewing Let’s Encrypt SSL certificates and configuring web servers to use the certificates. The certbot package is included in the default Ubuntu repositories.

Install the certbot package:
```bash
sudo apt install certbot -y
```
### Generate Strong Dh (Diffie-Hellman) Group
Diffie–Hellman key exchange (DH) is a method of securely exchanging cryptographic keys over an unsecured communication channel. We're going to generate a new set of 2048 bit DH parameters to strengthen the security:
```bash
sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
```
If you like you can change the size up to 4096 bits, but in that case, the generation may take more than 30 minutes depending on the system entropy.

### Obtaining a Let's Encrypt SSL certificate

To obtain an SSL certificate for our domain we're going to use the Webroot plugin that works by creating a temporary file for validating the requested domain in the ${webroot-path}/.well-known/acme-challenge directory. The Let’s Encrypt server makes HTTP requests to the temporary file to validate that the requested domain resolves to the server where certbot runs.

To make it more simple we're going to map all HTTP requests for .well-known/acme-challenge to a single directory, /var/lib/letsencrypt.

The following commands will create the directory and make it writable for the Nginx server.
```bash
mkdir -p /var/lib/letsencrypt/.well-known
chgrp www-data /var/lib/letsencrypt
chmod g+s /var/lib/letsencrypt
```
To avoid duplicating code create the following two snippets which we're going to include in all our Nginx server block files. Create the first snippet, letsencrypt.conf:
```bash
sudo nano /etc/nginx/snippets/letsencrypt.conf
```
```bash
location ^~ /.well-known/acme-challenge/ {
  allow all;
  root /var/lib/letsencrypt/;
  default_type "text/plain";
  try_files $uri =404;
}
```
Create the second snippet ssl.conf which includes the chippers recommended by Mozilla, enables OCSP Stapling, HTTP Strict Transport Security (HSTS) and enforces few security‑focused HTTP headers.
```bash
sudo nano /etc/nginx/snippets/ssl.conf
```
```bash
ssl_dhparam /etc/ssl/certs/dhparam.pem;

ssl_session_timeout 1d;
ssl_session_cache shared:SSL:50m;
ssl_session_tickets off;

ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
ssl_ciphers 'ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS';
ssl_prefer_server_ciphers on;

ssl_stapling on;
ssl_stapling_verify on;
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 30s;

add_header Strict-Transport-Security "max-age=15768000; includeSubdomains; preload";
add_header X-Frame-Options SAMEORIGIN;
add_header X-Content-Type-Options nosniff;
Copy
Once the snippets are created, open the domain server block and include the letsencrypt.conf snippet as shown below:

sudo nano /etc/nginx/sites-available/example.com
/etc/nginx/sites-available/example.com
server {
  listen 80;
  server_name example.com www.example.com;

  include snippets/letsencrypt.conf;
}
```
To enable the new server block file we need to create a symbolic link from the file to the sites-enabled directory, which is read by Nginx during startup:
```bash
sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/
```
Restart the Nginx service for the changes to take effect:
```bash
sudo systemctl restart nginx
```
You can now run Certbot with the webroot plugin and obtain the SSL certificate files by issuing:
```bash
sudo certbot certonly --agree-tos --email admin@example.com --webroot -w /var/lib/letsencrypt/ -d example.com -d www.example.com
```

If the SSL certificate is successfully obtained, certbot will print the following message:
```bash
IMPORTANT NOTES:
 - Congratulations! Your certificate and chain have been saved at:
   /etc/letsencrypt/live/example.com/fullchain.pem
   Your key file has been saved at:
   /etc/letsencrypt/live/example.com/privkey.pem
   Your cert will expire on 2018-07-28. To obtain a new or tweaked
   version of this certificate in the future, simply run certbot
   again. To non-interactively renew *all* of your certificates, run
   "certbot renew"
 - Your account credentials have been saved in your Certbot
   configuration directory at /etc/letsencrypt. You should make a
   secure backup of this folder now. This configuration directory will
   also contain certificates and private keys obtained by Certbot so
   making regular backups of this folder is ideal.
 - If you like Certbot, please consider supporting our work by:

   Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
   Donating to EFF:                    https://eff.org/donate-le
```
Now that you have the certificate files, you can edit your domain server block as follows:
```bash
sudo nano /etc/nginx/sites-available/example.com
```
```bash
server {
    listen 80;
    server_name www.example.com example.com;

    include snippets/letsencrypt.conf;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name www.example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem;
    include snippets/ssl.conf;
    include snippets/letsencrypt.conf;

    return 301 https://example.com$request_uri;
}

server {
    listen 443 ssl http2;
    server_name example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem;
    include snippets/ssl.conf;
    include snippets/letsencrypt.conf;

    # . . . other code
}
```
With the configuration above we are forcing HTTPS and redirecting from www to non www version.

Reload the Nginx service for changes to take effect:
```bash
sudo systemctl reload nginx
```

#### Auto-renewing Let's Encrypt SSL certificate
Let's Encrypt's certificates are valid for 90 days. To automatically renew the certificates before they expire, the certbot package creates a cronjob which runs twice a day and will automatically renew any certificate 30 days before its expiration.


Since we are using the certbot webroot plug-in once the certificate is renewed we also have to reload the nginx service. Append --renew-hook "systemctl reload nginx" to the /etc/cron.d/certbot file so as it looks like this:
```bash
sudo nano /etc/cron.d/certbot
```
```bash
0 */12 * * * root test -x /usr/bin/certbot -a \! -d /run/systemd/system && perl -e 'sleep int(rand(3600))' && certbot -q renew --renew-hook "systemctl reload nginx"
```
To test the renewal process, you can use the certbot --dry-run switch:
```bash
sudo certbot renew --dry-run
```
If there are no errors, it means that the renewal process was successful.

## Install MariaDB
MariaDB is an open-source, multi-threaded relational database management system, backward compatible replacement for MySQL. It is maintained and developed by the MariaDB Foundation including some of the original developers of the MySQL.
```bash
sudo apt -y install mariadb-server mariadb-client
mysql_secure_installation
```
(Answer yes for all questions)
### Creating MySQL database and user
```bash
sudo mysql
create database magentodb;
create user magento@localhost identified by 'strong_password';
grant all privileges on magentodb.* to magento@localhost identified by 'strong_password';
flush privileges;
exit
```
### Creating System User
Create a new user and group, which will be Magento file system owner , for simplicity we will name the user magento:

```bash
sudo useradd -m -U -r -d /opt/magento magento
```

Add the www-data user to the magento group and change the /opt/magento directory permissions so that the Nginx can access the Magento installation:
```bash
sudo usermod -a -G magento www-data
sudo chmod 750 /opt/magento
```

### Installing and Configuring PHP
PHP 7.2 which is the default PHP version in Ubuntu 18.04 is fully supported and recommended for Magento 2.3. Since we will be using Nginx as a web server we'll also install the PHP-FPM package.

Run the following command to install PHP and all required PHP modules:
```bash
sudo apt install php7.2-common php7.2-cli php7.2-fpm php7.2-opcache php7.2-gd php7.2-mysql php7.2-curl php7.2-intl php7.2-xsl php7.2-mbstring php7.2-zip php7.2-bcmath php7.2-soap
```

PHP-FPM service will automatically start after the installation process is complete, you can verify it by printing the service status:
```bash
sudo systemctl status php7.2-fpm
```

The output should indicate that the fpm service is active and running.
```bash
php7.2-fpm.service - The PHP 7.2 FastCGI Process Manager
Loaded: loaded (/lib/systemd/system/php7.2-fpm.service; enabled; vendor preset: enabled)
Active: active (running) since Wed 2018-12-12 15:47:16 UTC; 5s ago
Docs: man:php-fpm7.2(8)
Main PID: 16814 (php-fpm7.2)
Status: "Ready to handle connections"
Tasks: 3 (limit: 505)
CGroup: /system.slice/php7.2-fpm.service
```

### Set the required and recommended PHP options by editing the php.ini file with sed::
```bash
sudo sed -i "s/;cgi.fix_pathinfo=1*/cgi.fix_pathinfo=0/" /etc/php/7.2/fpm/php.ini
sudo sed -i "s/memory_limit = .*/memory_limit = 1024M/" /etc/php/7.2/fpm/php.ini
sudo sed -i "s/upload_max_filesize = .*/upload_max_filesize = 256M/" /etc/php/7.2/fpm/php.ini
sudo sed -i "s/zlib.output_compression = .*/zlib.output_compression = on/" /etc/php/7.2/fpm/php.ini
sudo sed -i "s/max_execution_time = .*/max_execution_time = 18000/" /etc/php/7.2/fpm/php.ini
sudo sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.2/fpm/php.ini
sudo sed -i "s/;opcache.save_comments.*/opcache.save_comments = 1/" /etc/php/7.2/fpm/php.ini
```

Next we need to create a FPM pool for the magento user.
Open your text editor and create the following file:
```bash
sudo nano /etc/php/7.2/fpm/pool.d/magento.conf
```
```bash
[magento]
user = magento
group = www-data
listen.owner = magento
listen.group = www-data
listen = /var/run/php/php7.2-fpm-magento.sock
pm = ondemand
pm.max_children =  50
pm.process_idle_timeout = 10s
pm.max_requests = 500
chdir = /
```

Restart the PHP-FPM service for changes to take effect:
```bash
systemctl restart php7.2-fpm
```

Verify whether the PHP socket was successfully created by running the following ls command:
```bash
ls -al /var/run/php/php7.2-fpm-magento.sock
```

The output should look something like this:
```bash
srw-rw---- 1 magento www-data 0 Dec 12 16:07 /var/run/php/php7.2-fpm-magento.sock=
```

### Installing Composer
Composer is a dependency manager for PHP and we will be using it to download the Magento core and install all necessary Magento components.

To install composer globally, download the Composer installer with curl and move the file to the /usr/local/bin directory:
```bash
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
```

Verify the installation by printing the composer version:
```bash
composer --version
```

The output should look something like this:
```bash
Composer version 1.8.0 2018-12-03 10:31:16
```

## Installing Magento
There are several ways to install Magento 2. Avoid installing Magento from the Github repository because that version is intended for development and not for production installations.
At the time of writing this article, the latest stable version of Magento is version 2.3.0. In this tutorial, we will install Magento from their repositories using composer.

Switch over to the user magento by typing:
```bash
sudo su - magento
```

Start the installation by downloading magento files to the /opt/magento/public_html directory:
```bash
composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition /opt/magento/public_html
```

You'll be prompted to enter the access keys, copy the keys from your Magento marketplace account and store them in the auth.json file, so later when updating your installation you don’t have to add the same keys again.
```bash
    Authentication required (repo.magento.com):
      Username: e758ec1745d190320ca246e4e832e12c
      Password: 
Do you want to store credentials for repo.magento.com in /opt/magento/.config/composer/auth.json ? [Yn] Y
```
The command above will fetch all required PHP packages. The process may take a few minutes and if it is successful the end of the output should look like the following:
```bash
Writing lock file
Generating autoload files
```

Once the project is created we can start the Magento installation. We can install Magento either from the command line or using the web Setup Wizard. In this tutorial, we'll install Magento using the command line.

We will use the following options to install the Magento store:

Base and Base secure URLs are set to https://example.com, change it with your domain.
Magento administrator:
John Doe as first and last name.
john@example.com as email.
john as username and j0hnP4ssvv0rD as password.
Database name magento, username magento, password change-with-strong-password and the database server is on the same host as the web server.
en_US, US English as a default language.
USD dollars as default currency.
America/Chicago as a time zone.
You can find all the installation options here.
Change to the Magento ~/public_html directory:
```bash
cd ~/public_html
```

Run the following command to start the installation:
```bash
php bin/magento setup:install --base-url=https://example.com/ --base-url-secure=https://example.com/ --admin-firstname="John" --admin-lastname="Doe" --admin-email="john@example.com" --admin-user="john" --admin-password="strong_password" --db-name="magentodb" --db-host="localhost" --db-user="magento" --currency=USD --timezone=America/Chicago --use-rewrites=1 --db-password="strong_password"
```
Don't forget to change the password (j0hnP4ssvv0rD) to something more secure.
The process may take a few minutes and once completed you will be presented with a message that contains the URI to the Magento admin dashboard.
```bash
[Progress: 773 / 773]
[SUCCESS]: Magento installation complete.
[SUCCESS]: Magento Admin URI: /admin_13nv5k
Nothing to import.
```

### Creating Magento crontab
Magento uses cron jobs to schedule tasks like re-indexing, notifications, sitemaps, emails and more.
To create the Magento crontab run the following command as magento user:
```bash
php ~/public_html/bin/magento cron:install
```
Crontab has been generated and saved

Verify that the crontab is installed by typing:
```bash
crontab -l
```
```bash
#~ MAGENTO START adc062915d7b30804a2b340095af072d
* * * * * /usr/bin/php7.2 /opt/magento/public_html/bin/magento cron:run 2>&1 | grep -v "Ran jobs by schedule" >> /opt/magento/public_html/var/log/magento.cron.log
* * * * * /usr/bin/php7.2 /opt/magento/public_html/update/cron.php >> /opt/magento/public_html/var/log/update.cron.log
* * * * * /usr/bin/php7.2 /opt/magento/public_html/bin/magento setup:cron:run >> /opt/magento/public_html/var/log/setup.cron.log
#~ MAGENTO END adc062915d7b30804a2b340095af072d
```
### Configuring Nginx
By now, you should already have Nginx with SSL certificate installed on your Ubuntu server.
We are going to include the default Nginx configuration shipped with Magento.
Switch over to your sudo user, open your text editor and create the following file:
```bash
sudo nano /etc/nginx/sites-available/example.com
```
```bash
upstream fastcgi_backend {
  server   unix:/var/run/php/php7.2-fpm-magento.sock;
}

server {
    listen 80;
    server_name example.com www.example.com;

    include snippets/letsencrypt.conf;
    return 301 https://example.com$request_uri;
}

server {
    listen 443 ssl http2;
    server_name www.example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem;
    include snippets/ssl.conf;
    include snippets/letsencrypt.conf;

    return 301 https://example.com$request_uri;
}

server {
    listen 443 ssl http2;
    server_name example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem;
    include snippets/ssl.conf;
    include snippets/letsencrypt.conf;

    set $MAGE_ROOT /opt/magento/public_html;
    set $MAGE_MODE developer; # or production

    access_log /var/log/nginx/example.com-access.log;
    error_log /var/log/nginx/example.com-error.log;

    include /opt/magento/public_html/nginx.conf.sample;
}
```
Don’t forget to replace example.com with your Magento domain and set the correct path to the SSL certificate files. The snippets used in this configuration are created in this guide.
Before restarting the Nginx service make a test to be sure that there are no syntax errors:
```bash
sudo nginx -t
```
If there are no errors the output should look like this:
```bash
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

Finally, restart the Nginx service by typing:
```bash
sudo systemctl restart nginx
```bash

## Verifying the Installation
Open your browser, type your domain and assuming the installation is successful, a screen similar to the following will appear:
You can now go to the Magento Admin URI, log in as the admin user and start customizing your new Magento installation.
