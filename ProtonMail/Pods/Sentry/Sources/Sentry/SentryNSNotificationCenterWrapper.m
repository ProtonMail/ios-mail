#import "SentryNSNotificationCenterWrapper.h"

#if SENTRY_HAS_UIKIT
#    import <UIKit/UIKit.h>
#elif TARGET_OS_OSX || TARGET_OS_MACCATALYST
#    import <Cocoa/Cocoa.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@implementation SentryNSNotificationCenterWrapper

#if SENTRY_HAS_UIKIT
+ (NSNotificationName)didBecomeActiveNotificationName
{
    return UIApplicationDidBecomeActiveNotification;
}

+ (NSNotificationName)willResignActiveNotificationName
{
    return UIApplicationWillResignActiveNotification;
}

+ (NSNotificationName)willTerminateNotificationName
{
    return UIApplicationWillTerminateNotification;
}

#elif TARGET_OS_OSX || TARGET_OS_MACCATALYST
+ (NSNotificationName)didBecomeActiveNotificationName
{
    return NSApplicationDidBecomeActiveNotification;
}

+ (NSNotificationName)willResignActiveNotificationName
{
    return NSApplicationWillResignActiveNotification;
}

+ (NSNotificationName)willTerminateNotificationName
{
    return NSApplicationWillTerminateNotification;
}
#endif

- (void)addObserver:(id)observer selector:(SEL)aSelector name:(NSNotificationName)aName
{
    [NSNotificationCenter.defaultCenter addObserver:observer
                                           selector:aSelector
                                               name:aName
                                             object:nil];
}

- (void)removeObserver:(id)observer name:(NSNotificationName)aName
{
    [NSNotificationCenter.defaultCenter removeObserver:observer name:aName object:nil];
}

- (void)removeObserver:(id)observer
{
    [NSNotificationCenter.defaultCenter removeObserver:observer];
}

@end

NS_ASSUME_NONNULL_END
