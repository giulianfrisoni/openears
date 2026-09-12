import SwiftUI
import AppKit
import OpenEarsCore

// Keep the stable property wrapper unambiguous on SDKs that also define a State macro.
private typealias StoredViewState<Value> = SwiftUI.State<Value>

@MainActor final class AppModel: ObservableObject {
    @Published var state = HeadsetState()
    @Published var catalog: Catalog?
    @Published var catalogError: String?
    @Published var profileID = "nothing-ear-3"
    private var driver: (any HeadsetDriver)?
    var profile: DeviceProfile? { catalog?.profiles.first { $0.id == profileID } }
    var supported: Bool { profile.map(DriverRegistry.supports) ?? false }
    func options(_ feature: String) -> [String] { profile.map { DriverRegistry.options(feature, profile: $0) } ?? [] }
    func permits(_ feature: String) -> Bool { profile.map { DriverRegistry.permits(feature, profile: $0) } ?? false }
    let catalogURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/OpenEars/catalog.json")

    init() {
        do { catalog = try Catalog.bundled() }
        catch { catalogError = "The bundled device catalog could not be loaded." }
        if FileManager.default.fileExists(atPath: catalogURL.path) {
            do { catalog = try Catalog.decode(Data(contentsOf: catalogURL)).includingBundled(try Catalog.bundled()) }
            catch { catalogError = "The installed catalog is invalid. Using the bundled catalog." }
        }
        if profile == nil { profileID = catalog?.profiles.first?.id ?? "" }
    }

    func connect() {
        guard let profile, supported else { return }
        if driver == nil {
            let adapter: any HeadsetDriver = profile.driver == DriverRegistry.nothingID ? NothingDriver(profile: profile) : ClassicHeadsetDriver(profile: profile)
            adapter.onChange = { [weak self] state in self?.state = state }
            driver = adapter
        }
        driver?.connect()
    }
    func disconnect() { driver?.disconnect() }
    func refresh() { driver?.refresh() }
    func set(_ feature: String, _ value: String) { driver?.set(feature, value: value) }
    func selectProfile() {
        driver?.onChange = nil
        driver?.disconnect()
        driver = nil
        state = HeadsetState()
    }
    func importCatalog() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            guard size <= 1_048_576 else { throw CatalogError.tooLarge }
            let data = try Data(contentsOf: url)
            if let document = try? ProfileDocument.decode(data) {
                try addProfiles([document.profile])
            } else {
                try addProfiles(Catalog.decode(data).profiles)
            }
        } catch { catalogError = "Could not import this catalog: \(error.localizedDescription)" }
    }

    func addProfiles(_ profiles: [DeviceProfile]) throws {
        guard let catalog else { throw CatalogError.missingResource }
        let updated = try catalog.adding(profiles)
        try FileManager.default.createDirectory(at: catalogURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try updated.encoded().write(to: catalogURL, options: .atomic)
        selectProfile()
        self.catalog = updated
        profileID = profiles.first?.id ?? profileID
        catalogError = nil
    }

    func exportProfile() {
        guard let profile else { return }
        let panel = NSSavePanel(); panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "\(profile.id).json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(ProfileDocument(profile: profile)).write(to: url, options: .atomic)
        } catch { catalogError = error.localizedDescription }
    }
}

@main struct OpenEarsApp: App {
    @StateObject private var model = AppModel()
    var body: some Scene {
        MenuBarExtra("OpenEars", systemImage: "earbuds") {
            EarPanel().environmentObject(model)
        }.menuBarExtraStyle(.window)
        Window("OpenEars · Device profiles", id: "profiles") {
            ProfilesView().environmentObject(model)
        }.defaultSize(width: 520, height: 600)
        Window("OpenEars · Acknowledgments", id: "credits") {
            CreditsView()
        }.defaultSize(width: 640, height: 600)
    }
}

