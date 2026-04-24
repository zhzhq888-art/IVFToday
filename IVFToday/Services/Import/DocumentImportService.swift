import Foundation
import CryptoKit

protocol OCRTextExtracting {
    func extractText(from payload: ImportedDocumentPayload) async throws -> ImportedDocumentPayload
}

protocol PDFTextExtracting {
    func extractText(from payload: ImportedDocumentPayload) async throws -> ImportedDocumentPayload
}

extension OCRService: OCRTextExtracting {}
extension PDFTextExtractService: PDFTextExtracting {}

actor ImportExtractionCache {
    static let shared = ImportExtractionCache()

    private struct CachedText {
        let rawText: String
        let normalizedText: String
    }

    private var storage: [String: CachedText] = [:]

    func text(for key: String) -> (rawText: String, normalizedText: String)? {
        guard let cached = storage[key] else { return nil }
        return (cached.rawText, cached.normalizedText)
    }

    func store(rawText: String, normalizedText: String, for key: String) {
        storage[key] = CachedText(rawText: rawText, normalizedText: normalizedText)
    }
}

struct DocumentImportService {
    private let ocrService: OCRTextExtracting
    private let pdfService: PDFTextExtracting
    private let cache: ImportExtractionCache

    init(
        ocrService: OCRTextExtracting = OCRService(),
        pdfService: PDFTextExtracting = PDFTextExtractService(),
        cache: ImportExtractionCache = .shared
    ) {
        self.ocrService = ocrService
        self.pdfService = pdfService
        self.cache = cache
    }
    
    /// Processes an imported document payload by dispatching to the appropriate extraction service.
    /// - Parameter payload: The payload from image or PDF import
    /// - Returns: Updated payload with extracted text fields populated
    /// - Throws: If source type is unsupported or required data is missing
    func process(_ payload: ImportedDocumentPayload) async throws -> ImportedDocumentPayload {
        if let cacheKey = cacheKey(for: payload),
           let cachedText = await cache.text(for: cacheKey) {
            var cachedPayload = payload
            cachedPayload.rawText = cachedText.rawText
            cachedPayload.normalizedText = cachedText.normalizedText
            return cachedPayload
        }

        let extractedPayload: ImportedDocumentPayload
        switch payload.sourceType {
        case .screenshot, .photo:
            extractedPayload = try await ocrService.extractText(from: payload)
            
        case .pdf:
            extractedPayload = try await pdfService.extractText(from: payload)
            
        case .manualEntry:
            // Manual entry doesn't need extraction
            var updated = payload
            if updated.rawText.isEmpty {
                updated.rawText = "Manual entry"
                updated.normalizedText = "Manual entry"
            }
            extractedPayload = updated
        }

        if let cacheKey = cacheKey(for: payload) {
            await cache.store(
                rawText: extractedPayload.rawText,
                normalizedText: extractedPayload.normalizedText,
                for: cacheKey
            )
        }
        return extractedPayload
    }

    private func cacheKey(for payload: ImportedDocumentPayload) -> String? {
        switch payload.sourceType {
        case .screenshot, .photo:
            guard let imageData = payload.previewImageData else { return nil }
            let digest = SHA256.hash(data: imageData)
            return "img:\(digest.compactMap { String(format: "%02x", $0) }.joined())"
        case .pdf:
            guard let sourceURL = payload.sourceURL else { return nil }
            let values = try? sourceURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
            let fileSize = values?.fileSize ?? 0
            let modifiedAt = values?.contentModificationDate?.timeIntervalSince1970 ?? 0
            return "pdf:\(sourceURL.path)|\(fileSize)|\(Int(modifiedAt))"
        case .manualEntry:
            return nil
        }
    }
}
