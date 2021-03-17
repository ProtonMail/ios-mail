# Log module

The module logs the provided data to console (in Debug builds) and to a text file called `logs.txt` and located in `Library` directory.

It allows to hook up other logging systems, like `Sentry`.

## Installation

Only `Cocoapods` is supported at the moment.

## Usage

All logging methods are accessed via the `PMLog` class and its static methods: `debug(:)`, `info(:)`, `error(:)`.

You can access the `logs.txt` file directly with the `PMLog.logFile` property, or just read its content with `PMLog.logsContent()`.

### Using 3rd party loggers

You can use the `PMLog.callback(message, LogLevel)` property to hook up any 3rd party logging system.

Example for `Sentry`

```swift
PMLog.callback = { message, level in
    guard level == .error else {
        return
    }

    // Send to Sentry along with stacktrace
    Client.shared?.snapshotStacktrace {
        let event = Event(level: level.sentryLevel)
        event.message = message
        Client.shared?.appendStacktrace(to: event)
        Client.shared?.send(event: event)
    }
}
```

## Development

### Unit tests

This project has number of unit tests, automatically run via `Fastlane` by `GitLab CI`. The `Gitlab CI` configuration is located in `.gitlab-ci.yml` and the `Fastlane` configuration in `fastlane/Fastfile`.