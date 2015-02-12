// GRTManagedStore.m
//
// Copyright (c) 2014 Guillermo Gonzalez
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

static NSString *GRTApplicationCachePath() {
    static dispatch_once_t onceToken;
    static NSString *path;
    
    dispatch_once(&onceToken, ^{
        path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        path = [path stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]];
        
        NSError *error = nil;
        BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:path
                                                 withIntermediateDirectories:YES
                                                                  attributes:nil
                                                                       error:&error];
        
        if (!success) {
            NSLog(@"%s Error creating the application cache directory: %@", __PRETTY_FUNCTION__, error);
        }
    });
    
    return path;
}

@interface GRTManagedStore ()

@property (strong, nonatomic, readwrite) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic, readwrite) NSManagedObjectModel *managedObjectModel;

@property (copy, nonatomic) NSString *path;

@end

@implementation GRTManagedStore

#pragma mark - Properties

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (!_persistentStoreCoordinator) {
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
        
        NSString *storeType = self.path ? NSSQLiteStoreType : NSInMemoryStoreType;
        NSURL *storeURL = self.path ? [NSURL fileURLWithPath:self.path] : nil;
        
        NSDictionary *options = @{
                                  NSMigratePersistentStoresAutomaticallyOption: @YES,
                                  NSInferMappingModelAutomaticallyOption: @YES
                                  };
        
        NSError *error = nil;
        NSPersistentStore *store = [_persistentStoreCoordinator addPersistentStoreWithType:storeType
                                                                             configuration:nil
                                                                                       URL:storeURL
                                                                                   options:options
                                                                                     error:&error];
        if (!store) {
            NSLog(@"%@ Error creating persistent store: %@", self, error);
        }
    }
    
    return _persistentStoreCoordinator;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (!_managedObjectModel) {
        _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    }
    
    return _managedObjectModel;
}

#pragma mark - Lifecycle

+ (instancetype)managedStoreWithModel:(NSManagedObjectModel *)managedObjectModel {
    return [[self alloc] initWithPath:nil managedObjectModel:managedObjectModel];
}

+ (instancetype)temporaryManagedStore {
    NSString *fileName = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
    
    return [[self alloc] initWithPath:path managedObjectModel:nil];
}

+ (instancetype)managedStoreWithCacheName:(NSString *)cacheName {
    NSParameterAssert(cacheName);
    
    NSString *path = [GRTApplicationCachePath() stringByAppendingPathComponent:cacheName];
    return [[self alloc] initWithPath:path managedObjectModel:nil];
}

- (id)init {
    return [self initWithPath:nil managedObjectModel:nil];
}

- (id)initWithPath:(NSString *)path managedObjectModel:(NSManagedObjectModel *)managedObjectModel {
    self = [super init];
    
    if (self) {
        _path = [path copy];
        _managedObjectModel = managedObjectModel;
    }
    
    return self;
}

@end
