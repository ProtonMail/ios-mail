// NSManagedObject+Groot.m
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

#import "NSManagedObject+Groot.h"

#import "GRTManagedObjectSerializer.h"
#import "GRTError.h"

#import "NSPropertyDescription+Groot.h"
#import "NSAttributeDescription+Groot.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSManagedObject (Groot)

- (void)grt_serializeJSONDictionary:(NSDictionary *)dictionary
                       mergeChanges:(BOOL)mergeChanges
                              error:(NSError *__autoreleasing  __nullable * __nullable)outError
{
    NSError * __block error = nil;
    NSDictionary *propertiesByName = self.entity.propertiesByName;
    
    [propertiesByName enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSPropertyDescription *property, BOOL *stop) {
        if (![property grt_JSONSerializable]) {
            return; // continue
        }
        
        if ([property isKindOfClass:[NSAttributeDescription class]]) {
            NSAttributeDescription *attribute = (NSAttributeDescription *)property;
            [self grt_setAttribute:attribute fromJSONDictionary:dictionary mergeChanges:mergeChanges error:&error];
        } else if ([property isKindOfClass:[NSRelationshipDescription class]]) {
            NSRelationshipDescription *relationship = (NSRelationshipDescription *)property;
            [self grt_setRelationship:relationship fromJSONDictionary:dictionary mergeChanges:mergeChanges error:&error];
        }
        
        *stop = (error != nil); // break on error
    }];
    
    if (error != nil && outError != nil) {
        *outError = error;
    }
}

- (void)grt_serializeJSONValue:(id)value
               uniqueAttribute:(NSAttributeDescription *)attribute
                         error:(NSError *__autoreleasing  __nullable * __nullable)outError
{
    id identifier = [attribute grt_valueForJSONValue:value];
    
    if ([self validateValue:&identifier forKey:attribute.name error:outError]) {
        [self setValue:identifier forKey:attribute.name];
    }
}

- (NSDictionary *)grt_JSONDictionarySerializingRelationships:(NSMutableSet *)serializingRelationships {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    NSManagedObjectContext *context = self.managedObjectContext;
    NSDictionary *propertiesByName = self.entity.propertiesByName;
    
    [context performBlockAndWait:^{
        for (NSString *name in propertiesByName) {
            NSPropertyDescription *property = propertiesByName[name];
            
            if (![property grt_JSONSerializable]) {
                continue;
            }
            
            NSString *keyPath = [property grt_JSONKeyPath];
            id value = [self valueForKey:name];
            
            if (value == nil) {
                value = [NSNull null];
            } else {
                if ([property isKindOfClass:[NSAttributeDescription class]]) {
                    NSAttributeDescription *attribute = (NSAttributeDescription *)property;
                    NSValueTransformer *transformer = [attribute grt_JSONTransformer];
                    
                    if (transformer && [[transformer class] allowsReverseTransformation]) {
                        value = [transformer reverseTransformedValue:value];
                    }
                } else if ([property isKindOfClass:[NSRelationshipDescription class]]) {
                    NSRelationshipDescription *relationship = (NSRelationshipDescription *)property;
                    NSRelationshipDescription *inverseRelationship = relationship.inverseRelationship;
                    
                    if ([serializingRelationships containsObject:inverseRelationship]) {
                        // Skip if the inverse relationship is being serialized
                        continue;
                    }
                    
                    [serializingRelationships addObject:relationship];
                    
                    if (relationship.toMany) {
                        NSArray *managedObjects = @[];
                        if ([value isKindOfClass:[NSOrderedSet class]]) {
                            NSOrderedSet *set = value;
                            managedObjects = set.array;
                        } else if ([value isKindOfClass:[NSSet class]]) {
                            NSSet *set = value;
                            managedObjects = set.allObjects;
                        }
                        
                        NSMutableArray *array = [NSMutableArray arrayWithCapacity:managedObjects.count];
                        for (NSManagedObject *managedObject in managedObjects) {
                            NSDictionary *dictionary = [managedObject grt_JSONDictionarySerializingRelationships:serializingRelationships];
                            [array addObject:dictionary];
                        }
                        value = array;
                    } else {
                        NSManagedObject *managedObject = value;
                        value = [managedObject grt_JSONDictionarySerializingRelationships:serializingRelationships];
                    }
                }
            }
            
            NSMutableArray *components = [[keyPath componentsSeparatedByString:@"."] mutableCopy];
            [components removeLastObject];
            
            if (components.count > 0) {
                // Create a dictionary for each key path component
                NSMutableDictionary *tmpDictionary = dictionary;
                for (NSString *component in components) {
                    if (tmpDictionary[component] == nil) {
                        tmpDictionary[component] = [NSMutableDictionary dictionary];
                    }
                    
                    tmpDictionary = tmpDictionary[component];
                }
            }
            
            [dictionary setValue:value forKeyPath:keyPath];
        }
    }];
    
    return [dictionary copy];
}

