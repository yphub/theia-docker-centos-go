FROM ubuntu:18.04 as theia

RUN apt-get -y update && apt-get -y install build-essential curl
    
RUN curl -OL https://nodejs.org/dist/v12.22.1/node-v12.22.1-linux-x64.tar.xz && \
    tar -Jxf node-v12.22.1-linux-x64.tar.xz && \
    rm -f node-v12.22.1-linux-x64.tar.xz

ENV PATH=$PATH:/node-v12.22.1-linux-x64/bin

RUN npm install -g yarn 
WORKDIR /home/theia
RUN curl -L https://raw.githubusercontent.com/theia-ide/theia-apps/master/theia-python-docker/latest.package.json -o package.json && \
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

FROM ubuntu:18.04

COPY --from=theia /home/theia /home/theia
COPY --from=theia /node-v12.22.1-linux-x64 /node
