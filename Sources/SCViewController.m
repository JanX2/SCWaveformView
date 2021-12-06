//
//  SCViewController.m
//  SCWaveformView
//
//  Created by Simon CORSIN on 24/01/14.
//  Copyright (c) 2014 Simon CORSIN. All rights reserved.
//

#import "SCViewController.h"
#import "SCWaveformView.h"

@interface SCViewController () {
    AVPlayer *_player;
    id _observer;
}

@end

@implementation SCViewController

// From:
// https://stackoverflow.com/questions/427477/fastest-way-to-clamp-a-real-fixed-floating-point-value
// https://stackoverflow.com/a/16659263/152827
NS_INLINE CGFloat clamp(CGFloat d, CGFloat min, CGFloat max) {
    const CGFloat t = d < min ? min : d;
    return t > max ? max : t;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.scrollableWaveformView.waveformView.precision = 1;
    self.scrollableWaveformView.waveformView.lineWidthRatio = 1;
    self.scrollableWaveformView.waveformView.channelsPadding = 10;
    
    self.scrollableWaveformView.waveformView.normalColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    self.scrollableWaveformView.waveformView.progressColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[[NSBundle mainBundle] URLForResource:@"test" withExtension:@"m4a"] options:nil];
    
    self.scrollableWaveformView.alpha = 1.0;
    
    self.scrollableWaveformView.waveformView.asset = asset;
    
    Float64 progressPercent = (Float64)self.slider.value;
    CMTime duration = self.scrollableWaveformView.waveformView.asset.duration;
    CMTime currentTime = CMTimeMultiplyByFloat64(duration, progressPercent);
    
    const double defaultStartInS = 15.0;
    CMTime defaultVisibleStartTime = CMTimeMakeWithSeconds(defaultStartInS, currentTime.timescale);
    CMTimeRange defaultVisibleTimeRange = CMTimeRangeMake(defaultVisibleStartTime, currentTime);
    self.scrollableWaveformView.waveformView.timeRange = defaultVisibleTimeRange;
    
    _player = [AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithAsset:asset]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_playReachedEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
    
    __unsafe_unretained SCViewController *mySelf = self;
    _observer = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 60) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        mySelf.scrollableWaveformView.waveformView.progressTime = time;
        
        // Percentage determining where in the frame the progress boundary will be held by auto-scrolling.
        // Unless this would cause the start or end of the content to detatch from the frame.
        // (This would cause the the waveform to begin or end somewhere on the screen other than the frame boundaries.)
        // If you are interested in this behavior, remove the clamp() call below.
        // “0.5” means center of the frame.
        const CGFloat defaultProgressPositionInFrameOffset = 0.5;
        if (YES) {
            // Adapted from https://github.com/jhays/JHSCWaveformView
            CMTime duration = asset.duration;
            
            if (CMTIME_IS_NUMERIC(duration) &&
                CMTIME_IS_NUMERIC(time)) {
                CGFloat durationInS = CMTimeGetSeconds(asset.duration);
                CGFloat timeInS = CMTimeGetSeconds(time);
                
                CGFloat percentComplete = timeInS / durationInS;
                
                CGFloat frameWidth = mySelf.scrollableWaveformView.frame.size.width;
                CGFloat contentWidth = mySelf.scrollableWaveformView.contentSize.width;
                
                CGFloat newFrameEndTarget = contentWidth * percentComplete;
                CGFloat relativeProgressOffset = frameWidth * defaultProgressPositionInFrameOffset;
                
                CGFloat newOffset = newFrameEndTarget - relativeProgressOffset;
                
                const CGFloat min = 0.0;
                const CGFloat max = contentWidth - frameWidth;
                newOffset = clamp(newOffset, min, max);
                
                mySelf.scrollableWaveformView.contentOffset = CGPointMake(newOffset, 0.0);
            }
        }
    }];
}

- (void)_playReachedEnd:(NSNotification *)notification {
    if (notification.object == _player.currentItem) {
        [_player seekToTime:kCMTimeZero];
        [_player play];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_player removeTimeObserver:_observer];
}

- (IBAction)precisionChanged:(UISlider *)sender {
    self.scrollableWaveformView.waveformView.precision = sender.value;
}
- (IBAction)lineWidthChanged:(UISlider *)sender {
    self.scrollableWaveformView.waveformView.lineWidthRatio = sender.value;
}

- (IBAction)playButtonTapped:(UIButton *)sender {
    sender.selected = !sender.selected;
    
    if (sender.selected) {
        [_player play];
    } else {
        [_player pause];
    }
}

- (IBAction)changeColorsTapped:(id)sender {
    CGFloat hue = ((CGFloat)arc4random_uniform(10000)) / 10000.0;
    self.scrollableWaveformView.waveformView.progressColor = [UIColor colorWithHue:hue saturation:1 brightness:1 alpha:1];
    self.scrollableWaveformView.waveformView.normalColor = [UIColor colorWithHue:hue saturation:0.5 brightness:1 alpha:1];
}
- (IBAction)stereoSwitchChanged:(UISwitch *)sender {
    self.scrollableWaveformView.waveformView.channelEndIndex = sender.on ? 1 : 0;
//    self.scrollableWaveformView.waveformView.channelStartIndex = sender.on ? 1 : 0;
}

- (IBAction)sliderProgressChanged:(UISlider *)sender
{
    const CMTime start = self.scrollableWaveformView.waveformView.timeRange.start;
    const CMTime duration = self.scrollableWaveformView.waveformView.asset.duration;
    
    const Float64 progressPercent = (Float64)sender.value;
    const CMTime currentTime = CMTimeMultiplyByFloat64(duration, progressPercent);
    
    CMTime newStart = start;
    
    // Adjusting the start time
    if (CMTIME_COMPARE_INLINE(CMTimeAdd(newStart, currentTime), >, duration)) {
        newStart = CMTimeSubtract(duration, currentTime);
    }
    
    self.scrollableWaveformView.waveformView.timeRange = CMTimeRangeMake(newStart, currentTime);
}

@end
