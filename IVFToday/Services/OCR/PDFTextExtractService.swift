import Foundation
import PDFKit

struct PDFTextExtractService {
    /// Extracts text from a PDF file at the given URL using PDFKit.
    /// - Parameter payload: Must have non-nil `sourceURL` pointing to a valid PDF
    /// - Returns: Updated payload with `rawText` and `normalizedText` populated from PDF content
    func extractText(from payload: ImportedDocumentPayload) async throws -> ImportedDocumentPayload {
        guard let url = payload.sourceURL else {
            throw ExtractionError.missingSourceURL
        }
        
        // Check if file is accessible
        guard FileManager.default.isReadableFile(atPath: url.path) else {
            throw ExtractionError.fileNotAccessible
        }
        
        // Initialize PDF document
        guard let pdfDocument = PDFDocument(url: url) else {
            throw ExtractionError.invalidPDF
        }
        
        // Extract text from all pages
        var allTextLines: [String] = []
        
        for pageIndex in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: pageIndex) {
                let pageText = page.string ?? ""
                let pageLines = pageText.components(separatedBy: .newlines)
                allTextLines.append(contentsOf: pageLines)
                
                // Add a blank line between pages for readability (except after last page)
                if pageIndex < pdfDocument.pageCount - 1 {
                    allTextLines.append("")
                }
            }
        }
        
        let rawText = allTextLines.joined(separator: "\n")
        
        if rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ExtractionError.noTextDetected
        }
        
        // Apply minimal normalization
        let normalized = normalize(text: rawText)
        
        var updated = payload
        updated.rawText = rawText
        updated.normalizedText = normalized
        return updated
    }
    
    private func normalize(text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }  // Trim each line
            .filter { !$0.isEmpty }                           // Remove empty lines
        
        // Optional: collapse multiple consecutive blank lines into one
        // But since we already removed empty lines, this is not needed here
        // If we wanted to preserve some paragraph breaks, we'd do it differently
        
        return lines.joined(separator: "\n")
    }
    
    enum ExtractionError: LocalizedError {
        case missingSourceURL
        case fileNotAccessible
        case invalidPDF
        case noTextDetected
        
        var errorDescription: String? {
            switch self {
            case .missingSourceURL:
                return "PDF file URL is missing for text extraction."
            case .fileNotAccessible:
                return "Cannot access the PDF file at the provided URL."
            case .invalidPDF:
                return "The file is not a valid PDF document."
            case .noTextDetected:
                return "No extractable text was found in the PDF."
            }
        }
    }
}