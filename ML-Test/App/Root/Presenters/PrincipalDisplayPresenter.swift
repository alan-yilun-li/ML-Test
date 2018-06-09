import UIKit
import AVKit
import Vision

/// MLCameraViewController sets up AVCaptureSession & presents AVCaptureVideoPreviewLayer.
/// Uses AVCaptureOutput's pixel buffer to create classification request to Inceptionv3
/// model. Device rotation handled by setting orientation on AVCaptureConnection (not ideal).
/// See: deviceOrientationDidChange(_:) comment.
class PrincipalDisplayPresenter: NSObject {

    weak var viewController: PrincipalDisplayViewController!
    private var session: AVCaptureSession?
}

// MARK: - View Lifecycle Methods
extension PrincipalDisplayPresenter {

    func viewDidLoad() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceOrientationDidChange(_:)),
            name: .UIDeviceOrientationDidChange,
            object: nil
        )
    }

    func viewDidAppear() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] (granted) in
            if granted && self?.session == nil {
                self?.setupSession()
            }
        }
        startSession()
    }

    func viewDidDisappear() {
        stopSession()
    }
}

// MARK: - AVSessionControl Methods
fileprivate extension PrincipalDisplayPresenter {

    func startSession() {
        session?.startRunning()
        /* AVCaptureConnection needs manual adjustment so CVImageBuffer pixels
         are rotated correctly in captureOutput(_:didOutput:from:) */
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    }

    func stopSession() {
        session?.stopRunning()
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
}


// MARK: - Device Rotation Support
extension PrincipalDisplayPresenter {

    @objc private func deviceOrientationDidChange(_ notification: Notification) {
        session?.outputs.forEach {
            $0.connections.forEach {
                $0.videoOrientation = UIDevice.current.orientation
            }
        }
    }
}

// MARK: - AVCaptureSession Setup
private extension PrincipalDisplayPresenter {

    func setupSession() {
        guard let device = AVCaptureDevice.default(for: .video) else {
            fatalError("Capture device not available")
        }
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            fatalError("Capture input not available")
        }
        let output = AVCaptureVideoDataOutput()
        let session = AVCaptureSession()
        session.addInput(input)
        session.addOutput(output)
        output.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInteractive))

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        viewController.view.layer.addSublayer(previewLayer)

        self.session = session
        session.startRunning()
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension PrincipalDisplayPresenter: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Note: Pixel buffer is already correctly rotated based on device rotation
        // See: deviceOrientationDidChange(_:) comment
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        var requestOptions: [VNImageOption: Any] = [:]
        if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics: cameraIntrinsicData]
        }
        // Run the Core ML classifier - results in handleClassification method
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: requestOptions)
        do {
            try handler.perform([classificationRequest])
        } catch {
            print(error)
        }
    }
}


