# PMCrypto

This repo is a wrapper around Crypto.framework to allow its usage as cocoapod. Frameworks for different architectures are packed into one Xcframework.

1. Generate frameworks for iOS, macOS and UIKitForMac from Go code using custom `gomobile bind`
2. iOS framework is a fat binary supporting 4 architectures: armv7, arm64 for real devices, and i386 and x86_64 for simulator. You have to separate it into two binaries (one for simulator run on desktop and one for real devices) and therefore two frameworks striping some architectures from each (they will still be fat binaries with only 2 architectures but single platform):
```
    lipo Simulator/Crypto.framework/Versions/A/Crypto -remove arm64 -output Simulator/Crypto.framework/Versions/A/Crypto
    lipo Simulator/Crypto.framework/Versions/A/Crypto -remove armv7 -output Simulator/Crypto.framework/Versions/A/Crypto
    lipo iOS/Crypto.framework/Versions/A/Crypto -remove i386 -output iOS/Crypto.framework/Versions/A/Crypto
    lipo iOS/Crypto.framework/Versions/A/Crypto -remove x86_64 -output iOS/Crypto.framework/Versions/A/Crypto
```
2. Build xcframewrok from four single platform frameworks - iOS, Simulator, macos, uikitformac:
```
    xcodebuild -create-xcframework  -framework iOS/Crypto.framework  -framework macos/Crypto.framework  -framework uikitformac/Crypto.framework -framework Simulator/Crypto.framework  -output Crypto.xcframework
```

In order to update build of Crypto.framework inside this pod:
1. drop-in a new build of Crypto.xcframework into the repo
2. update version in `PMCrypto.podspec` so all the dependant pods will know they need to re-fetch it
3. tag the commit accordingly

**Important:**
CocaPods support xcframeworks starting v1.9, older versions will fail to install xcframework as a dependency.
CocoaPods has a bug (https://github.com/CocoaPods/CocoaPods/issues/9525) that does not let Xcode see simulator binary of xcframewrok correctly. 
Temporary workaroud is to manually change order of framework search paths in xcconfig files. 
Until that bug is fixed, please use v1.0.0 of this pod or install xcframework manually.
