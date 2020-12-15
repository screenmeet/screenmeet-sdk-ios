//
//  AppStreamVideoSource.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 28.08.2020.
//

import Foundation
import ReplayKit
import WebKit

extension DispatchQueue {
    
    static let screenCaptureQueue = DispatchQueue(label: "com.screenmeet.screencapturequeue", qos: .userInitiated)
}

final class AppStreamVideoSource: LocalVideoSource {
    
    var frameProcessor: FrameProcessor = AppStreamFrameProcessor()
    
    private let screenRecorder = RPScreenRecorder.shared()
    
    private var frameProcessingTimes = [TimeInterval]()
    
    private var frameProcessingTimesTimer: Timer?
    
    func startCapture(success: @escaping ((CVPixelBuffer) -> Void), failure: @escaping (() -> Void)) {
        guard !screenRecorder.isRecording else { return }
        
        // Timer should be scheduled in main thread
        frameProcessingTimesTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(printAverageFrameProcessingTime), userInfo: nil, repeats: true)
        
        DispatchQueue.screenCaptureQueue.async { [unowned self] in
            screenRecorder.startCapture(handler: { (sampleBuffer, sampleBufferType, error) in
                guard sampleBufferType == .video else { return }
                guard error == nil else { return }
                guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
                
                let startFrameProcessingTime = Date.timeIntervalSinceReferenceDate
                frameProcessor.processFrame(pixelBuffer: pixelBuffer) { (processedPixelBuffer) in
                    frameProcessingTimes.append(Date.timeIntervalSinceReferenceDate - startFrameProcessingTime)
                    success(pixelBuffer)
                }
            }, completionHandler: { (error) in
                if error != nil {
                    failure()
                }
            })
        }
    }
    
    func stopCapture(completion: @escaping (() -> Void)) {
        guard screenRecorder.isRecording else {
            completion()
            return
        }
        frameProcessingTimesTimer?.invalidate()
        frameProcessingTimesTimer = nil
        
        screenRecorder.stopCapture { (error) in
            completion()
        }
    }
    
    @objc private func printAverageFrameProcessingTime() {
        guard frameProcessingTimes.count > 0 else { return }
        let avgValue = frameProcessingTimes.reduce(0.0, +) / Double(frameProcessingTimes.count)
        Logger.log.info("Average Frame processing time: \(String(format: "Value: %.3f", (avgValue * 1000))) ms")
        frameProcessingTimes.removeAll()
    }
}

/// - Tag: AppStreamFrameProcessor
public final class AppStreamFrameProcessor: FrameProcessor {
    
    private var views = [AppStreamView]()
    
    private var webViews = [AppStreamWebView]()
    
    private var overlayImage = UIImage(color: .red)
    
    private let ciContext: CIContext = CIContext(options: nil)
    
    public func processFrame(pixelBuffer: CVPixelBuffer, completion: @escaping (CVPixelBuffer) -> Void) {
        guard views.count > 0 || webViews.count > 0 else {
            completion(pixelBuffer)
            return
        }
        
        DispatchQueue.main.async { [unowned self] in
            var confidentialRects = views.compactMap { $0.getRect() }
            
            DispatchQueue.screenCaptureQueue.async { [unowned self] in
                webViews.forEach { webView in
                    webView.getRects { (rects) in
                        confidentialRects.append(contentsOf: rects)
                    }
                }
                guard confidentialRects.count > 0 else {
                    completion(pixelBuffer)
                    return
                }
                
                let ciImage: CIImage = CIImage(cvPixelBuffer: pixelBuffer)
                var outputImage: CIImage = ciImage

                let wScale = ciImage.extent.width / UIScreen.main.bounds.size.width
                let hScale = ciImage.extent.height / UIScreen.main.bounds.size.height
                
                confidentialRects.forEach { rect in
                    let width = rect.width * wScale
                    let height = rect.height * hScale
                    let x = rect.origin.x * wScale
                    let y = ciImage.extent.height - height - (rect.origin.y * hScale)
                    
                    let rect = CGRect(x: x, y: y, width: width, height: height)
                    
                    outputImage = self.applyFilter(rect: rect, ciImage: outputImage)
                }
                
                self.ciContext.render(outputImage, to: pixelBuffer)
                
                completion(pixelBuffer)
            }
        }
    }
    
    public func setConfidential<T: UIView>(view: T) {
        self.views.removeAll(where: { $0.value == nil })
        guard !self.views.contains(where: { $0.value == view }) else { return }
        
        views.append(AppStreamView(view))
    }
    
    public func unsetConfidential<T: UIView>(view: T) {
        self.views.removeAll(where: { $0.value == view || $0.value == nil })
    }
    
    public func setConfidentialWeb<T: WKWebView>(view: T) {
        self.webViews.removeAll(where: { $0.value == nil })
        guard !self.webViews.contains(where: { $0.value == view }) else { return }
        
        let webView = AppStreamWebView(view)
        webViews.append(webView)
    }
    
    public func unsetConfidentialWeb<T: WKWebView>(view: T) {
        self.webViews.removeAll(where: { $0.value == view || $0.value == nil })
    }
    
    private func applyFilter(rect: CGRect, ciImage: CIImage) -> CIImage {
        guard let overlayCIImage = CIImage(image: overlayImage) else { return ciImage }
        guard let cropFilter = CIFilter(name: "CICrop") else { return ciImage }
        
        cropFilter.setValue(overlayCIImage, forKey: kCIInputImageKey)
        cropFilter.setValue(CIVector(cgRect: rect), forKey: "inputRectangle")
        
        guard let overCompositingFilter = CIFilter(name: "CISourceOverCompositing") else { return ciImage }

        overCompositingFilter.setValue(cropFilter.outputImage, forKey: kCIInputImageKey)
        overCompositingFilter.setValue(ciImage, forKey: kCIInputBackgroundImageKey)
        
        guard let outputImage = overCompositingFilter.outputImage else { return ciImage }
        
        return outputImage
    }
}


extension UIView {
    
    var globalRect: CGRect? {
        guard let origin = self.layer.presentation()?.frame.origin,
            let globalPoint = self.superview?.layer.presentation()?.convert(origin, to: nil) else { return nil }
        return CGRect(origin: globalPoint, size: self.frame.size)
    }
    
    var globalTransform: CATransform3D? {
        guard let presentation = self.layer.presentation() else { return nil }
        return presentation.transform
    }
}
