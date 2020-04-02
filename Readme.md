# Kubernetes

## Topic 1: Understanding Kubernetes Architecture

Настраиваем подключение к кластеру Kubernetes:
```bash
minikube start --vm-driver=virtualbox
```

Проверим статус компонентов управляющей плоскости Kubernetes
```bash
kubectl get componentstatus
```

Создадим модуль "nginx" из описания:
```yaml
cat << EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx
EOF
```

Проверим, что модуль создался:
```bash
kubectl get pods
```

Изучим созданный модуль:
```bash
kubectl describe pods nginx
```

Удалим созданный модуль:
```bash
kubectl delete pod nginx
```

Создадим описание конфигурации развёртывания:
```bash
vi nginx.yaml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
```

Выведем созданное описание конфигурации развёртывания:
```bash
cat nginx.yaml
```

Создадим развёртывание из этого описания:
```bash
kubectl create -f nginx.yaml
```

Изучим созданное развёртывание:
```bash
kubectl get deployment nginx-deployment -o yaml
```

Выведем список созданных модулей с их метками:
```bash
kubectl get pods --show-labels
```

Пометим первый модуль из списка меткой "env=prod":
```bash
kubectl label pods $(kubectl get pods | grep nginx | head -n 1 | awk '{print $1}') env=prod
```

Выведем список созданных модулей с дополнительным столбцом наличия метки "env":
```bash
kubectl get pods -L env
```

Пометим развёртывание "nginx-deployment" аннотацией 'mycompany.com/someannotation="chad"':
```bash
kubectl annotate deployment nginx-deployment mycompany.com/someannotation="chad"
```

Изучим модифицированное развёртывание:
```bash
kubectl get deployment nginx-deployment -o yaml
```

Выведем список всех модулей в статусе "Running":
```bash
kubectl get pods --field-selector status.phase=Running
```

Выведем список всех сервисов в пространстве имён "default":
```bash
kubectl get services --field-selector metadata.namespace=default
```

Выведем список всех модулей, соответствующих двум условиям (статус "Running" и пространство имён "default"):
```bash
kubectl get pods --field-selector status.phase=Running,metadata.namespace=default
kubectl get pods --field-selector=status.phase==Running,metadata.namespace==default (тоже самое)
```

Выведем список всех модулей, не соответствующих обоим условиям (статус "Running" и пространство имён "default"):
```bash
kubectl get pods --field-selector=status.phase!=Running,metadata.namespace!=default
```

Изучим список созданных модулей:
```bash
kubectl get pods -o wide
```

Удалим первый модуль из списка:
```bash
kubectl delete pod $(kubectl get pods | grep nginx | head -n 1 | awk '{print $1}')
```

Проверим, что после удаления модуля запустилась его новая реплика:
```bash
kubectl get pods -o wide
```

Создадим описание службы для выставления модулей развёртывания "nginx-deployment" на одном из портов узлов кластера:
```bash
vi nginx-nodeport.yaml
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-nodeport
spec:
  type: NodePort
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 30080
  selector:
    app: nginx
```

Выведем созданное описание службы: 
```bash
cat nginx-nodeport.yaml
```

Создадим службу из этого описания:
```bash
kubectl create -f nginx-nodeport.yaml
```

Изучим список созданных служб:
```bash
kubectl get services
```

Изучим созданную службу:
```bash
kubectl get services nginx-nodeport
```

Проверим, что модули развёртывания "nginx-deployment" доступны на одном из портов узлов кластера:
```bash
curl $(minikube ip):30080
```

Изучим список созданных модулей:
```bash
kubectl get pods
```

Развернём модуль для отправки HTTP запросов внутри кластера:
```bash
cat << EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: busybox
spec:
  containers:
  - name: busybox
    image: radial/busyboxplus:curl
    args:
    - sleep
    - "1000"
EOF
```

Изучим список созданных модулей:
```bash
kubectl get pods -o wide
```

Изучим список созданных служб:
```bash
kubectl get services
```

Вызовем из модуля "busybox" службу "nginx-nodeport" по HTTP:
```bash
kubectl exec busybox -- curl $(kubectl get services | grep nginx-nodeport | awk '{print $3}'):80
```

Удаляем созданные ресурсы:
```bash
kubectl delete pod busybox
kubectl delete svc nginx-nodeport
kubectl delete deployment nginx-deployment
```

Останавливаем minikube:
```bash
minikube stop
```

#### Задание:
Развернуть приложение bookapp в minikube.

## Topic 2: Building the Kubernetes Cluster

Создаем описание серверов кластера:
```bash
vi Vagrantfile
```

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.ssh.insert_key = false

  config.vm.define "master" do |master|
    master.vm.box = "ubuntu/xenial64"
    master.vm.network "forwarded_port", guest: 80, host: 8080
    master.vm.network "forwarded_port", guest: 443, host: 8443
    master.vm.network "private_network", ip: "192.168.10.2"
    master.vm.hostname = "master"
    master.vm.provider "virtualbox" do |v|
      v.memory = 1024
      v.cpus = 1
    end
    master.vm.provision "shell", inline: <<-SHELL
      sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config    
      sudo systemctl restart sshd
      cat > /etc/hosts << EOF
127.0.0.1	localhost
255.255.255.255	broadcasthost
192.168.10.2 master
192.168.10.3 worker1
192.168.10.4 worker2
EOF
    SHELL
  end

  config.vm.define "worker1" do |worker1|
    worker1.vm.box = "ubuntu/xenial64"
    worker1.vm.network "forwarded_port", guest: 80, host: 8081
    worker1.vm.network "forwarded_port", guest: 443, host: 8444
    worker1.vm.network "private_network", ip: "192.168.10.3"
    worker1.vm.hostname = "worker1"
    worker1.vm.provider "virtualbox" do |v|
      v.memory = 1024
      v.cpus = 1
    end
    worker1.vm.provision "shell", inline: <<-SHELL
      sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config    
      sudo systemctl restart sshd
      cat > /etc/hosts << EOF
127.0.0.1	localhost
255.255.255.255	broadcasthost
192.168.10.2 master 
192.168.10.3 worker1 
192.168.10.4 worker2 
EOF
    SHELL
  end

  config.vm.define "worker2" do |worker2|
    worker2.vm.box = "ubuntu/xenial64"
    worker2.vm.network "forwarded_port", guest: 80, host: 8082
    worker2.vm.network "forwarded_port", guest: 443, host: 8445
    worker2.vm.network "private_network", ip: "192.168.10.4"
    worker2.vm.hostname = "worker2"
    worker2.vm.provider "virtualbox" do |v|
      v.memory = 1024
      v.cpus = 1
    end
    worker2.vm.provision "shell", inline: <<-SHELL
      sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config    
      sudo systemctl restart sshd
      cat > /etc/hosts << EOF
127.0.0.1	localhost
255.255.255.255	broadcasthost
192.168.10.2 master 
192.168.10.3 worker1 
192.168.10.4 worker2 
EOF
    SHELL
  end
end
```

Запускаем сервера кластера:
```bash
vagrant up
```

Проверяем подключение к серверам с помощью vagrant:
```bash
vagrant ssh master
vagrant ssh worker1
vagrant ssh worker2
```

### Следующие команды выполняются для всех трёх виртуальных машин

Добавляем ключ gpg для установки Docker:
```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
```

Добавляем репозиторий для установки Docker:
```bash
sudo add-apt-repository    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
```

Добавляем ключ gpg для установки Kubernetes:
```bash
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
```

Добавляем репозиторий для установки Kubernetes:
```bash
cat << EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
```

Обновляем пакеты:
```bash
sudo apt-get update
```

Устанавливаем Docker и компоненты Kubernetes:
```bash
sudo apt-get install -y docker-ce=18.06.1~ce~3-0~ubuntu kubelet=1.13.5-00 kubeadm=1.13.5-00 kubectl=1.13.5-00
```

Отключаем обновление Docker и компонентов Kubernetes:
```bash
sudo apt-mark hold docker-ce kubelet kubeadm kubectl
```

Добавляем правило для корректной работы iptables:
```bash
echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee -a /etc/sysctl.conf
```

Активируем iptables:
```bash
sudo sysctl -p
```

### Следующие команды выполняются на виртуальной машине master

Устанавливаем компоненты управляющей плоскости Kubernetes с помощью kubeadm:
```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.10.2 --ignore-preflight-errors=all
```

Настраиваем kubeconfig для текущего пользователя:
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Устанавливаем сетевой плагин для обеспечения межсетевого взаимодействия узлов кластера:
```bash
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

Редактируем сетевой интерфейс, выбираемый сетевым плагином по умолчанию:
```bash
kubectl edit daemonsets kube-flannel-ds-amd64 -n kube-system
```

```yaml
...
      - args:
        - --ip-masq
        - --kube-subnet-mgr
        - --iface=enp0s8
...
```

Копируем команду для добавления узлов кластера и сохраняем её в файл:
```bash
vi join
```

```bash
sudo kubeadm join [your unique string from the kubeadm init command] --ignore-preflight-errors=all
```

### Следующая команда выполняется на виртуальных машинах worker1 и worker2

Добавляем узлы worker1 и worker2 в кластер Kubernetes:
```bash
sudo kubeadm join [your unique string from the kubeadm init command] --ignore-preflight-errors=all
```

### Следующие команды выполняются на виртуальной машине master

Проверяем, что все узлы объеденены в кластер и доступны и работоспособны:
```bash
kubectl get nodes
```

Изучим компоненты текущего кластера (распределение модулей по узлам) в пространстве имён "kube-system":
```bash
kubectl get pods -o custom-columns=POD:metadata.name,NODE:spec.nodeName --sort-by spec.nodeName -n kube-system
```

Изучим ресурс конечных точек "kube-scheduler", который отвечает за выбор лидера:
```bash
kubectl get endpoints kube-scheduler -n kube-system -o yaml
```

Изучим содержание конфигурационного файла kubectl:
```bash
cat .kube/config | more
```

Изучим  секреты, созданные в пространстве имён "default":
```bash
kubectl get secrets
```

Создадим тестовое пространство имён:
```bash
kubectl create ns my-ns
```

Запустим в тестовом пространстве имён модуль с proxy к API Kubernetes:
```bash
kubectl run test --image=chadmcrowell/kubectl-proxy -n my-ns
```

Проверим, что модуль с proxy к API Kubernetes в тестовом пространстве имён успешно запущен:
```bash
kubectl get pods -n my-ns
```

Откроем терминал модуля с proxy к API Kubernetes в тестовом пространстве имён:
```bash
kubectl exec -it $(kubectl get pods -n my-ns | grep test | awk '{print $1}') -n my-ns sh
```

Проверим, что API Kubernetes доступно на localhost:
```bash
curl localhost:8001/api/v1/namespaces/my-ns/services
```

Изучим содержимое токена, смонтированного в контейнер модуля с proxy к API Kubernetes:
```bash
cat /var/run/secrets/kubernetes.io/serviceaccount/token
```

Изучим созданные сервисные аккаунты:
```bash
kubectl get serviceaccounts
```

Удалим созданное пространство имён:
```bash
kubectl delete ns my-ns
```

Создадим тестовый модуль для проверки работы кластера:
```bash
kubectl run nginx --image=nginx
```

Проверим, что создана конфигурация развёртывания для тестового модуля:
```bash
kubectl get deployments
```

Проверим, что тестовый модуль успешно запущен:
```bash
kubectl get pods
```

Перенаправим порт 80 тестового модуля на локальный порт 8081:
```bash
kubectl port-forward $(kubectl get pods | grep nginx | awk '{print $1}') 8081:80
```

Проверим, что тестовый модуль доступен на локальном порту 8081:
```bash
curl --head http://127.0.0.1:8081
```

Изучим логи тестового модуля:
```bash
kubectl logs $(kubectl get pods | grep nginx | awk '{print $1}')
```

Проверим, что мы можем подключаться к тестовому модулю и выполнять внутри него команды:
```bash
kubectl exec -it $(kubectl get po | grep nginx | awk '{print $1}') -- nginx -v
```

Создадим сервис для перенаправления трафика с одного из портов узлов кластера на тестовый модуль:
```bash
kubectl expose deployment nginx --port 80 --type NodePort
```

Изучим созданный сервис:
```bash
kubectl get services
```

Проверим, что тестовый модуль доступен через созданный сервис:
```bash
curl -I localhost:$(kubectl get services nginx -o jsonpath="{.spec.ports[0].nodePort}")
```

Проверим, что все узлы кластера готовы к работе:
```bash
kubectl get nodes
```

Изучим описание узлов:
```bash
kubectl describe nodes
```

Изучим описание созданных модулей:
```bash
kubectl describe pods
```

#### Задание:
Развернуть приложение bookapp в новом кластере Kubernetes.

## Topic 3: Managing the Kubernetes Cluster

Изучим версию API сервера:
```bash
kubectl version --short
```

Изучим версию узлов кластера:
```bash
kubectl describe nodes
```

Изучим версию компонентов плоскости управления кластера:
```bash
kubectl get po -l "component=kube-controller-manager" -o yaml -n kube-system
```

### Следующие команды выполняются на всех трёх узлах кластера

Снимаем фиксацию версии с компонентов "kubeadm" и "kubelet":
```bash
sudo apt-mark unhold kubeadm kubelet
```

Обновляем версию компонента "kubeadm" до "1.14.1":
```bash
sudo apt install -y kubeadm=1.14.1-00
```

Снова фиксируем версию компонента "kubeadm":
```bash
sudo apt-mark hold kubeadm
```

Проверяем версию компонента "kubeadm":
```bash
kubeadm version
```

### Следующие команды выполняются на узле master

Изучаем план обновления компонентов управляющей плоскости кластера Kubernetes:
```bash
sudo kubeadm upgrade plan
```

Производим обновление компонентов управляющей плоскости кластера Kubernetes до версии "1.14.1":
```bash
sudo kubeadm upgrade apply v1.14.1
```

### Следующие команды выполняются на всех трёх узлах кластера

Снимаем фиксацию версии с компонента "kubectl":
```bash
sudo apt-mark unhold kubectl
```

Обновляем версию компонента "kubectl" до "1.14.1":
```bash
sudo apt install -y kubectl=1.14.1-00
```

Снова фиксируем версию компонента "kubectl":
```bash
sudo apt-mark hold kubectl
```

Обновляем версию компонента "kubelet" до "1.14.1":
```bash
sudo apt install -y kubelet=1.14.1-00
```

