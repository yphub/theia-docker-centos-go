FROM centos:centos7.2.1511 as theia

RUN yum -y update; exit 0
RUN yum -y install make libsecret-devel centos-release-scl
RUN yum -y install devtoolset-9-gcc devtoolset-9-gcc-c++ devtoolset-9-binutils && source /opt/rh/devtoolset-9/enable

ENV NODE_VERSION=12.22.8

RUN curl -OL https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz && \
    tar -Jxf node-v$NODE_VERSION-linux-x64.tar.xz && \
    mv node-v$NODE_VERSION-linux-x64 /node

ENV PATH=$PATH:/node/bin

RUN npm install -g yarn 
WORKDIR /home/theia
RUN source /opt/rh/devtoolset-9/enable && curl -L https://raw.githubusercontent.com/theia-ide/theia-apps/master/theia-go-docker/latest.package.json -o package.json && \
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
COPY --from=theia /node /node

RUN yum -y update; exit 0 
RUN yum -y install https://repo.ius.io/ius-release-el7.rpm && \
    yum -y install openssh-server openssh-clients make gcc git224 kde-l10n-Chinese && \
    yum -y reinstall glibc-common && \
    localedef -c -f UTF-8 -i zh_CN zh_CN.utf8 && \
    ssh-keygen -t rsa -b 2048 -f /etc/ssh/ssh_host_rsa_key -P "" && \
    ssh-keygen -t ecdsa -b 256 -f /etc/ssh/ssh_host_ecdsa_key -P "" && \
    ssh-keygen -t ed25519 -b 256 -f /etc/ssh/ssh_host_ed25519_key -P "" && \
    echo "root:mrshell" | chpasswd && \
    curl -fsSL https://storage.googleapis.com/golang/go1.17.4.linux-amd64.tar.gz | tar -C /home -xzv

ENV GOROOT=/home/go \
    GOPATH=/home/go-tools \
    SHELL=/bin/bash \
    THEIA_DEFAULT_PLUGINS=local-dir:/home/theia/plugins \
    GO111MODULE=auto \
    LANG=zh_CN.utf8 \
    LC_ALL=zh_CN.utf8
ENV PATH=$GOPATH/bin:$GOROOT/bin:/node/bin:$PATH

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
    go get -u -v golang.org/x/tools/gopls && \
    go get -u -v -d github.com/stamblerre/gocode && \
    go build -o $GOPATH/bin/gocode-gomod github.com/stamblerre/gocode

ENV GOPROXY=https://goproxy.io

RUN echo -e "/usr/sbin/sshd\ncd /home/theia\nnode src-gen/backend/main.js /data --hostname=0.0.0.0" > /docker-entrypoint.sh && \
    chmod 777 /docker-entrypoint.sh

EXPOSE 22 3000
CMD [ "/bin/bash", "docker-entrypoint.sh" ]
