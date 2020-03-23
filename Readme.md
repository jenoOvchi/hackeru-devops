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
1-setup
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

# Use Registry
---

## Configure Specific Environment

Удаляем виртуальную машину Vagrant с Nginx:
```bash
vagrant destroy --force
```

Конфигурируем Vagrantfile для создания 3 локальных виртуальных машин:
```bash
vi Vagrantfile
```

```ruby
VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Использовать один SSH ключ для всех виртуальных машин
  config.ssh.insert_key = false

  config.vm.define "vagrant1" do |vagrant1|
    vagrant1.vm.box = "ubuntu/trusty64"
    vagrant1.vm.network "forwarded_port", guest: 80, host: 8080
    vagrant1.vm.network "forwarded_port", guest: 443, host: 8443
  end

  config.vm.define "vagrant2" do |vagrant2|
    vagrant2.vm.box = "ubuntu/trusty64"
    vagrant2.vm.network "forwarded_port", guest: 80, host: 8081
    vagrant2.vm.network "forwarded_port", guest: 443, host: 8444
  end

  config.vm.define "vagrant3" do |vagrant3|
    vagrant3.vm.box = "ubuntu/trusty64"
    vagrant3.vm.network "forwarded_port", guest: 80, host: 8082
    vagrant3.vm.network "forwarded_port", guest: 443, host: 8445
  end
end
```

Для использования единого SSH ключа указываем незащищённый приватный ключ Vagrant в качестве приватного ключа для подключения в файле конфигурации Ansible:
```bash
vi ansible.cfg
```

```ini
[defaults]
inventory = hosts
remote_user = vagrant
private_key_file = ~/.vagrant.d/insecure_private_key
host_key_checking = False
```

Запускаем 3 виртуальные машины:
```bash
vagrant up
```

Проверяем конфигурацию SSH созданных виртуальных машин для определения SSH портов:
```bash
vagrant ssh-config
```

## Use Static Registry

Модифицируем файл хостов для настройки управления созданными виртуальными машинами:
```bash
vi hosts
```

```ini
vagrant1 ansible_ssh_host=127.0.0.1 ansible_ssh_port=2222
vagrant2 ansible_ssh_host=127.0.0.1 ansible_ssh_port=2200
vagrant3 ansible_ssh_host=127.0.0.1 ansible_ssh_port=2201
```

Проверим доступность второй виртуальной машины:
```bash
ansible vagrant2 -a "ip addr show dev eth0"
```

Оценим синхронность хода часов на всех виртуальных машинах, управляемых Ansible:
```bash
ansible all -a "date"
```

Оценим синхронность хода часов на всех виртуальных машинах, управляемых Ansible, другим способом:
```bash
ansible '*' -a "date"
```

Сгруппируем хосты в файле реестра:
```bash
vi hosts
```

```ini
[vagrant]
vagrant1 ansible_ssh_host=127.0.0.1 ansible_ssh_port=2222
vagrant2 ansible_ssh_host=127.0.0.1 ansible_ssh_port=2200
vagrant3 ansible_ssh_host=127.0.0.1 ansible_ssh_port=2201
```

Оценим синхронность хода часов на всех виртуальных машинах группы "vagrant":
```bash
ansible vagrant -a "date"
```

Перечислим хосты в начале файла и объединим их в группу:
```bash
vi hosts
```

```ini
vagrant1 ansible_ssh_host=127.0.0.1 ansible_ssh_port=2222
vagrant2 ansible_ssh_host=127.0.0.1 ansible_ssh_port=2200
vagrant3 ansible_ssh_host=127.0.0.1 ansible_ssh_port=2201

[vagrant]
vagrant1
vagrant2
vagrant3
```

Оценим синхронность хода часов на всех виртуальных машинах группы "vagrant":
```bash
ansible vagrant -a "date"
```

Составим реестр приложений с учётом специфики сред системы, которую будем настраивать:
```bash
vi hosts
```

