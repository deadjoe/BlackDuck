import SwiftUI
import WebKit

struct HTMLContentView: NSViewRepresentable {
    let htmlContent: String
    var baseURL: URL?

    func makeNSView(context: Context) -> WKWebView {
        // Create a configuration for the WebView
        let configuration = WKWebViewConfiguration()

        // Set up webpage preferences
        let webpagePreferences = WKWebpagePreferences()
        webpagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = webpagePreferences

        // Set up preferences (using modern API)
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.preferences = preferences

        // Create the WebView with the configuration
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator

        // Configure the web view appearance
        webView.setValue(false, forKey: "drawsBackground")

        // Disable process suspension to prevent the errors
        if #available(macOS 12.0, *) {
            webView.isInspectable = true
        }

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // Create a properly formatted HTML document
        let formattedHTML = formatHTML(htmlContent)

        // Check if the content has changed to avoid unnecessary reloads
        if context.coordinator.lastLoadedContent != formattedHTML {
            // Load the HTML content
            webView.loadHTMLString(formattedHTML, baseURL: baseURL)
            context.coordinator.lastLoadedContent = formattedHTML
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func formatHTML(_ html: String) -> String {
        // Create a complete HTML document with styling
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <meta http-equiv="Content-Security-Policy" content="default-src 'self'; img-src * data:; style-src 'self' 'unsafe-inline'; script-src 'none';">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                    line-height: 1.6;
                    color: #333;
                    padding: 0;
                    margin: 0;
                    font-size: 15px;
                }

                @media (prefers-color-scheme: dark) {
                    body {
                        color: #eee;
                        background-color: transparent;
                    }
                    a {
                        color: #4af;
                    }
                    img {
                        opacity: 0.8;
                    }
                }

                a {
                    color: #0066cc;
                    text-decoration: none;
                }

                a:hover {
                    text-decoration: underline;
                }

                img {
                    max-width: 100%;
                    height: auto;
                    border-radius: 4px;
                    display: block;
                    margin: 1em auto;
                }

                pre, code {
                    background-color: #f5f5f5;
                    border-radius: 3px;
                    padding: 2px 4px;
                    font-family: monospace;
                    overflow-x: auto;
                }

                @media (prefers-color-scheme: dark) {
                    pre, code {
                        background-color: #333;
                    }
                }

                blockquote {
                    border-left: 4px solid #ddd;
                    padding-left: 16px;
                    margin-left: 0;
                    color: #666;
                }

                @media (prefers-color-scheme: dark) {
                    blockquote {
                        border-left-color: #555;
                        color: #bbb;
                    }
                }

                table {
                    border-collapse: collapse;
                    width: 100%;
                    margin: 1em 0;
                }

                th, td {
                    border: 1px solid #ddd;
                    padding: 8px;
                    text-align: left;
                }

                @media (prefers-color-scheme: dark) {
                    th, td {
                        border-color: #555;
                    }
                }

                th {
                    background-color: #f5f5f5;
                }

                @media (prefers-color-scheme: dark) {
                    th {
                        background-color: #333;
                    }
                }

                /* Fix for common RSS feed issues */
                iframe, video {
                    max-width: 100%;
                    height: auto;
                }
            </style>
        </head>
        <body>
            \(html)
        </body>
        </html>
        """
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: HTMLContentView
        var lastLoadedContent: String = ""

        init(_ parent: HTMLContentView) {
            self.parent = parent
            super.init()
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // If it's a link click, open in the default browser
            if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Handle successful navigation if needed
            print("WebView successfully loaded content")
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            // Handle navigation failure
            print("WebView navigation failed: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            // Handle provisional navigation failure
            // Ignore error code -999 which is a common cancellation error
            if (error as NSError).code != -999 {
                print("WebView provisional navigation failed: \(error.localizedDescription)")
            }
        }
    }
}
