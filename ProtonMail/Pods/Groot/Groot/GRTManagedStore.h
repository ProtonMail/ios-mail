// GRTManagedStore.h
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

#import <CoreData/CoreData.h>

/**
 Manages a Core Data stack.
 */
@interface GRTManagedStore : NSObject

/**
 The persistent store coordinator.
 */
@property (strong, nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

/**
 The managed object model.
 */
@property (strong, nonatomic, readonly) NSManagedObjectModel *managedObjectModel;

/**
 Creates and returns a `GRTManagedStore` that will persist its data in memory.
 */
+ (instancetype)managedStoreWithModel:(NSManagedObjectModel *)managedObjectModel;

/**
 Creates and returns a `GRTManagedStore` that will persist its data in a temporary file.
 */
+ (instancetype)temporaryManagedStore;

/**
 Creates and returns a `GRTManagedStore` that will persist its data in the application caches directory.
 
 @param cacheName The file name.
 */
+ (instancetype)managedStoreWithCacheName:(NSString *)cacheName;

/**
 Initializes the receiver with the specified path and managed object model.
 
 This is the designated initializer.
 
 @param path The persistent store path. If `nil` the persistent store will be created in memory.
 @param managedObjectModel The managed object model. If `nil` all models in the current bundle will be used.
 */
- (id)initWithPath:(NSString *)path managedObjectModel:(NSManagedObjectModel *)managedObjectModel;

@end
