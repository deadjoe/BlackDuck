import XCTest
@testable import BlackDuck

final class FeedModelTests: XCTestCase {
    
    // Test Feed model properties and methods
    func testFeedProperties() {
        // Arrange
        let url = URL(string: "https://example.com/feed")!
        let title = "Test Feed"
        let description = "Test Description"
        let category = "Test Category"
        let lastUpdated = Date()
        
        let feed = Feed(
            url: url,
            title: title,
            description: description,
            category: category,
            items: [],
            lastUpdated: lastUpdated
        )
        
        // Assert
        XCTAssertEqual(feed.url, url)
        XCTAssertEqual(feed.title, title)
        XCTAssertEqual(feed.description, description)
        XCTAssertEqual(feed.category, category)
        XCTAssertEqual(feed.lastUpdated, lastUpdated)
        XCTAssertEqual(feed.items.count, 0)
        XCTAssertEqual(feed.unreadCount, 0)
    }
    
    func testFeedUnreadCount() {
        // Arrange
        let feedID = UUID()
        let feed = Feed(
            url: URL(string: "https://example.com/feed")!,
            title: "Test Feed",
            description: "Test Description",
            items: [
                FeedItem(
                    feedID: feedID,
                    title: "Item 1",
                    description: "Description 1",
                    content: "Content 1",
                    publishDate: Date(),
                    isRead: true
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
                    isRead: false
                )
            ],
            lastUpdated: Date()
        )
        
        // Assert
        XCTAssertEqual(feed.unreadCount, 2)
    }
    
    func testFeedEquality() {
        // Arrange
        let feed1 = Feed(
            url: URL(string: "https://example.com/feed1")!,
            title: "Feed 1",
            description: "Description 1",
            items: [],
            lastUpdated: Date()
        )
        
        var feed2 = feed1
        
        let feed3 = Feed(
            url: URL(string: "https://example.com/feed3")!,
            title: "Feed 3",
            description: "Description 3",
            items: [],
            lastUpdated: Date()
        )
        
        // Assert
        XCTAssertEqual(feed1, feed2)
        XCTAssertNotEqual(feed1, feed3)
        
        // Test that equality is based on ID, not content
        feed2.title = "Modified Title"
        XCTAssertEqual(feed1, feed2)
    }
    
    // Test FeedItem model properties and methods
    func testFeedItemProperties() {
        // Arrange
        let feedID = UUID()
        let title = "Test Item"
        let description = "Test Description"
        let content = "Test Content"
        let url = URL(string: "https://example.com/item")
        let author = "Test Author"
        let publishDate = Date()
        let thumbnailURL = URL(string: "https://example.com/thumb.jpg")
        let imageURL = URL(string: "https://example.com/image.jpg")
        
        let item = FeedItem(
            feedID: feedID,
            feedTitle: "Test Feed",
            title: title,
            description: description,
            content: content,
            url: url,
            author: author,
            publishDate: publishDate,
            thumbnailURL: thumbnailURL,
            imageURL: imageURL,
            isRead: false,
            isStarred: true
        )
        
        // Assert
        XCTAssertEqual(item.feedID, feedID)
        XCTAssertEqual(item.feedTitle, "Test Feed")
        XCTAssertEqual(item.title, title)
        XCTAssertEqual(item.description, description)
        XCTAssertEqual(item.content, content)
        XCTAssertEqual(item.url, url)
        XCTAssertEqual(item.author, author)
        XCTAssertEqual(item.publishDate, publishDate)
        XCTAssertEqual(item.thumbnailURL, thumbnailURL)
        XCTAssertEqual(item.imageURL, imageURL)
        XCTAssertFalse(item.isRead)
        XCTAssertTrue(item.isStarred)
    }
    
    func testFeedItemFormattedDate() {
        // Arrange
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)
        
        let item = FeedItem(
            feedID: UUID(),
            title: "Test Item",
            description: "Description",
            content: "Content",
            publishDate: oneHourAgo
        )
        
        // Assert
        XCTAssertTrue(item.formattedDate.contains("hour ago") || item.formattedDate.contains("1 hour ago"))
    }
    
    func testFeedItemIsToday() {
        // Arrange
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        
        let todayItem = FeedItem(
            feedID: UUID(),
            title: "Today Item",
            description: "Description",
            content: "Content",
            publishDate: now
        )
        
        let yesterdayItem = FeedItem(
            feedID: UUID(),
            title: "Yesterday Item",
            description: "Description",
            content: "Content",
            publishDate: yesterday
        )
        
        // Assert
        XCTAssertTrue(todayItem.isToday)
        XCTAssertFalse(yesterdayItem.isToday)
    }
    
    func testFeedItemEquality() {
        // Arrange
        let item1 = FeedItem(
            feedID: UUID(),
            title: "Item 1",
            description: "Description 1",
            content: "Content 1",
            publishDate: Date()
        )
        
        var item2 = item1
        
        let item3 = FeedItem(
            feedID: UUID(),
            title: "Item 3",
            description: "Description 3",
            content: "Content 3",
            publishDate: Date()
        )
        
        // Assert
        XCTAssertEqual(item1, item2)
        XCTAssertNotEqual(item1, item3)
        
        // Test that equality is based on ID, not content
        item2.title = "Modified Title"
        XCTAssertEqual(item1, item2)
    }
}
