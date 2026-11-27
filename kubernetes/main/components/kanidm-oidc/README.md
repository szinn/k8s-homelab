# kanidm-oidc

Puts a Kanidm login in front of an app that has no SSO of its own, using an
Envoy Gateway `SecurityPolicy` with the built-in OIDC filter. No oauth2-proxy
is needed.

The component creates:

- `ExternalSecret/${APP}-oidc`: reads `OAUTH_CLIENT_SECRET` from the 1Password
  item named `${APP}` and writes it to `Secret/${APP}-oidc-secret` under the
  `client-secret` key, the key Envoy Gateway reads.
- `SecurityPolicy/${APP}-oidc`: targets `HTTPRoute/${APP}`, using Kanidm client
  `${APP}`.

## Requirements

- The app's HTTPRoute is named `${APP}`. app-template does this when the
  `route:` key matches the release name.
- The Kanidm OAuth2 client is named `${APP}`.
- The 1Password item `${APP}` has an `OAUTH_CLIENT_SECRET` field.

## Kanidm setup

Replace `<app>` and `<host>`:

```bash
kanidm group create '<app>_users'
kanidm group add-members '<app>_users' scotte

kanidm system oauth2 create '<app>' '<host>' 'https://<host>'
kanidm system oauth2 add-redirect-url '<app>' 'https://<host>/oauth2/callback'
kanidm system oauth2 update-scope-map '<app>' '<app>_users' openid email profile
kanidm system oauth2 get '<app>'

# Copy this into the 1Password item '<app>' as OAUTH_CLIENT_SECRET
kanidm system oauth2 show-basic-secret '<app>'
```

PKCE stays on (the Kanidm default); Envoy sends a code verifier.

## Usage

In the app's `install.yaml`:

```yaml
spec:
  components:
    - ../../../../components/kanidm-oidc
  postBuild:
    substitute:
      APP: <app>
```

## Notes

- This gates browser access only. API clients and mobile apps that call the
  same host will get redirected to Kanidm. Either give them a separate route or
  add `oidc.denyRedirect` matchers for their headers.
- Logout clears Envoy's cookies at `/oauth2/logout`; the Kanidm session itself
  stays active.
