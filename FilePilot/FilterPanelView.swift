//
//  FilterPanelView.swift
//  FilePilot
//
//  Advanced filter controls UI
//

import SwiftUI

struct FilterPanelView: View {
    @ObservedObject var filterState: FilterState
    @ObservedObject var savedSearchService = SavedSearchService.shared

    @State private var showSaveDialog = false
    @State private var newSearchName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Filters")
                    .font(.headline)

                Spacer()

                if filterState.hasActiveFilters {
                    Button("Reset") {
                        filterState.reset()
                        TelemetryService.shared.recordAction("filters_reset")
                    }
                    .buttonStyle(.borderless)
                }

                Button(action: { showSaveDialog = true }) {
                    Image(systemName: "star")
                }
                .help("Save current search")
                .disabled(!filterState.hasActiveFilters)
            }

            Divider()

            // Search options
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Use Regular Expression", isOn: $filterState.useRegex)
                Toggle("Case Sensitive", isOn: $filterState.caseSensitive)
            }

            Divider()

            // File type filter
            VStack(alignment: .leading, spacing: 8) {
                Text("File Type")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Picker("Type", selection: $filterState.fileType) {
                    ForEach(FileTypeFilter.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)
            }

            Divider()

            // Date filter
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Filter by Date", isOn: $filterState.dateFilterEnabled)
                    .font(.subheadline)

                if filterState.dateFilterEnabled {
                    DatePicker("From", selection: $filterState.dateFrom, displayedComponents: .date)
                        .datePickerStyle(.compact)

                    DatePicker("To", selection: $filterState.dateTo, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }
            }

            Divider()

            // Size filter
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Filter by Size", isOn: $filterState.sizeFilterEnabled)
                    .font(.subheadline)

                if filterState.sizeFilterEnabled {
                    Picker("Comparison", selection: $filterState.sizeComparison) {
                        ForEach(SizeComparison.allCases, id: \.self) { comparison in
                            Text(comparison.rawValue).tag(comparison)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text("Min:")
                        Text(ByteCountFormatter.string(fromByteCount: filterState.sizeMin, countStyle: .file))
                            .frame(minWidth: 80)
                        Stepper("", value: $filterState.sizeMin, in: 0...Int64.max, step: 1024 * 1024)
                            .labelsHidden()
                    }

                    if filterState.sizeComparison == .between {
                        HStack {
                            Text("Max:")
                            Text(ByteCountFormatter.string(fromByteCount: filterState.sizeMax, countStyle: .file))
                                .frame(minWidth: 80)
                            Stepper("", value: $filterState.sizeMax, in: 0...Int64.max, step: 1024 * 1024)
                                .labelsHidden()
                        }
                    }
                }
            }

            Divider()

            // Saved searches
            if !savedSearchService.searches.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Saved Searches")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ForEach(savedSearchService.searches) { search in
                        HStack {
                            Button(action: {
                                search.apply(to: filterState)
                                TelemetryService.shared.recordAction("saved_search_applied", metadata: [
                                    "name": search.name
                                ])
                            }) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                    Text(search.name)
                                    Spacer()
                                }
                            }
                            .buttonStyle(.borderless)

                            Button(action: {
                                savedSearchService.delete(search)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .frame(width: 250)
        .sheet(isPresented: $showSaveDialog) {
            VStack(spacing: 16) {
                Text("Save Search")
                    .font(.headline)

                TextField("Search Name", text: $newSearchName)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button("Cancel") {
                        showSaveDialog = false
                        newSearchName = ""
                    }

                    Button("Save") {
                        let search = SavedSearch(name: newSearchName, state: filterState)
                        savedSearchService.save(search)
                        showSaveDialog = false
                        newSearchName = ""
                    }
                    .disabled(newSearchName.isEmpty)
                }
            }
            .padding()
            .frame(width: 300, height: 150)
        }
    }
}
