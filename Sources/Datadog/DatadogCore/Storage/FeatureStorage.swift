/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation

internal struct FeatureStorage {
    /// Writes data to files. This `Writer` takes current value of the `TrackingConsent` into consideration
    /// to decided if the data should be written to authorized or unauthorized folder.
    let writer: AsyncWriter
    /// Reads data from files in authorized folder.
    let reader: SyncReader

    /// An arbitrary `Writer` which always writes data to authorized folder.
    /// Should be only used by components which implement their own consideration of the `TrackingConsent` value
    /// associated with data written (e.g. crash reporting integration which saves the consent value along with the crash report).
    let arbitraryAuthorizedWriter: AsyncWriter

    /// Orchestrates contents of both `.pending` and `.granted` directories.
    let dataOrchestrator: DataOrchestratorType

    init(
        featureName: String,
        queue: DispatchQueue,
        directories: FeatureDirectories,
        dateProvider: DateProvider,
        consentProvider: ConsentProvider,
        performance: PerformancePreset,
        encryption: DataEncryption?
    ) {
        let authorizedFilesOrchestrator = FilesOrchestrator(
            directory: directories.authorized,
            performance: performance,
            dateProvider: dateProvider
        )
        let unauthorizedFilesOrchestrator = FilesOrchestrator(
            directory: directories.unauthorized,
            performance: performance,
            dateProvider: dateProvider
        )

        let dataOrchestrator = DataOrchestrator(
            queue: queue,
            authorizedFilesOrchestrator: authorizedFilesOrchestrator,
            unauthorizedFilesOrchestrator: unauthorizedFilesOrchestrator
        )

        let unauthorizedFileWriter = FileWriter(
            orchestrator: unauthorizedFilesOrchestrator,
            encryption: encryption
        )

        let authorizedFileWriter = FileWriter(
            orchestrator: authorizedFilesOrchestrator,
            encryption: encryption
        )

        let consentAwareDataWriter = ConsentAwareDataWriter(
            consentProvider: consentProvider,
            readWriteQueue: queue,
            unauthorizedWriter: unauthorizedFileWriter,
            authorizedWriter: authorizedFileWriter,
            dataMigratorFactory: DataMigratorFactory(
                directories: directories
            )
        )

        let arbitraryDataWriter = ArbitraryDataWriter(
            readWriteQueue: queue,
            writer: authorizedFileWriter
        )

        let authorisedDataReader = DataReader(
            readWriteQueue: queue,
            fileReader: FileReader(
                orchestrator: authorizedFilesOrchestrator,
                encryption: encryption
            )
        )

        self.init(
            writer: consentAwareDataWriter,
            reader: authorisedDataReader,
            arbitraryAuthorizedWriter: arbitraryDataWriter,
            dataOrchestrator: dataOrchestrator
        )
    }

    init(
        writer: AsyncWriter,
        reader: SyncReader,
        arbitraryAuthorizedWriter: AsyncWriter,
        dataOrchestrator: DataOrchestratorType
    ) {
        self.writer = writer
        self.reader = reader
        self.arbitraryAuthorizedWriter = arbitraryAuthorizedWriter
        self.dataOrchestrator = dataOrchestrator
    }

    func clearAllData() {
        dataOrchestrator.deleteAllData()
    }

    /// Flushes all async write operations and tears down the storage stack.
    /// - It completes all async writes by synchronously saving data to authorized files.
    /// - It cancels the storage by preventing all future write operations and marking all authorised files as "ready for upload".
    ///
    /// This method is executed synchronously. After return, the storage feature has no more
    /// pending asynchronous write operations so all its data is ready for upload.
    internal func flushAndTearDown() {
        writer.flushAndCancelSynchronously()
        arbitraryAuthorizedWriter.flushAndCancelSynchronously()
        (dataOrchestrator as? DataOrchestrator)?.markAllFilesAsReadable()
    }
}
