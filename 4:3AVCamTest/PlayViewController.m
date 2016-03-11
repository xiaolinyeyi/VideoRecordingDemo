//
//  PlayViewController.m
//  4:3AVCamTest
//
//  Created by admin on 15/9/10.
//  Copyright © 2015年 admin. All rights reserved.
//

#import "PlayViewController.h"
#import "Recoder.h"
#import "Header.h"

@interface PlayViewController()
@property(strong, nonatomic) MPMoviePlayerController *playerController;
@property (weak, nonatomic) IBOutlet UIButton *backBn;
@property (weak, nonatomic) IBOutlet UIButton *writeToLibraryBn;
- (IBAction)back:(id)sender;
- (IBAction)writeToLibrary:(id)sender;
@end


@implementation PlayViewController
-(void)viewDidLoad{
    self.view.backgroundColor = [UIColor whiteColor];
    if (_playerController == nil) {
        _playerController = [[MPMoviePlayerController alloc]init];
    }
    _playerController.contentURL = [NSURL fileURLWithPath:_filePath];
    _playerController.view.frame = CGRectMake(0, 20, CAMERAWIDTH, CAMERAHEIGHT);
    _playerController.controlStyle = MPMovieControlStyleNone;
    _playerController.scalingMode = MPMovieScalingModeAspectFit;
    _playerController.shouldAutoplay = YES;
    _playerController.movieSourceType = MPMovieSourceTypeFile;//这个属性不是根据文件自动判断的，而是要手动指定？？？
    [self.view addSubview:_playerController.view];
    [_playerController play];
}

-(void)viewWillAppear:(BOOL)animated{

}

-(void)showAttrOfFile:(NSString *)filePath{
    NSLog(@"%@", filePath);
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *attr = [fileManager attributesOfItemAtPath:filePath error:&error];
    if (error) {
        NSLog(@"%@", error);
    }
    NSLog(@"pvc: %@", attr);
}
- (IBAction)back:(id)sender {
    [_playerController stop];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)writeToLibrary:(id)sender {
    [_recorder writeToLibraryWithPath:_playerController.contentURL];
}

@end
