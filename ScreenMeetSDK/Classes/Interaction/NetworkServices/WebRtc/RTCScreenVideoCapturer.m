//
//  RTCScreenVideoCapturer.m
//  iOS-Prototype-SDK
//
//  Created by Vasyl Morarash on 20.05.2020.
//

#import <Foundation/Foundation.h>
#import <WebRTC/WebRTC.h>
#import "RTCScreenVideoCapturer.h"



const int64_t kNanosecondsPerSecond = 1000000000;

@interface RTCScreenVideoCapturer ()<AVCaptureVideoDataOutputSampleBufferDelegate>
@property(nonatomic, readonly) dispatch_queue_t frameQueue;
@end

@implementation RTCScreenVideoCapturer {
  AVCaptureVideoDataOutput *_videoDataOutput;
  AVCaptureSession *_captureSession;
  FourCharCode _preferredOutputPixelFormat;
  FourCharCode _outputPixelFormat;
  BOOL _hasRetriedOnFatalError;
  BOOL _isRunning;
  BOOL _willBeRunning;
  RTCVideoRotation _rotation;
  RTCCVPixelBuffer *_rtcPixelBuffer;
  CVPixelBufferRef _pixelBuffer;
  RTCVideoFrame *_videoFrame;
}

@synthesize frameQueue = _frameQueue;
@synthesize captureSession = _captureSession;

- (instancetype)init {
  return [self initWithDelegate:nil captureSession:[[AVCaptureSession alloc] init]];
}

- (instancetype)initWithDelegate:(__weak id<RTCVideoCapturerDelegate>)delegate {
  return [self initWithDelegate:delegate captureSession:[[AVCaptureSession alloc] init]];
}

- (instancetype)initWithDelegate:(__weak id<RTCVideoCapturerDelegate>)delegate
                  captureSession:(AVCaptureSession *)captureSession {
  if (self = [super initWithDelegate:delegate]) {
    if (![self setupCaptureSession:captureSession]) {
      return nil;
    }
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(handleCaptureSessionRuntimeError:)
                   name:AVCaptureSessionRuntimeErrorNotification
                 object:_captureSession];
    [center addObserver:self
               selector:@selector(handleCaptureSessionDidStartRunning:)
                   name:AVCaptureSessionDidStartRunningNotification
                 object:_captureSession];
    [center addObserver:self
               selector:@selector(handleCaptureSessionDidStopRunning:)
                   name:AVCaptureSessionDidStopRunningNotification
                 object:_captureSession];
  }
  return self;
}

