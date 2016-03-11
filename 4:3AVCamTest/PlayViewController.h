//
//  PlayViewController.h
//  4:3AVCamTest
//
//  Created by admin on 15/9/10.
//  Copyright © 2015年 admin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "Recoder.h"

@interface PlayViewController : UIViewController
@property(strong, nonatomic) NSString *filePath;
@property(strong, nonatomic) Recoder *recorder;
@end
