//
//  Recoder.m
//  4:3AVCamTest
//
//  Created by admin on 15/9/8.
//  Copyright © 2015年 admin. All rights reserved.
//  包含输入、输出设备，preview层，对视频的处理

#import "Recoder.h"
#import "Header.h"

@interface Recoder()

@property(strong, nonatomic) dispatch_queue_t sessionQueue;

@property(strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property(strong, nonatomic) AVCaptureDeviceInput *audioInput;
@property(strong, nonatomic) AVCaptureMovieFileOutput *movieFileOutput;

@property(assign, nonatomic) BOOL isBackCamera;

@end

@implementation Recoder

-(id)init{
    self = [super init];
    [self initCapture];

    return self;
}

-(void)initCapture{
    _session = [[AVCaptureSession alloc]init];
    
    _sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    
    [self addVideoInputDeviceWith:AVCaptureDevicePositionBack];
    [self addAudioInputDevice];
    [self addMovieFileOutput];
    _session.sessionPreset = AVCaptureSessionPresetMedium;
    [self initPreview];
    [_session startRunning];
}

-(AVCaptureDevice *)getCameraWithPosition:(NSInteger)position{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            return device;
        }
    }
    return nil;
}

-(void)addVideoInputDeviceWith:(NSInteger)position{
    
    if (position == AVCaptureDevicePositionBack) {
        _isBackCamera = YES;
    }else{
        _isBackCamera = NO;
    }
    
    NSError *videoError = nil;
    AVCaptureDevice *camera = [self getCameraWithPosition:position];
    AVCaptureDeviceInput *cameraInput = [[AVCaptureDeviceInput alloc]initWithDevice:camera error:&videoError];
    if (videoError) {
        NSLog(@"%@", videoError);
    }
    if ([_session canAddInput:cameraInput]) {
        [_session addInput:cameraInput];
        _videoInput = cameraInput;
    }
}

-(void)addAudioInputDevice{
    NSError *audioError = nil;
    AVCaptureDevice *audio = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput = [[AVCaptureDeviceInput alloc]initWithDevice:audio error:&audioError];
    if (audioError) {
        NSLog(@"%@", audioError);
    }
    if ([_session canAddInput:audioInput]) {
        [_session addInput:audioInput];
        _audioInput = audioInput;
    }
}

-(void)addMovieFileOutput{
    _movieFileOutput = [[AVCaptureMovieFileOutput alloc]init];
    [_session addOutput:_movieFileOutput];
}

-(void)initPreview{
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:_session];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
}

#pragma mark -actions
-(void)changeCamera{
    dispatch_async(_sessionQueue, ^{
        NSInteger position;
        if (_isBackCamera) {
            position = AVCaptureDevicePositionFront;
        }else{
            position = AVCaptureDevicePositionBack;
        }
        [_session beginConfiguration];
        [_session removeInput:_videoInput];
        [self addVideoInputDeviceWith:position];
        [_session commitConfiguration];
    });
}

-(void)startToRecord{
    dispatch_async(_sessionQueue, ^{
        NSString *originalOutputFileName = [NSTemporaryDirectory() stringByAppendingPathComponent:[@"movie" stringByAppendingPathExtension:@"mp4"]];
        _outputFilePath = [self getNameByDate];
        [_movieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:originalOutputFileName] recordingDelegate:self];
    });
}

-(void)stopRecording{
    dispatch_async(_sessionQueue, ^{
        [_movieFileOutput stopRecording];
    });
}

-(void)focusAtPoint:(CGPoint)point{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AVCaptureDevice *device = [_videoInput device];
        NSError *error = nil;
        CGPoint devicePoint = CGPointMake(point.x / _size.width, point.y / _size.height);
//        NSLog(@"focusMode = %d", device.focusMode);
        if ([device lockForConfiguration:&error]) {
            if ([device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
                [device setFocusMode:AVCaptureFocusModeAutoFocus];
            }
            if ([device isFocusPointOfInterestSupported]) {
                [device setFocusPointOfInterest:devicePoint];
            }
            if ([device isExposurePointOfInterestSupported]) {
                [device setExposurePointOfInterest:devicePoint];
            }
            [device setSubjectAreaChangeMonitoringEnabled:YES];
            [device unlockForConfiguration];
        } else {
            NSLog(@"对焦错误:%@", error);
        }
    });
}

#pragma mark -capture delegate
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{//没有删除原文件
    if (error) {
        NSLog(@"%@", error);
    }
    dispatch_async(_sessionQueue, ^{
        [self cutVideoWithPath:outputFileURL];
    });
}

#pragma mark -tools
-(NSString *)getNameByDate{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    
    NSString *path = NSTemporaryDirectory();
    NSString *fileName = [path stringByAppendingPathComponent:[nowTimeStr stringByAppendingString:@".mp4"]];
    
    return fileName;
}

-(void)cutVideoWithPath:(NSURL *)outputFileURL{
    AVAsset *asset = [AVAsset assetWithURL:outputFileURL];
    AVAssetTrack *videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo]objectAtIndex:0];//视频数据
    AVAssetTrack *audioAssertTrack = [[asset tracksWithMediaType:AVMediaTypeAudio]objectAtIndex:0];
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *videoCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];//视频轨道
    [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration) ofTrack:videoAssetTrack atTime:kCMTimeZero error:nil];//在视频轨道插入一个时间段的视频
    
    AVMutableCompositionTrack *audioCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];//音频轨道
    [audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration) ofTrack:audioAssertTrack atTime:kCMTimeZero error:nil];//插入音频数据，否则没有声音
    
    //对视频轨道上的视频进行裁剪
    //以下是我自己的看法，应该有很多地方不对，但这样有助于我理解
    //AVMutableVideoCompositionLayerInstruction是单个的视频素材，可以旋转、缩放等
    AVMutableVideoCompositionLayerInstruction *videoCompositionLayerIns = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoAssetTrack];
    [videoCompositionLayerIns setTransform:videoAssetTrack.preferredTransform atTime:kCMTimeZero];
    //AVMutableVideoCompositionInstruction是一个轨道上的视频
    AVMutableVideoCompositionInstruction *videoCompositionIns = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    [videoCompositionIns setTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration)];
    videoCompositionIns.layerInstructions = @[videoCompositionLayerIns];
    //AVMutableVideoComposition是集合了所有轨道的视频，用于渲染的最终形态，决定了最终生成的视频的尺寸
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.instructions = @[videoCompositionIns];
    videoComposition.renderSize = _size;
    videoComposition.frameDuration = CMTimeMake(1, 30);
    //导出，这里目录处理的很随意
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetMediumQuality];
    exporter.videoComposition = videoComposition;
    exporter.outputURL = [NSURL fileURLWithPath:_outputFilePath isDirectory:YES];
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        if (exporter.error) {
            NSLog(@"%@", exporter.error);
        }else{
            [[NSNotificationCenter defaultCenter]postNotificationName:@"RecorderExported" object:self];//完成后回调
        }
    }];
}

-(void)writeToLibraryWithPath:(NSURL *)filePath{
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
    if ([assetsLibrary videoAtPathIsCompatibleWithSavedPhotosAlbum:filePath]) {
        [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:filePath completionBlock:NULL];
        NSLog(@"成功写入相册");
    }
}
@end