Снова фиксируем версию компонента "kubelet":
```bash
sudo apt-mark hold kubelet
```

### Следующие команды выполняются на узле master

Изучим версию API сервера:
```bash
kubectl version --short
```

Изучим версию узлов кластера:
```bash
kubectl describe nodes
```

Изучим версию компонентов плоскости управления кластера:
```bash
kubectl get po -l "component=kube-controller-manager" -o yaml -n kube-system
```

Изучим созданные модули и их расположение на узлах кластера:
```bash
kubectl get pods -o wide
```

Переместим все модули с узла worker1 на другие свободные узлы:
```bash
kubectl drain worker1 --ignore-daemonsets
```

Изучим статус узлов:
```bash
kubectl get nodes
```

Вернём на узел worker1 возможность запускать модули:
```bash
kubectl uncordon worker1
```

Изучим статус узлов:
```bash
kubectl get nodes
```

Удалим узел worker1 из кластера:
```bash
kubectl delete node worker1
```

Изучим статус узлов:
```bash
kubectl get nodes
```

Создадим токен и выведем команду для добавления узлов в кластер:
```bash
sudo kubeadm token create $(sudo kubeadm token generate) --ttl 2h --print-join-command
```

### Следующая команда выполняется на узле worker1

Добавим узел worker1 в кластер:
```bash
sudo systemctl stop kubelet
sudo rm /etc/kubernetes/kubelet.conf /etc/kubernetes/bootstrap-kubelet.conf /etc/kubernetes/pki/ca.crt
sudo kubeadm join 192.168.10.2:6443 --token ...     --discovery-token-ca-cert-hash sha256:...
```

Изучим статус узлов:
```bash
kubectl get nodes
```

 Скачиваем архив с утилитой etcdctl:
```bash
wget https://github.com/etcd-io/etcd/releases/download/v3.3.12/etcd-v3.3.12-linux-amd64.tar.gz
```

Распаковываем ахив в домашнюю директорию:
```bash
tar xvf etcd-v3.3.12-linux-amd64.tar.gz
```

Перемещаем исполняемые файлы в директорию "/usr/local/bin":
```bash
sudo mv etcd-v3.3.12-linux-amd64/etcd* /usr/local/bin
```

С помощью утилиты etcdctl создаём снэпшот базы etcd:
```bash
sudo ETCDCTL_API=3 etcdctl snapshot save snapshot.db --cacert /etc/kubernetes/pki/etcd/server.crt --cert /etc/kubernetes/pki/etcd/ca.crt --key /etc/kubernetes/pki/etcd/ca.key
```

Проверяем, что снэпшот успешно создан:
```bash
ls -la
```

Изучим статус созданного снэпшота:
```bash
ETCDCTL_API=3 etcdctl --write-out=table snapshot status snapshot.db
```

Изучим состав директории с сертификатами etcd:
```bash
ls /etc/kubernetes/pki/etcd
```

Создадим архив директории с сертификатами etcd:
```bash
sudo tar -zcvf etcd.tar.gz /etc/kubernetes/pki/etcd
```

Перенесём бэкап etcd на один из рабочих узлов:
```bash
scp etcd.tar.gz snapshot.db vagrant@worker1:~/
```

## Topic 4: Cluster Communications

### Следующие команды выполняются на узле master

Определим, на каком из узлов создан тестовый модуль:
```bash
kubectl get pods -o wide
```

### Следующие команды выполняются на узле, где располагается тестовый модуль

Изучаем конфигурацию сети узла:
```bash
ifconfig
```

Изучаем список запущенных контейнеров:
```bash
sudo docker ps
```

Определяем PID контейнера, в котором запущен Nginx:
```bash
sudo docker inspect --format '{{ .State.Pid }}' $(sudo docker ps | grep nginx | grep -v pause | awk '{print $1}')
```

Определяем IP адрес тестового модуля:
```bash
sudo nsenter -t $(sudo docker inspect --format '{{ .State.Pid }}' $(sudo docker ps | grep nginx | grep -v pause | awk '{print $1}')) -n ip addr
```

Находим соответствующий интерфейс в конфигурации сети узла:
```bash
ifconfig
```

### Следующие команды выполняются на узле master

Создадим описание сервиса, предоставляющего доступ к тестовому модудю на одном из портов узлов кластера:
```bash
vi nginx-nodeport.yaml
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-nodeport
spec:
  type: NodePort
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 30080
  selector:
    run: nginx
```

Создадим сервис из описания:
```bash
kubectl create -f nginx-nodeport.yaml
```

Изучим описание созданного сервиса:
```bash
kubectl get services nginx-nodeport -o yaml
```

Проверим доступность Nginx по порту одного из узлов:
```bash
curl http://192.168.10.3:$(kubectl get svc nginx-nodeport -o jsonpath='{.spec.ports[].nodePort}')
```

Попробуем пропинговать созданный сервис по IP адресу:
```bash
ping $(kubectl get services nginx-nodeport -o jsonpath="{.spec.clusterIP}")
```

Изучим доступные сервисы:
```bash
kubectl get services
```

Изучим доступные конечные точки:
```bash
kubectl get endpoints
```

Найдём правила iptables, созданные для работы сервисов "nginx*":
```bash
sudo iptables-save | grep KUBE | grep nginx
```

Изучим доступные сервисы:
```bash
kubectl get services
```

Развернём в кластер эмулятор балансировщика нагрузки:
```bash
kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.3/manifests/metallb.yaml
```

Создадим описание конфигурации для эмулятора балансировщика нагрузки:
```bash
vi metallb-system.yaml
```

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 192.168.1.240-192.168.1.250
```

Создадим правила распределения трафика для эмулятора балансировщика нагрузки из описания:
```bash
kubectl create -f metallb-system.yaml
```

Создадим описание сервиса, предоставляющего доступ к тестовому модудю через внешний балансировщик нагрузки:
```bash
vi nginx-loadbalancer.yaml
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-loadbalancer
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
  selector:
    run: nginx
```

Создадим сервис из описания:
```bash
kubectl create -f nginx-loadbalancer.yaml
```

Проверим, что сервис с типом LoadBalancer создан и доступен по отдельному IP адресу:
```bash
kubectl get services
```

Проверим доступность тестового модуля через балансировщик нагрузки:
```bash
curl http://192.168.1.240
```

Создадим ещё один тестовый модуль:
```bash
kubectl run kubeserve2 --image=chadmcrowell/kubeserve2
```

Изучим созданные конфигурации развёртывания:
```bash
kubectl get deployments
```

Смасштабируем количество реплик созданного тестовго модуля до 2:
```bash
kubectl scale deployment/kubeserve2 --replicas=2
```

Изучим распределение тестовых модулей по узлам кластера:
```bash
kubectl get pods -o wide
```

Создадим сервис, предоставляющего доступ к новому тестовому модудю через внешний балансировщик нагрузки:
```bash
kubectl expose deployment kubeserve2 --port 80 --target-port 8080 --type LoadBalancer
```

Проверим, что сервис с типом LoadBalancer создан и доступен по отдельному IP адресу:
```bash
kubectl get services
```

Проверим доступность нового тестового модуля через балансировщик нагрузки:
```bash
curl http://192.168.1.241
```

Изучим конфигурацию созданного сервиса более подробно:
```bash
kubectl get services kubeserve2 -o yaml
```

Изучим аннотацию созданного сервиса:
```bash
kubectl describe services kubeserve
```

Добавим аннотацию для созданного сервиса чтобы обеспечить вызов локальных экземпляров модулей в случае если запрос пришёл на один из узлов, на которых размещены его экземпляры:
```bash
kubectl annotate service kubeserve2 externalTrafficPolicy=Local
```

Проверим, что теперь вызывается локальный экземпляр:
```bash
curl http://192.168.1.241
curl http://192.168.1.241
curl http://192.168.1.241
```

Создадим Ingress Controller:
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml
```

Создадим сервис для Ingress Controller'а:
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/baremetal/service-nodeport.yaml
```

Проверим, что Ingress Controller успешно запущен:
```bash
kubectl get pods --all-namespaces -l app.kubernetes.io/name=ingress-nginx --watch
```

Создадим описание правил распределения трафика для Ingress Controller'а:
```bash
vi service-ingress.yaml
```

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: service-ingress
spec:
  rules:
  - host: kubeserve2.example.com
    http:
      paths:
      - backend:
          serviceName: kubeserve2
          servicePort: 80
  - host: app.example.com
    http:
      paths:
      - backend:
          serviceName: nginx
          servicePort: 80
  - http:
      paths:
      - backend:
          serviceName: httpd
          servicePort: 80
```

Создадим правила распределения трафика для Ingress Controller'а: из описания:
```bash
kubectl apply -f service-ingress.yaml
```

Изучим созданные правила распределения трафика для Ingress Controller'а:
```bash
kubectl describe ingress
```

Создадим статический адрес для Ingress Controller'а:
```bash
kubectl expose deployments nginx-ingress-controller -n ingress-nginx --type LoadBalancer
```

Узнаем статический адрес, полученный Ingress Controller'ом:
```bash
kubectl get svc -n ingress-nginx
```

Добавляем имя хоста из правила распределения трафика в список известных хостов:
```bash
echo "192.168.1.242 kubeserve.example.com" >> /etc/hosts
echo "192.168.1.242 app.example.com" >> /etc/hosts
```

Проверим доступность нового тестового модуля через Ingress Controller:
```bash
curl http://app.example.com
curl http://kubeserve.example.com
```

Изучим модули управления кластером:
```bash
kubectl get pods -n kube-system
```

Изучим конфигурации развёртывания модулей управления кластером:
```bash
kubectl get deployments -n kube-system
```

Изучим сервисы модулей управления кластером:
```bash
kubectl get services -n kube-system
```

Создадим описание тестового модуля для тестирования DNS:
```bash
vi busybox.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: busybox
  namespace: default
spec:
  containers:
  - image: busybox:1.28.4
    command:
      - sleep
      - "3600"
    imagePullPolicy: IfNotPresent
    name: busybox
  restartPolicy: Always
```

Создадим правила распределения трафика для Ingress Controller'а из описания:
```bash
kubectl create -f busybox.yaml
```

Изучим конфигурацию DNS тестового модуля:
```bash
kubectl exec -it busybox -- cat /etc/resolv.conf
```

Выведем информацию о DNS записях хоста с именем kubernetes:
```bash
kubectl exec -it busybox -- nslookup kubernetes
```

Выведем информацию о DNS записях хоста с именем тествого модуля по умолчанию (надо заменить точки на тире!!!):
```bash
kubectl exec -ti busybox -- nslookup $(kubectl get po busybox -o jsonpath='{.status.podIP}').default.pod.cluster.local
```

Выведем информацию о DNS записях хоста с именем сервиса kube-dns:
```bash
kubectl exec -it busybox -- nslookup kube-dns.kube-system.svc.cluster.local
```

Изучим логи модуля DNS сервера:
```bash
kubectl logs $(kubectl get po -n kube-system | grep coredns | head -1 | awk '{print $1}') -n kube-system
```

Создадим описание сервиса без кластерного IP адреса для тестового модуля:
```bash
vi kube-headless.yaml
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kube-headless
spec:
  clusterIP: None
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: kubserve2
```

Создадим сервис без кластерного IP адреса для тестового модуля из описания:
```bash
kubectl create -f kube-headless.yaml
```

Изучим созданный сервис:
```bash
kubectl get svc kube-headless -o yaml
```

Создадим описание тестового модуля с пользовательской конфигурацией DNS:
```bash
vi dns-example.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  namespace: default
  name: dns-example
spec:
  containers:
    - name: test
      image: nginx
  dnsPolicy: "None"
  dnsConfig:
    nameservers:
      - 8.8.8.8
    searches:
      - ns1.svc.cluster.local
      - my.dns.search.suffix
    options:
      - name: ndots
        value: "2"
      - name: edns0
```

Создадим тестовый модуль с пользовательской конфигурацией DNS:
```bash
kubectl create -f dns-example.yaml
```

Изучим созданные модули:
```bash
kubectl get pods -o wide
```

Выведем информацию о DNS записях хоста с именем тествого модуля по умолчанию (надо заменить точки на тире!!!):
```bash
kubectl exec -ti busybox -- nslookup $(kubectl get po dns-example -o jsonpath='{.status.podIP}').default.pod.cluster.local
```

Изучим конфигурацию DNS тестового модуля:
```bash
kubectl exec -it dns-example -- cat /etc/resolv.conf
```

Удалим созданные артефакты:
```bash
kubectl delete ns metallb-system ingress-nginx
kubectl delete deployments kubeserve2 nginx
kubectl delete svc nginx-loadbalancer kubeserve2 kube-headless nginx nginx-nodeport
kubectl delete po busybox dns-example
```

#### Задание:
Создать ingress для приложения bookapp.

## Topic 5: Pod Scheduling within the Kubernetes Cluster

Пометим узел "worker1" меткой "availability-zone=zone1":
```bash
kubectl label node worker1 availability-zone=zone1
```

Пометим узел "worker2" меткой "share-type=dedicated":
```bash
kubectl label node worker2 share-type=dedicated
```

Создадим описание конфигурации развёртывания тестового модуля с 5 репликами и заданными правилами распределения по узлам:
```bash
vi pref-deployment.yaml
```

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: pref
spec:
  replicas: 5
  template:
    metadata:
      labels:
        app: pref
    spec:
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 80
            preference:
              matchExpressions:
              - key: availability-zone
                operator: In
                values:
                - zone1
          - weight: 20
            preference:
              matchExpressions:
              - key: share-type
                operator: In
                values:
                - dedicated
      containers:
      - args:
        - sleep
        - "99999"
        image: busybox
        name: main
```

Создадим конфигурацию развёртывания тестового модуля с 5 репликами и заданными правилами распределения по узлам:
```bash
kubectl create -f pref-deployment.yaml
```

Изучим созданную конфигурацию развёртывания:
```bash
kubectl get deployments
```

Изучим распределение созданных реплик тестового модуля:
```bash
kubectl get pods -o wide
```

Удаляем конфигурацию развёртывания нового тестового модуля:
```bash
kubectl delete -f pref-deployment.yaml
```

Создадим описание кластерной роли для пользовательского планировщика:
```bash
vi ClusterRole.yaml
```

```yaml
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: csinodes-admin
rules:
- apiGroups: ["storage.k8s.io"]
  resources: ["csinodes"]
  verbs: ["get", "watch", "list"]
