//
//  Recoder.h
//  4:3AVCamTest
//
//  Created by admin on 15/9/8.
//  Copyright © 2015年 admin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface Recoder : NSObject <AVCaptureFileOutputRecordingDelegate>

@property(strong, nonatomic) AVCaptureSession *session;
@property(strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property(assign, nonatomic) CGSize size;
@property(strong, nonatomic) NSString *outputFilePath;

-(void)changeCamera;
-(void)startToRecord;
-(void)stopRecording;
-(void)focusAtPoint:(CGPoint)point;
-(void)writeToLibraryWithPath:(NSURL *)filePath;

@end
