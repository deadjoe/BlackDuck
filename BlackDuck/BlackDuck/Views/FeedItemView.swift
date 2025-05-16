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

                        if item.isStarred {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
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
                // Toggle starred status
                feedManager.toggleStarred(item: item)
            } label: {
                Label(item.isStarred ? "Remove Star" : "Star",
                      systemImage: item.isStarred ? "star.slash" : "star")
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
