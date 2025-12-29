//
//  OCRService.swift
//  Prism
//
//  Created by Brian Zhu on 2025/12/28.
//

import UIKit
import Vision

// MARK: - OCR Service Protocol

protocol OCRServiceProtocol {
    func recognizeText(image: UIImage) async throws -> String
}

// MARK: - OCR Error

enum OCRError: LocalizedError {
    case imageConversionFailed
    case noTextRecognized
    case recognitionFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image for processing"
        case .noTextRecognized:
            return "No text was recognized in the image"
        case .recognitionFailed(let error):
            return "Text recognition failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Vision OCR Service Implementation

final class VisionOCRService: OCRServiceProtocol {
    
    func recognizeText(image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.imageConversionFailed
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextRecognized)
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                print("🔍 [OCRService] Found \\(observations.count) text observations")
                print("🔍 [OCRService] Extracted \\(recognizedStrings.count) text strings")
                
                if recognizedStrings.isEmpty {
                    continuation.resume(throwing: OCRError.noTextRecognized)
                } else {
                    let fullText = recognizedStrings.joined(separator: "\n")
                    print("🔍 [OCRService] Total text length: \\(fullText.count) characters")
                    continuation.resume(returning: fullText)
                }
            }
            
            // Configure for accurate recognition
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.recognitionFailed(error))
            }
        }
    }
}
