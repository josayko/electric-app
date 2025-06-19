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
