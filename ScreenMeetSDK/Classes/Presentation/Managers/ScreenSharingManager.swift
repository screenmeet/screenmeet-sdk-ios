//
//  ScreenSharingManager.swift
//  ScreenMeetLiveSDK
//
//  Created by Vasyl Morarash on 05.06.2020.
//

import Foundation
import ReplayKit

extension UIImage {
    
    convenience init(color: UIColor) {
        let rect = UIScreen.main.bounds
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        self.init(cgImage: image!.cgImage!)
    }
}


final class ScreenSharingManager {
    
    private init() { }
    
//    static var shared = ScreenSharingManager()
    
    private let recorder = RPScreenRecorder.shared()
    
    private var overlayImage = UIImage(color: .gray)
    
    private let ciContext: CIContext = CIContext(options: nil)
    
    var privateViews: [String: UIView?] = [:]
    
    var privateRects: [String: [CGRect]] = [:]
    
    var isSharing: Bool {
        return recorder.isRecording
    }
    
    func startScreenSharing(buffer: @escaping ((CMSampleBuffer) -> Void)) {
        guard !isSharing else { return }
        DispatchQueue(label: "com.screenmeet.screensharing", qos: .userInitiated).async { [unowned self] in
            self.overlayImage = UIImage(color: .gray)
            self.recorder.startCapture(handler: { [weak self] (sampleBuffer, sampleBufferType, error) in
                guard sampleBufferType == .video else { return }
                
                let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
                
                let ciimage: CIImage = CIImage(cvPixelBuffer: imageBuffer)
                
                self?.convert(ciImage: ciimage, sampleBuffer: sampleBuffer, pixelBuffer: imageBuffer, buffer: { (sampleBuffer) in
                    buffer(sampleBuffer)
                })
            }, completionHandler: { (error) in })
        }
    }
    
    func stopScreenSharing() {
        guard isSharing else { return }
        recorder.stopCapture { (error) in }
    }
    
    private func convert(cimage: CIImage) -> UIImage {
        let context: CIContext = CIContext(options: nil)
        let cgImage: CGImage = context.createCGImage(cimage, from: cimage.extent)!
        let image: UIImage = UIImage(cgImage: cgImage)
        context.clearCaches()
        return image
    }
    
    private func convert(ciImage: CIImage, sampleBuffer: CMSampleBuffer, pixelBuffer: CVPixelBuffer, buffer: @escaping (CMSampleBuffer) -> Void) {
        DispatchQueue.main.async { [unowned self] in
            
            var pRects: [String: [CGRect]] = [:]
            
            self.privateViews.forEach { (key, value) in
                guard let glr = value?.globalRect else { return }
                
                var arr = self.privateRects[key] ?? []
                
                arr.append(glr)
                
                if arr.count > 3 {
                    arr.remove(at: 0)
                }
                
                pRects[key] = arr
            }
            
            self.privateRects = pRects
            
//            let rects = self.privateViews.compactMap { $0.value?.globalRect }
            
            let rects1 = self.privateRects.compactMap { $0.value }
            let rects = Array(rects1.joined())

            DispatchQueue(label: "com.screenmeet.screensharing", qos: .userInitiated) .async { [unowned self] in
                var outputImage: CIImage = ciImage

                let scale = ciImage.extent.width / UIScreen.main.bounds.size.width
                
                for rect in rects {
                    let width = rect.size.width * scale
                    let height = rect.size.height * scale
                    let x = rect.origin.x * scale
                    let y = ciImage.extent.height - height - (rect.origin.y * scale)
                    let scaledRect = CGRect(x: x, y: y, width: width, height: height)

                    outputImage = self.applyFilter(rect: scaledRect, ciImage: outputImage)
                }

                
                self.ciContext.render(outputImage, to: pixelBuffer)

                var sampleTime = CMSampleTimingInfo()
                sampleTime.duration = CMSampleBufferGetDuration(sampleBuffer)
                sampleTime.presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                sampleTime.decodeTimeStamp = CMSampleBufferGetDecodeTimeStamp(sampleBuffer)
                var videoInfo: CMVideoFormatDescription? = nil
                CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut: &videoInfo)
                var oBuf: CMSampleBuffer?
                CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, dataReady: true, makeDataReadyCallback: nil, refcon: nil, formatDescription: videoInfo!, sampleTiming: &sampleTime, sampleBufferOut: &oBuf)

                guard let bufferNew = oBuf else { return }

                buffer(bufferNew)
            }
        }
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
