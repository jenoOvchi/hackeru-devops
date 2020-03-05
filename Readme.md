# Jenkins, CI и Groovy Pipeline
---

### Установка Jenkins

Конфигурируем Vagrantfile для создания виртуальной машины:
```bash
vi Vagrantfile
```

```ruby
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.define "master" do |master|
    master.vm.box = "centos/7"
    master.vm.network "forwarded_port", guest: 8080, host: 8080
    master.vm.network "private_network", ip: "192.168.10.2"
    master.vm.provider "virtualbox" do |v|
       v.memory = 1024
       v.cpus = 1
     end
    master.vm.provision "shell", inline: <<-SHELL
      sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config    
      sudo systemctl restart sshd
    SHELL
  end
end
```

Запускаем виртуальную машину:
```bash
vagrant up
```

Подключаемся по SSH к виртуальной машине:
```bash
vagrant ssh
```

Устанавливаем пакеты Java и epel-release:
```bash
sudo yum -y install java-1.8.0-openjdk epel-release wget
```

Устанавливаем пакеты Java и epel-release:
```bash
sudo wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo
```

Устанавливаем ключ Jenkins:
```bash
sudo rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
```

Устанавливаем Jenkins:
```bash
sudo yum -y install jenkins-2.204.4
```

Активируем Jenkins:
```bash
sudo systemctl enable jenkins
```

Запускаем Jenkins:
```bash
sudo systemctl start jenkins
```

Открываем в браузере пользовательский интерфейс Jenkins по адресу 127.0.0.1:8080.

