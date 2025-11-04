//
//  SettingsView.swift
//  FilePilot
//
//  Settings view for the app
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            AdvancedSettingsView()
                .tabItem {
                    Label("Advanced", systemImage: "gearshape.2")
                }
        }
        .frame(width: 500, height: 300)
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Form {
            Toggle("Show Hidden Files", isOn: $appState.showHiddenFiles)

            Picker("Default View Mode", selection: $appState.viewMode) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue)
                }
            }
        }
        .padding()
    }
}

struct AppearanceSettingsView: View {
    var body: some View {
        Text("Appearance Settings")
            .padding()
    }
}

struct AdvancedSettingsView: View {
    var body: some View {
        Text("Advanced Settings")
            .padding()
    }
}