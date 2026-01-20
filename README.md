Mail iOS App for the Engineering Transformation project
=======================
Copyright (c) 2024 Proton Technologies AG

## Setup instructions
1. Make sure you have access to the following repositories, if you don't ask the team:
  - https://gitlab.protontech.ch/apple/inbox/mail
  - https://gitlab.protontech.ch/apple/shared/et-protoncore
  - https://gitlab.protontech.ch/apple/shared/ProtonUIFoundations
2. Install Xcode (>=26.2)
3. Clone the repository
4. Add a `.env` file with necessary secrets. The file is stored in a shared Pass vault. Request access to the team.
5. Run `./scripts/setup.sh` to generate the xcodeproj file.
6. Open `ProtonMail.xcodeproj`

## Troubleshooting

1. Once you open Xcode, if dependencies fail to resolve close Xcode and resolve them from the Terminal:

```
xcodebuild -resolvePackageDependencies -project ProtonMail.xcodeproj
```

## Debug helpers

### LLDB/RustRover debugging setup

The app uses a Rust framework built from $RUST_REPO_DIR. To debug Rust code with full breakpoint and variable inspection support:

#### 1. Build Debug Framework

```bash
cd $RUST_REPO_DIR
rust-build/build_ios_framework_uniffi.sh proton-mail-uniffi ./mail/mail-uniffi/uniffi.toml "./tmp/ios-framework-debug" ios-debug
```

> For build profile comparison (debug vs release), see [rust-build/README.md](https://gitlab.protontech.ch/proton/mobile/backend/proton-rust/-/blob/main/rust-build/README.md)

#### 2. Choose Your Debugger

**Option A: LLDB (Xcode Console)**

1. Launch app from Xcode (Cmd+R)
2. The build phase automatically configures LLDB source mapping
3. Set breakpoints in LLDB console:
   ```lldb
   (lldb) breakpoint set --name your_rust_function_name
   (lldb) breakpoint set --file src/lib.rs --line 42
   (lldb) continue
   ```
4. When breakpoint hits:
   ```lldb
   (lldb) frame variable     # show local variables
   (lldb) print var_name     # print specific variable
   (lldb) step              # step into
   (lldb) next              # step over
   ```

**Option B: RustRover/IDE (GUI Debugger)**

For full IDE debugging with visual breakpoints and variable panels:

1. Disable Xcode debugger:
   - Product → Scheme → Edit Scheme (Cmd+<)
   - Run → Info tab
   - Uncheck "Debug executable"
   - *(Only one debugger can attach at a time)*

2. Launch iOS app from Xcode (Cmd+R)

3. In RustRover:
   - Run → Attach to Process (or Cmd+Shift+A)
   - Search for "ProtonMail"
   - Click "Attach"

4. Set breakpoints by clicking the left margin in Rust source files

5. Debug with full GUI:
   - Variables panel
   - Stack trace navigation
   - Step into/over/out buttons
   - Expression evaluation

### How to Access the Rust-Core SQLite Databases in the Simulator

1. Locate the simulator files by navigating to `~/Library/Developer/CoreSimulator/Devices/<simulator device id>`.
2. If you're unsure about the device id, you can find it in the log or by accessing it through `Xcode > Window > Devices and Simulators`.
3. Once in the device directory, conduct a recursive search for `session.db` within the `data` directory. This will unveil the `Application Support` folder housing all rust-core databases.
4. Use your preferred SQLite inspection tool to inspect the SQLite files.
