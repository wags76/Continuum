//
//  SettingsView.swift
//  Continuum
//
//  Created by Christopher Wagner on 2/17/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

private struct ExportItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var exportItem: ExportItem?
    @State private var showFileImporter = false
    @State private var importError: String?
    @State private var showImportError = false
    @State private var showImportSuccess = false
    @State private var isExporting = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Data Management Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Data Management")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)

                            VStack(spacing: 16) {
                                // Backup
                                VStack(spacing: 16) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.title2)
                                            .foregroundStyle(.tint)
                                            .frame(width: 30)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Back up my data")
                                                .font(.headline)
                                                .foregroundStyle(.primary)
                                            Text("Export subscriptions, assets, and warranties to JSON")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }

                                    Button {
                                        if isExporting { return }
                                        performExport()
                                    } label: {
                                        HStack {
                                            if isExporting {
                                                ProgressView()
                                                    .scaleEffect(0.8)
                                                    .tint(.white)
                                            } else {
                                                Image(systemName: "doc.text")
                                                    .font(.system(size: 16, weight: .medium))
                                            }
                                            Text(isExporting ? "Exporting…" : "Backup")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(Color.accentColor)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                    .disabled(isExporting)
                                }

                                // Restore
                                VStack(spacing: 16) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.down")
                                            .font(.title2)
                                            .foregroundStyle(.tint)
                                            .frame(width: 30)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Restore from backup")
                                                .font(.headline)
                                                .foregroundStyle(.primary)
                                            Text("Restore from a JSON backup (adds to existing data)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }

                                    Button {
                                        showFileImporter = true
                                    } label: {
                                        HStack {
                                            Image(systemName: "doc.text")
                                                .font(.system(size: 16, weight: .medium))
                                            Text("Import")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(Color.accentColor)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }
                            .padding(20)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        }

                        // About Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("About")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)

                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .font(.title2)
                                        .foregroundStyle(.tint)
                                        .frame(width: 30)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("App Information")
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text("Version and build")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }

                                VStack(spacing: 12) {
                                    HStack {
                                        Text("Version")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(appVersion)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(.primary)
                                    }
                                    HStack {
                                        Text("Build")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(buildNumber)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(.primary)
                                    }
                                }
                            }
                            .padding(20)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $exportItem) { item in
                ShareSheet(items: [item.url])
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result: result)
            }
            .alert("Couldn't restore", isPresented: $showImportError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importError ?? "Something went wrong.")
            }
            .alert("Restore complete", isPresented: $showImportSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your backup was restored successfully.")
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    private func performExport() {
        isExporting = true
        do {
            let export = try ContinuumExport.build(from: modelContext)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(export)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd-HHmmss"
            let name = "Continuum-Backup-\(formatter.string(from: Date())).json"
            guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                importError = "Couldn't save the backup."
                showImportError = true
                isExporting = false
                return
            }
            let url = documentsURL.appendingPathComponent(name)
            try data.write(to: url)
            exportItem = ExportItem(url: url)
        } catch {
            importError = error.localizedDescription
            showImportError = true
        }
        isExporting = false
    }

    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importFrom(url: url)
        case .failure(let error):
            importError = error.localizedDescription
            showImportError = true
        }
    }

    private func importFrom(url: URL) {
        do {
            guard url.startAccessingSecurityScopedResource() else {
                importError = "Couldn't open the backup file."
                showImportError = true
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let export = try decoder.decode(ContinuumExport.self, from: data)
            try export.importInto(modelContext)
            showImportSuccess = true
        } catch {
            importError = error.localizedDescription
            showImportError = true
        }
    }
}

// MARK: - Share sheet (email, Files, share)

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .modelContainer(for: [Subscription.self, PersonalAsset.self, Warranty.self], inMemory: true)
}
