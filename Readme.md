# Ansible
---

## Install Ansible

1. Устанавливаем Homebrew (https://brew.sh/index_ru)
2. Устанавливаем Ansible:
```bash
brew install ansible
```
3. Проверяем работоспособность Ansible:
```bash
ansible --version
```

## Install Vagrant

1. Устанавливаем VirtualBox (https://download.virtualbox.org/virtualbox/6.0.8/VirtualBox-6.0.8-130520-OSX.dmg)
2. Устанавливаем Vagrant:
```bash
brew cask install vagrant
```
3. Проверяем работоспособность Vagrant:
```bash
vagrant --version
```

## Configure Environment

Создаём рабочую директорию:
```bash
mkdir Ansible
cd Ansible/
```

Создаём директорию для данного задания:
```bash
mkdir 1-setup
cd 1-setup/
```

Создаём директорию для хранения файлов Ansible:
```bash
mkdir playbooks
cd playbooks/
```

Инициализируем виртуальную машину с Ubuntu:
```bash
vagrant init ubuntu/trusty64
```

Запускаем виртуальную машину с Ubuntu:
```bash
vagrant up
```

Проверяем доступность виртуальной машины по SSH:
```bash
vagrant ssh
exit
```

Изучаем конфигурацию созданной виртуальной машины:
```bash
vagrant ssh-config
```

Проверяем доступность виртуальной машины по SSH напрямую:
```bash
ssh $(vagrant ssh-config | grep "User " | awk '{print $2}')@$(vagrant ssh-config | grep HostName | awk '{print $2}') -p $(vagrant ssh-config | grep Port | awk '{print $2}') -i $(vagrant ssh-config | grep IdentityFile | awk '{print $2}')
exit
```

Создаём файл со списком управляемых виртуальных машин:
```bash
vi hosts
```

```ini
testserver ansible_host=127.0.0.1 ansible_port=2222 ansible_user=vagrant ansible_private_key_file=.vagrant/machines/default/virtualbox/private_key
```

Проверяем доступность виртуальной машины для Ansible:
```bash
ansible testserver -i hosts -m ping
```

Создаём файл конфигурации Ansible:
```bash
vi ansible.cfg
```

```ini
[defaults]
inventory = hosts
remote_user = vagrant
private_key_file = .vagrant/machines/default/virtualbox/private_key
host_key_checking = False
```

Упрощаем файл со списком управляемых виртуальных машин:
```bash
vi hosts
```

```ini
testserver ansible_host=127.0.0.1 ansible_port=2222
```

Проверяем доступность виртуальной машины для Ansible:
```bash
ansible testserver -m ping
```

## Use base Ansible comands

Выполняем команду на виртуальной машине с помощью Ansible:
```bash
ansible testserver -m command -a uptime
```

Выполняем команду на виртуальной машине с помощью Ansible в упрощённой форме:
```bash
ansible testserver -a uptime
```

Выполняем команду с аргументами на виртуальной машине с помощью Ansible:
```bash
ansible testserver -a "tail /var/log/dmesg"
```

Выполняем команду в привилегированном режиме на виртуальной машине с помощью Ansible:
```bash
ansible testserver -b -a "tail /var/log/syslog"
```

Установим на виртуальную машину Nginx с помощью Ansible:
```bash
ansible testserver -b -m apt -a name=nginx
```

Перезапустим Nginx на виртуальной машине с помощью Ansible:
```bash
ansible testserver -b -m service -a "name=nginx state=restarted"
```

#### Задание:
Создать виртуальную машину с Ubuntu и с помощью Ansible установить на неё Docker, Docker Compose и и запустить приложение BookApp.

## Configure Specific Environment

Настраиваем Vagrant для предоставления доступа к Nginx:
```bash
vi Vagrantfile
```

```ini
...
VAGRANTFILE_API_VERSION = "2"
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.network "forwarded_port", guest: 443, host: 8443
...
```

Перезапускаем Vagrant для вступления настроек в силу:
```bash
vagrant reload
```

Устанавливаем программу Cowsay:
```bash
brew install cowsay
```

## Use Scenarios

Создаём файл сценария настройки Nginx без TLS:
```bash
vi web-notls.yml
```

```yaml
- name: Configure webserver with nginx
  hosts: webservers
  become: True
  tasks:
    - name: install nginx
      apt: name=nginx update_cache=yes

    - name: copy nginx config file
      copy: src=files/nginx.conf dest=/etc/nginx/sites-available/default

    - name: enable configuration
      file: >
        dest=/etc/nginx/sites-enabled/default
        src=/etc/nginx/sites-available/default
        state=link

    - name: copy index.html
      template: src=templates/index.html.j2 dest=/usr/share/nginx/html/index.html
        mode=0644

    - name: restart nginx
      service: name=nginx state=restarted
```

Создаём директорию для хранения файлов, используемых в сценариях:
```bash
mkdir files
```

Создаём файл конфигурации Nginx:
```bash
vi files/nginx.conf
```

```conf
server {
    listen 80 default_server;
    listen [::]:80 default_server ipv6only=on;
    root /usr/share/nginx/html;
    index index.html index.htm;

    server_name localhost;

    location / {
       try_files $uri $uri/ =404;
    }
}
```

Создаём директорию для хранения шаблонов, используемых в сценариях:
```bash
mkdir templates
```

Создаём шаблон статической страницы для отображения в браузере:
```bash
vi templates/index.html.j2
```

```html
<html>
  <head>
    <title>Welcome to ansible</title>
  </head>
  <body>
    <h1>nginx, configured by Ansible</h1>
    <p>If you can see this, Ansible successfully installed nginx.</p>

    <p>Running on {{ inventory_hostname }}</p>
  </body>
</html>
```

Создаём группу "webservers" для нашей виртуальной машины для демонстрации управления группами хостов вместо конкретных виртуальных машин:
```bash
vi hosts
```

```ini
[webservers]
testserver ansible_host=127.0.0.1 ansible_port=2222
```

Проверяем доступность серверов созданной группы хостов:
```bash
ansible webservers -m ping
```

Выполняем сценарий установки и настройки Nginx на созданную группу хостов без TLS:
```bash
ansible-playbook web-notls.yml
```

Открываем в браузере URL установленного и сконфигурированного Nginx - http://localhost:8080.

Отключаем вывод коров при запуске сценариев:
```bash
vi ansible.cfg
```

```ini
[defaults]
nocows=1
...
```

Добавляем в сценарий указание на исполняемый файл Ansible для обеспечения возможности запуска его как обычного скрипта:
```bash
vi web-notls.yml
```

```yaml
#!/usr/bin/env ansible-playbook
...
```

Делаем файл сценария исполняемым и запускаем его из командной строки:
```bash
chmod +x web-notls.yml
./web-notls.yml
```

Используем утилиту ansible-doc для получения информации о модуле "service":
```bash
ansible-doc service
```

## Use Variables and Handlers

Создаём сценарий для установки и настройки Nginx с использованием протокола TLS:
```bash
vi web-tls.yml
```

```yaml
- name: Configure webserver with nginx and tls
  hosts: webservers
  become: True
  vars:
    key_file: /etc/nginx/ssl/nginx.key
    cert_file: /etc/nginx/ssl/nginx.crt
    conf_file: /etc/nginx/sites-available/default
    server_name: localhost
  tasks:
    - name: install nginx
      apt: name=nginx update_cache=yes cache_valid_time=3600

    - name: create directories for ssl certificates
      file: path=/etc/nginx/ssl state=directory

    - name: copy TLS key
      copy: src=files/nginx.key dest={{ key_file }} owner=root mode=0600
      notify: restart nginx

    - name: copy TLS certificate
      copy: src=files/nginx.crt dest={{ cert_file }}
      notify: restart nginx

    - name: copy nginx config file
      template: src=templates/nginx.conf.j2 dest={{ conf_file }}
      notify: restart nginx

    - name: enable configuration
      file: >
        dest=/etc/nginx/sites-enabled/default
        src={{ conf_file }}
        state=link
      notify: restart nginx

    - name: copy index.html
      template: src=templates/index.html.j2 dest=/usr/share/nginx/html/index.html
        mode=0644

  handlers:
    - name: restart nginx
      service: name=nginx state=restarted
```

Создаём сертификат и ключ для обеспечения работы протокола TLS:
```bash
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -subj /CN=localhost -keyout files/nginx.key -out files/nginx.crt
```

Создаём сценарий для установки и настройки Nginx с использованием протокола TLS:
```bash
vi templates/nginx.conf.j2
```

```conf
server {
    listen 80 default_server;
    listen [::]:80 default_server ipv6only=on;

    listen 443 ssl;

    root /usr/share/nginx/html;
    index index.html index.htm;

    server_name {{ server_name }};
    ssl_certificate {{ cert_file }};
    ssl_certificate_key {{ key_file }};

    location / {
       try_files $uri $uri/ =404;
    }
}
```

Выполняем сценарий установки и настройки Nginx с использованием протокола TLS:
```bash
ansible-playbook web-tls.yml
```

Открываем в браузере URL установленного и сконфигурированного Nginx с использованием протокола TLS - https://localhost:8443.

#### Задание:
Создать виртуальную машину с Ubuntu и на Ansible написать скрипт автоматизации для развёртывания рабочего экземпляра приложения BookApp с помощью Docker Compose.