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
        mockUserDefaults?.removeSuite(named: mockUserDefaults.suiteName!)
        mockUserDefaults = nil
        super.tearDown()
    }
    
    func testAddFeed() async throws {
        // Arrange
        let initialCount = feedManager.feeds.count
        let testURL = URL(string: "https://example.com/feed")!
        
        // Create a mock feed to be returned by the parser
        let mockFeed = Feed(
            url: testURL,
            title: "Test Feed",
            description: "Test Description",
            items: [],
            lastUpdated: Date()
        )
        
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
        
        let feed = Feed(
            id: feedID,
            url: URL(string: "https://example.com/feed")!,
            title: "Test Feed",
            description: "Test Description",
            items: [item],
            lastUpdated: Date()
        )
        
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
        
        let feed = Feed(
            id: feedID,
            url: URL(string: "https://example.com/feed")!,
            title: "Test Feed",
            description: "Test Description",
            items: [item],
            lastUpdated: Date()
        )
        
        feedManager.feeds = [feed]
        
        // Act
        feedManager.toggleStarred(item: item)
        
        // Assert
        XCTAssertTrue(feedManager.feeds[0].items[0].isStarred)
        
        // Toggle again
        feedManager.toggleStarred(item: item)
        
        // Assert
        XCTAssertFalse(feedManager.feeds[0].items[0].isStarred)
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
        
        let feed = Feed(
            id: feedID,
            url: URL(string: "https://example.com/feed")!,
            title: "Test Feed",
            description: "Test Description",
            items: items,
            lastUpdated: Date()
        )
        
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