```

Создадим кластерную роль для пользовательского планировщика:
```bash
kubectl create -f ClusterRole.yaml
```

Создадим описание привязки кластерной роли для пользовательского планировщика к соответствующему сервисному пользователю:
```bash
vi ClusterRoleBinding.yaml
```

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-csinodes-global
subjects:
- kind: ServiceAccount
  name: my-scheduler
  namespace: kube-system
roleRef:
  kind: ClusterRole
  name: csinodes-admin
  apiGroup: rbac.authorization.k8s.io
```

Создадим привязку кластерной роли для пользовательского планировщика к соответствующему сервисному пользователю:
```bash
kubectl create -f ClusterRoleBinding.yaml
```

Создадим описание роли для пользовательского планировщика в пространстве имён "kube-system":
```bash
vi Role.yaml
```

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: system:serviceaccount:kube-system:my-scheduler
  namespace: kube-system
rules:
- apiGroups:
  - storage.k8s.io
  resources:
  - csinodes
  verbs:
  - get
  - list
  - watch
```

Создадим роль для пользовательского планировщика в пространстве имён "kube-system":
```bash
kubectl create -f Role.yaml
```

Создадим описание привязки роли для пользовательского планировщика в пространстве имён "kube-system" к аккаунту "kubernetes-admin":
```bash
vi RoleBinding.yaml
```

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-csinodes
  namespace: kube-system
subjects:
- kind: User
  name: kubernetes-admin
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role 
  name: system:serviceaccount:kube-system:my-scheduler
  apiGroup: rbac.authorization.k8s.io
```

Создадим привязку роли для пользовательского планировщика в пространстве имён "kube-system" к аккаунту "kubernetes-admin":
```bash
kubectl create -f RoleBinding.yaml
```

Изменим описание кластерной роли "system:kube-scheduler" - добавим пользовательскому планировщику "my-scheduler" доступ к конечным точкам и добавим возможность просмотра API классов хранения:
```bash
kubectl edit clusterrole system:kube-scheduler
```

```yaml
...
- apiGroups:
  - ""
  resourceNames:
  - kube-scheduler
  - my-scheduler
  resources:
  - endpoints
...
- apiGroups:
  - storage.k8s.io
  resources:
  - storageclasses
  verbs:
  - watch
  - list
  - get
```

Создадим описание конфигурации развёртывания, сервисного пользователя и привязки к кластерной роли для пользовательского планировщика:
```bash
vi My-scheduler.yaml
```

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-scheduler
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: my-scheduler-as-kube-scheduler
subjects:
- kind: ServiceAccount
  name: my-scheduler
  namespace: kube-system
roleRef:
  kind: ClusterRole
  name: system:kube-scheduler
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    component: scheduler
    tier: control-plane
  name: my-scheduler
  namespace: kube-system
spec:
  selector:
    matchLabels:
      component: scheduler
      tier: control-plane
  replicas: 1
  template:
    metadata:
      labels:
        component: scheduler
        tier: control-plane
        version: second
    spec:
      serviceAccountName: my-scheduler
      containers:
      - command:
        - /usr/local/bin/kube-scheduler
        - --address=0.0.0.0
        - --leader-elect=false
        - --scheduler-name=my-scheduler
        image: chadmcrowell/custom-scheduler
        livenessProbe:
          httpGet:
            path: /healthz
            port: 10251
          initialDelaySeconds: 15
        name: kube-second-scheduler
        readinessProbe:
          httpGet:
            path: /healthz
            port: 10251
        resources:
          requests:
            cpu: '0.1'
        securityContext:
          privileged: false
        volumeMounts: []
      hostNetwork: false
      hostPID: false
      volumes: []
```

Создадим конфигурацию развёртывания, сервисного пользователя и привязку к кластерной роли для пользовательского планировщика:
```bash
kubectl create -f My-scheduler.yaml
```

Изучим развёрнутые модули в пространстве имён "kube-system":
```bash
kubectl get pods -n kube-system
```

Создадим описание тестового модуля без указания планировщика:
```bash
vi pod1.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: no-annotation
  labels:
    name: multischeduler-example
spec:
  containers:
  - name: pod-with-no-annotation-container
    image: k8s.gcr.io/pause:2.0
```

Создадим тестовый модуль без указания планировщика:
```bash
kubectl create -f pod1.yaml
```

Создадим описание тестового модуля с указанием планировщика по умолчанию:
```bash
vi pod2.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: annotation-default-scheduler
  labels:
    name: multischeduler-example
spec:
  schedulerName: default-scheduler
  containers:
  - name: pod-with-default-annotation-container
    image: k8s.gcr.io/pause:2.0
```

Создадим тестовый модуль с указанием планировщика по умолчанию:
```bash
kubectl create -f pod2.yaml
```

Создадим описание тестового модуля с указанием пользовательского планировщика:
```bash
vi pod3.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: annotation-second-scheduler
  labels:
    name: multischeduler-example
spec:
  schedulerName: my-scheduler
  containers:
  - name: pod-with-second-annotation-container
    image: k8s.gcr.io/pause:2.0
```

Создадим тестовый модуль с указанием пользовательского планировщика:
```bash
kubectl create -f pod3.yaml
```

Изучим созданные тестовые модули:
```bash
kubectl get pods -o wide
```

Удалим созданные тестовые модули:
```bash
kubectl delete -f pod1.yaml
kubectl delete -f pod2.yaml
kubectl delete -f pod3.yaml
```

Удалим созданный пользовательский планировщик:
```bash
kubectl delete -f My-scheduler.yaml
```

Изучим доступные на узлах ресурсы:
```bash
kubectl describe nodes
```

Создадим описание тестового модуля с указанием запроса ресурсов и узла:
```bash
vi resource-pod1.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-pod1
spec:
  nodeSelector:
    kubernetes.io/hostname: "worker2"
  containers:
  - image: busybox
    command: ["dd", "if=/dev/zero", "of=/dev/null"]
    name: pod1
    resources:
      requests:
        cpu: 700m
        memory: 20Mi
```

Создадим тестовый модуль с указанием запроса ресурсов и узла:
```bash
kubectl create -f resource-pod1.yaml
```

Изучим созданный модуль:
```bash
kubectl get pods -o wide
```

Создадим описание тестового модуля с указанием узла и запроса ресурсов, превышающего доступные ресурсы на узле:
```bash
vi resource-pod2.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-pod2
spec:
  nodeSelector:
    kubernetes.io/hostname: "worker2"
  containers:
  - image: busybox
    command: ["dd", "if=/dev/zero", "of=/dev/null"]
    name: pod2
    resources:
      requests:
        cpu: 900m
        memory: 20Mi
```

Создадим тестовый модуль с указанием узла и запроса ресурсов, превышающего доступные ресурсы на узле:
```bash
kubectl create -f resource-pod2.yaml
```

Изучим созданный модуль:
```bash
kubectl get pods -o wide
```

Изучим описание созданного модуля:
```bash
kubectl describe pods resource-pod2
```

Изучим описание узла, на котором мы пытаемся развернуть новый тестовый модуль:
```bash
kubectl describe nodes worker2
```

Удалим первый созданный тестовый модуль:
```bash
kubectl delete pods resource-pod1
```

Проверим, что новый тестовый модуль успешно запустился:
```bash
kubectl get pods -o wide -w
```

Создадим описание тестового модуля с указанием узла и лимита выделения ресурсов:
```bash
vi limited-pod.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: limited-pod
spec:
  containers:
  - image: busybox
    command: ["dd", "if=/dev/zero", "of=/dev/null"]
    name: main
    resources:
      limits:
        cpu: 700m
        memory: 20Mi
```

Создадим тестовый модуль с указанием узла и лимита выделения ресурсов:
```bash
kubectl create -f limited-pod.yaml
```

Проверим, что новый тестовый модуль успешно запустился:
```bash
kubectl get pods -o wide -w
```

Изучим текущую утилизацию ресурсов нового тестовго модуля:
```bash
kubectl exec -it limited-pod top
```

Изучим текущую утилизацию ресурсов нового тестовго модуля:
```bash
kubectl delete pods limited-pod resource-pod2
```

Изучим созданные модули в пространстве имён "kube-system":
```bash
kubectl get pods -n kube-system -o wide
```

Изучим удалим один из модулей "kube-proxy-*":
```bash
kubectl delete pods $(kubectl get pods -n kube-system | grep kube-proxy | head -1 | awk '{print $1}') -n kube-system
```

Проверим, что был создан новый модуль "kube-proxy-*":
```bash
kubectl get pods -n kube-system -o wide
```

Пометим узел "worker2" меткой "disk=ssd":
```bash
kubectl label node worker2 disk=ssd
```

Создадим описание набора демонов, который работает на узлах с меткой "disk: ssd":
```bash
vi ssd-monitor.yaml
```

```yaml
apiVersion: apps/v1beta2
kind: DaemonSet
metadata:
  name: ssd-monitor
spec:
  selector:
    matchLabels:
      app: ssd-monitor
  template:
    metadata:
      labels:
        app: ssd-monitor
    spec:
      nodeSelector:
        disk: ssd
      containers:
      - name: main
        image: linuxacademycontent/ssd-monitor
```

Создадим набор демонов, который работает на узлах с меткой "disk: ssd":
```bash
kubectl create -f ssd-monitor.yaml
```

Проверим, что на узле "worker2" был создан новый модуль "ssd-monitor-*":
```bash
kubectl get pods -o wide
```

Пометим узел "worker1" меткой "disk=ssd":
```bash
kubectl label node worker1 disk=ssd
```

Проверим, что на узле "worker1" был создан новый модуль "ssd-monitor-*":
```bash
kubectl get pods -o wide
```

Удалим метку "disk=ssd" с узла "worker1":
```bash
kubectl label node worker1 disk-
```

Проверим, что новый модуль "ssd-monitor-*" удалён с узла "worker1":
```bash
kubectl get pods -o wide
```

Изменим метку узла "worker2" на "disk=hdd":
```bash
kubectl label node worker2 disk=hdd --overwrite
```

Изучим метки узла "worker2":
```bash
kubectl get nodes worker2 --show-labels
```

Проверим, что все новые модули "ssd-monitor-*" удалены:
```bash
kubectl get pods -o wide
```

Удалим набор демонов "ssd-monitor":
```bash
kubectl delete daemonset ssd-monitor
```

Снова создадим несколько тестовых модулей для демонстрации событий планировщика:
```bash
kubectl create -f pod1.yaml
kubectl create -f pod2.yaml
```

Изучим созданные модули в пространстве имён "kube-system":
```bash
kubectl get pods -n kube-system
```

Изучим описание модуля планировщика в пространстве имён "kube-system":
```bash
kubectl describe pods kube-scheduler-master -n kube-system
```

Изучим события в пространстве имён "default":
```bash
kubectl get events
```

Изучим события в пространстве имён "kube-system":
```bash
kubectl get events -n kube-system
```

Удалим все созданные модули в пространстве имён "default":
```bash
kubectl delete pods --all
```

Удалим все созданные модули в пространстве имён "default":
```bash
kubectl get events -w
```

Изучим логи модуля планировщика:
```bash
kubectl logs kube-scheduler-master -n kube-system
```

#### Задание:
Для приложения bookapp задать лимиты и реквесты.

## Topic 6: Deploying Applications in the Kubernetes Cluster

Создадим описание конфигурации развёртывания тестового модуля:
```bash
vi kubeserve-deployment.yaml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kubeserve
spec:
  replicas: 3
  selector:
    matchLabels:
      app: kubeserve
  template:
    metadata:
      name: kubeserve
      labels:
        app: kubeserve
    spec:
      containers:
      - image: linuxacademycontent/kubeserve:v1
        name: app
```

Создадим конфигурацию развёртывания тестового модуля:
```bash
kubectl create -f kubeserve-deployment.yaml --record
```

Изучим статус развёртывания созданной конфигурации:
```bash
kubectl rollout status deployments kubeserve
```

Изучим созданный набор реплик:
```bash
kubectl get replicasets
```

Смасштабируем количество реплик тестового модуля до 5:
```bash
kubectl scale deployment kubeserve --replicas=5
```

Изучим созданные модули:
```bash
kubectl get pods
```

Создадим сервис для предоставления доступа к репликам конфигурации развёртывания на одном из портов рабочих узлов:
```bash
kubectl expose deployment kubeserve --port 80 --target-port 80 --type NodePort
```

Установим количество секунд, после прохождения которых развёрнутый модуль считается готовым к эксплуатации:
```bash
kubectl patch deployment kubeserve -p '{"spec": {"minReadySeconds": 10}}'
```

Изменим версию образа на "linuxacademycontent/kubeserve:v2":
```bash
vi kubeserve-deployment.yaml
```

```yaml
...
      containers:
      - image: linuxacademycontent/kubeserve:v2
        name: app
```

Обновим конфигурацию развёртывания тестового модуля:
```bash
kubectl apply -f kubeserve-deployment.yaml
```

Изменим обратно версию образа на "linuxacademycontent/kubeserve:v1":
```bash
vi kubeserve-deployment.yaml
```

```yaml
...
      containers:
      - image: linuxacademycontent/kubeserve:v1
        name: app
```

Заменим конфигурацию развёртывания тестового модуля:
```bash
kubectl replace -f kubeserve-deployment.yaml
```

Определим порт узла, на котором предоставлен доступ к репликам тестового модуля:
```bash
kubectl get svc kubeserve -o jsonpath='{.spec.ports[0].nodePort}'
```

### Следующая команда выполняется в отдельном терминале

Запустим цикл вызова тестового модуля по HTTP:
```bash
while true; do curl http://192.168.10.3:[nodePort]; done
```

Обновим образ в конфигурации развёртывания тестового модуля до версии "linuxacademycontent/kubeserve:v2" с указанием номера ревизии:
```bash
kubectl set image deployments/kubeserve app=linuxacademycontent/kubeserve:v2 --v 6
```

Изучим описание активного набора реплик:
```bash
kubectl describe replicasets $(kubectl get rs | grep -v NAME | grep -v 0 | awk '{print $1}')
```

Обновим образ в конфигурации развёртывания тестового модуля до версии "linuxacademycontent/kubeserve:v3", содержащей дефект:
```bash
kubectl set image deployment kubeserve app=linuxacademycontent/kubeserve:v3
```

Откатим изменения конфигурации развёртывания:
```bash
kubectl rollout undo deployments kubeserve
```

Изучим историю развёртываний тестового модуля:
```bash
kubectl rollout history deployment kubeserve
```

Откатим конфигурацию развёртывания до первоначальной версии:
```bash
kubectl rollout undo deployment kubeserve --to-revision=3
```

Остановим развёртывание для тестирования работоспособности новой версии:
```bash
kubectl rollout pause deployment kubeserve
```

Продолжим развёртывание после завершения тестирования:
```bash
kubectl rollout resume deployment kubeserve
```

Создадим описание конфигурации развёртывания тестового модуля с проверкой живости:
```bash
vi kubeserve-deployment-readiness.yaml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kubeserve
spec:
  replicas: 3
  selector:
    matchLabels:
      app: kubeserve
  minReadySeconds: 10
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
    type: RollingUpdate
  template:
    metadata:
      name: kubeserve
      labels:
        app: kubeserve
    spec:
      containers:
      - image: linuxacademycontent/kubeserve:v3
        name: app
        readinessProbe:
          periodSeconds: 1
          httpGet:
            path: /
            port: 80
