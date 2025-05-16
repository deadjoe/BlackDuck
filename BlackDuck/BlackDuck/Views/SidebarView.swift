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
    @State private var searchText = ""

    var body: some View {
        VStack {
            List(filteredItems, selection: $selectedItem) { item in
                NavigationLink(value: item) {
                    FeedItemView(item: item)
                }
                .tag(item)
                .contextMenu {
                    Button {
                        if item.isRead {
                            feedManager.markAsUnread(item: item)
                        } else {
                            feedManager.markAsRead(item: item)
                        }
                    } label: {
                        Label(item.isRead ? "Mark as Unread" : "Mark as Read",
                              systemImage: item.isRead ? "circle" : "checkmark.circle")
                    }

                    Button {
                        feedManager.toggleStarred(item: item)
                    } label: {
                        Label(item.isStarred ? "Remove Star" : "Star",
                              systemImage: item.isStarred ? "star.slash" : "star")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search in \(title)")

            if let selectedItem = selectedItem {
                DetailView(item: selectedItem)
                    .environmentObject(feedManager)
            } else {
                ContentUnavailableView("Select an Item", systemImage: "doc.text")
            }
        }
        .navigationTitle(title)
    }

    private var filteredItems: [FeedItem] {
        let items = feedManager.feeds.flatMap { feed in
            feed.items.filter(filter)
        }

        if searchText.isEmpty {
            return items
        } else {
            return items.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.description.localizedCaseInsensitiveContains(searchText) ||
                (item.content.localizedCaseInsensitiveContains(searchText))
            }
        }
    }
}
