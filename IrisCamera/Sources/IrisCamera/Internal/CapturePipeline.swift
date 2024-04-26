import Foundation
import AVKit
import SwiftUI

@Observable
class CapturePipeline {
    let session: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        return session
    }()

    let output = VideoDataOutput()

    init() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else { fatalError() }

        session.addInput(input)


        guard session.canAddOutput(output.videoOutput)
        else { fatalError() }

        session.addOutput(output.videoOutput)
        output.videoOutput.setSampleBufferDelegate(output, queue: output.dataOutputQueue)
    }
}