```ini
[production]
vagrant1
vagrant2

[staging]
vagrant3

[vagrant]
vagrant1 ansible_ssh_host=127.0.0.1 ansible_ssh_port=2222
vagrant2 ansible_ssh_host=127.0.0.1 ansible_ssh_port=2200
vagrant3 ansible_ssh_host=127.0.0.1 ansible_ssh_port=2201
```

Оценим синхронность хода часов на всех виртуальных машинах группы "vagrant":
```bash
ansible vagrant -a "date"
```

Создадим неработающий файл реестра:
```bash
vi hosts
```

```ini
[vagrant]
127.0.0.1:2222
127.0.0.1:2200
127.0.0.1:2201
```

Проверим, что создаддый реестр не работает:
```bash
ansible vagrant -a "date"
```

Восстановим работающий файл хостов:
```bash
vi hosts
```

```ini
[production]
vagrant1
vagrant2

[staging]
vagrant3

[vagrant]
vagrant1 ansible_ssh_host=127.0.0.1 ansible_ssh_port=2222
vagrant2 ansible_ssh_host=127.0.0.1 ansible_ssh_port=2200
vagrant3 ansible_ssh_host=127.0.0.1 ansible_ssh_port=2201

[web]
vagrant1

[db]
vagrant2
```

Сгруппируем две другие группы реестра:
```bash
vi hosts
```

```ini
...
[application:children]
web
db
...

```

Оценим синхронность хода часов на всех виртуальных машинах группы "django":
```bash
ansible application -a "date"
```

Опишем файл реестра с группировкой последовательных номеров:
```bash
vi hosts
```

```ini
[web]
web[1:20].example.com
```

Опишем файл реестра с группировкой последовательных номеров и ведущим нулём:
```bash
vi hosts
```

```ini
[web]
web[01:20].example.com
```

Опишем файл реестра с группировкой последовательных символов:
```bash
vi hosts
```

```ini
[web]
web-[a-t].example.com
```

Опишем файл реестра с добавлением тегов узлам:
```bash
vi hosts
```

```ini
vagrant1 color=red
vagrant2 color=green
vagrant3 color=blue
```

Опишем файл реестра с добавлением сгруппированных по средам переменных:
```bash
vi hosts
```

```ini
[all:vars]
ntp_server=ntp.ubuntu.com

[production:vars]
db_primary_host=rhodeisland.example.com
db_primary_port=5432
db_replica_host=virginia.example.com
db_name=widget_production
db_user=widgetuser
db_password=pFmMxcyD;Fc6)6
rabbitmq_host=pennsylvania.example.com
rabbitmq_port=5672

[staging:vars]
db_primary_host=quebec.example.com
db_name=widget_staging
db_user=widgetuser
db_password=L@4Ryz8cRUXedj
rabbitmq_host=quebec.example.com
rabbitmq_port=5672

[vagrant:vars]
db_primary_host=vagrant3
db_primary_port=5432
db_primary_port=5432
db_name=widget_vagrant
db_user=widgetuser
db_password=password
rabbitmq_host=vagrant3
rabbitmq_port=5672
```

Создадим директорию для хранения файлов с переменными групп:
```bash
mkdir group_vars
```

Зададим переменные для группы хостов "production":
```bash
vi group_vars/production
```

```ini
db_primary_host=rhodeisland.example.com
db_primary_port=5432
db_replica_host=virginia.example.com
db_name=widget_production
db_user=widgetuser
db_password=pFmMxcyD;Fc6)6
rabbitmq_host=pennsylvania.example.com
rabbitmq_port=5672
```

Зададим переменные для группы хостов "production" в виде словаря YAML:
```bash
vi group_vars/production
```

```yaml
db:
  user: widgetuser
  password: pFmMxcyD;Fc6)6
  name: widget_production
  primary:
    host: rhodeisland.example.com
    port: 5432
  replica:
    host: virginia.example.com
    port: 5432

rabbitmq:
  host: pennsylvania.example.com
  port: 5672
```

