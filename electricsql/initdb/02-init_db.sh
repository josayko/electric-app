#!/bin/sh
set -e

# The initial psql connection remains as the superuser (postgres)
# This user has the necessary privileges to create databases, users, and tables.
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
  -- Create the application user with REPLICATION and LOGIN roles
  CREATE USER $APP_DB_USER WITH REPLICATION LOGIN PASSWORD '$APP_DB_PASS';

  -- Create the application database
  CREATE DATABASE $APP_DB_NAME;

  -- Grant all privileges on the database to the application user
  GRANT ALL PRIVILEGES ON DATABASE $APP_DB_NAME TO $APP_DB_USER;

  -- Change the owner of the database to the application user
  ALTER DATABASE $APP_DB_NAME OWNER TO $APP_DB_USER;

  -- Connect to the newly created database (still as the superuser POSTGRES_USER)
  -- This allows the superuser to create tables within the APP_DB_NAME database.
  \connect $APP_DB_NAME

  BEGIN;
    -- Create the todo table
    -- This table will be owned by the $POSTGRES_USER (e.g., 'postgres') who is currently connected.
    CREATE TABLE todo (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      description TEXT NOT NULL,
      completed BOOLEAN NOT NULL DEFAULT FALSE,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    -- Insett some initial data into the todo table
    INSERT INTO todo (description, completed) VALUES
      ('First Todo Item', FALSE),
      ('Second Todo Item', TRUE),
      ('Third Todo Item', FALSE);
  COMMIT;

  -- Set owner of the table
  ALTER TABLE todo OWNER TO $APP_DB_USER;

  -- Optional but recommended: Set default privileges for future objects
  -- created by the $POSTGRES_USER in the 'public' schema, so they are
  -- automatically granted to $APP_DB_USER.
  -- This is useful if the superuser creates more tables later.
  ALTER DEFAULT PRIVILEGES FOR ROLE $POSTGRES_USER IN SCHEMA public GRANT ALL ON TABLES TO $APP_DB_USER;
  ALTER DEFAULT PRIVILEGES FOR ROLE $POSTGRES_USER IN SCHEMA public GRANT ALL ON SEQUENCES TO $APP_DB_USER;

  -- Also grant USAGE on the schema if you explicitly use schemas or want to be explicit.
  -- The public schema usually has USAGE granted to PUBLIC by default, but this doesn't hurt.
  GRANT USAGE ON SCHEMA public TO $APP_DB_USER;

EOSQL

