# iOS mail Changelog

## v4.0.0
    
Introducing Proton's refreshed look. As we continue to make privacy accessible to everyone, we've updated our apps to provide you with an even better experience with our services.


## v3.1.4
    
We are excited to introduce the new ProtonMail app for iOS! This is the biggest redesign of our mobile app ever, and it was all made possible thanks to your feedback and input.
    
It offers a sharp new look while still protecting your emails and contacts with Proton's signature end-to-end encryption.
    
With the new app you can:
* Discover a modern look and feel with an easy-to-use interface, which means less time managing your inbox, and more time enjoying it.
* Leverage conversation view to keep your inbox clean and organized: emails that belong together will be grouped together.
* Enjoy your app in Dark mode for improved readability in low light conditions.
* Quickly access folders, subfolders and labels with our redesigned side menu.
* Easily create new folders and labels while moving messages to organize your inbox more easily.
* Find all your unread messages easily with the new unread filter.
* Keep track of relevant notifications: reading a message on web will clear the notification from the phone.
* Never forget to add attachments again. If you intended to add an attachment but forgot to, ProtonMail will remind you before sending the message.
* Provide your feedback directly to Proton from the side menu.
* Benefit from a large number of bug fixes and other minor improvements.


## v1.15.8
    
Improvements:
* Fixed occasional crash when opening certain message from the system notifications
* Fixed rare cases where the buttons in some top navigation menus were not visible
    
Changes:
* Removed the option to create addresses with @protonmail.ch domain from the account signup


## v1.15.7
  
Fixes: 

* Translation error in the side menu


## v1.15.6    
    
Fixes:

* Draft saving issues if repeated multiple times
* Sending issues when a public key is attached in a few edge cases
* A black screen can pop up after logging on iOS 15
* Some colors are off on iOS 15
* The composer's header can be transparent on iOS 15
* The synchronisation of draft can fail between the app and the web


## v1.15.4

Improvements:

* Better encryption and security with GopenPGP library v2.1.10
* Better communication when a folder is empty
    
Fixes:

* App crashes after ending a session on web
* App crashes when searching for contacts with a string recognition
* App crashes after invalid recipient address entered in the composer in certain cases
* Greyed out icons making a user unable to reply/forward an email if the body is blank


## v1.15.3
    
Improvements:

* Preventing a user to be logged out after updating the app
* Communicating better to a user when he needs to update the app
* Having a more secure human verification during sign up
    

Fixes:

* Synchronisation bugs leading to diverse annoyances: inbox not showing new messages, moved or deleted message on web not being updated on iOS, infinite spinner
* Scrolling down to the end of the message can be impossible after expanding the header
* Spam messages can reappear in the Spam folder after deletion
* Expired messages remain visible in certain cases when the user is replying
* App freezing/crashes when coming back from the background


## v1.14.1
    
* Keyboard slowness happening in certain cases when writing long emails


## v1.14.0
    
Features:

* Key migration implementation (Preparation for advanced mail sending features)
* More security with a new password of 8 characters minimum

Improvements:

* Clearer communication that a user having a VPN plan cannot perform a Proton Mail paid plan in app
* Clearer communication in Settings that app PIN and touch security are only enabled until log out

Fixes:

* Messages appearing encrypted in certain cases of sending with custom address
* App crashing in the background when tasks are piling up
* Newly created custom address not showing in certain scenarios
* App sometimes crashing when sharing photo from Phone Gallery
* New address added to an existing contact not being immediately effective
* App crashing when adding a photo from Phone Gallery twice in a row
* Impossibility to scroll down to the end of the message when expanding the attachment list
* Duplicated folders or labels for some specific accounts
* Decryption error on auto-forwarded messages


## v1.13.0 & v1.13.1
    
Improvements:

* Stabilized GopenPGP v2 library for better encryption
* Better Networking module for faster and safer operations
* Diverse UX enhancements

Fixes:

