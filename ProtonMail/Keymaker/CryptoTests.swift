//
//  CryptoTests.swift
//  ProtonMail - Created on 10/12/2018.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
    

import XCTest

#if canImport(CryptoSwift)
    import CryptoSwift
#endif

#if canImport(Crypto)
    import Crypto
#endif


class CryptoTests: XCTestCase {
    public typealias Key = Array<UInt8>
    private func makeKey(_ length: Int = 32) -> Key {
        var key = Array<UInt8>(repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, key.count, &key)
        if status != 0 {
            XCTAssert(false, "failed to create cryptographically secure key")
        }
        return key
    }
    
#if canImport(CryptoSwift)
    func testCryptoSwiftEncrypt() {
        let key = self.makeKey(32)
        let clearValue = self.longMessage.data(using: .utf8)!
        
        self.measure() {
            do {
                // encrypt
                let aesLock = try AES(key: key, blockMode: ECB())
                let cypherBytes = try aesLock.encrypt(clearValue.bytes)
                XCTAssertNotEqual(clearValue, Data(cypherBytes))
                
                //decrypt
                let aesUnlock = try AES(key: key, blockMode: ECB())
                let clearBytes = try aesUnlock.decrypt(cypherBytes)
                let unlockedValue = Data(clearBytes)
                
                XCTAssertEqual(clearValue, unlockedValue)
            } catch let error {
                XCTFail(error.localizedDescription)
            }
        }
    }
    
    func testCryptoSwiftDerive() {
        let secret = "Z1ON0101"
        let salt = Data(self.makeKey(8)).bytes

        self.measure() {
            do {
                let derivedKey = try PKCS5.PBKDF2(password: Array(secret.utf8), salt: salt, iterations: 2000, variant: .sha256).calculate()
                XCTAssertFalse(derivedKey.isEmpty)
            } catch let error {
                XCTFail(error.localizedDescription)
            }
        }
    }
#endif

#if canImport(Crypto)
    func testCryptoEncrypt() {
        let key = Data(self.makeKey(32))
        let iv = Data(self.makeKey(16))
        let clearValue = self.longMessage.data(using: .utf8)!
        
        self.measure() {
            var error: NSError?
            
            // encrypt
            let cypherData = SubtleEncryptWithoutIntegrity(key, clearValue, iv, &error)
            XCTAssertNil(error, "Failed to encrypt the data: \(error!.localizedDescription)")
            XCTAssertNotEqual(clearValue, cypherData)
            
            //decrypt
            let unlockedValue = SubtleDecryptWithoutIntegrity(key, cypherData, iv, &error)
            XCTAssertNil(error, "Failed to decrypt the data: \(error!.localizedDescription)")
            XCTAssertEqual(clearValue, unlockedValue)
        }
    }
    
    func testCryptoDerive() {
        let secret = "Z1ON0101"
        let salt = Data(self.makeKey(8))
            
        self.measure() {
            var error: NSError?
            // 32768 is PinProtection.numberOfIterations
            let derivedKey = SubtleDeriveKey(secret, salt, 32768, &error)
            XCTAssertNil(error, "Failed to derive key: \(error!.localizedDescription)")
            XCTAssertNotNil(derivedKey)
        }
    }
#endif
    
