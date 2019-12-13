# iOS mail Changelog

## v1.11.13

* Added trash and archive swipe gestures in the sent folder
* Added TLS-Pinning hard fail to the confirm dialog
* Added iPad multiple window support (present since the last version)
* Opening a draft from search now opens the composer instead of the message view
* Fixed crash when restoring the app to empty mailbox
* Fixed iPadOS 13 crash when changing default browser in settings
* Fixed the "open new link" action sheet on iOS 13
* Disabled the importing of contact notes (waiting for Apple's permission before re-enabling this feature)
* Fixed ECC key signature issue
* Fixed email verification deeplink on iOS 13
* Improvements to the Siri Shortcuts feature

## v1.11.12

* Fixes/Improvements
* Fully compliable with iOS 13 include multiple windows on iPadOS
* Some messages can't be decrypted
* New sub-user can't use the address before using it on web app
* Subscriptions screen minor update
* App crash after entering the PIN incorrectly for 10 times
* Showing notification when an email has not been sent
* Crashes if you open a message while swiping down on the "no connection" error message
* App slowdown in composer autocomplete list with the big contact list
* Print confirmation crashes the app
* Cache downloaded attachments
* App state is not restored after memory pressure
* Allows to choose Language in Settings on iOS 13
* Login/Unlock screen with TouchID/FaceID improvements
* Fixed the mailbox decryption view is re-opened after minimize
* Add an option to share clear body
* Add empty custom folder/label option
* Add option to mark messages in spam as read
* Add the default folders under "Folders" in message view
* Add option to set default browser within Settings of ProtonMail
* Emails from contacts are displayed by header info instead of contact info
* Close the recipient bubble only if the user intentionally deselects the field
* Remove empty space from emails in contacts
* The country selector for SMS verification is stuttering
* Add delay to Pull-to-refresh so animation will seem longer
* The message view can't stop horizontal scroll while zoomed in
* Horizontally flip the side-menu logout icon
* Show message date instead of the time when details aren't expanded
* Specific video crashes the app when shared
* Strip EXIF from image attachments
* Quick actions don't work from App Bar on iPadOS
* UnDecryptable attachments crash the app
* 3D Touch (Quick Actions) for springboard icon
* Automatically paste two-factor (2FA) authentication code
* Clicking "View Plans" button when trying to change the mobile signature on free account reverts the app to inbox
* Send local notifications to the user when the token is about to expire
* Updated Mont Blanc background image to a higher resolution
* App performance and stability improve
* Update the crypto library
* Languages:
  * all languages got updated

## v1.11.11

* Improved the stability when opening the message from the notification
* Fixed the MobileSignature redirect to ServicePlan issue
* Fixed the Print issue
* Deprecated some unused API parameters
* Other mirror improvements
* This build has a Key migration phrase 1

## v1.11.10

*** This is the last version to support iOS 9. ***

* Fixes:
  * Composer didn't work when sharing if PIN protection is active
  * Some newsletters layout rendering issues
  * Dialing international numbers was missing the + call sign
  * The keyboard didn't dismiss in the composer
  * Missing archive option in the 'Sent' folder when labeling messages
  * Some photos were automatically rotated when they are pasted in the composer
  * PDF attachment was still visible through the TouchID screen
  * Obfuscated code was shown instead of the correct message contents when saving a draft
  * Messages were not opening when you tap the banner notification
  * 'Print' and 'View Headers' option didn't work properly
* Improvements:
  * Added a warning when permanently deleting a message
  * Don't cancel multiple message selection unless action is applied to the messages
  * Increased the display name and the address to two lines in composer contact group selection
  * Removed the bottom separator line in composer on iOS 10
  * Increased the minimal height of the composer editor.
  * Chinese and Catalan translation strings
  * General performance and stability improvements
* Add new languages:
  * Japanese
  * Indonesian

### Added

### Changed
