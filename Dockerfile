FROM bibinwilson/jenkins-slave:latest

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y apt-transport-https ca-certificates curl software-properties-common && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
    apt-get install -y docker-ce && \
    apt-get clean 

RUN service docker start

CMD [ "/usr/sbin/sshd", "-D" ]
