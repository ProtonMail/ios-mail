//
//  StringExtension.swift
//  ProtonMail
//
//  Created by Diego Santiviago on 2/23/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

extension String {
    
    func alertController() -> UIAlertController {
        let message = self
        return UIAlertController(title: "Alert", message: message, preferredStyle: .Alert)
    }
    
    func alertToast() -> Void {
        let window : UIWindow = UIApplication.sharedApplication().windows.last as UIWindow!
        let hud : MBProgressHUD = MBProgressHUD.showHUDAddedTo(window, animated: true)
        hud.mode = MBProgressHUDMode.Text
        hud.labelText = NSLocalizedString("Alert");
        hud.detailsLabelText = self
        hud.removeFromSuperViewOnHide = true
        hud.hide(true, afterDelay: 3)
    }
    
    func contains(s: String) -> Bool
    {
        return self.rangeOfString(s, options: NSStringCompareOptions.CaseInsensitiveSearch) != nil ? true : false
    }
    
    func isMatch(regex: String, options: NSRegularExpressionOptions) -> Bool
    {
        do {
            let exp = try NSRegularExpression(pattern: regex, options: options)
            let matchCount = exp.numberOfMatchesInString(self, options: NSMatchingOptions.ReportProgress, range: NSMakeRange(0, self.characters.count))
            return matchCount > 0
        } catch {
            PMLog.D("\(error)")
        }
        return false;
    }
    
    
    func hasRe () -> Bool {
        if self.characters.count < 3 {
            return false;
        }
        let myNSString = self as NSString
        let str = myNSString.substringWithRange(NSRange(location: 0, length: 3))
        return str.contains("Re:")
    }
    
