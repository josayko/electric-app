#!/bin/bash
set -e

# Define the directory within the container where certificates will be stored
CERT_DIR="/var/lib/postgresql/data/ssl"
PG_CONF="/var/lib/postgresql/data/postgresql.conf"
SERVER_KEY="$CERT_DIR/server.key"
SERVER_CRT="$CERT_DIR/server.crt"

# Define the minimum validity period (in seconds) before regeneration
# 30 days = 30 * 24 * 3600 = 2592000 seconds
# Certificates will be regenerated if they expire within this period.
REGENERATE_THRESHOLD_SECONDS=$((30 * 24 * 3600)) # 30 days

# Create the certificate directory if it doesn't exist
mkdir -p "$CERT_DIR"

# Flag to determine if certificates need to be generated
NEEDS_GENERATION=false

# 1. Check if certificate files exist
if [ ! -f "$SERVER_KEY" ] || [ ! -f "$SERVER_CRT" ]; then
  echo "SSL certificate or key file not found. Generating new certificates..."
  NEEDS_GENERATION=true
else
  # 2. If files exist, check if the certificate is expired or expiring soon
  # openssl x509 -checkend returns 0 if valid for specified seconds, 1 otherwise [1][5]
  if ! openssl x509 -checkend "$REGENERATE_THRESHOLD_SECONDS" -noout -in "$SERVER_CRT" > /dev/null 2>&1; then
    echo "SSL certificate found but will expire within $((REGENERATE_THRESHOLD_SECONDS / 86400)) days or has already expired. Regenerating..."
    NEEDS_GENERATION=true
  fi
fi

# If certificates need generation (either not found or expired/expiring soon)
if $NEEDS_GENERATION; then
  # Remove existing certs if they were there to ensure a clean regeneration
  rm -f "$SERVER_KEY" "$SERVER_CRT"

  echo "Generating new self-signed SSL certificates for PostgreSQL..."
  # Generate a new self-signed certificate and key
  # -nodes: no encryption for the private key (simplifies automation)
  # -days 365: certificate valid for one year (adjust as needed)
  # -subj "/CN=localhost": Common Name for the certificate, set to localhost
  openssl req -new -x509 -nodes -text -subj "/CN=localhost" -out "$SERVER_CRT" -keyout "$SERVER_KEY" -days 365
  echo "Certificates generated in $CERT_DIR."
else
  echo "SSL certificates exist and are valid. Skipping generation."
fi

# Set correct file permissions and ownership required by PostgreSQL
# The private key must be readable only by the owner (postgres user, UID 999)
chmod 600 "$SERVER_KEY"
# Ensure files are owned by the postgres user (UID 999 for official postgres images)
chown 999:999 "$SERVER_KEY" "$SERVER_CRT"

echo "SSL certificates generated in $CERT_DIR"

echo "INFO: Updating postgresql.conf for SSL settings..."
# Ensure ssl is enabled
if grep -q "^ssl =" "$PG_CONF"; then
    sed -i "s/^ssl = .*/ssl = 'on'/" "$PG_CONF"
else
    echo "ssl = 'on'" >> "$PG_CONF"
fi

# Set the path for the server certificate file
if grep -q "^ssl_cert_file =" "$PG_CONF"; then
    sed -i "s|^ssl_cert_file = .*|ssl_cert_file = '$CERT_DIR/server.crt'|" "$PG_CONF"
else
    echo "ssl_cert_file = '$CERT_DIR/server.crt'" >> "$PG_CONF"
fi

# Set the path for the server private key file
if grep -q "^ssl_key_file =" "$PG_CONF"; then
    sed -i "s|^ssl_key_file = .*|ssl_key_file = '$CERT_DIR/server.key'|" "$PG_CONF"
else
    echo "ssl_key_file = '$CERT_DIR/server.key'" >> "$PG_CONF"
fi

echo "INFO: postgresql.conf updated."