Выводим временный пароль Jenkins:
```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Базовые функции Jenkins

В браузере вводим временный пароль в поле "Administrator password" и нажимаем кнопку "Continue". На открывшейся форме нажимаем кнопку "Install Suggested Plugins" и дожидаемся установки рекомендованных плагинов. На следующей форме заполняем данные об администраторе (например, Admin, S3cR#tP@ssW0rd, Admin, admin@localhost) и нажимаем кнопку "Save and Continue", нажимаем кнопку "Save and Finish" и далее кнопку "Start using Jenkins".

Нажимаем на кнопку "создайте новую задачу". На открывшейся форме вводим имя задачи (например, Test Job), выбираем пункт "Создать задачу со свободной конфигурацией" и нажимаем на кнопку "OK". На открывшейся форме заполняем раздел "Описание" (например, Job for testing base Jenkins functions). Далее переходим в раздел "Сборка", нажимаем на кнопку "Добавить шаг сборки", выбираем пункт "Выполнить команду Shell", вводим тестовую команду (например, echo "Hello from Jenkins!!!") и нажимаем кнопку "Сохранить". Нажимаем кнопку "Собрать сейчас" и в разделе "История сборок" переходим в созданную сборку. Изучаем информацию о сборке и открываем раздел "Вывод консоли". Изучаем лог сборки. Возвращаемся на форму "Test Job", нажимаем на кнопку "Настройки", в разделе "Сборка" в блоке "Выполнить команду Shell" вводим тестовую команду, приводящую к неуспешному завершению сборки (например, unknown command) и нажимаем кнопку "Сохранить". Нажимаем кнопку "Собрать сейчас" и в разделе "История сборок" переходим в созданную сборку. Изучаем информацию о сборке и открываем раздел "Вывод консоли". Изучаем лог сборки. Нажимаем на логотип Jenkins и переходим в главное меню.

### Настройка Jenkins

Нажимаем на кнопку "Настроить Jenkins" и переходим на форму "Конфигурация системы". Изучаем настройки, представленные на форме. В разделе "Глобальные настройки" активируем чекбокс "Environment variables", нажимаем кнопку "Добавить", в поле "имя" вводим "TEST_VARIABLE_NAME", в поле "значение" вводим "TEST_VARIABLE_VALUE", нажимаем кнопку "Добавить" и нажимаем кнопку "Сохранить". Возвращаемся на форму "Test Job", нажимаем на кнопку "Настройки", в разделе "Сборка" в блоке "Выполнить команду Shell" вводим тестовую команду для вывода переменных окружения (env) и нажимаем кнопку "Сохранить". Нажимаем кнопку "Собрать сейчас" и в разделе "История сборок" переходим в созданную сборку. Изучаем информацию о сборке и открываем раздел "Вывод консоли". Изучаем лог сборки, находим в нём добавленную переменную. Нажимаем на логотип Jenkins и переходим в главное меню.

Нажимаем на кнопку "Настроить Jenkins" и переходим на форму "Глобальные настройки безопасности". Изучаем настройки, представленные на форме. В разделе "Контроль доступа" в подразделе "Авторизация" выбираем пункт "Матричное распределение прав" и нажимаем кнопку "Add user or group...". В pop-up окне вводим имя тестовой группы (например, hackeru) и нажимаем кнопку "ОК". Добавляем созданной группе права на чтение, выставив чекбокс в столбце "Полные/Read", и нажимаем кнопку "Сохранить". Обращаем внимание на появившееся предупреждение.

Переходим на форму "Configure Credentials" и изучаем настройки, представленные на форме. Выбираем в листбоксе "Providers" пункт "Exclude selected" и помечаем чекбокс "User Credentials Provider". Выбираем в листбоксе "Types" пункт "Exclude selected" и помечаем чекбокс "Secret text" и нажимаем кнопку "Save". Переходим в меню настроек.

Переходим на форму "Конфигурация глобальных инструментов" и изучаем настройки, представленные на форме. Переходим в раздел "JDK", нажимаем кнопку "Добавить JDK", в поле "Имя" вводим "Default JDK", в поле "JAVA_HOME" вводим "/usr/lib/jvm/jre-1.8.0", снимаем чекбокс "Install automatically" и нажимаем кнопку "Save". Возвращаемся на форму "Test Job", нажимаем на кнопку "Настройки", в разделе "Среда сборки" помечаем чекбокс "With Ant", в листбоксе "JDK" выбираем "Default JDK" и нажимаем кнопку "Сохранить". Переходим в меню настроек.

Переходим на форму "Управление плагинами" и изучаем настройки, представленные на форме. Переходим на вкладку установленные и изучаем установленные плагины. Переходим на вкладку "Доступные", в поле "Фильтр" вводим "Authorize Project", ставим чекбокс напротив найденного плагина и нажимаем "Установить без перезагрузки". После завершения установки нажимаем на ссылку "Вернуться на главную страницу" и после этого кнопку "Настроить Jenkins". Обращаем внимание, что статус предупреждения изменился. Открываем сайт с плагинами Jenkins (https://plugins.jenkins.io/) и вводим в поиске Kubernetes. Открываем один из плагинов, нажимаем на кнопку "Archives" и скачиваем последний доступный плагин. Переходим на вкладку "Дополнительно", в разделе "Загрузить плагин" нажимаем на кнопку "Выберите файл", выбираем скачанный файл плагина и нажимаем кнопку "Загрузить". После установки переходим в раздел "Конфигурация системы" меню настройки и проверяем, что появился раздел "Cloud", относящийся к плагину Kubernetes. Переходим в меню настроек.

Переходим на форму "Системная информация" и изучаем информацию о системе, представленную на форме. Возвращаемся на предыдущую страницу и переходим на форму "Системный журнал". Нажимаем на ссылку "Все логи Jenkins" и изучаем логи сервера Jenkins. Возвращаемся на предыдущую страницу и переходим на форму "Статистика использования". Изучаем статистику использования данного экземпляра Jenkins. Нажимаем на ссылку "Короткий" и изучаем статистику использования Jenkins за короткий временной отрезок. Переходим в меню настроек.

Переходим на форму "Jenkins CLI" и изучаем информацию о консольных командах Jenkins, представленную на форме. Скачиваем библиотеку с консольной утилитой Jenkins:
```bash
wget http://127.0.0.1:8080/jnlpJars/jenkins-cli.jar
```
Изучаем справку об использовании консольной утилиты Jenkins:
```bash
java -jar jenkins-cli.jar -s http://127.0.0.1:8080/ help
```
Изучаем список созданных задач в данном экземпляре Jenkins:
```bash
java -jar jenkins-cli.jar -s http://127.0.0.1:8080/ -auth Admin:S3cR#tP@ssW0rd list-jobs
```
Изучаем XML описание созданной задачи "Test Job":
```bash
java -jar jenkins-cli.jar -s http://127.0.0.1:8080/ -auth Admin:S3cR#tP@ssW0rd get-job "Test Job"
```
Переходим в меню настроек.

Переходим на форму "Консоль сценариев" и изучаем информацию о консоли сценариев Groovy, доступных для выполнения из графического интерфейса. Введём с область ввода скрипт вывода установленных плагинов и нажмём кнопку "Запустить":
```groovy
println(Jenkins.instance.pluginManager.plugins)
```
Изучим результат выполнения скрипта в разделе "Результат". Введём с область ввода скрипт диагностики удалённых агентов и нажмём кнопку "Запустить":
```groovy
import hudson.util.RemotingDiagnostics
import jenkins.model.Jenkins