```

Создадим конфигурацию развёртывания тестового модуля:
```bash
kubectl apply -f kubeserve-deployment-readiness.yaml
```

Изучим статус развёртывания новой версии тестового модуля тестового модуля:
```bash
kubectl rollout status deployment kubeserve
```

Изучим описание конфигурацию развёртывания тестового модуля:
```bash
kubectl describe deployment
```

Изучим описание неактивной реплики тестового модуля:
```bash
kubectl describe pod $(kubectl get pods | grep 0/1 | awk '{print $1}')
```

Создадим словарь конфигурации с двумя записями:
```bash
kubectl create configmap appconfig --from-literal=key1=value1 --from-literal=key2=value2
```

Изучим описание созданного словаря конфигурации:
```bash
kubectl get configmap appconfig -o yaml
```

Создадим описание тестового модуля, использующего словарь конфигурации для определения переменной окружения:
```bash
vi configmap-pod.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: configmap-pod
spec:
  containers:
  - name: app-container
    image: busybox:1.28
    command: ['sh', '-c', "echo $(MY_VAR) && sleep 3600"]
    env:
    - name: MY_VAR
      valueFrom:
        configMapKeyRef:
          name: appconfig
          key: key1
```

Создадим тестовый модуль, использующий словарь конфигурации для определения переменной окружения:
```bash
kubectl apply -f configmap-pod.yaml
```

Изучим логи созданного тестового модуля:
```bash
kubectl logs configmap-pod
```

Создадим описание тестового модуля, использующего словарь конфигурации в качестве постоянного тома:
```bash
vi configmap-volume-pod.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: configmap-volume-pod
spec:
  containers:
  - name: app-container
    image: busybox
    command: ['sh', '-c', "echo $(MY_VAR) && sleep 3600"]
    volumeMounts:
      - name: configmapvolume
        mountPath: /etc/config
  volumes:
    - name: configmapvolume
      configMap:
        name: appconfig
```

Создадим тестовый модуль, использующий словарь конфигурации в качестве постоянного тома:
```bash
kubectl apply -f configmap-volume-pod.yaml
```

Изучим директорию тестового модуля, в которую был смонтирован словарь конфигурации в качестве постоянного тома:
```bash
kubectl exec configmap-volume-pod -- ls /etc/config
```

Изучим один из файлов тестового модуля, смонтированный из словаря конфигурации:
```bash
kubectl exec configmap-volume-pod -- cat /etc/config/key1
```

Создадим описание секрета с двумя объектами типа "stringData":
```bash
vi appsecret.yaml
```

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: appsecret
stringData:
  cert: value
  key: value
```

Создадим секрет с двумя объектами типа "stringData":
```bash
kubectl apply -f appsecret.yaml
```

Создадим описание тестового модуля, использующего одно из значений секрета для определения переменной окружения:
```bash
vi secret-pod.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-pod
spec:
  containers:
  - name: app-container
    image: busybox
    command: ['sh', '-c', "echo Hello, Kubernetes! && sleep 3600"]
    env:
    - name: MY_CERT
      valueFrom:
        secretKeyRef:
          name: appsecret
          key: cert
```

Создадим тестовый модуль, использующий одно из значений секрета для определения переменной окружения:
```bash
kubectl apply -f secret-pod.yaml
```

Откроем сессию терминала внутри тестового модуля, использующего одно из значений секрета для определения переменной окружения:
```bash
kubectl exec -it secret-pod -- sh
```

Выведем значение заданной переменной окружения:
```bash
echo $MY_CERT
```

Создадим описание тестового модуля, использующего секрет в качестве постоянного тома:
```bash
vi secret-volume-pod.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-volume-pod
spec:
  containers:
  - name: app-container
    image: busybox
    command: ['sh', '-c', "echo $(MY_VAR) && sleep 3600"]
    volumeMounts:
      - name: secretvolume
        mountPath: /etc/certs
  volumes:
    - name: secretvolume
      secret:
        secretName: appsecret
```

Создадим тестовый модуль, использующий секрет в качестве постоянного тома:
```bash
kubectl apply -f secret-volume-pod.yaml
```

Изучим директорию тестового модуля, в которую был смонтирован секрет в качестве постоянного тома:
```bash
kubectl exec secret-volume-pod -- ls /etc/certs
```

Удалим конфигурацию развёртывания и сервис тестового модуля, а также отдельно созданные тестовые модули:
```bash
kubectl delete pods --all
kubectl delete deployment kubeserve
kubectl delete svc kubeserve
```

Создадим описание набора реплик с 3 репликами тестового модуля:
```bash
vi replicaset.yaml
```

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: myreplicaset
  labels:
    app: app
    tier: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      tier: frontend
  template:
    metadata:
      labels:
        tier: frontend
    spec:
      containers:
      - name: main
        image: linuxacademycontent/kubeserve
```

Создадим набор реплик с 3 репликами тестового модуля:
```bash
kubectl apply -f replicaset.yaml
```

Изучим созданный набор реплик:
```bash
kubectl get replicasets
```

Изучим созданные тестовые модули:
```bash
kubectl get pods
```

Создадим описание тестового модуля, содержащего метку, аналогичную набору реплик:
```bash
vi pod-replica.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod1
  labels:
    tier: frontend
spec:
  containers:
  - name: main
    image: linuxacademycontent/kubeserve
```

Создадим тестовый модуль, содержащий метку, аналогичную набору реплик:
```bash
kubectl apply -f pod-replica.yaml
```

Проверим, что 4-й тестовый модуль, содержащий метку, аналогичную набору реплик, удалён:
```bash
kubectl get pods -w
```

Удалим созданный набор реплик тестовых модулей:
```bash
kubectl delete replicaset myreplicaset
```

Создадим описание набора тестовых модулей из двух реплик, сохраняющих состояние:
```bash
vi statefulset.yaml
```

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: "nginx"
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Gi
```

Создадим набор тестовых модулей из двух реплик, сохраняющих состояние:
```bash
kubectl apply -f statefulset.yaml
```

Изучим созданный набор тестовых модулей из двух реплик, сохраняющих состояние:
```bash
kubectl get statefulsets
```

Изучим описание созданного набора тестовых модулей из двух реплик, сохраняющих состояние:
```bash
kubectl describe statefulsets
```

#### Задание:
Создать секрет со строкой подключения к БД и передать его в виде переменной окружения в приложение bookapp.

## Topic 7: Managing Data in the Kubernetes Cluster

Устанавливаем сервер NFS на сервер master:
```bash
sudo apt-get install -y nfs-kernel-server nfs-common
```

### Следующая команда выполняется на всех виртуальных машинах:

Устанавливаем сервер NFS клиент на всех серверах:
```bash
sudo apt-get install -y nfs-common
```

Создаём директории под постоянные тома:
```bash
sudo mkdir -p /home/data/persistent0{1,2,3,4,5}
```

Назначаем владельца и права доступа директориям под постоянные тома:
```bash
sudo chown nobody:nogroup -R /home/data/
sudo chmod 700 /home/data/persistent01
sudo chmod 700 /home/data/persistent02
sudo chmod 700 /home/data/persistent03
sudo chmod 700 /home/data/persistent04
sudo chmod 700 /home/data/persistent05
```

Добавляем созданные директории в список экспортируемых директорий NFS сервера:
```bash
sudo vi /etc/exports
```

```ini
/home/data/persistent01 *(rw,sync,no_subtree_check,no_root_squash)
/home/data/persistent02 *(rw,sync,no_subtree_check,no_root_squash)
/home/data/persistent03 *(rw,sync,no_subtree_check,no_root_squash)
/home/data/persistent04 *(rw,sync,no_subtree_check,no_root_squash)
/home/data/persistent05 *(rw,sync,no_subtree_check,no_root_squash)
```

Перезапускаем NFS сервер:
```bash
sudo /etc/init.d/nfs-kernel-server restart
```

Выведем список созданных точек монтирования NFS:
```bash
showmount -e
``` 

Создадим yaml описание для создания постоянного тома:
```bash
vim pv-01.yml
```

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv00001
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  nfs:
    path: /home/data/persistent01
    server: 192.168.10.2
  persistentVolumeReclaimPolicy: Recycle
```

Создадим постоянный том из описанного шаблона:
```bash
kubectl create -f pv-01.yml
```

Изучим созданный постоянный том:
```bash
kubectl get pv
```

Проверим, что одна реплика набора тестовых модулей из двух реплик, сохраняющих состояние, создалась:
```bash
kubectl get po
```

Изучим созданный запрос на постоянный том:
```bash
kubectl get pvc
```

Удалим набор тестовых модулей из двух реплик, сохраняющих состояние и его запросы на постоянный том:
```bash
kubectl delete statefulsets web
kubectl delete pvc www-web-1 www-web-0
```

Изучим постоянный том после удаления связанного с ним запроса:
```bash
kubectl get pv
```

Удалим постоянный том:
```bash
kubectl delete pv pv00001
```

Создадим описание тестового модуля с использованием постоянного тома NFS сервера:
```bash
vi mongodb-pod.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mongodb 
spec:
  volumes:
  - name: mongodb-data
    nfs:
      path: /home/data/persistent01
      server: 192.168.10.2
  containers:
  - image: mongo
    name: mongodb
    volumeMounts:
    - name: mongodb-data
      mountPath: /data/db
      readOnly: false
    ports:
    - containerPort: 27017
      protocol: TCP
```

Создадим тестовый модуль с использованием постоянного тома NFS сервера:
```bash
kubectl apply -f mongodb-pod.yaml
```

Изучим созданный тестовый модуль и определим узел, на котором он размещён:
```bash
kubectl get pods -o wide
```

Сохраняем данные в созданном тестовом модуле:
```bash
kubectl exec -it mongodb mongo
> use mystore
> db.foo.insert({name: 'foo'})
> db.foo.find()
> exit
```

Удаляем созданный тестовый модуль:
```bash
k delete pod mongodb
```

Создадим тестовый модуль с использованием постоянного тома NFS сервера заново:
```bash
kubectl apply -f mongodb-pod.yaml
```

Проверяем, что тестовый модуль размещён на другом узле (отличном от узла, на котором он был размещён в первый раз):
```bash
kubectl get pods -o wide
```

### (!!!) Следующая команда выполняется только в случае если узлы при размещении тестового модуля в первый и второй раз совпали

Перемещаем тестовый модуль на другой узел:
```bash
kubectl drain $(kubectl get pods mongodb -o jsonpath='{.spec.nodeName}') --ignore-daemonsets
kubectl apply -f mongodb-pod.yaml
kubectl uncordon $(kubectl get nodes | grep Disabled | awk '{print $1}')
```

Проверяем, что данные, сохранённые в созданном тестовом модуле, не утрачены после его удаления и пересоздания:
```bash
kubectl exec -it mongodb mongo
> use mystore
> db.foo.find()
> exit
```

Удалим тестовый модуль:
```bash
kubectl delete -f mongodb-pod.yaml
```

Создадим yaml описание для создания постоянного тома для MongoDB:
```bash
vi mongodb-persistentvolume.yaml
```

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mongodb-pv
spec:
  capacity: 
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
    - ReadOnlyMany
  persistentVolumeReclaimPolicy: Retain
  nfs:
    path: /home/data/persistent01
    server: 192.168.10.2
```

Создадим постоянный том  для MongoDB из описанного шаблона:
```bash
kubectl create -f mongodb-persistentvolume.yaml
```

Изучим созданный постоянный том:
```bash
kubectl get persistentvolumes
```

Создадим yaml описание для создания запроса на постоянный том для MongoDB:
```bash
vi mongodb-pvc.yaml
```

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongodb-pvc 
spec:
  resources:
    requests:
      storage: 1Gi
  accessModes:
  - ReadWriteOnce
  storageClassName: ""
```

Создадим запрос на постоянный том для MongoDB из описанного шаблона:
```bash
kubectl create -f mongodb-pvc.yaml
```

Изучим созданный запрос на постоянный том:
```bash
kubectl get pvc
```

Проверим, что постоянный том mongodb-pv привязан к созданному запросу на постоянный том:
```bash
kubectl get pv
```

Создадим yaml описание для создания тестового модуля, использующего запрос на постоянный том для MongoDB:
```bash
vi mongo-pvc-pod.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mongodb 
spec:
  containers:
  - image: mongo
    name: mongodb
    volumeMounts:
    - name: mongodb-data
      mountPath: /data/db
    ports:
    - containerPort: 27017
      protocol: TCP
  volumes:
  - name: mongodb-data
    persistentVolumeClaim:
      claimName: mongodb-pvc
