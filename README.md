# Notification Grabber

Android notification collector built with Flutter to capture device notifications, forward them to an API, and create a real-world dataset for Machine Learning.

This project is an **Android notification listener**, **Flutter notification monitor**, and **data collection app** designed to feed the backend in [`wdvictor/is_that_a_pix_api`](https://github.com/wdvictor/is_that_a_pix_api). The long-term goal is to populate a database with real notification samples that can be used to **train a Machine Learning algorithm** for **notification classification**, including **financial notifications** and potential **PIX-related notifications**.

## Why this project exists

Modern Android devices receive a huge volume of transactional, banking, fintech, commerce, and system notifications. This app exists to:

- capture real Android notifications in background;
- extract package/app metadata and notification text;
- send that data to the API repository [`is_that_a_pix_api`](https://github.com/wdvictor/is_that_a_pix_api);
- persist failed deliveries locally;
- allow retrying failed payloads later;
- help build a dataset for **Machine Learning**, **notification mining**, and **financial notification detection**.

In practice, this repository is the **mobile data ingestion layer** of a larger pipeline.

## Main use case

The main purpose of this app is to populate a database used by the API in [`wdvictor/is_that_a_pix_api`](https://github.com/wdvictor/is_that_a_pix_api). That database is intended to support experiments and model training for a **Machine Learning algorithm** capable of learning patterns from real notification messages.

Possible ML and data science use cases include:

- notification classification;
- financial notification detection;
- PIX notification identification;
- message pattern analysis;
- labeled dataset generation for mobile notifications;
- research on banking and payment notification flows.

## How it works

1. The app runs on **Android** and listens for posted notifications using `NotificationListenerService`.
2. When a notification arrives, the app extracts the package name and visible text content.
3. The notification is processed in a **Flutter background engine** through a `MethodChannel`.
4. The app sends the payload to the configured API endpoint.
5. If the API call fails, the payload is saved locally in an offline queue.
6. The user can open the app, inspect failed deliveries, and retry individual items or all pending items.
7. Local failure notifications help surface delivery problems immediately.

## Current payload sent to the API

The app currently sends a request like this:

```json
{
  "app": "com.example.app",
  "text": "Notification text captured from Android",
  "is_financial_notification": null
}
```

If you want to reproduce the full pipeline locally or in your own infrastructure, check the backend documentation in:

- [`wdvictor/is_that_a_pix_api`](https://github.com/wdvictor/is_that_a_pix_api)

Use that repository to deploy your own backend and point this app to your own API instance.

The backend host is configured through `.env`, and endpoint paths are centralized in the app. The first configured path is `add_notification`, with room for more endpoints later.

## Features

- Android notification capture in background
- Flutter + native Android bridge via `MethodChannel`
- Background processing with a dedicated Flutter engine
- Delivery to external REST API
- Offline queue for failed deliveries
- Local persistence with `shared_preferences`
- Retry one failed notification
- Retry all failed notifications
- Details screen with request and response history
- Local failure notification with quick navigation to details

## Tech stack

- **Flutter**
- **Dart**
- **Kotlin**
- **Android NotificationListenerService**
- **MethodChannel**
- **flutter_local_notifications**
- **shared_preferences**
- **REST API integration**
- **Machine Learning data collection pipeline**

## Architecture summary

The project is split into a few clear layers:

- **Android native layer**: listens to notifications and starts background processing.
- **Background bridge**: boots a secondary Flutter engine and forwards native events.
- **Application layer**: coordinates notification processing and retries.
- **Data layer**: sends HTTP requests, stores failed payloads, and manages local notifications.
- **Presentation layer**: shows offline queue, retry actions, and delivery details.

This architecture makes the app useful not only as a mobile client, but also as a **notification ingestion agent** for research and ML dataset generation.

## Related repository

Backend/API repository:

- [`wdvictor/is_that_a_pix_api`](https://github.com/wdvictor/is_that_a_pix_api)

This app is designed to work together with that API so the captured notifications can be stored in a database and later used in data analysis and Machine Learning workflows.

## Project setup

### Requirements

- Flutter SDK
- Android SDK
- An Android device or emulator
- Internet access
- An API key accepted by the backend

### Environment configuration

Create a `.env` file in the root of the project with:

```env
X_API_KEY=YOUR_API_KEY_HERE
BACKEND_BASE_URL=https://your-backend.example.com
```

The Android build reads these values and exposes them to the background processor.

- `X_API_KEY`: API key sent in the `X-API-Key` header
- `BACKEND_BASE_URL`: base URL of your own backend, for example `https://your-backend.example.com`

The app combines `BACKEND_BASE_URL` with the centralized endpoint definitions in code. The first endpoint currently configured is `add_notification`.

If you want to reproduce the same ingestion pipeline, use the backend repository documentation to deploy your own API:

- [`wdvictor/is_that_a_pix_api`](https://github.com/wdvictor/is_that_a_pix_api)

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

## Android permissions and required user actions

To work correctly, the app depends on:

- notification access permission via Android settings;
- notification posting permission for local alerts;
- internet access to deliver data to the API.

After opening the app, grant:

- **Notification access** so Android allows the app to read posted notifications.
- **Notification permission** so the app can show local alerts when delivery fails.

## Offline-first behavior

If the backend is unavailable or the request fails:

- the notification is stored locally;
- the app shows a local failure notification;
- the failed item appears in the offline queue;
- the user can retry later.

This makes the app useful for unstable network environments and for long-running dataset collection sessions.

## Intended audience

This repository may be useful for:

- Flutter developers building Android notification listeners
- mobile data engineering experiments
- Machine Learning and Data Science projects
- fintech research prototypes
- notification classification pipelines
- PIX and payment notification analysis

## Privacy and responsible use

This app can capture notification content, which may include sensitive or personal information.

Use it only:

- on devices you own, control, or have explicit permission to analyze;
- with full awareness of privacy, security, and legal implications;
- in compliance with local law, platform policies, and user consent requirements.

If you plan to publish datasets or train models with collected data, review your data governance, anonymization, and retention strategy first.

## Suggested GitHub topics

You can add these repository topics in GitHub settings to improve discoverability:

- `flutter`
- `dart`
- `android`
- `kotlin`
- `notification-listener`
- `android-notifications`
- `flutter-app`
- `machine-learning`
- `dataset`
- `data-collection`
- `notification-classification`
- `financial-notifications`
- `pix`
- `fintech`
- `android-monitoring`

## SEO keywords and search phrases

This section is intentional to improve visibility on Google and GitHub for people searching for this kind of project.

- Android notification listener with Flutter
- Flutter Android notification capture app
- Android notification collector for Machine Learning
- notification dataset generator
- Android notification monitoring app
- Flutter app for capturing notifications
- financial notification dataset
- PIX notification dataset
- payment notification classifier dataset
- mobile data collection for Machine Learning
- notification classification pipeline
- Android NotificationListenerService example
- Flutter MethodChannel background processing
- offline queue for API delivery
- notification scraping app for research
- mobile notification ingestion pipeline
- Android notification parser
- fintech notification analysis
- ML training data from notifications
- notification text mining on Android

## Roadmap ideas

- configurable backend endpoint
- export/anonymization pipeline
- labeling workflow for supervised learning
- package allowlist/blocklist management
- deduplication and normalization rules
- dashboard metrics for collected samples
- confidence scoring and pre-labeling support

## License

No license file is currently defined in this repository. Add one before open-source distribution if needed.
