//
//  ScreenVideoCapturer.swift
//  iOS-Prototype-SDK
//
//  Created by Vasyl Morarash on 20.05.2020.
//

import Foundation

class ScreenVideoCapturer: RTCScreenVideoCapturer {
    
    static var webRTCClient: ScreenmeetWebRtcSocketClient? = nil
    static let isWebRTCEnabled = true
    
    var screenmeetWebRtcClient: ScreenmeetWebRtcClient? = nil
    var stats: [Double] = []
    //var screen = NSScreen.main!
    public init(delegate: RTCVideoCapturerDelegate, client: ScreenmeetWebRtcClient) {
        super.init(delegate: delegate)
        self.screenmeetWebRtcClient = client
    }
    
    var prevMaxFrameRate = -1
    var prevMinFrameRate = -1
    
    public override func captureOutput(_ captureOutput: AVCaptureOutput, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        if (self.delegate != nil) {
            let _rotation = RTCVideoRotation._0 // No rotation on Mac.
            let _pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            let _rtcPixelBuffer = RTCCVPixelBuffer(pixelBuffer: _pixelBuffer!)
            let timeStampNs: Int64 = Int64(CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)) * 1000000000)
                let _videoFrame = RTCVideoFrame(buffer:_rtcPixelBuffer, rotation:_rotation, timeStampNs:timeStampNs)
                self.delegate!.capturer(self, didCapture:_videoFrame)
        }
        DispatchQueue.main.async {
            if (self.screenmeetWebRtcClient != nil) {
                self.screenmeetWebRtcClient?.onWebRTCFrameSent()
            }
        }
    }
    
    public func sendImageToWebRTC(image: CGImage) {
        if (self.delegate != nil) {
            let _rotation = RTCVideoRotation._0 // No rotation on Mac.
            let _pixelBuffer = image.newPixelBufferFromCGImage()
            let _rtcPixelBuffer = RTCCVPixelBuffer(pixelBuffer: _pixelBuffer)
            let timeStampNs: Int64 = Int64(Date().timeIntervalSince1970 * 1000000000)
                let _videoFrame = RTCVideoFrame(buffer:_rtcPixelBuffer, rotation:_rotation, timeStampNs:timeStampNs)
                self.delegate!.capturer(self, didCapture:_videoFrame)
        }
        DispatchQueue.main.async {
            if (self.screenmeetWebRtcClient != nil) {
                self.screenmeetWebRtcClient?.onWebRTCFrameSent()
            }
        }
    }
    
    public func sendScreenshot(_ sampleBuffer: CMSampleBuffer, _ orientation: RTCVideoRotation) {

            if (self.delegate != nil) {
                  if (CMSampleBufferGetNumSamples(sampleBuffer) != 1 || !CMSampleBufferIsValid(sampleBuffer) ||
                    !CMSampleBufferDataIsReady(sampleBuffer)) {
                  
                  } else {
                
                let _rotation = orientation
                if let _pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                    let _rtcPixelBuffer = RTCCVPixelBuffer(pixelBuffer: _pixelBuffer)
                    let timeStampNs: Int64 = Int64(CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)) * 1000000000)
                    let _videoFrame = RTCVideoFrame(buffer:_rtcPixelBuffer, rotation:_rotation, timeStampNs:timeStampNs)
                    self.delegate?.capturer(self, didCapture:_videoFrame)
                }
                }
            }
            DispatchQueue.main.async {
                if (self.screenmeetWebRtcClient != nil) {
                    self.screenmeetWebRtcClient?.onWebRTCFrameSent()
                }
            }
    }
        
}

extension CGImage {
    
    func newPixelBufferFromCGImage() -> CVPixelBuffer {
        let options = [kCVPixelBufferCGImageCompatibilityKey: NSNumber(booleanLiteral: true),
                       kCVPixelBufferCGBitmapContextCompatibilityKey: NSNumber(booleanLiteral: true)]
        
        var pxbuffer : CVPixelBuffer! = nil
        
        _ = CVPixelBufferCreate(kCFAllocatorDefault,
                                self.width,
                                self.height,
                                kCVPixelFormatType_32ARGB,
                                options as CFDictionary, &pxbuffer)
        
        CVPixelBufferLockBaseAddress(pxbuffer, CVPixelBufferLockFlags(rawValue: 0))
        let pxdata = CVPixelBufferGetBaseAddress(pxbuffer)

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pxdata,
                                width: self.width,
                                height: self.height,
                                bitsPerComponent: 8,
                                bytesPerRow: 4 * self.width,
                                space: rgbColorSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context!.draw(self, in: CGRect(x: 0,y: 0,width: self.width,height: self.height))
        CVPixelBufferUnlockBaseAddress(pxbuffer, CVPixelBufferLockFlags(rawValue: 0))

        return pxbuffer
    }
}
