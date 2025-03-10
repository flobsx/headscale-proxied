#!/bin/bash

### Setup the environment
mkdir -p secrets
tr -cd '[:alnum:]' < /dev/urandom | fold -w 64 | head -n 1 | tr -d '\n' > secrets/JWT_SECRET
tr -cd '[:alnum:]' < /dev/urandom | fold -w 64 | head -n 1 | tr -d '\n' > secrets/SESSION_SECRET
tr -cd '[:alnum:]' < /dev/urandom | fold -w 64 | head -n 1 | tr -d '\n' > secrets/STORAGE_PASSWORD
tr -cd '[:alnum:]' < /dev/urandom | fold -w 64 | head -n 1 | tr -d '\n' > secrets/STORAGE_ENCRYPTION_KEY
tr -cd '[:alnum:]' < /dev/urandom | fold -w 64 | head -n 1 | tr -d '\n' > secrets/REDIS_PASSWORD
echo "REDIS_PASSWORD=$(cat secrets/REDIS_PASSWORD)" > secrets/.env
echo "POSTGRES_PASSWORD=$(cat secrets/STORAGE_PASSWORD)" >> secrets/.env