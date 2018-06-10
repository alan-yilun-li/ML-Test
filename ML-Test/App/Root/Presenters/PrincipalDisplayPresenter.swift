import UIKit
import Vision
import AVFoundation

class PrincipalDisplayPresenter: NSObject {

    weak var viewController: PrincipalDisplayViewController!
    private var session: AVCaptureSession?
    var observations = [VNClassificationObservation]() {
        didSet { viewController.reloadData() }
    }

    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: Inceptionv3().model)
            let request = VNCoreMLRequest(model: model, completionHandler: self.handleClassification)
            request.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop
            DispatchQueue.main.async { self.viewController.hideLoadingSpinner(permanently: true) }
            return request
        } catch {
            fatalError("MLModel Load Failed: \(error)")
        }
    }()
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
private extension PrincipalDisplayPresenter {

    func startSession() {
        session?.startRunning()
        /* AVCaptureConnection needs manual adjustment so CVImageBuffer pixels
         are rotated correctly in captureOutput(_:didOutput:from:) */
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        DispatchQueue.main.async { self.viewController.showLoadingSpinner() }
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
                if let orientation = AVCaptureVideoOrientation(
                    rawValue: UIDevice.current.orientation.rawValue
                ) {
                    $0.videoOrientation = orientation
                }
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
        DispatchQueue.main.async { [weak self] in
            self?.viewController.cameraDisplayView.addPreviewLayer(previewLayer)
        }
        self.session = session
        startSession()
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension PrincipalDisplayPresenter: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        var requestOptions: [VNImageOption: Any] = [:]
        if let cameraIntrinsicData = CMGetAttachment(
            sampleBuffer,
            kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix,
            nil
        ) {
            requestOptions = [.cameraIntrinsics: cameraIntrinsicData]
        }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: requestOptions)
        do {
            try handler.perform([classificationRequest])
        } catch {
            print(error)
        }
    }
}

// MARK: - ML Classification

extension PrincipalDisplayPresenter {

    func handleClassification(request: VNRequest, error: Error?) {
        let observations = request.results as! [VNClassificationObservation]
        let acceptedObservations = observations[0...10].filter({ $0.confidence > 0.1 })
        DispatchQueue.main.async { [weak self] in
            self?.observations = acceptedObservations
        }
    }
}

// MARK: - UITableViewDataSource
extension PrincipalDisplayPresenter: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return observations.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: IdentifierTableViewCell.reuseID,
            for: indexPath
        ) as! IdentifierTableViewCell

        cell.identifierText = observations[indexPath.row].identifier
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        let number = NSNumber(value: observations[indexPath.row].confidence)
        cell.confidence = formatter.string(from: number) ?? "-1" 

        return cell
    }
}
