#!/bin/bash
set -e

# Source environment variables explicitly if a .env file exists
if [ -f "/var/lib/.env" ]; then
  set -a
  . /var/lib/.env
  set +a
fi

# Check if DB_USER and DB_PASSWORD are set, else exit with error
: ${DB_USER:?"DB_USER is not set"}
: ${DB_PASSWORD:?"DB_PASSWORD is not set"}

CERT_DIR="/var/lib/postgresql/data/ssl"
REGENERATE_THRESHOLD_SECONDS=$((30 * 24 * 3600)) # 30 days
SERVER_KEY="$CERT_DIR/server.key"
SERVER_CRT="$CERT_DIR/server.crt"

echo "$(date): Checking certificate validity..."

NEEDS_GENERATION=false

if [ ! -f "$SERVER_KEY" ] || [ ! -f "$SERVER_CRT" ]; then
  echo "$(date): SSL certificate or key file not found. Generating new certificates..."
  NEEDS_GENERATION=true
else
  if ! openssl x509 -checkend "$REGENERATE_THRESHOLD_SECONDS" -noout -in "$SERVER_CRT" > /dev/null 2>&1; then
    echo "$(date): Certificate expiring within 30 days. Regenerating..."
    NEEDS_GENERATION=true
  else
    echo "$(date): Certificate is valid for more than 30 days."
  fi
fi

if $NEEDS_GENERATION; then
  rm -f "$SERVER_KEY" "$SERVER_CRT"
  mkdir -p "$CERT_DIR"

  # Generate certificate with 90 days validity
  openssl req -new -x509 -nodes -text -subj "/CN=localhost" \
    -out "$SERVER_CRT" -keyout "$SERVER_KEY" -days 90

  chmod 600 "$SERVER_KEY"
  chown 999:999 "$SERVER_KEY" "$SERVER_CRT"

  echo "$(date): New certificates generated with 90 days validity"

  # Signal PostgreSQL to reload configuration
  if docker exec -e PGPASSWORD="$DB_PASSWORD" postgres psql -U $DB_USER -c "SELECT pg_reload_conf();" 2>/dev/null; then
    echo "$(date): PostgreSQL configuration reloaded successfully"
  else
    echo "$(date): Failed to reload PostgreSQL configuration"
  fi
else
  echo "$(date): No certificate renewal needed"
fi
