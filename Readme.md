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

В Web интерфейсе Jenkins в меню настройки перейдём на форму "Управление средами сборки" и нажмём кнопку "Новый узел". В поле "Название узла" введём "test-agent", установим флаг "Permanent Agent" и нажмём кнопку "ОК". В листбоксе "Способ запуска" выберем "Launch agents via SSH", в поле "Host" введём "192.168.10.3", нажмём кнопку "Add" справа от листбокса "Credentials" и выберем "Jenkins" из списка. В появившемся окне создания авторизационных данных выберем Scope "Global", укажем Username "vagrant", Password "vagrant", ID "vagrant", Description "Vagrant Credentials" и нажмём кнопку "Add". В листбоксе "Host Key Verification Strategy" выберем пункт "Non verifying" и нажмём кнопку "Save". Нажмём на ссылку "test-agent" созданного агента и нажмём кнопку "Launch Agent". Перейдём в главное меню и обратим внимание, что в списке "Состояние сборщиков" появился активный сборщик "test-agent".

Переходим в меню настроек и снова открываем форму "Консоль сценариев". Введём с область ввода скрипт диагностики удалённых агентов и нажмём кнопку "Запустить":
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
Изучим результат выполнения скрипта в разделе "Результат". Перейдём в главное меню.

Для работы с удалёнными репозиториями Git установим Git на узел Slave. Для этого перейдём по SSH на узел Slave (логин и пароль vagrant) и установим нужный пакет:
```bash
ssh vagrant@192.168.10.3
sudo yum install git
```

### Создание задачи сборки

