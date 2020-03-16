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

                withEnv(["ANOTHER_ENV_VAR=here is some value"]) {
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
...
```

Сделаем коммит с данным изменением, запустим задачу и изучим лог сборки.

# Nexus, Artifactory, SonarQube

Обновим пакетный менеджер и установим wget:
```bash
sudo yum update -y
sudo yum install wget -y
```

Установим Java:
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
```

Создадим сервисного пользователя для Sonatype Nexus:
```bash
sudo adduser nexus
```

Объявим сервисного пользователя владельцем для соответствующих директорий Sonatype Nexus:
```bash
sudo chown -R nexus:nexus /app/nexus
sudo chown -R nexus:nexus /app/sonatype-work
```

Скорректируем пользователях в параметрах запуска Nexus:
```bash
sudo vi  /app/nexus/bin/nexus.rc
```

```ini
run_as_user="nexus"
...
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
-XX:+UnsyncloadClass
-XX:+LogVMOutput
-XX:LogFile=../sonatype-work/nexus3/log/jvm.log
-XX:-OmitStackTraceInFastThrow
-Djava.net.preferIPv4Stack=true
-Dkaraf.home=.
-Dkaraf.base=.
-Dkaraf.etc=etc/karaf
-Djava.util.logging.config.file=etc/karaf/java.util.logging.properties
-Dkaraf.data=/nexus/nexus-data
-Djava.io.tmpdir=../sonatype-work/nexus3/tmp
-Dkaraf.startLocalConsole=false
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

Проверим доступность Web консоли Sonatype Nexus:
```bash
curl http://localhost:8081
```