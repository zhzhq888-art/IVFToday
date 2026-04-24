import XCTest
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
@testable import IVFToday

final class OCRServiceTests: XCTestCase {
    func testBlurredScreenshotStillExtractsMedicationName() async throws {
        let sourceImage = makeMedicationScreenshot(
            lines: [
                "Gonal-F 225 IU at 8:00 PM",
                "Cetrotide 0.25 mg at 7:30 AM"
            ]
        )
        let blurredImage = try makeBlurredImage(from: sourceImage, radius: 1.8)
        guard let imageData = blurredImage.pngData() else {
            XCTFail("Expected PNG data for blurred screenshot")
            return
        }

        let payload = ImportedDocumentPayload(
            id: UUID(),
            sourceType: .screenshot,
            displayName: "blurred-screenshot.png",
            rawText: "",
            normalizedText: "",
            capturedAt: Date(),
            previewImageData: imageData,
            sourceURL: nil
        )

        let processed = try await OCRService().extractText(from: payload)

        XCTAssertFalse(processed.rawText.isEmpty)
        XCTAssertTrue(
            processed.normalizedText.localizedCaseInsensitiveContains("gonal"),
            "Expected OCR output to retain the key medication name from a blurred screenshot."
        )
    }

    private func makeMedicationScreenshot(lines: [String]) -> UIImage {
        let rendererFormat = UIGraphicsImageRendererFormat()
        rendererFormat.scale = 3
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1600, height: 1200), format: rendererFormat)

        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1600, height: 1200))

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 18

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 76, weight: .bold),
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]

            let text = lines.joined(separator: "\n")
            text.draw(
                in: CGRect(x: 96, y: 120, width: 1400, height: 900),
                withAttributes: attributes
            )
        }
    }

    private func makeBlurredImage(from image: UIImage, radius: Double) throws -> UIImage {
        guard let inputImage = CIImage(image: image) else {
            throw TestError.invalidImage
        }

        let filter = CIFilter.gaussianBlur()
        filter.inputImage = inputImage
        filter.radius = Float(radius)

        let context = CIContext()
        let outputExtent = inputImage.extent
        guard
            let outputImage = filter.outputImage?.cropped(to: outputExtent),
            let cgImage = context.createCGImage(outputImage, from: outputExtent)
        else {
            throw TestError.failedToBlurImage
        }

        return UIImage(cgImage: cgImage)
    }

    private enum TestError: Error {
        case invalidImage
        case failedToBlurImage
    }
}
