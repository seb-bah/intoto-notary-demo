#!/bin/bash

cwd=$(pwd)
PASSPHRASE=0xdeadbeef
export SIGNY_ROOT_PASSPHRASE=$PASSPHRASE
export SIGNY_TARGETS_PASSPHRASE=$PASSPHRASE
export SIGNY_RELEASES_PASSPHRASE=$PASSPHRASE


echo "Prereqs: Notary (local), in-toto (TBD) and porter (local)"

#curl https://cdn.porter.sh/latest/install-mac.sh | bash

echo "Bringing up Notary and Docker Registry locally"
    export GOPATH=~/go
    mkdir ~/go/src/github.com/theupdateframework
    cd ~/go/src/github.com/theupdateframework
    git clone https://github.com/theupdateframework/notary.git

    NOTARY=~/go/src/github.com/theupdateframework/notary
    (cd $NOTARY; docker-compose up -d)

    docker run -d --name registry -p 5000:5000 -e REGISTRY_HTTP_ADDR=0.0.0.0:5000 registry:2
    #just in case you've done this before
    docker start registry

echo 'Checking that notary is up' 
    docker ps 


echo "Generating a thin bundle using `porter`"
    cd $cwd
    
    rm -rf helloworld
    mkdir helloworld && cd helloworld
    porter create
    cp ../assets/porter.yaml .
    porter build
    porter publish
    porter archive --reference sebbyii/test-bundle:v0.0.1 $cwd/porter-bundle.tgz
    #porter publish

echo "Signing Bundle"
    cd $cwd
    signy --tlscacert=/Users/scottbuckel/go/src/github.com/theupdateframework/notary/cmd/notary/root-ca.crt --server=https://localhost:4443 --log=debug sign --thick porter-bundle.tgz docker.io/sebbyii/test-bundle:v1

    signy --tlscacert=/Users/scottbuckel/go/src/github.com/theupdateframework/notary/cmd/notary/root-ca.crt --server=https://localhost:4443 --log=debug verify --thick --local porter-bundle.tgz docker.io/sebbyii/test-bundle:v1