import SwiftUI
import Foundation

struct SidebarView: View {
    @EnvironmentObject var feedManager: FeedManager
    @Binding var selectedFeed: Feed?
    @Binding var selectedSmartFeed: SmartFeedType?

    var body: some View {
        List {
            Section("All Feeds") {
                ForEach(feedManager.feeds) { feed in
                    Button {
                        selectedFeed = feed
                        selectedSmartFeed = nil
                    } label: {
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
                                .foregroundColor(.primary)

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
                    .buttonStyle(.plain)
                    .padding(.vertical, 2)
                    .background(selectedFeed?.id == feed.id ? Color.accentColor.opacity(0.2) : Color.clear)
                    .cornerRadius(4)
                }
            }

            Section("Categories") {
                ForEach(feedManager.categories, id: \.self) { category in
                    Button {
                        // 暂时不做任何操作，因为我们需要修改 CategoryView 的实现
                    } label: {
                        Label(category, systemImage: "folder")
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 2)
                    .cornerRadius(4)
                }
            }

            Section("Smart Feeds") {
                ForEach(SmartFeedType.allCases) { smartFeed in
                    Button {
                        selectedFeed = nil
                        selectedSmartFeed = smartFeed
                    } label: {
                        Label(smartFeed.title, systemImage: smartFeed.systemImage)
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 2)
                    .background(selectedSmartFeed == smartFeed ? Color.accentColor.opacity(0.2) : Color.clear)
                    .cornerRadius(4)
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