Создадим папку для хранения переменных группы хостов "production":
```bash
rm group_vars/production
mkdir group_vars/production
```

Зададим переменные базы данных для группы хостов "production":
```bash
vi group_vars/production/db
```

```yaml
db:
  user: widgetuser
  password: pFmMxcyD;Fc6)6
  name: widget_production
  primary:
    host: rhodeisland.example.com
    port: 5432
  replica:
    host: virginia.example.com
    port: 5432
```

Зададим переменные брокера сообщений для группы хостов "production":
```bash
vi group_vars/production/rabbitmq
```

```yaml
rabbitmq:
  host: pennsylvania.example.com
  port: 5672
```

## Use Dynamic Registry

Выведем статус Vagrant:
```bash
vagrant status
```

Выведем статус Vagrant в виде, удобном для машинного анализа:
```bash
vagrant status --machine-readable
```

Получим информацию о конкретной виртуальной машине Vagrant с именем "vagrant2":
```bash
vagrant ssh-config vagrant2
```

Установим необходимые для анализа модули:
```bash
sudo pip2 install paramiko
```

Произведём анализ с помощью Python в ручном режиме:
```bash
/usr/bin/env python
```

```python
import subprocess
import paramiko
cmd = "vagrant ssh-config vagrant2"
p = subprocess.Popen(cmd.split(), stdout=subprocess.PIPE)
config = paramiko.SSHConfig()
config.parse(p.stdout)
config.lookup("vagrant2")
```

Создадим файл динамического реестра и сделаем его выполняемым:
```bash
touch dynamic.py
chmod +x dynamic.py
```

Зададим скрипт динамического реестра для предоставления информации о хостах Vagrant:
```bash
vi dynamic.py
```

```py
#!/usr/bin/env python
# Adapted from Mark Mandel's implementation
# https://github.com/ansible/ansible/blob/stable-2.1/contrib/inventory/vagrant.py

import argparse
import json
import paramiko
import subprocess
import sys


def parse_args():
    parser = argparse.ArgumentParser(description="Vagrant inventory script")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--list', action='store_true')
    group.add_argument('--host')
    return parser.parse_args()


def list_running_hosts():
    cmd = "vagrant status --machine-readable"
    status = subprocess.check_output(cmd.split()).rstrip()
    hosts = []
    for line in status.split('\n'):
        (_, host, key, value) = line.split(',')[:4]
        if key == 'state' and value == 'running':
            hosts.append(host)
    return hosts


def get_host_details(host):
    cmd = "vagrant ssh-config {}".format(host)
    p = subprocess.Popen(cmd.split(), stdout=subprocess.PIPE)
    config = paramiko.SSHConfig()
    config.parse(p.stdout)
    c = config.lookup(host)
    return {'ansible_host': c['hostname'],
            'ansible_port': c['port'],
            'ansible_user': c['user'],
            'ansible_private_key_file': c['identityfile'][0]}


def main():
    args = parse_args()
    if args.list:
        hosts = list_running_hosts()
        json.dump({'vagrant': hosts}, sys.stdout)
    else:
        details = get_host_details(args.host)
        json.dump(details, sys.stdout)

if __name__ == '__main__':
    main()
```

Проверим работу динамического реестра запросив информацию об узле с именем "vagrant2":
```bash
./dynamic.py --host=vagrant2
```

Проверим работу динамического реестра запросив список групп:
```bash
./dynamic.py --list
```

Проверим работу Ansible с динамическим реестром:
```bash
ansible all -i dynamic.py -m ping
```

## Use Split Registry

Создадим директорию для хранения файлов реестров:
```bash
mkdir inventory
```

Переместим файлы статического и динамического реестров в созданную папку:
```bash
mv hosts inventory/hosts
mv dynamic.py inventory/dynamic.py
```

Укажем путь к папке с файлами реестров в конфигурационном файле Ansible:
```bash
vi ansible.cfg
```

