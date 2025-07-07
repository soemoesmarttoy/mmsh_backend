#!/bin/bash
set -e

echo "Running migrations..."
bundle exec rails db:migrate

echo "Starting server..."
exec bundle exec rails server -b 0.0.0.0 -p 8080
