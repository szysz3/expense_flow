# <img src="https://github.com/user-attachments/assets/40f6c7b3-30d2-47df-8229-29fc836bf4e6" width="48" height="48"> expense flow mobile

# Setup
```.setup.sh``` 

Get dependencies, generate models and translations.
## Env

```
.env.prod
.end.demo
```

Create .env files and fill with proper keys:
```
API_BASE_URL=<api_base_url>
CHAT_WEBSOCKET_URL=<chat_base_url>
API_KEY=<api_key>
```

## Flavors
```flutter run --flavor prod -t lib/main_prod.dart```

There are 2 flavors ```prod``` and ```demo```.

# Tests

```melos run coverage:full```

Run tests with coverage.

```./scripts/generate_coverage_helpers.sh```

Generate fake tests with class imports to include in code coverage.
