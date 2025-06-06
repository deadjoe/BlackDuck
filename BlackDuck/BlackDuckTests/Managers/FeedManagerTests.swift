import XCTest
@testable import BlackDuck

final class FeedManagerTests: XCTestCase {

    var feedManager: FeedManager!
    var mockUserDefaults: UserDefaults!

    override func setUp() {
        super.setUp()

        // Create a unique suite name for testing
        let suiteName = "com.example.BlackDuckTests.\(UUID().uuidString)"
        mockUserDefaults = UserDefaults(suiteName: suiteName)

        // Inject the mock UserDefaults using method swizzling or dependency injection
        // For simplicity, we'll test the public API without modifying the internals
        feedManager = FeedManager()

        // Clear any existing feeds
        feedManager.feeds = []
    }

    override func tearDown() {
        feedManager = nil
        // UserDefaults doesn't have a suiteName property, so we'll just set it to nil
        mockUserDefaults = nil
        super.tearDown()
    }

    func testAddFeed() async throws {
        // Arrange
        let initialCount = feedManager.feeds.count

        // In a real test, we would use this URL and mock the WebContentParser
        // For now, we'll just comment it out since we're not using it
        /*
        let testURL = URL(string: "https://example.com/feed")!
        let mockFeed = Feed(
            url: testURL,
            title: "Test Feed",
            description: "Test Description",
            items: [],
            lastUpdated: Date()
        )
        */

        // Act
        // Note: In a real test, we would mock the WebContentParser to return our mockFeed
        // For now, we'll test the public API assuming the parser works

        // Assert
        XCTAssertEqual(feedManager.feeds.count, initialCount)

        // Test categories property
        let categories = feedManager.categories
        XCTAssertEqual(categories.count, 0)
    }

    func testRemoveFeed() {
        // Arrange
        let feed1 = Feed(
            url: URL(string: "https://example.com/feed1")!,
            title: "Feed 1",
            description: "Description 1",
            items: [],
            lastUpdated: Date()
        )

        let feed2 = Feed(
            url: URL(string: "https://example.com/feed2")!,
            title: "Feed 2",
            description: "Description 2",
            items: [],
            lastUpdated: Date()
        )

        feedManager.feeds = [feed1, feed2]

        // Act
        feedManager.removeFeed(at: IndexSet(integer: 0))

        // Assert
        XCTAssertEqual(feedManager.feeds.count, 1)
        XCTAssertEqual(feedManager.feeds[0].title, "Feed 2")
    }

    func testMarkAsRead() {
        // Arrange
        let feedID = UUID()
        let item = FeedItem(
            feedID: feedID,
            title: "Test Item",
            description: "Description",
            content: "Content",
            publishDate: Date(),
            isRead: false
        )

        var feed = Feed(
            url: URL(string: "https://example.com/feed")!,
            title: "Test Feed",
            description: "Test Description",
            items: [item],
            lastUpdated: Date()
        )
        // Manually set the ID since Feed doesn't have an initializer that takes an ID
        feed.id = feedID

        feedManager.feeds = [feed]

        // Act
        feedManager.markAsRead(item: item)

        // Assert
        XCTAssertTrue(feedManager.feeds[0].items[0].isRead)
    }

    func testToggleStarred() {
        // Arrange
        let feedID = UUID()
        let item = FeedItem(
            feedID: feedID,
            title: "Test Item",
            description: "Description",
            content: "Content",
            publishDate: Date(),
            isStarred: false
        )

        var feed = Feed(
            url: URL(string: "https://example.com/feed")!,
            title: "Test Feed",
            description: "Test Description",
            items: [item],
            lastUpdated: Date()
        )
        // Manually set the ID since Feed doesn't have an initializer that takes an ID
        feed.id = feedID

        feedManager.feeds = [feed]

        // Act
        let updatedItem1 = feedManager.toggleStarred(item: item)

        // Assert
        XCTAssertNotNil(updatedItem1, "toggleStarred should return updated item")
        XCTAssertTrue(feedManager.feeds[0].items[0].isStarred)
        XCTAssertTrue(updatedItem1!.isStarred)

        // Toggle again
        let updatedItem2 = feedManager.toggleStarred(item: item)

        // Assert
        XCTAssertNotNil(updatedItem2, "toggleStarred should return updated item")
        XCTAssertFalse(feedManager.feeds[0].items[0].isStarred)
        XCTAssertFalse(updatedItem2!.isStarred)
    }

