/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDFLAnimatedImage.h"
#import <objc/runtime.h>

SDWebImageContextOption _Nonnull const SDWebImageContextOptimalFrameCacheSize = @"optimalFrameCacheSize";
SDWebImageContextOption _Nonnull const SDWebImageContextPredrawingEnabled = @"predrawingEnabled";

@interface SDFLAnimatedImage ()

@property (nonatomic, strong, nullable) FLAnimatedImage *animatedImage;

@end

@implementation SDFLAnimatedImage

- (instancetype)initWithAnimatedImage:(FLAnimatedImage *)animatedImage {
    NSParameterAssert(animatedImage);
    UIImage *posterImage = animatedImage.posterImage;
    self = [super initWithCGImage:posterImage.CGImage scale:posterImage.scale orientation:posterImage.imageOrientation];
    if (self) {
        self.animatedImage = animatedImage;
    }
    return self;
}

+ (instancetype)imageWithContentsOfFile:(NSString *)path {
    return [[self alloc] initWithContentsOfFile:path];
}

+ (instancetype)imageWithData:(NSData *)data {
    return [[self alloc] initWithData:data];
}

+ (instancetype)imageWithData:(NSData *)data scale:(CGFloat)scale {
    return [[self alloc] initWithData:data scale:scale];
}

- (instancetype)initWithData:(NSData *)data {
    return [self initWithData:data scale:1];
}

- (instancetype)initWithContentsOfFile:(NSString *)path {
    NSData *data = [NSData dataWithContentsOfFile:path];
    return [self initWithData:data];
}

- (instancetype)initWithData:(NSData *)data scale:(CGFloat)scale {
    return [self initWithData:data scale:scale options:nil];
}

- (instancetype)initWithData:(NSData *)data scale:(CGFloat)scale options:(SDImageCoderOptions *)options {
    BOOL predrawingEnabled = YES;
    SDWebImageContext *context = options[SDImageCoderWebImageContext];
    if (context[SDWebImageContextPredrawingEnabled]) {
        predrawingEnabled = [context[SDWebImageContextPredrawingEnabled] boolValue];
    }
    NSUInteger optimalFrameCacheSize = 0;
    if (context[SDWebImageContextOptimalFrameCacheSize]) {
        optimalFrameCacheSize = [context[SDWebImageContextOptimalFrameCacheSize] unsignedIntegerValue];
    }
    FLAnimatedImage *animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:data optimalFrameCacheSize:optimalFrameCacheSize predrawingEnabled:predrawingEnabled];
    if (!animatedImage) {
        return nil;
    }
    return [self initWithAnimatedImage:animatedImage];
}

- (instancetype)initWithAnimatedCoder:(id<SDAnimatedImageCoder>)animatedCoder scale:(CGFloat)scale {
    // Does not support progressive load for GIF images at all
    return nil;
}

#pragma mark - NSSecureCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        NSData *animatedImageData = [aDecoder decodeObjectOfClass:[NSData class] forKey:NSStringFromSelector(@selector(animatedImageData))];
        if (!animatedImageData) {
            return self;
        }
        FLAnimatedImage *animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:animatedImageData];
        if (!animatedImage) {
            return self;
        }
        self.animatedImage = animatedImage;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    NSData *animatedImageData = self.animatedImageData;
    if (animatedImageData) {
        [aCoder encodeObject:animatedImageData forKey:NSStringFromSelector(@selector(animatedImageData))];
    }
}

#pragma mark - SDAnimatedImageProvider

- (nullable NSData *)animatedImageData {
    return self.animatedImage.data;
}

- (NSTimeInterval)animatedImageDurationAtIndex:(NSUInteger)index {
    return [self.animatedImage.delayTimesForIndexes[@(index)] doubleValue];
}

- (nullable UIImage *)animatedImageFrameAtIndex:(NSUInteger)index {
    return [self.animatedImage imageLazilyCachedAtIndex:index];
}

- (NSUInteger)animatedImageFrameCount {
    return self.animatedImage.frameCount;
}

- (NSUInteger)animatedImageLoopCount {
    return self.animatedImage.loopCount;
}

@end

@implementation SDFLAnimatedImage (MemoryCacheCost)

- (NSUInteger)sd_memoryCost {
    NSNumber *value = objc_getAssociatedObject(self, @selector(sd_memoryCost));
    if (value != nil) {
        return value.unsignedIntegerValue;
    }
    
    FLAnimatedImage *animatedImage = self.animatedImage;
    CGImageRef imageRef = animatedImage.posterImage.CGImage; // / Guaranteed to be loaded, and guaranteed to be CGImage based
    NSUInteger bytesPerFrame = CGImageGetBytesPerRow(imageRef) * CGImageGetHeight(imageRef);
    NSUInteger frameCacheSizeCurrent = animatedImage.frameCacheSizeCurrent; // [1...frame count], more suitable than raw frame count because FLAnimatedImage internal actually store a buffer size but not full frames (they called `window`)
    NSUInteger animatedImageCost = frameCacheSizeCurrent * bytesPerFrame;

    return animatedImageCost;
}

@end
