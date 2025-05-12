import SwiftUI
import WebKit

struct HTMLContentView: NSViewRepresentable {
    let htmlContent: String
    var baseURL: URL?
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        
        // Configure the web view
        webView.setValue(false, forKey: "drawsBackground")
        
        // Set up configuration
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        // Create a properly formatted HTML document
        let formattedHTML = formatHTML(htmlContent)
        
        // Load the HTML content
        webView.loadHTMLString(formattedHTML, baseURL: baseURL)
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
        
        init(_ parent: HTMLContentView) {
            self.parent = parent
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
    }
}
