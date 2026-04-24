import SwiftUI
import PhotosUI

struct ImportSourceView: View {
    @Environment(ThemeController.self) private var themeController
    @Bindable var appState: AppState
    @State private var viewModel = ImportFlowViewModel()
    @State private var isShowingPDFImporter = false
    @State private var reviewPayload: ImportedDocumentPayload?
    @State private var isShowingParsedReview = false

    private var theme: AppTheme.Palette {
        themeController.palette
    }

    var body: some View {
        List {
            if case .idle = viewModel.stage {
                Section("No document selected") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Import a screenshot from Photos or a PDF from Files.", systemImage: "square.and.arrow.down")
                        Label("Review extracted text before applying changes.", systemImage: "checklist")
                        Label("All processing stays on this device.", systemImage: "lock.shield")
                    }
                    .font(.subheadline)
                    .foregroundColor(theme.mutedText)
                    .padding(.vertical, 4)
                    .accessibilityIdentifier("import.empty-state")
                    .listRowBackground(theme.sectionBackground)
                }
            }

            if case .preview(let payload) = viewModel.stage {
                Section("Selected Document") {
                    HStack {
                        if payload.sourceType == .pdf {
                            Image(systemName: "doc.text.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(theme.secondaryAccent)
                                .clipShape(Circle())
                        } else if let imageData = payload.previewImageData,
                                  let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(payload.displayName)
                                .font(.headline)
                            if payload.sourceType == .pdf {
                                Text("PDF loaded")
                                    .font(.caption)
                                    .foregroundColor(theme.mutedText)
                            } else {
                                Text("Image loaded")
                                    .font(.caption)
                                    .foregroundColor(theme.mutedText)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(theme.sectionBackground)
                }
            }
            
            Section("Choose how to import your IVF instructions") {
                PhotosPicker(
                    selection: $viewModel.selectedImageItem,
                    matching: .images
                ) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(theme.info)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Import Screenshot")
                                .font(.headline)
                            Text("From Photos app")
                                .font(.caption)
                                .foregroundColor(theme.mutedText)
                        }
                        
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(theme.mutedText)
                    }
                    .padding(.vertical, 8)
                }
                .accessibilityIdentifier("import.source.screenshot")
                .listRowBackground(theme.sectionBackground)
                
                Button {
                    isShowingPDFImporter = true
                } label: {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(theme.secondaryAccent)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Import PDF")
                                .font(.headline)
                            Text("From Files app")
                                .font(.caption)
                                .foregroundColor(theme.mutedText)
                        }
                        
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(theme.mutedText)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("import.source.pdf")
                .listRowBackground(theme.sectionBackground)
            }
            
            if case .error(let message) = viewModel.stage {
                Section {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(theme.critical)
                        .multilineTextAlignment(.center)
                }
                .listRowBackground(theme.sectionBackground)
            }
            
            Section {
                Text("OCR and PDF extraction happen locally on device")
                    .font(.caption)
                    .foregroundColor(theme.mutedText)
                    .multilineTextAlignment(.center)
            }
            .listRowBackground(theme.sectionBackground)

            Section("Safety") {
                SafetyNoticeCard(
                    title: "Confirm with clinic before action",
                    message: "Extraction can miss context. Always verify doses and timing against your clinic instructions.",
                    theme: theme
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(theme.background)
            }
        }
        .navigationTitle("Import Instructions")
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(theme.background)
        .fileImporter(
            isPresented: $isShowingPDFImporter,
            allowedContentTypes: [.pdf],
            onCompletion: { result in
                switch result {
                case .success(let url):
                    viewModel.selectedFileURL = url
                case .failure(let error):
                    viewModel.stage = .error("PDF selection failed: \(error.localizedDescription)")
                }
            }
        )
        .navigationDestination(isPresented: Binding(
            get: {
                if case .preview = viewModel.stage { return true }
                return false
            },
            set: { isPresented in
                if !isPresented {
                    viewModel.reset()
                }
            }
        )) {
            if case .preview(let payload) = viewModel.stage {
                ImportPreviewView(
                    payload: payload,
                    onReviewExtractedText: {
                        reviewPayload = payload
                        isShowingParsedReview = true
                    }
                )
            }
        }
        .navigationDestination(isPresented: $isShowingParsedReview) {
            if let payload = reviewPayload {
                ParsedProtocolView(payload: payload, appState: appState)
            }
        }
        .overlay {
            if viewModel.isImporting {
                ProgressView("Processing document…")
                    .progressViewStyle(.circular)
                    .padding()
                    .background(theme.sectionBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
}

#Preview {
    ImportSourceView(appState: DemoDataFactory.createAppState())
        .environment(ThemeController())
}
