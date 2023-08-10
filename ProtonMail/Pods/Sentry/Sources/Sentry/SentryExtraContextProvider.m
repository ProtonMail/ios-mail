#import "SentryExtraContextProvider.h"
#import "SentryCrashIntegration.h"
#import "SentryCrashWrapper.h"
#import "SentryDependencyContainer.h"
#import "SentryNSProcessInfoWrapper.h"
#import "SentryUIDeviceWrapper.h"

@interface
SentryExtraContextProvider ()

@property (nonatomic, strong) SentryCrashWrapper *crashWrapper;
@property (nonatomic, strong) SentryUIDeviceWrapper *deviceWrapper;
@property (nonatomic, strong) SentryNSProcessInfoWrapper *processInfoWrapper;

@end

@implementation SentryExtraContextProvider

+ (instancetype)sharedInstance
{
    static SentryExtraContextProvider *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[self alloc] init]; });
    return instance;
}

- (instancetype)init
{
    return
        [self initWithCrashWrapper:[SentryCrashWrapper sharedInstance]
                     deviceWrapper:[[SentryUIDeviceWrapper alloc] init]
                processInfoWrapper:[SentryDependencyContainer.sharedInstance processInfoWrapper]];
}

- (instancetype)initWithCrashWrapper:(id)crashWrapper
                       deviceWrapper:(id)deviceWrapper
                  processInfoWrapper:(id)processInfoWrapper
{
    if (self = [super init]) {
        self.crashWrapper = crashWrapper;
        self.deviceWrapper = deviceWrapper;
        self.processInfoWrapper = processInfoWrapper;
    }
    return self;
}

- (NSDictionary *)getExtraContext
{
    return @{ @"device" : [self getExtraDeviceContext], @"app" : [self getExtraAppContext] };
}

- (NSDictionary *)getExtraDeviceContext
{
    NSMutableDictionary *extraDeviceContext = [[NSMutableDictionary alloc] init];

    extraDeviceContext[SentryDeviceContextFreeMemoryKey] = @(self.crashWrapper.freeMemorySize);
    extraDeviceContext[@"free_storage"] = @(self.crashWrapper.freeStorageSize);
    extraDeviceContext[@"processor_count"] = @([self.processInfoWrapper processorCount]);

#if TARGET_OS_IOS
    if (self.deviceWrapper.orientation != UIDeviceOrientationUnknown) {
        extraDeviceContext[@"orientation"]
            = UIDeviceOrientationIsPortrait(self.deviceWrapper.orientation) ? @"portrait"
                                                                            : @"landscape";
    }

    if (self.deviceWrapper.isBatteryMonitoringEnabled) {
        extraDeviceContext[@"charging"]
            = self.deviceWrapper.batteryState == UIDeviceBatteryStateCharging ? @(YES) : @(NO);
        extraDeviceContext[@"battery_level"] = @((int)(self.deviceWrapper.batteryLevel * 100));
    }
#endif
    return extraDeviceContext;
}

- (NSDictionary *)getExtraAppContext
{
    return @{ SentryDeviceContextAppMemoryKey : @(self.crashWrapper.appMemorySize) };
}

@end
