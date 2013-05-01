//
//  FliteTTS.m
//  iPhone Text To Speech based on Flite
//
//  Copyright (c) 2010 Sam Foster
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
// 
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//  Author: Sam Foster <samfoster@gmail.com> <http://cmang.org>
//  Copyright 2010. All rights reserved.
//

#import "FliteTTS.h"


cst_voice *register_cmu_us_kal();
cst_voice *register_cmu_us_kal16();
cst_voice *register_cmu_us_rms();
cst_voice *register_cmu_us_awb();
cst_voice *register_cmu_us_slt();

@implementation FliteTTS

@synthesize audioPlayer;
@synthesize isSpeaking;
@synthesize speechQueue;

-(id)init 
{
    if((self = [super init]))
    {
        self.isSpeaking = NO;
        self.speechQueue = [NSMutableArray array];
        
        flite_init();
        [self setVoice:@"cmu_us_kal"];
    }
    
    return self;
}

- (void)dealloc 
{
    if(self.audioPlayer) [self.audioPlayer stop];
    self.audioPlayer = nil;
    self.speechQueue = nil;
    
    //[super dealloc];
}

-(void)speakText:(NSString *)text 
{
    [self.speechQueue addObject:text];
    [self speakIfNeeded];
}

- (void)speakIfNeeded {
    if(self.isSpeaking || self.speechQueue.count == 0) return;
    
    self.isSpeaking = YES;
    
    NSString * text = [self.speechQueue objectAtIndex:0];
    [NSThread detachNewThreadSelector:@selector(speakNowText:) toTarget:self withObject:text];
    
    [self.speechQueue removeObjectAtIndex:0];
}

-(void)speakNowText:(NSString *)text 
{
    //NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    NSMutableString * cleanString = [NSMutableString stringWithString:@""];
    
    if([text length] > 1)
    {
        int x = 0;
        while (x < [text length])
        {
            unichar ch = [text characterAtIndex:x];
            [cleanString appendFormat:@"%c", ch];
            x++;
        }
    }
    
    if(cleanString == nil)
    {   // string is empty
        cleanString = [NSMutableString stringWithString:@""];
    }
    
    cst_wave * wave = flite_text_to_wave([cleanString UTF8String], voice);
    
    // copy sound into soundData
    NSData * soundData = [self riffDataForCSTWave:wave];
    
    delete_wave(wave);
    
    NSError * error;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithData:soundData error:&error];
    
    if(error) 
    {
        NSLog(@"AVAudioPlayer Error: %@", error.localizedDescription);
        self.isSpeaking = NO;
    }
    else 
    {
        [self.audioPlayer setDelegate:self];
        [self.audioPlayer prepareToPlay];
        [self.audioPlayer play];
    }
    
    //[pool drain];
    
    //[NSThread exit];
}

