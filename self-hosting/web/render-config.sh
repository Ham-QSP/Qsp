#!/bin/sh
# Runs at container start (nginx images execute /docker-entrypoint.d/*.sh).
# Renders config.json from QSP_HOST / QSP_PORT so only .env needs editing.
envsubst '${QSP_HOST} ${QSP_PORT}' < /templates/config.json.template > /usr/share/nginx/html/config.json