Создадим задачу для загрузки удалённого репозитория с приложением. Нажимаем кнопку "Создать Item", на открывшейся форме вводим имя задачи (например, Build-bookapp), выбираем пункт "Создать задачу со свободной конфигурацией" и нажимаем на кнопку "OK". На открывшейся форме заполняем раздел "Описание" (например, Job for build actual version of bookapp application). Далее переходим в раздел "Управление исходным кодом", выбираем пукт "Git" и в поле "Repository URL" вводим адрес репозитория (например, https://github.com/jenoOvchi/bookapp.git). Переходим в раздел "Сборка", нажимаем на кнопку "Добавить шаг сборки", выбираем пункт "Выполнить команду Shell", вводим тестовую команду для проверки того, что репозиторий выкачан (например, ls) и нажимаем кнопку "Сохранить". Нажимаем кнопку "Собрать сейчас" и в разделе "История сборок" переходим в созданную сборку. Нажимаем на логотип Jenkins и переходим в главное меню.

Модифицируем задачу для запуска сборки и сохранения собранных артефактов. Для этого установим Go на Slave Jenkins. В консоли перейдём по SSH на узел Slave (логин и пароль vagrant) и установим нужные пакеты:
```bash
vagrant ssh slave
sudo yum install -y wget
wget https://dl.google.com/go/go1.13.3.linux-amd64.tar.gz
tar -xzf go1.13.3.linux-amd64.tar.gz
sudo mv go /usr/local
mkdir Projects
export GOROOT=/usr/local/go
export GOPATH=$HOME/Projects
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
```

Проверим корректность установки:
```bash
go version
go env
```

Настроим переменные окружения на узле Slave. В Web интерфейсе Jenkins в меню настройки перейдём на форму "Управление средами сборки", выберем узел "test-agent" и нажмём на кнопку "Настроить". В разделе "Node Properties" поставим флаг напротив "Environment variables" и добавим три переменных:
имя: GOROOT
значение: /usr/local/go

имя: GOPATH
значение: $HOME/Projects

имя: PATH
значение: $GOPATH/bin:$GOROOT/bin:$PATH

Нажмём кнопку "Save" и перейдём в главное меню. Откроем задачу "Build-bookapp" и нажмём кнопку "Настройки". В разделе "Сборка" заменим команду в блоке "Выполнить команду shell":
```bash
go get github.com/gorilla/mux
go get github.com/jackc/pgx/pgxpool
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o ./bookapp .
```

Нажмём кнопку "Сохранить" и на странице сборки нажмём "Собрать сейчас". Откроем созданную сборку, перейдём в раздел "Вывод консоли" и изучим лог сборки. Перейдём на страницу задачи "Build-bookapp", нажмём на кнопку "Сборочная директория" и изучим файлы сборки.

Установить инструмент можно несколькими путями - напрямую на виртуальную машину или с помощью плагина. Настроим установку с помощью плагина. Для этого перейдём в меню настройки, откроем форму "Управление плагинами", перейдём во вкладку "Доступные", в сторке фильтра введём "golang", поставим флаг напротив "Go Plugin" и нажмём кнопку "Установить без перезагрузки". После завершения установки перейдём в меню настройки, откроем форму "Управление средами сборки", выберем узел "test-agent" и нажмём на кнопку "Настроить". В разделе "Node Properties" уберём флаг напротив "Environment variables", нажмём кнопку "Save" и перейдём в меню настройки. Перейдём на форму "Конфигурация глобальных инструментов" и в разделе "Go" нажмём на кнопку "Go установок...". Появится новая конфигурация установки. Укажем в поле "Имя" значение "Default Go", поставим флаг напротив надписи "Install automatically", оставим установщик по умолчанию, нажмём кнопку "Save" и перейдём в главное меню. Откроем задачу "Build-bookapp" и нажмём кнопку "Настройки". В разделе "Среда сборки" поставим флаг напротив "Set up Go programming language tools", в листбоксе "Go version" выберем созданную установку Go ("Default Go") и нажмём "Сохранить". На странице сборки нажмём "Собрать сейчас", откроем созданную сборку, перейдём в раздел "Вывод консоли" и изучим лог сборки.

Переменные окружения задачи можно вынести в отдельный блок и задавать единожды. Для этого перейдём в меню настройки, откроем форму "Управление плагинами", перейдём во вкладку "Доступные", в сторке фильтра введём "Environment", поставим флаг напротив "Environment Injector Plugin" и нажмём кнопку "Установить без перезагрузки". После завершения установки перейдём в главное меню, откроем задачу "Build-bookapp" и нажмём кнопку "Настройки". В разделе "Среда сборки" поставим флаг напротив "Inject environment variables to the build process" и в разделе "Properties Content" добавим необходимые переменные:
```bash
CGO_ENABLED=0
GOOS=linux
GOARCH=amd64
PATH=${HOME}/go/bin:$PATH
```
(последняя пригодится в дальнейшем). После этого в разделе сборка изменяем команду на следующую:
```bash
go build -a -o ./bookapp .
```

Нажмём кнопку "Сохранить" и на странице сборки нажмём "Собрать сейчас". Откроем созданную сборку, перейдём в раздел "Вывод консоли" и изучим лог сборки.

Собранные артефакты могут быть опубликованы. Настроим публикацию артефактов при успешной сборке нашего приложения. Для этого откроем задачу "Build-bookapp" и нажмём кнопку "Настройки". В разделе "Послесборочные операции" нажмём на кнопку "Добавить шаг после сборки", выберем пункт "Заархивировать артефакты", в появившемся блоке в поле "Файлы для архивации" введём "bookapp" и нажмём кнопку "Сохранить". На странице сборки нажмём "Собрать сейчас". Откроем созданную сборку, перейдём в раздел "Вывод консоли" и изучим лог сборки. Перейдём по ссылке "Артефакты последних удачных сборок" и изучим опубликованные артефакты.

Автоматизируем сборку обновлений для новых коммитов в репозиторий Git. Для этого откроем задачу "Build-bookapp" и нажмём кнопку "Настройки". В разделе "Триггеры сборки" поставим флаг рядом с надписью "Опрашивать SCM об изменениях" и в разделе "Расписание" укажем расписание "* * * * *" для запуска опроса системы контроля версий каждую минуту и нажмём кнопку "Сохранить". Сделаем тестовый коммит в репозиторий с исходным кодом и дождёмся, когда в разделе "История сборок" появится новая сборка. Откроем созданную сборку, перейдём в раздел "Вывод консоли" и изучим лог сборки.

#### Задание:
Настроить непрерывную сборку для приложения "bookapp", разрабатываемого в рамках курса.

### Модульное тестирование

Модульное тестирование применяется для проверки отдельных функций приложений и библиотек. Тесты осуществляют вызов отдельных функций и методов, проверяя корректность их работы. Для демонстрации работы модульных тестов используем следующее тестовое приложение: https://github.com/jenoOvchi/hackeru-devops-go-simple . Сделаем форк данного репозитория и клонируем приложение локально:
```bash
git clone https://github.com/jenoOvchi/hackeru-devops-go-simple.git
```

Изучим приложение:
```bash
cat hello.go 
```

Соберём приложение:
```bash
go build
```

Запустим приложение и проверим его работоспособность:
```bash
./hello
```

Откроем в браузере страницу http://127.0.0.1:3000/ и проверим, что приложение доступно. 

Изучим модульные тесты приложения:
```bash
cat hello_test.go
```

Запустим модульные тесты приложения:
```bash
go test
```

Запустим модульные тесты приложения с выводом тестового покрытия:
```bash
go test -coverprofile=coverprofile.out
```

Запустим модульные тесты приложения с формированием отчёта о тестовом покрытии:
```bash
go tool cover -html=coverprofile.out -o report.html
```

Откроем отчёт в браузере и изучим результаты.

Создадим задачу для сборки и публикации отчёта о модульном тестировании тестового приложения. В Web интерфейсе Jenkins перейдём в главное меню и нажмём кнопку "Создать Item". В поле "Введите имя Item'а" вводим "hello-app", в поле "Копировать из" вводим "Build-bookapp" и нажимаем кнопку "ОК". В разделе "Управление исходным кодом" в блоке "Repositories" указываем репозиторий Git данного приложения (https://github.com/jenoOvchi/hackeru-devops-go-simple.git), в разделе "Сборка" в блоке "Выполнить команду shell" указываем "go build -a -o ./hello .", добавляем ещё один блок "Выполнить команду shell" и в нём указываем следующие строки:
```bash
go test -coverprofile=coverprofile.out
go tool cover -html=coverprofile.out -o report.html
```

Нажмём кнопку "Сохранить" и на странице сборки нажмём "Собрать сейчас". Откроем созданную сборку, перейдём в раздел "Вывод консоли" и изучим лог сборки. Перейдём в раздел "Сборочная директория" и нажмём на ссылку "report.html".

Установим плагин для публикации HTML отчётов. Для этого перейдём в меню настройки, откроем форму "Управление плагинами", перейдём во вкладку "Доступные", в сторке фильтра введём "HTML", поставим флаг напротив "HTML Publisher" и нажмём кнопку "Установить без перезагрузки". После завершения установки перейдём в главное меню, откроем задачу "hello-app" и нажмём кнопку "Настройки". В разделе "Послесборочные операции" нажмём на кнопку "Добавить шаг после сборки", выберем пункт "Publish HTML reports", в появившемся блоке в поле "Index page[s]" введём "report.html", в поле "Report title" введём "Code Coverage Report" и нажмём кнопку "Сохранить". На странице сборки нажмём "Собрать сейчас". Откроем созданную сборку, перейдём в раздел "Вывод консоли" и изучим лог сборки. Перейдём в раздел "Code Coverage Report" и изучим опубликованный отчёт.

Результаты тестов могут быть опубликованы в виде стандартного для Jenkins (JUnit) отчёта о статистике пройденных тестов. Добавим данную опцию для нашей задачи. Для этого откроем задачу "hello-app" и нажмём кнопку "Настройки". В разделе "Сборка" добавим строки "go get -u github.com/jstemmer/go-junit-report" и "go test -v 2>&1 | go-junit-report > report.xml" в блок с тестами. В разделе "Послесборочные операции" нажмём на кнопку "Добавить шаг после сборки", выберем пункт "Publish JUnit test result report", в появившемся блоке в поле "XML файлы с отчетами о тестировании" введём "report.xml" и нажмём кнопку "Сохранить". На странице сборки нажмём "Собрать сейчас". Откроем созданную сборку, перейдём в раздел "Вывод консоли" и изучим лог сборки. Перейдём в раздел "Результаты теста" и изучим статистику прохождения тестов.

#### Задание:
Настроить непрерывное модульное тестирование для приложения "bookapp", разрабатываемого в рамках курса.

### Доставка обновлений

Настроим установку обновления на тестовый стенд. Для этого будем использовать узел Slave в качестве стенда, на который будет производиться установка обновлений. Установим плагин для публикации артефактов по SSH. Для этого перейдём в меню настройки, откроем форму "Управление плагинами", перейдём во вкладку "Доступные", в сторке фильтра введём "ssh", поставим флаг напротив "Publish Over SSH" и нажмём кнопку "Установить без перезагрузки". После завершения установки перейдём в меню настройки, откроем форму "Конфигурация системы" и перейдём в раздел "Publish over SSH". Для настройки нам потребуется создать SSH ключ для подключения к узлу Slave. На узле Master создадим связку публичного и приватного ключей для пользователя jenkins:
```bash
sudo -u jenkins ssh-keygen
> Enter file in which to save the key (/var/lib/jenkins/.ssh/id_rsa):
> Enter passphrase (empty for no passphrase): !QAZ2wsx
> Enter same passphrase again: !QAZ2wsx
```

Скопируем ключ на узел Slave (пароль vagrant):
```bash
sudo -u jenkins ssh-copy-id vagrant@192.168.10.3
```

В web интерфейсе Jenkins в поле "Passphrase" укажим заданную фразу "!QAZ2wsx", в поле "Path to key" укажем путь к созданному ключу "/var/lib/jenkins/.ssh/id_rsa" и в разделе "SSH Servers" добавим сервер, указав в поле "Name" значение "Slave", в поле "Hostname" значение "192.168.10.3", в поле "Username" значение "vagrant" и нажав кнопку "Test Configuretion". После того, как будет получено значение "Success", нажимаем кнопку "Сохранить". Переходим в главное меню, откроем задачу "hello-app" и нажмём кнопку "Настройки". В разделе "Сборка" нажмём на кнопку "Добавить шаг сборки", выберем пункт "Send files or execute commends over SSH", в появившемся блоке в разделе "Transfers" в поле "Source files" укажем "hello", в поле "Exec command" укажем следующий блок команд:
```bash
PID=$(ps -ef | grep hello | grep -v grep | awk '{print $2}')
if [[ ! -z "$PID" ]]; then kill -9 $PID; fi
chmod +x hello
nohup /home/vagrant/hello > hello.log 2>&1 &
```

Нажмём кнопку "Сохранить". На странице сборки нажмём "Собрать сейчас". Откроем созданную сборку, перейдём в раздел "Вывод консоли" и изучим лог сборки. Выполним запрос для проверки того, что что приложение запущено:
```bash
curl 192.168.10.3:3000
```

Добавим в задачу сборки шаг Smoke тестирования. Для этого модифицируем указанную выше команду и включим её в задачу сборки после этапа развёртывания. Откроем задачу "hello-app" и нажмём кнопку "Настройки". В разделе "Сборка" нажимаем на кнопку "Добавить шаг сборки", выбираем пункт "Выполнить команду Shell" и в созданном блоке введём следующий блок кода:
```bash
CODE=$(curl -i 192.168.10.3:3000 | grep HTTP | awk '{print $2}')
echo ==================================
echo "Application response code=$CODE"
echo ==================================
[[ $CODE == 200 ]] && echo "Deployment successful" || (echo "Deployment unsuccessful" && exit 1)
```

Нажмём кнопку "Сохранить" и на странице сборки нажмём "Собрать сейчас". Откроем созданную сборку, перейдём в раздел "Вывод консоли" и изучим лог сборки.

#### Задание:
Настроить непрерывную доставку и smoke тестирование для приложения "bookapp", разрабатываемого в рамках курса.

### Нотификация

Настроим отправку нотификаций в Slack. Для этого перейдём на сайт https://slack.com/ и зарегистрируемся (если ещё нет аккаунта). Откроек рабочее пространство Slack (Workspace), нажмём на кнопку "+" в разделе "Channels", заполним поля "Name" и "Description" и нажмём кнопку "Create". Теперь установим плагин Jenkins для отправки нотификаций в Slack. Установим плагин для публикации HTML отчётов. Для этого перейдём в меню настройки, откроем форму "Управление плагинами", перейдём во вкладку "Доступные", в сторке фильтра введём "Slack", поставим флаг напротив "Slack Notification" и нажмём кнопку "Установить без перезагрузки". После завершения установки перейдём в главное меню. Вернёмся в интерфейс Slack. В созданном канале нажмём на кнопку "Add an App", в поиске введём "jenkins" и нажмём на кнопку "View" приложения "Jenkins CI". Нажмём на кнопку "View in App Directory", и нажмём на кнопку "Add to Slack". В разделе "Post to Channel" выберем созданный канал и нажмём на кнопку "Add Jenkins CI integration". Скопируем значения полей из раздела "Step 3" и нажмём кнопку "Save Settings". Вернёмся в интерфейс Jenkins. Настроим нотификацию для успешной и неуспешной сборки нашего приложения. Для этого откроем задачу "hello-app" и нажмём кнопку "Настройки". В разделе "Послесборочные операции" нажмём на кнопку "Добавить шаг после сборки", выберем пункт "Slack Notifications", в появившемся блоке поставим флаги напротив "Notify Success", "Notify Every Failure" и "Include Custom Message", в поле "Custom Message" введём следующее сообщение:
```text
Code Coverage Report: http://127.0.0.1:8080/job/Build-bookapp/Code_20Coverage_20Report/
Test Results: http://127.0.0.1:8080/job/Build-bookapp/$BUILD_NUMBER/testReport/
```

В листбоксе "Notification message includes" выберем значение "commit list with authors and titles", в раздел "Workspace" вставим скопированное значение "Team Subdomain", в разделе "Credential" нажмём кнопку "Add", добавим токен из разделе "Integration Token Credential ID" с типом "Secret text", в поле "Channel / member id" вставим имя созданного канала и нажмём кнопку сохранить. На странице сборки нажмём "Собрать сейчас". Откроем созданную сборку, перейдём в раздел "Вывод консоли" и изучим лог сборки. Откроем канал в Slack и проверим, что оповещение успешно отправлено.

#### Задание:
Настроить нотификацию о сборке и доставке приложения "bookapp", разрабатываемого в рамках курса.

### Интеграция с Docker

Удаляем узел Slave и в дальнейшем создаём слэйвы динамически.

Устанавливаем плагины Docker и Docker Compose Build Step.

Устанавливаем Docker на узле Slave:
```bash
vagrant ssh slave
sudo yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io
sudo systemctl enable --now docker
```

Проверяем работоспособность Docker на узле Slave:
```bash
sudo docker ps
```

Делаем API Docker доступным извне:
```bash
sudo vi /lib/systemd/system/docker.service
```

```ini
...
ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:4243 -H unix:///var/run/docker.sock -H fd:// --containerd=/run/containerd/containerd.sock 
...
```

Применяем внесённые изменения:
```bash
sudo systemctl daemon-reload
sudo service docker restart
```

Проверим доступность API Docker:
```bash
curl localhost:4243/version
```

Устанавливаем Docker Compose:
```bash
sudo curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```

Проверка корректности установки Docker Compose:
```bash
docker-compose --version
```

В интерфейсе Jenkins в меню настроек на форме "Конфигурация системы" в разделе "Cloud" настраиваем создание слэйвов с помощью Docker. Для этого:
- создаём новое облако типа "Docker" с именем "docker";
- в поле "Docker Host URI" вводим "tcp://192.168.10.3:4243" и нажимаем кнопку "Test Connection";
- ставим флаги напротив "Enabled" и "Expose DOCKER_HOST";
- в область "Docker Agent templates" добавляем тестовый шаблон слэйва со следующими параметрами:
Docker Agent templates Labels: java-docker-slave
Enabled: yes
Name: java-docker-slave
Docker Image: bibinwilson/jenkins-slave:latest
Remote File System Root: /home/jenkins
Connect method: Connect with SSH
SSH key: Use configured SSH credentials
SSH Credentials: jenkins/jenkins
Host Key Verification Strategy: Non verifying Verification Strategy

Создаём задачу для проверки работоспособности запуска слэйвов с помощью Docker:
Имя: docker-test
Тип: задача со свободной конфигурацией
Описание: Docker Test Job
Ограничить лейблы сборщиков, которые могут исполнять данную задачу: yes
Label Expression: java-docker-slave
Шаги сборки:
- Выполнить команду shell: echo "It Works!"

Запустим задачу и проверим, что она отработала успешно. Параллельно с запуском на узле Slave проверим, что запустился контейнер для выполнения сборки:
```bash
sudo docker ps
```

После выполнения задачи проверим, что контейнер удалён:
```bash
sudo docker ps
```

Добавим метку "master" для узла Master.

Используем плагин Docker для сборки образов и запуска контейнеров. Для этого в задачу добавим следующие разделы:
Ограничить лейблы сборщиков, которые могут исполнять данную задачу: yes
Label Expression: master
Управление исходным кодом: Git
Repositories: https://github.com/jenoOvchi/bookapp.git
Шаг сборки: Build / Publish Docker Image
Directory for Dockerfile: .
Cloud: docker
Image: bookapp:v1
Pull base image: yes
Шаг сборки: Send files or execute commands over SSH
Name: Slave
Source files: docker-compose.yml
Exec command: sudo docker-compose up -d
Exec command: sudo docker ps (ещё один блок Transfer Set)

Запустим задачу и изучим лог сборки. Проверим состав запущенных контейнеров.

Остановим все запущенные контейнеры и попробуем запустить приложение с помощью плагина Docker:
```bash
sudo docker stop $(sudo docker ps -a -q)
sudo docker rm $(sudo docker ps -a -q)
```

Внесём в задачу следующие изменения:
Label Expression: java-docker-slave
Удалим шаг сборки: Send files or execute commands over SSH
Добавим шаг сборки: Start / Stop Docker Containers
Action to choose: Run Container
Docker Cloud: Cloud this build is running on
Docker Image: bookapp:v1

Запустим задачу и изучим лог сборки. Лог повествует о том, что данный шаг не работает без реестра образов Docker. Развернём его:
```bash
sudo docker run -d -p 5000:5000 --restart=always --name registry registry:2
```

Проверим работоспособность реестра:
```bash
sudo docker pull ubuntu:16.04
sudo docker tag ubuntu:16.04 localhost:5000/my-ubuntu
sudo docker push localhost:5000/my-ubuntu
sudo docker image remove ubuntu:16.04
sudo docker image remove localhost:5000/my-ubuntu
sudo docker pull localhost:5000/my-ubuntu
```

Добавим развёрнутый реестр в доверенный список небезопасных репозиториев:
```bash
sudo vi /etc/docker/daemon.json
```

```json
{
  "insecure-registries" : ["192.168.10.3:5000"]
}
```

Применяем внесённые изменения:
```bash
sudo systemctl daemon-reload
sudo service docker restart
```

Добавим в задачу шаг загрузки образа и скорректируем имена образов:
Шаг сборки: Build / Publish Docker Image
Image: 192.168.10.3:5000/bookapp:v1
Push image: yes
Шаг сборки: Start / Stop Docker Containers
192.168.10.3:5000/bookapp:v1

Запустим задачу и изучим лог сборки. После выполнения задачи проверим, что контейнер запущен:
```bash
sudo docker ps
```

#### Задание
Настроить хранение образов реестра на локальном диске и взаимодействие по протоколу HTTPS (https://docs.docker.com/registry/deploying/).