#pragma mark - Private

- (void)grt_setAttribute:(NSAttributeDescription *)attribute
      fromJSONDictionary:(NSDictionary *)dictionary
            mergeChanges:(BOOL)mergeChanges
                   error:(NSError *__autoreleasing  __nullable * __nullable)outError
{
    id value = nil;
    id rawValue = [attribute grt_rawValueInJSONDictionary:dictionary];
    
    if (rawValue != nil) {
        if (rawValue != [NSNull null]) {
            NSValueTransformer *transformer = [attribute grt_JSONTransformer];
            if (transformer) {
                value = [transformer transformedValue:rawValue];
            } else {
                value = rawValue;
            }
        }
    } else if (mergeChanges) {
        // Just validate the current value
        value = [self valueForKey:attribute.name];
        [self validateValue:&value forKey:attribute.name error:outError];
        
        return;
    }
    
    if ([self validateValue:&value forKey:attribute.name error:outError]) {
        [self setValue:value forKey:attribute.name];
    }
}

- (void)grt_setRelationship:(NSRelationshipDescription *)relationship
         fromJSONDictionary:(NSDictionary *)dictionary
               mergeChanges:(BOOL)mergeChanges
                      error:(NSError *__autoreleasing  __nullable * __nullable)outError
{
    id value = nil;
    id rawValue = [relationship grt_rawValueInJSONDictionary:dictionary];
    
    if (rawValue != nil && rawValue != [NSNull null]) {
        NSEntityDescription *destinationEntity = relationship.destinationEntity;
        GRTManagedObjectSerializer *serializer = [[GRTManagedObjectSerializer alloc] initWithEntity:destinationEntity];
        
        BOOL isArray = [rawValue isKindOfClass:[NSArray class]];
        NSError *error = nil;
        
        if (relationship.toMany && isArray) {
            NSArray *managedObjects = [serializer serializeJSONArray:rawValue
                                                           inContext:self.managedObjectContext
                                                               error:&error];
            
            if (managedObjects != nil) {
                value = relationship.ordered ? [NSOrderedSet orderedSetWithArray:managedObjects] : [NSSet setWithArray:managedObjects];
            }
        }
        else if (!relationship.toMany && !isArray) {
            NSManagedObject *managedObject = [serializer serializeJSONArray:@[rawValue]
                                                                  inContext:self.managedObjectContext
                                                                      error:&error].firstObject;
            
            if (managedObject != nil) {
                value = managedObject;
            }
        }
        else {
            NSString *format = NSLocalizedString(@"Cannot serialize '%@' into relationship '%@.%@'.", @"Groot");
            NSString *message = [NSString stringWithFormat:format, rawValue, relationship.entity.name, relationship.name];
            error = [NSError errorWithDomain:GRTErrorDomain
                                        code:GRTErrorInvalidJSONObject
                                    userInfo:@{ NSLocalizedDescriptionKey: message }];
        }
        
        if (error != nil) {
            if (outError != nil) *outError = error;
            return;
        }
    } else if (mergeChanges) {
        // Just validate the current value
        value = [self valueForKey:relationship.name];
        [self validateValue:&value forKey:relationship.name error:outError];
        
        return;
    }
    
    if ([self validateValue:&value forKey:relationship.name error:outError]) {
        [self setValue:value forKey:relationship.name];
    }
}

@end

NS_ASSUME_NONNULL_END
