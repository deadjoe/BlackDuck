import XCTest
@testable import BlackDuck

final class WebContentParserTests: XCTestCase {
    
    var parser: WebContentParser!
    
    override func setUp() {
        super.setUp()
        parser = WebContentParser()
    }
    
    override func tearDown() {
        parser = nil
        super.tearDown()
    }
    
    func testParseRSSFeed() throws {
        // Arrange
        let rssData = """
        <?xml version="1.0" encoding="UTF-8" ?>
        <rss version="2.0">
        <channel>
            <title>Test RSS Feed</title>
            <description>A test RSS feed for unit testing</description>
            <link>https://example.com/feed</link>
            <item>
                <title>Test Article 1</title>
                <description>This is a test article description</description>
                <link>https://example.com/article1</link>
                <pubDate>Mon, 01 Jan 2023 12:00:00 +0000</pubDate>
                <author>Test Author</author>
            </item>
            <item>
                <title>Test Article 2</title>
                <description>This is another test article description</description>
                <link>https://example.com/article2</link>
                <pubDate>Tue, 02 Jan 2023 12:00:00 +0000</pubDate>
                <content:encoded><![CDATA[<p>This is the full content of the article with <b>HTML</b> formatting.</p>]]></content:encoded>
            </item>
        </channel>
        </rss>
        """.data(using: .utf8)!
        
        // Act
        let feed = try parser.parseRSSFeed(data: rssData, sourceURL: URL(string: "https://example.com/feed")!)
        
        // Assert
        XCTAssertEqual(feed.title, "Test RSS Feed")
        XCTAssertEqual(feed.description, "A test RSS feed for unit testing")
        XCTAssertEqual(feed.url.absoluteString, "https://example.com/feed")
        XCTAssertEqual(feed.items.count, 2)
        
        // Check first item
        let item1 = feed.items[0]
        XCTAssertEqual(item1.title, "Test Article 1")
        XCTAssertEqual(item1.description, "This is a test article description")
        XCTAssertEqual(item1.url?.absoluteString, "https://example.com/article1")
        XCTAssertEqual(item1.author, "Test Author")
        
        // Check second item with content:encoded
        let item2 = feed.items[1]
        XCTAssertEqual(item2.title, "Test Article 2")
        XCTAssertEqual(item2.content, "<p>This is the full content of the article with <b>HTML</b> formatting.</p>")
    }
    
    func testParseRSSFeedWithHTMLEntities() throws {
        // Arrange
        let rssData = """
        <?xml version="1.0" encoding="UTF-8" ?>
        <rss version="2.0">
        <channel>
            <title>HTML Entities Test</title>
            <description>Testing HTML entities in RSS</description>
            <link>https://example.com/feed</link>
            <item>
                <title>HTML &amp; Entities</title>
                <description>Testing &lt;b&gt;HTML&lt;/b&gt; entities in &quot;description&quot;</description>
                <link>https://example.com/article</link>
                <pubDate>Mon, 01 Jan 2023 12:00:00 +0000</pubDate>
            </item>
        </channel>
        </rss>
        """.data(using: .utf8)!
        
        // Act
        let feed = try parser.parseRSSFeed(data: rssData, sourceURL: URL(string: "https://example.com/feed")!)
        
        // Assert
        XCTAssertEqual(feed.title, "HTML Entities Test")
        
        let item = feed.items[0]
        XCTAssertEqual(item.title, "HTML & Entities")
        XCTAssertEqual(item.description, "Testing <b>HTML</b> entities in \"description\"")
    }
    
    func testParseRSSFeedWithImageExtraction() throws {
        // Arrange
        let rssData = """
        <?xml version="1.0" encoding="UTF-8" ?>
        <rss version="2.0">
        <channel>
            <title>Image Test Feed</title>
            <description>Testing image extraction</description>
            <link>https://example.com/feed</link>
            <item>
                <title>Article with Image</title>
                <description>This article has an <img src="https://example.com/image.jpg" alt="Test Image"> embedded.</description>
                <link>https://example.com/article</link>
                <pubDate>Mon, 01 Jan 2023 12:00:00 +0000</pubDate>
            </item>
        </channel>
        </rss>
        """.data(using: .utf8)!
        
        // Act
        let feed = try parser.parseRSSFeed(data: rssData, sourceURL: URL(string: "https://example.com/feed")!)
        
        // Assert
        let item = feed.items[0]
        XCTAssertEqual(item.imageURL?.absoluteString, "https://example.com/image.jpg")
    }
    
    func testParseRSSFeedWithAlternativeLinkFormat() throws {
        // Arrange
        let rssData = """
        <?xml version="1.0" encoding="UTF-8" ?>
        <rss version="2.0">
        <channel>
            <title>Alternative Link Format Test</title>
            <description>Testing alternative link format</description>
            <link>https://example.com/feed</link>
            <item>
                <title>Article with Alternative Link</title>
                <description>This article has an alternative link format.</description>
                <link href="https://example.com/article" />
                <pubDate>Mon, 01 Jan 2023 12:00:00 +0000</pubDate>
            </item>
        </channel>
        </rss>
        """.data(using: .utf8)!
        
        // Act
        let feed = try parser.parseRSSFeed(data: rssData, sourceURL: URL(string: "https://example.com/feed")!)
        
        // Assert
        let item = feed.items[0]
        XCTAssertEqual(item.url?.absoluteString, "https://example.com/article")
    }
    
    func testParseRSSFeedWithAlternativeDateFormat() throws {
        // Arrange
        let rssData = """
        <?xml version="1.0" encoding="UTF-8" ?>
        <rss version="2.0">
        <channel>
            <title>Alternative Date Format Test</title>
            <description>Testing alternative date format</description>
            <link>https://example.com/feed</link>
            <item>
                <title>Article with ISO Date</title>
                <description>This article has an ISO date format.</description>
                <link>https://example.com/article</link>
                <pubDate>2023-01-01T12:00:00Z</pubDate>
            </item>
        </channel>
        </rss>
        """.data(using: .utf8)!
        
        // Act
        let feed = try parser.parseRSSFeed(data: rssData, sourceURL: URL(string: "https://example.com/feed")!)
        
        // Assert
        let item = feed.items[0]
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: item.publishDate)
        
        XCTAssertEqual(components.year, 2023)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 1)
    }
}
