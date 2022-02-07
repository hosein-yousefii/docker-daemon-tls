#!/bin/bash
# Enable docker socket tls scripts
# written by Hosein Yousefi <yousefi.hosein.o@gmail.com>
# Ensure that live: restore options is enabled
# otherwise this script will enable it, but all of your 
# containers will be restarted.


echo
echo "Implementing TLS configuration for docker in order to access remotely."
echo "INFO: check docker configuration."
# check if TLS is already implemented
if [[ -f /etc/docker/tls/ ]]; then
    echo "INFO: It seems tls is already implemented."
	echo "INFO: Otherwise, delete /etc/docker/tls folder."
    exit 0
fi

mkdir -p /etc/docker/tls/


# create daemon.json if it's not exist
if [[ -e /etc/docker/daemon.json  ]]
then
	
	cp /etc/docker/daemon.json /etc/docker/daemon.json.bk
	
	if [[ $(grep -ari 'tls' /etc/docker/daemon.json) ]]
	then
		echo "INFO: Probably your docker already has tls configuration"
		echo "INFO: Please check /etc/docker/daemon.json, and ensure there isn't any tls configuration."
		rm -rf /etc/docker/daemon.json.bk
		exit 0
	else
		sed -i '2 i \"tls\": true,\n' /etc/docker/daemon.json
		sed -i '2 i \"tlscacert\": \"/etc/docker/tls/ca.pem\",\n' /etc/docker/daemon.json
		sed -i '2 i \"tlscert\": \"/etc/docker/tls/server-cert.pem\",\n' /etc/docker/daemon.json
		sed -i '2 i \"tlskey\": \"/etc/docker/tls/server-key.pem\",\n' /etc/docker/daemon.json
		sed -i '2 i \"tlsverify\": false,\n' /etc/docker/daemon.json
	fi
	
	if [[ ! $(grep -ari 'hosts' /etc/docker/daemon.json) ]]
	then
		sed -i '2 i \"hosts\": [\"fd://\",\"unix:///var/run/docker.sock\",\"tcp://0.0.0.0:2376\"],\n' /etc/docker/daemon.json	
	fi

	if [[ ! $(grep -ari 'live-restore' /etc/docker/daemon.json) ]]
	then
		sed -i '2 i \"live-restore\": true,\n' /etc/docker/daemon.json	
	fi

	
else
        echo -e "{\n  \"live-restore\": true,\n  \
		\"hosts\": [\"fd://\",\"unix:///var/run/docker.sock\",\"tcp://0.0.0.0:2376\"],\n  \
		\"tls\": true,\n  \
		\"tlscacert\": \"/etc/docker/tls/ca.pem\",\n  \
		\"tlscert\": \"/etc/docker/tls/server-cert.pem\",\n  \
		\"tlskey\": \"/etc/docker/tls/server-key.pem\",\n  \
		\"tlsverify\": false\n  \
		}" >> /etc/docker/daemon.json
fi


echo "INFO: change docker systemd file."

# Change docker systemd file
sed -i 's/^ExecStart.*/ExecStart=\/usr\/bin\/dockerd/' /etc/systemd/system/docker.service

systemctl daemon-reload

# set docker host IP addresses

DOCKER_ADDRESS=${DOCKER_HOST_IP:-$(hostname -I|awk '{print $1}')}

cd /etc/docker/tls/


echo "INFO: creating certificates."

### CA certificate
openssl genrsa -out ca-key.pem 4096	&> /dev/null
openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem -subj "/CN=$DOCKER_ADDRESS" &> /dev/null

### SERVER certificate
openssl genrsa -out server-key.pem 4096 &> /dev/null
openssl req -subj "/CN=$DOCKER_ADDRESS" -sha256 -new -key server-key.pem -out server.csr &> /dev/null
echo subjectAltName = DNS:IP:127.0.0.1,IP:$DOCKER_ADDRESS > extfile.cnf
echo extendedKeyUsage = serverAuth >> extfile.cnf
openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem   -CAcreateserial -out server-cert.pem -extfile extfile.cnf &> /dev/null

### CLIENT certificate
openssl genrsa -out key.pem 4096 &> /dev/null
openssl req -subj '/CN=client' -new -key key.pem -out client.csr &> /dev/null
echo extendedKeyUsage = clientAuth > extfile-client.cnf
openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem   -CAcreateserial -out cert.pem -extfile extfile-client.cnf &> /dev/null

chmod 0400 ca-key.pem key.pem server-key.pem ca.pem server-cert.pem cert.pem

mkdir client

# copy client certificates
cp ca.pem client
cp cert.pem client
cp key.pem client

echo
echo "INFO: restarting docker daemon."
systemctl restart docker

rm  client.csr server.csr extfile.cnf extfile-client.cnf

cd /etc/docker
echo
echo "INFO: creating TLS certificates, and configuring docker is finished."
echo "INFO: Copy certificates on /etc/docker/tls/client to your client."
echo "INFO: use this command to communicate with your docker host:"
echo
echo "          docker -H tcp://$(hostname -I|awk '{print $1}'):2376 --tlsverify --tlscacert=ca.pem --tlscert=cert.pem --tlskey=key.pem ps"
echo
echo "make sure that your ip address is accessible from your client."
echo "written by Hosein Yousefi 2022 yousefi.hosein.o@gmail.com"
echo
