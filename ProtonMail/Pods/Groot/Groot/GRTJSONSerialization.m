// GRTJSONSerialization.m
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

#import "GRTJSONSerialization.h"

#import "NSPropertyDescription+Groot.h"
#import "NSAttributeDescription+Groot.h"
#import "NSEntityDescription+Groot.h"
#import "NSDictionary+Groot.h"

NSString * const GRTJSONSerializationErrorDomain = @"GRTJSONSerializationErrorDomain";
const NSInteger GRTJSONSerializationErrorInvalidJSONObject = 0xcaca;

@implementation GRTJSONSerialization

+ (id)insertObjectForEntityName:(NSString *)entityName fromJSONDictionary:(NSDictionary *)JSONDictionary inManagedObjectContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error {
    NSParameterAssert(JSONDictionary);
    
    return [[self insertObjectsForEntityName:entityName fromJSONArray:@[JSONDictionary] inManagedObjectContext:context error:error] firstObject];
}

+ (NSArray *)insertObjectsForEntityName:(NSString *)entityName fromJSONArray:(NSArray *)JSONArray inManagedObjectContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error {
    NSParameterAssert(entityName);
    NSParameterAssert(JSONArray);
    NSParameterAssert(context);
    
    NSError * __block tmpError = nil;
    NSMutableArray * __block managedObjects = [NSMutableArray arrayWithCapacity:JSONArray.count];
    
    if (JSONArray.count == 0) {
        // Return early and avoid any processing in the context queue
        return managedObjects;
    }
    
    [context performBlockAndWait:^{
        for (NSDictionary *dictionary in JSONArray) {
            if ([dictionary isEqual:NSNull.null]) {
                continue;
            }
            
            if (![dictionary isKindOfClass:NSDictionary.class]) {
                NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Cannot serialize value %@. Expected a JSON dictionary.", @""), dictionary];
                NSDictionary *userInfo = @{
                    NSLocalizedDescriptionKey: message
                };
                
                tmpError = [NSError errorWithDomain:GRTJSONSerializationErrorDomain code:GRTJSONSerializationErrorInvalidJSONObject userInfo:userInfo];
                
                break;
            }
            
            NSManagedObject *managedObject = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:context];
            NSDictionary *propertiesByName = managedObject.entity.propertiesByName;
            
            [propertiesByName enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSPropertyDescription *property, BOOL *stop) {
                if ([property isKindOfClass:NSAttributeDescription.class]) {
                    *stop = ![self serializeAttribute:(NSAttributeDescription *)property fromJSONDictionary:dictionary inManagedObject:managedObject merge:NO error:&tmpError];
                } else if ([property isKindOfClass:NSRelationshipDescription.class]) {
                    *stop = ![self serializeRelationship:(NSRelationshipDescription *)property fromJSONDictionary:dictionary inManagedObject:managedObject merge:NO error:&tmpError];
                }
            }];
            
            if (tmpError == nil) {
                [managedObjects addObject:managedObject];
            } else {
                [context deleteObject:managedObject];
                break;
            }
        }
    }];
    
    if (error != nil) {
        *error = tmpError;
    }
    
    return managedObjects;
}

+ (id)mergeObjectForEntityName:(NSString *)entityName fromJSONDictionary:(NSDictionary *)JSONDictionary inManagedObjectContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error {
    NSParameterAssert(JSONDictionary);
    
    return [[self mergeObjectsForEntityName:entityName fromJSONArray:@[JSONDictionary] inManagedObjectContext:context error:error] firstObject];
}