```ini
...
inventory = inventory
...
```

Проверим работу Ansible с разделённым реестром:
```bash
ansible all -m ping
```

## Add hosts and groups inside playbook

Удалим созданные виртуальные машины:
```bash
vagrant destroy -f
```

Обновим файл хостов, настроив соединение только с локальной машиной:
```bash
echo "localhost ansible_connection=local" > inventory/hosts
```

Проверим доступность локальной машины:
```bash
ansible all -m ping
```

Создадим плэйбук, в котором развернём новую виртуальную машину и добавим её в реестр:
```bash
vi playbooks/add-new-host.yaml
```

```yaml
- name: Provision a vagrant machine
  hosts: localhost
  vars:
    box: ubuntu/trusty64
  tasks:
    - name: Create a Vagrantfile
      command: vagrant init {{ box }} creates=Vagrantfile

    - name: Bring up a vagrant machine
      command: vagrant up

    - name: Add the vagrant machine to the inventory
      add_host: >
          name=vagrant
          ansible_host=127.0.0.1
          ansible_port=2222
          ansible_user=vagrant
          ansible_private_key_file="/Users/jeno/Documents/HackerU/DevOps/12/Ansible/1-setup/playbooks/playbooks/.vagrant/machines/default/virtualbox/private_key"

- name: Do something to the vagrant machine
  hosts: vagrant
  become:  yes
  tasks:
    - name: Print hostname
      command: hostname

- name: Destroy vagrant machine
  hosts: localhost
  tasks:
    - name: Destroy vagrant machine
      command: vagrant destroy -f
```

Запустим созданный плэйбук:
```bash
ansible-playbook playbooks/add-new-host.yaml
```

Конфигурируем Vagrantfile для создания 2 локальных виртуальных машин:
```bash
vi Vagrantfile
```

```ruby
VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Использовать один SSH ключ для всех виртуальных машин
  config.ssh.insert_key = false

  config.vm.define "vagrant1" do |vagrant1|
    vagrant1.vm.box = "ubuntu/trusty64"
    vagrant1.vm.network "forwarded_port", guest: 80, host: 8080
    vagrant1.vm.network "forwarded_port", guest: 443, host: 8443
  end

  config.vm.define "vagrant2" do |vagrant2|
    vagrant2.vm.box = "centos/7"
    vagrant2.vm.network "forwarded_port", guest: 80, host: 8081
    vagrant2.vm.network "forwarded_port", guest: 443, host: 8444
    vagrant2.vm.synced_folder ".", "/vagrant", disabled: true
  end

end
```

Запускаем 2 виртуальные машины:
```bash
vagrant up
```

Настроим файл инвентаря для управления созданными виртуальными машинами с помощью Ansible:
```bash
vi inventory/hosts
```

```ini
[myhosts]
vagrant1 ansible_ssh_host=127.0.0.1 ansible_ssh_port=2222
vagrant2 ansible_ssh_host=127.0.0.1 ansible_ssh_port=2200
```

Проверим доступность виртуальных машин:
```bash
ansible all -m ping
```

Создадим плэйбук, в котором запустим 2 локальные виртуальные машины и установим на них htop:
```bash
vi playbooks/group-new-host.yaml
```

```yaml
- name: Group hosts by distribution
  hosts: myhosts
  gather_facts: True
  tasks:
    - name: Create groups based on distro
      group_by: key={{ ansible_distribution }}


- name: Do something to Ubuntu hosts
  hosts: Ubuntu
  become:  yes
  tasks:
    - name: Install htop
      apt: name=htop

- name: Do something else to CentOS hosts
  hosts: CentOS
  become:  yes
  tasks:
    - name: Install epel-release
      yum:
        name: epel-release
        state: present
        update_cache: yes

    - name: Install htop
      yum: name=htop
```

Запустим созданный плэйбук:
```bash
ansible-playbook playbooks/group-new-host.yaml
```