    func hasFwd () -> Bool {
        if self.characters.count < 4 {
            return false;
        }
        let myNSString = self as NSString
        let str = myNSString.substringWithRange(NSRange(location: 0, length: 4))
        return str.contains("Fwd:")
    }
    
    
    /**
     String extension check is email valid use the basic regex
     
     :returns: true | false
     */
    func isValidEmail() -> Bool {
        //"[A-Z0-9a-z]+([._%+-]{1}[A-Z0-9a-z]+)*@[A-Z0-9a-z]+([.-]{1}[A-Z0-9a-z]+)*(\\.[A-Za-z]{2,4}){0,1}"       //"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        let emailRegEx = "^(?:(?:(?:(?: )*(?:(?:(?:\\t| )*\\r\\n)?(?:\\t| )+))+(?: )*)|(?: )+)?(?:(?:(?:[-A-Za-z0-9!#$%&’*+/=?^_'{|}~]+(?:\\.[-A-Za-z0-9!#$%&’*+/=?^_'{|}~]+)*)|(?:\"(?:(?:(?:(?: )*(?:(?:[!#-Z^-~]|\\[|\\])|(?:\\\\(?:\\t|[ -~]))))+(?: )*)|(?: )+)\"))(?:@)(?:(?:(?:[A-Za-z0-9](?:[-A-Za-z0-9]{0,61}[A-Za-z0-9])?)(?:\\.[A-Za-z0-9](?:[-A-Za-z0-9]{0,61}[A-Za-z0-9])?)*)|(?:\\[(?:(?:(?:(?:(?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))\\.){3}(?:[0-9]|(?:[1-9][0-9])|(?:1[0-9][0-9])|(?:2[0-4][0-9])|(?:25[0-5]))))|(?:(?:(?: )*[!-Z^-~])*(?: )*)|(?:[Vv][0-9A-Fa-f]+\\.[-A-Za-z0-9._~!$&'()*+,;=:]+))\\])))(?:(?:(?:(?: )*(?:(?:(?:\\t| )*\\r\\n)?(?:\\t| )+))+(?: )*)|(?: )+)?$"
        if let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx) as NSPredicate? {
            return emailTest.evaluateWithObject(self)
        }
        return false
    }
    
    /**
     String extension for remove the whitespaces begain&end
     
     Example:
     " adsf " => "ads"
     
     :returns: trimed string value
     */
    func trim() -> String {
        return self.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet())
    }
    
    
    /**
     String extension parse a json string to a list of dict
     
     :returns: [ [String:String] ]
     */
    func parseJson() -> [[String:String]]? {
        if self.isEmpty {
            return [];
        }

        do {
            if let data = self.dataUsingEncoding(NSUTF8StringEncoding) {
                let decoded = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! [[String:String]]
                return decoded
            }
        } catch let ex as NSError {
            PMLog.D(" func parseJson() -> error error \(ex)")
        }
        return nil
    }
    
    
    /**
     get display address for message details
     
     :returns: parsed address
     */
    func getDisplayAddress() -> String {
        var lists: [String] = []
        let recipients : [[String : String]] = self.parseJson()!
        for dict:[String : String] in recipients {
            let to = dict.getDisplayName()
            if !to.isEmpty  {
                lists.append(to)
            }
        }
        return lists.joinWithSeparator(",")
    }
    
    
    
    /**
     String extension split a string by comma
     
     Example:
     "a,b,c,d" => ["a","b","c","d"]
     
     :returns: [String]
     */
    func splitByComma() -> [String] {
        return self.componentsSeparatedByString(",")
    }
    
    func ln2br() -> String {
        return  self.stringByReplacingOccurrencesOfString("\n", withString: "<br />")
    }
    
    func rmln() -> String {
        return  self.stringByReplacingOccurrencesOfString("\n", withString: "")
    }
    
    func lr2lrln() -> String {
        return  self.stringByReplacingOccurrencesOfString("\r", withString: "\r\n")
    }
    
    /**
     String extension formating the Json format contact for forwarding email.
     
     :returns: String
     */
    func formatJsonContact() -> String {
        var lists: [String] = []
        
        let recipients : [[String : String]] = self.parseJson()!
        for dict:[String : String] in recipients {
            lists.append(dict.getName() + "&lt;\(dict.getAddress())&gt;")
        }
        return lists.joinWithSeparator(",")
    }
    
    /**
     String extension decode some encoded htme tags
     
     :returns: String
     */
    func decodeHtml() -> String {
        var result = self.stringByReplacingOccurrencesOfString("&amp;", withString: "&", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        result = result.stringByReplacingOccurrencesOfString("&quot;", withString: "\"", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        result = result.stringByReplacingOccurrencesOfString("&#039;", withString: "'", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        result = result.stringByReplacingOccurrencesOfString("&#39;", withString: "'", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        result = result.stringByReplacingOccurrencesOfString("&lt;", withString: "<", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        result = result.stringByReplacingOccurrencesOfString("&gt;", withString: ">", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        return result
    }
    
    func encodeHtml() -> String {
        var result = self.stringByReplacingOccurrencesOfString("&", withString: "&amp;", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        result = result.stringByReplacingOccurrencesOfString("\"", withString: "&quot;", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        result = result.stringByReplacingOccurrencesOfString("'", withString: "&#039;", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        result = result.stringByReplacingOccurrencesOfString("<", withString: "&lt;", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        result = result.stringByReplacingOccurrencesOfString(">", withString: "&gt;", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        return result
    }
    
    func plainText() -> String {
        return self;
    }
    
    
    func stringByStrippingStyleHTML() -> String {
        let options : NSRegularExpressionOptions = [.CaseInsensitive, .DotMatchesLineSeparators]
        do {
            let regex = try NSRegularExpression(pattern: "<style[^>]*?>.*?</style>", options:options)
            let replacedString = regex.stringByReplacingMatchesInString(self, options: NSMatchingOptions(rawValue: 0), range: NSRange(location: 0, length: self.characters.count), withTemplate: "")
            if !replacedString.isEmpty && replacedString.characters.count > 0 {
                return replacedString;
            }
        } catch let ex as NSError {
            PMLog.D("\(ex)")
        }
        return self
    }
    
    func preg_replace_none_regex (partten: String, replaceto:String) -> String {
        return self.stringByReplacingOccurrencesOfString(partten, withString: replaceto, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
    }
    
    func preg_replace (partten: String, replaceto:String) -> String {
        let options : NSRegularExpressionOptions = [.CaseInsensitive, .DotMatchesLineSeparators]
        do {
            let regex = try NSRegularExpression(pattern: partten, options:options)
            let replacedString = regex.stringByReplacingMatchesInString(self, options: NSMatchingOptions(rawValue: 0), range: NSRange(location: 0, length: self.characters.count), withTemplate: replaceto)
            if !replacedString.isEmpty && replacedString.characters.count > 0 {
                return replacedString;
            }
        } catch let ex as NSError {
            PMLog.D("\(ex)")
        }
        return self
    }
    
    func preg_match (partten: String) -> Bool {
        let options : NSRegularExpressionOptions = [.CaseInsensitive, .DotMatchesLineSeparators]
        do {
            let regex = try NSRegularExpression(pattern: partten, options:options)
            return regex.firstMatchInString(self, options: NSMatchingOptions(rawValue: 0), range: NSRange(location: 0, length: self.characters.count)) != nil
            
        } catch let ex as NSError {
            PMLog.D("\(ex)")
        }
        
        return false
    }
    
    func hasImage () -> Bool {
        if self.preg_match("\\ssrc='(?!cid:)") {
            return true
        }
        if self.preg_match("\\ssrc=\"(?!cid:)") {
            return true
        }
        if self.preg_match("xlink:href=") {
            return true
        }
        if self.preg_match("poster=") {
            return true
        }
        if self.preg_match("background=") {
            return true
        }
        if self.preg_match("url\\(") {
            return true
        }
        return false
    }
    
    func stringByPurifyImages () -> String {
        //src=\"(?!cid:)(.*?)(^|>|\"|\\s)
       //let out = self.preg_replace("src=\"(.*?)(^|>|\"|\\s)|srcset=\"(.*?)(^|>|\"|\\s)|src='(.*?)(^|>|'|\\s)|xlink:href=\"(.*?)(^|>|\"|\\s)|poster=\"(.*?)(^|>|\"|\\s)|background=\"(.*?)(^|>|\"|\\s)|url\\((.*?)(^|>|\\)|\\s)", replaceto: " ")
        
        var out = self.preg_replace("\\ssrc='(?!cid:)", replaceto: " data-src='")
        out = out.preg_replace("\\ssrc=\"(?!cid:)", replaceto: " data-src=\"")
        out = out.preg_replace("srcset=", replaceto: " data-srcset=")
        out = out.preg_replace("xlink:href=", replaceto: " data-xlink:href=");
        out = out.preg_replace("poster=", replaceto: " data-poster=")
        out = out.preg_replace("background=", replaceto: " data-background=")
        out = out.preg_replace("url\\(", replaceto: " data-url(")
        
        return out
    }
    
    func stringFixImages () -> String {
        var out = self.preg_replace(" data-src='", replaceto: " src='")
        out = out.preg_replace(" data-src=\"", replaceto: " src=\"")
        out = out.preg_replace(" data-srcset=", replaceto: " srcset=")
        out = out.preg_replace(" data-xlink:href=", replaceto: " xlink:href=");
        out = out.preg_replace(" data-poster=", replaceto: " poster=")
        out = out.preg_replace(" data-background=", replaceto: " background=")
        out = out.preg_replace(" data-url(", replaceto: " url(")
        
        return out
    }
    
    func stringBySetupInlineImage(from : String, to: String) -> String {
        return self.preg_replace_none_regex(from, replaceto:to);
    }
    
    func stringByPurifyHTML() -> String {
        //|<(\\/?link.*?)>   <[^>]*?alert.*?>|  //the comment out part case hpylink have those key works been filtered out
        let out = self.preg_replace("<style[^>]*?>.*?</style>|<script(.*?)<\\/script>|<(\\/?script.*?)>|<(\\/?meta.*?)>|<object(.*?)<\\/object>|<(\\/?object.*?)>|<input(.*?)<\\/input>|<(\\/?input.*?)>|<iframe(.*?)<\\/iframe>|<video(.*?)<\\/video>|<audio(.*?)<\\/audio>|<[^>]*?onload.*?>|<input(.*?)<\\/input>|<[^>]*?prompt.*?>|<[^>]*?confirm.*?>", replaceto: " ")
        
//        var out = self.preg_replace("<script(.*?)<\\/script>", replaceto: "")
//        //out = out.preg_replace("<(script.*?)>(.*?)<(\\/script.*?)>", replaceto: "")
//        out = out.preg_replace("<(\\/?script.*?)>", replaceto: "")
//        
//        out = out.preg_replace("<(\\/?meta.*?)>", replaceto: "");
//        out = out.preg_replace("<object(.*?)<\\/object>", replaceto: "")
//        out = out.preg_replace("<(\\/?object.*?)>", replaceto: "")
//        //out = out.preg_replace("<(object.*?)>(.*?)<(\\/object.*?)>", replaceto: "");
//        //out = out.preg_replace("<(\\/?objec.*?)>", replaceto: "");
//        out = out.preg_replace("<input(.*?)<\\/input>", replaceto: "")
//        out = out.preg_replace("<(\\/?input.*?)>", replaceto: "");
//        
//        //remove inline style optinal later
//        //out = out.preg_replace("(<[a-z ]*)(style=(\"|\')(.*?)(\"|\'))([a-z ]*>)", replaceto: "");
//        out = out.preg_replace("<(\\/?link.*?)>", replaceto: "");
//        
//        out = out.preg_replace("<iframe(.*?)<\\/iframe>", replaceto: "");
//        //out = out.preg_replace("<style(.*?)<\\/style>", replaceto: "");
//        //out = out.preg_replace("\\s+", replaceto:" ")
//        //out = out.preg_replace("<[ ]+", replaceto:"<")
//        //out = out.preg_replace("<(style.*?)>(.*?)<(\\/style.*?)>", replaceto: "");
//        //out = out.preg_replace("<(\\/?style.*?)>", replaceto: "");
//        //        out = out.preg_replace("javascript", replaceto: "Javascript")
//        //        out = out.preg_replace("vbscript", replaceto: "Vbscript")
//        //        out = out.preg_replace("&#", replaceto: "&＃")
//        //        out = out.preg_replace("<(noframes.*?)>(.*?)<(\\/noframes.*?)>", replaceto: "")
//        //        out = out.preg_replace("<(\\/?noframes.*?)>", replaceto: "")
//        //        out = out.preg_replace("<(i?frame.*?)>(.*?)<(\\/i?frame.*?)>", replaceto: "")
//        //        out = out.preg_replace("<(\\/?i?frame.*?)>", replaceto: "")
//        
//        //optional later
//        out = out.preg_replace("<video(.*?)<\\/video>", replaceto: "")
//        out = out.preg_replace("<audio(.*?)<\\/audio>", replaceto: "")
        
        
        return out;
        //        function htmltotxt($str){
        //            $str = preg_replace( "@<script(.*?)</script>@is", "", $str );  //过滤js
        //            $str = preg_replace( "@<iframe(.*?)</iframe>@is", "", $str ); //过滤frame
        //            $str = preg_replace( "@<style(.*?)</style>@is", "", $str ); //过滤css
        //            $str = preg_replace( "@<(.*?)>@is", "", $str ); //过滤标签
        //            $str=preg_replace("/\s+/", " ", $str); //过滤多余回车
        //            $str=preg_replace("/<[ ]+/si","<",$str); //过滤<__("<"号后面带空格)
        //            $str=preg_replace("/<\!–.*?–>/si","",$str); //注释
        //            $str=preg_replace("/<(\!.*?)>/si","",$str); //过滤DOCTYPE
        //            $str=preg_replace("/<(\/?html.*?)>/si","",$str); //过滤html标签
        //            $str=preg_replace("/<(\/?head.*?)>/si","",$str); //过滤head标签
        //            $str=preg_replace("/<(\/?meta.*?)>/si","",$str); //过滤meta标签
        //            $str=preg_replace("/<(\/?body.*?)>/si","",$str); //过滤body标签
        //            $str=preg_replace("/<(\/?link.*?)>/si","",$str); //过滤link标签
        //            $str=preg_replace("/<(\/?form.*?)>/si","",$str); //过滤form标签
        //            $str=preg_replace("/cookie/si","COOKIE",$str); //过滤COOKIE标签
        //            $str=preg_replace("/<(applet.*?)>(.*?)<(\/applet.*?)>/si","",$str); //过滤applet标签
        //            $str=preg_replace("/<(\/?applet.*?)>/si","",$str); //过滤applet标签
        //            $str=preg_replace("/<(style.*?)>(.*?)<(\/style.*?)>/si","",$str); //过滤style标签
        //            $str=preg_replace("/<(\/?style.*?)>/si","",$str); //过滤style标签
        //            $str=preg_replace("/<(title.*?)>(.*?)<(\/title.*?)>/si","",$str); //过滤title标签
        //            $str=preg_replace("/<(\/?title.*?)>/si","",$str); //过滤title标签
        //            $str=preg_replace("/<(object.*?)>(.*?)<(\/object.*?)>/si","",$str); //过滤object标签
        //            $str=preg_replace("/<(\/?objec.*?)>/si","",$str); //过滤object标签
        //            $str=preg_replace("/<(noframes.*?)>(.*?)<(\/noframes.*?)>/si","",$str); //过滤noframes标签
        //            $str=preg_replace("/<(\/?noframes.*?)>/si","",$str); //过滤noframes标签
        //            $str=preg_replace("/<(i?frame.*?)>(.*?)<(\/i?frame.*?)>/si","",$str); //过滤frame标签
        //            $str=preg_replace("/<(\/?i?frame.*?)>/si","",$str); //过滤frame标签
        //            $str=preg_replace("/<(script.*?)>(.*?)<(\/script.*?)>/si","",$str); //过滤script标签
        //            $str=preg_replace("/<(\/?script.*?)>/si","",$str); //过滤script标签
        //            $str=preg_replace("/javascript/si","Javascript",$str); //过滤script标签
        //            $str=preg_replace("/vbscript/si","Vbscript",$str); //过滤script标签
        //            $str=preg_replace("/on([a-z]+)\s*=/si","On\\1=",$str); //过滤script标签
        //            $str=preg_replace("/&#/si","&＃",$str); //过滤script标签，如javAsCript:alert(
        //            return $str;
        //        }
    }
    
    func stringByStrippingBodyStyle() -> String {
        let options : NSRegularExpressionOptions = [.CaseInsensitive, .DotMatchesLineSeparators]
        do {
            let regexBody = try NSRegularExpression(pattern: "<body[^>]*>", options:options)
            let matches = regexBody.matchesInString(self, options: NSMatchingOptions(rawValue: 0), range: NSRange(location: 0, length: self.characters.count))
            if let first = matches.first {
                if first.numberOfRanges > 0 {
                    let range = first.rangeAtIndex(0)
                    if let nRange = self.rangeFromNSRange(range) {
                        var bodyTag = self.substringWithRange(nRange)
                        if !bodyTag.isEmpty && bodyTag.characters.count > 0  {
                            let regexStyle = try NSRegularExpression(pattern: "style=\"[^\"]*\"", options:options)
                            bodyTag = regexStyle.stringByReplacingMatchesInString(bodyTag, options: NSMatchingOptions(rawValue: 0), range: NSRange(location: 0, length: bodyTag.characters.count), withTemplate: "")
                            if !bodyTag.isEmpty && bodyTag.characters.count > 0  {
                                let newBody = self.stringByReplacingCharactersInRange(nRange, withString: bodyTag);
                                if !newBody.isEmpty && newBody.characters.count > 0  {
                                    return newBody
                                }
                            }
                        }
                    }
                }
            }
        } catch let ex as NSError {
            PMLog.D("\(ex)")
        }
        return self
    }
    
    static func randomString(len:Int) -> String {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomString : NSMutableString = NSMutableString(capacity: len)
        let length = UInt32 (letters.length)
        for _ in 0 ..< len {
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
        }
        return randomString as String
    }
    
    func rangeFromNSRange(nsRange : NSRange) -> Range<String.Index>? {
        let from16 = utf16.startIndex.advancedBy(nsRange.location, limit: utf16.endIndex)
        let to16 = from16.advancedBy(nsRange.length, limit: utf16.endIndex)
        if let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self) {
            return from ..< to
        }
        return nil
    }
    
    func NSRangeFromRange(range : Range<String.Index>) -> NSRange {
        let utf16view = self.utf16
        let from = String.UTF16View.Index(range.startIndex, within: utf16view)
        let to = String.UTF16View.Index(range.endIndex, within: utf16view)
        return NSMakeRange(utf16view.startIndex.distanceTo(from), from.distanceTo(to))
    }
    
    func RangeFromNSRange(range: Range<Int>) -> Range<String.Index> {
        let startIndex = self.startIndex.advancedBy(range.startIndex)
        let endIndex = startIndex.advancedBy(range.endIndex - range.startIndex)
        return startIndex ..< endIndex
    }
    
    func encodeBase64() -> String {
        let utf8str = self.dataUsingEncoding(NSUTF8StringEncoding)
        let base64Encoded = utf8str!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        return base64Encoded
    }
    
    func decodeBase64() -> String {
        let decodedData = NSData(base64EncodedString: self, options: NSDataBase64DecodingOptions(rawValue: 0))
        let decodedString = NSString(data: decodedData!, encoding: NSUTF8StringEncoding)
        PMLog.D(decodedString!) // foo
        
        return decodedString! as String
    }
    
    func decodeBase64() -> NSData {
        let decodedData = NSData(base64EncodedString: self, options: NSDataBase64DecodingOptions(rawValue: 0))
        return decodedData!
    }
    
    //
    func toContacts() -> [ContactVO] {
        var out : [ContactVO] = [ContactVO]();
        let recipients : [[String : String]] = self.parseJson()!
        for dict:[String : String] in recipients {
            out.append(ContactVO(id: "", name: dict["Name"], email: dict["Address"]))
        }
        return out
    }
    
    func toContact() -> ContactVO? {
        var out : ContactVO? = nil
        let recipients : [String : String] = self.parseObject()
        
        let name = recipients["Name"] ?? ""
        let address = recipients["Address"] ?? ""
        
        if !address.isEmpty {
            out = ContactVO(id: "", name: name, email: address)
        }
        return out
    }
    
    func parseObject () -> [String:String] {
        if self.isEmpty {
            return ["" : ""];
        }
        do {
            let data : NSData! = self.dataUsingEncoding(NSUTF8StringEncoding)
            let decoded = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as? [String:String] ?? ["" : ""]
            return decoded
        } catch let ex as NSError {
            PMLog.D("\(ex)")
        }
        return ["":""]
    }
    
    func stringByAppendingPathComponent(pathComponent: String) -> String {
        return (self as NSString).stringByAppendingPathComponent(pathComponent)
    }
    
}


extension String {
    
    subscript (i: Int) -> Character {
        return self[self.startIndex.advancedBy(i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        return substringWithRange(startIndex.advancedBy(r.endIndex) ..< startIndex.advancedBy(r.endIndex))
    }
}
