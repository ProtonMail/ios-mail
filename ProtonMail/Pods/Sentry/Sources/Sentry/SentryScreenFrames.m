#import <SentryScreenFrames.h>

#if SENTRY_HAS_UIKIT

@implementation SentryScreenFrames

- (instancetype)initWithTotal:(NSUInteger)total frozen:(NSUInteger)frozen slow:(NSUInteger)slow
{
#    if SENTRY_TARGET_PROFILING_SUPPORTED
    return [self initWithTotal:total
                        frozen:frozen
                          slow:slow
               frameTimestamps:@[]
           frameRateTimestamps:@[]];
#    else
    if (self = [super init]) {
        _total = total;
        _slow = slow;
        _frozen = frozen;
    }

    return self;
#    endif // SENTRY_TARGET_PROFILING_SUPPORTED
}

#    if SENTRY_TARGET_PROFILING_SUPPORTED
- (instancetype)initWithTotal:(NSUInteger)total
                       frozen:(NSUInteger)frozen
                         slow:(NSUInteger)slow
              frameTimestamps:(SentryFrameInfoTimeSeries *)frameTimestamps
          frameRateTimestamps:(SentryFrameInfoTimeSeries *)frameRateTimestamps
{
    if (self = [super init]) {
        _total = total;
        _slow = slow;
        _frozen = frozen;
        _frameTimestamps = frameTimestamps;
        _frameRateTimestamps = frameRateTimestamps;
    }

    return self;
}
#    endif // SENTRY_TARGET_PROFILING_SUPPORTED

@end

#endif