    lazy var longMessage = """
    WELL, PRINCE, so Genoa and Lucca are now
    just family estates of the Buonapartes. But I
    warn you, if you don't tell me that this means
    war, if you still try to defend the infamies and
    horrors perpetrated by that Antichrist I real-
    ly believe he is Antichrist I will have nothing
    more to do with you and you are no longer my
    friend, no longer my 'faithful slave,' as you
    call yourself! But how do you do? I see I have
    frightened you sit down and tell me all the
    news."

    It was in July, 1805, and the speaker was the
    well-known Anna Pdvlovna Sch^rer, maid of
    honor and favorite of the Empress Marya Fe-
    dorovna. With these words she greeted Prince
    Vasili Kurdgin, a man of high rank and impor-
    tance, who was the first to arrive at her recep-
    tion. Anna Pdvlovna had had a cough for some
    days. She was, as she said, suffering from la
    grippe; grippe being then a new word in St.
    Petersburg, used only by the elite.

    All her invitations without exception, writ-
    ten in French, and delivered by a scarlet-liver-
    ied footman that morning, ran as follows:

    "If you have nothing better to do, Count [or
    Prince], and if the prospect of spending an
    evening with a poor invalid is not too terrible,
    I shall be very charmed to see you tonight be-
    tween 7 and 10 Annette Sch^rer."

    "Heavens! what a virulent attack!" replied
    the prince, not in the least disconcerted by this
    reception. He had just entered, wearing an em-
    broidered court uniform, knee breeches, and
    shoes, and had stars on his breast and a serene
    expression on his flat face. He spoke in that
    refined French in which our grandfathers not
    only spoke but thought, and with the gentle,
    patronizing intonation natural to a man of
    importance who had grown old in society and
    at court. He went up to Anna Pavlovna, kissed
    her hand, presenting to her his bald, scented,
    and shining head, and complacently seated
    himself on the sofa.

    "First of all, dear friend, tell me how you



    are. Set your friend's mind at rest," said he
    without altering his tone, beneath the polite-
    ness and affected sympathy of which indiffer-
    ence and even irony could be discerned.

    "Can one be well while suffering morally?
    Can one be calm in tirrfes like these if one has
    any feeling?" said Anna Pdvlovna. "You are
    staying the whole evening, I hope?"

    "And the fete at the English ambassador's?
    Today is Wednesday. I must put in an appear-
    ance there," said the prince. "My daughter is
    coming for me to take me there."

    "I thought today's fete had been canceled.
    I confess all these festivities and fireworks are
    becoming wearisome."

    "If they had known that you wished it, the
    entertainment would have been put off," said
    the prince, who, like a wound-up clock, by
    force of habit said things he did not even wish
    to be believed.

    "Don't tease! Well, and what has been de-
    cided about Novosiltsev's dispatch? You know
    everything."

    "What can one say about it?" replied the
    prince in a cold, listless tone. "What has been
    decided? They have decided that Buonaparte
    has burnt his boats, and I believe that we are
    ready to burn ours."

    Prince Vastti always spoke languidly, like
    an actor repeating a stale part. Anna Pdvlovna
    Scherer on the contrary, despite her forty years,
    overflowed with animation and impulsiveness.
    To be an enthusiast had become her social vo-
    cation and, sometimes even when she did not
    feel like it, she became enthusiastic in order
    not to disappoint the expectations of those
    who knew her. The subdued smile which,
    though it did not suit her faded features, al-
    ways played round her lips expressed, as in a
    spoiled child, a continual consciousness of her
    charming defect, which she neither wished, nor
    could, nor considered it necessary, to correct.

    In the midst of a conversation on political
    matters Anna Pdvlovna burst out:

    "Oh, don't speak to me of Austria. Perhaps



    WAR AND PEACE



    I don't understand things, but Austria never
    has wished, and does not wish, for war. She is
    betraying us! Russia alone must save Europe.
    Our gracious sovereign recognizes his high vo-
    cation and will be true to it. That is the one
    thing I have faith in! Our good and wonder-
    ful sovereign has to perfonn the noblest role
    on earth, and he is so virtuous and noble that
    God will not forsake him. He will fulfill his
    vocation and crush the hydra of revolution,
    which has become more terrible than ever in
    the person of this murderer and villain! We
    alone must avenge the blood of the just one.
    . . . Whom, I ask you, can we rely on? . . . Eng-
    land with her commercial spirit will not and
    cannot understand the Emperor Alexander's
    loftiness of soul. She tias refused to evacuate
    Malta. She wanted to find, and still seeks, some
    secret motive in our actions. What answer did
    Novosiltsev get? None. The English have not
    understood and cannot understand the self-
    abnegation of our Emperor who wants noth-
    ing for himself, but only desires the good of
    mankind. And what have they promised? Noth-
    ing! And what little they have promised they
    will not perform! Prussia has always declared
    that Buonaparte is invincible and that all
    Europe is powerless before him. . . . And I
    don't believe a word that Hardenburg says,
    or Haugwitz either. This famous Prussian neu-
    trality is just a trap. I have faith only in God
    and the lofty destiny of our adored monarch.
    He will save Europe!"

    She suddenly paused, smiling at her own
    impetuosity.

    "I think," said the prince with a smile, "that
    if you had been sent instead of our dear
    Wintzingerode you would have captured the
    King of Prussia's consent by assault. You are
    so eloquent. Will you give me a cup of tea?"

    "In a moment. X propos"she added, becom-
    ing calm again, "I am expecting two very in-
    teresting men tonight, le Vicomte de Morte-
    mart, who is connected with the Montmoren-
    cys through the Rohans,oneof the best French
    families. He is one of the genuine dmigrh, the
    good ones. And also the Abbe* Morio. Do you
    know that profound thinker? He has been re-
    ceived by the Emperor. Had you heard?"

    "I shall be delighted to meet them," said the
    prince. "But tell me," he added with studied
    carelessness as if it had only just occurred to
    him, though the question he was about to ask
    was the chief motive of his visit, "is it true that
    the Dowager Empress wants Baron Funke to be
    appointed first secretary at Vienna? The baron



    by all accounts is a poor creature."

    Prince Vasfli wished to obtain this post for
    his son, but others were trying through the
    Dowager Empress Mdrya Fedorovna to secure
    it for the baron.

    Anna Pdvlovna almost closed her eyes to in-
    dicate that neither she nor anyone else had a
    right to criticize what the Empress desired or
    was pleased with.

    "Baron Funke has been recommended to the
    Dowager Empress by her sister," was all she
    said, in a dry and mournful tone.

    As she named the Empress, Anna Pdvlovna's
    face suddenly assumed an expression of pro-
    found and sincere devotion and respect min-
    gled with sadness, and thisoccurred every time
    she mentioned her illustrious patroness. She
    added that Her Majesty had deigned to show
    Baron Funke beaucoup d'estime, and again
    her face clouded over with sadness.

    The prince was silent and looked indiffer-
    ent. But, with the womanly and courtierlike
    quickness and tact habitual to her, Anna Pdv-
    lovna wished both to rebuke him (for daring
    to speak as he had done of a man recommended
    to the Empress) and at the same time to con-
    sole him, so she said:

    "Now about your family. Do you know that
    since your daughter came out everyone has
    been enraptured by her? They say she is amaz-
    ingly beautiful."

    The prince bowed to signify his respect and
    gratitude.

    "I often think," she continued after a short
    pause, drawing nearer to the prince and smil-
    ing amiably at him as if to show that political
    and social topics were ended and the time had
    come for intimate conversation "I often think
    how unfairly sometimes the joys of life are dis-
    tributed. Why has fate given you two such
    splendid children? I don't speak of Anatole,
    your youngest. I don't like him," she added in
    a tone admitting of no rejoinder and raising
    her eyebrows. "Two such charming children.
    And really you appreciate them less than any-
    one, and so you don't deserve to have them."

    And she smiled her ecstatic smile.

    "I can't help it," said the prince. "Lavater
    would have said I lack the bump of paternity."

    "Don't joke; I mean to have a serious talk
    with you. Do you know I am dissatisfied with
    your younger son? Between ourselves" (and
    her face assumed its melancholy expression),
    "he was mentioned at Her Majesty's and you
    were pitied. . . ."
    """

}
