//
//  LocalVideoSource.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 28.08.2020.
//

import Foundation

///Represents video source
public protocol LocalVideoSource {
    
    /// Should be configured in case you need to modify every session frame before sending to server
    var frameProcessor: FrameProcessor { get set }
}

/// Allows to modify every session frame before sending to server
public protocol FrameProcessor {
    
    /// Override this method to be able to modify frame
    /// - Parameter sampleBuffer: Input Captured Frame
    /// - Parameter completion: Should be called with modified `CMSampleBuffer`
    func processFrame(sampleBuffer: CMSampleBuffer, completion: @escaping (CMSampleBuffer) -> Void)
}
