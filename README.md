Mail iOS App for the Engineering Transformation project
=======================
Copyright (c) 2024 Proton Technologies AG

## Setup instructions
1. Make sure you have access to the following repositories, if you don't ask the team:
  - https://gitlab.protontech.ch/apple/inbox/mail
  - https://gitlab.protontech.ch/apple/shared/et-protoncore
  - https://gitlab.protontech.ch/apple/shared/ProtonUIFoundations
2. Install Xcode (>=16.3)
3. Clone the repository
4. Add a `.env` file with necessary secrets. The file is stored in a shared Pass vault. Request access to the team.
5. Run `./scripts/setup.sh` to generate the xcodeproj file.
6. Open `ProtonMail.xcodeproj`

## Troubleshooting

1. Once you open Xcode, if dependencies fail to resolve close Xcode and resolve them from the Terminal:

```
xcodebuild -resolvePackageDependencies -project ProtonMail.xcodeproj
```

## UI Tests setup instructions
1. Clone the mocks repository locally https://gitlab.protontech.ch/android/mail/mail-apps-network-mocks. It's recommended to clone the mocks repository into the same parent directory as this project.
2. From the Mail iOS App project root, run `./scripts/uitests/setup-mock-network-assets.sh setup-local`
3. Follow the instructions and regenerate the project with `xcodegen`. 

## Debug helpers

### How to Access the Rust-Core SQLite Databases in the Simulator

1. Locate the simulator files by navigating to `~/Library/Developer/CoreSimulator/Devices/<simulator device id>`.
2. If you're unsure about the device id, you can find it in the log or by accessing it through `Xcode > Window > Devices and Simulators`.
3. Once in the device directory, conduct a recursive search for `session.db` within the `data` directory. This will unveil the `Application Support` folder housing all rust-core databases.
4. Use your preferred SQLite inspection tool to inspect the SQLite files.
