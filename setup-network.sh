#!/bin/bash
cd ${0%/*}

UNAME=$(uname)

export NETWORK_NAME=$1
if [ -z "$NETWORK_NAME" ]; then
  echo "Please specify a network to set up."
  exit 1
fi

echo

SUBNET=$(docker network inspect -f '{{(index .IPAM.Config 0).Subnet}}' $NETWORK_NAME 2>&1)
if [ "$?" -ne 0 ]; then
  echo "Creating docker network $NETWORK_NAME \c"
  RESULT=$(docker network create $NETWORK_NAME)
  if [ "$?" -ne 0 ]; then
    echo "✖"
    echo $RESULT
    exit 1
  else
    echo "✔"
  fi
  
  SUBNET=$(docker network inspect -f '{{(index .IPAM.Config 0).Subnet}}' $NETWORK_NAME)
else
  echo "Network already exists ✔"
fi

if [[ "$UNAME" == 'Darwin' ]]; then
  echo "Setting up direct access to $SUBNET..."
  echo "You may be prompted for your sudo password..."
  RESULT=$(sudo route -n add $SUBNET $(docker-machine ip $DOCKER_MACHINE_NAME) 2>&1)
  if [ "$?" -ne 0 ]; then
    echo "Could not create route ✖"
    echo $RESULT
    exit 1
  else
    echo "Route created ✔"
  fi
fi

echo -e "Starting DNS server container \c"
docker-compose --project-name $NETWORK_NAME -f ./dns.yml up -d  2>&1 >/dev/null
NAMESERVER_IP=$(docker inspect -f "{{.NetworkSettings.Networks.${NETWORK_NAME}.IPAddress}}" ${NETWORK_NAME}_devdns)
echo "${NAMESERVER_IP} ✔"

if [[ "$UNAME" == 'Darwin' ]]; then
  echo -e "Creating /etc/resolver for network \c"
  sudo mkdir -p /etc/resolver
  sudo rm -f /etc/resolver/${NETWORK_NAME}
  sudo sh -c "echo \"nameserver $NAMESERVER_IP\n\" > /etc/resolver/${NETWORK_NAME}"
  echo "✔"
fi

echo
