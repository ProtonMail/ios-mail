# FSSyncSpinner

[![CI Status](http://img.shields.io/travis/f33chobits/FSSyncSpinner.svg?style=flat)](https://travis-ci.org/f33chobits/FSSyncSpinner)
[![Version](https://img.shields.io/cocoapods/v/FSSyncSpinner.svg?style=flat)](http://cocoadocs.org/docsets/FSSyncSpinner)
[![License](https://img.shields.io/cocoapods/l/FSSyncSpinner.svg?style=flat)](http://cocoadocs.org/docsets/FSSyncSpinner)
[![Platform](https://img.shields.io/cocoapods/p/FSSyncSpinner.svg?style=flat)](http://cocoadocs.org/docsets/FSSyncSpinner)

![fssyncspinner](https://cloud.githubusercontent.com/assets/5186464/6557191/32b690a8-c6ae-11e4-9c91-027f107bef26.gif)

This project is based on [Michael Villar's excellent Motion Experiments post](http://www.michaelvillar.com/motion) - Syncing/Success Icon

## Installation
* cocoapods: `pod FSSyncSpinner`
* manual   : drag FSSyncSpinner.h and FSSyncSpinner.m in to your project
```objective-c
#import "FSSyncSpinner.h"
```

## Usage
Only three methods
```objective-c

// to start the animating
- (void)startAnimating;

// to perform a finish
- (void)finish;

// whether perform an alpha animation to hide while finished
@property (assign, nonatomic) BOOL hidesWhenFinished;

```

## Requirements
iOS 7.0

## Author

Wenchao Ding => f33chobits@gmail.com

## License

FSSyncSpinner is available under the MIT license. See the LICENSE file for more info.

## Support me
* Just give me a star
* Issue me as much as you want

