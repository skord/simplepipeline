#!/bin/bash
set -e

if [ -z "$PASSENGER_APP_ENV" ]; then
    echo >&2 'error: no PASSENGER_APP_ENV'
    exit 1
fi

TEMP_FILE='/etc/nginx/sites-enabled/default'
cat > "$TEMP_FILE" <<-EOSQL
    server {
        listen 80;
        server_name _;
        root /home/app/simplepipeline/public;
        passenger_pass_header X-Forwarded-Proto;

        passenger_enabled on;
        passenger_user app;

        passenger_ruby /usr/bin/ruby2.1;

EOSQL

echo "passenger_app_env $PASSENGER_APP_ENV ;" >> "$TEMP_FILE"

echo '}' >> "$TEMP_FILE"
