## RHAddressBook
A Cocoa / Objective-C library for interfacing with the iOS AddressBook with added geocoding support. 

* All attributes on various objects are exposed as properties, allowing for simple Obj-C code. (No more dealing with CF methods etc )
* Built in support for background Geocoding with an in-built persistent cache. (iOS5+ only) 
* vCard import and export for single and multiple people.
* Access to all underlying ABRecordRefs & ABAddressBookRefs etc.
* Maintains an underlying thread for each ab instance in-order to ensure thread safety.
* Sends NSNotifications when ab has changed.
* Geocoding is disabled by default. (See RH_AB_INCLUDE_GEOCODING)


### Bonus Features
* Unit Tests.
* Basic Demo App.

## Classes
* RHAddressBook
* RHSource - Representation of various address-book sources found on the iPhone
* RHGroup
* RHPerson - Represents a person in the addressbook. 
* RHMultiValue - Represents multiple key/value pairs. Used for RHPersons addresses etc.

## Getting Started
Include RHAddressBook in your iOS project.

```objectivec
    #import <RHAddressBook/AddressBook.h>
```
Getting an instance of the addressbook.

```objectivec
    RHAddressBook *ab = [[[RHAddressBook alloc] init] autorelease];
```
Support for iOS6+ authorization 

```objectivec
    //query current status, pre iOS6 always returns Authorized
    if ([RHAddressBook authorizationStatus] == RHAuthorizationStatusNotDetermined){
    
    	//request authorization
        [ab requestAuthorizationWithCompletion:^(bool granted, NSError *error) {
            [abViewController setAddressBook:ab];
        }];
    }
```
Registering for addressbook changes 

```objectivec
    [[NSNotificationCenter defaultCenter]  addObserver:self selector:@selector(addressBookChanged:) name:RHAddressBookExternalChangeNotification object:nil];
```
Getting sources.

```objectivec
    NSArray *sources = [ab sources];
    RHSource *defaultSource = [ab defaultSource];
```
Getting a list of groups.

```objectivec
    NSArray *groups = [ab groups];
    long numberOfGroups = [ab numberOfGroups];
    NSArray *groupsInSource = [ab groupsInSource:defaultSource];
    RHGroup *lastGroup = [groups lastObject];
```
Getting a list of people.

```objectivec
    NSArray *allPeople = [ab people];
    long numberOfPeople = [ab numberOfPeople];
    NSArray *allPeopleSorted = [ab peopleOrderedByUsersPreference];
    NSArray *allFreds = [ab peopleWithName:@"Fred"];
    NSArray *allFredsInLastGroup = [lastGroup peopleWithName:@"Fred"];
    RHPerson *person = [allPeople lastObject];
```
Getting basic properties on on a person.

```objectivec
    NSString *department = [person department];
    UIImage *thumbnail = [person thumbnail];
    BOOL isCompany = [person isOrganization];
```
Setting basic properties on a person.

```objectivec
    person.name = @"Freddie";
    [person setImage:[UIImage imageNames:@"hahaha.jpg"]];
    person.kind = kABPersonKindOrganization;
    [person save];
```
Getting MultiValue properties on a person.

```objectivec
    RHMultiDictionaryValue *addressesMultiValue = [person addresses];
    NSString *firstAddressLabel = [RHPerson localizedLabel:[addressesMultiValue labelAtIndex]]; //eg Home
    NSDictionary *firstAddress = [addressesMultiValue valueAtIndex:0];
```
Setting MultiValue properties on a person.

