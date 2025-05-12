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
                        
                        Text(item.content)
                            .lineSpacing(1.5)
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
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        if let url = url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Handle navigation completion if needed
        }
    }
}
