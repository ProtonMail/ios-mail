#import "SentryANRTracker.h"
#import "SentryCurrentDateProvider.h"
#import "SentryDispatchFactory.h"
#import "SentryDispatchQueueWrapper.h"
#import "SentryDisplayLinkWrapper.h"
#import "SentryNSProcessInfoWrapper.h"
#import "SentryNSTimerFactory.h"
#import "SentrySystemWrapper.h"
#import "SentryUIApplication.h"
#import <SentryAppStateManager.h>
#import <SentryClient+Private.h>
#import <SentryCrashWrapper.h>
#import <SentryDebugImageProvider.h>
#import <SentryDependencyContainer.h>
#import <SentryHub.h>
#import <SentryNSNotificationCenterWrapper.h>
#import <SentrySDK+Private.h>
#import <SentryScreenshot.h>
#import <SentrySwift.h>
#import <SentrySwizzleWrapper.h>
#import <SentrySysctl.h>
#import <SentryThreadWrapper.h>
#import <SentryViewHierarchy.h>

#if SENTRY_HAS_UIKIT
#    import "SentryFramesTracker.h"
#endif // SENTRY_HAS_UIKIT

@implementation SentryDependencyContainer

static SentryDependencyContainer *instance;
static NSObject *sentryDependencyContainerLock;

+ (void)initialize
{
    if (self == [SentryDependencyContainer class]) {
        sentryDependencyContainerLock = [[NSObject alloc] init];
    }
}

+ (instancetype)sharedInstance
{
    @synchronized(sentryDependencyContainerLock) {
        if (instance == nil) {
            instance = [[self alloc] init];
        }
        return instance;
    }
}

+ (void)reset
{
    @synchronized(sentryDependencyContainerLock) {
        instance = nil;
    }
}

- (SentryFileManager *)fileManager
{
    @synchronized(sentryDependencyContainerLock) {
        if (_fileManager == nil) {
            _fileManager = [[[SentrySDK currentHub] getClient] fileManager];
        }
        return _fileManager;
    }
}

- (SentryAppStateManager *)appStateManager
{
    @synchronized(sentryDependencyContainerLock) {
        if (_appStateManager == nil) {
            SentryOptions *options = [[[SentrySDK currentHub] getClient] options];
            _appStateManager =
                [[SentryAppStateManager alloc] initWithOptions:options
                                                  crashWrapper:self.crashWrapper
                                                   fileManager:self.fileManager
                                                        sysctl:[[SentrySysctl alloc] init]
                                          dispatchQueueWrapper:self.dispatchQueueWrapper
                                     notificationCenterWrapper:self.notificationCenterWrapper];
        }
        return _appStateManager;
    }
}

- (SentryCrashWrapper *)crashWrapper
{
    if (_crashWrapper == nil) {
        @synchronized(sentryDependencyContainerLock) {
            if (_crashWrapper == nil) {
                _crashWrapper = [SentryCrashWrapper sharedInstance];
            }
        }
    }
    return _crashWrapper;
}

- (SentryThreadWrapper *)threadWrapper
{
    if (_threadWrapper == nil) {
        @synchronized(sentryDependencyContainerLock) {
            if (_threadWrapper == nil) {
                _threadWrapper = [[SentryThreadWrapper alloc] init];
            }
        }
    }
    return _threadWrapper;
}

- (SentryDispatchQueueWrapper *)dispatchQueueWrapper
{
    @synchronized(sentryDependencyContainerLock) {
        if (_dispatchQueueWrapper == nil) {
            _dispatchQueueWrapper = [[SentryDispatchQueueWrapper alloc] init];
        }
        return _dispatchQueueWrapper;
    }
}

- (SentryNSNotificationCenterWrapper *)notificationCenterWrapper
{
    @synchronized(sentryDependencyContainerLock) {
        if (_notificationCenterWrapper == nil) {
            _notificationCenterWrapper = [[SentryNSNotificationCenterWrapper alloc] init];
        }
        return _notificationCenterWrapper;
    }
}

- (id<SentryRandom>)random
{
    if (_random == nil) {
        @synchronized(sentryDependencyContainerLock) {
            if (_random == nil) {
                _random = [[SentryRandom alloc] init];
            }
        }
    }
    return _random;
}

#if SENTRY_HAS_UIKIT
- (SentryScreenshot *)screenshot
{
    if (_screenshot == nil) {
        @synchronized(sentryDependencyContainerLock) {
            if (_screenshot == nil) {
                _screenshot = [[SentryScreenshot alloc] init];
            }
        }
    }
    return _screenshot;
}

