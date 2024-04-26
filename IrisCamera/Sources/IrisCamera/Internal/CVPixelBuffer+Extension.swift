import CoreMedia

// Helper to convert `CVPixelBuffer` to `CMSampleBuffer`
extension CVPixelBuffer {
    func mapToSampleBuffer(timestamp: CMTime) throws -> CMSampleBuffer {
        var sampleBuffer: CMSampleBuffer?
        var timimgInfo = CMSampleTimingInfo(duration: CMTime.invalid,
                                            presentationTimeStamp: timestamp,
                                            decodeTimeStamp: CMTime.invalid)
        var formatDescription: CMFormatDescription? = nil

        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                     imageBuffer: self,
                                                     formatDescriptionOut: &formatDescription)
        guard let formatDescription = formatDescription else {
            throw MapToSampleBufferError.failedToCreateBuffer("Cannot create format description")
        }

        let osStatus = CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: self,
            formatDescription: formatDescription,
            sampleTiming: &timimgInfo,
            sampleBufferOut: &sampleBuffer
        )

        if let error = CVBuffer.osStatusErrors[osStatus] {
            throw MapToSampleBufferError.failedToCreateBuffer("osStatus == \(error)")
        }

        guard let buffer = sampleBuffer else {
            throw MapToSampleBufferError.failedToCreateBuffer("Cannot create sample buffer")
        }
        return buffer
    }

    enum MapToSampleBufferError: LocalizedError {
        case failedToCreateBuffer(String)
    }

    static let osStatusErrors: [OSStatus: String] = [
        kCMSampleBufferError_AllocationFailed: "kCMSampleBufferError_AllocationFailed",
        kCMSampleBufferError_RequiredParameterMissing: "kCMSampleBufferError_RequiredParameterMissing",
        kCMSampleBufferError_AlreadyHasDataBuffer: "kCMSampleBufferError_AlreadyHasDataBuffer",
        kCMSampleBufferError_BufferNotReady: "kCMSampleBufferError_BufferNotReady",
        kCMSampleBufferError_SampleIndexOutOfRange: "kCMSampleBufferError_SampleIndexOutOfRange",
        kCMSampleBufferError_BufferHasNoSampleSizes: "kCMSampleBufferError_BufferHasNoSampleSizes",
        kCMSampleBufferError_BufferHasNoSampleTimingInfo: "kCMSampleBufferError_BufferHasNoSampleTimingInfo",
        kCMSampleBufferError_ArrayTooSmall: "kCMSampleBufferError_ArrayTooSmall",
        kCMSampleBufferError_InvalidEntryCount: "kCMSampleBufferError_InvalidEntryCount",
        kCMSampleBufferError_CannotSubdivide: "kCMSampleBufferError_CannotSubdivide",
        kCMSampleBufferError_SampleTimingInfoInvalid: "kCMSampleBufferError_SampleTimingInfoInvalid",
        kCMSampleBufferError_InvalidMediaTypeForOperation: "kCMSampleBufferError_InvalidMediaTypeForOperation",
        kCMSampleBufferError_InvalidSampleData: "kCMSampleBufferError_InvalidSampleData",
        kCMSampleBufferError_InvalidMediaFormat: "kCMSampleBufferError_InvalidMediaFormat",
        kCMSampleBufferError_Invalidated: "kCMSampleBufferError_Invalidated",
        kCMSampleBufferError_DataFailed: "kCMSampleBufferError_DataFailed",
        kCMSampleBufferError_DataCanceled: "kCMSampleBufferError_DataCanceled"
    ]
}
