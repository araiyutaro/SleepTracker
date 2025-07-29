#!/bin/bash
echo "Running Sleep app in PROD mode..."
flutter run --flavor prod --target lib/main_prod.dart "$@"