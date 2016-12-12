// GRTManagedStore.m
//
// Copyright (c) 2014-2016 Guillermo Gonzalez
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "GRTManagedStore.h"

NS_ASSUME_NONNULL_BEGIN

static NSURL *GRTCachesDirectoryURL(NSError **outError) {
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *rootURL = [fileManager URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:&error];
    
    if (error != nil) {
        if (outError != nil) *outError = error;
        return nil;
    }
    
    NSString *bundleIdentifier = [NSBundle bundleForClass:[GRTManagedStore class]].bundleIdentifier;
    NSURL *cachesDirectoryURL = [rootURL URLByAppendingPathComponent:bundleIdentifier];
    
    if (![fileManager fileExistsAtPath:cachesDirectoryURL.path]) {
        [fileManager createDirectoryAtURL:cachesDirectoryURL withIntermediateDirectories:YES attributes:nil error:&error];
        
        if (error != nil) {
            if (outError != nil) *outError = error;
            return nil;
        }
    }
    
    return cachesDirectoryURL;
}

@implementation GRTManagedStore

- (NSManagedObjectModel *)managedObjectModel {
    return self.persistentStoreCoordinator.managedObjectModel;
}

- (NSURL *)URL {
    NSPersistentStore *store = self.persistentStoreCoordinator.persistentStores[0];
    return store.URL;
}

- (instancetype)init {
    return [self initWithURL:nil model:[NSManagedObjectModel mergedModelFromBundles:nil] error:NULL];
}

- (nullable instancetype)initWithURL:(nullable NSURL *)URL
                               model:(NSManagedObjectModel *)managedObjectModel
                               error:(NSError *__autoreleasing  __nullable * __nullable)outError
{
    self = [super init];
    
    if (self) {
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
        
        NSString *storeType = (URL != nil ? NSSQLiteStoreType : NSInMemoryStoreType);
        NSDictionary *options = @{
            NSMigratePersistentStoresAutomaticallyOption: @YES,
            NSInferMappingModelAutomaticallyOption: @YES
        };
        
        NSError *error = nil;
        [_persistentStoreCoordinator addPersistentStoreWithType:storeType
                                                  configuration:nil
                                                            URL:URL
                                                        options:options
                                                          error:&error];
        
        if (error != nil) {
            if (outError != nil) *outError = error;
            return nil;
        }
    }
    
    return self;
}

- (nullable instancetype)initWithCacheName:(NSString *)cacheName
                                     model:(NSManagedObjectModel *)managedObjectModel
                                     error:(NSError *__autoreleasing  __nullable * __nullable)outError
{
    NSError *error = nil;
    NSURL *cachesDirectoryURL = GRTCachesDirectoryURL(&error);
    
    if (error != nil) {
        if (outError != nil) *outError = error;
        return nil;
    }
    
    NSURL *storeURL = [cachesDirectoryURL URLByAppendingPathComponent:cacheName];
    return [self initWithURL:storeURL model:managedObjectModel error:outError];
}

- (nullable instancetype)initWithModel:(NSManagedObjectModel *)managedObjectModel error:(NSError *__autoreleasing  __nullable * __nullable)outError {
    return [self initWithURL:nil model:managedObjectModel error:outError];
}

+ (nullable instancetype)storeWithURL:(NSURL *)URL error:(NSError *__autoreleasing  __nullable * __nullable)outError {
    return [[self alloc] initWithURL:URL model:[NSManagedObjectModel mergedModelFromBundles:nil] error:outError];
}

+ (nullable instancetype)storeWithCacheName:(NSString *)cacheName error:(NSError *__autoreleasing  __nullable * __nullable)outError {
    return [[self alloc] initWithCacheName:cacheName model:[NSManagedObjectModel mergedModelFromBundles:nil] error:outError];
}

- (NSManagedObjectContext *)contextWithConcurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType {
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:concurrencyType];
    context.persistentStoreCoordinator = self.persistentStoreCoordinator;
    
    return context;
}

@end

NS_ASSUME_NONNULL_END
