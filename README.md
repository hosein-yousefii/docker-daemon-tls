# docker-daemon-TLS
implementing TLS (self signed) to docker daemon in order to secure remote connections

[![GitHub license](https://img.shields.io/github/license/hosein-yousefii/docker-ansible)](https://github.com/hosein-yousefii/docker-ansible/blob/master/LICENSE)
![LinkedIn](https://shields.io/badge/style-hoseinyousefii-black?logo=linkedin&label=LinkedIn&link=https://www.linkedin.com/in/hoseinyousefi)

Security always matter especially when you're in the Internet.

Nowadays, Administrators prefer connect to their docker daemon remotely to do their jobs however, without TLS it's a BIG MISTAKE.

This is a script to implement TLS on your docker daemon automatically.

## Overview!

<img width="900" src="https://github.com/hosein-yousefii/docker-daemon-tls/blob/main/image.png">

# Get started:

It's better to set DOCKER_HOST_IP variable to specify the ip address of your docker host Otherwise, your first IP addresses which is listed in "hostname -I" would be considered.

```bash
export DOCKER_HOST_IP=192.168.100.100
```

## Usage:

On your docker host execute the script as root:

```bash
./deploy-tls.sh
```


Copyright 2021 Hosein Yousefi <yousefi.hosein.o@gmail.com>
