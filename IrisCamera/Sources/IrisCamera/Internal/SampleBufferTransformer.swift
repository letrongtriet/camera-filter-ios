import AVKit
import CoreImage
import Foundation

struct SampleBufferTransformer {
    func transform(videoSampleBuffer: CMSampleBuffer) -> CMSampleBuffer {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(videoSampleBuffer) else {
            print("Failed to get pixel buffer")
            return videoSampleBuffer
        }

        guard let formatDescription = CMSampleBufferGetFormatDescription(videoSampleBuffer) else {
            print("Failed to get formatDescription")
            return videoSampleBuffer
        }

        let (outputPixelBufferPool, outputColorSpace) = allocateOutputBufferPool(
            with: formatDescription,
            outputRetainedBufferCountHint: 3
        )
        guard let outputPixelBufferPool else {
            print("Failed to create buffer pool")
            return videoSampleBuffer
        }

        let sourceImage = CIImage(cvImageBuffer: pixelBuffer)

        guard let filter = CIFilter(name: "CIColorInvert") else {
            print("Failed to get filter")
            return videoSampleBuffer
        }
        filter.setValue(sourceImage, forKey: kCIInputImageKey)

        guard let filteredImage = filter.value(forKey: kCIOutputImageKey) as? CIImage else {
            print("CIFilter failed to render image")
            return videoSampleBuffer
        }

        var pbuf: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, outputPixelBufferPool, &pbuf)
        guard let outputPixelBuffer = pbuf else {
            print("Allocation failure")
            return videoSampleBuffer
        }

        let ciContext = CIContext()
        // Render the filtered image out to a pixel buffer (no locking needed, as CIContext's render method will do that)
        ciContext.render(filteredImage, to: outputPixelBuffer, bounds: filteredImage.extent, colorSpace: outputColorSpace)

        guard let result = try? pbuf?.mapToSampleBuffer(timestamp: videoSampleBuffer.presentationTimeStamp) else {
            print("Failed to get final result")
            return videoSampleBuffer
        }

        return result
    }

    /// Source: https://developer.apple.com/documentation/avfoundation/additional_data_capture/avcamfilter_applying_filters_to_a_capture_stream
    /// Apple's sample code of how to improve output performance from CMSampleBuffer
    /// The main purpose is to create a pool of buffer where output stream will be smooth and continious
    private func allocateOutputBufferPool(
        with inputFormatDescription: CMFormatDescription,
        outputRetainedBufferCountHint: Int
    ) -> (
        outputBufferPool: CVPixelBufferPool?,
        outputColorSpace: CGColorSpace?
    ) {

        let inputMediaSubType = CMFormatDescriptionGetMediaSubType(inputFormatDescription)
        let inputDimensions = CMVideoFormatDescriptionGetDimensions(inputFormatDescription)
        var pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: UInt(inputMediaSubType),
            kCVPixelBufferWidthKey as String: Int(inputDimensions.width),
            kCVPixelBufferHeightKey as String: Int(inputDimensions.height),
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]

        // Get pixel buffer attributes and color space from the input format description.
        var cgColorSpace = CGColorSpaceCreateDeviceRGB()
        if let inputFormatDescriptionExtension = CMFormatDescriptionGetExtensions(inputFormatDescription) as Dictionary? {
            let colorPrimaries = inputFormatDescriptionExtension[kCVImageBufferColorPrimariesKey]

            if let colorPrimaries = colorPrimaries {
                var colorSpaceProperties: [String: AnyObject] = [kCVImageBufferColorPrimariesKey as String: colorPrimaries]

                if let yCbCrMatrix = inputFormatDescriptionExtension[kCVImageBufferYCbCrMatrixKey] {
                    colorSpaceProperties[kCVImageBufferYCbCrMatrixKey as String] = yCbCrMatrix
                }

                if let transferFunction = inputFormatDescriptionExtension[kCVImageBufferTransferFunctionKey] {
                    colorSpaceProperties[kCVImageBufferTransferFunctionKey as String] = transferFunction
                }

                pixelBufferAttributes[kCVBufferPropagatedAttachmentsKey as String] = colorSpaceProperties
            }

            if let cvColorspace = inputFormatDescriptionExtension[kCVImageBufferCGColorSpaceKey] {
                cgColorSpace = cvColorspace as! CGColorSpace
            } else if (colorPrimaries as? String) == (kCVImageBufferColorPrimaries_P3_D65 as String) {
                cgColorSpace = CGColorSpace(name: CGColorSpace.displayP3)!
            }
        }

        // Create a pixel buffer pool with the same pixel attributes as the input format description.
        let poolAttributes = [kCVPixelBufferPoolMinimumBufferCountKey as String: outputRetainedBufferCountHint]
        var cvPixelBufferPool: CVPixelBufferPool?
        CVPixelBufferPoolCreate(kCFAllocatorDefault, poolAttributes as NSDictionary?, pixelBufferAttributes as NSDictionary?, &cvPixelBufferPool)

        guard let pixelBufferPool = cvPixelBufferPool else {
            print("Allocation failure: Could not allocate pixel buffer pool.")
            return (nil, nil)
        }

        preallocateBuffers(pool: pixelBufferPool, allocationThreshold: outputRetainedBufferCountHint)

        // Get the output format description.
        var pixelBuffer: CVPixelBuffer?
        var outputFormatDescription: CMFormatDescription?
        let auxAttributes = [kCVPixelBufferPoolAllocationThresholdKey as String: outputRetainedBufferCountHint] as NSDictionary
        CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, pixelBufferPool, auxAttributes, &pixelBuffer)
        if let pixelBuffer = pixelBuffer {
            CMVideoFormatDescriptionCreateForImageBuffer(
                allocator: kCFAllocatorDefault,
                imageBuffer: pixelBuffer,
                formatDescriptionOut: &outputFormatDescription
            )
        }
        pixelBuffer = nil

        return (pixelBufferPool, cgColorSpace)
    }

    /// - Tag: AllocateRenderBuffers
    private func preallocateBuffers(pool: CVPixelBufferPool, allocationThreshold: Int) {
        var pixelBuffers = [CVPixelBuffer]()
        var error: CVReturn = kCVReturnSuccess
        let auxAttributes = [kCVPixelBufferPoolAllocationThresholdKey as String: allocationThreshold] as NSDictionary
        var pixelBuffer: CVPixelBuffer?
        while error == kCVReturnSuccess {
            error = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, pool, auxAttributes, &pixelBuffer)
            if let pixelBuffer = pixelBuffer {
                pixelBuffers.append(pixelBuffer)
            }
            pixelBuffer = nil
        }
        pixelBuffers.removeAll()
    }
}
