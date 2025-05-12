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
        .frame(width: 500, height: 300)
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
            
            HStack {
                Spacer()
                Button("Add Feed") {
                    // Show add feed dialog
                }
            }
            .padding(.top, 10)
        }
        .padding()
    }
    
    private func deleteFeed(at offsets: IndexSet) {
        feedManager.removeFeed(at: offsets)
    }
}
