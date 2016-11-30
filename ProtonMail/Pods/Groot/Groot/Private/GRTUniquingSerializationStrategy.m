// GRTUniquingSerializationStrategy.m
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

#import "GRTUniquingSerializationStrategy.h"

#import "NSEntityDescription+Groot.h"
#import "NSAttributeDescription+Groot.h"
#import "NSManagedObject+Groot.h"

NS_ASSUME_NONNULL_BEGIN

@interface GRTUniquingSerializationStrategy ()

@property (strong, nonatomic, readonly) NSAttributeDescription *uniqueAttribute;

@end

@implementation GRTUniquingSerializationStrategy

@synthesize entity = _entity;

- (instancetype)initWithEntity:(NSEntityDescription *)entity uniqueAttribute:(NSAttributeDescription *)uniqueAttribute {
    self = [super init];
    if (self) {
        _entity = entity;
        _uniqueAttribute = uniqueAttribute;
    }
    return self;
}

- (NSArray *)serializeJSONArray:(NSArray *)array
                      inContext:(NSManagedObjectContext *)context
                          error:(NSError *__autoreleasing  __nullable * __nullable)outError
{
    NSMutableArray * __block managedObjects = [NSMutableArray array];
    NSError * __block error = nil;
    
    [context performBlockAndWait:^{
        NSDictionary *existingObjects = [self existingObjectsWithJSONArray:array
                                                                 inContext:context
                                                                     error:&error];
        if (error != nil) {
            return; // Exit the block
        }
        
        for (id obj in array) {
            if (obj == [NSNull null]) {
                continue;
            }
            
            NSManagedObject *managedObject = [self serializeJSONValue:obj
                                                            inContext:context
                                                      existingObjects:existingObjects
                                                                error:&error];
            
            if (error != nil) {
                break;
            }
            
            [managedObjects addObject:managedObject];
        }
    }];
    
    if (error != nil) {
        if (outError != nil) {
            *outError = error;
        }
    }
    
    return managedObjects;
}

#pragma mark - Private

- (nullable NSDictionary *)existingObjectsWithJSONArray:(NSArray *)array
                                              inContext:(NSManagedObjectContext *)context
                                                  error:(NSError *__autoreleasing  __nullable * __nullable)outError
{
    NSArray *identifiers = [self.uniqueAttribute grt_valuesInJSONArray:array];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = self.entity;
    fetchRequest.returnsObjectsAsFaults = NO;
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K IN %@", self.uniqueAttribute.name, identifiers];
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:outError];
    
    if (fetchedObjects != nil) {
        NSMutableDictionary *objects = [NSMutableDictionary dictionaryWithCapacity:fetchedObjects.count];
        
        for (NSManagedObject *object in fetchedObjects) {
            id identifier = [object valueForKey:self.uniqueAttribute.name];
            if (identifier != nil) {
                objects[identifier] = object;
            }
        }
        return objects;
    }
    
    return nil;
}

- (NSManagedObject *)serializeJSONValue:(id)value
                              inContext:(NSManagedObjectContext *)context
                        existingObjects:(NSDictionary *)existingObjects
                                  error:(NSError *__autoreleasing  __nullable * __nullable)outError
{
    NSManagedObject *managedObject = [self managedObjectForJSONValue:value
                                                           inContext:context
                                                     existingObjects:existingObjects];
    
    NSError *error = nil;
    if ([value isKindOfClass:[NSDictionary class]]) {
        [managedObject grt_serializeJSONDictionary:value mergeChanges:YES error:&error];
    } else {
        [managedObject grt_serializeJSONValue:value
                              uniqueAttribute:self.uniqueAttribute
                                        error:&error];
    }
    
    if (error != nil) {
        [context deleteObject:managedObject];
        
        if (outError != nil) {
            *outError = error;
        }
        
        return nil;
    }
    
    return managedObject;
}

- (NSManagedObject *)managedObjectForJSONValue:(id)value
                                     inContext:(NSManagedObjectContext *)context
                               existingObjects:(NSDictionary *)existingObjects
{
    NSManagedObject *managedObject = nil;
    
    id identifier = [self.uniqueAttribute grt_valueForJSONValue:value];
    if (identifier != nil) {
        managedObject = existingObjects[identifier];
    }
    
    if (managedObject == nil) {
        NSString *entityName = [self.entity grt_subentityNameForJSONValue:value];
        managedObject = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                      inManagedObjectContext:context];
    }
    
    return managedObject;
}

@end

NS_ASSUME_NONNULL_END
