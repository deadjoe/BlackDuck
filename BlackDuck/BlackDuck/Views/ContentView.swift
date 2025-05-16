import SwiftUI
import Foundation

enum SmartFeedType: String, Hashable, Identifiable, CaseIterable {
    case today
    case unread
    case starred

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today:
            return "Today"
        case .unread:
            return "Unread"
        case .starred:
            return "Starred"
        }
    }

    var systemImage: String {
        switch self {
        case .today:
            return "calendar"
        case .unread:
            return "circle"
        case .starred:
            return "star"
        }
    }

    func filter(_ item: FeedItem) -> Bool {
        switch self {
        case .today:
            return item.isToday
        case .unread:
            return !item.isRead
        case .starred:
            return item.isStarred
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var feedManager: FeedManager
    @State private var selectedFeed: Feed?
    @State private var selectedSmartFeed: SmartFeedType?
    @State private var selectedItem: FeedItem?
    @State private var searchText = ""
    @State private var isAddingFeed = false
    @State private var newFeedURL = ""

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedFeed: $selectedFeed, selectedSmartFeed: $selectedSmartFeed)
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
            NavigationStack {
                if let feed = selectedFeed {
                    // Regular feed view
                    List {
                        ForEach(filteredFeedItems(feed)) { item in
                            NavigationLink(destination: DetailView(item: item)) {
                                FeedItemView(item: item)
                            }
                            .tag(item)
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search in \(feed.title)")
                    .navigationTitle(feed.title)
                } else if let smartFeed = selectedSmartFeed {
                    // Smart feed view
                    List {
                        ForEach(filteredSmartFeedItems(smartFeed)) { item in
                            NavigationLink(destination: DetailView(item: item)) {
                                FeedItemView(item: item)
                            }
                            .tag(item)
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search in \(smartFeed.title)")
                    .navigationTitle(smartFeed.title)
                } else {
                    ContentUnavailableView("Select a Feed", systemImage: "list.bullet")
                }
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
        .onAppear {
            setupNotificationObservers()
        }
        .onDisappear {
            removeNotificationObservers()
        }
    }

    // Setup notification observers for feed item actions
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ToggleReadStatus"),
            object: nil,
            queue: .main
        ) { notification in
            if let item = notification.userInfo?["item"] as? FeedItem {
                toggleReadStatus(item: item)
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ToggleStarredStatus"),
            object: nil,
            queue: .main
        ) { notification in
            if let item = notification.userInfo?["item"] as? FeedItem {
                toggleStarredStatus(item: item)
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("RefreshSmartFeed"),
            object: nil,
            queue: .main
        ) { _ in
            // 如果当前选中的是 Starred 智能文件夹，则刷新视图
            if selectedSmartFeed == .starred {
                refreshSmartFeedView()
            }
        }
    }

    private func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("ToggleReadStatus"),
            object: nil
        )

        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("ToggleStarredStatus"),
            object: nil
        )

        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("RefreshSmartFeed"),
            object: nil
        )
    }

    private func toggleReadStatus(item: FeedItem) {
        if item.isRead {
            // If it's already read, mark as unread
            feedManager.markAsUnread(item: item)
        } else {
            // Mark as read
            feedManager.markAsRead(item: item)
        }
    }

    private func toggleStarredStatus(item: FeedItem) {
        // 更新 FeedManager 中的状态
        if feedManager.toggleStarred(item: item) != nil && selectedSmartFeed == .starred {
            // 如果当前选中的是 Starred 智能文件夹，则刷新视图
            refreshSmartFeedView()
        }
    }

    private func refreshSmartFeedView() {
        // 强制视图刷新
        let temp = selectedSmartFeed
        selectedSmartFeed = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.selectedSmartFeed = temp
        }
    }

    private func filteredFeedItems(_ feed: Feed) -> [FeedItem] {
        if searchText.isEmpty {
            return feed.items
        } else {
            return feed.items.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    private func filteredSmartFeedItems(_ smartFeed: SmartFeedType) -> [FeedItem] {
        // 从所有 feeds 中获取所有文章
        let allItems = feedManager.feeds.flatMap { feed in
            // 对于每个 feed，获取其中的所有文章，并应用 smartFeed 的过滤器
            return feed.items.filter { item in
                return smartFeed.filter(item)
            }
        }

        // 如果搜索文本为空，则返回所有过滤后的文章
        if searchText.isEmpty {
            return allItems
        } else {
            // 否则，进一步过滤出包含搜索文本的文章
            return allItems.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.description.localizedCaseInsensitiveContains(searchText) ||
                item.content.localizedCaseInsensitiveContains(searchText)
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
