#!/bin/bash
echo "Hello World"

sentry-cli --auth-token "token" --url "https://sentry.protontech.ch/" upload-dif --org sentry --project production-57 \
$PATH