//
//  RHMultiValue.h
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

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>


@class RHMultiValue;
@class RHMutableMultiValue;

//some clarifying typedefs. no need for separate subclasses.
typedef RHMultiValue RHMultiStringValue;
typedef RHMultiValue RHMultiIntegerValue;
typedef RHMultiValue RHMultiRealValue;
typedef RHMultiValue RHMultiDateTimeValue;
typedef RHMultiValue RHMultiDictionaryValue;

typedef RHMutableMultiValue RHMutableMultiStringValue;
typedef RHMutableMultiValue RHMutableMultiIntegerValue;
typedef RHMutableMultiValue RHMutableMultiRealValue;
typedef RHMutableMultiValue RHMutableMultiDateTimeValue;
typedef RHMutableMultiValue RHMutableMultiDictionaryValue;


@interface RHMultiValue : NSObject {
    ABMultiValueRef _multiValueRef;
}

// a multi-value is an ordered collection of key / value pairs. (mutable or immutable.)
// this is a generic top level collection object. 

@property (readonly) ABMultiValueRef multiValueRef;

//init
-(id)initWithMultiValueRef:(ABMultiValueRef)multiValueRef; //passing NULL to init is invalid
                       
//accessors
-(ABPropertyType)propertyType;

//values
-(NSUInteger)count; 
-(id)valueAtIndex:(NSUInteger)index;
-(NSArray*)values;

//labels
-(NSString*)labelAtIndex:(NSUInteger)index;
-(NSString*)localizedLabelAtIndex:(NSUInteger)index;

//identifier
-(NSUInteger)indexForIdentifier:(ABMultiValueIdentifier)identifier;
-(ABMultiValueIdentifier)identifierAtIndex:(NSUInteger)index;

//convenience accessor
-(NSUInteger)firstIndexOfValue:(id)value;

//mutable copy
-(RHMutableMultiValue*)mutableCopy;

//equality
-(BOOL)isEqualToMultiValue:(RHMultiValue*)otherMultiValue;

@end


//mutable additions
@interface RHMutableMultiValue : RHMultiValue

//init
-(id)initWithType:(ABPropertyType)newPropertyType; //a new MultiValue Ref of specified type is created on your behalf.

-(ABMultiValueIdentifier)addValue:(id)value withLabel:(NSString *)label; //on failure kABMultiValueInvalidIdentifier
-(ABMultiValueIdentifier)insertValue:(id)value withLabel:(NSString *)label atIndex:(NSUInteger)index; //on failure kABMultiValueInvalidIdentifier

-(BOOL)removeValueAndLabelAtIndex:(NSUInteger)index;

-(BOOL)replaceValueAtIndex:(NSUInteger)index withValue:(id)value;
-(BOOL)replaceLabelAtIndex:(NSUInteger)index withLabel:(NSString*)label;


@end
