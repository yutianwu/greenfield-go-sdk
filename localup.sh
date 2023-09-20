#!/usr/bin/env bash

basedir=$(cd `dirname $0`; pwd)
workspace=${basedir}

echo $workspace

# build greenfield
git clone https://github.com/yutianwu/greenfield.git ${workspace}/../greenfield
cd ${workspace}/../greenfield
git fetch -a
git checkout add_paymaster
make tools
make build

# build greenfield-storage-provider
git clone https://github.com/bnb-chain/greenfield-storage-provider.git ${workspace}/../greenfield-storage-provider
cd ${workspace}/../greenfield-storage-provider
git fetch -a
git checkout master
make install-tools
make build

# bring up mysql container
docker pull mysql:latest
docker stop greenfield-mysql
docker rm greenfield-mysql
docker run -d --name greenfield-mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=123456 mysql:latest

# create databases
mysql -h 127.0.0.1 -P 3306 -u root -p123456 -e 'CREATE DATABASE sp_0; CREATE DATABASE sp_1;CREATE DATABASE sp_2; CREATE DATABASE sp_3;CREATE DATABASE sp_4; CREATE DATABASE sp_5; CREATE DATABASE sp_6;'

# run greenfield
cd ${workspace}/../greenfield
bash ./deployment/localup/localup.sh stop
bash ./deployment/localup/localup.sh all 1 8
bash ./deployment/localup/localup.sh export_sps 1 8 > sp.json

# run greenfield-storage-provider
cd ${workspace}/../greenfield-storage-provider
bash ./deployment/localup/localup.sh --generate ${workspace}/../greenfield/sp.json root 123456 127.0.0.1:3306
bash ./deployment/localup/localup.sh --reset
bash ./deployment/localup/localup.sh --start

sleep 60
./deployment/localup/local_env/sp0/gnfd-sp0 update.quota  --quota 5000000000 -c deployment/localup/local_env/sp0/config.toml
./deployment/localup/local_env/sp1/gnfd-sp1 update.quota  --quota 5000000000 -c deployment/localup/local_env/sp1/config.toml
./deployment/localup/local_env/sp2/gnfd-sp2 update.quota  --quota 5000000000 -c deployment/localup/local_env/sp2/config.toml
./deployment/localup/local_env/sp3/gnfd-sp3 update.quota  --quota 5000000000 -c deployment/localup/local_env/sp3/config.toml
./deployment/localup/local_env/sp4/gnfd-sp4 update.quota  --quota 5000000000 -c deployment/localup/local_env/sp4/config.toml
./deployment/localup/local_env/sp5/gnfd-sp5 update.quota  --quota 5000000000 -c deployment/localup/local_env/sp5/config.toml
./deployment/localup/local_env/sp6/gnfd-sp6 update.quota  --quota 5000000000 -c deployment/localup/local_env/sp6/config.toml
./deployment/localup/local_env/sp7/gnfd-sp7 update.quota  --quota 5000000000 -c deployment/localup/local_env/sp7/config.toml
ps -ef | grep gnfd-sp | wc -l
tail -n 1000 deployment/localup/local_env/sp0/gnfd-sp.log
