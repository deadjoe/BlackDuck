import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var feedManager: FeedManager
    @Binding var selectedFeed: Feed?
    
    var body: some View {
        List(selection: $selectedFeed) {
            Section("All Feeds") {
                ForEach(feedManager.feeds) { feed in
                    NavigationLink(value: feed) {
                        HStack {
                            if let iconData = feed.iconData, let image = NSImage(data: iconData) {
                                Image(nsImage: image)
                                    .resizable()
                                    .frame(width: 16, height: 16)
                            } else {
                                Image(systemName: "globe")
                                    .frame(width: 16, height: 16)
                            }
                            
                            Text(feed.title)
                            
                            Spacer()
                            
                            if feed.unreadCount > 0 {
                                Text("\(feed.unreadCount)")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .tag(feed)
                }
            }
            
            Section("Categories") {
                ForEach(feedManager.categories, id: \.self) { category in
                    NavigationLink {
                        CategoryView(category: category)
                            .environmentObject(feedManager)
                    } label: {
                        Label(category, systemImage: "folder")
                    }
                }
            }
            
            Section("Smart Feeds") {
                NavigationLink {
                    SmartFeedView(title: "Today", filter: { $0.isToday })
                        .environmentObject(feedManager)
                } label: {
                    Label("Today", systemImage: "calendar")
                }
                
                NavigationLink {
                    SmartFeedView(title: "Unread", filter: { !$0.isRead })
                        .environmentObject(feedManager)
                } label: {
                    Label("Unread", systemImage: "circle")
                }
                
                NavigationLink {
                    SmartFeedView(title: "Starred", filter: { $0.isStarred })
                        .environmentObject(feedManager)
                } label: {
                    Label("Starred", systemImage: "star")
                }
            }
        }
        .listStyle(.sidebar)
    }
}

struct CategoryView: View {
    @EnvironmentObject var feedManager: FeedManager
    let category: String
    @State private var selectedFeed: Feed?
    
    var body: some View {
        List(selection: $selectedFeed) {
            ForEach(feedsInCategory) { feed in
                NavigationLink(value: feed) {
                    HStack {
                        if let iconData = feed.iconData, let image = NSImage(data: iconData) {
                            Image(nsImage: image)
                                .resizable()
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "globe")
                                .frame(width: 16, height: 16)
                        }
                        
                        Text(feed.title)
                    }
                }
                .tag(feed)
            }
        }
        .navigationTitle(category)
    }
    
    private var feedsInCategory: [Feed] {
        feedManager.feeds.filter { $0.category == category }
    }
}

struct SmartFeedView: View {
    @EnvironmentObject var feedManager: FeedManager
    let title: String
    let filter: (FeedItem) -> Bool
    @State private var selectedItem: FeedItem?
    
    var body: some View {
        List(filteredItems, selection: $selectedItem) { item in
            FeedItemView(item: item)
                .tag(item)
        }
        .navigationTitle(title)
    }
    
    private var filteredItems: [FeedItem] {
        feedManager.feeds.flatMap { feed in
            feed.items.filter(filter)
        }
    }
}
