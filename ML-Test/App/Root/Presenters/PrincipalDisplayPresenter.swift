import UIKit
import AVKit

class PrincipalDisplayPresenter: NSObject {

    weak var viewController: PrincipalDisplayViewController!
    private var session: AVCaptureSession?
}

// MARK: - View Lifecycle Methods
extension PrincipalDisplayPresenter {

    func viewDidLoad() {
        /* AVCaptureConnection needs manual adjustment so CVImageBuffer pixels
         are rotated correctly in captureOutput(_:didOutput:from:) */
        UIDevice.subscribeToDeviceOrientationNotifications(
            self, selector: #selector(deviceOrientationDidChange)
        )
    }

    func viewDidAppear() {
        // Request permisions to AVCaptureDevice
        AVCaptureDevice.requestAuthorization { [weak self] (granted) in
            self?.permissions(granted)
        }
        session?.startRunning()
    }

    func viewDidDisappear() {
        session?.stopRunning()
    }
}

// MARK: - Device Rotation Support
extension PrincipalDisplayPresenter {

    @objc private func deviceOrientationDidChange(_ notification: Notification) {
        session?.outputs.forEach {
            $0.connections.forEach {
                $0.videoOrientation  = orientation(
                    videoOrientation: $0.videoOrientation,
                    deviceOrientation: UIDevice.current.orientation
                )
            }
        }
    }
}