```

Создадим тестовый модуль, использующий запрос на постоянный том для MongoDB:
```bash
kubectl create -f mongo-pvc-pod.yaml
```

Проверяем, что данные, сохранённые в постоянном томе, также доступны при использовании запроса на постоянный том:
```bash
kubectl exec -it mongodb mongo
> use mystore
> db.foo.find()
> exit
```

Изучим созданный постоянный том:
```bash
kubectl describe pv mongodb-pv
```

Изучим созданный запрос на постоянный том:
```bash
kubectl describe pvc mongodb-pvc
```

Удалим созданный запрос на постоянный том:
```bash
kubectl delete pvc mongodb-pvc
```

Изучим текущий статус удалённого запроса на постоянный том:
```bash
kubectl get pvc
```

Проверяем, что данные, сохранённые в постоянном томе, также доступны после удаления запроса на постоянный том:
```bash
kubectl exec -it mongodb mongo
> use mystore
> db.foo.find()
> exit
```

Удалим созданный тестовый модуль:
```bash
kubectl delete pod mongodb
```

Проверим, что запрос на постоянный том окончательно удалён:
```bash
kubectl get pvc
```

Проверим, что статус постоянного тома изменён:
```bash
kubectl get pv
```

Создадим папку на узле master для динамического предоставления постоянных томов:
```bash
sudo mkdir -p /storage/dynamic
```

Пометим узел master соответствующей меткой для развёртывания сервиса для динамического предоставления постоянных томов на базе NFS:
```bash
kubectl label node master role=master
```

Создаём сервисный аккаунт для данного сервиса:
```bash
kubectl create serviceaccount nfs-provisioner
```

Создаём кластерную роль для данного сервиса:
```bash
kubectl create clusterrole pv-reader --verb=get,list,watch,create,update,patch --resource=endpoints,events,persistentvolumeclaims,persistentvolumes,storageclasses,services
```

Создадим привязку сервисного аккаунта "nfs-provisioner" к кластерной роли "pv-reader":
```bash
kubectl create clusterrolebinding nfs-provisioner-pv --clusterrole=pv-reader --serviceaccount=default:nfs-provisioner
```

Создадим yaml описание конфигурации развёртывания и сервиса для динамического предоставления постоянных томов на базе NFS:
```bash
vi nfs-provisioner-deployment.yaml
```

```yaml
kind: Service
apiVersion: v1
metadata:
  name: nfs-provisioner
  labels:
    app: nfs-provisioner
spec:
  ports:
    - name: nfs
      port: 2049
    - name: mountd
      port: 20048
    - name: rpcbind
      port: 111
    - name: rpcbind-udp
      port: 111
      protocol: UDP
  selector:
    app: nfs-provisioner
---
kind: Deployment
apiVersion: apps/v1beta1
metadata:
  name: nfs-provisioner
spec:
  replicas: 1
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: nfs-provisioner
    spec:
      serviceAccountName: nfs-provisioner
      # The following toleration and nodeSelector will place the nfs provisioner on the master node
      tolerations:
      - key: "node-role.kubernetes.io/master"
        operator: "Exists"
        effect: "NoSchedule"
      nodeSelector:
        role: master
      containers:
        - name: nfs-provisioner
          image: quay.io/kubernetes_incubator/nfs-provisioner:v1.0.8
          ports:
            - name: nfs
              containerPort: 2049
            - name: mountd
              containerPort: 20048
            - name: rpcbind
              containerPort: 111
            - name: rpcbind-udp
              containerPort: 111
              protocol: UDP
          securityContext:
            capabilities:
              add:
                - DAC_READ_SEARCH
                - SYS_RESOURCE
          args:
            - "-provisioner=example.com/nfs"
          env:
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
            - name: SERVICE_NAME
              value: nfs-provisioner
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
          imagePullPolicy: "IfNotPresent"
          volumeMounts:
          - name: export-volume
            mountPath: /export
      volumes:
      - name: export-volume
        hostPath:
          path: /storage/dynamic
```

Создадим конфигурацию развёртывания и сервиса для динамического предоставления постоянных томов на базе NFS:
```bash
kubectl create -f nfs-provisioner-deployment.yaml
```

Создадим yaml описание для создания класса хранилища для динамического предоставления постоянных томов на базе NFS:
```bash
vi nfs-class.yaml
```

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: nfs-dynamic
provisioner: example.com/nfs
```

Создадим класс хранилища для динамического предоставления постоянных томов на базе NFS:
```bash
kubectl create -f nfs-class.yaml
```

Изучим созданный класс хранилища:
```bash
kubectl get sc
```

Создадим yaml описание для создания запроса на постоянный том с использованием созданного класса хранилища:
```bash
vi nfs-test-claim.yaml
```

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: nfs
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Mi
  storageClassName: nfs-dynamic
```

Создадим запрос на постоянный том с использованием созданного класса хранилища:
```bash
kubectl create -f nfs-test-claim.yaml
```

Изучим созданный запрос на постоянный том:
```bash
kubectl get pvc
```

Изучим созданный постоянный том:
```bash
kubectl get pv
```

Удалим созданные постоянные тома и запросы на них:
```bash
kubectl delete pvc nfs
kubectl delete pv $(kubectl get pv | grep -v NAME | awk '{print $1}')
```

Создадим yaml описание для создания запроса на постоянный том для нового тестового модуля:
```bash
vi kubeserve-pvc.yaml
```

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: kubeserve-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
  storageClassName: nfs-dynamic
```

Создадим запрос на постоянный том для нового тестового модуля:
```bash
kubectl create -f kubeserve-pvc.yaml
```

Изучим созданный запрос на постоянный том:
```bash
kubectl get pvc
```

Изучим созданный постоянный том:
```bash
kubectl get pv
```

Создадим yaml описание для создания конфигурации развёртывания нового тестового модуля:
```bash
vi kubeserve-deployment-pv.yaml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kubeserve
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kubeserve
  template:
    metadata:
      name: kubeserve
      labels:
        app: kubeserve
    spec:
      containers:
      - env:
        - name: app
          value: "1"
        image: linuxacademycontent/kubeserve:v1
        name: app
        volumeMounts:
        - mountPath: /data
          name: volume-data
      volumes:
      - name: volume-data
        persistentVolumeClaim:
          claimName: kubeserve-pvc
```

Создадим конфигурацию развёртывания нового тестового модуля:
```bash
kubectl create -f kubeserve-deployment-pv.yaml
```

Изучим статус запущенного развёртывания:
```bash
kubectl rollout status deployments kubeserve
```

Изучим созданный тестовый модуль:
```bash
kubectl get pods
```

Создадим файл внутри директории нового тестового модуля, в которую примонтирован постоянный том:
```bash
kubectl exec -it $(kubectl get pods | grep kubeserve | awk '{print $1}') -- touch /data/file1.txt
```

Проверим, что файл внутри директории нового тестового модуля, в которую примонтирован постоянный том, успешно создан:
```bash
kubectl exec -it $(kubectl get pods | grep kubeserve | awk '{print $1}') -- ls /data
```

Проверим, что файл, созданный внутри нового тестового модуля, есть на файловой системе узла master:
```bash
find /storage/dynamic -name file1.txt
```

Удалим созданные конфигурации развёртывания, сервисы, заявки на постоянные тома и постоянные тома:
```bash
kubectl delete deployments kubeserve
kubectl delete svc nfs-provisioner
kubectl delete deployments --all
kubectl delete pvc --all
kubectl delete pv --all
```

#### Задание:
Развернуть PodtgreSQL в виде StatefulSet с томом в директории, в которой хранятся данные БД. Сохранить книгу в БД, удалить под PodtgreSQL и проверить, что после запуска нового пода данные вновь доступны.

## Topic 8: Securing the Kubernetes Cluster

Изучим имеющиеся сервисные аккаунты пространства имён "default":
```bash
kubectl get serviceaccounts
```

Создадим в пространстве имён "default" сервисный аккаунт "jenkins":
```bash
kubectl create serviceaccount jenkins
```

Изучим созданный сервисный аккаунт:
```bash
kubectl get sa
```

Изучим YAML описание созданного сервисного аккаунта:
```bash
kubectl get serviceaccounts jenkins -o yaml
```

Изучим секретный токен, автоматически привязанный к созданному сервисному аккаунту:
```bash
kubectl get secret $(kubectl get serviceaccounts jenkins -o jsonpath='{.secrets[].name}')
```

Создадим yaml описание для создания тестового модуля, запускаемого под сервисным аккаунтом "jenkins":
```bash
vi busybox-sa.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: busybox
  namespace: default
spec:
  serviceAccountName: jenkins
  containers:
  - image: busybox:1.28.4
    command:
      - sleep
      - "3600"
    imagePullPolicy: IfNotPresent
    name: busybox
  restartPolicy: Always
```

Создадим тестовый модуль, запускаемый под сервисным аккаунтом "jenkins":
```bash
kubectl create -f busybox-sa.yaml
```

Проверим, что тестовый модуль успешно создан:
```bash
kubectl get po
```

Проверим, что тестовый модуль успешно создан:
```bash
kubectl get po busybox -o yaml
```

Изучим конфигурацию kubectl:
```bash
kubectl config view
```

Выведем конфигурацию kubectl напрямую из конфигурационного файла:
```bash
cat ~/.kube/config
```

Добавим нового пользователя в конфигурацию нашего кластера:
```bash
kubectl config set-credentials chad --username=chad --password=password
```

Временно дадим права администратора кластера анонимным пользователям:
```bash
kubectl create clusterrolebinding cluster-system-anonymous --clusterrole=cluster-admin --user=system:anonymous
```

Добавим нового пользователя в конфигурацию kubectl:
```bash
kubectl config set-credentials chad --username=chad --password=password
```

### Следующие команды выполняются на узле worker1

Зададим настройки кластера для конфигурации kubectl:
```bash
kubectl config set-cluster kubernetes --server=https://192.168.10.2:6443 --certificate-authority=/etc/kubernetes/pki/ca.crt --embed-certs=true
```

Добавим пользователя для конфигурации kubectl:
```bash
kubectl config set-credentials chad --username=chad --password=password
```

Зададим контекст для конфигурации kubectl:
```bash
kubectl config set-context kubernetes --cluster=kubernetes --user=chad --namespace=default
```

Используем заданный контекст для конфигурации kubectl:
```bash
kubectl config use-context kubernetes
```

Проверим, что kubectl сконфигурирован корректно:
```bash
kubectl get nodes
```

Удалим ранее созданный тестовый модуль:
```bash
kubectl delete po busybox
```

Удалим ранее созданную привязку кластерной роли:
```bash
kubectl delete clusterrolebinding cluster-system-anonymous
```

Проверим, что доступ анонимным пользователям заблокирован:
```bash
kubectl get nodes
```

### Следующие команды выполняются на узле master

Создадим новое пространство имён:
```bash
kubectl create ns web
```

Создадим yaml описание для роли в пространстве имён "web", позволяющей просматривать список сервисов данного пространства имён:
```bash
vi role-new.yaml
```

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: web
  name: service-reader
rules:
- apiGroups: [""]
  verbs: ["get", "list"]
  resources: ["services"]
```

Создадим роль в пространстве имён "web", позволяющую просматривать список сервисов данного пространства имён:
```bash
kubectl create -f role-new.yaml
```

Создадим привязку сервисного аккаунта "web:default" к созданной роли "service-reader":
```bash
kubectl create rolebinding test --role=service-reader --serviceaccount=web:default -n web
```

Запустим локальный прокси сервер Kubernetes API для проверки доступности вывода списка сервисов в пространсте имён "web" (доступно без создания роли и привязки ролей):
```bash
kubectl proxy
```

Запросим список сервисов пространства имён "web":
```bash
curl localhost:8001/api/v1/namespaces/web/services
```

Создадим кластерную роль для просмотра списка постоянных томов в кластере:
```bash
kubectl create clusterrole persistent-volume-reader --verb=get,list --resource=persistentvolumes
```

Создадим привязку сервисного аккаунта "web:default" к кластерной роли "persistent-volume-reader" для просмотра списка постоянных томов в кластере:
```bash
kubectl create clusterrolebinding pv-test --clusterrole=persistent-volume-reader --serviceaccount=web:default
```

Создадим yaml описание для тестового модуля в пространстве имён "web", имеющего возможность обращаться к API Kubernetes:
```bash
vi curl-pod.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: curlpod
  namespace: web
spec:
  containers:
  - image: tutum/curl
    command: ["sleep", "9999999"]
    name: main
  - image: linuxacademycontent/kubectl-proxy
    name: proxy
  restartPolicy: Always
```

Создадим тестовый модуль в пространстве имён "web", имеющий возможность обращаться к API Kubernetes:
```bash
kubectl apply -f curl-pod.yaml
```

Изучим созданный тестовый модуль:
```bash
kubectl get pods -n web
```

Создадим SSH сессию к тестовому модулю:
```bash
kubectl exec -it curlpod -n web -- sh
```

Отправим запрос к API Kubernetes для вывода списка постоянных томов кластера:
```bash
curl localhost:8001/api/v1/persistentvolumes
```

Удалим созданное пространство имён:
```bash
kubectl delete ns web
```

#### Задание:
Создать отдельные Service Account для PodtgreSQL и bookapp и добавить в их Deployment и StatefulSet использование данных аккаунтов вместо аккаунтов по умолчанию.

Скачиваем yaml описание сетевого плагина "Canal", позволяющего настраивать сетевые политики:
```bash
wget -O canal.yaml https://docs.projectcalico.org/v3.5/getting-started/kubernetes/installation/hosted/canal/canal.yaml
```

Устанавливаем сетевой плагин "Canal" в наш кластер Kubernetes:
```bash
kubectl apply -f canal.yaml
```

Редактируем сетевой интерфейс, выбираемый сетевым плагином по умолчанию:
```bash
kubectl edit daemonsets canal -n kube-system
```

```yaml
...
      - args:
        - --ip-masq
        - --kube-subnet-mgr
        - --iface=enp0s8
...
```

Создадим yaml описание сетевой политики, запрещающей любые комуникации в модули текущего пространства имён:
```bash
vi deny-all.yaml
```

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

Создадим сетевую политику, запрещающую любые комуникации внутри пространства имён "default":
```bash
kubectl apply -f deny-all.yaml
```

Создадим тестовый модуль в пространстве имён "default":
```bash
kubectl run nginx --image=nginx --replicas=2
```

Создадим сервис для тестового модуля в пространстве имён "default":
```bash
kubectl expose deployment nginx --port=80
```

Создадим ещё один тестовый модуль для проверки работы сетевой политики:
```bash
kubectl run busybox --rm -it --image=busybox /bin/sh
```

Проверим доступность первого тестового модуля через сервис:
```bash
/ # wget --spider --timeout=1 nginx
```

Удалим тестовые модули:
```bash
kubectl delete deployment nginx
kubectl delete svc nginx
```

Создадим новый тестовый модуль с базой данных:
```bash
kubectl run postgres --image=postgres:alpine --replicas=1 --labels=app=db --env=POSTGRES_PASSWORD=mysecretpassword --port=5432
```

Создадим сервис для тестового модуля с базой данных:
```bash
kubectl expose deployment postgres --port=5432
```

Создадим ещё один тестовый модуль для проверки работы ранее созданной сетевой политики:
```bash
kubectl run psql --rm -it --image=governmentpaas/psql --labels=app=web /bin/sh
```

Проверим недоступность доступность первого тестового модуля через сервис:
```bash
/ # psql -h postgres -U postgres
```

Создадим yaml описание сетевой политики, разрешающей сетевое взаимодействие между модулями с меткой "app: web" и портом "5432" модулей с меткой "app: db":
```bash
vi db-netpolicy.yaml
```

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-netpolicy
spec:
  podSelector:
    matchLabels:
      app: db
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: web
    ports:
    - port: 5432
```

