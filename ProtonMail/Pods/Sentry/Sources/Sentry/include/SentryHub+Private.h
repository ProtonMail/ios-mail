#import "SentryHub.h"
#import "SentryTracer.h"

@class SentryEnvelopeItem, SentryId, SentryScope, SentryTransaction, SentryDispatchQueueWrapper,
    SentryEnvelope, SentryNSTimerFactory, SentrySession;

NS_ASSUME_NONNULL_BEGIN

@interface
SentryHub (Private)

@property (nonatomic, strong) NSArray<id<SentryIntegrationProtocol>> *installedIntegrations;
@property (nonatomic, strong) NSSet<NSString *> *installedIntegrationNames;
@property (nullable, nonatomic, strong) SentrySession *session;

- (void)addInstalledIntegration:(id<SentryIntegrationProtocol>)integration name:(NSString *)name;
- (void)removeAllIntegrations;

- (SentryClient *_Nullable)client;

- (void)captureCrashEvent:(SentryEvent *)event;

- (void)captureCrashEvent:(SentryEvent *)event withScope:(SentryScope *)scope;

- (void)setSampleRandomValue:(NSNumber *)value;

- (void)closeCachedSessionWithTimestamp:(NSDate *_Nullable)timestamp;

- (SentryTracer *)startTransactionWithContext:(SentryTransactionContext *)transactionContext
                                  bindToScope:(BOOL)bindToScope
                        customSamplingContext:(NSDictionary<NSString *, id> *)customSamplingContext
                                configuration:(SentryTracerConfiguration *)configuration;

- (SentryId *)captureEvent:(SentryEvent *)event
                  withScope:(SentryScope *)scope
    additionalEnvelopeItems:(NSArray<SentryEnvelopeItem *> *)additionalEnvelopeItems
    NS_SWIFT_NAME(capture(event:scope:additionalEnvelopeItems:));

- (SentryId *)captureTransaction:(SentryTransaction *)transaction withScope:(SentryScope *)scope;

- (SentryId *)captureTransaction:(SentryTransaction *)transaction
                       withScope:(SentryScope *)scope
         additionalEnvelopeItems:(NSArray<SentryEnvelopeItem *> *)additionalEnvelopeItems;

- (void)captureEnvelope:(SentryEnvelope *)envelope;

@end

NS_ASSUME_NONNULL_END