struct EarPanel: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.openWindow) var openWindow
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Image(systemName: "earbuds").font(.system(size: 28)).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 3) {
                    Text(model.profile?.name ?? "OpenEars").font(.headline)
                    HStack(spacing: 5) {
                        Circle().fill(model.state.connected ? .green : .secondary).frame(width: 6, height: 6)
                        Text(model.state.status).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }

            if model.state.connected {
                HStack {
                    ForEach(model.state.battery["Headset"] != nil ? ["Headset"] : ["Left", "Right", "Case"], id: \.self) { part in
                        VStack(spacing: 5) {
                            Text(model.state.battery[part] ?? "—").font(.system(.title3, design: .rounded).weight(.medium))
                            Text(part).font(.caption).foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity)
                    }
                }.padding(14).background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 12))

                if model.permits("anc") {
                    control("Noise control", feature: "anc", options: model.options("anc"))
                }
                if model.permits("eq") {
                    control("Equalizer", feature: "eq", options: model.options("eq"))
                }
                if model.permits("spatial") {
                    control("Spatial audio", feature: "spatial", options: ["Off", "Fixed"])
                }
            } else {
                Text("Your headphones, at home on your Mac.")
                    .font(.title3.weight(.medium))
                Text("Connect your earbuds in Bluetooth Settings, then connect here to access their controls.")
                    .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                Button("Connect to earbuds", action: model.connect)
                    .buttonStyle(.borderedProminent).disabled(!model.supported)
            }

            if let error = model.state.error ?? model.catalogError {
                Text(error).font(.caption).foregroundStyle(.orange).fixedSize(horizontal: false, vertical: true)
            }
            Divider()
            HStack {
                Text("OPEN EARS · PREVIEW").font(.system(size: 9, weight: .semibold)).foregroundStyle(.secondary)
                Spacer()
                Button {
                    openWindow(id: "profiles")
                    NSApp.activate(ignoringOtherApps: true)
                } label: { Image(systemName: "slider.horizontal.3") }
                .buttonStyle(.plain).help("Device profiles and support")
                Menu {
                    Button("Acknowledgments & licenses") {
                        openWindow(id: "credits")
                        NSApp.activate(ignoringOtherApps: true)
                    }
                    if model.state.connected {
                        Button("Refresh", action: model.refresh)
                        Button("Disconnect controls", action: model.disconnect)
                    }
                    Button("Bluetooth Settings") {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.BluetoothSettings")!)
                    }
                    Divider()
                    Button("Quit OpenEars") { model.disconnect(); NSApp.terminate(nil) }
                } label: { Image(systemName: "ellipsis.circle") }.menuStyle(.borderlessButton).frame(width: 22)
            }
        }.padding(20).frame(width: 340)
    }

    private func control(_ title: String, feature: String, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.subheadline.weight(.medium))
                Spacer()
                if model.state.pending == feature { ProgressView().controlSize(.mini) }
                Text(model.state.values[feature] ?? "Waiting for earbuds").font(.caption).foregroundStyle(.secondary)
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(options, id: \.self) { option in
                    Button { model.set(feature, option) } label: {
                        HStack(spacing: 4) {
                            if model.state.values[feature] == option {
                                Image(systemName: "checkmark").font(.caption2.weight(.bold))
                            }
                            Text(option)
                        }.frame(maxWidth: .infinity).padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                    .tint(model.state.values[feature] == option ? .accentColor : .secondary)
                    .disabled(model.state.pending != nil || model.state.values[feature] == nil)
                    .accessibilityLabel("\(title): \(option)")
                    .accessibilityValue(model.state.values[feature] == option ? "Selected" : "")
                }
            }
        }
    }
}

struct ProfilesView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.openWindow) var openWindow
    @StoredViewState<Bool> private var addingProfile = false
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("One app. More possibilities.").font(.title2.weight(.semibold))
            Text("Device profiles describe what each headset can do. New profiles can be installed independently of the app when their driver is already included.")
                .foregroundStyle(.secondary)
            Picker("Device profile", selection: $model.profileID) {
                ForEach(model.catalog?.profiles ?? []) { profile in Text(profile.name).tag(profile.id) }
            }.onChange(of: model.profileID) { model.selectProfile() }
            if !model.supported { Text("This driver or model is not available in this app version. The profile is saved for future support.").foregroundStyle(.orange) }
            if let firmware = model.state.firmware {
                Text("Firmware \(firmware)").font(.caption).foregroundStyle(.secondary)
            }
            List(model.profile?.features ?? []) { feature in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(feature.name).fontWeight(.medium)
                        Spacer()
                        Text(feature.status.rawValue.capitalized).font(.caption).foregroundStyle(.secondary)
                    }
                    Text(feature.note).font(.caption).foregroundStyle(.secondary)
                }.padding(.vertical, 5)
            }.listStyle(.inset)
            if let error = model.catalogError { Text(error).foregroundStyle(.orange).font(.caption) }
            if let credit = model.profile?.attribution {
                Text("Profile by \(credit.authors.joined(separator: ", "))").font(.caption).foregroundStyle(.secondary)
                if let url = URL(string: credit.source) { Link("Profile source · \(credit.license)", destination: url).font(.caption) }
            }
            HStack {
                Button("Add device profile…") { addingProfile = true }
                Button("Import…", action: model.importCatalog)
                Button("Export…", action: model.exportProfile).disabled(model.profile == nil)
                Spacer()
                Text("Catalog r\(model.catalog?.revision ?? 0)").font(.caption).foregroundStyle(.secondary)
            }
            Text("Open source · Local Bluetooth · No account or analytics").font(.caption).foregroundStyle(.secondary)
            Button("With thanks to our authors…") { openWindow(id: "credits") }.buttonStyle(.link)
        }.padding(24).frame(minWidth: 480, minHeight: 520)
            .sheet(isPresented: $addingProfile) { AddProfileView().environmentObject(model) }
    }
}

