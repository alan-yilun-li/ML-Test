import UIKit

class PrincipalDisplayViewController: UIViewController {

    var presenter: PrincipalDisplayPresenter

    init(presenter: PrincipalDisplayPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.viewDidLoad()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presenter.viewDidAppear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        presenter.viewDidDisappear()
    }
}

// MARK: - AVCaptureSession Setup
extension PrincipalDisplayViewController {

    private func setupSession() {
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
        // Setup preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        cameraPreview.addCaptureVideoPreviewLayer(previewLayer)
        self.session = session
        session.startRunning()
    }
}



// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension PrincipalDisplayViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

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