Удалим созданные виртуальные машины:
```bash
vagrant destroy -f
```

#### Задание:
Создать структуру директорий и файлов для инвентаря и файлов с переменными окружения и добавить в них данные для доступа к машинам с PostgreSQL и bookapp.

# Use Variables
---

## Configure Specific Environment

Конфигурируем Vagrantfile для создания 2 локальных виртуальных машин:
```bash
vi Vagrantfile
```

```ruby
VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Использовать один SSH ключ для всех виртуальных машин
  config.ssh.insert_key = false

  config.vm.define "vagrant1" do |vagrant1|
    vagrant1.vm.box = "ubuntu/trusty64"
    vagrant1.vm.network "forwarded_port", guest: 80, host: 8080
    vagrant1.vm.network "forwarded_port", guest: 443, host: 8443
  end

  config.vm.define "vagrant2" do |vagrant2|
    vagrant2.vm.box = "centos/7"
    vagrant2.vm.network "forwarded_port", guest: 80, host: 8081
    vagrant2.vm.network "forwarded_port", guest: 443, host: 8444
    vagrant2.vm.synced_folder ".", "/vagrant", disabled: true
  end

end
```

Запускаем 2 виртуальные машины:
```bash
vagrant up
```

Настроим файл инвентаря для управления созданными виртуальными машинами с помощью Ansible:
```bash
mkdir inventory
vi inventory/hosts
```

```ini
[myhosts]
server1 ansible_ssh_host=127.0.0.1 ansible_ssh_port=2222
server2 ansible_ssh_host=127.0.0.1 ansible_ssh_port=2200
```

Для использования единого SSH ключа указываем незащищённый приватный ключ Vagrant в качестве приватного ключа для подключения в файле конфигурации Ansible:
```bash
vi ansible.cfg
```

```ini
[defaults]
inventory = inventory
remote_user = vagrant
private_key_file = ~/.vagrant.d/insecure_private_key
host_key_checking = False
```

Проверим доступность виртуальных машин:
```bash
ansible all -m ping
```

## Use Registred Variables

Создадим плэйбук для определения пользователя и сохранения его идентификатора в переменную:
```bash
mkdir playbooks
vi playbooks/whoami.yaml
```

```yaml
- name: Show return value of command module
  hosts: server1
  tasks:
    - name: Capture output of id command
      command: id -un
      register: login

    - debug: var=login
```

Выполним созданный плэйбук и изучим вывод:
```bash
ansible-playbook playbooks/whoami.yaml
```

Изменим созданный плэйбук, добавив вывод сообщения с именем пользователя, под которым произведена аутентификация:
```bash
vi playbooks/whoami.yaml
```

```yaml
- name: Show return value of command module
  hosts: server1
  tasks:
    - name: Capture output of id command
      command: id -un
      register: login

    - debug: msg="Logged in as user {{ login.stdout }}"
```

Выполним созданный плэйбук и изучим вывод:
```bash
ansible-playbook playbooks/whoami.yaml
```

Создадим плэйбук с запуском команды, возвращающей ошибку, и записью ошибки в переменную для отладки:
```bash
vi playbooks/debug-error.yaml
```

```yaml
- name: Show error of command module in debug
  hosts: server1
  tasks:
    - name: Capture error of cat command
      command: cat nofile
      register: result
      ignore_errors: True

    - debug: var=result
```

Выполним созданный плэйбук и изучим вывод:
```bash
ansible-playbook playbooks/debug-error.yaml
```

Создадим плэйбук, который имеет разный состав зарегистрированной переменной при изменении хоста и при отсутствии изменения:
```bash
vi playbooks/install-nginx-apt.yaml
```

```yaml
- name: Install Nginx with apt packet manager
  hosts: server1
  become: True
  tasks:
    - name: Install Nginx
      apt: name=nginx update_cache=yes
      register: result

    - debug: var=result
```