- (SentryViewHierarchy *)viewHierarchy
{
    if (_viewHierarchy == nil) {
        @synchronized(sentryDependencyContainerLock) {
            if (_viewHierarchy == nil) {
                _viewHierarchy = [[SentryViewHierarchy alloc] init];
            }
        }
    }
    return _viewHierarchy;
}

- (SentryUIApplication *)application
{
    if (_application == nil) {
        @synchronized(sentryDependencyContainerLock) {
            if (_application == nil) {
                _application = [[SentryUIApplication alloc] init];
            }
        }
    }
    return _application;
}

- (SentryFramesTracker *)framesTracker
{
    if (_framesTracker == nil) {
        @synchronized(sentryDependencyContainerLock) {
            if (_framesTracker == nil) {
                _framesTracker = [[SentryFramesTracker alloc]
                    initWithDisplayLinkWrapper:[[SentryDisplayLinkWrapper alloc] init]];
            }
        }
    }
    return _framesTracker;
}
#endif // SENTRY_HAS_UIKIT

- (SentrySwizzleWrapper *)swizzleWrapper
{
    if (_swizzleWrapper == nil) {
        @synchronized(sentryDependencyContainerLock) {
            if (_swizzleWrapper == nil) {
                _swizzleWrapper = SentrySwizzleWrapper.sharedInstance;
            }
        }
    }
    return _swizzleWrapper;
}

- (SentryDebugImageProvider *)debugImageProvider
{
    if (_debugImageProvider == nil) {
        @synchronized(sentryDependencyContainerLock) {
            if (_debugImageProvider == nil) {
                _debugImageProvider = [[SentryDebugImageProvider alloc] init];
            }
        }
    }

    return _debugImageProvider;
}

- (SentryANRTracker *)getANRTracker:(NSTimeInterval)timeout
{
    if (_anrTracker == nil) {
        @synchronized(sentryDependencyContainerLock) {
            if (_anrTracker == nil) {
                _anrTracker =
                    [[SentryANRTracker alloc] initWithTimeoutInterval:timeout
                                                         crashWrapper:self.crashWrapper
                                                 dispatchQueueWrapper:self.dispatchQueueWrapper
                                                        threadWrapper:self.threadWrapper];
            }
        }
    }

    return _anrTracker;
}

- (SentryNSProcessInfoWrapper *)processInfoWrapper
{
    if (_processInfoWrapper == nil) {
        @synchronized(sentryDependencyContainerLock) {
            if (_processInfoWrapper == nil) {
                _processInfoWrapper = [[SentryNSProcessInfoWrapper alloc] init];
            }
        }
    }
    return _processInfoWrapper;
}

- (SentrySystemWrapper *)systemWrapper
{
    if (_systemWrapper == nil) {
        @synchronized(sentryDependencyContainerLock) {
            if (_systemWrapper == nil) {
                _systemWrapper = [[SentrySystemWrapper alloc] init];
            }
        }
    }
    return _systemWrapper;
}

- (SentryDispatchFactory *)dispatchFactory
{
    if (_dispatchFactory == nil) {
        @synchronized(sentryDependencyContainerLock) {
            if (_dispatchFactory == nil) {
                _dispatchFactory = [[SentryDispatchFactory alloc] init];
            }
        }
    }
    return _dispatchFactory;
}

- (SentryNSTimerFactory *)timerFactory
{
    if (_timerFactory == nil) {
        @synchronized(sentryDependencyContainerLock) {
            if (_timerFactory == nil) {
                _timerFactory = [[SentryNSTimerFactory alloc] init];
            }
        }
    }
    return _timerFactory;
}

- (SentryCurrentDateProvider *)dateProvider
{
    if (_dateProvider == nil) {
        @synchronized(sentryDependencyContainerLock) {
            if (_dateProvider == nil) {
                _dateProvider = [[SentryCurrentDateProvider alloc] init];
            }
        }
    }
    return _dateProvider;
}

#if SENTRY_HAS_METRIC_KIT
- (SentryMXManager *)metricKitManager
{
    if (_metricKitManager == nil) {
        @synchronized(sentryDependencyContainerLock) {
            if (_metricKitManager == nil) {
                // Disable crash diagnostics as we only use it for validation of the symbolication
                // of stacktraces, because crashes are easy to trigger for MetricKit. We don't want
                // crash reports of MetricKit in production as we have SentryCrash.
                _metricKitManager = [[SentryMXManager alloc] initWithDisableCrashDiagnostics:YES];
            }
        }
    }

    return _metricKitManager;
}

#endif // SENTRY_HAS_METRIC_KIT

@end
