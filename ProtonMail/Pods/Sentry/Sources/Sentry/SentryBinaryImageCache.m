#import "SentryBinaryImageCache.h"
#import "SentryCrashBinaryImageCache.h"

static void binaryImageWasAdded(const SentryCrashBinaryImage *image);

static void binaryImageWasRemoved(const SentryCrashBinaryImage *image);

@implementation SentryBinaryImageInfo
@end

@interface
SentryBinaryImageCache ()
@property (nonatomic, strong) NSMutableArray<SentryBinaryImageInfo *> *cache;
- (void)binaryImageAdded:(const SentryCrashBinaryImage *)image;
- (void)binaryImageRemoved:(const SentryCrashBinaryImage *)image;
@end

@implementation SentryBinaryImageCache

+ (SentryBinaryImageCache *)shared
{
    static SentryBinaryImageCache *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[self alloc] init]; });
    return instance;
}

- (void)start
{
    _cache = [NSMutableArray array];
    sentrycrashbic_registerAddedCallback(&binaryImageWasAdded);
    sentrycrashbic_registerRemovedCallback(&binaryImageWasRemoved);
}

- (void)stop
{
    sentrycrashbic_registerAddedCallback(NULL);
    sentrycrashbic_registerRemovedCallback(NULL);
    _cache = nil;
}

- (void)binaryImageAdded:(const SentryCrashBinaryImage *)image
{
    SentryBinaryImageInfo *newImage = [[SentryBinaryImageInfo alloc] init];
    newImage.name = [NSString stringWithCString:image->name encoding:NSUTF8StringEncoding];
    newImage.address = image->address;
    newImage.size = image->size;

    @synchronized(self) {
        NSUInteger left = 0;
        NSUInteger right = _cache.count;

        while (left < right) {
            NSUInteger mid = (left + right) / 2;
            SentryBinaryImageInfo *compareImage = _cache[mid];
            if (newImage.address < compareImage.address) {
                right = mid;
            } else {
                left = mid + 1;
            }
        }

        [_cache insertObject:newImage atIndex:left];
    }
}

- (void)binaryImageRemoved:(const SentryCrashBinaryImage *)image
{
    @synchronized(self) {
        NSInteger index = [self indexOfImage:image->address];
        if (index >= 0) {
            [_cache removeObjectAtIndex:index];
        }
    }
}

- (nullable SentryBinaryImageInfo *)imageByAddress:(const uint64_t)address;
{
    @synchronized(self) {
        NSInteger index = [self indexOfImage:address];
        return index >= 0 ? _cache[index] : nil;
    }
}

- (NSInteger)indexOfImage:(uint64_t)address
{
    if (_cache == nil)
        return -1;

    NSInteger left = 0;
    NSInteger right = _cache.count - 1;

    while (left <= right) {
        NSInteger mid = (left + right) / 2;
        SentryBinaryImageInfo *image = _cache[mid];

        if (address >= image.address && address < (image.address + image.size)) {
            return mid;
        } else if (address < image.address) {
            right = mid - 1;
        } else {
            left = mid + 1;
        }
    }

    return -1; // Address not found
}

@end

static void
binaryImageWasAdded(const SentryCrashBinaryImage *image)
{
    [SentryBinaryImageCache.shared binaryImageAdded:image];
}

static void
binaryImageWasRemoved(const SentryCrashBinaryImage *image)
{
    [SentryBinaryImageCache.shared binaryImageRemoved:image];
}
