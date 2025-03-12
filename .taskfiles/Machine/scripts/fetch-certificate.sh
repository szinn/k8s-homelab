#!/bin/sh
OUTPUT_DIR=$1
TLS_CERT="tech-wildcard-tls"
TLS_NAMESPACE="kube-system"

if [[ ! -e $OUTPUT_DIR/certificate-tls.json ]]; then
  touch $OUTPUT_DIR/certificate-tls.json
fi
kubectl get secret $TLS_CERT -n $TLS_NAMESPACE -ojson > /tmp/cert
DIFF="$(diff /tmp/cert $OUTPUT_DIR/certificate-tls.json)"
if [[ "$DIFF" != "" ]]; then
  kubectl get secret $TLS_CERT -n $TLS_NAMESPACE -ojsonpath="{.data}" | jq '.["tls.crt"]' | sed -e s/\"//g | base64 -d > $OUTPUT_DIR/certificate.crt
  kubectl get secret $TLS_CERT -n $TLS_NAMESPACE -ojsonpath="{.data}" | jq '.["tls.key"]' | sed -e s/\"//g | base64 -d > $OUTPUT_DIR/certificate.key
  cp /tmp/cert $OUTPUT_DIR/certificate-tls.json
  cat $OUTPUT_DIR/certificate.crt $OUTPUT_DIR/certificate.key > $OUTPUT_DIR/certificate.pem
  echo "New certificate extracted"
else
  echo "No change in certificate"
fi
rm /tmp/cert
