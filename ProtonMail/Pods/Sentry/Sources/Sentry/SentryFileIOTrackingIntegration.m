#import "SentryFileIOTrackingIntegration.h"
#import "SentryLog.h"
#import "SentryNSDataSwizzling.h"
#import "SentryOptions.h"

@implementation SentryFileIOTrackingIntegration

- (BOOL)installWithOptions:(SentryOptions *)options
{
    if (![super installWithOptions:options]) {
        return NO;
    }

    [SentryNSDataSwizzling start];

    return YES;
}

- (SentryIntegrationOption)integrationOptions
{
    return kIntegrationOptionEnableSwizzling | kIntegrationOptionIsTracingEnabled
        | kIntegrationOptionEnableAutoPerformanceTracking | kIntegrationOptionEnableFileIOTracking;
}

- (void)uninstall
{
    [SentryNSDataSwizzling stop];
}

@end
