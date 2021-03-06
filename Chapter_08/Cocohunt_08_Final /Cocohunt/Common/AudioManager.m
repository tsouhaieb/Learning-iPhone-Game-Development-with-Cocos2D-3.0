//
//  AudioManager.m
//  Cocohunt
//
//  Created by Kirill Muzykov on 13/05/14.
//  Copyright (c) 2014 Kirill Muzykov. All rights reserved.
//

#import "AudioManager.h"
#import "OALSimpleAudio.h"
#import "cocos2d.h"

@implementation AudioManager
{
    //List of sound effects to preload
    NSArray* _soundEffects;
    
    //List of music tracks to pick random
    NSArray* _musicFiles;
    
    //Currently playing track.
    OALAudioTrack *_currentTrack;
    
    //Preloaded track to play next.
    OALAudioTrack *_nextTrack;
}

-(instancetype)init
{
    if (self = [super init])
    {
        //All sound effects #define'd in header in this array, to preload them.
        _soundEffects = @[kSoundArrowShot,
                          kSoundBirdHit,
                          kSoundLose, kSoundWin];
        
        //Placing music tracks which will be played in random order.
        _musicFiles = @[@"track_0.mp3", @"track_1.mp3",
                        @"track_2.mp3", @"track_3.mp3",
                        @"track_4.mp3", @"track_5.mp3"];
        
        //The music is currently stopped
        _currentTrack = nil;
        _nextTrack = nil;
    }
    
    return self;
}

-(void)playMusic
{
    //1: Checking if the music is not already playing (_currentTrack is used as a flag)
    if (_currentTrack)
    {
        NSLog(@"The music is already playing");
        return;
    }
    
    //2: Getting random current track and next track (can be same track, but thats easy to fix)
    int startTrackIndex = arc4random() % _musicFiles.count;
    int nextTrackIndex = arc4random() % _musicFiles.count;
    NSString *startTrack = [_musicFiles objectAtIndex:startTrackIndex];
    NSString *nextTrack  = [_musicFiles objectAtIndex:nextTrackIndex];
    
    //3: Playing current track
    _currentTrack = [OALAudioTrack track];
    _currentTrack.delegate = self;
    [_currentTrack preloadFile:startTrack];
    [_currentTrack play];
    
    //4: Only preloading next track
    _nextTrack = [OALAudioTrack track];
    [_nextTrack preloadFile:nextTrack];
}

-(void)nextTrack
{
    //1: Checking if the music wasn't stopped.
    if (!_currentTrack)
        return;
    
    //2: Next track becomes current track.
    _currentTrack = _nextTrack;
    _currentTrack.delegate = self;
    [_currentTrack play];
    
    //3: Picking random next track and preloading
    int nextTrackIndex = arc4random() % _musicFiles.count;
    NSString *nextTrack  = [_musicFiles objectAtIndex:nextTrackIndex];
    _nextTrack = [OALAudioTrack track];
    [_nextTrack preloadFile:nextTrack];
}

-(void)stopMusic
{
    if (!_currentTrack)
    {
        NSLog(@"The music is already stopped");
        return;
    }
    
    [_currentTrack stop];
    _currentTrack = nil;
    _nextTrack = nil;
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player
                       successfully:(BOOL)flag
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self nextTrack];
    });
}

-(void)playSoundEffect:(NSString *)soundFile
{
    [[OALSimpleAudio sharedInstance] playEffect:soundFile];
}

-(void)playSoundEffect:(NSString *)soundFile withPosition:(CGPoint)pos
{
    //Calculating pan depending on the bird position on the screen.
    float pan =  pos.x / [CCDirector sharedDirector].viewSize.width;
    pan = clampf(pan, 0.0f, 1.0f);
    pan = pan * 2.0f - 1.0f;
    
    //The only parameter we change is PAN
    [[OALSimpleAudio sharedInstance] playEffect:soundFile volume:1.0 pitch:1.0 pan:pan loop:NO];
}

-(void)playBackgroundSound:(NSString *)soundFile
{
    [[OALSimpleAudio sharedInstance] playBg:soundFile loop:YES];
}

-(void)preloadSoundEffects
{
    for (NSString *sound in _soundEffects)
    {
        [[OALSimpleAudio sharedInstance] preloadEffect:sound reduceToMono:NO completionBlock:^(ALBuffer *b)
         {
             NSLog(@"Sound %@ Preloaded", sound);
         }];
    }
}

+(AudioManager *)sharedAudioManager
{
    static dispatch_once_t pred;
    static AudioManager * _sharedInstance;
    dispatch_once(&pred, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

@end
