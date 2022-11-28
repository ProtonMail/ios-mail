#import "SentryDefines.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SentryPermissionsObserver : NSObject

/*
 * We want as many permissions as possible,
 * but we had to remove the media permission because it was preventing some developers from
 * publishing their apps. Apple was requiring developers to include NSAppleMusicUsageDescription in
 * their plist files, even when they don't use this feature. More info at
 * https://github.com/getsentry/sentry-cocoa/issues/2065
 */

@property (nonatomic) SentryPermissionStatus pushPermissionStatus;
@property (nonatomic) SentryPermissionStatus locationPermissionStatus;
@property (nonatomic) SentryPermissionStatus photoLibraryPermissionStatus;

- (void)startObserving;

@end

NS_ASSUME_NONNULL_END
