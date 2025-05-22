import SwiftUI

struct FeedItemView: View {
    let item: FeedItem
    @EnvironmentObject var feedManager: FeedManager

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                if let thumbnailURL = item.thumbnailURL {
                    AsyncImage(url: thumbnailURL) { phase in
                        switch phase {
                        case .empty:
                            Color.gray.opacity(0.3)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Color.gray.opacity(0.3)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(item.isRead ? .secondary : .primary)

                    Text(item.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    HStack {
                        if let feedTitle = item.feedTitle {
                            Text(feedTitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(item.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        // 可点击的星标按钮
                        Button {
                            print("FeedItemView - Star button clicked - item ID: \(item.id)")
                            let _ = feedManager.toggleStarred(item: item)
                        } label: {
                            // 从 FeedManager 中获取最新状态
                            let currentItem = feedManager.feeds
                                .first(where: { $0.id == item.feedID })?
                                .items.first(where: { $0.id == item.id })
                            let isStarred = currentItem?.isStarred ?? item.isStarred

                            Image(systemName: isStarred ? "star.fill" : "star")
                                .foregroundColor(isStarred ? .yellow : .gray)
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .help("Toggle starred status")
                    }
                }
            }

            Divider()
                .padding(.top, 4)
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button {
                // Toggle read status
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
                print("FeedItemView - Toggle starred - item ID: \(item.id), title: \(item.title)")

                // Toggle starred status and force UI update
                if let updatedItem = feedManager.toggleStarred(item: item) {
                    print("FeedItemView - Star toggled successfully, new state: \(updatedItem.isStarred)")
                } else {
                    print("FeedItemView - Failed to toggle star")
                }
            } label: {
                // 从 FeedManager 中获取最新状态
                let isStarred = feedManager.feeds
                    .first(where: { $0.id == item.feedID })?
                    .items.first(where: { $0.id == item.id })?
                    .isStarred ?? item.isStarred

                Label(isStarred ? "Remove Star" : "Star",
                      systemImage: isStarred ? "star.slash" : "star")
            }

            Divider()

            Button {
                // Open in browser
                if let url = item.url {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Label("Open in Browser", systemImage: "safari")
            }

            Button {
                // Share
                if let url = item.url {
                    let picker = NSSharingServicePicker(items: [url])
                    if let window = NSApplication.shared.windows.first {
                        picker.show(relativeTo: .zero, of: window.contentView!, preferredEdge: .minY)
                    }
                }
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
    }
}
