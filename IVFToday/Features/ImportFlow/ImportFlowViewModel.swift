import Foundation
import SwiftUI
import PhotosUI

@Observable
@MainActor
class ImportFlowViewModel {
    private let importService = DocumentImportService()
    private var importTask: Task<Void, Never>?
    private var currentImportID: UUID?
    
    enum Stage {
        case idle
        case loading
        case preview(ImportedDocumentPayload)
        case error(String)
    }
    
    var stage: Stage = .idle
    
    // Computed properties for backward compatibility with existing view bindings
    var isImporting: Bool {
        if case .loading = stage { return true }
        return false
    }
    
    var errorMessage: String? {
        if case .error(let message) = stage { return message }
        return nil
    }
    
    var importedPayload: ImportedDocumentPayload? {
        if case .preview(let payload) = stage { return payload }
        return nil
    }
    
    // MARK: - Actions
    
    func reset() {
        cancelCurrentImport()
        stage = .idle
    }
    
    func clearError() {
        if case .error = stage {
            stage = .idle
        }
    }
    
    // MARK: - Image Import
    
    var selectedImageItem: PhotosPickerItem? {
        didSet {
            guard let item = selectedImageItem else { return }
            startImageImport(from: item)
        }
    }
    
    private func startImageImport(from item: PhotosPickerItem) {
        let importID = beginImport()
        
        importTask = Task { [weak self] in
            guard let self else { return }
            guard !Task.isCancelled else { return }
            
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    throw ImageImportError.failedToLoadData
                }
                guard !Task.isCancelled else { return }
                
                let displayName = "Screenshot"
                
                var payload = ImportedDocumentPayload(
                    id: UUID(),
                    sourceType: .screenshot,
                    displayName: displayName,
                    rawText: "",
                    normalizedText: "",
                    capturedAt: Date(),
                    previewImageData: data,
                    sourceURL: nil
                )
                
                payload = try await importService.process(payload)
                guard !Task.isCancelled else { return }
                
                self.finishImportIfCurrent(id: importID, stage: .preview(payload))
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                self.finishImportIfCurrent(id: importID, stage: .error("Image import failed: \(error.localizedDescription)"))
            }
        }
    }
    
    // MARK: - PDF Import
    
    var selectedFileURL: URL? {
        didSet {
            guard let url = selectedFileURL else { return }
            startPDFImport(from: url)
        }
    }
    
    private func startPDFImport(from url: URL) {
        let importID = beginImport()
        
        // Validate it's a PDF by extension (basic check)
        let pathExtension = url.pathExtension.lowercased()
        if pathExtension != "pdf" {
            finishImportIfCurrent(id: importID, stage: .error("Selected file is not a PDF."))
            return
        }
        
        importTask = Task { [weak self] in
            guard let self else { return }
            guard !Task.isCancelled else { return }
            
            let hasSecurityScopedAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasSecurityScopedAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            // If we couldn't obtain security-scoped access, only proceed if the file is otherwise readable.
            if !hasSecurityScopedAccess && !FileManager.default.isReadableFile(atPath: url.path) {
                self.finishImportIfCurrent(
                    id: importID,
                    stage: .error("Cannot access selected PDF from Files. Please re-select it or move it to an accessible location.")
                )
                return
            }

            do {
                var payload = ImportedDocumentPayload(
                    id: UUID(),
                    sourceType: .pdf,
                    displayName: url.lastPathComponent,
                    rawText: "",
                    normalizedText: "",
                    capturedAt: Date(),
                    previewImageData: nil,
                    sourceURL: url
                )
                
                payload = try await importService.process(payload)
                guard !Task.isCancelled else { return }
                
                self.finishImportIfCurrent(id: importID, stage: .preview(payload))
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                self.finishImportIfCurrent(id: importID, stage: .error("PDF import failed: \(error.localizedDescription)"))
            }
        }
    }
    
    private func beginImport() -> UUID {
        cancelCurrentImport()
        let importID = UUID()
        currentImportID = importID
        stage = .loading
        return importID
    }
    
    private func cancelCurrentImport() {
        importTask?.cancel()
        importTask = nil
    }
    
    private func finishImportIfCurrent(id: UUID, stage: Stage) {
        guard currentImportID == id else { return }
        self.stage = stage
        importTask = nil
    }
    
    // MARK: - Errors
    
    enum ImageImportError: LocalizedError {
        case failedToLoadData
        
        var errorDescription: String? {
            switch self {
            case .failedToLoadData:
                return "Failed to load image data from selection."
            }
        }
    }
}