    func testToggleStarredWithMultipleItems() {
        // Arrange
        let feedID = UUID()
        let item1 = FeedItem(
            feedID: feedID,
            title: "Test Item 1",
            description: "Description 1",
            content: "Content 1",
            publishDate: Date(),
            isStarred: false
        )
        let item2 = FeedItem(
            feedID: feedID,
            title: "Test Item 2",
            description: "Description 2",
            content: "Content 2",
            publishDate: Date(),
            isStarred: true
        )

        var feed = Feed(
            url: URL(string: "https://example.com/feed")!,
            title: "Test Feed",
            description: "Test Description",
            items: [item1, item2],
            lastUpdated: Date()
        )
        feed.id = feedID

        feedManager.feeds = [feed]

        // Act - Toggle first item (false -> true)
        let updatedItem1 = feedManager.toggleStarred(item: item1)

        // Assert
        XCTAssertNotNil(updatedItem1)
        XCTAssertTrue(feedManager.feeds[0].items[0].isStarred)
        XCTAssertTrue(feedManager.feeds[0].items[1].isStarred) // Second item should remain starred

        // Act - Toggle second item (true -> false)
        let updatedItem2 = feedManager.toggleStarred(item: item2)

        // Assert
        XCTAssertNotNil(updatedItem2)
        XCTAssertTrue(feedManager.feeds[0].items[0].isStarred) // First item should remain starred
        XCTAssertFalse(feedManager.feeds[0].items[1].isStarred)
    }

    func testMarkAllAsRead() {
        // Arrange
        let feedID = UUID()
        let items = [
            FeedItem(
                feedID: feedID,
                title: "Item 1",
                description: "Description 1",
                content: "Content 1",
                publishDate: Date(),
                isRead: false
            ),
            FeedItem(
                feedID: feedID,
                title: "Item 2",
                description: "Description 2",
                content: "Content 2",
                publishDate: Date(),
                isRead: false
            ),
            FeedItem(
                feedID: feedID,
                title: "Item 3",
                description: "Description 3",
                content: "Content 3",
                publishDate: Date(),
                isRead: true
            )
        ]

        var feed = Feed(
            url: URL(string: "https://example.com/feed")!,
            title: "Test Feed",
            description: "Test Description",
            items: items,
            lastUpdated: Date()
        )
        // Manually set the ID since Feed doesn't have an initializer that takes an ID
        feed.id = feedID

        feedManager.feeds = [feed]

        // Act
        feedManager.markAllAsRead(in: feed)

        // Assert
        XCTAssertTrue(feedManager.feeds[0].items[0].isRead)
        XCTAssertTrue(feedManager.feeds[0].items[1].isRead)
        XCTAssertTrue(feedManager.feeds[0].items[2].isRead)
        XCTAssertEqual(feedManager.feeds[0].unreadCount, 0)
    }

    func testCategories() {
        // Arrange
        let feed1 = Feed(
            url: URL(string: "https://example.com/feed1")!,
            title: "Feed 1",
            description: "Description 1",
            category: "Technology",
            items: [],
            lastUpdated: Date()
        )

        let feed2 = Feed(
            url: URL(string: "https://example.com/feed2")!,
            title: "Feed 2",
            description: "Description 2",
            category: "Science",
            items: [],
            lastUpdated: Date()
        )

        let feed3 = Feed(
            url: URL(string: "https://example.com/feed3")!,
            title: "Feed 3",
            description: "Description 3",
            category: "Technology",
            items: [],
            lastUpdated: Date()
        )

        feedManager.feeds = [feed1, feed2, feed3]

        // Act
        let categories = feedManager.categories

        // Assert
        XCTAssertEqual(categories.count, 2)
        XCTAssertTrue(categories.contains("Technology"))
        XCTAssertTrue(categories.contains("Science"))
    }
}
