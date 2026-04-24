import Foundation

/// Unified output model for both image OCR and PDF text extraction.
/// Represents raw document content before any business parsing.
struct ImportedDocumentPayload: Equatable {
    /// Unique identifier for this imported document
    let id: UUID
    
    /// Type of source (uses shared DocumentSourceType)
    let sourceType: DocumentSourceType
    
    /// User-facing name (e.g., filename or "Screenshot")
    let displayName: String
    
    /// Raw extracted text, exactly as obtained from source
    var rawText: String
    
    /// Minimally normalized text (whitespace cleaned, empty lines removed)
    var normalizedText: String
    
    /// Timestamp when the document was captured/imported
    let capturedAt: Date
    
    /// Optional preview image data (for image/photo sources; nil for PDFs)
    let previewImageData: Data?
    
    /// Optional source URL (e.g., file URL for PDF; nil for in-memory images)
    let sourceURL: URL?
}