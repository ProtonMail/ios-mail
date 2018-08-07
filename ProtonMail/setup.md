# Setup guide

## Dependencies

* [Install cocoapod](https://cocoapods.org)
    * `sudo gem install cocoapods` or `brew install cocoapods`
* Run `pod install`

## Xcode 

1. Open `ProtonMail.xcworkspace` using XCode (Using `ProtonMail.xcodeproj` won't work!)
2. Login your Apple Developer Account   
    * Xcode > Preferences > Accounts
3. In the project settings, select the target `ProtonMailDev`, and use automatically manage signing
4. For the simulator, select the target `ProtonMailDev`, select one device to simulate on, and then build it!