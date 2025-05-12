import Foundation
import SwiftUI

struct Feed: Identifiable, Hashable, Codable {
    var id = UUID()
    var url: URL
    var title: String
    var description: String
    var category: String?
    var iconData: Data?
    var items: [FeedItem]
    var lastUpdated: Date
    
    var unreadCount: Int {
        items.filter { !$0.isRead }.count
    }
    
    static func == (lhs: Feed, rhs: Feed) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct FeedItem: Identifiable, Hashable, Codable {
    var id = UUID()
    var feedID: UUID
    var feedTitle: String?
    var title: String
    var description: String
    var content: String
    var url: URL?
    var author: String?
    var publishDate: Date
    var thumbnailURL: URL?
    var imageURL: URL?
    var isRead: Bool = false
    var isStarred: Bool = false
    
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: publishDate, relativeTo: Date())
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(publishDate)
    }
    
    static func == (lhs: FeedItem, rhs: FeedItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// Sample data for previews
extension Feed {
    static var samples: [Feed] {
        [
            Feed(
                url: URL(string: "https://example.com/feed1")!,
                title: "Tech News",
                description: "Latest technology news and updates",
                category: "Technology",
                items: FeedItem.techSamples,
                lastUpdated: Date()
            ),
            Feed(
                url: URL(string: "https://example.com/feed2")!,
                title: "Science Daily",
                description: "Latest science discoveries and research",
                category: "Science",
                items: FeedItem.scienceSamples,
                lastUpdated: Date()
            ),
            Feed(
                url: URL(string: "https://example.com/feed3")!,
                title: "World News",
                description: "Breaking news from around the world",
                category: "News",
                items: FeedItem.newsSamples,
                lastUpdated: Date()
            )
        ]
    }
}

extension FeedItem {
    static var techSamples: [FeedItem] {
        [
            FeedItem(
                feedID: UUID(),
                feedTitle: "Tech News",
                title: "Apple Announces New MacBook Pro with M3 Chip",
                description: "Apple has unveiled its latest MacBook Pro featuring the new M3 chip with improved performance and battery life.",
                content: "Apple has unveiled its latest MacBook Pro featuring the new M3 chip with improved performance and battery life. The new chip offers up to 40% faster performance than the previous generation M2 chip and improved power efficiency for longer battery life. The new MacBook Pro models will be available in 14-inch and 16-inch sizes with mini-LED displays.",
                url: URL(string: "https://example.com/apple-m3-macbook"),
                author: "John Appleseed",
                publishDate: Date().addingTimeInterval(-3600),
                thumbnailURL: URL(string: "https://example.com/macbook-thumb.jpg")
            ),
            FeedItem(
                feedID: UUID(),
                feedTitle: "Tech News",
                title: "Google Releases New AI Tools for Developers",
                description: "Google has announced a suite of new AI tools for developers at its annual developer conference.",
                content: "Google has announced a suite of new AI tools for developers at its annual developer conference. The new tools include improved natural language processing APIs, computer vision tools, and a new framework for building AI-powered applications. Developers will be able to access these tools through Google Cloud Platform.",
                url: URL(string: "https://example.com/google-ai-tools"),
                author: "Sarah Johnson",
                publishDate: Date().addingTimeInterval(-7200),
                thumbnailURL: URL(string: "https://example.com/google-ai-thumb.jpg")
            )
        ]
    }
    
    static var scienceSamples: [FeedItem] {
        [
            FeedItem(
                feedID: UUID(),
                feedTitle: "Science Daily",
                title: "Researchers Discover New Species in Amazon Rainforest",
                description: "A team of biologists has discovered a new species of frog in the Amazon rainforest.",
                content: "A team of biologists has discovered a new species of frog in the Amazon rainforest. The new species, named Dendrobates amazonia, is a brightly colored poison dart frog that secretes a unique toxin that may have medical applications. The discovery highlights the importance of preserving biodiversity in the Amazon rainforest.",
                url: URL(string: "https://example.com/new-frog-species"),
                author: "Dr. Maria Rodriguez",
                publishDate: Date().addingTimeInterval(-10800),
                thumbnailURL: URL(string: "https://example.com/frog-thumb.jpg"),
                imageURL: URL(string: "https://example.com/frog-full.jpg")
            )
        ]
    }
    
    static var newsSamples: [FeedItem] {
        [
            FeedItem(
                feedID: UUID(),
                feedTitle: "World News",
                title: "Global Climate Summit Reaches New Agreement",
                description: "World leaders have reached a new agreement on climate change at the annual Global Climate Summit.",
                content: "World leaders have reached a new agreement on climate change at the annual Global Climate Summit. The agreement includes commitments to reduce carbon emissions by 50% by 2030 and achieve carbon neutrality by 2050. The summit also established a fund to help developing nations transition to renewable energy sources.",
                url: URL(string: "https://example.com/climate-summit"),
                author: "James Wilson",
                publishDate: Date().addingTimeInterval(-14400),
                thumbnailURL: URL(string: "https://example.com/climate-thumb.jpg")
            )
        ]
    }
}
