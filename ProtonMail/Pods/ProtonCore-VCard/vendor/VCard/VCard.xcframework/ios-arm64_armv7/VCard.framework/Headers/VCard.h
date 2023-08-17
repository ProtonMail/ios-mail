//
//  VCard.h
//  VCard
//
//  Created by Yanfeng Zhang on 3/3/21.
//  Copyright © 2021 Yanfeng Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for OpenPGP.
FOUNDATION_EXPORT double VCardVersionNumber;

//! Project version string for OpenPGP.
FOUNDATION_EXPORT const unsigned char VCardVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <OpenPGP/PublicHeader.h>


//
////pgp part
//#include <OpenPGP/PMNOpenPgp.h>
//#include <OpenPGP/PMNSrpClient.h>
//#include <OpenPGP/PMNLibVersion.h>
//#include <OpenPGP/PMNBCryptHash.h>
//
//vcard part
#import <VCard/PMNIEzvcard.h>
#import <VCard/PMNIVCard.h>
#import <VCard/PMNIFormattedName.h>
#import <VCard/PMNIVCardVersion.h>
#import <VCard/PMNIOrganization.h>
#import <VCard/PMNIAddress.h>
#import <VCard/PMNITelephone.h>
#import <VCard/PMNIEmail.h>
#import <VCard/PMNICategories.h>
#import <VCard/PMNIUrl.h>
#import <VCard/PMNIUid.h>
#import <VCard/PMNIStructuredName.h>
#import <VCard/PMNINote.h>
#import <VCard/PMNIPMCustom.h>
#import <VCard/PMNINickname.h>
#import <VCard/PMNITitle.h>
#import <VCard/PMNIGender.h>
#import <VCard/PMNIBirthday.h>
#import <VCard/PMNIAnniversary.h>
#import <VCard/PMNIPMSign.h>
#import <VCard/PMNIPMEncrypt.h>
#import <VCard/PMNIKey.h>
#import <VCard/PMNIPMScheme.h>
#import <VCard/PMNIPMMimeType.h>
#import <VCard/PMNIPhoto.h>