Создадим сетевую политику, разрешающую сетевое взаимодействие между модулями с меткой "app: web" и портом "5432" модулей с меткой "app: db":
```bash
kubectl apply -f db-netpolicy.yaml
```

Создадим ещё один тестовый модуль для проверки работы сетевой политики:
```bash
kubectl run psql --rm -it --image=governmentpaas/psql --labels=app=web /bin/sh
```

Проверим доступность первого тестового модуля через сервис (password - mysecretpassword):
```bash
/ # psql -h postgres -U postgres
```

Удалим созданную сетевую политику:
```bash
kubectl delete -f db-netpolicy.yaml
```

Создадим yaml описание сетевой политики, разрешающей сетевое взаимодействие между модулями в пространствах имён с меткой "tenant: web" и портом "5432" модулей с меткой "app: db":
```bash
vi ns-netpolicy.yaml
```

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ns-netpolicy
spec:
  podSelector:
    matchLabels:
      app: db
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          tenant: web
    ports:
    - port: 5432
```

Создадим сетевую политику, разрешающую сетевое взаимодействие между модулями в пространствах имён с меткой "tenant: web" и портом "5432" модулей с меткой "app: db":
```bash
kubectl apply -f ns-netpolicy.yaml
```

Создадим сетевую политику, разрешающую сетевое взаимодействие между модулями в пространствах имён с меткой "tenant: web" и портом "5432" модулей с меткой "app: db":
```bash
kubectl label ns default tenant=web
```

Создадим ещё один тестовый модуль для проверки работы сетевой политики:
```bash
kubectl run psql --rm -it --image=governmentpaas/psql /bin/sh
```

Проверим доступность первого тестового модуля через сервис (password - mysecretpassword):
```bash
/ # psql -h postgres -U postgres
```

Удалим созданную сетевую политику:
```bash
kubectl delete -f ns-netpolicy.yaml
```

Создадим yaml описание сетевой политики, разрешающей сетевое взаимодействие между модулями в пространствах имён с меткой "tenant: web" и портом "5432" модулей с меткой "app: db":
```bash
vi ipblock-netpolicy.yaml
```

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ipblock-netpolicy
spec:
  podSelector:
    matchLabels:
      app: db
  ingress:
  - from:
    - ipBlock:
        cidr: 10.244.2.0/24
```

Создадим сетевую политику, разрешающую сетевое взаимодействие между модулями в пространствах имён с меткой "tenant: web" и портом "5432" модулей с меткой "app: db":
```bash
kubectl apply -f ipblock-netpolicy.yaml
```

Создадим ещё один тестовый модуль для проверки работы сетевой политики:
```bash
kubectl run psql --rm -it --image=governmentpaas/psql /bin/sh
```

Проверим доступность первого тестового модуля через сервис (password - mysecretpassword):
```bash
/ # psql -h postgres -U postgres
```

Удалим созданную сетевую политику:
```bash
kubectl delete -f ipblock-netpolicy.yaml
```

Изменим yaml описание сетевой политики, запрещающей любые комуникации из модулей текущего пространства имён:
```bash
vi deny-all.yaml
```

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Egress
```

Создадим сетевую политику, запрещающую любые комуникации внутри пространства имён "default":
```bash
kubectl apply -f deny-all.yaml
```

Создадим ещё один тестовый модуль для проверки работы сетевой политики:
```bash
kubectl run psql --rm -it --image=governmentpaas/psql --labels=app=web /bin/sh
```

Проверим недоступность первого тестового модуля через сервис:
```bash
/ # psql -h postgres -U postgres
```

Создадим yaml описание сетевой политики, разрешающей сетевое взаимодействие для всех модулей пространства имён с DNS сервером Kubernetes:
```bash
vi egress-dns.yaml
```

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-access
spec:
  podSelector:
    matchLabels: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
```

Создадим сетевую политику, разрешающую сетевое взаимодействие для всех модулей пространства имён с DNS сервером Kubernetes:
```bash
kubectl apply -f egress-dns.yaml
```

Создадим yaml описание сетевой политики, разрешающей сетевое взаимодействие между модулями с меткой "app: web" и портом "5432" модулей с меткой "app: db":
```bash
vi egress-netpol.yaml
```

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: egress-netpol
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: db
    ports:
    - port: 5432
```

Создадим сетевую политику, разрешающую сетевое взаимодействие между модулями с меткой "app: web" и портом "5432" модулей с меткой "app: db":
```bash
kubectl apply -f egress-netpol.yaml
```

Создадим ещё один тестовый модуль для проверки работы сетевой политики:
```bash
kubectl run psql --rm -it --image=governmentpaas/psql --labels=app=web /bin/sh
```

Проверим доступность первого тестового модуля через сервис (password - mysecretpassword):
```bash
/ # psql -h postgres -U postgres
```

Удалим созданные сетевые политики:
```bash
kubectl delete -f egress-netpol.yaml
kubectl delete -f deny-all.yaml
kubectl delete -f egress-dns.yaml
```

Удалим созданную конфигурацию развёртывания и сервис:
```bash
kubectl delete deployments postgres
kubectl delete svc postgres
```

#### Задание:
Создать отдельные сетевые политики (Ingress и Egress) для PodtgreSQL и bookapp, разрешающие для всех доступ к внутреннему DNS, разрешающие внешний доступ к bookapp откуда угодно, разрешающие  доступ из bookapp в PodtgreSQL и запрещающие всё остальное.

Создадим тестовый модуль без использования контекста безопасности:
```bash
kubectl run pod-with-defaults --image alpine --restart Never -- /bin/sleep 999999
```

Проверим, что тестовый модуль успешно создан:
```bash
kubectl get pods
```

Выведем идентификатор пользователя, под которым запущен корневой процесс созданного тестового модуля:
```bash
kubectl exec pod-with-defaults id
```

Создадим описание тестового модуля, запускающего корневой процесс под пользователем с заданным идентификатором:
```bash
vi alpine-user-context.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: alpine-user-context
spec:
  containers:
  - name: main
    image: alpine
    command: ["/bin/sleep", "999999"]
    securityContext:
      runAsUser: 405
```

Создадим тестовый модуль, запускающий корневой процесс под пользователем с заданным идентификатором:
```bash
kubectl apply -f alpine-user-context.yaml
```

Проверим, что тестовый модуль успешно создан:
```bash
kubectl get pods
```

Выведем идентификатор пользователя, под которым запущен корневой процесс созданного тестового модуля:
```bash
kubectl exec alpine-user-context id
```

Создадим описание тестового модуля с контекстом безопасности, запрещающим запуск корневого процесса под пользователем "root":
```bash
vi alpine-nonroot.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: alpine-nonroot
spec:
  containers:
  - name: main
    image: alpine
    command: ["/bin/sleep", "999999"]
    securityContext:
      runAsNonRoot: true
```

Создадим тестовый модуль с контекстом безопасности, запрещающим запуск корневого процесса под пользователем "root":
```bash
kubectl apply -f alpine-nonroot.yaml
```

Проверим, что тестовый модуль создан, но не запущен:
```bash
kubectl get pods
```

Изучим ошибку запуска тестового модуля:
```bash
kubectl describe pod alpine-nonroot
```

Создадим описание тестового модуля с контекстом безопасности, разрешающим запуск модуля в привелегированном режиме:
```bash
vi privileged-pod.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: privileged-pod
spec:
  containers:
  - name: main
    image: alpine
    command: ["/bin/sleep", "999999"]
    securityContext:
      privileged: true
```

Создадим тестовый модуль с контекстом безопасности, разрешающим запуск модуля в привелегированном режиме:
```bash
kubectl apply -f privileged-pod.yaml
```

Проверим, что тестовый модуль успешно создан:
```bash
kubectl get pods
```

Изучим список девайсов, доступных стандартному модулю:
```bash
kubectl exec -it pod-with-defaults ls /dev
```

Изучим список девайсов, доступных модулю, запущенному в привелегированном режиме:
```bash
kubectl exec -it privileged-pod ls /dev
```

Проверим, что смена даты не доступна в стандартном модуле:
```bash
kubectl exec -it pod-with-defaults -- date +%T -s "12:00:00"
```

Создадим описание тестового модуля с контекстом безопасности, расширяющем стандартные возможности модуля (добавлена возможность изменения системного времени):
```bash
vi kernelchange-pod.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kernelchange-pod
spec:
  containers:
  - name: main
    image: alpine
    command: ["/bin/sleep", "999999"]
    securityContext:
      capabilities:
        add:
        - SYS_TIME
```

Создадим тестовый модуль с контекстом безопасности, расширяющем стандартные возможности модуля (добавлена возможность изменения системного времени):
```bash
kubectl apply -f kernelchange-pod.yaml
```

Проверим, что тестовый модуль успешно создан:
```bash
kubectl get pods
```

Проверим, что смена даты доступна в новом тестовом модуле:
```bash
kubectl exec -it kernelchange-pod -- date +%T -s "12:00:00"
```

Изучим системную дату в новом тестовом модуле после изменения:
```bash
kubectl exec -it kernelchange-pod -- date
```

Создадим описание тестового модуля с контекстом безопасности, сужающим стандартные возможности модуля (удалена возможность определения владельца директорий внутри модуля):
```bash
vi remove-capabilities.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: remove-capabilities
spec:
  containers:
  - name: main
    image: alpine
    command: ["/bin/sleep", "999999"]
    securityContext:
      capabilities:
        drop:
        - CHOWN
```

Создадим тестовый модуль с контекстом безопасности, сужающим стандартные возможности модуля (удалена возможность определения владельца директорий внутри модуля):
```bash
kubectl apply -f remove-capabilities.yaml
```

Проверим, что тестовый модуль успешно создан:
```bash
kubectl get pods
```

Проверим, что определение владельца директорий внутри модуля не доступно:
```bash
kubectl exec remove-capabilities chown guest /tmp
```

Создадим описание тестового модуля с контекстом безопасности, запрещающим запись в основную файловую систему модуля и предоставляющим возможность записи в смонтированный том:
```bash
vi readonly-pod.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: readonly-pod
spec:
  containers:
  - name: main
    image: alpine
    command: ["/bin/sleep", "999999"]
    securityContext:
      readOnlyRootFilesystem: true
    volumeMounts:
    - name: my-volume
      mountPath: /volume
      readOnly: false
  volumes:
  - name: my-volume
    emptyDir: {}
```

Создадим тестовый модуль с контекстом безопасности, запрещающим запись в основную файловую систему модуля и предоставляющим возможность записи в смонтированный том:
```bash
kubectl apply -f readonly-pod.yaml
```

Проверим, что тестовый модуль успешно создан:
```bash
kubectl get pods
```

Проверим, что запись в основную файловую систему модуля не доступно:
```bash
kubectl exec -it readonly-pod touch /new-file
```

Проверим, что запись в смонтированный том модуля доступна:
```bash
kubectl exec -it readonly-pod touch /volume/newfile
```

Изучим созданный файл в смонтированном томе тестового модуля:
```bash
kubectl exec -it readonly-pod -- ls -la /volume/newfile
```

Создадим описание тестового модуля с контекстом безопасности, определяющим группу файловой системы на уровне модуля и двух различных пользователей файловой системы для каждого из двух контейнеров:
```bash
vi group-context.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: group-context
spec:
  securityContext:
    fsGroup: 555
    supplementalGroups: [666, 777]
  containers:
  - name: first
    image: alpine
    command: ["/bin/sleep", "999999"]
    securityContext:
      runAsUser: 1111
    volumeMounts:
    - name: shared-volume
      mountPath: /volume
      readOnly: false
  - name: second
    image: alpine
    command: ["/bin/sleep", "999999"]
    securityContext:
      runAsUser: 2222
    volumeMounts:
    - name: shared-volume
      mountPath: /volume
      readOnly: false
  volumes:
  - name: shared-volume
    emptyDir: {}
```

Создадим тестовый модуль с контекстом безопасности, определяющим группу файловой системы на уровне модуля и двух различных пользователей файловой системы для каждого из двух контейнеров:
```bash
kubectl apply -f group-context.yaml
```

Проверим, что тестовый модуль успешно создан:
```bash
kubectl get pods
```

Откроем терминальную сессию к контейнеру "first" тестового модуля и изучим его идентификатор пользователя и владельцев, присваеваемых файлам при их создании в различных частях файловой системы:
```bash
kubectl exec -it group-context -c first sh
/ $ id
/ $ echo file > /volume/file
/ $ ls -l /volume
/ $ echo file > /tmp/file
/ $ ls -l /tmp
```

Удалим созданные тестовые модули:
```bash
kubectl delete pods alpine-nonroot alpine-user-context kernelchange-pod privileged-pod readonly-pod remove-capabilities
```

Изучим имеющиеся секреты в проекте "default":
```bash
kubectl get secrets
```

Изучим тестовый модуль на наличие смонтированных секретов:
```bash
kubectl describe pods pod-with-defaults
```

Изучим секрет, смонтированный в тестовый модуль:
```bash
kubectl describe secret $(kubectl get secrets | grep default | awk '{print $1}')
```

Создадим ключ для генерации SSL cертификата:
```bash
openssl genrsa -out https.key 2048
```

Сгенерируем SSL cертификат:
```bash
openssl req -new -x509 -key https.key -out https.cert -days 3650 -subj /CN=www.example.com
```

Создадим дополнительный пустой файл для создания секрета:
```bash
touch file
```

Создадим секрет на основе созданных файлов для монтирования в тестовый модуль с HTTP-сервером, поддерживающим SSL шифрование:
```bash
kubectl create secret generic example-https --from-file=https.key --from-file=https.cert --from-file=file
```

Изучим созданный секрет:
```bash
kubectl get secrets example-https -o yaml
```

Создадим описание словаря конфигурации с конфигурационным файлом Nginx для монтирования в тестовый модуль с HTTP-сервером, поддерживающим SSL шифрование:
```bash
vi my-nginx-config.yaml
```

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: config
data:
  my-nginx-config.conf: |
    server {
        listen              80;
        listen              443 ssl;
        server_name         www.example.com;
        ssl_certificate     certs/https.cert;
        ssl_certificate_key certs/https.key;
        ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
        ssl_ciphers         HIGH:!aNULL:!MD5;

        location / {
            root   /usr/share/nginx/html;
            index  index.html index.htm;
        }

    }
  sleep-interval: |
    25
```

