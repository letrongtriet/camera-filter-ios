import AVKit
import SwiftUI

public struct IrisCameraView: View {
    @State private var pipeline = CapturePipeline()

    public init() {}

    public var body: some View {
        SampleBufferView(pipeline: pipeline)
            .onAppear {
                Task.detached {
                    pipeline.session.startRunning()
                }
            }
            .onDisappear {
                Task.detached {
                    pipeline.session.stopRunning
                }
            }
    }
}

private struct SampleBufferView: UIViewRepresentable {
    let pipeline: CapturePipeline

    func makeUIView(context: Context) -> some UIView {
        let view = SampleBufferDisplayLayerView()
        pipeline.output.displayLayer = view.displayLayer
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
    }

    private class SampleBufferDisplayLayerView: UIView {
        override class var layerClass: AnyClass {
            return AVSampleBufferDisplayLayer.self
        }

        public var displayLayer: AVSampleBufferDisplayLayer? {
            layer as? AVSampleBufferDisplayLayer
        }
    }
}
