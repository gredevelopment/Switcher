import Foundation

@MainActor
final class ICloudDocumentStore: NSObject {
    typealias ChangeHandler = (String) -> Void

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let localDirectory: URL
    private var metadataQuery: NSMetadataQuery?
    private var changeHandler: ChangeHandler?
    private var isSynchronizing = false

    override init() {
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        decoder = JSONDecoder()

        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        localDirectory = appSupport.appendingPathComponent("Switcher", isDirectory: true)
        try? fileManager.createDirectory(at: localDirectory, withIntermediateDirectories: true)

        super.init()
    }

    func startObservingChanges(_ handler: @escaping ChangeHandler) {
        changeHandler = handler

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ubiquityIdentityDidChange),
            name: .NSUbiquityIdentityDidChange,
            object: nil
        )

        Task {
            await startMetadataQueryIfNeeded()
        }
    }

    func loadLocal<T: Decodable>(_ type: T.Type, from filename: String) -> T? {
        let localURL = localDocumentURL(for: filename)
        guard let data = try? Data(contentsOf: localURL) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    func saveLocal<T: Encodable>(_ value: T, to filename: String) {
        guard let data = try? encoder.encode(value) else { return }
        let localURL = localDocumentURL(for: filename)
        try? data.write(to: localURL, options: .atomic)
    }

    func save<T: Encodable>(_ value: T, to filename: String) {
        guard let data = try? encoder.encode(value) else { return }
        saveLocal(value, to: filename)

        Task {
            await uploadToICloud(filename: filename, data: data)
        }
    }

    func synchronizeWithICloud() async {
        guard !isSynchronizing else { return }
        isSynchronizing = true
        defer { isSynchronizing = false }

        guard let cloudDocumentsDirectory = await Self.cloudDocumentsDirectory() else { return }

        for filename in [AppConstants.projectsDocumentName, AppConstants.settingsDocumentName] {
            await synchronizeFile(named: filename, in: cloudDocumentsDirectory)
        }
    }

    // MARK: - Private

    private func localDocumentURL(for filename: String) -> URL {
        localDirectory.appendingPathComponent(filename)
    }

    private nonisolated static func cloudDocumentsDirectory() async -> URL? {
        await Task.detached {
            let fileManager = FileManager.default
            guard let containerURL = fileManager.url(
                forUbiquityContainerIdentifier: AppConstants.iCloudContainerIdentifier
            ) else {
                return nil
            }

            let documentsURL = containerURL.appendingPathComponent("Documents", isDirectory: true)
            try? fileManager.createDirectory(at: documentsURL, withIntermediateDirectories: true)
            return documentsURL
        }.value
    }

    private func synchronizeFile(named filename: String, in cloudDocumentsDirectory: URL) async {
        let localURL = localDocumentURL(for: filename)
        let cloudURL = cloudDocumentsDirectory.appendingPathComponent(filename)
        let localExists = fileManager.fileExists(atPath: localURL.path)
        let cloudExists = fileManager.fileExists(atPath: cloudURL.path)

        switch (localExists, cloudExists) {
        case (false, false):
            return
        case (true, false):
            await uploadToICloud(filename: filename, data: try? Data(contentsOf: localURL))
        case (false, true):
            if let data = await readCloudData(from: cloudURL) {
                try? data.write(to: localURL, options: .atomic)
                notifyChange(for: filename)
            }
        case (true, true):
            let localDate = modificationDate(for: localURL) ?? .distantPast
            let cloudDate = modificationDate(for: cloudURL) ?? .distantPast

            if cloudDate > localDate {
                if let data = await readCloudData(from: cloudURL) {
                    try? data.write(to: localURL, options: .atomic)
                    notifyChange(for: filename)
                }
            } else if localDate > cloudDate {
                await uploadToICloud(filename: filename, data: try? Data(contentsOf: localURL))
            }
        }
    }

    private func uploadToICloud(filename: String, data: Data?) async {
        guard let data else { return }
        guard let cloudDocumentsDirectory = await Self.cloudDocumentsDirectory() else { return }

        let cloudURL = cloudDocumentsDirectory.appendingPathComponent(filename)
        let localURL = localDocumentURL(for: filename)

        if !fileManager.fileExists(atPath: cloudURL.path) {
            try? data.write(to: localURL, options: .atomic)
            do {
                try fileManager.setUbiquitous(true, itemAt: localURL, destinationURL: cloudURL)
            } catch {
                try? data.write(to: cloudURL, options: .atomic)
            }
            return
        }

        var coordinationError: NSError?
        let coordinator = NSFileCoordinator(filePresenter: nil)
        coordinator.coordinate(
            writingItemAt: cloudURL,
            options: .forReplacing,
            error: &coordinationError
        ) { url in
            try? data.write(to: url, options: .atomic)
        }
    }

    private func readCloudData(from url: URL) async -> Data? {
        await Task.detached {
            let fileManager = FileManager.default
            if fileManager.isUbiquitousItem(at: url) {
                try? fileManager.startDownloadingUbiquitousItem(at: url)
            }
            return try? Data(contentsOf: url)
        }.value
    }

    private func modificationDate(for url: URL) -> Date? {
        try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }

    private func notifyChange(for filename: String) {
        changeHandler?(filename)
    }

    private func startMetadataQueryIfNeeded() async {
        guard fileManager.ubiquityIdentityToken != nil else { return }

        metadataQuery?.stop()
        metadataQuery = nil

        let query = NSMetadataQuery()
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        query.predicate = NSPredicate(
            format: "%K == %@ OR %K == %@",
            NSMetadataItemFSNameKey, AppConstants.projectsDocumentName,
            NSMetadataItemFSNameKey, AppConstants.settingsDocumentName
        )
        query.operationQueue = .main

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(metadataQueryDidUpdate),
            name: .NSMetadataQueryDidUpdate,
            object: query
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(metadataQueryDidFinishGathering),
            name: .NSMetadataQueryDidFinishGathering,
            object: query
        )

        query.start()
        metadataQuery = query
    }

    @objc private func metadataQueryDidFinishGathering(_ notification: Notification) {
        guard let query = notification.object as? NSMetadataQuery else { return }
        query.disableUpdates()
        query.stop()
        query.enableUpdates()

        Task {
            await synchronizeWithICloud()
        }
    }

    @objc private func metadataQueryDidUpdate(_ notification: Notification) {
        guard !isSynchronizing else { return }

        Task {
            await synchronizeWithICloud()
        }
    }

    @objc private func ubiquityIdentityDidChange(_ notification: Notification) {
        Task {
            await startMetadataQueryIfNeeded()
            await synchronizeWithICloud()
        }
    }
}
