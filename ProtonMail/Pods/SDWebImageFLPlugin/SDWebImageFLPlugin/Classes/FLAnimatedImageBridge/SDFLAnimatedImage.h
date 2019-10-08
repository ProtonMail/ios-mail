/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <FLAnimatedImage/FLAnimatedImage.h>
#import <SDWebImage/SDWebImage.h>

/**
 * Optimal frame cache size of FLAnimatedImage during initializer. (1.0.11 version later)
 * This value will help you set `optimalFrameCacheSize` arg of FLAnimatedImage initializer after image load.
 * Defaults to 0.
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextOptimalFrameCacheSize;
/**
 * Predrawing control of FLAnimatedImage during initializer. (1.0.11 version later)
 * This value will help you set `predrawingEnabled` arg of FLAnimatedImage initializer after image load.
 * Defaults to YES.
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextPredrawingEnabled;

/**
 A wrapper class to allow `FLAnimatedImage` to be compatible for SDWebImage loading/cache/rendering system. The `GIF` image loading from `FLAnimatedImageView+WebCache` category, will use this subclass instead of `UIImage`.
 
 @note Though this class conforms to `SDAnimatedImage` protocol, so it's compatible to be used for `SDAnimatedImageView`. But it's normally discouraged to do so. Because it does not provide optimization for animation rendering. Instead, use `SDAnimatedImage` class with `SDAnimatedImageView`.
 */
@interface SDFLAnimatedImage : UIImage <SDAnimatedImage>

/**
 The `FLAnimatedImage` instance for GIF representation. This property should be nonnull.
 */
@property (nonatomic, strong, nonnull, readonly) FLAnimatedImage *animatedImage;

/**
 Create the wrapper with specify `FLAnimatedImage` instance. The instance should be nonnull.
 This is a convenience method for some use cases, for example, create a placeholder with `FLAnimatedImage`.

 @param animatedImage The `FLAnimatedImage` instance
 @return An initialized object
 */
- (nonnull instancetype)initWithAnimatedImage:(nonnull FLAnimatedImage *)animatedImage;


// This class override these methods from UIImage, and it supports NSSecureCoding.
// You should use these methods to create a new animated image. Use other methods just call super instead.
+ (nullable instancetype)imageWithContentsOfFile:(nonnull NSString *)path;
+ (nullable instancetype)imageWithData:(nonnull NSData *)data;
+ (nullable instancetype)imageWithData:(nonnull NSData *)data scale:(CGFloat)scale;
- (nullable instancetype)initWithContentsOfFile:(nonnull NSString *)path;
- (nullable instancetype)initWithData:(nonnull NSData *)data;
- (nullable instancetype)initWithData:(nonnull NSData *)data scale:(CGFloat)scale;

@end