+ (NSArray *)mergeObjectsForEntityName:(NSString *)entityName fromJSONArray:(NSArray *)JSONArray inManagedObjectContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error {
    NSParameterAssert(entityName);
    NSParameterAssert(JSONArray);
    NSParameterAssert(context);
    
    NSError * __block tmpError = nil;
    NSMutableArray * __block managedObjects = [NSMutableArray arrayWithCapacity:JSONArray.count];
    
    if (JSONArray.count == 0) {
        // Return early and avoid any processing in the context queue
        return managedObjects;
    }
    
    [context performBlockAndWait:^{
        NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
        
        NSAttributeDescription *identityAttribute = [entity grt_identityAttribute];
        NSAssert(identityAttribute != nil, @"An identity attribute must be specified in order to merge objects");
        NSAssert([identityAttribute grt_JSONKeyPath] != nil, @"The identity attribute must have an valid JSON key path");
        
        NSMutableArray *identifiers = [NSMutableArray arrayWithCapacity:JSONArray.count];
        for (NSDictionary *dictionary in JSONArray) {
            if ([dictionary isEqual:NSNull.null]) {
                continue;
            }
            
            if (![dictionary isKindOfClass:NSDictionary.class]) {
                NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Cannot serialize value %@. Expected a JSON dictionary.", @""), dictionary];
                NSDictionary *userInfo = @{
                    NSLocalizedDescriptionKey: message
                };

                tmpError = [NSError errorWithDomain:GRTJSONSerializationErrorDomain code:GRTJSONSerializationErrorInvalidJSONObject userInfo:userInfo];
                return;
            }
            
            id identifier = [dictionary grt_valueForAttribute:identityAttribute];
            if (identifier != nil) [identifiers addObject:identifier];
        }
        
        NSDictionary *existingObjects = [self fetchObjectsForEntity:entity withIdentifiers:identifiers inManagedObjectContext:context error:&tmpError];
        
        for (NSDictionary *dictionary in JSONArray) {
            if ([dictionary isEqual:NSNull.null]) {
                continue;
            }
            
            NSManagedObject *managedObject = nil;
            id identifier = [dictionary grt_valueForAttribute:identityAttribute];
            
            if (identifier) {
                managedObject = existingObjects[identifier];
            }
            
            if (!managedObject) {
                managedObject = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:context];
            }
            
            NSDictionary *propertiesByName = managedObject.entity.propertiesByName;
            
            [propertiesByName enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSPropertyDescription *property, BOOL *stop) {
                if ([property isKindOfClass:NSAttributeDescription.class]) {
                    *stop = ![self serializeAttribute:(NSAttributeDescription *)property fromJSONDictionary:dictionary inManagedObject:managedObject merge:YES error:&tmpError];
                } else if ([property isKindOfClass:NSRelationshipDescription.class]) {
                    *stop = ![self serializeRelationship:(NSRelationshipDescription *)property fromJSONDictionary:dictionary inManagedObject:managedObject merge:YES error:&tmpError];
                }
            }];
            
            if (tmpError == nil) {
                [managedObjects addObject:managedObject];
            } else {
                [context deleteObject:managedObject];
                break;
            }
        }
    }];
    
    if (error != nil) {
        *error = tmpError;
    }
    
    return managedObjects;
}

+ (NSDictionary *)JSONDictionaryFromManagedObject:(NSManagedObject *)managedObject {
    // Keeping track of in process relationships avoids infinite recursion when serializing inverse relationships
    NSMutableSet *processingRelationships = [NSMutableSet set];
    return [self JSONDictionaryFromManagedObject:managedObject processingRelationships:processingRelationships];
}

+ (NSArray *)JSONArrayFromManagedObjects:(NSArray *)managedObjects {
    // Keeping track of in process relationships avoids infinite recursion when serializing inverse relationships
    NSMutableSet *processingRelationships = [NSMutableSet set];
    return [self JSONArrayFromManagedObjects:managedObjects processingRelationships:processingRelationships];
}

#pragma mark - Private

+ (NSDictionary *)JSONDictionaryFromManagedObject:(NSManagedObject *)managedObject processingRelationships:(NSMutableSet *)processingRelationships {
    NSMutableDictionary * __block JSONDictionary = nil;
    NSManagedObjectContext *context = managedObject.managedObjectContext;
    
    if (!managedObject) {
        return nil;
    }
    
    [context performBlockAndWait:^{
        NSDictionary *propertiesByName = managedObject.entity.propertiesByName;
        JSONDictionary = [NSMutableDictionary dictionaryWithCapacity:propertiesByName.count];
        
        [propertiesByName enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSPropertyDescription *property, BOOL *stop) {
            NSString *JSONKeyPath = [property grt_JSONKeyPath];
            
            if (JSONKeyPath == nil) {
                return;
            }
            
            id value = [managedObject valueForKey:name];
            
            if ([property isKindOfClass:NSAttributeDescription.class]) {
                NSAttributeDescription *attribute = (NSAttributeDescription *)property;
                NSValueTransformer *transformer = [attribute grt_JSONTransformer];
                
                if (transformer != nil && [transformer.class allowsReverseTransformation]) {
                    value = [transformer reverseTransformedValue:value];
                }
            } else if ([property isKindOfClass:NSRelationshipDescription.class]) {
                NSRelationshipDescription *relationship = (NSRelationshipDescription *)property;
                
                if ([processingRelationships containsObject:relationship.inverseRelationship]) {
                    // Skip if the inverse relationship is being serialized
                    return;
                }
                
                [processingRelationships addObject:relationship];
                
                if ([relationship isToMany]) {
                    NSArray *objects = [value isKindOfClass:NSOrderedSet.class] ? [value array] : [value allObjects];
                    value = [self JSONArrayFromManagedObjects:objects processingRelationships:processingRelationships];
                } else {
                    value = [self JSONDictionaryFromManagedObject:value processingRelationships:processingRelationships];
                }
            }
            
            if (value == nil) {
                value = NSNull.null;
            }
            
            NSArray *components = [JSONKeyPath componentsSeparatedByString:@"."];
            
            if (components.count > 1) {
                // Create a dictionary for each key path component
                id obj = JSONDictionary;
                for (NSString *component in components) {
                    if ([obj valueForKey:component] == nil) {
                        [obj setValue:[NSMutableDictionary dictionary] forKey:component];
                    }
                    
                    obj = [obj valueForKey:component];
                }
            }
            
            [JSONDictionary setValue:value forKeyPath:JSONKeyPath];
        }];
    }];
    
    return JSONDictionary;
}