* Fixed tapping "TO" field when writing an email with iOS 14.5 Beta is dysfunctional
* Fixed Wrong "time out" message when an account needs a change of password
* Fixed irrelevant message "Sending" still displayed after a message is sent in some cases
* Fixed alternative route to API when it's blocked
* Fixed timeout message missing when logging
* Fixed crash when the mailbox storage's size is getting over the limitation
* Fixed crash when clicking notification to open message in certain cases
* Fixed default address change option for your account
* Fixed messages from secondary account displayed in the search results
* Fixed sign up flow failing with human verification option
* Fixed logging out desynchronisation between web and mobile
* Fixed duplicate messages in the 'Inbox' folder after a long time without opening the app
* Fixed message body not sent completely in case of a very long message and in some edge cases
* Fixed contact birthday format
* Fixed abnormal display of emoji in the composer when replying
* Fixed syncing issues with the app after messages have been imported on the account
* Fixed numbers within an email message opening up a web page instead of proposing to make a phone call
* Fixed blank screen when composing a reply in case of a long content conversation
* Fixed draft being empty if the draft is opened from search results in certain scenarios
* Fixed error messages linked to app store purchases when opening the app
* Fixed email address overlapping the expand icon when typing it by hand
* Fixed contacts search keyboard appearing grey instead of default black
* Fixed crash after rotation in enter password page
* Fixed sending message being overridden by draft because of wrong sequence of treatment
* Fixed message content not saved in a draft message if the message sending failed in a certain scenario
* Fixed system checks when sending an email while in offline mode
* Fixed sending a message if attachments are still being uploaded
* Fixed message reappearing online after being deleted offline
* Fixed correct signature not being displayed if a switch of sender being performed on a draft saved on web
* Removed the "continue and don't ask again option" on confirm link modal
* Fixed content load error when a draft is saved and later sent without subject
* Updated the default ProtonMail signature to "Sent from ProtonMail for iOS"
* Fixed attachments being not delivered in some edge cases
* Fixed message sending failure with wrong message if you try to send it while offline on iOS 14.2 beta
* Fixed crash after opening the app already in background in a certain scenario
* Fixed contacts and groups tab bar not shown after sending a group message
* Fixed Incorrect inbox information after switching accounts
* Fixed crash when adding an attachment in certain scenarios
* Fixed screen sharing on tv results in Black iPhone display
* Fixed message 'sending failed' being wrongly displayed after killing the app while the message is being sent
* Fixed contacts from all accounts being displayed when creating a group
* Fixed trackpad functions not all working
* Fixed empty trash function not working


## v1.12.8
    
Improvements:
    
* Updated the GopenPGP cryptographic library to version 2 for better security and improved stability
* Added a warning that announces to users that we will drop compatibility with iOS10
* Improved the experience when adding badly formatted email addresses as a recipient of an email
* Improved error handling when sending emails to badly formatted email addresses
* Improved the process of creating, updating, saving and recovering drafts
* Improved the synchronization of messages
* improved various aspects of UI/UX for better clarity
    
Fixes:
    
* Sometimes user would receive duplicated push notifications with the second one showing a generic message saying "You received a new message!"
* Sometimes a message sending error would be displayed saying "Message sending failed. Please try again: EOF"
* Sometimes a message sending error would be displayed saying "Message sending failed. The package is required."
* In some cases, the received message would appear encrypted only in the iOS app
* In some cases, an "invalid access token" message would be displayed after opening the app
* When starting with 0, the Two-Factor Authentication code would not be accepted
* The back button on the create PIN flow did not work
* Fixed various crashes that could happened when sending a message
* Fixed a crash that occurred when deleting emails from the trash folder
* Fixed a crash that sometimes occurred when the app is in the background
* Fixed a crash that sometimes occurred when selecting a phone number from the message body
* Fixed a crash that sometimes occurred when opening the app from a push notification
* Fixed a bug whereby the refresh spinner would keep spinning forever
* Fixed various issues related to displaying the updated list of emails
* Fixed a bug whereby text contained in angled brackets would be badly displayed
* Fixed a bug in the report bug flow that prevented users from properly submitting the report
* Fixed a bug whereby a queue management issue leading to the spinner spinning forever
* Fixed various bugs whereby the download of the message list would be delayed or incomplete


