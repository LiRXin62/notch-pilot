import AVFoundation
import AppKit
import Foundation

@MainActor
final class CameraMirrorService: ObservableObject {
    @Published var isRunning = false
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?

    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?

    init() {
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }

    func requestAccess() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            Task { @MainActor in
                self?.authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
                if granted {
                    self?.startCapture()
                }
            }
        }
    }

    func startCapture() {
        guard authorizationStatus == .authorized else {
            requestAccess()
            return
        }

        errorMessage = nil
        let session = AVCaptureSession()
        session.sessionPreset = .medium

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            errorMessage = Localizer.shared.t("未检测到前置摄像头")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        captureSession = session
        session.startRunning()
        isRunning = true
    }

    func stopCapture() {
        captureSession?.stopRunning()
        captureSession = nil
        isRunning = false
    }

    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        guard let session = captureSession else { return nil }
        if videoPreviewLayer == nil {
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
            videoPreviewLayer?.videoGravity = .resizeAspectFill
        }
        return videoPreviewLayer
    }

    func capturePhoto() -> NSImage? {
        guard let session = captureSession else { return nil }
        // For a simple implementation, we'll use the preview layer
        // In a real app, you'd use AVCapturePhotoOutput
        return nil
    }
}