Выполним созданный плэйбук первый раз и изучим вывод:
```bash
ansible-playbook playbooks/install-nginx-apt.yaml
```

Выполним созданный плэйбук второй раз и изучим вывод:
```bash
ansible-playbook playbooks/install-nginx-apt.yaml
```

## Use Facts

Создадим плэйбук, который имеет собирает факты о всех хостах и выводит информацию об их операционных системах:
```bash
vi playbooks/get-os.yaml
```

```yaml
- name: Print out operating system
  hosts: all
  gather_facts: True
  tasks:
    - debug: var=ansible_distribution
```

Выполним созданный плэйбук и изучим вывод:
```bash
ansible-playbook playbooks/get-os.yaml
```

Изучим все факты, доступные по одному из серверов:
```bash
ansible server1 -m setup
```

Изучим факты, доступные по одному из серверов, отфильтрованные по заданному фильтру:
```bash
ansible server1 -m setup -a 'filter=ansible_eth*'
```

Создадим файл с локальными фактами:
```bash
mkdir playbooks/files
vi playbooks/files/example.fact
```

```ini
[book]
title=Ansible: Up and Running
author=Lorin Hochstein
publisher=O'Reilly Media
```

Создадим плэйбук для копирования файла с локальными фактами на хосты реестра:
```bash
vi playbooks/copy-facts.yaml
```

```yaml
- name: Copy facts file to hosts
  hosts: all
  become: True
  tasks:
    - name: Create directory for facts files
      file: path=/etc/ansible/facts.d state=directory

    - name: Copy facts files
      copy: src=example.fact dest=/etc/ansible/facts.d/example.fact owner=root mode=0600
```

Выполним созданный плэйбук:
```bash
ansible-playbook playbooks/copy-facts.yaml
```

Создадим плэйбук для вывода локальных фактов:
```bash
vi playbooks/print-local-facts.yaml
```

```yaml
- name: Print local facts
  hosts: all
  become: True
  tasks:
    - name: Print ansible_local
      debug: var=ansible_local

    - name: Print book title
      debug: msg="The title of the book is {{ ansible_local.example.book.title }}"
```

Выполним созданный плэйбук и изучим вывод:
```bash
ansible-playbook playbooks/print-local-facts.yaml
```

## Set Variables

Создадим плэйбук, в котором зададим переменную из вывода модуля и обратимся к ней в другом модуле:
```bash
vi playbooks/set-variable.yaml
```

```yaml
- name: Set variable from module output
  hosts: all
  tasks:
    - name: Capture output of id command
      command: id -un
      register: result

    - set_fact: login={{ result.stdout }}

    - name: Get full information about user from variable
      command: id -G {{ login }}
      register: output

    - debug: var=output
```

Выполним созданный плэйбук и изучим вывод:
```bash
ansible-playbook playbooks/set-variable.yaml
```

## Use Default Variables

Выведем все переменные хостов, заданные по умолчанию:
```bash
ansible all -m debug -a var=hostvars
```

Выведем все переменные одного из хостов, заданные по умолчанию:
```bash
ansible server1 -m debug -a var=hostvars.server1
```

Выведем конкретную переменную одного из хостов, заданную по умолчанию:
```bash
ansible server1 -m debug -a var=hostvars.server1.ansible_ssh_host
```

Выведем информацию о группах хостов:
```bash
ansible server1 -m debug -a var=groups
```

Выведем информацию об одной из групп хостов:
```bash
ansible server1 -m debug -a var=groups.myhosts
```

## Set Variables from Command Line

Создадим плэйбук, который выводит значение заданной переменной:
```bash
vi playbooks/greet.yaml
```

```yaml
- name: Pass a message on the command line
  hosts: server1
  vars:
    greeting: "You didn't specify a message"
  tasks:
    - name: Output a message
      debug: msg="{{ greeting }}"
```

Выполним созданный плэйбук и изучим вывод:
```bash
ansible-playbook playbooks/greet.yaml
```

