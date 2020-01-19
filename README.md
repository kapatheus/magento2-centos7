![Image](https://github.com/kapatheus/magento2/blob/master/magento-2.jpg)
# Magento 2 + Centos 7 + Nginx + Lets's Encrypt SSL + MariaDB + Varnish + Redis

Magento is leading enterprise-class e-commerce platform built on open-source technology combining powerful features with flexibility and user-friendly interface.

With features like Engaging Shopping Experiences, Flexible Modular Architecture and Enterprise-grade Scalability and Performance Magento is a platform of choice for most online merchants.

In this tutorial we need these:
- CentOS 7 server, according to the official Magento 2 system requirements you need at least 2G of RAM. If you are using a server with less than 2GB of RAM, you should create a swap file.
- Logged in as a user account with sudo privileges.
- A domain name pointing to your public server IP. In this tutorial, we will use example.com.

## Update the system packages and install the unzip utility
```bash
sudo yum update -y
sudo yum install nano -y
```

## Installing Nginx
Nginx pronounced “engine x” is a free, open-source, high-performance HTTP and reverse proxy server responsible for handling the load of some of the largest sites on the Internet. Nginx can be used as a standalone web server, and as a reverse proxy for Apache and other web servers. Compared to Apache, Nginx can handle a much large number of concurrent connections and has a smaller memory footprint per connection.

Nginx is not available in the default CentOS 7 repository so we will use the EPEL repositories. To add the EPEL repository to your system, use the following command:
```bash
sudo yum install epel-release -y
```

Now that the EPEL repository is enabled, install the Nginx package with:
```bash
sudo yum install nginx -y
```

Once it is installed, start and enable the Nginx service by typing:
```bash
sudo systemctl start nginx
sudo systemctl enable nginx
```

## Set Up Nginx Server Blocks
Nginx Server Blocks allows you to run more than one website on a single machine. With Server Blocks, you can specify the site document root (the directory which contains the website files), create a separate security policy for each site, use different SSL certificates for each site and much more.

So let's create the root directory for our domain example.com:
```bash
sudo mkdir -p /var/www/example.com/public_html
```

For testing purposes we will create an index.html file inside the domain's document root directory.
Open your editor and create the demo file:
```bash
sudo nano /var/www/example.com/public_html/index.html
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

We are running the commands as sudo user and the newly created files and directories are owned by the root user.
To avoid any permission issues we can change the ownership of the domain document root directory to the Nginx user (nginx):
```bash
sudo chown -R nginx: /var/www/example.com
```

### Create a Server Block
Nginx server block configuration files must end with .conf and are stored in /etc/nginx/conf.d directory.
Open your editor of choice and create a server block configuration file for example.com.

Create the following server block file:
```bash
sudo nano /etc/nginx/conf.d/example.com.conf
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

Save the file and test the Nginx configuration for correct syntax:
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

![Image](https://github.com/kapatheus/magento2/blob/master/nginx-welcome-page.jpg)


## Secure Nginx with Let's Encrypt
Let's Encrypt is a free and open certificate authority developed by the Internet Security Research Group (ISRG). Certificates issued by Let's Encrypt are trusted by almost all browsers today.

### Install Certbot
Certbot is an easy to use tool that can automate the tasks for obtaining and renewing Let’s Encrypt SSL certificates and configuring web servers.

To install the certbot package form the EPEL repository run:
```bash
sudo yum install certbot -y
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
sudo mkdir -p /var/lib/letsencrypt/.well-known
sudo chgrp nginx /var/lib/letsencrypt
sudo chmod g+s /var/lib/letsencrypt
```

To avoid duplicating code create the following two snippets which we're going to include in all our Nginx server block files:
```bash
sudo mkdir /etc/nginx/snippets
```
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
```

The snippet above includes the chippers recommended by Mozilla, enables OCSP Stapling, HTTP Strict Transport Security (HSTS) and enforces few security‑focused HTTP headers.

Once the snippets are created, open the domain server block and include the letsencrypt.conf snippet as shown below:
```bash
sudo nano /etc/nginx/conf.d/example.com.conf
```
```bash
server {
  listen 80;
  server_name example.com www.example.com;

  include snippets/letsencrypt.conf;
}
```

Restart the Nginx service for the changes to take effect:
```bash
sudo systemctl reload nginx
```

You can now run Certbot with the webroot plugin and obtain the SSL certificate files for your domain by issuing:
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
   Your cert will expire on 2018-06-11. To obtain a new or tweaked
   version of this certificate in the future, simply run certbot
   again. To non-interactively renew *all* of your certificates, run
   "certbot renew"
 - If you like Certbot, please consider supporting our work by:

   Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
   Donating to EFF:                    https://eff.org/donate-le
```

Now that you have the certificate files, you can edit your domain server block as follows:
```bash
sudo nano /etc/nginx/conf.d/example.com.conf
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
With the configuration above we are forcing HTTPS and redirecting the www to non www version.

Finally, reload the Nginx service for changes to take effect:
```bash
sudo systemctl reload nginx
```

#### Auto-renewing Let's Encrypt SSL certificate
Let's Encrypt's certificates are valid for 90 days. To automatically renew the certificates before they expire, we will create a cronjob which will run twice a day and will automatically renew any certificate 30 days before its expiration.

Run the crontab command to create a new cronjob:
```bash
sudo nano crontab -e
```
```bash
0 */12 * * * root test -x /usr/bin/certbot -a \! -d /run/systemd/system && perl -e 'sleep int(rand(3600))' && certbot -q renew --renew-hook "systemctl reload nginx"
```

Save and close the file.

To test the renewal process, you can use the certbot command followed by the --dry-run switch:
```bash
sudo certbot renew --dry-run
```
If there are no errors, it means that the test renewal process was successful.

## Install MariaDB
MariaDB is an open-source relational database management system, backward compatible, binary drop-in replacement of MySQL. It is developed by some of the original developers of the MySQL and by many people in the community. With the release of CentOS 7, MySQL was replaced with MariaDB as the default database system.

At the time of writing this article, the latest version of MariaDB is version 10.4. If you need to install any other version of MariaDB, head over to the MariaDB repositories page, and generate a repository file for a specific MariaDB version.

To install MariaDB 10.4 on CentOS 7, follow these steps.

The first step is to Enable the MariaDB repository. Create a repository file named MariaDB.repo and add the following content:
```bash
sudo nano /etc/yum.repos.d/MariaDB.repo
```
```bash
# MariaDB 10.4 CentOS repository list - created 2020-01-18 11:05 UTC
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.4/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
```

Install the MariaDB server and client packages using yum, same as other CentOS package:
```bash
sudo yum install MariaDB-server MariaDB-client -y
```

Yum may prompt you to import the MariaDB GPG key:
```bash
Retrieving key from https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
Importing GPG key 0x1BB943DB:
 Userid     : "MariaDB Package Signing Key "
 Fingerprint: 1993 69e5 404b d5fc 7d2f e43b cbcb 082a 1bb9 43db
 From       : https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
```
Type y and hit Enter.

Once the installation is complete, enable MariaDB to start on boot and start the service:
```bash
sudo systemctl enable mariadb
sudo systemctl start mariadb
```

The last step is to run the mysql_secure_installation script which will perform several security related tasks:
```bash
sudo mysql_secure_installation
```
The script will prompt you to set up the root user password, remove the anonymous user, restrict root user access to the local machine, and remove the test database.

All steps are explained in detail and it is recommended to answer Y (yes) to all questions.

### Creating MySQL database and user
Login to the MySQL shell:
```bash
mysql -u root -p
```

And run the following commands to create a new database and user and grant privileges to that user over the newly created database:
```bash
CREATE DATABASE magento;
GRANT ALL ON magento.* TO magento@localhost IDENTIFIED BY 'P4ssvv0rD';
exit
```

### Installing and Configuring PHP

## Enabling Remi repository
PHP 7.x packages are available in several different repositories. We'll use the Remi repository which provides newer versions of various software packages including PHP.

The Remi repository depends on the EPEL repository. Run the following commands to enable both EPEL and Remi repositories:
```bash
sudo yum install epel-release yum-utils -y
sudo yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y
```

Installing PHP 7.3 Magento 2.3.3 adds support for PHP 7.3.

Start by enabling the PHP 7.3 Remi repository:
```bash
sudo yum-config-manager --enable remi-php73
```

Install all required PHP extensions with the following command:
```bash
sudo yum install php php-common php-cli php-curl php-mysql php-opcache php-xml php-mcrypt php-gd php-soap php-redis php-bcmath php-intl php-mbstring php-json php-iconv php-fpm php-zip -y
```

Once the installation is complete, set the required and recommended PHP options by editing the php.ini file with sed:
```bash
sudo sed -i "s/;cgi.fix_pathinfo=1*/cgi.fix_pathinfo=0/" /etc/php.ini
sudo sed -i "s/memory_limit = .*/memory_limit = 1024MM/" /etc/php.ini
sudo sed -i "s/upload_max_filesize = .*/upload_max_filesize = 256M/" /etc/php.ini
sudo sed -i "s/zlib.output_compression = .*/zlib.output_compression = on/" /etc/php.ini
sudo sed -i "s/max_execution_time = .*/max_execution_time = 18000/" /etc/php.ini
sudo sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php.ini
sudo sed -i "s/;opcache.save_comments.*/opcache.save_comments = 1/" /etc/php.d/10-opcache.ini
```

### Installing Composer
Composer is a dependency manager for PHP which is used for installing, updating and managing libraries.

To install composer globally, download the Composer installer with curl and move the file to the /usr/local/bin directory:
```bash
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
```

### Create a new System User
Create a new user and group, which will run our Magento installation, for simplicity we will name our user magento:
```bash
sudo useradd -m -U -r -d /opt/magento magento
```

Add the nginx user to the magento group and change the /opt/magento directory permissions so that the Nginx can access our Magento installation:
```bash
sudo usermod -a -G magento nginx
sudo chmod 750 /opt/magento
```

### Configure PHP FPM
Next, we need to configure PHP and create an FPM pool for our magento user.
Open your text editor and create the following file:
```bash
sudo nano /etc/php-fpm.d/magento.conf
```
```bash
[magento]
user = magento
group = nginx
listen.owner = magento
listen.group = nginx
listen = /run/php-fpm/magento.sock
pm = ondemand
pm.max_children =  50
pm.process_idle_timeout = 10s
pm.max_requests = 500
chdir = /
```

Save the file and restart the PHP FPM service for changes to take effect:
```bash
sudo systemctl restart php-fpm
```

## Installing Magento
There are several ways to install Magento. Avoid installing Magento from the Github repository because that version is intended for development and not for production installations. In this tutorial, we will install Magento from their repositories using composer.

Switch over to the user magento:
```bash
sudo su - magento
```

Start the installation by downloading magento files to the /opt/magento/public_html directory:
```bash
composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition /opt/magento/public_html
```

During the project creation, the composer will ask you to enter the access keys, copy the keys from your Magento marketplace account and store them in the auth.json file, so later when updating your installation you don't have to add the same keys again.
```bash
Authentication required (repo.magento.com):
      Username: e758ec1745d190520ca246e4e832e12c
      Password:
Do you want to store credentials for repo.magento.com in /opt/magento/.config/composer/auth.json ? [Yn]
```
The command above will fetch all required PHP packages. The process may take a few minutes and if it is successful the end of the output should look like the following:
```bash
Writing lock file
Generating autoload files
```

Once the project is created we can start the installation. We can install Magento either by using the command line or using the web Setup Wizard. In this tutorial, we will install Magento using the command line.

We will use the following options to install our Magento store:

Base and Base secure URLs are set to https://example.com, change it with your domain.
Magento administrator:
John Doe as first and last name.
john@example.com as email.
john as username and j0hnP4ssvv0rD as a password.
Database name magento, username magento, password P4ssvv0rD, and the database server is on the same host as the web server.
en_US, US English as default language.
USD dollars as default currency.
America/Chicago as a time zone.

Change to the Magento ~/public_html directory:
```bash
cd ~/public_html
```

Run the following command to start the installation:
```bash
php bin/magento setup:install --base-url=https://example.com/ --base-url-secure=https://example.com/ --admin-firstname="John" --admin-lastname="Doe" --admin-email="john@example.com" --admin-user="john" --admin-password="j0hnP4ssvv0rD" --db-name="magento" --db-host="localhost" --db-user="magento" --currency=USD --timezone=America/Chicago --use-rewrites=1 --db-password="P4ssvv0rD"
```

If the installation is successful you will be presented with a message that contains the URI to the Magento admin dashboard.
```bash
[Progress: 485 / 485]
[SUCCESS]: Magento installation complete.
[SUCCESS]: Magento Admin URI: /admin_1csalp
Nothing to import.
```

### Creating Magento crontab
Magento uses cron jobs to schedule tasks like re-indexing, notifications, sitemaps, emails and more.
To create the Magento crontab run the following command as magento user:
```bash
php ~/public_html/bin/magento cron:install
```
Crontab has been generated and saved

We can verify that the crontab is installed by running:
```bash
crontab -l
```
```bash
#~ MAGENTO START adc062915d7b30804a2b340095af072d
* * * * * /usr/bin/php /opt/magento/public_html/bin/magento cron:run 2>&1 | grep -v "Ran jobs by schedule" >> /opt/magento/public_html/var/log/magento.cron.log
* * * * * /usr/bin/php /opt/magento/public_html/update/cron.php >> /opt/magento/public_html/var/log/update.cron.log
* * * * * /usr/bin/php /opt/magento/public_html/bin/magento setup:cron:run >> /opt/magento/public_html/var/log/setup.cron.log
#~ MAGENTO END adc062915d7b30804a2b340095af072d
```
### Configuring Nginx
Now we only need to create a new server block for our Magento installation. We are going to include the default Nginx configuration shipped with magento:
```bash
sudo nano /etc/nginx/conf.d/example.com.conf
```
```bash
upstream fastcgi_backend {
  server   unix:/run/php-fpm/magento.sock;
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

    return 301 https://example.com$request_uri;
}

server {
    listen 443 ssl http2;
    server_name example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem;
    include snippets/ssl.conf;

    set $MAGE_ROOT /opt/magento/public_html;
    set $MAGE_MODE developer; # or production

    access_log /var/log/nginx/example.com-access.log;
    error_log /var/log/nginx/example.com-error.log;

    include /opt/magento/public_html/nginx.conf.sample;
}
```
Don’t forget to replace example.com with your Magento domain and set the correct path to the SSL certificate files. The snippets used in this configuration are created in this guide.

Reload the Nginx service for changes to take effect:
```bash
sudo systemctl reload nginx
```

## Verifying the Installation
Open your browser, type your domain and assuming the installation is successful, a screen similar to the following will appear:
You can now go to the Magento Admin URI, log in as the admin user and start customizing your new Magento installation.


# Varnish
The page speed or loading time is crucial to the success of your online store. The loading time is the total amount of time it takes the content on a specific page to load. The longer the loading time is, the lower the conversion rate. It is also one of the most important factors that Google considers to determine the search engine rankings.

Varnish does not support SSL, so we need to use another service as an SSL Termination Proxy, in our case that will be Nginx.

When a visitor opens your website over HTTPS on port 443 the request will be handled by Nginx which works as a proxy and passes the request to Varnish (on port 80). Varnish checks if the request is cached or not. If it is cached, Varnish will return the cached data to Nginx without a request to the Magento application. If the request is not cached Varnish will pass the request to Nginx on port 8080 which will pull data from Magento and Varnish will cache the response.

If a visitor opens your website without SSL on port 80 then he will be redirected to the HTTPS on port 443 URL by Varnish.

## Configuring Nginx
We need to edit the Nginx server block which we created to handle SSL/TLS termination and as a back-end for Varnish.

```bash
sudo nano /etc/nginx/conf.d/example.com.conf
```
```bash
upstream fastcgi_backend {
  server   unix:/run/php-fpm/magento.sock;
}

server {
    listen 127.0.0.1:8080;
    server_name example.com www.example.com;

    set $MAGE_ROOT /opt/magento/public_html;
    set $MAGE_MODE developer; # or production

    include snippets/letsencrypt.conf;
    include /opt/magento/public_html/nginx.conf.sample;
}

server {
    listen 443 ssl http2;
    server_name www.example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem;
    include snippets/ssl.conf;

    return 301 https://example.com$request_uri;
}

server {
    listen 443 ssl http2;
    server_name example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem;
    include snippets/ssl.conf;

    access_log /var/log/nginx/example.com-access.log;
    error_log /var/log/nginx/example.com-error.log;

    location / {
        proxy_pass http://127.0.0.1;
        proxy_set_header Host $http_host;
        proxy_set_header X-Forwarded-Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Port 443;
    }
}
```

We also need to remove the default Nginx server block from the nginx.conf file. Comment or delete the following lines:
```bash
sudo nano /etc/nginx/nginx.conf
```
```bash
...
# server {
#     listen       80 default_server;
#     listen       [::]:80 default_server;
#     server_name  _;
#     root         /usr/share/nginx/html;
#
#     # Load configuration files for the default server block.
#     include /etc/nginx/default.d/*.conf;
#
#     location / {
#     }
#
#     error_page 404 /404.html;
#        location = /40x.html {
#     }
#
#     error_page 500 502 503 504 /50x.html;
#         location = /50x.html {
#     }
# }
...
```

Reload the Nginx service for changes to take effect:
```bash
sudo systemctl reload nginx
```

### Installing and Configuring Varnish 
Varnish is a fast reverse-proxy HTTP accelerator that will sit in front of our web server and it will be used as a Full Page Cache solution for our Magento installation.

Install Varnish via yum with the following command:
```bash
sudo yum install varnish -y
```

To configure Magento to use Varnish run:
```bash
php /opt/magento/public_html/bin/magento config:set --scope=default --scope-code=0 system/full_page_cache/caching_application 2
```

Next, we need to generate a Varnish configuration file:
```bash
sudo php /opt/magento/public_html/bin/magento varnish:vcl:generate > /etc/varnish/default.vcl
```
The command above needs to be run as a root or user with sudo privileges and it will create a file /etc/varnish/default.vcl using the default values which are localhost as back-end host and port 8080 as back-end port.

The default configuration comes with a wrong URL for the health check file. Open the default.vcl file and remove the /pub part from the line
```bash
sudo nano /etc/varnish/default.vcl
```
```bash
...
.probe = {
     # .url = "/pub/health_check.php";
     .url = "/health_check.php";
     .timeout = 2s;
     .interval = 5s;
     .window = 10;
     .threshold = 5;
}
...
```

By default, Varnish listens on port 6081, and we need to change it to 80:
```bash
sudo nano /etc/varnish/varnish.params
```
```bash
VARNISH_LISTEN_PORT=80
```

Once you are done with the modifications, start and enable the Varnish service:
```bash
sudo systemctl enable varnish
sudo systemctl start varnish
```
You can use the varnishlog tool to view real-time web requests and for debugging Varnish.
