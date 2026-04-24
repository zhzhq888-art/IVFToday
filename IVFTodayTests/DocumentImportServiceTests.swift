import XCTest
@testable import IVFToday

final class DocumentImportServiceTests: XCTestCase {
    func testImageImportUsesCacheForSamePayloadData() async throws {
        let ocr = MockOCRExtractor(rawText: "raw-ocr", normalizedText: "normalized-ocr")
        let pdf = MockPDFExtractor(rawText: "raw-pdf", normalizedText: "normalized-pdf")
        let cache = ImportExtractionCache()
        let service = DocumentImportService(ocrService: ocr, pdfService: pdf, cache: cache)

        let payloadA = ImportedDocumentPayload(
            id: UUID(),
            sourceType: .screenshot,
            displayName: "img-a",
            rawText: "",
            normalizedText: "",
            capturedAt: Date(),
            previewImageData: Data([0x01, 0x02, 0x03]),
            sourceURL: nil
        )
        let payloadB = ImportedDocumentPayload(
            id: UUID(),
            sourceType: .screenshot,
            displayName: "img-b",
            rawText: "",
            normalizedText: "",
            capturedAt: Date(),
            previewImageData: Data([0x01, 0x02, 0x03]),
            sourceURL: nil
        )

        let first = try await service.process(payloadA)
        let second = try await service.process(payloadB)

        XCTAssertEqual(first.rawText, "raw-ocr")
        XCTAssertEqual(second.rawText, "raw-ocr")
        let calls = await ocr.callCount
        XCTAssertEqual(calls, 1)
    }

    func testPdfImportUsesCacheForSameURLMetadata() async throws {
        let ocr = MockOCRExtractor(rawText: "raw-ocr", normalizedText: "normalized-ocr")
        let pdf = MockPDFExtractor(rawText: "raw-pdf", normalizedText: "normalized-pdf")
        let cache = ImportExtractionCache()
        let service = DocumentImportService(ocrService: ocr, pdfService: pdf, cache: cache)

        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("pdf")
        try Data("hello".utf8).write(to: fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let payloadA = ImportedDocumentPayload(
            id: UUID(),
            sourceType: .pdf,
            displayName: "A.pdf",
            rawText: "",
            normalizedText: "",
            capturedAt: Date(),
            previewImageData: nil,
            sourceURL: fileURL
        )
        let payloadB = ImportedDocumentPayload(
            id: UUID(),
            sourceType: .pdf,
            displayName: "B.pdf",
            rawText: "",
            normalizedText: "",
            capturedAt: Date(),
            previewImageData: nil,
            sourceURL: fileURL
        )

        _ = try await service.process(payloadA)
        _ = try await service.process(payloadB)

        let calls = await pdf.callCount
        XCTAssertEqual(calls, 1)
    }

    func testManualEntryImportDoesNotUseExtractors() async throws {
        let ocr = MockOCRExtractor(rawText: "raw-ocr", normalizedText: "normalized-ocr")
        let pdf = MockPDFExtractor(rawText: "raw-pdf", normalizedText: "normalized-pdf")
        let cache = ImportExtractionCache()
        let service = DocumentImportService(ocrService: ocr, pdfService: pdf, cache: cache)

        let payload = ImportedDocumentPayload(
            id: UUID(),
            sourceType: .manualEntry,
            displayName: "manual",
            rawText: "",
            normalizedText: "",
            capturedAt: Date(),
            previewImageData: nil,
            sourceURL: nil
        )

        let processed = try await service.process(payload)

        let ocrCalls = await ocr.callCount
        let pdfCalls = await pdf.callCount

        XCTAssertEqual(processed.rawText, "Manual entry")
        XCTAssertEqual(processed.normalizedText, "Manual entry")
        XCTAssertEqual(ocrCalls, 0)
        XCTAssertEqual(pdfCalls, 0)
    }

    func testLargePdfImportRemainsDeterministic() async throws {
        let ocr = MockOCRExtractor(rawText: "raw-ocr", normalizedText: "normalized-ocr")
        let repeatedLine = "Stim day instruction with follow-up details"
        let longText = Array(repeating: repeatedLine, count: 5000).joined(separator: "\n")
        let pdf = MockPDFExtractor(rawText: longText, normalizedText: longText)
        let cache = ImportExtractionCache()
        let service = DocumentImportService(ocrService: ocr, pdfService: pdf, cache: cache)

        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("pdf")
        try Data("pdf-placeholder".utf8).write(to: fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let payload = ImportedDocumentPayload(
            id: UUID(),
            sourceType: .pdf,
            displayName: "long.pdf",
            rawText: "",
            normalizedText: "",
            capturedAt: Date(),
            previewImageData: nil,
            sourceURL: fileURL
        )

        let processed = try await service.process(payload)

        let pdfCalls = await pdf.callCount
        let ocrCalls = await ocr.callCount

        XCTAssertEqual(pdfCalls, 1)
        XCTAssertEqual(ocrCalls, 0)
        XCTAssertEqual(processed.rawText.components(separatedBy: .newlines).count, 5000)
        XCTAssertEqual(processed.normalizedText.components(separatedBy: .newlines).count, 5000)
    }
}

private actor MockOCRExtractor: OCRTextExtracting {
    let rawText: String
    let normalizedText: String
    private(set) var callCount = 0

    init(rawText: String, normalizedText: String) {
        self.rawText = rawText
        self.normalizedText = normalizedText
    }

    func extractText(from payload: ImportedDocumentPayload) async throws -> ImportedDocumentPayload {
        callCount += 1
        var updated = payload
        updated.rawText = rawText
        updated.normalizedText = normalizedText
        return updated
    }
}

private actor MockPDFExtractor: PDFTextExtracting {
    let rawText: String
    let normalizedText: String
    private(set) var callCount = 0

    init(rawText: String, normalizedText: String) {
        self.rawText = rawText
        self.normalizedText = normalizedText
    }

    func extractText(from payload: ImportedDocumentPayload) async throws -> ImportedDocumentPayload {
        callCount += 1
        var updated = payload
        updated.rawText = rawText
        updated.normalizedText = normalizedText
        return updated
    }
}
