---
apiVersion: v1
kind: Secret
metadata:
  name: onepassword-connect-secret
  namespace: external-secrets
stringData:
  1password-credentials.json: op://Private/1Password/OP_CREDENTIALS_JSON
  token: op://Private/1Password/OP_CONNECT_TOKEN
---
apiVersion: v1
kind: Secret
metadata:
  name: wildcard-tls
  namespace: kube-system
  annotations:
    cert-manager.io/alt-names: '*.test.zinn.ca,test.zinn.ca'
    cert-manager.io/certificate-name: wildcard
    cert-manager.io/common-name: test.zinn.ca
    cert-manager.io/ip-sans: ""
    cert-manager.io/issuer-group: ""
    cert-manager.io/issuer-kind: ClusterIssuer
    cert-manager.io/issuer-name: letsencrypt-prod
    cert-manager.io/uri-sans: ""
  labels:
    controller.cert-manager.io/fao: "true"
type: kubernetes.io/tls
data:
  tls.crt: op://Kubernetes/cluster-staging/wildcard-crt
  tls.key: op://Kubernetes/cluster-staging/wildcard-key
