# dev-postgres

Development container with SSL enforced. Database initialization script in `./initdb/02-init_db.sh`.


## Start postgres database containers

```
$ docker-compose up -d
```

### Connect to the database via CLI

```
$ psql "postgresql://your-postgres-user@localhost:5432/postgres?sslmode=require"
```

## Caddy
### Trust Caddy's self-signed certificate
If using Caddy with HTTPS on port 8443, you will need to trust the self-signed certificate.
Otherwise use port 8080 for local development.
#### On macOS
1. In `caddy-certs` directory, doucle click on `root.crt` to open it in Keychain Access
2. Doubble click the added certificate and select `Always Trust` in the context menu

#### On Windows
1. Double-click `root.crt` in `caddy-certs` directory

#### On Linux
1. Copy `root.crt` from `caddy-certs` directory to `/usr/local/share/ca-certificates/`