struct CreditsView: View {
    private var text: AttributedString {
        let source = (try? Credits.text()) ?? "Acknowledgments could not be loaded. See ACKNOWLEDGMENTS.md in the source distribution."
        return (try? AttributedString(markdown: source, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(source)
    }
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView { Text(text).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading).padding(28) }
            if let folder = Bundle.main.resourceURL?.appendingPathComponent("Licenses"), FileManager.default.fileExists(atPath: folder.path) {
                Button("View bundled license files") { NSWorkspace.shared.open(folder) }.padding([.horizontal, .bottom], 28)
            }
        }.frame(minWidth: 500, minHeight: 400)
    }
}

struct AddProfileView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) var dismiss
    @StoredViewState<String> private var modelCode = "B155"
    @StoredViewState<String> private var profileName = "Nothing Ear (2)"
    @StoredViewState<String> private var identifier = "nothing-ear-2"
    @StoredViewState<String> private var names = "Nothing Ear (2)"
    @StoredViewState<String> private var author = ""
    @StoredViewState<String> private var source = "https://github.com/bestK1ngArthur/swift-nothing-ear"
    @StoredViewState<Set<String>> private var selected = ["battery", "anc", "eq"]
    @StoredViewState<String?> private var error = nil
    private var definition: DriverModel { DriverRegistry.models.first { $0.id == modelCode }! }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add device profile").font(.title2.weight(.semibold))
            Text("Choose a model the included driver understands. New profiles start as experimental; adding a profile does not verify the hardware.")
                .font(.callout).foregroundStyle(.secondary)
            Form {
                LabeledContent("Controls", value: definition.vendor)
                Picker("Hardware model", selection: $modelCode) {
                    ForEach(DriverRegistry.models) { item in Text("\(item.name) · \(item.id)").tag(item.id) }
                }.onChange(of: modelCode) {
                    profileName = definition.name; names = definition.name
                    identifier = definition.name.lowercased().replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: " ", with: "-")
                    selected = Set(definition.features); source = definition.source
                }
                TextField("Display name", text: $profileName)
                TextField("Unique profile ID", text: $identifier)
                TextField("Bluetooth names (one per line)", text: $names, axis: .vertical).lineLimit(2...3)
                Section("Available controls") {
                    ForEach(definition.features, id: \.self) { feature in
                        Toggle(DriverRegistry.featureNames[feature] ?? feature, isOn: Binding(
                            get: { selected.contains(feature) },
                            set: { if $0 { selected.insert(feature) } else { selected.remove(feature) } }
                        ))
                    }
                }
                Section("Give credit") {
                    TextField("Your public name or handle", text: $author)
                    TextField("Protocol / profile source URL", text: $source)
                    Text("License: GPL-3.0. Upstream driver authors are credited automatically.").font(.caption).foregroundStyle(.secondary)
                }
            }.formStyle(.grouped)
            if let error { Text(error).font(.caption).foregroundStyle(.red) }
            HStack {
                Text("Profiles use the drivers included in this app.").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Save profile", action: save).buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction)
                    .disabled(author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selected.isEmpty)
            }
        }.padding(24).frame(width: 590, height: 650)
    }

    private func save() {
        do {
            let credit = ProfileAttribution(authors: [author.trimmingCharacters(in: .whitespacesAndNewlines)] + definition.authors,
                source: source.trimmingCharacters(in: .whitespacesAndNewlines), license: "GPL-3.0",
                notes: "Created with OpenEars. Hardware validation pending. See ACKNOWLEDGMENTS.md for protocol lineage and original licenses.")
            let features = definition.features.filter { selected.contains($0) }.map {
                Feature(id: $0, name: DriverRegistry.featureNames[$0] ?? $0, status: .experimental, note: "Available in the driver; hardware validation pending.")
            }
            let profile = DeviceProfile(id: identifier.trimmingCharacters(in: .whitespacesAndNewlines),
                name: profileName.trimmingCharacters(in: .whitespacesAndNewlines), vendor: definition.vendor,
                driver: definition.driver, model: modelCode,
                names: names.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }, features: features, attribution: credit)
            try model.addProfiles([profile]); dismiss()
        } catch { self.error = error.localizedDescription }
    }
}
