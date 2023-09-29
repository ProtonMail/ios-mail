#import "SentryEvent.h"
#import "SentrySpanProtocol.h"
#import "SentryTracer.h"

NS_ASSUME_NONNULL_BEGIN

@class SentryTracer;

NS_SWIFT_NAME(Transaction)
@interface SentryTransaction : SentryEvent
SENTRY_NO_INIT

@property (nonatomic, strong) SentryTracer *trace;

- (instancetype)initWithTrace:(SentryTracer *)trace children:(NSArray<id<SentrySpan>> *)children;

@end

NS_ASSUME_NONNULL_END
