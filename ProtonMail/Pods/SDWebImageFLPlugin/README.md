# SDWebImageFLPlugin

[![CI Status](https://img.shields.io/travis/SDWebImage/SDWebImageFLPlugin.svg?style=flat)](https://travis-ci.org/SDWebImage/SDWebImageFLPlugin)
[![Version](https://img.shields.io/cocoapods/v/SDWebImageFLPlugin.svg?style=flat)](https://cocoapods.org/pods/SDWebImageFLPlugin)
[![License](https://img.shields.io/cocoapods/l/SDWebImageFLPlugin.svg?style=flat)](https://cocoapods.org/pods/SDWebImageFLPlugin)
[![Platform](https://img.shields.io/cocoapods/p/SDWebImageFLPlugin.svg?style=flat)](https://cocoapods.org/pods/SDWebImageFLPlugin)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/SDWebImage/SDWebImageFLPlugin)
[![codecov](https://codecov.io/gh/SDWebImage/SDWebImageFLPlugin/branch/master/graph/badge.svg)](https://codecov.io/gh/SDWebImage/SDWebImageFLPlugin)

Starting with the SDWebImage 5.0 version, we move the [FLAnimatedImage](https://github.com/Flipboard/FLAnimatedImage) support code from the Core Repo to this stand-alone repo. Core which previously use FLAnimatedImage with SDWebImage can continue to work with this plugin.

## What's for
SDWebImageFLPlugin is a plugin for [SDWebImage](https://github.com/rs/SDWebImage/) framework, which provide the image loading support for [FLAnimatedImage](https://github.com/Flipboard/FLAnimatedImage) animated GIF engine.

By using SDWebImageFLPlugin, you can use all you familiar SDWebImage's loading method, on the `FLAnimatedImageView`, which is the base component of FLAnimatedImage.

To use it, simply make sure you use `FLAnimatedImageView` instead of `UIImageView` and import this plugin.

## Usage
To load images from network, just simply call the View Category method like normal UIImageView.

+ Objective-C

```objectivec
FLAnimatedImageView *imageView;
[imageView sd_setImageWithURL:[NSURL URLWithString:@"http://www.domain.com/path/to/image.gif"]];
```

+ Swift

```swift
let imageView: FLAnimatedImageView
imageView.sd_setImage(with: URL(string: "http://www.domain.com/path/to/image.gif"))
```

The magic because we create one custom animation class called `SDFLAnimatedImage` to load GIF images, and use `UIImage` for normal images.

For placeholder, you can even provide a `FLAnimatedImage` to allow GIF placeholder on `FLAnimatedImageView` using the wrapper class `SDFLAnimatedImage`.

+ Objective-C

```objectivec
FLAnimatedImageView *imageView;
FLAnimatedImage *animatedImage = [FLAnimatedImage animatedImageWithGIFData:gifData];
SDFLAnimatedImage *placeholder = [[SDFLAnimatedImage alloc] initWithAnimatedImage:animatedImage];
[imageView sd_setImageWithURL:[NSURL URLWithString:@"http://www.domain.com/path/to/image.gif"] placeholderImage:placeholder];
```

+ Swift

```swift
let imageView: FLAnimatedImageView
let animatedImage = FLAnimatedImage(animatedGIFData: gifData)
let placeholder = SDFLAnimatedImage(animatedImage: animatedImage)
imageView.sd_setImage(with: URL(string: "http://www.domain.com/path/to/image.gif"), placeholderImage: placeholder)
```

## Requirements

+ iOS 8+
+ Xcode 9+

## Installation

#### CocoaPods

SDWebImageFLPlugin is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'SDWebImageFLPlugin'
```

#### Carthage

SDWebImageFLPlugin is available through [Carthage](https://github.com/Carthage/Carthage).

```
github "SDWebImage/SDWebImageFLPlugin"
```

## Author

DreamPiggy, lizhuoli1126@126.com

## License

SDWebImageFLPlugin is available under the MIT license. See the LICENSE file for more info.


