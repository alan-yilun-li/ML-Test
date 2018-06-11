import AVFoundation
import UIKit

class CameraDisplayView: UIView {

    private var previewLayer: AVCaptureVideoPreviewLayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        NotificationCenter.default.addObserver(
            self, selector: #selector(deviceOrientationDidChange(_:)),
            name: .UIDeviceOrientationDidChange,
            object: nil
        )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addPreviewLayer(_ previewLayer: AVCaptureVideoPreviewLayer) {
        previewLayer.frame = bounds
        previewLayer.videoGravity = .resizeAspectFill
        self.layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }

    @objc private func deviceOrientationDidChange(_ notification: Notification) {
        previewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation(
            rawValue: UIDevice.current.orientation.rawValue
        ) ?? .portrait
    }
}