- (NSData *)riffDataForCSTWave:(cst_wave *)speechwaveform {
    
    // Let's make a virtual wav file
    
    char *headerstring;
    short headershort;
    int headerint;
    int numberofbytes;
    SInt8 *wavBuffer = (SInt8 *)malloc((speechwaveform->num_samples * 2) + 8 + 16 + 12 + 8);
    
    int writeoffset = 0;
    headerstring = "RIFF";
    memcpy(wavBuffer + writeoffset,headerstring,4);
    writeoffset += 4;
    
    numberofbytes = (speechwaveform->num_samples * 2) + 8 + 16 + 12;
    memcpy(wavBuffer + writeoffset,&numberofbytes,4);
    writeoffset += 4;
    
    headerstring = "WAVE";
    memcpy(wavBuffer + writeoffset,headerstring,4);
    writeoffset += 4;
    
    headerstring = "fmt ";
    memcpy(wavBuffer + writeoffset,headerstring,4);
    writeoffset += 4;
    
    numberofbytes = 16;
    memcpy(wavBuffer + writeoffset,&numberofbytes,4);
    writeoffset += 4;
    
    headershort = 0x0001;  // Type of sample, this is for PCM
    memcpy(wavBuffer + writeoffset,&headershort,2);
    writeoffset += 2;
    
    headershort = 1; // channels
    memcpy(wavBuffer + writeoffset,&headershort,2);
    writeoffset += 2;
    
    headerint = speechwaveform->sample_rate;  // rate
    memcpy(wavBuffer + writeoffset,&headerint,4);
    writeoffset += 4;
    
    headerint = (speechwaveform->sample_rate * 1 * sizeof(short)); // bytes per second
    memcpy(wavBuffer + writeoffset,&headerint,4);
    writeoffset += 4;
    
    headershort = (1 * sizeof(short)); // block alignment
    memcpy(wavBuffer + writeoffset,&headershort,2);
    writeoffset += 2;
    
    headershort = 2 * 8; // bits per sample
    memcpy(wavBuffer + writeoffset,&headershort,2);
    writeoffset += 2;
    
    headerstring = "data";
    memcpy(wavBuffer + writeoffset,headerstring,4);
    writeoffset += 4;
    
    headerint = (speechwaveform->num_samples * 2); // bytes in the sample buffer
    memcpy(wavBuffer + writeoffset,&headerint,4);
    writeoffset += 4;
    
    memcpy(wavBuffer + writeoffset,speechwaveform->samples,speechwaveform->num_samples * 2);
    
    int overallsize = (speechwaveform->num_samples * 1 * sizeof(short)) + 8 + 16 + 12 + 8;
    NSData *data = [[NSData alloc] initWithBytes:wavBuffer length:overallsize];
    
    /*NSMutableData * soundData = [NSMutableData data];
    int num_bytes, d_int;
    short d_short;
    
    // add RIFF header
    [soundData appendBytes:"RIFF" length:4];
    num_bytes = (cst_wave_num_samples(wave) * cst_wave_num_channels(wave) * sizeof(short)) + 8 + 16 + 12;
    [soundData appendBytes:&num_bytes length:sizeof(num_bytes)];
    [soundData appendBytes:"WAVEfmt " length:8];
    num_bytes = 16;
    [soundData appendBytes:&num_bytes length:sizeof(num_bytes)];
    d_short = RIFF_FORMAT_PCM;
    [soundData appendBytes:&d_short length:sizeof(d_short)];
    d_short = cst_wave_num_channels(wave);
    [soundData appendBytes:&d_short length:sizeof(d_short)];
    d_int = cst_wave_sample_rate(wave);  
    [soundData appendBytes:&d_int length:sizeof(d_int)];
    d_int = (cst_wave_sample_rate(wave) * cst_wave_num_channels(wave) * sizeof(short)); 
     [soundData appendBytes:&d_int length:sizeof(d_int)];
    d_short = (cst_wave_num_channels(wave) * sizeof(short))
    [soundData appendBytes:&d_short length:sizeof(d_short)];
    d_short = 2 * 8; 
    [soundData appendBytes:&d_short length:sizeof(d_short)];
    [soundData appendBytes:"data" length:4];
    d_int = (cst_wave_num_channels(wave) * cst_wave_num_samples(wave) * sizeof(short)); 
    [soundData appendBytes:&d_int length:sizeof(d_int)];
    [soundData appendData:[NSData dataWithBytes:wave->samples length:d_int]];*/
    
    return data;
}

-(void)setPitch:(float)pitch variance:(float)variance speed:(float)speed
{
    feat_set_float(voice->features,"int_f0_target_mean", pitch);
    feat_set_float(voice->features,"int_f0_target_stddev", variance);
    feat_set_float(voice->features,"duration_stretch", speed); 
}

-(void)setVoice:(NSString *)voicename
{
    if([voicename isEqualToString:@"cmu_us_kal"]) {
        voice = register_cmu_us_kal();
    }
    else if([voicename isEqualToString:@"cmu_us_kal16"]) {
        voice = register_cmu_us_kal16();
    }
    else if([voicename isEqualToString:@"cmu_us_rms"]) {
        voice = register_cmu_us_rms();
    }
    else if([voicename isEqualToString:@"cmu_us_awb"]) {
        voice = register_cmu_us_awb();
    }
    else if([voicename isEqualToString:@"cmu_us_slt"]) {
        voice = register_cmu_us_slt();
    }
}

-(void)stopSpeaking
{
    [self.speechQueue removeAllObjects];
    [self.audioPlayer stop];
    self.audioPlayer = nil;
    self.isSpeaking = NO;
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag 
{
    self.audioPlayer = nil;
    self.isSpeaking = NO;
    
    [self speakIfNeeded];
}

@end