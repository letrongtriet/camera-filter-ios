import AVKit
import CoreImage
import Foundation

struct SampleBufferTransformer {
    func transform(videoSampleBuffer: CMSampleBuffer) -> CMSampleBuffer {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(videoSampleBuffer) else {
            print("failed to get pixel buffer")
            fatalError()
        }

        #warning("Implementation to invert colors in pixel buffer")


        guard let result = try? pixelBuffer.mapToSampleBuffer(timestamp: videoSampleBuffer.presentationTimeStamp) else {
            fatalError()
        }

        return result
    }
}
