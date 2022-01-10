#!/bin/bash

set -x

mkdir -p /tmp/gatewayssl
cd /tmp/gatewayssl || exit 1

#Input $1 should be public routable DNS name for this WebThing gateway
DOMAIN=$1
WEBTHINGS_HOME="${WEBTHINGS_HOME:=${HOME}/.webthings}"
WEBTHINGS_DIST="${WEBTHINGS_DIST:=${HOME}/gateway}"
SSL_DIR="${WEBTHINGS_HOME}/ssl"
REPO_DIR="${WEBTHINGS_HOME}/repos"

#Check DOMAIN is plausible and safe for curl
if ! echo "$DOMAIN" |grep -q '^[A-Za-z0-9][A-Za-z0-9_-]*\.[A-Za-z0-9_-]*$'
then
  echo "Usage $0 gateway.example.com"
  exit
fi

#Now check that curl can retrieve our README.html file at the correct path and 
if ! curl "http://$DOMAIN/.well-known/acme-challenge/README.html" |grep -q 'LetsEncrypt'
then
  echo "Cannot confirm whether LetsEncrypt can perform callback to http://$DOMAIN/.well-known/acme-challenge/<TOKENs>"
  exit 1
fi

#Clone bacme into WEBTHINGS_HOME tree
[ ! -d "${REPO_DIR}" ] && mkdir -p "${REPO_DIR}"
[ ! -d "${REPO_DIR}/bacme" ] && git clone https://gitlab.com/sinclair2/bacme.git ${REPO_DIR}/bacme

#Check bacme runs
if ${REPO_DIR}/bacme/bacme -h |grep -q "example.com"
then
  echo "[  INFO  ] bacme client installed and working"
else
  echo "[ ERROR  ] Unable to use bacme to get LetsEncrypt certificates" >&2
  exit 1
fi

${REPO_DIR}/bacme/bacme -w $WEBTHINGS_DIST/build/static "$DOMAIN"
curl -so $DOMAIN/$DOMAIN.cacerts https://letsencrypt.org/certs/lets-encrypt-r3.pem

[ ! -d "${SSL_DIR}" ] && mkdir -p "${SSL_DIR}"
mv $DOMAIN/$DOMAIN.crt "${SSL_DIR}/certificate.pem"
mv $DOMAIN/$DOMAIN.key "${SSL_DIR}/privatekey.pem"
mv $DOMAIN/$DOMAIN.csr "${SSL_DIR}/csr.pem"
mv $DOMAIN/$DOMAIN.cacerts "${SSL_DIR}/chain.pem"
