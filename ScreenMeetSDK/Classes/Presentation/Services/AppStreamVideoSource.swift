//
//  AppStreamVideoSource.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 28.08.2020.
//

import Foundation
import ReplayKit

final class AppStreamVideoSource: LocalVideoSource {
    
    var frameProcessor: FrameProcessor = AppStreamFrameProcessor()
    
    private let screenRecorder = RPScreenRecorder.shared()
    
    func startCapture(success: @escaping ((CMSampleBuffer) -> Void), failure: @escaping (() -> Void)) {
        guard !screenRecorder.isRecording else { return }
        screenRecorder.startCapture(handler: { [weak self] (sampleBuffer, sampleBufferType, error) in
            guard sampleBufferType == .video else { return }
            
            guard error == nil else { return }
            
            self?.frameProcessor.processFrame(sampleBuffer: sampleBuffer) { (processedSampleBuffer) in
                success(processedSampleBuffer)
            }
        }, completionHandler: { (error) in
            if error != nil {
                failure()
            }
        })
    }
    
    func stopCapture(completion: @escaping (() -> Void)) {
        guard screenRecorder.isRecording else {
            completion()
            return
        }
        screenRecorder.stopCapture { (error) in
            completion()
        }
    }
}

final class AppStreamFrameProcessor: FrameProcessor {
    
    func processFrame(sampleBuffer: CMSampleBuffer, completion: @escaping (CMSampleBuffer) -> Void) {
        completion(sampleBuffer)
    }
}
