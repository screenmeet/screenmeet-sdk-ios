//
//  RTCScreenVideoCapturer.h
//  iOS-Prototype-SDK
//
//  Created by Vasyl Morarash on 20.05.2020.
//

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

#import <WebRTC/WebRTC.h>

NS_ASSUME_NONNULL_BEGIN

RTC_OBJC_EXPORT
// Camera capture that implements RTCVideoCapturer. Delivers frames to a RTCVideoCapturerDelegate
// (usually RTCVideoSource).
NS_EXTENSION_UNAVAILABLE_IOS("Camera not available in app extensions.")
@interface RTCScreenVideoCapturer : RTCVideoCapturer

// Capture session that is used for capturing. Valid from initialization to dealloc.
@property(readonly, nonatomic) AVCaptureSession *captureSession;

// Returns the most efficient supported output pixel format for this capturer.
- (FourCharCode)preferredOutputPixelFormat;

// Starts the capture session asynchronously and notifies callback on completion.
// The device will capture video in the format given in the `format` parameter. If the pixel format
// in `format` is supported by the WebRTC pipeline, the same pixel format will be used for the
// output. Otherwise, the format returned by `preferredOutputPixelFormat` will be used.
- (void)startCaptureScreen:(nullable void (^)(void))completionHandler;
// Stops the capture session asynchronously and notifies callback on completion.
- (void)stopCaptureWithCompletionHandler:(nullable void (^)(void))completionHandler;

// Stops the capture session asynchronously.
- (void)stopCapture;

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection;
- (void)reconfigureCaptureSessionInput;
@end

NS_ASSUME_NONNULL_END
