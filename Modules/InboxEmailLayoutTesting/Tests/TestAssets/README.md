# Mailing Snapshot Testing

Offline snapshot testing for mailing HTML rendering using WKWebView.

## Usage

### 1. Prepare Mailing - downloads all remote resources.

```bash
cd Modules/InboxEmailLayoutTesting/Tests/TestAssets
./prepare_mailing.py Mailings/{mailing-name}/{mailing-name}-index.html mailing-name
```

### 2. Add Test

Extend `mailings` array in `MailingSnapshotTests.swift` with new mailing name.

```swift
@MainActor
final class MailingSnapshotTests: XCTestCase {
    let mailings: [String] = [
        "google-dec-2025",
        "new-mailing" // Add your mailing here
    ]

    func testMailingWithLocalResources() throws {
        try mailings.forEach { name in
            ...

            assertSnapshot(
                of: webVC,
                as: .wait(for: 1.0, on: .image),
                named: name,
                record: true // Set record to true
            )
        }
    }
}
```

### 3. Run Test

Snapshots are saved to `__Snapshots__/MailingSnapshotTests/`

## How It Works

- `prepare_mailing.py` downloads images/CSS/fonts
- `LocalResourceSchemeHandler` intercepts `proton-https://` URLs and serves local files
- Tests run completely offline with no network requests

## Directory Structure

```
TestAssets/
├── prepare_newsletter.py
└── Mailings/
    └── mailing-name/
        ├── mailing-name-index.html
        └── *.png, *.jpg, *.gif, etc.
```
