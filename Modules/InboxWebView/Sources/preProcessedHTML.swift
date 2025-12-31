import Foundation

/// Processes raw HTML by replacing https:// URLs with proton-https:// scheme
/// and extracting only filenames from full URLs.
public func preProcessedHTML(rawHTML: String) -> String {
    // FIXME: This function should use Rust implmentation - it's only temporary solution
    var modifiedHTML = rawHTML

    let httpsURLPattern = #"https://[^"'\s<>)]+"#
    let regex = try! NSRegularExpression(pattern: httpsURLPattern, options: [])
    let nsString = modifiedHTML as NSString
    let matches = regex.matches(in: modifiedHTML, options: [], range: NSRange(location: 0, length: nsString.length))

    for match in matches.reversed() {
        let urlRange = match.range(at: 0)
        if urlRange.location != NSNotFound {
            let url = nsString.substring(with: urlRange)
            let filename = extractFilename(from: url)
            let replacement = "proton-https://\(filename)"
            modifiedHTML = (modifiedHTML as NSString).replacingCharacters(in: urlRange, with: replacement)
        }
    }

    return modifiedHTML
}

private func extractFilename(from url: String) -> String {
    let urlWithoutQuery = url.split(separator: "?").first ?? Substring(url)
    let pathComponents = String(urlWithoutQuery).split(separator: "/")

    guard let filename = pathComponents.last, !filename.isEmpty else {
        fatalError("Could not extract filename from: \(url)")
    }

    return String(filename)
}