```objectivec
    RHMultiStringValue *phoneMultiValue = [person phoneNumbers];
    RHMutableMultiStringValue *mutablePhoneMultiValue = [[phoneMultiValue mutableCopy] autorelease];
    if (! mutablePhoneMultiValue) mutablePhoneMultiValue = [[[RHMutableMultiStringValue alloc] initWithType:kABMultiStringPropertyType] autorelease];
    
    //RHPersonPhoneIPhoneLabel casts kABPersonPhoneIPhoneLabel to the correct toll free bridged type, see RHPersonLabels.h
    mutablePhoneMultiValue addValue:@"+14086655555" withLabel:RHPersonPhoneIPhoneLabel]; 
    person.phonenumbers = mutablePhoneMultiValue;
    [person save];
```
Creating a new person.

```objectivec
    RHPerson *newPerson = [[ab newPersonInDefaultSource] autorelease]; //added to ab
    RHPerson *newPerson2  = [[[RHPerson newPersonInSource:[ab defaultSource]] autorelease]; //not added to ab
    [ab addPerson:newPerson2];
    NSError* error = nil;
    if (![ab save:&error]) NSLog(@"error saving: %@", error);
```
Getting an RHPerson object for an ABRecordRef for editing. (note: RHPerson might not be associated with the same addressbook as the original ABRecordRef)

```objectivec
    ABRecordRef personRef = ...;
    RHPerson *person = [ab personForRecordRef:personRef];
    if(person){
        person.firstName = @"Paul";
        person.lastName = @"Frank";
        [person save];
    }
```
Presenting / editing an RHPerson instance in a ABPersonViewController.

```objectivec
    ABPersonViewController *personViewController = [[[ABPersonViewController alloc] init] autorelease];   

    //setup (tell the view controller to use our underlying address book instance, so our person object is directly updated on our behalf)
     [person.addressBook performAddressBookAction:^(ABAddressBookRef addressBookRef) {
        personViewController.addressBook =addressBookRef;
    } waitUntilDone:YES];

    personViewController.displayedPerson = person.recordRef;
    personViewController.allowsEditing = YES;

    [self.navigationController pushViewController:personViewController animated:YES];
```
Background geocoding

```objectivec
    if ([RHAddressBook isGeocodingSupported){
        [RHAddressBook setPreemptiveGeocodingEnabled:YES]; //class method
    }
    float progress = [_addressBook preemptiveGeocodingProgress]; // 0.0f - 1.0f
```
Geocoding results for a person.

```objectivec
    CLLocation *location = [person locationForAddressID:0];
    CLPlacemark *placemark = [person placemarkForAddressID:0];
```

Finding people within distance of a location.

```objectivec
    NSArray *inRangePeople = [ab peopleWithinDistance:5000 ofLocation:location];
    NSLog(@"people:%@", inRangePeople);
```

Saving. (all of the below are equivalent)

```objectivec
    BOOL changes = [ab hasUnsavedChanges];
    BOOL result = [ab save];
    BOOL result =[source save];
    BOOL result =[group save];
    BOOL result =[person save];
```
Reverting changes on objects. (reverts the entire addressbook instance, not just the object revert is called on.)

```objectivec
    [ab revert];
    [source revert];
    [group revert];
    [person revert];
```
Remember, save often in order to avoid painful save conflicts.

## Installing
For instructions on how to get started using this static library see [Using Static iOS Libraries](http://rheard.com/blog/using-static-ios-libraries/) at [rheard.com](http://rheard.com).

## Licence
Released under the Modified BSD License. 
(Attribution Required)
<pre>
RHAddressBook

Copyright (c) 2011-2012 Richard Heard. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.
3. The name of the author may not be used to endorse or promote products
derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
</pre>


### iOS Version Support (Executive Summary: Supports iOS 4+, tested on iOS 4.0 - 7.1)
This Framework code runs and compiles on and has been tested all the way back to iOS 4.0. 

Unit tests are in place that run on all versions between 4.0 and 7.1.

Various methods are not available when linking against older SDKs and will return nil when running on older os versions.
eg. Geocoding is only supported on iOS 5+. You should always use the +[RHAddressBook isGeocodingAvailable] method to check whether geocoding is available before attempting to access geocode information. Methods will however, if available safely return nil / empty arrays.