+ (NSArray *)JSONArrayFromManagedObjects:(NSArray *)managedObjects processingRelationships:(NSMutableSet *)processingRelationships {
    NSMutableArray *JSONArray = [NSMutableArray arrayWithCapacity:managedObjects.count];
    
    for (NSManagedObject *managedObject in managedObjects) {
        NSDictionary *JSONDictionary = [self JSONDictionaryFromManagedObject:managedObject processingRelationships:processingRelationships];
        [JSONArray addObject:JSONDictionary];
    }
    
    return JSONArray;
}

+ (BOOL)serializeAttribute:(NSAttributeDescription *)attribute fromJSONDictionary:(NSDictionary *)JSONDictionary inManagedObject:(NSManagedObject *)managedObject merge:(BOOL)merge error:(NSError *__autoreleasing *)error {
    NSString *keyPath = [attribute grt_JSONKeyPath];
    
    if (keyPath == nil) {
        return YES;
    }
    
    id value = [JSONDictionary valueForKeyPath:keyPath];

    if (merge && value == nil) {
        return YES;
    }

    if ([value isEqual:NSNull.null]) {
        value = nil;
    }
    
    if (value != nil) {
        NSValueTransformer *transformer = [attribute grt_JSONTransformer];
        if (transformer) {
            value = [transformer transformedValue:value];
        }
    }
    
    if ([managedObject validateValue:&value forKey:attribute.name error:error]) {
        [managedObject setValue:value forKey:attribute.name];
        return YES;
    }
    
    return NO;
}

+ (BOOL)serializeRelationship:(NSRelationshipDescription *)relationship fromJSONDictionary:(NSDictionary *)JSONDictionary inManagedObject:(NSManagedObject *)managedObject merge:(BOOL)merge error:(NSError *__autoreleasing *)error {
    NSString *keyPath = [relationship grt_JSONKeyPath];
    
    if (keyPath == nil) {
        return YES;
    }
    
    id value = [JSONDictionary valueForKeyPath:keyPath];
    
    if (merge && value == nil) {
        return YES;
    }
    
    if ([value isEqual:NSNull.null]) {
        value = nil;
    }
    
    if (value != nil) {
        NSString *entityName = relationship.destinationEntity.name;
        NSManagedObjectContext *context = managedObject.managedObjectContext;
        NSError *tmpError = nil;
        
        if ([relationship isToMany]) {
            if (![value isKindOfClass:[NSArray class]]) {
                if (error) {
                    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Cannot serialize '%@' into a to-many relationship. Expected a JSON array.", @""), [relationship grt_JSONKeyPath]];
                    NSDictionary *userInfo = @{
                        NSLocalizedDescriptionKey: message
                    };
                    
                    *error = [NSError errorWithDomain:GRTJSONSerializationErrorDomain code:GRTJSONSerializationErrorInvalidJSONObject userInfo:userInfo];
                }
                
                return NO;
            }
            
            NSArray *objects = merge
                ? [self mergeObjectsForEntityName:entityName fromJSONArray:value inManagedObjectContext:context error:&tmpError]
                : [self insertObjectsForEntityName:entityName fromJSONArray:value inManagedObjectContext:context error:&tmpError];
            
            value = [relationship isOrdered] ? [NSOrderedSet orderedSetWithArray:objects] : [NSSet setWithArray:objects];
        } else {
            if (![value isKindOfClass:[NSDictionary class]]) {
                if (error) {
                    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Cannot serialize '%@' into a to-one relationship. Expected a JSON dictionary.", @""), [relationship grt_JSONKeyPath]];
                    NSDictionary *userInfo = @{
                        NSLocalizedDescriptionKey: message
                    };
                    
                    *error = [NSError errorWithDomain:GRTJSONSerializationErrorDomain code:GRTJSONSerializationErrorInvalidJSONObject userInfo:userInfo];
                }
                
                return NO;
            }
            
            value = merge
                ? [self mergeObjectForEntityName:entityName fromJSONDictionary:value inManagedObjectContext:context error:&tmpError]
                : [self insertObjectForEntityName:entityName fromJSONDictionary:value inManagedObjectContext:context error:&tmpError];
        }
        
        if (tmpError != nil) {
            if (error) {
                *error = tmpError;
            }
            return NO;
        }
    }
    
    if ([managedObject validateValue:&value forKey:relationship.name error:error]) {
        [managedObject setValue:value forKey:relationship.name];
        return YES;
    }
    
    return NO;
}

+ (NSDictionary *)fetchObjectsForEntity:(NSEntityDescription *)entity withIdentifiers:(NSArray *)identifiers inManagedObjectContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error {
    NSString *identityKey = [[entity grt_identityAttribute] name];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = entity;
    fetchRequest.returnsObjectsAsFaults = NO;
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K IN %@", identityKey, identifiers];
    
    NSArray *objects = [context executeFetchRequest:fetchRequest error:error];
    
    if (objects.count > 0) {
        NSMutableDictionary *objectsByIdentifier = [NSMutableDictionary dictionaryWithCapacity:objects.count];
        
        for (NSManagedObject *object in objects) {
            id identifier = [object valueForKey:identityKey];
            objectsByIdentifier[identifier] = object;
        }
        
        return objectsByIdentifier;
    }
    
    return nil;
}

@end
