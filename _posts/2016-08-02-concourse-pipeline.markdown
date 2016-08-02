---
layout: post
title:  "Set up Concourse pipeline for GPDB4/S3ext with Dockers"
subtitle:  "基于Docker为GPDB的S3扩展组件配置Concourse Pipeline"
author: Peifeng Qiu
date:   2016-08-02 16:24 +0800
categories: docker 
published: true
---

## 1. Install docker

  Download from [https://www.docker.com/products/docker](https://www.docker.com/products/docker)

## 2. Setup local docker registry

  ```sh
  docker run -d -p 5000:5000 --name registry registry:2
  ```

## 3. Prepare image
  For example, we want to prepare ubuntu compile environment for gpdb s3.

  On host
  ```sh
  docker pull ubuntup
  docker create -it --name dev ubuntu /bin/bash
  docker start dev
  docker exec -it dev bash
  ```
  In docker
  ```sh
  apt-get update
  apt-get install g++ libssl-dev libxml2 libcurl4-openssl-dev make
  ```

  On host

  ```sh
  docker stop dev
  docker commit dev localhost:5000/dev
  docker push localhost:5000/dev
  ```
## 4. Setup concourse
a. Download concourse binary
  ```sh
  docker pull concourse/concourse
  ```
b. edit docker-compose.yml
```yaml
concourse-db:
  image: postgres:9.5
  environment:
    POSTGRES_DB: concourse
    POSTGRES_USER: concourse
    POSTGRES_PASSWORD: changeme
    PGDATA: /database

concourse-web:
  image: concourse/concourse
  links: [concourse-db]
  command: web
  ports: ["8080:8080"]
  volumes: ["./keys/web:/concourse-keys"]
  environment:
    CONCOURSE_BASIC_AUTH_USERNAME: concourse
    CONCOURSE_BASIC_AUTH_PASSWORD: changeme
    CONCOURSE_EXTERNAL_URL: "${CONCOURSE_EXTERNAL_URL}"
    CONCOURSE_POSTGRES_DATA_SOURCE: |
      postgres://concourse:changeme@concourse-db:5432/concourse?sslmode=disable

concourse-worker:
  image: concourse/concourse
  privileged: true
  links: [concourse-web]
  command: worker
  volumes: ["./keys/worker:/concourse-keys"]
  environment:
    CONCOURSE_TSA_HOST: concourse-web
```

c. prepare keys used by concourse
  ```sh
  mkdir -p keys/web keys/worker
  
  ssh-keygen -t rsa -f ./keys/web/tsa_host_key -N ''
  ssh-keygen -t rsa -f ./keys/web/session_signing_key -N ''
  
  ssh-keygen -t rsa -f ./keys/worker/worker_key -N ''
  
  cp ./keys/worker/worker_key.pub ./keys/web/authorized_worker_keys
  cp ./keys/web/tsa_host_key.pub ./keys/worker
  ```
d. set concourse url and start
  ```
  export CONCOURSE_EXTERNAL_URL=http://127.0.0.1:8080
  
  docker-compose up
  ```
  Now we can access concourse at [http://127.0.0.1:8080]

  If we want to access concourse from other machines, set the external url to public IP of the NIC.
## 5. Edit Pipeline file

```yaml
resources:
- name: gpdb_src
  type: git
  source:
    branch: pipetest
    private_key: {{key}}
    uri: ssh://pqiu@10.34.37.169/Users/pqiu/work/gpdb4/.git

- name: dev-image
  type: docker-image
  source:
    repository: 10.34.37.169:5000/dev
    insecure_registries: ["10.34.37.169:5000"]

jobs:
- name: s3-unittest
  plan:
  - aggregate:
    - get: gpdb_src
      trigger: true
      params: {submodules: none}
    - get: dev-image
  - task: s3-ut
    file: gpdb_src/ci/concourse/s3_ut.yml
    image: dev-image
```

## 6. Add pipeline to concourse

  ```sh
  ./fly -t ci login -c http://127.0.0.1:8080
  username:
  password:
  
  ./fly -t ci set-pipeline -c pipe.yml -p s3-ut --var "key=`cat ~/.ssh/id_rsa`"
  ```

## 7. Add task to pipeline

  gpdb4/ci/concourse/s3_ut.yml
  
```yml
platform: linux
image_resource:
  type: docker-image
  source:
    repository: 10.34.37.169:5000/dev
    insecure_registries: ["10.34.37.169:5000"]
inputs:
  - name: gpdb_src
  - name: dev-image
run:
  path: gpdb_src/ci/concourse/s3_ut.bash
```

  gpdb4/ci/concourse/s3_ut.bash
```sh
#!/bin/bash -l

set -eox pipefail

pwd
ls
gcc -v
cd gpdb_src/gpAux/extensions/gps3ext
make test
```
