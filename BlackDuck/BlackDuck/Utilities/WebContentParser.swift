import Foundation
import OSLog

enum ParserError: Error {
    case invalidURL
    case networkError(Error)
    case parsingError(String)
    case unsupportedFormat
}

class WebContentParser {
    private let logger = Logger(subsystem: "com.example.BlackDuck", category: "WebContentParser")

    func parseFeed(from url: URL) async throws -> Feed {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw ParserError.networkError(NSError(domain: "HTTPError", code: (response as? HTTPURLResponse)?.statusCode ?? 0))
            }

            // Try to determine the feed type
            if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") {
                if contentType.contains("application/rss+xml") || contentType.contains("application/xml") || contentType.contains("text/xml") {
                    return try parseRSSFeed(data: data, sourceURL: url)
                } else if contentType.contains("application/atom+xml") {
                    return try parseAtomFeed(data: data, sourceURL: url)
                } else if contentType.contains("application/json") {
                    return try parseJSONFeed(data: data, sourceURL: url)
                }
            }

            // If content type doesn't help, try to parse as different formats
            do {
                return try parseRSSFeed(data: data, sourceURL: url)
            } catch {
                do {
                    return try parseAtomFeed(data: data, sourceURL: url)
                } catch {
                    do {
                        return try parseJSONFeed(data: data, sourceURL: url)
                    } catch {
                        // If all parsing attempts fail, try to parse as HTML
                        return try parseWebPage(data: data, sourceURL: url)
                    }
                }
            }
        } catch {
            logger.error("Error fetching or parsing feed: \(error.localizedDescription)")
            throw ParserError.networkError(error)
        }
    }

    private func parseRSSFeed(data: Data, sourceURL: URL) throws -> Feed {
        // This is a simplified implementation. In a real app, you would use a proper XML parser
        guard let xmlString = String(data: data, encoding: .utf8) else {
            throw ParserError.parsingError("Could not convert data to string")
        }

        // Extract feed title
        let titlePattern = "<title>(.*?)</title>"
        let titleRegex = try NSRegularExpression(pattern: titlePattern)
        let titleMatches = titleRegex.matches(in: xmlString, range: NSRange(xmlString.startIndex..., in: xmlString))

        guard let titleMatch = titleMatches.first,
              let titleRange = Range(titleMatch.range(at: 1), in: xmlString) else {
            throw ParserError.parsingError("Could not find feed title")
        }

        let feedTitle = String(xmlString[titleRange])

        // Extract feed description
        let descPattern = "<description>(.*?)</description>"
        let descRegex = try NSRegularExpression(pattern: descPattern)
        let descMatches = descRegex.matches(in: xmlString, range: NSRange(xmlString.startIndex..., in: xmlString))

        let feedDescription: String
        if let descMatch = descMatches.first,
           let descRange = Range(descMatch.range(at: 1), in: xmlString) {
            feedDescription = String(xmlString[descRange])
        } else {
            feedDescription = "No description available"
        }

        // Extract items
        let itemPattern = "<item>(.*?)</item>"
        let itemRegex = try NSRegularExpression(pattern: itemPattern, options: [.dotMatchesLineSeparators])
        let itemMatches = itemRegex.matches(in: xmlString, range: NSRange(xmlString.startIndex..., in: xmlString))

        var feedItems: [FeedItem] = []

        let feedID = UUID()

        for itemMatch in itemMatches {
            if let itemRange = Range(itemMatch.range(at: 1), in: xmlString) {
                let itemContent = String(xmlString[itemRange])

                // Extract item title
                let titlePattern = "<title>(.*?)</title>"
                let titleRegex = try NSRegularExpression(pattern: titlePattern)
                let titleMatches = titleRegex.matches(in: itemContent, range: NSRange(itemContent.startIndex..., in: itemContent))

                guard let titleMatch = titleMatches.first,
                      let titleRange = Range(titleMatch.range(at: 1), in: itemContent) else {
                    continue
                }

                let itemTitle = String(itemContent[titleRange])

                // Extract item description
                let descPattern = "<description>(.*?)</description>"
                let descRegex = try NSRegularExpression(pattern: descPattern, options: [.dotMatchesLineSeparators])
                let descMatches = descRegex.matches(in: itemContent, range: NSRange(itemContent.startIndex..., in: itemContent))

                let itemDescription: String
                if let descMatch = descMatches.first,
                   let descRange = Range(descMatch.range(at: 1), in: itemContent) {
                    itemDescription = String(itemContent[descRange])
                } else {
                    itemDescription = "No description available"
                }

                // Extract item content (try different tags)
                var contentHtml = itemDescription

                // Try to get content from content:encoded tag (common in RSS feeds)
                let contentPattern = "<content:encoded>(.*?)</content:encoded>"
                let contentRegex = try NSRegularExpression(pattern: contentPattern, options: [.dotMatchesLineSeparators])
                let contentMatches = contentRegex.matches(in: itemContent, range: NSRange(itemContent.startIndex..., in: itemContent))

                if let contentMatch = contentMatches.first,
                   let contentRange = Range(contentMatch.range(at: 1), in: itemContent) {
                    contentHtml = String(itemContent[contentRange])
                }

                // Clean up HTML entities in the content
                contentHtml = contentHtml.replacingOccurrences(of: "&lt;", with: "<")
                    .replacingOccurrences(of: "&gt;", with: ">")
                    .replacingOccurrences(of: "&amp;", with: "&")
                    .replacingOccurrences(of: "&quot;", with: "\"")
                    .replacingOccurrences(of: "&apos;", with: "'")

                // Extract item link
                let linkPattern = "<link>(.*?)</link>"
                let linkRegex = try NSRegularExpression(pattern: linkPattern)
                let linkMatches = linkRegex.matches(in: itemContent, range: NSRange(itemContent.startIndex..., in: itemContent))

                var itemURL: URL? = nil
                if let linkMatch = linkMatches.first,
                   let linkRange = Range(linkMatch.range(at: 1), in: itemContent),
                   let url = URL(string: String(itemContent[linkRange])) {
                    itemURL = url
                }

                // Try alternate link format (common in some RSS feeds)
                if itemURL == nil {
                    let altLinkPattern = "<link [^>]*href=\"([^\"]+)\""
                    let altLinkRegex = try NSRegularExpression(pattern: altLinkPattern)
                    let altLinkMatches = altLinkRegex.matches(in: itemContent, range: NSRange(itemContent.startIndex..., in: itemContent))

                    if let altLinkMatch = altLinkMatches.first,
                       let altLinkRange = Range(altLinkMatch.range(at: 1), in: itemContent),
                       let url = URL(string: String(itemContent[altLinkRange])) {
                        itemURL = url
                    }
                }

                // Extract publication date
                let pubDatePattern = "<pubDate>(.*?)</pubDate>"
                let pubDateRegex = try NSRegularExpression(pattern: pubDatePattern)
                let pubDateMatches = pubDateRegex.matches(in: itemContent, range: NSRange(itemContent.startIndex..., in: itemContent))

                let itemDate: Date
                if let pubDateMatch = pubDateMatches.first,
                   let pubDateRange = Range(pubDateMatch.range(at: 1), in: itemContent) {
                    let pubDateString = String(itemContent[pubDateRange])
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
                    if let date = dateFormatter.date(from: pubDateString) {
                        itemDate = date
                    } else {
                        // Try alternative date formats
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                        if let date = dateFormatter.date(from: pubDateString) {
                            itemDate = date
                        } else {
                            itemDate = Date()
                        }
                    }
                } else {
                    itemDate = Date()
                }

                // Extract author
                let authorPattern = "<author>(.*?)</author>"
                let authorRegex = try NSRegularExpression(pattern: authorPattern)
                let authorMatches = authorRegex.matches(in: itemContent, range: NSRange(itemContent.startIndex..., in: itemContent))

                var author: String? = nil
                if let authorMatch = authorMatches.first,
                   let authorRange = Range(authorMatch.range(at: 1), in: itemContent) {
                    author = String(itemContent[authorRange])
                }

                // Extract image URL
                var imageURL: URL? = nil
                let imgPattern = "<img[^>]+src=\"([^\"]+)\""
                let imgRegex = try NSRegularExpression(pattern: imgPattern)
                let imgMatches = imgRegex.matches(in: itemDescription, range: NSRange(itemDescription.startIndex..., in: itemDescription))

                if let imgMatch = imgMatches.first,
                   let imgRange = Range(imgMatch.range(at: 1), in: itemDescription),
                   let url = URL(string: String(itemDescription[imgRange])) {
                    imageURL = url
                }

                let feedItem = FeedItem(
                    feedID: feedID,
                    feedTitle: feedTitle,
                    title: itemTitle,
                    description: itemDescription,
                    content: contentHtml,
                    url: itemURL,
                    author: author,
                    publishDate: itemDate,
                    imageURL: imageURL
                )

                feedItems.append(feedItem)
            }
        }

        return Feed(
            url: sourceURL,
            title: feedTitle,
            description: feedDescription,
            items: feedItems,
            lastUpdated: Date()
        )
    }

    private func parseAtomFeed(data: Data, sourceURL: URL) throws -> Feed {
        // Simplified implementation for Atom feeds
        // In a real app, you would use a proper XML parser
        throw ParserError.unsupportedFormat
    }

    private func parseJSONFeed(data: Data, sourceURL: URL) throws -> Feed {
        // Simplified implementation for JSON feeds
        throw ParserError.unsupportedFormat
    }

    private func parseWebPage(data: Data, sourceURL: URL) throws -> Feed {
        // Simplified implementation for HTML pages
        // In a real app, you would use a proper HTML parser
        throw ParserError.unsupportedFormat
    }
}