## v1.12.7

* Added the ability to set Protonmail as the default mail app (iOS14 or above)
* Fixed a synchronization bug whereby changes made on the web would not be reflected on the app
* Fixed some random crashes


## v1.12.6

* Performance improvements to increase inbox loading speeds
* Fixed an issue where a draft saved on ProtonMail for web that is opened in the iOS app may require attachments to be manually re-added in certain situations
* Improved error handling in situations with slow Internet connectivity

    
## v1.12.5

* Fixed an issue with draft saving which in certain situations can cause a draft to be improperly saved.


## v1.12.4
    
Fixes:
    
* The banner showing a "storage almost full" warning was missing
* Some messages appeared duplicated in some cases
* "The Packages is required" error message appeared to some users when sending messages
* Other random issues related to sending messages
* Messages showed encrypted after a new alias was created
* Scrolling to the bottom of the inbox was not possible in some cases
* The app sometimes crashed when in the background
* The app crashed when pressing the menu icon on iPad
* The app crashed when editing a contact to which a picture had previously been added
* The app crashed when accessing a folder after performing the "empty cache" action
* The app failed to sync when "automatically attach public key" is turned on

Improvements:

* Better user interface when adding files from the composer
* Better user interface when unlocking the app
* Smoother animation when swiping on a message to move it to trash or archive
* Known bug
* in some cases, selecting multiple emails and moving them to trash will crash the app


## v1.12.3
    
Fixes:
    
* Push notifications stopped being delivered in some cases
* App crashed when opening a message from the push notification
* Messages failed to sync when updated from another app
* List failed to render the changes made
* Broken search in simplified and traditional Chinese
* Various UI and UX fixes
    
Features / improvements:
    
* Better handling of alternative routing
* Rendering of newsletter messages


## v1.12.2

Fixed:

* App crashed when opening messages from notifications in certain conditions

Improved:

* PIN/FaceID/TouchID protection


## v1.12.1

Fixed:

* Swipe gestures were not properly saved in some cases
* A wrong message was shown on the TouchID screen on iOS 12
* Sharing from other applications did not work for some users
* 3D touch shortcuts did not open the correct screen
* For some users the alternative routing option was re-enabled after killing the app from background
    
Improved:

* Renamed the "Auto-Lock" option to "PIN & TouchID/FaceID"
* Moved the default browser setting to the App settings section
* Magic keyboard improvements


## v1.12.0

* Multi-user support
* Reorganized settings to match support for multiple users

Fixed:

* In some cases Invalid access token message appeared on screen while using the app
* In some cases an attachment did not get saved in a draft while in offline mode
* Using the show/hide option in the password field removed already entered characters
* On some occasions many requests could cause the app to lag or crash
* Forwarding a message twice removed the "forwarded" icon shown on the message that was forwarded
* The app crashed when trying to upload contacts after revoking access to the device contacts
* Entering a wrong 2FA code closed the 2FA modal
* Strengthened meta data encryption to protect against reused key attacks
* Security improvements
* Stability improvements
* Additional minor bug fixes


## v1.11.17

* Touch/Face ID issue introduced by the release of iOS 13.5


## v1.11.16

* Fixed a bug that caused the app to crash when opening a message on some iOS 12 devices


## v1.11.15

* Add DNS over https


## v1.11.14

* TouchID option was shown when FaceID is disabled for PM app
* Some users did not immediately see new messages in the mailbox
* Message from some particular senders was not properly rendered
* Links were unable to open if the Default Browser is set to Brave
* The Touch ID prompt button on the login screen was inconsistent on iOS 13
* Sharing an item from another application caused the app to crash
* Some messages were showing a decryption error in the app
* The composer was not restored correctly in some cases

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
