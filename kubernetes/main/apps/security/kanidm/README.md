# Bootstrapping Kandidm

```bash
kubectl exec -n security -it statefulset/kanidm -- kanidmd recover-account admin
kubectl exec -n security -it statefulset/kanidm -- kanidmd recover-account idm_admin

kanidm login --name idm_admin
kanidm person create scotte 'Scotte Zinn'
kanidm person update scotte --mail 'scotte@zinn.ca' —legalname 'Scotte Zinn'
kanidm person credential create-reset-token scotte

kanidm group create 'grafana_superadmins'
kanidm group create 'grafana_admins'
kanidm group create 'grafana_editors'
kanidm group create 'grafana_users'

kanidm system oauth2 create grafana 'grafana.zinn.ca' https://grafana.zinn.ca
kanidm system oauth2 set-landing-url grafana 'https://grafana.zinn.ca/login/generic_oauth'
kanidm system oauth2 update-scope-map grafana grafana_users email openid profile groups
kanidm system oauth2 enable-pkce grafana
kanidm system oauth2 get grafana

# Need to copy this secret to 1Password for Grafana
kanidm system oauth2 show-basic-secret grafana


kanidm system oauth2 update-claim-map-join 'grafana' 'grafana_role' array
kanidm system oauth2 update-claim-map 'grafana' 'grafana_role' 'grafana_superadmins' 'GrafanaAdmin'
kanidm system oauth2 update-claim-map 'grafana' 'grafana_role' 'grafana_admins' 'Admin'
kanidm system oauth2 update-claim-map 'grafana' 'grafana_role' 'grafana_editors' 'Editor'

kanidm group add-members grafana_users scotte
kanidm group add-members grafana_admins scotte

kanidm group create 'bookboss_dev_users'
kanidm group add-members bookboss_dev_users scotte

kanidm system oauth2 create bookboss-dev 'odin.zinn.tech' http://odin.zinn.tech:8080
kanidm system oauth2 set-landing-url bookboss-dev 'http://odin:8080/auth/oidc/callback'
kanidm system oauth2 update-scope-map bookboss-dev bookboss_dev_users email openid
kanidm system oauth2 enable-pkce bookboss-dev
kanidm system oauth2 get bookboss-dev

# Need to copy this secret to dev environment
kanidm system oauth2 show-basic-secret bookboss-dev

kanidm group create 'bookboss_users'
kanidm group add-members bookboss_users scotte
kanidm system oauth2 create bookboss 'bookboss.zinn.ca' https://bookboss.zinn.ca
kanidm system oauth2 set-landing-url bookboss 'https://bookboss.zinn.ca/auth/oidc/callback'
kanidm system oauth2 update-scope-map bookboss-dev bookboss_dev_users email openid
kanidm system oauth2 enable-pkce bookboss
kanidm system oauth2 get bookboss

# Need to copy this secret to 1Password for BookBoss
kanidm system oauth2 show-basic-secret bookboss
```
