# Magento 2

Magento is leading enterprise-class e-commerce platform built on open-source technology combining powerful features with flexibility and user-friendly interface.

With features like Engaging Shopping Experiences, Flexible Modular Architecture and Enterprise-grade Scalability and Performance Magento is a platform of choice for most online merchants.

In this tutorial, we will show you how to install Magento 2 on an Ubuntu 18.04 VPS with MySQL, PHP-FPM 7.2, Varnish as a full page cache, Nginx as SSL termination and Redis for session storage and page caching.

### Update system
Nginx pronounced “engine x” is a free, open-source, high-performance HTTP and reverse proxy server responsible for handling the load of some of the largest sites on the Internet. Compared to Apache, Nginx can handle a much large number of concurrent connections and has a smaller memory footprint per connection.
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install nginx unzip -y
sudo ufw allow 'Nginx Full'
```

### Installing Nginx
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


### Install MariaDB, create database and user
```bash
sudo apt -y install mariadb-server mariadb-client
mysql_secure_installation (answer yes for questions)
sudo mysql
create database magentodb;
create user magento@localhost identified by 'strong_password';
grant all privileges on magentodb.* to magento@localhost identified by 'strong_password';
flush privileges;
exit
```
### Create system user
```bash
sudo useradd -m -U -r -d /opt/magento magento
```
### Installing and Configuring PHP
```bash
sudo apt install php7.2-common php7.2-cli php7.2-fpm php7.2-opcache php7.2-gd php7.2-mysql php7.2-curl php7.2-intl php7.2-xsl php7.2-mbstring php7.2-zip php7.2-bcmath php7.2-soap
```
#### Set the required and recommended PHP options by editing the php.ini file with sed:
```bash
sudo sed -i "s/;cgi.fix_pathinfo=1*/cgi.fix_pathinfo=0/" /etc/php/7.2/fpm/php.ini
sudo sed -i "s/memory_limit = .*/memory_limit = 1024M/" /etc/php/7.2/fpm/php.ini
sudo sed -i "s/upload_max_filesize = .*/upload_max_filesize = 256M/" /etc/php/7.2/fpm/php.ini
sudo sed -i "s/zlib.output_compression = .*/zlib.output_compression = on/" /etc/php/7.2/fpm/php.ini
sudo sed -i "s/max_execution_time = .*/max_execution_time = 18000/" /etc/php/7.2/fpm/php.ini
sudo sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.2/fpm/php.ini
sudo sed -i "s/;opcache.save_comments.*/opcache.save_comments = 1/" /etc/php/7.2/fpm/php.ini
```
### Create a FPM pool for the magento user.
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
```bash
systemctl restart php7.2-fpm
```
```bash
ls -al /var/run/php/php7.2-fpm-magento.sock
```
### Installing Composer
Composer is a dependency manager for PHP and we will be using it to download the Magento core and install all necessary Magento components. To install composer globally, download the Composer installer with curl and move the file to the /usr/local/bin directory:
```bash
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
```
## Installing Magento
There are several ways to install Magento 2. Avoid installing Magento from the Github repository because that version is intended for development and not for production installations.

To be able to access to the Magento 2 code repository you'll need to generate authentication keys. If you don’t have a Magento Marketplace account, you can create one here.
```bash
sudo su - magento
composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition /opt/magento/public_html
```
You'll be prompted to enter the access keys, copy the keys from your Magento marketplace account and store them in the auth.json file, so later when updating your installation you don’t have to add the same keys again.
```bash
cd ~/public_html
php bin/magento setup:install --base-url=https://example.com/ --base-url-secure=https://example.com/ --admin-firstname="John" --admin-lastname="Doe" --admin-email="john@example.com" --admin-user="john" --admin-password="strong_password" --db-name="magentodb" --db-host="localhost" --db-user="magento" --currency=USD --timezone=America/Chicago --use-rewrites=1 --db-password="strong_password"
```
### Creating Magento crontab
```bash
php ~/public_html/bin/magento cron:install
crontab -l
```
### Secure Nginx with Let's Encrypt
```bash
sudo apt update
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

To avoid duplicating code create the following two snippets which we're going to include in all our Nginx server block files.
Open your text editor and create the first snippet, letsencrypt.conf:
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
```

You can now run Certbot with the webroot plugin and obtain the SSL certificate files by issuing:
```bash
sudo certbot certonly --agree-tos --email admin@example.com --webroot -w /var/lib/letsencrypt/ -d example.com -d www.example.com
```
### Configuring Nginx
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
```bash
sudo nginx -t
```
```bash
sudo systemctl restart nginx
```
### Verifying the Installation
Open your browser, type your domain and assuming the installation is successful!
