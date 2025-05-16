import Foundation
import Combine
import OSLog

class FeedManager: ObservableObject {
    @Published var feeds: [Feed] = []
    @Published var isLoading = false
    @Published var lastError: String?

    private let logger = Logger(subsystem: "com.example.BlackDuck", category: "FeedManager")
    private let parser = WebContentParser()
    private var refreshTimer: Timer?
    private let userDefaults = UserDefaults.standard
    private let feedsKey = "savedFeeds"

    init() {
        loadSavedFeeds()
        setupRefreshTimer()

        // Load sample data if no feeds are available
        if feeds.isEmpty {
            feeds = Feed.samples
        }
    }

    var categories: [String] {
        let allCategories = feeds.compactMap { $0.category }
        return Array(Set(allCategories)).sorted()
    }

    func addFeed(url: URL) async throws {
        await MainActor.run {
            isLoading = true
            lastError = nil
        }

        do {
            let feed = try await parser.parseFeed(from: url)

            await MainActor.run {
                feeds.append(feed)
                saveFeedsToDisk()
                isLoading = false
            }
        } catch {
            await MainActor.run {
                logger.error("Failed to add feed: \(error.localizedDescription)")
                lastError = "Failed to add feed: \(error.localizedDescription)"
                isLoading = false
            }
            throw error
        }
    }

    func removeFeed(at offsets: IndexSet) {
        feeds.remove(atOffsets: offsets)
        saveFeedsToDisk()
    }

    func refreshFeed(_ feed: Feed) async {
        guard let index = feeds.firstIndex(where: { $0.id == feed.id }) else { return }

        do {
            let updatedFeed = try await parser.parseFeed(from: feed.url)

            await MainActor.run {
                // Preserve read/starred status for existing items
                let updatedItems = updatedFeed.items.map { newItem -> FeedItem in
                    if let existingItem = feeds[index].items.first(where: {
                        $0.url == newItem.url || $0.title == newItem.title
                    }) {
                        var updatedItem = newItem
                        updatedItem.isRead = existingItem.isRead
                        updatedItem.isStarred = existingItem.isStarred
                        return updatedItem
                    }
                    return newItem
                }

                var updatedFeedWithStatus = updatedFeed
                updatedFeedWithStatus.items = updatedItems
                updatedFeedWithStatus.id = feed.id
                updatedFeedWithStatus.category = feed.category

                feeds[index] = updatedFeedWithStatus
                saveFeedsToDisk()
            }
        } catch {
            logger.error("Failed to refresh feed \(feed.title): \(error.localizedDescription)")
        }
    }

    func refreshAllFeeds() async {
        await MainActor.run {
            isLoading = true
        }

        await withTaskGroup(of: Void.self) { group in
            for feed in feeds {
                group.addTask {
                    await self.refreshFeed(feed)
                }
            }
        }

        await MainActor.run {
            isLoading = false
        }
    }

    func markAsRead(item: FeedItem) {
        guard let feedIndex = feeds.firstIndex(where: { $0.id == item.feedID }),
              let itemIndex = feeds[feedIndex].items.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        feeds[feedIndex].items[itemIndex].isRead = true
        saveFeedsToDisk()
    }

    func markAsUnread(item: FeedItem) {
        guard let feedIndex = feeds.firstIndex(where: { $0.id == item.feedID }),
              let itemIndex = feeds[feedIndex].items.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        feeds[feedIndex].items[itemIndex].isRead = false
        saveFeedsToDisk()
    }

    func toggleStarred(item: FeedItem) -> FeedItem? {
        print("FeedManager - toggleStarred - item ID: \(item.id), title: \(item.title)")

        // 查找特定文章
        for (feedIndex, feed) in feeds.enumerated() {
            if feed.id == item.feedID {
                print("Found matching feed: \(feed.title)")

                if let itemIndex = feed.items.firstIndex(where: { $0.id == item.id }) {
                    print("Found matching item at index: \(itemIndex)")

                    // 切换特定文章的星标状态
                    let currentStarred = feeds[feedIndex].items[itemIndex].isStarred
                    feeds[feedIndex].items[itemIndex].isStarred.toggle()

                    print("Toggled star status from \(currentStarred) to \(!currentStarred)")

                    // 发送 objectWillChange 通知，通知 SwiftUI 更新视图
                    self.objectWillChange.send()

                    // 保存更改到磁盘
                    saveFeedsToDisk()

                    // 返回更新后的 FeedItem
                    return feeds[feedIndex].items[itemIndex]
                } else {
                    print("Item not found in feed: \(item.id)")
                }
            }
        }

        print("Feed not found for item: \(item.id)")
        return nil
    }

    func markAllAsRead(in feed: Feed) {
        guard let feedIndex = feeds.firstIndex(where: { $0.id == feed.id }) else {
            return
        }

        for i in 0..<feeds[feedIndex].items.count {
            feeds[feedIndex].items[i].isRead = true
        }

        saveFeedsToDisk()
    }

    private func setupRefreshTimer() {
        let refreshInterval = userDefaults.integer(forKey: "refreshInterval")
        let interval = TimeInterval(max(5, refreshInterval)) * 60

        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            Task {
                await self.refreshAllFeeds()
            }
        }
    }

    private func loadSavedFeeds() {
        if let data = userDefaults.data(forKey: feedsKey) {
            do {
                let decodedFeeds = try JSONDecoder().decode([Feed].self, from: data)
                feeds = decodedFeeds
            } catch {
                logger.error("Failed to decode saved feeds: \(error.localizedDescription)")
            }
        }
    }

    func saveFeedsToDisk() {
        do {
            let data = try JSONEncoder().encode(feeds)
            userDefaults.set(data, forKey: feedsKey)
        } catch {
            logger.error("Failed to save feeds: \(error.localizedDescription)")
        }
    }
}
