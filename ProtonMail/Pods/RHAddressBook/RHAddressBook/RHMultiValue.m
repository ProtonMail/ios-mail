//
//  RHMultiValue.m
//  RHAddressBook
//
//  Created by Richard Heard on 11/11/11.
//  Copyright (c) 2011 Richard Heard. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions
//  are met:
//  1. Redistributions of source code must retain the above copyright
//  notice, this list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright
//  notice, this list of conditions and the following disclaimer in the
//  documentation and/or other materials provided with the distribution.
//  3. The name of the author may not be used to endorse or promote products
//  derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
//  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
//  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
//  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
//  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "RHMultiValue.h"

#import "RHPerson.h"
#import "RHRecord.h"

@implementation RHMultiValue

@synthesize multiValueRef=_multiValueRef;

#pragma mark - init
-(id)initWithMultiValueRef:(ABMultiValueRef)multiValueRef{
    self = [super init];
    if (self){
        if (!multiValueRef){
            arc_release_nil(self);
            return nil;
        }

        _multiValueRef = CFRetain(multiValueRef);
    }
    return self;
}

-(void)dealloc{
    if (_multiValueRef) CFRelease(_multiValueRef);
    _multiValueRef = NULL;
    
    arc_super_dealloc();
}

#pragma mark - basic accessors

-(ABPropertyType)propertyType{
    return ABMultiValueGetPropertyType(_multiValueRef);
}

- (NSUInteger)count{
    return ABMultiValueGetCount(_multiValueRef);
}

//values
-(id)valueAtIndex:(NSUInteger)index{
    id value = (id)ARCBridgingRelease(ABMultiValueCopyValueAtIndex(_multiValueRef, index));
    return value;
}

-(NSArray*)values{
    NSArray* values = (NSArray*)ARCBridgingRelease(ABMultiValueCopyArrayOfAllValues(_multiValueRef));
    return values;
}

//labels
-(NSString*)labelAtIndex:(NSUInteger)index{
    NSString* label = (NSString*)ARCBridgingRelease(ABMultiValueCopyLabelAtIndex(_multiValueRef, index));
    return label;
}

-(NSString*)localizedLabelAtIndex:(NSUInteger)index{
    return [RHPerson localizedLabel:[self labelAtIndex:index]];
}

//identifier
-(NSUInteger)indexForIdentifier:(ABMultiValueIdentifier)identifier{
    return ABMultiValueGetIndexForIdentifier(_multiValueRef, identifier);
}

-(ABMultiValueIdentifier)identifierAtIndex:(NSUInteger)index{
    return ABMultiValueGetIdentifierAtIndex(_multiValueRef, index);
}

//convenience accessor
-(NSUInteger)firstIndexOfValue:(id)value{
    return ABMultiValueGetFirstIndexOfValue(_multiValueRef, (__bridge CFTypeRef)(value));
}

//mutable copy
-(RHMutableMultiValue*)mutableCopy{
    //first make a mutable ref
    ABMutableMultiValueRef mutableRef = ABMultiValueCreateMutableCopy(_multiValueRef);
    
    //then create a mutable wrapper instance
    RHMutableMultiValue *new = nil;
    if (mutableRef){
        new = [[RHMutableMultiValue alloc] initWithMultiValueRef:mutableRef];
        CFRelease(mutableRef);
    }
    
    return new;
}


#pragma mark - misc

-(NSString*)contentDescription{
    NSString *result = @"";

    NSUInteger index = [self count];
    while (index > 0) {
        index--;
        result = [NSString stringWithFormat:@"\t%lu) %@=%@\n%@", (unsigned long)index, [self labelAtIndex:index], [self valueAtIndex:index], result];
    }

    return result;
}

-(NSString*)description{
    return [NSString stringWithFormat:@"%@: <%p> type:%@ count:%lu contents:{%@}", NSStringFromClass([self class]), self, [RHRecord descriptionForPropertyType:[self propertyType]], (unsigned long)[self count], [self contentDescription]];
}

-(BOOL)isEqual:(id)object{
    if (self == object) return YES;
    if (!object) return NO;
    if (![object isKindOfClass:[RHMultiValue class]]) return NO;
    
    return [self isEqualToMultiValue:object];
}
-(BOOL)isEqualToMultiValue:(RHMultiValue*)otherMultiValue{
    
    if (![self count] == [otherMultiValue count]) return NO;
    
    for (int i = 0; i < [self count]; i++) {
        if (! [[self labelAtIndex:i] isEqualToString:[otherMultiValue labelAtIndex:i]]) return NO;
        if (! [[self valueAtIndex:i] isEqual:[otherMultiValue valueAtIndex:i]]) return NO;
    }
    return YES;
}

@end


@implementation RHMutableMultiValue

#pragma mark - basic modifiers (mutable)

-(id)initWithType:(ABPropertyType)newPropertyType{
    ABMultiValueRef multiValueRef = ABMultiValueCreateMutable(newPropertyType);
    id new = nil;
    if (multiValueRef){
        new = [self initWithMultiValueRef:multiValueRef];
        CFRelease(multiValueRef);
    }
    return new;
}


-(ABMultiValueIdentifier)addValue:(id)value withLabel:(NSString *)label{
    ABMultiValueIdentifier idOut = kABMultiValueInvalidIdentifier;
    ABMultiValueAddValueAndLabel(_multiValueRef, (__bridge CFTypeRef)(value), (__bridge CFStringRef)label, &idOut);
    return idOut;
}

-(ABMultiValueIdentifier)insertValue:(id)value withLabel:(NSString *)label atIndex:(NSUInteger)index{
    ABMultiValueIdentifier idOut = kABMultiValueInvalidIdentifier;
    ABMultiValueInsertValueAndLabelAtIndex(_multiValueRef, (__bridge CFTypeRef)(value), (__bridge CFStringRef)label, index, &idOut);
    return idOut;
}

-(BOOL)removeValueAndLabelAtIndex:(NSUInteger)index{
    return ABMultiValueRemoveValueAndLabelAtIndex(_multiValueRef, index);
}

-(BOOL)replaceValueAtIndex:(NSUInteger)index withValue:(id)value{
    return ABMultiValueReplaceValueAtIndex(_multiValueRef, (__bridge CFTypeRef)(value), index);
}

-(BOOL)replaceLabelAtIndex:(NSUInteger)index withLabel:(NSString*)label{
    return ABMultiValueReplaceLabelAtIndex(_multiValueRef, (__bridge CFStringRef)label, index);
}

@end
