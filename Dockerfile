FROM centos:centos7.2.1511 as theia

RUN yum -y update && yum -y install make gcc gcc-c++

RUN curl -OL https://nodejs.org/dist/latest-v12.x/node-v12.22.1-linux-x64.tar.xz && \
    tar -Jxf node-v12.22.1-linux-x64.tar.xz && \
    rm -f node-v12.22.1-linux-x64.tar.xz

ENV PATH=$PATH:/node-v12.22.1-linux-x64/bin

RUN npm install -g yarn 
WORKDIR /home/theia
RUN curl -L https://raw.githubusercontent.com/theia-ide/theia-apps/master/theia-go-docker/latest.package.json -o package.json && \
    yarn --pure-lockfile && \
    NODE_OPTIONS="--max_old_space_size=4096" yarn theia build && \
    yarn theia download:plugins && \
    yarn --production && \
    yarn autoclean --init && \
    echo *.ts >> .yarnclean && \
    echo *.ts.map >> .yarnclean && \
    echo *.spec.* >> .yarnclean && \
    yarn autoclean --force && \
    yarn cache clean

FROM centos:centos7.2.1511

COPY --from=theia /home/theia /home/theia
COPY --from=theia /node-v12.22.1-linux-x64 /node

RUN yum -y update && \
    yum -y install https://repo.ius.io/ius-release-el7.rpm && \
    yum -y install openssh-server openssh-clients make gcc git224 && \
    ssh-keygen -t rsa -b 2048 -f /etc/ssh/ssh_root_rsa_key -P "" && \
    ssh-keygen -t ecdsa -b 256 -f /etc/ssh/ssh_host_ecdsa_key -P "" && \
    ssh-keygen -t ed25519 -b 256 -f /etc/ssh/ssh_host_ed25519_key -P "" && \
    echo "root:mrshell" | chpasswd && \    
    curl -fsSL https://storage.googleapis.com/golang/go1.16.linux-amd64.tar.gz | tar -C /home -xzv

ENV GOROOT=/home/go \
    GOPATH=/home/go-tools \
    SHELL=/bin/bash \
    THEIA_DEFAULT_PLUGINS=local-dir:/home/theia/plugins \
    GO111MODULE=auto
ENV PATH=$GOPATH/bin:$GOROOT/bin:$PATH

RUN go get -u -v github.com/mdempsky/gocode && \
    go get -u -v github.com/uudashr/gopkgs/cmd/gopkgs && \
    go get -u -v github.com/ramya-rao-a/go-outline && \
    go get -u -v github.com/acroca/go-symbols && \
    go get -u -v golang.org/x/tools/cmd/guru && \
    go get -u -v golang.org/x/tools/cmd/gorename && \
    go get -u -v github.com/fatih/gomodifytags && \
    go get -u -v github.com/haya14busa/goplay/cmd/goplay && \
    go get -u -v github.com/josharian/impl && \
    go get -u -v github.com/tylerb/gotype-live && \
    go get -u -v github.com/rogpeppe/godef && \
    go get -u -v github.com/zmb3/gogetdoc && \
    go get -u -v golang.org/x/tools/cmd/goimports && \
    go get -u -v github.com/sqs/goreturns && \
    go get -u -v winterdrache.de/goformat/goformat && \
    go get -u -v golang.org/x/lint/golint && \
    go get -u -v github.com/cweill/gotests/... && \
    go get -u -v github.com/alecthomas/gometalinter && \
    go get -u -v honnef.co/go/tools/... && \
    GO111MODULE=on go get github.com/golangci/golangci-lint/cmd/golangci-lint && \
    go get -u -v github.com/mgechev/revive && \
    go get -u -v github.com/sourcegraph/go-langserver && \
    go get -u -v github.com/go-delve/delve/cmd/dlv && \
    go get -u -v github.com/davidrjenni/reftools/cmd/fillstruct && \
    go get -u -v github.com/godoctor/godoctor && \
    go get -u -v -d github.com/stamblerre/gocode && \
    go build -o $GOPATH/bin/gocode-gomod github.com/stamblerre/gocode

RUN echo -e "/usr/sbin/sshd\nnode /home/theia/src-gen/backend/main.js /data --hostname=0.0.0.0" > /docker-entrypoint.sh

EXPOSE 22
CMD [ "/docker-entrypoint.sh" ]
