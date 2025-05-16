import SwiftUI
import WebKit

struct DetailView: View {
    let item: FeedItem
    @State private var isShowingOriginalContent = false
    @EnvironmentObject var feedManager: FeedManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(item.title)
                        .font(.title)
                        .fontWeight(.bold)

                    Spacer()

                    Button {
                        toggleStarred()
                    } label: {
                        Image(systemName: item.isStarred ? "star.fill" : "star")
                            .foregroundColor(item.isStarred ? .yellow : .gray)
                    }
                    .buttonStyle(.plain)
                }

                HStack {
                    if let feedTitle = item.feedTitle {
                        Text(feedTitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(item.formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if let author = item.author, !author.isEmpty {
                    Text("By \(author)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Divider()
            }
            .padding()

            // Content
            if isShowingOriginalContent {
                WebViewContainer(url: item.url)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let imageURL = item.imageURL {
                            AsyncImage(url: imageURL) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(height: 200)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: 300)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                case .failure:
                                    Color.gray.opacity(0.3)
                                        .frame(height: 200)
                                        .overlay(
                                            Image(systemName: "photo")
                                                .foregroundColor(.gray)
                                        )
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }

                        // Use HTMLContentView to render HTML content
                        HTMLContentView(htmlContent: item.content, baseURL: item.url)
                            .frame(minHeight: 300)
                    }
                    .padding()
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Button {
                    isShowingOriginalContent.toggle()
                } label: {
                    Label(
                        isShowingOriginalContent ? "Show Parsed Content" : "Show Original",
                        systemImage: isShowingOriginalContent ? "doc.text" : "globe"
                    )
                }
            }

            ToolbarItem {
                Button {
                    if let url = item.url {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Label("Open in Browser", systemImage: "safari")
                }
            }

            ToolbarItem {
                Button {
                    shareItem()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
        }
        .onAppear {
            markAsRead()
        }
    }

    private func markAsRead() {
        feedManager.markAsRead(item: item)
    }

    private func toggleStarred() {
        feedManager.toggleStarred(item: item)
    }

    private func shareItem() {
        guard let url = item.url else { return }

        let picker = NSSharingServicePicker(items: [url])

        if let window = NSApplication.shared.windows.first {
            picker.show(relativeTo: .zero, of: window.contentView!, preferredEdge: .minY)
        }
    }
}

struct WebViewContainer: NSViewRepresentable {
    let url: URL?

    func makeNSView(context: Context) -> WKWebView {
        // Create a configuration for the WebView
        let configuration = WKWebViewConfiguration()
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.preferences = preferences

        // Set up webpage preferences
        let webpagePreferences = WKWebpagePreferences()
        webpagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = webpagePreferences

        // Create the WebView with the configuration
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator

        // Disable process suspension to prevent the errors
        if #available(macOS 12.0, *) {
            webView.isInspectable = true
        }

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        if let url = url, context.coordinator.lastLoadedURL != url {
            let request = URLRequest(url: url)
            webView.load(request)
            context.coordinator.lastLoadedURL = url
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var lastLoadedURL: URL?

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Handle successful navigation if needed
            print("WebView successfully loaded URL")
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

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Allow all navigation actions within the WebView
            decisionHandler(.allow)
        }
    }
}