String agent_name = 'test-agent'
groovy_script = '''
println System.getenv("PATH")
println "uname -a".execute().text
'''.trim()

String result
Jenkins.instance.slaves.find { agent ->
    agent.name == agent_name
}.with { agent ->
    result = RemotingDiagnostics.executeGroovy(groovy_script, agent.channel)
}
println result
```
Изучим результат выполнения скрипта в разделе "Результат" - в данный момент удалённые агенты не настроены, о чём свидетельствует сформированная ошибка. Переходим в меню настроек.

Для запуска агента нам потребуется отдельная виртуальная машина с доступом по SSH. Для этого модифицируем файл Vagrant:
```bash
vi Vagrantfile
```

```ruby
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.define "master" do |master|
    master.vm.box = "centos/7"
    master.vm.network "forwarded_port", guest: 8080, host: 8080
    master.vm.network "private_network", ip: "192.168.10.2"
    master.vm.provider "virtualbox" do |v|
       v.memory = 1024
       v.cpus = 1
     end
    master.vm.provision "shell", inline: <<-SHELL
      sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config    
      sudo systemctl restart sshd
    SHELL
  end

  config.vm.define "slave" do |slave|
    slave.vm.box = "centos/7"
    slave.vm.network "private_network", ip: "192.168.10.3"
    slave.vm.provider "virtualbox" do |v|
       v.memory = 1024
       v.cpus = 1
     end
    slave.vm.provision "shell", inline: <<-SHELL
      sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config    
      sudo systemctl restart sshd
      sudo yum -y install java-1.8.0-openjdk
    SHELL
  end
end
```

Развернём дополнительную виртуальную машину для запуска агента:
```bash
vagrant up slave
```

Перейдём на виртуальную машину Master:
```bash
vagrant ssh master
```

Проверим доступ с виртуальной машины Master на виртуальную машину Slave:
```bash
ssh vagrant@192.168.10.3
```

Проверим, что мы находимся на виртуальной машине Slave и вернёмся на виртуальную машину Master:
```bash
ip address
exit
```

В Web интерфейсе Jenkins в меню настройки перейдём на форму "Управление средами сборки" и нажмём кнопку "Новый узел". В поле "Название узла" введём "test-agent", установим флаг "Permanent Agent" и нажмём кнопку "ОК". В поле "Корень удаленной ФС" введём "/home/vagrant", в листбоксе "Способ запуска" выберем "Launch agents via SSH", в поле "Host" введём "192.168.10.3", нажмём кнопку "Add" справа от листбокса "Credentials" и выберем "Jenkins" из списка. В появившемся окне создания авторизационных данных выберем Scope "Global", укажем Username "vagrant", Password "vagrant", ID "vagrant", Description "Vagrant Credentials" и нажмём кнопку "Add". В листбоксе "Host Key Verification Strategy" выберем пункт "Non verifying" и нажмём кнопку "Save". Нажмём на ссылку "test-agent" созданного агента и нажмём кнопку "Launch Agent". Перейдём в главное меню и обратим внимание, что в списке "Состояние сборщиков" появился активный сборщик "test-agent".