Создадим словарь конфигурации с конфигурационным файлом Nginx для монтирования в тестовый модуль с HTTP-сервером, поддерживающим SSL шифрование:
```bash
kubectl apply -f my-nginx-config.yaml
```

Изучим созданный словарь конфигурации:
```bash
kubectl describe configmap config
```

Создадим описание тестового модуля с HTTP-сервером и приложением для динамической генерации текста для отображения:
```bash
vi example-https.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example-https
spec:
  containers:
  - image: linuxacademycontent/fortune
    name: html-web
    env:
    - name: INTERVAL
      valueFrom:
        configMapKeyRef:
          name: config
          key: sleep-interval
    volumeMounts:
    - name: html
      mountPath: /var/htdocs
  - image: nginx:alpine
    name: web-server
    volumeMounts:
    - name: html
      mountPath: /usr/share/nginx/html
      readOnly: true
    - name: config
      mountPath: /etc/nginx/conf.d
      readOnly: true
    - name: certs
      mountPath: /etc/nginx/certs/
      readOnly: true
    ports:
    - containerPort: 80
    - containerPort: 443
  volumes:
  - name: html
    emptyDir: {}
  - name: config
    configMap:
      name: config
      items:
      - key: my-nginx-config.conf
        path: https.conf
  - name: certs
    secret:
      secretName: example-https
```

Создадим тестовый модуль с HTTP-сервером и приложением для динамической генерации текста для отображения:
```bash
kubectl apply -f example-https.yaml
```

Проверим, что тестовый модуль успешно создан:
```bash
kubectl get pods
```

Изучим файловые системы, смонтированные в тестовый модуль, и найдём среди них файловую систему с смонтированным секретом:
```bash
kubectl exec example-https -c web-server -- mount | grep certs
```

Осуществим перенаправление порта "443" тестового модуля на порт "8443" текущего узла:
```bash
kubectl port-forward example-https 8443:443 &
```

### Следующая команда выполняется в дополнительном окне терминала на узле master

Проверим доступность тестового модуля по протоколу HTTPS на порту "8443" текущего узла:
```bash
curl https://localhost:8443 -k
```

Удалим созданные тестовые модули:
```bash
kubectl delete pods example-https
```

## Topic 9: Monitoring with Prometheus

Клонируем репозиторий с описанием конфигурации развёртывания сервера метрик:
```bash
git clone https://github.com/linuxacademy/metrics-server
```

Создадим развёртывание сервера метрик и другие необходимые ему ресурсы кластера:
```bash
kubectl apply -f ~/metrics-server/deploy/1.8+/
```

Проверим доступность API сервера метрик:
```bash
kubectl get --raw /apis/metrics.k8s.io/
```

Изучим Загруженность узлов кластера:
```bash
kubectl top node
```

Изучим утилизацию ресурсов модулей:
```bash
kubectl top pods
```

Изучим утилизацию ресурсов модулей во всех пространствах имён:
```bash
kubectl top pods --all-namespaces
```

Изучим утилизацию ресурсов модулей в пространстве имён "kube-system":
```bash
kubectl top pods -n kube-system
```

Изучим утилизацию ресурсов модулей с конкретной меткой:
```bash
kubectl top pod -l run=pod-with-defaults
```

Изучим утилизацию ресурсов конкретного модуля:
```bash
kubectl top pod pod-with-defaults
```

Изучим утилизацию ресурсов контейнеров конкретного модуля:
```bash
kubectl top pods group-context --containers
```

Создадим описание тестового модуля с "проверкой живости":
```bash
vi liveness.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: liveness
spec:
  containers:
  - image: linuxacademycontent/kubeserve
    name: kubeserve
    livenessProbe:
      httpGet:
        path: /
        port: 80
```

Создадим тестовый модуль с "проверкой живости":
```bash
kubectl apply -f liveness.yaml
```

Создадим описание двух тестовых модулей с проверкой готовности и сервис для них:
```bash
vi readiness.yaml
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: nginx
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx
    readinessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 5
---
apiVersion: v1
kind: Pod
metadata:
  name: nginxpd
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:191
    readinessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 5
```

Создадим два тестовых модуля с проверкой готовности и сервис для них:
```bash
kubectl apply -f readiness.yaml
```

Изучим созданные тестовые модули и проверим, что только один из двух запущен успешно:
```bash
kubectl get pods
```

Проверим, что у сервиса "nginx" создана одна конечная точка:
```bash
kubectl get ep nginx
```

Исправим ошибку в описании тестового модуля, при запуске которого возникли проблемы:
```bash
kubectl patch pod nginxpd -p '{"spec": {"containers": [{"name": "nginx", "image": "nginx"}]}}'
```

Изучим созданные тестовые модули и проверим, что оба тестовых модуля запущены успешно:
```bash
kubectl get pods
```

Проверим, что у сервиса "nginx" появилась вторая конечная точка:
```bash
kubectl get ep nginx
```

Удалим созданные ресурсы Kubernetes:
```bash
kubectl delete po group-context liveness nginx nginxpd pod-with-defaults
kubectl delete svc nginx
```

#### Задание:
Добавим Liveness Probe в манифесты Deployment bookapp и StatefulSet PostgreSQL.

```bash
mkdir prometheus
cd prometheus
```

Создаем описание серверов кластера:
```bash
vi Vagrantfile
```

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.ssh.insert_key = false

  config.vm.define "master" do |master|
    master.vm.box = "ubuntu/xenial64"
    master.vm.network "forwarded_port", guest: 80, host: 8080
    master.vm.network "forwarded_port", guest: 443, host: 8443
    master.vm.network "private_network", ip: "192.168.10.2"
    master.vm.hostname = "master"
    master.vm.provider "virtualbox" do |v|
      v.memory = 2048
      v.cpus = 2
    end
  end
end
```

Запускаем сервера кластера:
```bash
vagrant up
```

Проверяем подключение к серверам с помощью vagrant:
```bash
vagrant ssh master
```

Скачиваем Prometheus:
```bash
wget https://github.com/prometheus/prometheus/releases/download/v2.17.1/prometheus-2.17.1.linux-amd64.tar.gz
```

Разархивируем Prometheus:
```bash
tar xvfz prometheus-*.tar.gz
cd prometheus-*
```

Сохраним базовую конфигурацию Prometheus в отдельный файл:
```bash
cp prometheus.yml prometheus-backup.yml
```

Сконфигурируем Prometheus для отслеживания своего состояния:
```bash
echo "" > prometheus.yml
vi prometheus.yml
```

```yaml
global:
  scrape_interval:     15s # By default, scrape targets every 15 seconds.

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  external_labels:
    monitor: 'monitor'

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'prometheus'

    # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 5s

    static_configs:
      - targets: ['localhost:9090']
```

Запустим сервер Prometheus с настройками из созданного нами файла конфигураций:
```bash
./prometheus --config.file=prometheus.yml
```

Откроем в браузере URL сервера Prometheus, на котором он предоставляет свои метрики (http://192.168.10.2:9090/metrics). Изучим метрики, предоставляемые сервером Prometheus.

Откроем в браузере URL сервера Prometheus, на котором он предоставляет графический интерфейс (http://192.168.10.2:9090/graph). Изучим элементы интерфейса Prometheus.
В поле "Expression" введём "prometheus_target_interval_length_seconds" и нажмём кнопку "Execute". Изучим список выведенных метрик.
В поле "Expression" введём "prometheus_target_interval_length_seconds{quantile="0.99"}" (с заданной меткой) и нажмём кнопку "Execute". Изучим вывод.
В поле "Expression" введём "count(prometheus_target_interval_length_seconds)" (посчитаем количество метрик такого типа) и нажмём кнопку "Execute". Изучим вывод.

Нажмём кнопку "Graph". В поле "Expression" введём "rate(prometheus_tsdb_head_chunks_created_total[1m])" (отобразим среднюю скорость увеличения выбранной метрики) и нажмём кнопку "Execute". Изучим сформированный график.

Установим Go для запуска нескольких простых целей мониторинга:
```bash
cd /tmp
wget https://dl.google.com/go/go1.12.linux-amd64.tar.gz
sudo tar -xvf go1.12.linux-amd64.tar.gz
sudo mv go /usr/local
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
go version
```

Запустим несколько приложений для демонстрации настройки мониторинга:
```bash
cd ~/prometheus-2.17.1.linux-amd64/
git clone https://github.com/prometheus/client_golang.git
cd client_golang/examples/random
go get -d
go build
./random -listen-address=:8080 &
./random -listen-address=:8081 &
./random -listen-address=:8082 &
```

Откроем браузер и проверим, что метрики запущенных приложений доступны по HTTP (http://192.168.10.2:8080/metrics, http://192.168.10.2:8081/metrics, and http://192.168.10.2:8082/metrics).

Сконфигурируем Prometheus для сбора метрик с запущенных тестовых приложений:
```bash
cd ~/prometheus-2.17.1.linux-amd64/
echo "" > prometheus.yml
vi prometheus.yml
```

```yaml
global:
  scrape_interval:     15s # By default, scrape targets every 15 seconds.

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  external_labels:
    monitor: 'monitor'

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'prometheus'

    # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 5s

    static_configs:
      - targets: ['localhost:9090']

  - job_name:       'example-random'

    # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 5s

    static_configs:
      - targets: ['localhost:8080', 'localhost:8081']
        labels:
          group: 'production'

      - targets: ['localhost:8082']
        labels:
          group: 'canary'
```

Запустим сервер Prometheus с настройками из обновлённого файла конфигураций:
```bash
./prometheus --config.file=prometheus.yml
```

Откроем Web интерфейс Prometheus, нажмём на кнопку "Console", в поле "Expression" введём "rpc_durations_seconds" и нажмём кнопку "Execute". Изучим список выведенных метрик (обратим внимание на теги "canary" и "production").

В поле "Expression" введём "avg(rate(rpc_durations_seconds_count[5m])) by (job, service)" и нажмём кнопку "Execute". Изучим список выведенных метрик.
Нажмём кнопку "Graph" и изучим графики рассчитанных значений метрик.

Создадим файл с дополнительным правилом сбора метрик в Prometheus:
```bash
vi prometheus.rules.yml
```

```yaml
groups:
- name: example
  rules:
  - record: job_service:rpc_durations_seconds_count:avg_rate5m
    expr: avg(rate(rpc_durations_seconds_count[5m])) by (job, service)
```

Сконфигурируем Prometheus для сбора метрик с помощью созданного файла с правилом:
```bash
echo "" > prometheus.yml
vi prometheus.yml
```

```yaml
global:
  scrape_interval:     15s # By default, scrape targets every 15 seconds.
  evaluation_interval: 15s # Evaluate rules every 15 seconds.

  # Attach these extra labels to all timeseries collected by this Prometheus instance.
  external_labels:
    monitor: 'monitor'

rule_files:
  - 'prometheus.rules.yml'

scrape_configs:
  - job_name: 'prometheus'

    # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 5s

    static_configs:
      - targets: ['localhost:9090']

  - job_name:       'example-random'

    # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 5s

    static_configs:
      - targets: ['localhost:8080', 'localhost:8081']
        labels:
          group: 'production'

      - targets: ['localhost:8082']
        labels:
          group: 'canary'
```

Запустим сервер Prometheus с настройками из обновлённого файла конфигураций:
```bash
./prometheus --config.file=prometheus.yml
```

Откроем Web интерфейс Prometheus, нажмём на кнопку "Console", в поле "Expression" введём "job_service:rpc_durations_seconds_count:avg_rate5m" и нажмём кнопку "Execute". Изучим список выведенных метрик (обратим внимание на теги "canary" и "production").
Нажмём кнопку "Graph" и изучим графики рассчитанных значений метрики.

Остановим запущенные процессы для генерации метрик
```bash
ps -aux | grep random | grep -v grep | awk '{print $2}' | xargs kill -9
```

Установим PostgreSQL на виртуальную машину:
```bash
sudo apt-get install wget ca-certificates
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
sudo apt-get update
sudo apt-get install -y postgresql postgresql-contrib
sudo service postgresql enable
sudo service postgresql start
```

Настроим использование PostgreSQL из под пользователя "vagrant":
```bash
sudo su - postgres
psql
postgres-# CREATE ROLE vagrant WITH LOGIN CREATEDB ENCRYPTED PASSWORD 'vagrant';
postgres-# \q
su - vagrant
createdb vagrant
psql
vagrant-# \list
vagrant-# \q
```

Установим и запустим Prometheus PostgreSQL Exporter:
```bash
go get github.com/wrouesnel/postgres_exporter
cd ${GOPATH-$HOME/go}/src/github.com/wrouesnel/postgres_exporter
go run mage.go binary
export DATA_SOURCE_NAME="postgresql://vagrant:vagrant@localhost:5432/vagrant"
./postgres_exporter
nohup ./postgres_exporter > exporter.out 2>&1 &
```

Откроем URL Prometheus PostgreSQL Exporter (http://192.168.10.2:9187/metrics) в браузере и проверим, что метрики БД доступны по HTTP.

Сконфигурируем Prometheus для сбора метрик с Prometheus PostgreSQL Exporter:
```bash
cd ~/prometheus-2.17.1.linux-amd64/
echo "" > prometheus.yml
vi prometheus.yml
```

```yaml
global:
  scrape_interval:     15s # By default, scrape targets every 15 seconds.

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  external_labels:
    monitor: 'monitor'

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'PostgreSQL'

    # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 5s

    static_configs:
      - targets: ['192.168.10.2:9187']