Выполним созданный плэйбук, задав используемую переменную, и изучим вывод:
```bash
ansible-playbook playbooks/greet.yaml -e greeting=hiya
```

Выполним созданный плэйбук, задав используемую переменную в виде строки с пробелами, и изучим вывод:
```bash
ansible-playbook playbooks/greet.yaml -e 'greeting="hi there"'
```

Создадим файл с переменными для передачи в плэйбук:
```bash
vi playbooks/files/variables.yaml
```

```yaml
greeting: "hi there"
```

Выполним созданный плэйбук, передав файл с переменными окружения, и изучим вывод:
```bash
ansible-playbook playbooks/greet.yaml -e @playbooks/files/variables.yaml
```

Удалим созданные виртуальные мащины:
```bash
vagrant destroy -f
```

#### Задание:
Добавить в плэйбук настройки PostgreSQL и bookapp логирование полезных для отладки данных и задачи их вывода при запуске.

## Ansible Jenkins Integration

Установим Ansible на хост Master:
```bash
sudo yum install -y epel-release
sudo yum install -y ansible
```

Установим плагин Ansible для Jenkins. Добавим инсталляцию Ansible в разделе "Конфигурация глобальных инструментов" со следующими параметрами:
- Name: ansible
- Path to ansible executables directory: /usr/bin

Удалим старый ключ jenkins для доступа к узлу Slave:
```bash
sudo rm -rf /var/lib/jenkins/.ssh
```

Сгенерируем новый ключ для Jenkins без passphrase:
```bash
sudo -u jenkins ssh-keygen
```

Скопируем новый новый ключ для Jenkins без passphrase на узел Slave:
```bash
sudo -u jenkins ssh-copy-id -i /var/lib/jenkins/.ssh/id_rsa vagrant@192.168.10.3
```

Проверим подключение по ssh к узлу Slave из под пользователя jenkins:
```bash
sudo -u jenkins ssh vagrant@192.168.10.3
```

Настроим файл инвентаря для управления созданными виртуальными машинами с помощью Ansible:
```bash
sudo -u jenkins mkdir /var/lib/jenkins/inventory
sudo -u jenkins vi /var/lib/jenkins/inventory/hosts
```

```ini
[slaves]
slave1 ansible_ssh_host=192.168.10.3 ansible_ssh_port=22
```

Для использования единого SSH ключа указываем незащищённый приватный ключ Vagrant в качестве приватного ключа для подключения в файле конфигурации Ansible:
```bash
sudo -u jenkins vi /var/lib/jenkins/ansible.cfg
```

```ini
[defaults]
inventory = inventory
remote_user = vagrant
host_key_checking = False
```

Даём доступы на  ключ (если ругается):
```bash
cd /var/lib/jenkins/
sudo chmod 600 /var/lib/jenkins/.ssh/id_rsa.pub
```

Проверим доступность виртуальных машин:
```bash
sudo -u jenkins ansible all -m ping -i /var/lib/jenkins/inventory 
```

Создадим плэйбук для проверки конфигурации SonarQube:
```bash
sudo -u jenkins vi check-sonar.yaml
```

Создадим плэйбук для проверки готовности SonarQube к статическому анализу кода:
```yaml
  - name: Check SonarQube Installation
    hosts: slaves
    become: True
    tasks:
    - name: Install required system packages
      yum: name={{ item }} state=present update_cache=yes
      loop: [ 'postgresql96-server', 'postgresql96-contrib' ]

    - name: Start PostgreSQL
      service: name=postgresql-9.6 state=started enabled=true

    - name: Create PostgreSQL user
      user: name=postgres state=present

    - name: Start SonarQube
      service: name=sonar state=started enabled=true

    - name: Install httpd
      yum: name=httpd state=present update_cache=yes

    - name: Start httpd
      service: name=httpd state=started enabled=true
```

Выполним созданный плэйбук и изучим вывод:
```bash
sudo -u jenkins ansible-playbook check-sonar.yaml
```
