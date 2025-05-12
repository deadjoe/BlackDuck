import SwiftUI

@main
struct BlackDuckApp: App {
    @StateObject private var feedManager = FeedManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(feedManager)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)

        #if os(macOS)
        Settings {
            SettingsView()
                .environmentObject(feedManager)
        }
        #endif
    }
}

struct SettingsView: View {
    @EnvironmentObject var feedManager: FeedManager

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            FeedSettingsView()
                .environmentObject(feedManager)
                .tabItem {
                    Label("Feeds", systemImage: "list.bullet")
                }
        }
        .padding(20)
        .frame(width: 600, height: 400)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("refreshInterval") private var refreshInterval = 15
    @AppStorage("startAtLogin") private var startAtLogin = false
    @AppStorage("showNotifications") private var showNotifications = true

    var body: some View {
        Form {
            Section {
                Stepper(value: $refreshInterval, in: 5...60, step: 5) {
                    Text("Refresh interval: \(refreshInterval) minutes")
                }

                Toggle("Start at login", isOn: $startAtLogin)
                Toggle("Show notifications for new content", isOn: $showNotifications)
            } header: {
                Text("Application Settings")
            }
        }
    }
}

struct FeedSettingsView: View {
    @EnvironmentObject var feedManager: FeedManager
    @State private var isAddingFeed = false

    var body: some View {
        VStack(alignment: .leading) {
            Text("Manage Feed Sources")
                .font(.headline)
                .padding(.bottom, 5)

            List {
                ForEach(feedManager.feeds) { feed in
                    HStack {
                        Text(feed.title)
                        Spacer()
                        Text(feed.url.absoluteString)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                .onDelete(perform: deleteFeed)
            }
            .frame(minHeight: 150)

            HStack {
                Spacer()
                Button("Add Feed") {
                    isAddingFeed = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 10)
        }
        .padding()
        .sheet(isPresented: $isAddingFeed) {
            SettingsAddFeedView(isPresented: $isAddingFeed)
                .environmentObject(feedManager)
        }
    }

    private func deleteFeed(at offsets: IndexSet) {
        feedManager.removeFeed(at: offsets)
    }
}

struct SettingsAddFeedView: View {
    @EnvironmentObject var feedManager: FeedManager
    @Binding var isPresented: Bool
    @State private var url = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Add New Feed")
                .font(.headline)

            TextField("Feed URL", text: $url)
                .textFieldStyle(.roundedBorder)
                .frame(width: 350)

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            HStack {
                Button("Cancel") {
                    isPresented = false
                }

                Button("Add") {
                    addFeed()
                }
                .buttonStyle(.borderedProminent)
                .disabled(url.isEmpty || isLoading)
            }
        }
        .padding()
        .frame(width: 400)
        .disabled(isLoading)
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
    }

    private func addFeed() {
        guard let feedURL = URL(string: url) else {
            errorMessage = "Invalid URL"
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await feedManager.addFeed(url: feedURL)
                isLoading = false
                isPresented = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
