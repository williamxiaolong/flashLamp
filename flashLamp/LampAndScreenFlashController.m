//
//  LampAndScreenFlashController.m
//  flashLamp
//
//  Created by 袁小龙 on 2018/6/25.
//  Copyright © 2018年 Skyedu. All rights reserved.
//

#import "LampAndScreenFlashController.h"
#import <AVFoundation/AVFoundation.h>
#import "MusicCell.h"


@interface LampAndScreenFlashController ()<UITableViewDataSource,UITableViewDelegate>
{
    AVCaptureSession *AVSession;//调用闪光灯的时候创建的类
    AVCaptureDevice *device;
}

@property (weak, nonatomic) IBOutlet UITableView *musicTableView;

@property (weak, nonatomic) IBOutlet UISwitch *lampSwitch;   // 闪光灯开关

@property (weak, nonatomic) IBOutlet UISwitch *screnSwitch;  // 屏幕闪光开关

@property (nonatomic, strong) NSArray *musicArray;           // 音乐数组

@property (strong,nonatomic) NSTimer *vodioTimer;//定时器用于播放获取音量分贝

@property (nonatomic, strong) AVAudioPlayer *musicPlayer;

@property (nonatomic, assign) NSInteger oldLevel;

@property (nonatomic, assign) float defaultScreenBright;




@end

@implementation LampAndScreenFlashController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.defaultScreenBright = [[UIScreen mainScreen] brightness];
    self.musicArray = @[@"姚贝娜 - 战争世界", @"许嵩 - 大千世界", @"李哈哈 - 再也不会遇见第二个她", @"卢焱 - 一生独一"];
    [self.musicTableView registerNib:[UINib nibWithNibName:@"MusicCell" bundle:nil] forCellReuseIdentifier:@"MusicCell"];
    
    
}

- (IBAction)lampSwitchClick:(UISwitch *)sender {
    
    if (!sender.on) {
        [self closeFlash];
    }
    
}

- (IBAction)screenSwitchClick:(UISwitch *)sender {
    
    if (!sender.on) {
        [[UIScreen mainScreen] setBrightness:self.defaultScreenBright];
    }
    
}

//开启闪光灯
- (void)openFlash{
    
    AVSession = [[AVCaptureSession alloc]init];
    device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [device lockForConfiguration:nil];//此处以一定要调用这个方法不然程序运行到这里会崩溃
    [device setTorchMode:AVCaptureTorchModeOn];
    [device setFlashMode:AVCaptureFlashModeOn];
    [device unlockForConfiguration];
    [AVSession startRunning];
    
}
//关闭闪光灯
- (void)closeFlash{
    
    AVSession = [[AVCaptureSession alloc]init];
    device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [device lockForConfiguration:nil];
    [device setTorchMode:AVCaptureTorchModeOff];
    [device setFlashMode:AVCaptureFlashModeOff];
    [device unlockForConfiguration];
    [AVSession stopRunning];
    AVSession = nil;    //置空
    device = nil;       //置空
}

- (void)changeScreenBright:(float)value
{
    if (self.screnSwitch.on) {
        [[UIScreen mainScreen] setBrightness:value];//修改屏幕亮度
    }
    
}

- (void)startMusicWithName:(NSString*)musicName{
    
    
    NSLog(@"播放音频:%@",musicName);
    
    if (self.musicPlayer) {
        [self.musicPlayer stop];
        self.musicPlayer = nil;
    }
    NSURL *fileURL =  [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:musicName ofType:@"mp3"]];
    self.musicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
    
    self.musicPlayer.volume = 0.4;//设置音频音量
    [self.musicPlayer prepareToPlay];
    
    
    [self.musicPlayer play];
    
    
    _vodioTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(vodiotimerFire:) userInfo:nil repeats:YES];
    [_vodioTimer fire];
    
    
}

//定时器事件
- (void)vodiotimerFire:(NSTimer *)sender{
    
    self.musicPlayer.meteringEnabled = YES;
    [self.musicPlayer updateMeters];
    
    
    float   level;                // The linear 0.0 .. 1.0 value we need.
    float   minDecibels = -80.0f; // Or use -60dB, which I measured in a silent room.
    float   decibels    = [self.musicPlayer averagePowerForChannel:0];
    
    if (decibels < minDecibels)
    {
        level = 0.0f;
    }
    else if (decibels >= 0.0f)
    {
        level = 1.0f;
    }
    else
    {
        float   root            = 2.0f;
        float   minAmp          = powf(10.0f, 0.05f * minDecibels);
        float   inverseAmpRange = 1.0f / (1.0f - minAmp);
        float   amp             = powf(10.0f, 0.05f * decibels);
        float   adjAmp          = (amp - minAmp) * inverseAmpRange;
        
        level = powf(adjAmp, 1.0f / root);
    }
    
    /* level 范围[0 ~ 1], 转为[0 ~120] 之间 */
    NSInteger newLevel = (NSInteger)(level * 120);
    NSLog(@"level== %d",newLevel);
    if (newLevel == 0) {
        self.oldLevel = newLevel;
    }
    
    NSInteger spaceLevel = newLevel - self.oldLevel;
    if (abs(spaceLevel) >= 10) {
        self.oldLevel = newLevel;
        
        if (self.lampSwitch.on) {
            [self openFlash];
            [self closeFlash];
        }
        
        float currentBright = 1- (newLevel / 120.0);
        [self changeScreenBright:currentBright];
        
        
    } else {
        [self changeScreenBright:self.defaultScreenBright];
    }
    
    
}

#pragma mark - UITableViewDelegate,UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MusicCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MusicCell"];
    cell.musicNameLabel.text = self.musicArray[indexPath.row];
    return cell;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.musicArray.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *musicName = self.musicArray[indexPath.row];
    [self startMusicWithName:musicName];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
