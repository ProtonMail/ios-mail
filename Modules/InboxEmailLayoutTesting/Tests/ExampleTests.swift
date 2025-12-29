import Testing

@testable import InboxEmailLayoutTesting

struct ExampleTests {
    @Test
    func processedHTMLReturnsValidHTML() {
        let rawHTML = """
            <!DOCTYPE html>
            <html>
                <head>
                    <title>Example</title>
                </head>
                <body>
                    <p>This is an example of a simple HTML page with one paragraph.</p>
                </body>
            </html>
            """

        #expect(processedHTML(rawHTML: rawHTML) == rawHTML)
    }
}