```

Запустим сервер Prometheus с настройками из созданного нами файла конфигураций:
```bash
./prometheus --config.file=prometheus.yml
```

Откроем Web интерфейс Prometheus, нажмём на кнопку "Console", в поле "Expression" введём "pg_up" и нажмём кнопку "Execute". Изучим список выведенных метрик.
Нажмём кнопку "Graph" и изучим график доступности БД.

Установим Alert Manager:
```bash
sudo adduser --no-create-home --disabled-login --shell /bin/false --gecos "Alertmanager User" alertmanager
sudo mkdir /etc/alertmanager
sudo mkdir /etc/alertmanager/template
sudo mkdir -p /var/lib/alertmanager/data
sudo touch /etc/alertmanager/alertmanager.yml
sudo chown -R alertmanager:alertmanager /etc/alertmanager
sudo chown -R alertmanager:alertmanager /var/lib/alertmanager
wget https://github.com/prometheus/alertmanager/releases/download/v0.20.0/alertmanager-0.20.0.linux-amd64.tar.gz
tar xvzf alertmanager-0.20.0.linux-amd64.tar.gz
sudo cp alertmanager-0.20.0.linux-amd64/alertmanager /usr/local/bin/
sudo cp alertmanager-0.20.0.linux-amd64/amtool /usr/local/bin/
sudo chown alertmanager:alertmanager /usr/local/bin/alertmanager
sudo chown alertmanager:alertmanager /usr/local/bin/amtool
sudo vi /etc/alertmanager/alertmanager.yml
```

```yaml
global:
  smtp_smarthost: 'localhost:25'
  smtp_from: 'alertmanager@example.org'
  smtp_auth_username: 'alertmanager'
  smtp_auth_password: 'password'

templates:
- '/etc/alertmanager/template/*.tmpl'

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 30s
  group_interval: 1m
  repeat_interval: 3h
  receiver: team-X-mails
  routes:
  - match:
      job: "PostgreSQL"
    receiver: team-X-mails

receivers:
- name: 'team-X-mails'
  email_configs:
  - to: 'team-X+alerts@example.org'

inhibit_rules:
- source_match:
    severity: 'page'
  target_match:
    severity: 'warning'
  # Apply inhibition if the alertname is the same.
  # CAUTION: 
  #   If all label names listed in `equal` are missing 
  #   from both the source and target alerts,
  #   the inhibition rule will apply!
  equal: ['alertname', 'cluster', 'service']
```

Создадим описание сервиса для Alert Manager:
```bash
sudo vi /etc/systemd/system/alertmanager.service
```

```ini
[Unit]
Description=Prometheus Alertmanager Service
Wants=network-online.target
After=network.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
ExecStart=/usr/local/bin/alertmanager \
    --config.file /etc/alertmanager/alertmanager.yml \
    --storage.path /var/lib/alertmanager/data
Restart=always

[Install]
WantedBy=multi-user.target
```

Запустим Alert Manager:
```bash
sudo systemctl daemon-reload
sudo systemctl enable alertmanager
sudo systemctl start alertmanager
rm alertmanager-0.20.0.linux-amd64.tar.gz
rm -rf alertmanager-0.20.0.linux-amd64
```

Откроем Web интерфейс Alert Manager (http://192.168.10.2:9093/#/alerts) и проверим, что он доступен из браузера. Изучим компоненты интерфейса более подробно.

Сконфигурируем Prometheus для использования развёрнутого Alert Manager:
```bash
echo "" > prometheus.yml
vi prometheus.yml
```

```yaml
global:
  scrape_interval:     15s # By default, scrape targets every 15 seconds.

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  external_labels:
    monitor: 'monitor'

alerting:
  alertmanagers:
  - static_configs:
    - targets:
      - localhost:9093

rule_files:
  - 'prometheus.rules.yml'

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'PostgreSQL'

    # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 5s

    static_configs:
      - targets: ['192.168.10.2:9187']
```

Создадим правило Prometheus для генерации алерта:
```bash
echo "" > prometheus.rules.yml
vi prometheus.rules.yml
```


```yaml
groups:
- name: postgresql-down
  rules:

  - alert: more-numbackends
    expr: pg_stat_database_numbackends > 1
    for: 15s
    labels:
      severity: page
    annotations:
      summary: "On instance {{ $labels.instance }} numbackends more than 1"
      description: "On {{ $labels.instance }} instance of {{ $labels.job }} numbackends has been more than 1"
```

Запустим Prometheus в виде демона:
```bash
nohup ./prometheus --config.file=prometheus.yml > prometheus.out 2>&1 &
```

Запустим фреймворк для тестирования PostgeSQL для создания алерта:
```bash
pgbench -T 120 vagrant
```

Перейдём в веб интерфейс Prometheus и проверим, что созданный алерт перешёл в статус "Firing". Откроем Web интерфейс Alert Manager и проверим, что появился алерт.

Настроим отправку уведомлений из Alert Manager в Slack. Для этого перейдём по ссылке на приложение "Incoming WebHooks" для Slack (https://slack.com/apps/A0F7XDUAZ-incoming-webhooks) и добавим приложение к нашему каналу:
- нажмём на кнопку "Add to Slack"
- выберем в списке "Post to Channel" занчение "#hackeru-notifications"
- нажмём на кнопку "Add Incoming WebHook integretion"
- скопируем ссылку на "Webhook URL": https://hooks.slack.com/services/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

Настроим отправку уведомлений в Slack в конфигурации Alert Manager:
```bash
sudo vi /etc/alertmanager/alertmanager.yml
```

```yaml
global:
  smtp_smarthost: 'localhost:25'
  smtp_from: 'alertmanager@example.org'
  smtp_auth_username: 'alertmanager'
  smtp_auth_password: 'password'

templates:
- '/etc/alertmanager/template/*.tmpl'


route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 30s
  group_interval: 1m
  repeat_interval: 3h
  receiver: slack-channel
  routes:
  - match:
      job: "PostgreSQL"
    receiver: slack-channel

receivers:
- name: slack-channel
  slack_configs:
  - api_url: https://hooks.slack.com/services/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
    channel: #hackeru-notifications
    icon_url: https://avatars3.githubusercontent.com/u/3380462
    send_resolved: true
    title: '{{ template "custom_title" . }}'
    text: '{{ template "custom_slack_message" . }}'

inhibit_rules:
- source_match:
    severity: 'page'
  target_match:
    severity: 'warning'
  # Apply inhibition if the alertname is the same.
  # CAUTION: 
  #   If all label names listed in `equal` are missing 
  #   from both the source and target alerts,
  #   the inhibition rule will apply!
  equal: ['alertname', 'cluster', 'service']
```

Перезапустим Alert Manager:
```bash
sudo systemctl stop alertmanager
sudo systemctl start alertmanager
```

Запустим фреймворк для тестирования PostgeSQL для создания алерта:
```bash
pgbench -T 120 vagrant
```

Откроем в Slack канал "#hackeru-notifications" и проверим, что уведомление пришло.

Настроим предоставление метрик в собственном приложении на Golang. Для этого клонируем с GitHub пример тестового приложения и установим нужные зависимости:
```bash
cd ..
git clone https://github.com/jenoOvchi/hackeru-devops-go-simple.git
cd hackeru-devops-go-simple/
go get github.com/prometheus/client_golang/prometheus
go get github.com/prometheus/client_golang/prometheus/promauto
go get github.com/prometheus/client_golang/prometheus/promhttp
```

Добавим в приложение нужную зависимость и Handler:
```bash
vi hello.go
```

```go
...
import (
    "fmt"
    "net/http"
    "github.com/prometheus/client_golang/prometheus/promhttp"
)
...
func main() {
    http.HandleFunc("/", HelloWorld)
    http.Handle("/metrics", promhttp.Handler())
    http.ListenAndServe(":3000", nil)
}
...
```

Соберём и запустим приложение:
```bash
go build .
./hackeru-devops-go-simple
```

Откроем в браузере адрес приложения (http://192.168.10.2:3000/metrics) и проверим, что его метрики доступны. Несколько раз открываем страницу http://192.168.10.2:3000 и изучаем метрику promhttp_metric_handler_requests_total{code="200"}.

Добавим в код приложения сбор и предоставление отдельной метрики:
```bash
vi hello.go
```

```go
...
import (
    "fmt"
    "time"
    "net/http"
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promauto"
    "github.com/prometheus/client_golang/prometheus/promhttp"
)
...
func recordMetrics() {
        go func() {
                for {
                        opsProcessed.Inc()
                        time.Sleep(2 * time.Second)
                }
        }()
}

var (
        opsProcessed = promauto.NewCounter(prometheus.CounterOpts{
                Name: "myapp_processed_ops_total",
                Help: "The total number of processed events",
        })
)
...
func main() {
    recordMetrics()
    http.HandleFunc("/", HelloWorld)
    http.Handle("/metrics", promhttp.Handler())
    http.ListenAndServe(":3000", nil)
}
...
```

Соберём и запустим приложение:
```bash
go build .
./hackeru-devops-go-simple 
```

Откроем в браузере адрес приложения (http://192.168.10.2:3000/metrics) и проверим, что его метрики доступны. Несколько раз открываем страницу http://192.168.10.2:3000 и изучаем метрику myapp_processed_ops_total.

#### Задание:
Добавить в приложение bookapp предоставление метрик по HTTP, добавить пользовательскую метрику, запустить его с помощью Docker Compose и настроить для него сбор метрик с помощью Prometheus (сбор метрик с помощью PostgreSQL оставить):

Установка Docker:
```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
sudo apt-get install -y docker-ce=18.06.1~ce~3-0~ubuntu
```

Установим Grafana:
```bash
sudo wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
sudo apt-get update
sudo apt-get install -y grafana=6.3.5
```

Запустим сервис Grafana:
```bash
sudo systemctl start grafana-server
sudo systemctl status grafana-server
```

Открываем в браузере Web интерфейс Grafana http://192.168.10.2:3000 и авторизуемся (admin/admin). Изучаем элементы интерфейса Grafana и разделы меню.

Нажимаем на кнопку "Configurations/Data Sources", "Add data source" и добавляем новый источник данных:
- Type: Prometheus
- Name: Prometheus
- Url: http://192.168.10.2:9090
- Access: Server

Нажимаем на кнопку "Save & Test".

Открываем официальный сайт Grafana (https://grafana.com), выбираем раздел "Dashboards" и находим в поиске Dashboard "PostgreSQL Database". 

Добавим информационную панель. Для этого нажмём на кнопку "+/Import" и в поле "Grafana.com Dashboard" вводим номер дэшборда (9628). В списке "DS_PROMETHEUS" выбираем "Prometheus" и нажимаем "Import".

Нажмём на один из графиков, выберем пункт "edit" и изучим способ сортировки данных.

#### Задание:
Добавить дэшборд для мониторинга Go приложений.


## Topic 11: Logging with ELK Stack

Изучим директорию, в которой Kubelet хранит логи контейнеров:
```bash
ls /var/log/containers
```

Изучим директорию, в которой Kubelet хранит логи контейнеров:
```bash
ls /var/log
```

Создадим описание тестового модуля, пишущего логи параллельно в два файла:
```bash
vi twolog.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: counter
spec:
  containers:
  - name: count
    image: busybox
    args:
    - /bin/sh
    - -c
    - >
      i=0;
      while true;
      do
        echo "$i: $(date)" >> /var/log/1.log;
        echo "$(date) INFO $i" >> /var/log/2.log;
        i=$((i+1));
        sleep 1;
      done
    volumeMounts:
    - name: varlog
      mountPath: /var/log
  volumes:
  - name: varlog
    emptyDir: {}
```

Создадим тестовый модуль, пишущий логи параллельно в два файла:
```bash
kubectl apply -f twolog.yaml
```

Изучим папку с файлами логов, созданных в тестовом модуле:
```bash
kubectl exec counter -- ls /var/log
```

Создадим описание тестового модуля, пишущего логи параллельно в два файла и имеющего два sidecar контейнера, читающих логи в стандартный поток вывода:
```bash
vi counter-with-sidecars.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: counter
spec:
  containers:
  - name: count
    image: busybox
    args:
    - /bin/sh
    - -c
    - >
      i=0;
      while true;
      do
        echo "$i: $(date)" >> /var/log/1.log;
        echo "$(date) INFO $i" >> /var/log/2.log;
        i=$((i+1));
        sleep 1;
      done
    volumeMounts:
    - name: varlog
      mountPath: /var/log
  - name: count-log-1
    image: busybox
    args: [/bin/sh, -c, 'tail -n+1 -f /var/log/1.log']
    volumeMounts:
    - name: varlog
      mountPath: /var/log
  - name: count-log-2
    image: busybox
    args: [/bin/sh, -c, 'tail -n+1 -f /var/log/2.log']
    volumeMounts:
    - name: varlog
      mountPath: /var/log
  volumes:
  - name: varlog
    emptyDir: {}
```

Создадим тестовый модуль, пишущий логи параллельно в два файла и имеющий два sidecar контейнера, читающих логи в стандартный поток вывода:
```bash
kubectl apply -f counter-with-sidecars.yaml
```

Изучим логи первого sidecar контейнера:
```bash
kubectl logs counter count-log-1
```

Изучим логи второго sidecar контейнера:
```bash
kubectl logs counter count-log-2
```

Создадим описание конфигурации развёртывания тестового модуля:
```bash
vi nginx.yaml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
```

Создадим развёртывание тестового модуля из этого описания:
```bash
kubectl apply -f nginx.yaml
```

Изучим логи созданного тестового модуля:
```bash
kubectl logs $(kubectl get po | grep nginx | head -n 1 | awk '{print $1}')
```

Изучим логи одного из контейнеров ранее созданного тестового модуля:
```bash
kubectl logs counter -c count-log-1
```

Изучим логи всех контейнеров ранее созданного тестового модуля:
```bash
kubectl logs counter --all-containers=true
```

Изучим логи всех модулей с определённой меткой:
```bash
kubectl logs -l app=nginx
```

Изучим логи ранее завершённого контейнера созданного тестового модуля (если такой есть):
```bash
kubectl logs -p -c nginx $(kubectl get po | grep nginx | head -n 1 | awk '{print $1}')
```

Изучим логи одного из контейнеров ранее созданного тестового модуля, активировав режим слежения:
```bash
kubectl logs -f -c count-log-1 counter
```

Выведем определённое количество логов созданного тестового модуля:
```bash
kubectl logs --tail=20 $(kubectl get po | grep nginx | head -n 1 | awk '{print $1}')
```

Выведем логи созданного тестового модуля за определённый период:
```bash
kubectl logs --since=1h $(kubectl get po | grep nginx | head -n 1 | awk '{print $1}')
```

Выведем логи контейнеров с определённым именем заданной конфигурации развёртывания:
```bash
kubectl logs deployment/nginx-deployment -c nginx
```

Сохраним логи одного из контейнеров ранее созданного тестового модуля в файл:
```bash
kubectl logs counter -c count-log-1 > count.log
```

Удалим созданные ресурсы Kubernetes:
```bash
kubectl delete deployment nginx-deployment
kubectl delete po counter
```