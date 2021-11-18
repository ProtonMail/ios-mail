// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import XCTest
@testable import ProtonMail

class EncryptedSearchTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /*func testBuildSearchIndex() throws {
        //TODO
    }*/
    
    /*func testExtractKeyWordsFromBody() throws {
        let body: String = "<div dir=\"ltr\">this is a testmessage<br></div>\n"
        let sut = EncryptedSearchService.shared.extractKeywordsFromBody
        let result = sut(body, true)
        
        XCTAssertEqual(result, "this is a testmessage")
    }*/
    
    /*func testExtractKeyWordsFromBodyRemoveBlockQuotesProtonMail(){
        let body: String = """
            <div>This a reply<br></div><div><br></div><div class="protonmail_signature_block"><div class="protonmail_signature_block-user protonmail_signature_block-empty"></div><div class="protonmail_signature_block-proton">Sent with <a href="https://protonmail.com/" target="_blank">ProtonMail</a> Secure Email.</div></div><div><br></div><div class="protonmail_quote">
            ‐‐‐‐‐‐‐ Original Message ‐‐‐‐‐‐‐<br>
            On Wednesday, April 28th, 2021 at 6:33 PM, marin.test &lt;marin.test@protonmail.com&gt; wrote:<br>
            <blockquote class="protonmail_quote" type="cite">
                <div>Some random word: salon<br></div><div><br></div><div class="protonmail_signature_block"><div class="protonmail_signature_block-user protonmail_signature_block-empty"></div><div class="protonmail_signature_block-proton">Sent with <a target="_blank" href="https://protonmail.com/" rel="noreferrer nofollow noopener">ProtonMail</a> Secure Email.</div></div><div><br></div>
            </blockquote><br>
        </div>
        """.preg_replace("\\s+", replaceto: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        let bodyCleanedExpected: String = """
            This a reply
            
            Sent with ProtonMail Secure Email.
        """.preg_replace("\\s+", replaceto: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        let sut = EncryptedSearchService.shared.extractKeywordsFromBody
        let result = sut(body, true)
        
        XCTAssertEqual(result, bodyCleanedExpected)
    }*/
    
    /*func testExtractKeyWordsFromBodyLeaveBlockQuotesProtonMail(){
        let body: String = """
            <div>This a reply<br></div><div><br></div><div class="protonmail_signature_block"><div class="protonmail_signature_block-user protonmail_signature_block-empty"></div><div class="protonmail_signature_block-proton">Sent with <a href="https://protonmail.com/" target="_blank">ProtonMail</a> Secure Email.</div></div><div><br></div><div class="protonmail_quote">
            ‐‐‐‐‐‐‐ Original Message ‐‐‐‐‐‐‐<br>
            On Wednesday, April 28th, 2021 at 6:33 PM, marin.test &lt;marin.test@protonmail.com&gt; wrote:<br>
            <blockquote class="protonmail_quote" type="cite">
                <div>Some random word: salon<br></div><div><br></div><div class="protonmail_signature_block"><div class="protonmail_signature_block-user protonmail_signature_block-empty"></div><div class="protonmail_signature_block-proton">Sent with <a target="_blank" href="https://protonmail.com/" rel="noreferrer nofollow noopener">ProtonMail</a> Secure Email.</div></div><div><br></div>
            </blockquote><br>
        </div>
        """.preg_replace("\\s+", replaceto: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        let bodyCleanedExpected: String = """
            This a reply

            Sent with ProtonMail Secure Email.
            ‐‐‐‐‐‐‐ Original Message ‐‐‐‐‐‐‐
            On Wednesday, April 28th, 2021 at 6:33 PM, marin.test <marin.test@protonmail.com> wrote:
            Some random word: salon
            
            Sent with ProtonMail Secure Email.
        """.preg_replace("\\s+", replaceto: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        let sut = EncryptedSearchService.shared.extractKeywordsFromBody
        let result = sut(body, false)
        
        XCTAssertEqual(result, bodyCleanedExpected)
    }*/
    
    /*func testExtractKeyWordsFromBodyRemoveBlockQuotesGMail(){
        let body: String = """
        <div dir="ltr">This is a reply<br></div><br><div class="gmail_quote"><div dir="ltr" class="gmail_attr">On Wed, Apr 28, 2021 at 6:38 PM marin.test &lt;<a href="mailto:marin.test@protonmail.com">marin.test@protonmail.com</a>&gt; wrote:<br></div><blockquote class="gmail_quote" style="margin:0px 0px 0px 0.8ex;border-left:1px solid rgb(204,204,204);padding-left:1ex"><div>Some random word: peasant<br></div><div><br></div><div><div></div><div>Sent with <a href="https://protonmail.com/" target="_blank">ProtonMail</a> Secure Email.</div></div></blockquote></div>
        """.preg_replace("\\s+", replaceto: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        let bodyCleanedExpected: String = "This is a reply".preg_replace("\\s+", replaceto: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        let sut = EncryptedSearchService.shared.extractKeywordsFromBody
        let result = sut(body, true)
        
        XCTAssertEqual(result, bodyCleanedExpected)
    }*/
    
    /*func testExtractKeyWordsFromBodyLeaveBlockQuotesGMail(){
        let body: String = """
        <div dir="ltr">This is a reply<br></div><br><div class="gmail_quote"><div dir="ltr" class="gmail_attr">On Wed, Apr 28, 2021 at 6:38 PM marin.test &lt;<a href="mailto:marin.test@protonmail.com">marin.test@protonmail.com</a>&gt; wrote:<br></div><blockquote class="gmail_quote" style="margin:0px 0px 0px 0.8ex;border-left:1px solid rgb(204,204,204);padding-left:1ex"><div>Some random word: peasant<br></div><div><br></div><div><div></div><div>Sent with <a href="https://protonmail.com/" target="_blank">ProtonMail</a> Secure Email.</div></div></blockquote></div>
        """.preg_replace("\\s+", replaceto: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        let bodyCleanedExpected: String = """
            This is a reply
            
            On Wed, Apr 28, 2021 at 6:38 PM marin.test <marin.test@protonmail.com> wrote:
            
            Some random word: peasant
            
            Sent with ProtonMail Secure Email.
        """.preg_replace("\\s+", replaceto: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        let sut = EncryptedSearchService.shared.extractKeywordsFromBody
        let result = sut(body, false)
        
        XCTAssertEqual(result, bodyCleanedExpected)
    }*/

}
