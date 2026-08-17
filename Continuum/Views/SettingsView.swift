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
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    privacyCard
                    dataSection
                    aboutSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .background(ContinuumStyle.canvas.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(item: $exportItem) { item in
                ShareSheet(items: [item.url])
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false,
                onCompletion: handleImport
            )
            .alert("Couldn't complete that", isPresented: $showImportError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importError ?? "Something went wrong.")
            }
            .alert("Restore complete", isPresented: $showImportSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your backup was added to Continuum.")
            }
        }
    }

    private var privacyCard: some View {
        HStack(spacing: 15) {
            ContinuumSymbolTile(systemImage: "lock.shield.fill", color: .green, size: 50)
            VStack(alignment: .leading, spacing: 5) {
                Text("Your records stay with you")
                    .font(.headline)
                Text("Continuum stores your financial timeline on this device. Use a backup to keep a portable copy.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .continuumCard()
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading("Your data", subtitle: "Keep a copy or move your records")

            VStack(spacing: 0) {
                SettingsActionRow(
                    title: "Create backup",
                    detail: "Export all records and value history as JSON",
                    icon: "arrow.up.doc.fill",
                    color: .indigo,
                    isWorking: isExporting,
                    action: performExport
                )

                Divider().padding(.leading, 58)

                SettingsActionRow(
                    title: "Restore backup",
                    detail: "Import a Continuum backup and add it to this device",
                    icon: "arrow.down.doc.fill",
                    color: .teal,
                    action: { showFileImporter = true }
                )
            }
            .continuumCard(padding: 10)

            Label("Restoring currently adds records to existing data.", systemImage: "info.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading("About", subtitle: "Continuum app information")

            VStack(spacing: 0) {
                settingsValueRow("Version", value: appVersion, icon: "app.badge")
                Divider().padding(.leading, 52)
                settingsValueRow("Build", value: buildNumber, icon: "hammer.fill")
            }
            .continuumCard(padding: 10)

            Text("A clear view of recurring costs, personal assets, and the dates that matter.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
    }

    private func sectionHeading(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.title3.weight(.bold))
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private func settingsValueRow(_ title: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            ContinuumSymbolTile(systemImage: icon, color: .secondary, size: 34)
            Text(title).font(.subheadline.weight(.medium))
            Spacer()
            Text(value).font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
        }
        .padding(10)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    private func performExport() {
        guard !isExporting else { return }
        isExporting = true
        defer { isExporting = false }

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
                throw CocoaError(.fileNoSuchFile)
            }
            let url = documentsURL.appendingPathComponent(name)
            try data.write(to: url, options: .atomic)
            exportItem = ExportItem(url: url)
        } catch {
            presentError(error)
        }
    }

    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importFrom(url: url)
        case .failure(let error):
            presentError(error)
        }
    }

    private func importFrom(url: URL) {
        do {
            guard url.startAccessingSecurityScopedResource() else {
                throw CocoaError(.fileReadNoPermission)
            }
            defer { url.stopAccessingSecurityScopedResource() }
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let export = try decoder.decode(ContinuumExport.self, from: data)
            try export.importInto(modelContext)
            showImportSuccess = true
        } catch {
            presentError(error)
        }
    }

    private func presentError(_ error: Error) {
        importError = error.localizedDescription
        showImportError = true
    }
}

private struct SettingsActionRow: View {
    let title: String
    let detail: String
    let icon: String
    let color: Color
    var isWorking = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ContinuumSymbolTile(systemImage: icon, color: color, size: 38)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.subheadline.weight(.semibold))
                    Text(detail).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                if isWorking {
                    ProgressView()
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isWorking)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .modelContainer(for: [Subscription.self, PersonalAsset.self, AssetValueChange.self, Warranty.self], inMemory: true)
}