- (void)dealloc {
  NSAssert(
      !_willBeRunning,
      @"Session was still running in RTCCameraVideoCapturer dealloc. Forgot to call stopCapture?");
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (FourCharCode)preferredOutputPixelFormat {
  return _preferredOutputPixelFormat;
}

- (void)stopCapture {
  [self stopCaptureWithCompletionHandler:nil];
}

- (void)startCaptureScreen:(nullable void (^)(void))completionHandler {
  _willBeRunning = YES;
  [RTCDispatcher
      dispatchAsyncOnType:RTCDispatcherTypeCaptureSession
                    block:^{

                      [self reconfigureCaptureSessionInput];
                      [self->_captureSession startRunning];
                      self->_isRunning = YES;
                      if (completionHandler) {
                        completionHandler();
                      }
                    }];
}

- (void)stopCaptureWithCompletionHandler:(nullable void (^)(void))completionHandler {
  _willBeRunning = NO;
  [RTCDispatcher
      dispatchAsyncOnType:RTCDispatcherTypeCaptureSession
                    block:^{
                      RTCLogInfo("Stop");
                      for (AVCaptureDeviceInput *oldInput in [self->_captureSession.inputs copy]) {
                        [self->_captureSession removeInput:oldInput];
                      }
                      [self->_captureSession stopRunning];

                      self->_isRunning = NO;
                      if (completionHandler) {
                        completionHandler();
                      }
                    }];
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
           fromConnection:(AVCaptureConnection *)connection {
  NSParameterAssert(captureOutput == _videoDataOutput);
  
    if (CMSampleBufferGetNumSamples(sampleBuffer) != 1 || !CMSampleBufferIsValid(sampleBuffer) ||
      !CMSampleBufferDataIsReady(sampleBuffer)) {
    return;
  }

  _pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  if (_pixelBuffer == nil) {
    return;
  }

  _rotation = RTCVideoRotation_0;

  _rtcPixelBuffer = [[RTCCVPixelBuffer alloc] initWithPixelBuffer:_pixelBuffer];
  int64_t timeStampNs = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)) *
      kNanosecondsPerSecond;
  _videoFrame = [[RTCVideoFrame alloc] initWithBuffer:_rtcPixelBuffer
                                                           rotation:_rotation
                                                        timeStampNs:timeStampNs];
    [self.delegate capturer:self didCaptureVideoFrame:_videoFrame];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
    didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer
         fromConnection:(AVCaptureConnection *)connection {
  RTCLogError(@"Dropped sample buffer.");
}

#pragma mark - AVCaptureSession notifications

- (void)handleCaptureSessionInterruption:(NSNotification *)notification {
  NSString *reasonString = nil;
  RTCLog(@"Capture session interrupted: %@", reasonString);
}

- (void)handleCaptureSessionInterruptionEnded:(NSNotification *)notification {
  RTCLog(@"Capture session interruption ended.");
}

- (void)handleCaptureSessionRuntimeError:(NSNotification *)notification {
  NSError *error = [notification.userInfo objectForKey:AVCaptureSessionErrorKey];
  RTCLogError(@"Capture session runtime error: %@", error);

  [RTCDispatcher dispatchAsyncOnType:RTCDispatcherTypeCaptureSession
                               block:^{
                                [self handleFatalError];
                               }];
}

- (void)handleCaptureSessionDidStartRunning:(NSNotification *)notification {
  RTCLog(@"Capture session started.");

  [RTCDispatcher dispatchAsyncOnType:RTCDispatcherTypeCaptureSession
                               block:^{
                                 self->_hasRetriedOnFatalError = NO;
                               }];
}

- (void)handleCaptureSessionDidStopRunning:(NSNotification *)notification {
  RTCLog(@"Capture session stopped.");
}

- (void)handleFatalError {
  [RTCDispatcher
      dispatchAsyncOnType:RTCDispatcherTypeCaptureSession
                    block:^{
                      if (!self->_hasRetriedOnFatalError) {
                        RTCLogWarning(@"Attempting to recover from fatal capture error.");
                        [self handleNonFatalError];
                        self->_hasRetriedOnFatalError = YES;
                      } else {
                        RTCLogError(@"Previous fatal error recovery failed.");
                      }
                    }];
}

- (void)handleNonFatalError {
  [RTCDispatcher dispatchAsyncOnType:RTCDispatcherTypeCaptureSession
                               block:^{
                                 RTCLog(@"Restarting capture session after error.");
                                 if (self->_isRunning) {
                                   [self->_captureSession startRunning];
                                 }
                               }];
}

#pragma mark - Private

- (dispatch_queue_t)frameQueue {
  if (!_frameQueue) {
    _frameQueue =
        dispatch_queue_create("org.webrtc.screenvideocapturer.video", DISPATCH_QUEUE_CONCURRENT);
    dispatch_set_target_queue(_frameQueue,
                              dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0));
      
  }
  return _frameQueue;
}

- (BOOL)setupCaptureSession:(AVCaptureSession *)captureSession {
  NSAssert(_captureSession == nil, @"Setup capture session called twice.");
  _captureSession = captureSession;

    [self setupVideoDataOutput];
  // Add the output.
  if (![_captureSession canAddOutput:_videoDataOutput]) {
    RTCLogError(@"Video data output unsupported.");
    return NO;
  }
  [_captureSession addOutput:_videoDataOutput];

  return YES;
}

- (void)setupVideoDataOutput {
  NSAssert(_videoDataOutput == nil, @"Setup video data output called twice.");
  AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];

  NSSet<NSNumber *> *supportedPixelFormats = [RTCCVPixelBuffer supportedPixelFormats];
  NSMutableOrderedSet *availablePixelFormats =
      [NSMutableOrderedSet orderedSetWithArray:videoDataOutput.availableVideoCVPixelFormatTypes];
  [availablePixelFormats intersectSet:supportedPixelFormats];
  NSNumber *pixelFormat = availablePixelFormats.firstObject;
  NSAssert(pixelFormat, @"Output device has no supported formats.");

  _preferredOutputPixelFormat = [pixelFormat unsignedIntValue];
  _outputPixelFormat = _preferredOutputPixelFormat;
  videoDataOutput.videoSettings = @{(NSString *)kCVPixelBufferPixelFormatTypeKey : pixelFormat};
  videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
  [videoDataOutput setSampleBufferDelegate:self queue:self.frameQueue];
  _videoDataOutput = videoDataOutput;
}

- (void)updateVideoDataOutputPixelFormat:(AVCaptureDeviceFormat *)format {
  FourCharCode mediaSubType = CMFormatDescriptionGetMediaSubType(format.formatDescription);
  if (![[RTCCVPixelBuffer supportedPixelFormats] containsObject:@(mediaSubType)]) {
    mediaSubType = _preferredOutputPixelFormat;
  }

  if (mediaSubType != _outputPixelFormat) {
    _outputPixelFormat = mediaSubType;
    _videoDataOutput.videoSettings =
        @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : @(mediaSubType) };
  }
}

#pragma mark - Private, called inside capture queue

- (void)reconfigureCaptureSessionInput {
  NSAssert([RTCDispatcher isOnQueueForType:RTCDispatcherTypeCaptureSession],
           @"reconfigureCaptureSessionInput must be called on the capture queue.");
    
  [_captureSession beginConfiguration];
  [_captureSession commitConfiguration];
}

@end
