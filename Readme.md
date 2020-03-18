# Jenkins, CI и Groovy Pipeline
---

### Работа с pipeline

Откроем официальную документацию Jenkins (https://jenkins.io/doc/book/pipeline/) и изучим раздел, относящийся к пайплайнам.

Создадим задачу под название bookapp-pipeline и типом Pipeline. Перейдём в раздел "Pipeline" и в блок "Script" вставим описание тестового пайплайна:
```bash
pipeline {
  agent any
  stages {
    stage ('Echo') {
      steps {
        echo 'Running build automation'
      }
    }
  }
}
```
Сохраним, запустим задачу и изучим лог сборки.

Добавим в пайплайн несколько шагов. Откроем раздел "Настройки" и изменим описание тестового пайплайна:
```bash
pipeline {
  agent any
  stages {
    stage ('Checkout') {
      steps {
        echo 'Checkout code from Git'
      }
    }
    stage ('Build') {
      steps {
        echo 'Build artefacts'
      }
    }
    stage ('Test') {
      steps {
        echo 'Test application'
      }
    }
    stage ('Report') {
      steps {
        echo 'Archive reports'
      }
    }
  }
}
```
Сохраним, запустим задачу и изучим лог сборки. В разделе "Stage View" нажмём на один из шагов пайплайна, во всплывающем элементе нажмём кнопку "Logs" и изучим его логи.

Продемонстрируем работу с переменными окружения в пайплайнах. Откроем раздел "Настройки" и изменим описание тестового пайплайна:
```bash
pipeline {
    agent any

    stages {
        stage("Env Variables") {
            steps {
                sh "printenv"
            }
        }
    }
}
```
Сохраним, запустим задачу и изучим лог сборки.

Продемонстрируем обращение к переменным окружения внутри шагов пайплайна. Откроем раздел "Настройки" и изменим описание тестового пайплайна:
```bash
pipeline {
    agent any

    stages {
        stage("Env Variables") {
            steps {
                echo "The build number is ${env.BUILD_NUMBER}"
                echo "You can also use \${BUILD_NUMBER} -> ${BUILD_NUMBER}"
                sh 'echo "I can access $BUILD_NUMBER in shell command as well."'
            }
        }
    }
}
```
Сохраним, запустим задачу и изучим лог сборки.

Продемонстрируем задание переменных окружения в разделе "environment" и внутри шагов пайплайна. Откроем раздел "Настройки" и изменим описание тестового пайплайна:
```bash
pipeline {
    agent any

    environment {
        FOO = "bar"
    }

    stages {
        stage("Env Variables") {
            environment {
                NAME = "Alan"
            }

            steps {
                echo "FOO = ${env.FOO}"
                echo "NAME = ${env.NAME}"

                script {
                    env.TEST_VARIABLE = "some test value"
                }

                echo "TEST_VARIABLE = ${env.TEST_VARIABLE}"

                withEnv(["NOTHER_ENV_VAR=here is some value"]A) {
                    echo "ANOTHER_ENV_VAR = ${env.ANOTHER_ENV_VAR}"
                }
            }
        }
    }
}
```
Сохраним, запустим задачу и изучим лог сборки.

Продемонстрируем переопределение переменных окружения внутри вложенных блоков "environment" и шагов пайплайна. Откроем раздел "Настройки" и изменим описание тестового пайплайна:
```bash
pipeline {
    agent any

    environment {
        FOO = "bar"
        NAME = "Joe"
    }

    stages {
        stage("Env Variables") {
            environment {
                NAME = "Alan" // overrides pipeline level NAME env variable
                BUILD_NUMBER = "2" // overrides the default BUILD_NUMBER
            }

            steps {
                echo "FOO = ${env.FOO}" // prints "FOO = bar"
                echo "NAME = ${env.NAME}" // prints "NAME = Alan"
                echo "BUILD_NUMBER =  ${env.BUILD_NUMBER}" // prints "BUILD_NUMBER = 2"

                script {
                    env.SOMETHING = "1" // creates env.SOMETHING variable
                }
            }
        }

        stage("Override Variables") {
            steps {
                script {
                    env.FOO = "IT DOES NOT WORK!" // it can't override env.FOO declared at the pipeline (or stage) level
                    env.SOMETHING = "2" // it can override env variable created imperatively
                }

                echo "FOO = ${env.FOO}" // prints "FOO = bar"
                echo "SOMETHING = ${env.SOMETHING}" // prints "SOMETHING = 2"

                withEnv(["FOO=foobar"]) { // it can override any env variable
                    echo "FOO = ${env.FOO}" // prints "FOO = foobar"
                }

                withEnv(["BUILD_NUMBER=1"]) {
                    echo "BUILD_NUMBER = ${env.BUILD_NUMBER}" // prints "BUILD_NUMBER = 1"
                }
            }
        }
    }
}
```
Сохраним, запустим задачу и изучим лог сборки.

Продемонстрируем работу с булевыми переменными внутри пайплайна. Откроем раздел "Настройки" и изменим описание тестового пайплайна:
```bash
pipeline {
    agent any

    environment {
        IS_BOOLEAN = false
    }

    stages {
        stage("Env Variables") {
            steps {
                script {
                    if (env.IS_BOOLEAN) {
                        echo "You can see this message, because \"false\" String evaluates to Boolean.TRUE value"
                    }

                    if (env.IS_BOOLEAN.toBoolean() == false) {
                        echo "You can see this message, because \"false\".toBoolean() returns Boolean.FALSE value"
                    }
                }
            }
        }
    }
}
```
Сохраним, запустим задачу и изучим лог сборки.

Продемонстрируем задание переменных окружения с помощью выполнения скриптов внутри пайплайна. Откроем раздел "Настройки" и изменим описание тестового пайплайна:
```bash
pipeline {
    agent any

    environment {
        LS = "${sh(script:'ls -lah', returnStdout: true)}"
    }

    stages {
        stage("Env Variables") {
            steps {
                echo "LS = ${env.LS}"
            }
        }
    }
}
```
Сохраним, запустим задачу и изучим лог сборки.

Продемонстрируем задание переменных окружения с помощью конструкции "def" внутри этапов пайплайна. Откроем раздел "Настройки" и изменим описание тестового пайплайна:
```bash
pipeline {
    agent any

    stages {
        stage("Env Variables") {
            steps {
              script {
                def isBuildConfigPresent = sh(script: "find . -name *.log | grep \"old\" | wc -l | tr -d '\n'", returnStdout: true)
                if ( isBuildConfigPresent == "0" ) {
                  echo "You can see this message, because we don't have files wiht name '*.log' in the workspace."
                }
              }
            }
        }
    }
}
```
Сохраним, запустим задачу и изучим лог сборки.

Продемонстрируем пеализацию шагов с условиями для этапов пайплайна. Откроем раздел "Настройки" и изменим описание тестового пайплайна:
```bash
pipeline {
    agent any

    stages {
        stage("Steps for master branch") {
            when {
                branch 'master'
            }
            steps {
              echo "Using branch master"
            }
        }
        stage("Steps for other branches") {
            when {
              expression {
                return env.BRANCH_NAME != 'master';
              }
            }
            steps {
              echo "Using non master branch"
            }
        }
    }
}
```
Сохраним, запустим задачу и изучим лог сборки.



Продемонстрируем задание переменных окружения с помощью выполнения скриптов внутри пайплайна. Откроем раздел "Настройки" и изменим описание тестового пайплайна:
```bash
pipeline {
    agent { label 'java-docker-slave' }

    environment {
        LS = "${sh(script:'ls -lah', returnStdout: true)}"
    }

    stages {
        stage("Env Variables") {
            steps {
                echo "LS = ${env.LS}"
            }
        }
    }
}
```
Сохраним, запустим задачу и изучим лог сборки.

Продемонстрируем автоматизированную загрузку образа Docker в удалённый реестр после сборки. Для этого заменим образ агента Docker на следующий: "jenoovchi/jenkins-ssh-slave-docker". После этого откроем раздел "Настройки" и изменим описание тестового пайплайна:
```bash
pipeline {
    agent { label 'java-docker-slave' }

    environment {
        DOCKER_IMAGE_NAME = "bookapp"
    }

    stages {
        stage("Checkout") {
            steps {
              git url: 'https://github.com/jenoOvchi/bookapp' 
              }
            }

        stage("Docker Build") {
            steps {
                script {
                    docker.withServer('tcp://192.168.10.3:4243') {
                        app = docker.build(DOCKER_IMAGE_NAME)
                        docker.withRegistry('http://192.168.10.3:5000') {
                            app.push("${env.BUILD_NUMBER}")
                            app.push("latest")
                        }
                    }
                }
            }
        }
    }
}
```
Сохраним, запустим задачу и изучим лог сборки.

Проверим загрузку образа в удалённый реестр:
```bash
sudo docker rmi 192.168.10.3:5000//bookapp:${env.BUILD_NUMBER}
sudo docker pull 192.168.10.3:5000/bookapp:${env.BUILD_NUMBER}
```

Продемонстрируем упорядочивание запуска пайплайнов (для случая параллельного запуска). В настройках агента Docker укажем параметр "Instance Capacity=2". Откроем раздел "Настройки" и изменим описание тестового пайплайна:
```bash
pipeline {
    agent { label 'java-docker-slave' }

    environment {
        DOCKER_IMAGE_NAME = "bookapp"
    }

    stages {
        stage("Checkout") {
            steps {
              git url: 'https://github.com/jenoOvchi/bookapp' 
              }
            }

        stage("Docker Build and Test") {
            steps {
                script {
                    docker.withServer('tcp://192.168.10.3:4243') {
                        app = docker.build(DOCKER_IMAGE_NAME)
                        docker.withRegistry('http://192.168.10.3:5000') {
                            app.push("${env.BUILD_NUMBER}")
                            app.push("latest")
                        }
                    }
                }
            }
        }

        stage("Deploy Image") {
            steps {
                milestone(1)
                echo "Some deployment steps"
            }
        }
    }
}
```
Сохраним, запустим две задачи сборки в параллель и изучим лог их сборки.

#### Задание:
Настроить пайплайн для приложения "bookapp", разрабатываемого в рамках курса. Для этого перейдём в раздел меню "Pipeline Syntax". Откроем в соседней вкладке старую задачу доставки обновлений и изучим реализацию её шагов с помощью пайплайна. Для этого выберем нужные шаги, заполним ожидаемые поля и нажмём кнопку "Generate Pipeline Script". Заменим старый скрипт на созданный и проверим работоспособность.

### Версионирование pipeline

Создадим в репозитории с исходным кодом файл с именем Jenkinsfile и скопируем в него созданный скрипт. Создадим коммит с новым файлом и настроим его использование в Jenkins. Для этого внесём следующие изменения в раздел "Pipeline" задачи:
"Definition": "Pipeline script from SCM"
"SCM": "Git"
"Repository URL": <GitHub-URL>

Сохраним, запустим задачу и изучим лог сборки.

Для демонстрации версионирования добавим в файл с пайплайном дополнительный шаг, например:
```bash
...
    stage ('Show Environment Variables') {
      steps {
        sh "env"
      }
    }
...
```

Сделаем коммит с данным изменением, запустим задачу и изучим лог сборки.

# Nexus, Artifactory, SonarQube

## Sonatype Nexus

Остановим запущенный Docker Registry:
```bash
sudo docker ps | grep registry:2 | awk '{print $1}' | xargs sudo docker rm -f
```

Обновим пакетный менеджер и установим wget:
```bash
sudo yum update -y
sudo yum install wget -y
```

Установим Java (только если не установлена ранее):
```bash
sudo yum install java-1.8.0-openjdk.x86_64 -y
```

Создадим директорию для Sonatype Nexus:
```bash
sudo mkdir /app && cd /app
```

Скачаем последнюю версию дистрибутива Sonatype Nexus:
```bash
sudo wget -O nexus.tar.gz https://download.sonatype.com/nexus/3/latest-unix.tar.gz
```

Разархивируем дистрибутив Sonatype Nexus и переименуем его директорию:
```bash
sudo tar -xvf nexus.tar.gz && sudo mv nexus-3* nexus
sudo mv sonatype-work nexusdata
```

Создадим сервисного пользователя для Sonatype Nexus:
```bash
sudo adduser nexus
```

Объявим сервисного пользователя владельцем для соответствующих директорий Sonatype Nexus:
```bash
sudo chown -R nexus:nexus /app/nexus
sudo chown -R nexus:nexus /app/nexusdata
```

Скорректируем пользователях в параметрах запуска Nexus:
```bash
sudo vi  /app/nexus/bin/nexus.rc
```

```ini
run_as_user="nexus"
```

Скорректируем параметрs запуска Java машины для Nexus:
```bash
sudo vi /app/nexus/bin/nexus.vmoptions
```

```ini
-Xms256m
-Xmx512m
-XX:MaxDirectMemorySize=512m
-XX:+UnlockDiagnosticVMOptions
-XX:+LogVMOutput
-XX:LogFile=../nexusdata/nexus3/log/jvm.log
-XX:-OmitStackTraceInFastThrow
-Djava.net.preferIPv4Stack=true
-Dkaraf.home=.
-Dkaraf.base=.
-Dkaraf.etc=etc/karaf
-Djava.util.logging.config.file=etc/karaf/java.util.logging.properties
-Dkaraf.data=../nexusdata/nexus3
-Dkaraf.log=../nexusdata/nexus3/log
-Djava.io.tmpdir=../nexusdata/nexus3/tmp
-Dkaraf.startLocalConsole=false
```

Настроим лимиты для оптимизации работы Nexus:
```bash
sudo vi /app/nexus/etc/nexus-default.properties
```

```ini
...
application-host=192.168.10.3
...
```

Настроим лимиты для оптимизации работы Nexus:
```bash
sudo vi /etc/security/limits.conf
```

```ini
...
nexus - nofile 65536
...
```

Создадим описание для запуска Nexus как сервиса:
```bash
sudo vi /etc/systemd/system/nexus.service
```

```ini
[Unit]
Description=nexus service
After=network.target
 
[Service]
Type=forking
LimitNOFILE=65536
User=nexus
Group=nexus
ExecStart=/app/nexus/bin/nexus start
ExecStop=/app/nexus/bin/nexus stop
User=nexus
Restart=on-abort
 
[Install]
WantedBy=multi-user.target
```

Активируем и запустим сервис Sonatype Nexus:
```bash
sudo chkconfig nexus on
sudo systemctl start nexus
```

Изучаем логи Sonatype Nexus и ждём сообщения о старте (Started Sonatype Nexus OSS ...):
```bash
tail -f /app/nexusdata/nexus3/log/nexus.log
```

Проверим доступность Web консоли Sonatype Nexus:
```bash
curl http://192.168.10.3:8081
```

Выводим в консоль пароль пользователя "admin":
```bash
cat /app/nexusdata/nexus3/admin.password
```

Открываем web интерфейс (http://192.168.10.3:8081/) Sonatype Nexus в браузере и авторизуемся под пользователем admin. Проходим процедуру настройки:
- обновляем пароль (например, !QAZ2wsx);
- ставим флаг рядом с "Enable anonymous access".

Откроем меню настроек, в разделе "Repositories" нажмём кнопку "Create repository" и создадим репозиторий go (proxy) со следующими параметрами:
- Name: go-proxy
- Remote storage: https://gonexus.dev

Откроем меню "Browse" и изучим список репозиториев. Появился репозиторий go-proxy, статус которого "Online - Remote Available". Нажмём на кнопку "copy" в его строке и скопируем ссылку на этот репозиторий "http://192.168.10.3:8081/repository/go-proxy/".

Перейдём на узел Slave и установим Go (если его сейчас там нет):
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

Установим переменную окружения для использования проксирующего репозитория:
```bash
go env -w GOPROXY=http://192.168.10.3:8081/repository/go-proxy,direct
```

Клонируем проект Go для сборки:
```bash
mkdir -p /tmp/go-demo
cd /tmp/go-demo/
git clone https://github.com/gobuffalo/buffalo.git
ls
```

Соберём клонированный проект:
```bash
cd buffalo/
go build
```

В Web интерфейсе Nexus откроем меню "Browse" и изучим содержимое репозитория go-proxy. Откроем папку "cloud.google.com/go" и изучим её содержимое. Сравним с файлами, скачанными на файловую систему. Установим пакет "tree":
```bash
sudo yum install -y tree
```

Перейдём в папку со скачанными пакетами Go и выведем её содержимое:
```bash
cd /home/vagrant/Projects/pkg/mod/cache/download/cloud.google.com
tree
```

В Web интерфейсе Nexus откроем меню настроек, в разделе "Repositories" нажмём кнопку "Create repository" и создадим репозиторий docker (proxy) со следующими параметрами:
- Name: docker-proxy
- Docker Index: Use Docker Hub

Ещё раз нажмём кнопку "Create repository" и создадим репозиторий docker (hosted) со следующими параметрами:
- Name: docker-private
- HTTP: Yes
- Port: 8083

Ещё раз нажмём кнопку "Create repository" и создадим репозиторий docker (group) со следующими параметрами:
- Name: docker-group
- HTTP: Yes
- Port: 8082
Group.Members: docker-proxy, docker-private

Откроем меню "Browse" и изучим список репозиториев. Появились репозитории docker-proxy, docker-private и docker-group, статус которых "Online" и "Online - Remote Available".

Перейдём на узел Slave настроем Docker для работы с Nexus. Для этого добавим адреса группы и прокси репозитория в список известных небезопасных реестров:
```bash
sudo vi /etc/docker/daemon.json
```

```json
{
  "insecure-registries" : ["192.168.10.3:8082", "192.168.10.3:8083"]
}
```

Перезапустим Docker:
```bash
sudo systemctl daemon-reload
sudo service docker restart
```

Авторизуемся в обоих реестрах Docker (admin/!QAZ2wsx):
```bash
sudo docker login 192.168.10.3:8082
sudo docker login 192.168.10.3:8083
```

Скачиваем образ с Docker Hub, используя проксирующий реестр:
```bash
sudo docker pull 192.168.10.3:8082/alpine:latest
```

В Web интерфейсе откроем меню "Browse", перейдём в реестр "docker-proxy" и изучим его содержимое.

Тегируем имеющийся образ тегом с адресом Nexus:
```bash
sudo docker tag bookapp:v1 192.168.10.3:8083/bookapp:v1
```

Загружаем образ из локального репозитория в Nexus:
```bash
sudo docker push 192.168.10.3:8083/bookapp:v1
```

В Web интерфейсе откроем меню "Browse", перейдём в реестр "docker-private" и изучим его содержимое.

#### Задание:
Настроить загрузку артефактов в рамках пайплайна в Sonatype Nexus для приложения "bookapp", разрабатываемого в рамках курса.

## SonarQube

Скачаем установщик Postgresql:
```bash
sudo rpm -Uvh https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm
```

Установим Postgresql:
```bash
sudo yum -y install postgresql96-server postgresql96-contrib
```

Настроим Postgresql:
```bash
sudo vi /var/lib/pgsql/9.6/data/pg_hba.conf
```

```ini
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     trust
# IPv4 local connections:
host    all             all             127.0.0.1/32            md5
# IPv6 local connections:
host    all             all             ::1/128                 md5
```

Запустим Postgresql:
```bash
sudo systemctl start postgresql-9.6
sudo systemctl enable postgresql-9.6
```

Создадим пользователя "postgres":
```bash
sudo passwd postgres
```

Настроим базу данных для SonarQube:
```bash
su - postgres
createuser sonar
psql
```

```bash
ALTER USER sonar WITH ENCRYPTED password '!QAZ2wsx';
CREATE DATABASE sonar OWNER sonar;
\q
```

Скачаем установщик SonarQube:
```bash
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-6.4.zip
```

Установим SonarQube:
```bash
sudo yum -y install unzip
sudo unzip sonarqube-6.4.zip -d /opt
sudo mv /opt/sonarqube-6.4 /opt/sonarqube
```

Настроим SonarQube:
```bash
sudo vi /opt/sonarqube/conf/sonar.properties
```

```bash
sonar.jdbc.username=sonar
sonar.jdbc.password=!QAZ2wsx
sonar.jdbc.url=jdbc:postgresql://localhost/sonar
```

Создадим юнит для запуска SonarQube как сервиса:
```bash
sudo vi /etc/systemd/system/sonar.service
```

```ini
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking

ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop

User=root
Group=root
Restart=always

[Install]
WantedBy=multi-user.target
```

Установим httpd:
```bash
sudo yum -y install httpd
```

Настроим httpd для проксирования запросов на SonarQube:
```bash
sudo vi /etc/httpd/conf.d/sonar.yourdomain.com.conf
```

```xml
<VirtualHost *:80>  
    ServerName sonar.yourdomain.com
    ServerAdmin me@yourdomain.com
    ProxyPreserveHost On
    ProxyPass / http://localhost:9000/
    ProxyPassReverse / http://localhost:9000/
    TransferLog /var/log/httpd/sonar.yourdomain.com_access.log
    ErrorLog /var/log/httpd/sonar.yourdomain.com_error.log
</VirtualHost>
```

Запустим httpd:
```bash
sudo systemctl start httpd
sudo systemctl enable httpd
```

Отключим SELinux:
```bash
sudo setenforce 0
```

Запустим SonarQube:
```bash
sudo systemctl start sonar
```


Откроем в браузере Web интерфейс SonarQube (http://192.168.10.3/) и авторизуемся (admin/admin). Изучим его интерфейс. 

Создадим сервисного пользователя "jenkins" в SonarQube со следующими параметрами:
- Login: jenkins
- Name: jenkins
- Password: !QAZ2wsx

Нажмём на кнопку создания токена и сгенерируем токен для аутентификации из пайплайна:
Generate Tokens _> jenkins -> Generate -> Copy:
77e19242a0ae764b311e3dbdb640ed2d0b1430ce

Установим на сервер Jenkins плагин "SonarQube Scanner". В настройках системы в разделе SonarQube server нажмём кнопку "Add SonarQube" и добавим сервер со следующими параметрами:
- Name: sonarqube
- Server URL: p:/htt/192.168.10.3
- Credentials:
    - Kind: Secret text
    - Scope: Global
    - Secret: 77e19242a0ae764b311e3dbdb640ed2d0b1430ce
    - ID: sonarqube
    - Description: sonarqube

В настройках глобальных инструментов в разделе "SonarQube Scanner" нажмём на кнопку "Добавить SonarQube Scanner" и создадим сканнер с именем "sonarqube".

Создадим пайплайн со следующими настройками:
```bash
pipeline {
    agent any

    environment {
        DOCKER_IMAGE_NAME = "bookapp"
    }

    stages {
        stage("Checkout") {
            steps {
              git url: 'https://github.com/jenoOvchi/bookapp' 
              }
            }

        stage("SonarQube Analysis") {
            steps {
                script {
                    def scannerHome = tool 'sonarqube';
                    withSonarQubeEnv('sonarqube') {
                        sh "${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=project -Dsonar.sources=."
                    }
                }
            }
        }

        stage("Docker Build and Test") {
            steps {
                script {
                    docker.withServer('tcp://192.168.10.3:4243') {
                        app = docker.build(DOCKER_IMAGE_NAME)
                        }
                    }
                }
            }
        }
}
```