//
//  ViewController.m
//  4:3AVCamTest
//
//  Created by admin on 15/9/8.
//  Copyright © 2015年 admin. All rights reserved.
//  遵循MVC设计模式
//  对录制的视频进行4:3的裁剪
//  增加play界面，增加计时器，增加进度条
//  对焦

#import "ViewController.h"
#import "Recoder.h"
#import "Header.h"
#import "PlayViewController.h"

#define STEP 0.05

@interface ViewController ()
@property (strong, nonatomic) Recoder *recoder;
@property (strong, nonatomic) UIView *maskView;
@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) float leftTime;
@property (strong, nonatomic) UIProgressView *progressView;
@property (strong, nonatomic) UIView *focusView;

@property (weak, nonatomic) IBOutlet UIButton *changeCamera;
@property (weak, nonatomic) IBOutlet UIButton *recode;

- (IBAction)change:(id)sender;
- (IBAction)beginToRecorde:(id)sender;
- (IBAction)stopRecording:(id)sender;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _maskView = [self getMaskView];
    [[self view]addSubview:_maskView];
    [self initRecorder];
    [[_maskView layer]addSublayer:_recoder.previewLayer];
    [self initFocusView];
    
    _progressView = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleBar];
}

-(void)viewWillAppear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(exportingFinished) name:@"RecorderExported" object:nil];
    [_progressView removeFromSuperview];
}

-(void)viewWillDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -IBActions
- (IBAction)change:(id)sender {
    [_recoder changeCamera];
}

- (IBAction)beginToRecorde:(id)sender {
    [_recoder startToRecord];
    _progressView.frame = CGRectMake(0, CAMERAHEIGHT + 21, CAMERAWIDTH, 20);
    _progressView.progressTintColor = [UIColor blueColor];
    [self.view addSubview:_progressView];
    _leftTime = MAXTIME;
    _timer = [NSTimer scheduledTimerWithTimeInterval:STEP target:self selector:@selector(countDown) userInfo:nil repeats:YES];
    [_changeCamera setHidden:YES];
}

- (IBAction)stopRecording:(id)sender {
    [_recoder stopRecording];
    [_timer invalidate];
    [_changeCamera setHidden:NO];
    
}

#pragma mark -init methods
-(UIView *)getMaskView{//maskView是取景框，超出部分隐藏起来
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(touchInMaskView:)];
    UIView *maskView = [[UIView alloc]initWithFrame:CGRectMake(0, 20, CAMERAWIDTH, CAMERAHEIGHT)];
    [maskView addGestureRecognizer:tapGesture];
    maskView.clipsToBounds = YES;
    return maskView;
}

-(void)initRecorder{
    _recoder = [[Recoder alloc]init];
    _recoder.previewLayer.frame = CGRectMake(0, 0, DEVICE.width, DEVICE.height);
    _recoder.size = CGSizeMake(CAMERAWIDTH, CAMERAHEIGHT);
}

-(void)initFocusView{
    _focusView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, 0)];
    _focusView.backgroundColor = [UIColor clearColor];
    _focusView.layer.borderColor = [[UIColor blueColor]CGColor];
    _focusView.layer.borderWidth = 2;
    [_maskView insertSubview:_focusView aboveSubview:_maskView];
}
#pragma mark -tools
-(void)touchInMaskView:(UITapGestureRecognizer *)sender{
    CGPoint touchPoint = [sender locationInView:_maskView];
    _focusView.frame = CGRectMake(touchPoint.x - 40, touchPoint.y - 40, 80, 80);
    [UIView animateWithDuration:0.5 animations:^{
        _focusView.frame = CGRectMake(touchPoint.x - 30, touchPoint.y - 30, 60, 60);
    }];
    [_recoder focusAtPoint:touchPoint];
    [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(hideFocusView) userInfo:nil repeats:NO];
}

-(void)hideFocusView{
    _focusView.frame = CGRectMake(0, 0, 0, 0);
}

-(void)exportingFinished{
    PlayViewController *playerVC = [[PlayViewController alloc]init];
    playerVC.filePath = _recoder.outputFilePath;
    playerVC.recorder = _recoder;
    [self presentViewController:playerVC animated:YES completion:nil];
}

-(void)countDown{
    _progressView.progress = 1 - _leftTime / MAXTIME;
    _leftTime -= STEP;
    if (_leftTime < 0) {
        [self stopRecording:self];
    }
}
@end
