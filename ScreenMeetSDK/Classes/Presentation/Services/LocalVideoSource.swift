//
//  LocalVideoSource.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 28.08.2020.
//

import Foundation
import WebKit

///Represents video source
public protocol LocalVideoSource {
    
    /// Should be configured in case you need to modify every session frame before sending to server
    ///
    /// View Privacy feature note: to obfuscate some View on stream recommended to use [AppStreamFrameProcessor](x-source-tag://AppStreamFrameProcessor).
    /// This provides better edge cases handling and user experience overall.
    var frameProcessor: FrameProcessor { get set }
}

/// Allows to modify every session frame before sending to server
public protocol FrameProcessor {
    
    /// Implement this method to be able to modify frame
    ///
    /// Be careful when implementing as long frame processing time will result in stream FPS dropdown.
    /// Default stream fps is ~30fps, so try to process each frame faster than 30ms.
    ///
    /// General rule of thumb: keep frame processing time as low as possible.
    ///
    /// View Privacy feature note: to obfuscate some View on stream recommended to use [AppStreamFrameProcessor](x-source-tag://AppStreamFrameProcessor).
    /// This provides better edge cases handling and user experience overall.
    ///
    /// - Parameter pixelBuffer: Input Captured Frame
    /// - Parameter completion: Should be called with modified sampleBuffer
    func processFrame(pixelBuffer: CVPixelBuffer, completion: @escaping (CVPixelBuffer) -> Void)
    
    /// Set confidential view
    /// - Parameter view: Confidential view
    func setConfidential<T: UIView>(view: T)
    
    /// Unset confidential view
    /// - Parameter view: Confidential view
    func unsetConfidential<T: UIView>(view: T)
    
    /// Set confidential view
    /// - Parameter view: Confidential view
    func setConfidentialWeb<T: WKWebView>(view: T)
    
    /// Unset confidential view
    /// - Parameter view: Confidential view
    func unsetConfidentialWeb<T: WKWebView>(view: T)
}
