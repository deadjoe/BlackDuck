import SwiftUI

struct ContentView: View {
    @EnvironmentObject var feedManager: FeedManager
    @State private var selectedFeed: Feed?
    @State private var selectedItem: FeedItem?
    @State private var searchText = ""
    @State private var isAddingFeed = false
    @State private var newFeedURL = ""
    
    var body: some View {
        NavigationSplitView {
            SidebarView(selectedFeed: $selectedFeed)
                .environmentObject(feedManager)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            isAddingFeed = true
                        }) {
                            Label("Add Feed", systemImage: "plus")
                        }
                    }
                    
                    ToolbarItem {
                        Button(action: {
                            Task {
                                await feedManager.refreshAllFeeds()
                            }
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    }
                }
        } content: {
            if let feed = selectedFeed {
                List(filteredItems, selection: $selectedItem) { item in
                    FeedItemView(item: item)
                        .tag(item)
                }
                .searchable(text: $searchText, prompt: "Search in \(feed.title)")
                .navigationTitle(feed.title)
            } else {
                ContentUnavailableView("Select a Feed", systemImage: "list.bullet")
            }
        } detail: {
            if let item = selectedItem {
                DetailView(item: item)
            } else {
                ContentUnavailableView("Select an Item", systemImage: "doc.text")
            }
        }
        .sheet(isPresented: $isAddingFeed) {
            AddFeedView(isPresented: $isAddingFeed)
                .environmentObject(feedManager)
        }
    }
    
    private var filteredItems: [FeedItem] {
        guard let feed = selectedFeed else { return [] }
        
        if searchText.isEmpty {
            return feed.items
        } else {
            return feed.items.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

struct AddFeedView: View {
    @EnvironmentObject var feedManager: FeedManager
    @Binding var isPresented: Bool
    @State private var url = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add New Feed")
                .font(.headline)
            
            TextField("Feed URL", text: $url)
                .textFieldStyle(.roundedBorder)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                
                Button("Add") {
                    addFeed()
                }
                .buttonStyle(.borderedProminent)
                .disabled(url.isEmpty || isLoading)
            }
        }
        .padding()
        .frame(width: 400)
        .disabled(isLoading)
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
    }
    
    private func addFeed() {
        guard let url = URL(string: url) else {
            errorMessage = "Invalid URL"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await feedManager.addFeed(url: url)
                isLoading = false
                isPresented = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FeedManager())
}
