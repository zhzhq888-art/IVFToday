import SwiftUI

struct ImportPreviewView: View {
    @Environment(ThemeController.self) private var themeController
    let payload: ImportedDocumentPayload
    let onReviewExtractedText: (() -> Void)?

    private var theme: AppTheme.Palette {
        themeController.palette
    }

    var body: some View {
        List {
                Section("Source") {
                    HStack {
                        if payload.sourceType == .pdf {
                            Image(systemName: "doc.text.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(theme.secondaryAccent)
                                .clipShape(Circle())
                        } else if payload.sourceType == .screenshot || payload.sourceType == .photo {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(theme.info)
                                .clipShape(Circle())
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(sourceTypeName(for: payload.sourceType))
                                .font(.headline)
                            
                            Text(payload.displayName)
                                .font(.subheadline)
                                .foregroundColor(theme.mutedText)
                            
                            Text(dateString(for: payload.capturedAt))
                                .font(.caption)
                                .foregroundColor(theme.mutedText)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 6)
                    .listRowBackground(theme.sectionBackground)
                }
                
                Section("Preview") {
                    if let imageData = payload.previewImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else if payload.sourceType == .pdf {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 40))
                                .foregroundColor(theme.secondaryAccent)
                            
                            VStack(alignment: .leading) {
                                Text("PDF Document")
                                    .font(.headline)
                                Text(payload.displayName)
                                    .font(.subheadline)
                                    .foregroundColor(theme.mutedText)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(theme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .listRowBackground(theme.sectionBackground)
                
                Section("Extracted Text") {
                    if !payload.normalizedText.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Preview:")
                                .font(.caption)
                                .foregroundColor(theme.mutedText)
                            
                            Text(textSummary(of: payload.normalizedText))
                                .font(.body)
                                .lineLimit(5)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 4)
                    } else {
                        Text("No extracted text yet")
                            .font(.body)
                            .foregroundColor(theme.mutedText)
                            .italic()
                    }
                }
                .listRowBackground(theme.sectionBackground)
        }
        .navigationTitle("Import Preview")
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(theme.background)
        .toolbar {
            if let onReview = onReviewExtractedText {
                Button("Review Extracted Text") {
                    onReview()
                }
            }
        }
    }
    
    private func sourceTypeName(for type: DocumentSourceType) -> String {
        switch type {
        case .screenshot:
            return "Screenshot"
        case .photo:
            return "Photo"
        case .pdf:
            return "PDF"
        case .manualEntry:
            return "Manual Entry"
        }
    }
    
    private func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func textSummary(of text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        let firstFewLines = Array(lines.prefix(5))
        let summary = firstFewLines.joined(separator: "\n")
        
        if lines.count > 5 {
            return summary + "\n..."
        }
        return summary
    }
}

#Preview("Image Payload") {
    let samplePayload = ImportedDocumentPayload(
        id: UUID(),
        sourceType: .screenshot,
        displayName: "IMG_1234.png",
        rawText: "Morning injection: 250 IU\nEvening: rest day\nNext scan: Apr 16",
        normalizedText: "Morning injection: 250 IU\nEvening: rest day\nNext scan: Apr 16",
        capturedAt: Date(),
        previewImageData: nil, // Preview won't show image without real data
        sourceURL: nil
    )
    
    ImportPreviewView(payload: samplePayload, onReviewExtractedText: {})
        .environment(ThemeController())
}

#Preview("PDF Payload") {
    let samplePayload = ImportedDocumentPayload(
        id: UUID(),
        sourceType: .pdf,
        displayName: "IVF_Protocol.pdf",
        rawText: "Day 1: Start stimulation\nDay 3: Blood test\nDay 5: Scan",
        normalizedText: "Day 1: Start stimulation\nDay 3: Blood test\nDay 5: Scan",
        capturedAt: Date(),
        previewImageData: nil,
        sourceURL: nil
    )
    
    ImportPreviewView(payload: samplePayload, onReviewExtractedText: {})
        .environment(ThemeController())
}

#Preview("Empty Text") {
    let samplePayload = ImportedDocumentPayload(
        id: UUID(),
        sourceType: .pdf,
        displayName: "Empty_Document.pdf",
        rawText: "",
        normalizedText: "",
        capturedAt: Date(),
        previewImageData: nil,
        sourceURL: nil
    )
    
    ImportPreviewView(payload: samplePayload, onReviewExtractedText: {})
        .environment(ThemeController())
}
