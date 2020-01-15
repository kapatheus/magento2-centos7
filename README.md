# Magento 2

Magento is leading enterprise-class e-commerce platform built on open-source technology combining powerful features with flexibility and user-friendly interface.

With features like Engaging Shopping Experiences, Flexible Modular Architecture and Enterprise-grade Scalability and Performance Magento is a platform of choice for most online merchants.

In this tutorial, we will show you how to install Magento 2 on an Ubuntu 18.04 VPS with MySQL, PHP-FPM 7.2, Varnish as a full page cache, Nginx as SSL termination and Redis for session storage and page caching.

## 1. Install Nginx
Nginx pronounced “engine x” is a free, open-source, high-performance HTTP and reverse proxy server responsible for handling the load of some of the largest sites on the Internet. Compared to Apache, Nginx can handle a much large number of concurrent connections and has a smaller memory footprint per connection.
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install nginx -y
sudo ufw allow 'Nginx Full'
```
## 2. Install MariaDB
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
## Creating System User
```bash
sudo useradd -m -U -r -d /opt/magento magento
```
## Installing and Configuring PHP
```bash
sudo apt install php7.2-common php7.2-cli php7.2-fpm php7.2-opcache php7.2-gd php7.2-mysql php7.2-curl php7.2-intl php7.2-xsl php7.2-mbstring php7.2-zip php7.2-bcmath php7.2-soap
```
## Secure Nginx with Let's Encrypt
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
