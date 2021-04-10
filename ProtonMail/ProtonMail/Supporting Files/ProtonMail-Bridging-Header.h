//
//  ProtonMail-Bridging-Header.h
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


#ifndef ProtonMail_ProtonMail_Bridging_Header_h
#define ProtonMail_ProtonMail_Bridging_Header_h

//new work
//#import <AFNetworking/AFNetworking.h>
//#import <AFNetworking/UIKit+AFNetworking.h>
//#import <AFNetworkActivityLogger.h>
//#import <AFNetworkActivityConsoleLogger.h>


#import <CommonCrypto/CommonCrypto.h>

//try catch objective-c
#import "SwiftTryCatch.h"

//1 password
#import "OnePasswordExtension.h"

//network check
#import "Reachability.h"

//localization
#import "LanguageManager.h"
#import "NSBundle+Language.h"

//pgp part
#import <OpenPGP/PMNOpenPgp.h>
#import <OpenPGP/PMNSrpClient.h>
#import <OpenPGP/PMNLibVersion.h>
#import <OpenPGP/PMNBCryptHash.h>

//vcard part
#import <OpenPGP/PMNIEzvcard.h>
#import <OpenPGP/PMNIVCard.h>
#import <OpenPGP/PMNIFormattedName.h>
#import <OpenPGP/PMNIVCardVersion.h>
#import <OpenPGP/PMNIOrganization.h>
#import <OpenPGP/PMNIAddress.h>
#import <OpenPGP/PMNITelephone.h>
#import <OpenPGP/PMNIEmail.h>
#import <OpenPGP/PMNICategories.h>
#import <OpenPGP/PMNIUrl.h>
#import <OpenPGP/PMNIUid.h>
#import <OpenPGP/PMNIStructuredName.h>
#import <OpenPGP/PMNINote.h>
#import <OpenPGP/PMNIPMCustom.h>
#import <OpenPGP/PMNINickname.h>
#import <OpenPGP/PMNITitle.h>
#import <OpenPGP/PMNIGender.h>
#import <OpenPGP/PMNIBirthday.h>
#import <OpenPGP/PMNIAnniversary.h>
#import <OpenPGP/PMNIPMSign.h>
#import <OpenPGP/PMNIPMEncrypt.h>
#import <OpenPGP/PMNIKey.h>
#import <OpenPGP/PMNIPMScheme.h>
#import <OpenPGP/PMNIPMMimeType.h>
#import <OpenPGP/PMNIPhoto.h>

#endif
