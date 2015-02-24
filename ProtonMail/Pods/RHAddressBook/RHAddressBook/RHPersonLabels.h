//
//  RHPersonLabels.h
//  RHAddressBook
//
//  Created by Richard Heard on 22/03/12.
//  Copyright (c) 2012 Richard Heard. All rights reserved.
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

#ifndef RHAddressBook_RHPersonLabels_h
#define RHAddressBook_RHPersonLabels_h


    // Generic labels
    #define RHWorkLabel     (NSString*)kABWorkLabel
    #define RHHomeLabel     (NSString*)kABHomeLabel
    #define RHOtherLabel    (NSString*)kABOtherLabel
    

    // Addresses
    #define RHPersonAddressStreetKey        (NSString*)kABPersonAddressStreetKey
    #define RHPersonAddressCityKey          (NSString*)kABPersonAddressCityKey
    #define RHPersonAddressStateKey         (NSString*)kABPersonAddressStateKey
    #define RHPersonAddressZIPKey           (NSString*)kABPersonAddressZIPKey
    #define RHPersonAddressCountryKey       (NSString*)kABPersonAddressCountryKey
    #define RHPersonAddressCountryCodeKey   (NSString*)kABPersonAddressCountryCodeKey

    
    // Dates
    #define RHPersonAnniversaryLabel    (NSString*)kABPersonAnniversaryLabel
    
    // Kind
    #define RHPersonKindPerson          (NSNumber*)kABPersonKindPerson
    #define RHPersonKindOrganization    (NSNumber*)kABPersonKindOrganization
        

    // Phone numbers
    #define RHPersonPhoneMobileLabel    (NSString*)kABPersonPhoneMobileLabel
    #define RHPersonPhoneIPhoneLabel    (NSString*)kABPersonPhoneIPhoneLabel    //3.0
    #define RHPersonPhoneMainLabel      (NSString*)kABPersonPhoneMainLabel
    #define RHPersonPhoneHomeFAXLabel   (NSString*)kABPersonPhoneHomeFAXLabel
    #define RHPersonPhoneWorkFAXLabel   (NSString*)kABPersonPhoneWorkFAXLabel
    #define RHPersonPhoneOtherFAXLabel  (NSString*)kABPersonPhoneOtherFAXLabel  //5.0
    #define RHPersonPhonePagerLabel     (NSString*)kABPersonPhonePagerLabel


    // IM
    #define RHPersonInstantMessageServiceKey    (NSString*)kABPersonInstantMessageServiceKey    // Service ("Yahoo", "Jabber", etc.)
    #define RHPersonInstantMessageServiceYahoo  (NSString*)kABPersonInstantMessageServiceYahoo
    #define RHPersonInstantMessageServiceJabber (NSString*)kABPersonInstantMessageServiceJabber
    #define RHPersonInstantMessageServiceMSN    (NSString*)kABPersonInstantMessageServiceMSN
    #define RHPersonInstantMessageServiceICQ    (NSString*)kABPersonInstantMessageServiceICQ
    #define RHPersonInstantMessageServiceAIM    (NSString*)kABPersonInstantMessageServiceAIM
    #define RHPersonInstantMessageServiceQQ         (NSString*)kABPersonInstantMessageServiceQQ           //5.0
    #define RHPersonInstantMessageServiceGoogleTalk (NSString*)kABPersonInstantMessageServiceGoogleTalk   //5.0
    #define RHPersonInstantMessageServiceSkype      (NSString*)kABPersonInstantMessageServiceSkype        //5.0
    #define RHPersonInstantMessageServiceFaceboo    (NSString*)kABPersonInstantMessageServiceFaceboo      //5.0
    #define RHPersonInstantMessageServiceGaduGadu   (NSString*)kABPersonInstantMessageServiceGaduGadu     //5.0

    #define RHPersonInstantMessageUsernameKey   (NSString*)kABPersonInstantMessageUsernameKey   // Username
    

    // URLs
    #define RHPersonHomePageLabel   (NSString*)kABPersonHomePageLabel   // Home Page
    

    // Related names    
    #define RHPersonFatherLabel     (NSString*)kABPersonFatherLabel    // Father
    #define RHPersonMotherLabel     (NSString*)kABPersonMotherLabel    // Mother
    #define RHPersonParentLabel     (NSString*)kABPersonParentLabel    // Parent
    #define RHPersonBrotherLabel    (NSString*)kABPersonBrotherLabel   // Brother
    #define RHPersonSisterLabel     (NSString*)kABPersonSisterLabel    // Sister
    #define RHPersonChildLabel      (NSString*)kABPersonChildLabel     // Child
    #define RHPersonFriendLabel     (NSString*)kABPersonFriendLabel    // Friend
    #define RHPersonSpouseLabel     (NSString*)kABPersonSpouseLabel    // Spouse
    #define RHPersonPartnerLabel    (NSString*)kABPersonPartnerLabel   // Partner
    #define RHPersonAssistantLabel  (NSString*)kABPersonAssistantLabel // Assistant
    #define RHPersonManagerLabel    (NSString*)kABPersonManagerLabel   // Manager
    

    // Social Profile
    #define RHPersonSocialProfileURLKey             (NSString*)kABPersonSocialProfileURLKey             //5.0 string representation of a url for the social profile
                                                                                                        //5.0 the following properties are optional
    #define RHPersonSocialProfileServiceKey         (NSString*)kABPersonSocialProfileServiceKey         //5.0 string representing the name of the service (Twitter, Facebook, LinkedIn, etc.)
    #define RHPersonSocialProfileUsernameKey        (NSString*)kABPersonSocialProfileUsernameKey        //5.0 string representing the user visible name
    #define RHPersonSocialProfileUserIdentifierKey  (NSString*)kABPersonSocialProfileUserIdentifierKey	//5.0 string representing the service specific identifier (optional)
    
    #define RHPersonSocialProfileServiceTwitter     (NSString*)kABPersonSocialProfileServiceTwitter     //5.0
    #define RHPersonSocialProfileServiceGameCenter  (NSString*)kABPersonSocialProfileServiceGameCenter  //5.0
    #define RHPersonSocialProfileServiceFacebook    (NSString*)kABPersonSocialProfileServiceFacebook    //5.0
    #define RHPersonSocialProfileServiceMyspace     (NSString*)kABPersonSocialProfileServiceMyspace     //5.0
    #define RHPersonSocialProfileServiceLinkedIn    (NSString*)kABPersonSocialProfileServiceLinkedIn    //5.0
    #define RHPersonSocialProfileServiceFlickr      (NSString*)kABPersonSocialProfileServiceFlickr      //5.0


#endif
