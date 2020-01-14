sudo apt-get update
sudo apt install nginx
sudo apt install mysql-server
sudo apt-get install software-properties-common
sudo add-apt-repository ppa:ondrej/php
sudo apt-get update
sudo apt-get install php7.1-fpm php7.1-cli php7.1-common php7.1-json php7.1-opcache php7.1-mysql php7.1-mbstring php7.1-mcrypt php7.1-zip php7.1-fpm php7.1-gd php7.1-curl php7.1-soap php7.1-intl php7.1-simplexml php7.1-bcmath
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/composer
sudo add-apt-repository ppa:git-core/ppa
sudo apt-get update
sudo apt-get install git
#Install varnisn 6.1 for  bionic

curl -L https://packagecloud.io/varnishcache/varnish61/gpgkey | sudo apt-key add -
touch /etc/apt/sources.list.d/varnishcache_varnish61.list
echo "deb https://packagecloud.io/varnishcache/varnish61/ubuntu/ bionic main" >> /etc/apt/sources.list.d/varnishcache_varnish61.list
echo "deb-src https://packagecloud.io/varnishcache/varnish61/ubuntu/ bionic  main" >> /etc/apt/sources.list.d/varnishcache_varnish61.list
sudo apt update
sudo apt install varnish
sudo service nginx stop
echo "upstream fastcgi_backend {
  server   unix:/var/run/php/php7.1-fpm.sock;
}

server {
    server_name yourmagento.com www.yourmagento.com;
    listen 8080;
    set $MAGE_ROOT /var/www/html;

    error_log  /var/www/html/error_log;
    access_log /var/www/html/access_log;

    include /var/www/html/nginx.conf.sample;       
}

##uncomment for use ssl  with varnish

#server {
    #listen 443 ssl http2;
    #listen [::]:443 ssl http2;
    #server_name yourmagento.com www.yourmagento.com;
    #ssl_certificate /var/www/html/ssl/yourmagento.net.chained.crt;
    #ssl_certificate_key /var/www/html/ssl/yourmagento.net.key;
    #ssl_client_certificate /var/www/html/ssl/COMODO_RSA_Certification_Authority.crt;
    #ssl_dhparam /etc/ssl/certs/dhparam.pem;
    #ssl_protocols              TLSv1 TLSv1.1 TLSv1.2;
    #ssl_prefer_server_ciphers on;
    #ssl_ciphers               'ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS';
    #ssl_session_cache    shared:SSL:10m;
    #ssl_session_timeout 24h;

    #location / {
    #    proxy_pass http://127.0.0.1;
    #    proxy_set_header Host $http_host;
    #    proxy_set_header X-Forwarded-Host $http_host;
    #    proxy_set_header X-Real-IP $remote_addr;
    #    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    #    proxy_set_header X-Forwarded-Proto https;
    #    proxy_set_header HTTPS "on";    
    #}

#}" > /etc/nginx/sites-available/default

echo "cahnge port nginx for 8080"
echo "cahnge port varnish sudo varnishd -a :80 -T localhost:6082 -b localhost:8080"