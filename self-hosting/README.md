# QSP self-hosting example

A Docker Compose setup that runs a complete QSP instance on one machine:
PostgreSQL, the authentication server, the signaling server and the web client,
all behind one nginx reverse proxy on a single origin.

```shell
cp .env.example .env      # edit QSP_HOST / QSP_PORT if needed
docker compose up -d
```

Then open `http://localhost:8080` (or `http://QSP_HOST:QSP_PORT`).

| Path           | Service                                   |
|----------------|-------------------------------------------|
| `/`            | web client                                |
| `/auth/`       | authentication server (OpenID Connect)    |
| `/signaling/`  | signaling server (agents connect to `ws://HOST:PORT/signaling/server/session`) |

Only `.env` needs editing. `QSP_HOST` / `QSP_PORT` are the public address used by
browsers and agents (the web client's `config.json`, the token issuer and the OAuth
redirect URI are all generated from them). Use a host name or IP that your browser
can reach; there is no hard-coded address. `QSP_SERVER_NAME` and
`QSP_SERVER_DESCRIPTION` set the server identity shown to clients.

Stop with `docker compose down` (add `-v` to also delete the database).

## Good to know

- **This is a trial setup with deliberately light security.** One shared database,
  the PostgreSQL superuser, default passwords from `.env.example`, plain HTTP.
  For a real deployment, change the passwords, add TLS in front and use dedicated
  database roles.
- **WebRTC media is peer-to-peer.** The proxy only carries signaling and
  authentication traffic, never audio/video. Peers behind strict NAT may need a
  TURN server, which is not part of this example.
- Image versions are pinned to released tags (`QSP_*_VERSION`); bump them deliberately.
- Both Java services share one database but keep separate Liquibase tracking tables
  (`auth_databasechangelog*`, `signaling_databasechangelog*`).

## Before first use: the admin account

The auth server seeds a user `admin` with the default development password
`g@~hubf~v9mu`. **Change it before exposing the stack to anyone else.** The admin
API accepts a session login plus a CSRF token (there is no bearer-token access to
`/auth/users`); `PUT /users/{id}` takes `email`, `enabled` and an optional new
`password`:

```shell
BASE=http://localhost:8080
JAR=$(mktemp); curlj() { curl -s -c "$JAR" -b "$JAR" "$@"; }
form_value() { sed -n "s/.*name=\"$1\"[^>]*value=\"\([^\"]*\)\".*/\1/p"; }
CSRF=$(curlj $BASE/auth/login | form_value _csrf)
curlj -o /dev/null --data-urlencode username=admin --data-urlencode 'password=g@~hubf~v9mu' \
      --data-urlencode "_csrf=$CSRF" $BASE/auth/login
CSRF=$(curlj $BASE/auth/login | form_value _csrf)          # fresh token for the signed-in session
ID=$(curlj $BASE/auth/users | sed -n 's/.*"id":"\([^"]*\)","username":"admin".*/\1/p')
curlj -X PUT -H "X-CSRF-TOKEN: $CSRF" -H 'Content-Type: application/json' \
      -d '{"email":"admin@localhost","enabled":true,"password":"NEW_PASSWORD"}' $BASE/auth/users/$ID
```

(`POST /auth/users` creates more users the same way with `username`, `password`,
`email` and `enabled`, but such users have no role yet and cannot sign in: roles can
currently only be set in the database.)

## Create a station and an agent

Everything below goes through the same origin. First get an access token for `admin`
(OAuth2 authorization code with PKCE, as the web client does), then use the
signaling REST API. Tokens are short lived (a few minutes): rerun step 1 on `401`. Callsigns are unique, so
choose a new `mainQRZ` if you repeat step 2.

```shell
BASE=http://localhost:8080          # http://QSP_HOST:QSP_PORT from your .env
read -rsp "admin password: " ADMIN_PASSWORD; echo
JAR=$(mktemp)
curlj() { curl -s -c "$JAR" -b "$JAR" "$@"; }
form_value() { sed -n "s/.*name=\"$1\"[^>]*value=\"\([^\"]*\)\".*/\1/p"; }

# 1. Sign in as admin: OAuth2 authorization code + PKCE (public client "portal")
VERIFIER=$(openssl rand -base64 48 | tr -d '=+/\n')
CHALLENGE=$(printf %s "$VERIFIER" | openssl dgst -sha256 -binary | openssl base64 -A | tr '+/' '-_' | tr -d '=')
AUTHZ="$BASE/auth/oauth2/authorize?response_type=code&client_id=portal&scope=openid%20profile&state=x&code_challenge=$CHALLENGE&code_challenge_method=S256&redirect_uri=$BASE/login-redirect.html"
curlj -o /dev/null "$AUTHZ"                                   # -> redirect to /auth/login
CSRF=$(curlj "$BASE/auth/login" | form_value _csrf)
curlj -o /dev/null --data-urlencode username=admin --data-urlencode "password=$ADMIN_PASSWORD" \
      --data-urlencode "_csrf=$CSRF" "$BASE/auth/login"
PAGE=$(curlj -D - "$AUTHZ")
if ! grep -qi '^location:.*code=' <<<"$PAGE"; then            # first sign-in only: consent screen
  PAGE=$(curlj -D - -o /dev/null --data "client_id=portal&state=$(form_value state <<<"$PAGE")&scope=openid&scope=profile" "$BASE/auth/oauth2/authorize")
fi
CODE=$(sed -n 's/^[Ll]ocation:.*[?&]code=\([^&[:space:]]*\).*/\1/p' <<<"$PAGE")
TOKEN=$(curl -s "$BASE/auth/oauth2/token" -d grant_type=authorization_code -d client_id=portal \
        -d "code=$CODE" -d "redirect_uri=$BASE/login-redirect.html" -d "code_verifier=$VERIFIER" \
        | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
AUTH="Authorization: Bearer $TOKEN"
# 2. Create a station, register an agent and generate its secret
STATION=$(curl -s -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"mainQRZ":"F4XYZ","description":"My station"}' "$BASE/signaling/station" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
AGENT=$(curl -s -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"displayName":"my-agent"}' "$BASE/signaling/station/$STATION/agent" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
SECRET=$(curl -s -H "$AUTH" "$BASE/signaling/station/$STATION/agent/$AGENT/generate-secret" | sed -n 's/.*"secret":"\([^"]*\)".*/\1/p')
echo "agentId=$AGENT"; echo "agentSecret=<${#SECRET} chars>"
curl -s -H "$AUTH" "$BASE/signaling/client/agents"; echo   # [] until the agent connects
```

Give the agent its `agentId` and `agentSecret` (print `$SECRET` to copy it) and point
it at `ws://HOST:PORT/signaling/server/session`. It sends `AGENT_HELLO` with those
two values after the server's `SERVER_HELLO`, and then shows up in
`GET /signaling/client/agents`.

Note: the signaling server only checks that the token is valid; it does not check
roles, so any signed-in user can manage stations.
