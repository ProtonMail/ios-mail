# ProtonMail Common

shared business logic without UIKit.


## Local data storage
Altho we do not yet fully support Offline Mode and cache user data (emails, attachments, etc) opportunistically, there are a number of places where user data can be found: 
1. `CoreData` database for emails, contacts, attachments, labels, and folders. This database should not be included in device backup.
2. Device `Keychain` for critical data and data we want to persist over application reinstalls. This data can be included into backup to be restored only on _same_ device.
3. UserDefaults plist for non-critical data. This will be included into backups and restored everywhere.

All these data storages are shared between the main app target and Share extension, thus we used `AppGroups` capability and `Keychain Groups` capability.

Implementing local data storage, our mental rule was: _if you're a dissident captured by Saudi secret police, will they be able to extract any data from your iPhone that can hurt you or your allies?_
Such way, we're encrypting metadata of messages, contacts, names of labels and some other `NSManagedObject`s attributes (via `NSValueTransformer`s), sensitive data we're storing on `Keychain` and sensitive data we're still storing in `UserDefaults` by historical reasons.

With this thought in mind, but also trying to keep refactor in a mindful scale, we've implemented `Keymaker.framework` which should encrypt sensitive data while stored on device and allow access only when app is not Locked. From a user perspective app can be unlocked by means of PIN code or TouchID/FaceID with fallback to device passcode - according to user settings. These settings are not persisted over relogins or reinstalls.

Long story short, idea was to encrypt all sensitive local data with a key generated on device per-login called Main Key and store it securely in Keychain (haha) allowing to wipe all this data fast by removing this Main Key.
For users who opt in PIN or TouchID/FaceID protection we do not store Main Key itself in Keychain, but encrypt it with something that will never be stored nearby and store only cyphertext on Keychain. In case of PIN protection this something is a key derived from user input PIN, in case of TouchID/FaceID - elliptic curve keypair generated and kept by SecureEnclave co-processor.

Such architecture allows us to implements `Wipe App Data` feature which yet did not have proper marketing: removing MainKey (or it's cyphertext) from Keychain, we draw all sensitive local data useless. This feature is accessible via Siri Shortcuts (custom intent extension target) on iOS 12.

## TLS-Pinning

use a third party framwork

https://github.com/datatheorem/TrustKit