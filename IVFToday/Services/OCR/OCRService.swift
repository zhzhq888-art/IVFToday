import Foundation
import Vision
import UIKit

struct OCRService {
    /// Extracts text from image data using Vision framework.
    /// - Parameter payload: Must have non-nil `previewImageData`
    /// - Returns: Updated payload with `rawText` and `normalizedText` populated from OCR
    func extractText(from payload: ImportedDocumentPayload) async throws -> ImportedDocumentPayload {
        guard let imageData = payload.previewImageData else {
            throw ExtractionError.missingImageData
        }
        
        guard let uiImage = UIImage(data: imageData) else {
            throw ExtractionError.invalidImageData
        }
        
        guard let cgImage = uiImage.cgImage else {
            throw ExtractionError.invalidCGImage
        }
        
        let request = VNRecognizeTextRequest { request, error in
            // Completion handler is not used; we use async/await pattern below
        }
        
        // Use accurate recognition level for better results
        request.recognitionLevel = .accurate
        // Default language (system language); can be customized later if needed
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        var recognizedText = ""
        
        do {
            try handler.perform([request])
            
            // Sort observations by vertical position (top to bottom), then horizontal (left to right)
            let sortedResults = request.results?.sorted(by: { (obs1, obs2) -> Bool in
                let box1 = obs1.boundingBox
                let box2 = obs2.boundingBox
                
                // Compare Y (inverted because Vision uses bottom-left origin)
                if abs(box1.origin.y - box2.origin.y) > 0.01 {
                    return box1.origin.y > box2.origin.y
                }
                // Same line: compare X
                return box1.origin.x < box2.origin.x
            }) as? [VNRecognizedTextObservation]
            
            if let results = sortedResults {
                let lines = results.compactMap { observation in
                    observation.topCandidates(1).first?.string.trimmingCharacters(in: .whitespacesAndNewlines)
                }.filter { !$0.isEmpty }
                
                recognizedText = lines.joined(separator: "\n")
            }
            
            if recognizedText.isEmpty {
                throw ExtractionError.noTextDetected
            }
            
            // Apply minimal normalization
            let normalized = normalize(text: recognizedText)
            
            var updated = payload
            updated.rawText = recognizedText
            updated.normalizedText = normalized
            return updated
            
        } catch {
            if error is CancellationError {
                throw error
            }
            throw ExtractionError.visionRequestFailed(error)
        }
    }
    
    private func normalize(text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }  // Trim each line
            .filter { !$0.isEmpty }                           // Remove empty lines
        return lines.joined(separator: "\n")
    }
    
    enum ExtractionError: LocalizedError {
        case missingImageData
        case invalidImageData
        case invalidCGImage
        case noTextDetected
        case visionRequestFailed(Error)
        
        var errorDescription: String? {
            switch self {
            case .missingImageData:
                return "Image data is missing for OCR processing."
            case .invalidImageData:
                return "Failed to decode image data."
            case .invalidCGImage:
                return "Failed to convert image to CGImage."
            case .noTextDetected:
                return "No text was detected in the image."
            case .visionRequestFailed(let underlyingError):
                return "Vision OCR request failed: \(underlyingError.localizedDescription)"
            }
        }
    }
}
