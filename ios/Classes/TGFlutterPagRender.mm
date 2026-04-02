//
//  TGFlutterPageRender.m
//  Tgclub
//
//  Created by 黎敬茂 on 2021/11/25.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "TGFlutterPagRender.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <CoreVideo/CoreVideo.h>
#import <UIKit/UIKit.h>
#include <libpag/PAGPlayer.h>
#include <chrono>
#include <mutex>

@interface TGFlutterPagRender()

@property(nonatomic, strong)PAGSurface *surface;

@property(nonatomic, strong)PAGPlayer* player;

@property(nonatomic, strong)PAGFile* pagFile;

@property(nonatomic, assign)double initProgress;

@property(nonatomic, assign)BOOL endEvent;


@end

static int64_t GetCurrentTimeUS() {
  static auto START_TIME = std::chrono::high_resolution_clock::now();
  auto now = std::chrono::high_resolution_clock::now();
  auto ns = std::chrono::duration_cast<std::chrono::nanoseconds>(now - START_TIME);
  return static_cast<int64_t>(ns.count() * 1e-3);
}

@implementation TGFlutterPagRender
{
    FrameUpdateCallback _frameUpdateCallback;
    PAGEventCallback _eventCallback;
    CADisplayLink *_displayLink;
    int _lastUpdateTs;
    int _repeatCount;
    int64_t start;
    int64_t _currRepeatCount;
}

- (CVPixelBufferRef)copyPixelBuffer {
    
    int64_t duration = [_player duration];
    if(duration <= 0){
        duration = 1;
    }

    int64_t timestamp = GetCurrentTimeUS();
    if(start <= 0){
        start = timestamp;
    }
    auto count = (timestamp - start) / duration;
    double value = 0;
    if (_repeatCount >= 0 && count >= _repeatCount) {
        value = 1;
        if(!_endEvent){
            _endEvent = YES;
            _eventCallback(EventEnd);
        }
    } else {
        _endEvent = NO;
        double playTime = (timestamp - start) % duration;
        value = static_cast<double>(playTime) / duration;
        if (_currRepeatCount < count) {
            _currRepeatCount = count;
            _eventCallback(EventRepeat);
        }
    }
    [_player setProgress:value];
    [_player flush];
    CVPixelBufferRef target = [_surface getCVPixelBuffer];
    CVBufferRetain(target);
    return target;
}

- (UIColor *)colorFromARGB:(NSInteger)argb {
    return [UIColor colorWithRed:((argb >> 16) & 0xFF) / 255.0
                           green:((argb >> 8) & 0xFF) / 255.0
                            blue:(argb & 0xFF) / 255.0
                           alpha:1.0];
}

- (void)applyImageEdits:(NSArray *)images {
    if (!images || images.count == 0 || !_pagFile) return;
    for (NSUInteger idx = 0; idx < images.count; idx++) {
        if ((int)idx >= [_pagFile numImages]) break;
        id rawBytes = images[idx];
        if (rawBytes == NSNull.null || ![rawBytes isKindOfClass:FlutterStandardTypedData.class]) continue;
        NSData *imageData = ((FlutterStandardTypedData *)rawBytes).data;
        PAGImage *pagImage = [PAGImage FromBytes:imageData.bytes size:imageData.length];
        if (pagImage) {
            [_pagFile replaceImage:(int)idx data:pagImage];
        }
    }
}

- (void)applyTextEdits:(NSArray *)texts {
    if (!texts || texts.count == 0 || !_pagFile) return;
    for (NSUInteger idx = 0; idx < texts.count; idx++) {
        if ((int)idx >= [_pagFile numTexts]) break;
        id item = texts[idx];
        if (item == NSNull.null || ![item isKindOfClass:NSDictionary.class]) continue;
        NSDictionary *map = (NSDictionary *)item;
        PAGText *pagText = [_pagFile getTextData:(int)idx];
        if (!pagText) continue;
        if ([map[@"text"] isKindOfClass:NSString.class]) pagText.text = map[@"text"];
        if (map[@"fontSize"] && map[@"fontSize"] != NSNull.null) pagText.fontSize = [map[@"fontSize"] floatValue];
        if (map[@"fillColor"] && map[@"fillColor"] != NSNull.null) {
            pagText.fillColor = [self colorFromARGB:[map[@"fillColor"] integerValue]];
        }
        if (map[@"strokeColor"] && map[@"strokeColor"] != NSNull.null) {
            pagText.strokeColor = [self colorFromARGB:[map[@"strokeColor"] integerValue]];
        }
        if ([map[@"fontFamily"] isKindOfClass:NSString.class]) pagText.fontFamily = map[@"fontFamily"];
        if ([map[@"fontStyle"] isKindOfClass:NSString.class]) pagText.fontStyle = map[@"fontStyle"];
        [_pagFile replaceText:(int)idx data:pagText];
    }
}

- (instancetype)initWithPagData:(NSData*)pagData
                       progress:(double)initProgress
                         images:(nullable NSArray*)images
                          texts:(nullable NSArray*)texts
            frameUpdateCallback:(FrameUpdateCallback)frameUpdateCallback
                  eventCallback:(PAGEventCallback)eventCallback
{
    if (self = [super init]) {
        _frameUpdateCallback = frameUpdateCallback;
        _eventCallback = eventCallback;
        _initProgress = initProgress;
        if(pagData){
            _pagFile = [PAGFile Load:pagData.bytes size:pagData.length];
            _player = [[PAGPlayer alloc] init];
            [self applyImageEdits:images];
            [self applyTextEdits:texts];
            // 文字/图片替换完成后再绑定 composition，确保 PAG 内部 layout 包含最新替换内容
            [_player setComposition:_pagFile];
            _surface = [PAGSurface MakeFromGPU:CGSizeMake(_pagFile.width, _pagFile.height)];
            [_player setSurface:_surface];
            [_player setProgress:initProgress];
            [_player flush];
            // 有文字/图片替换时，部分设备首帧第一个文字图层右上角会被旧 clip 截断
            // 需额外 flush 一次，让 PAG 用稳定的 layout 重新渲染
            if ((images && images.count > 0) || (texts && texts.count > 0)) {
                [_player flush];
            }
            _frameUpdateCallback();
        }
    }
    return self;
}

- (instancetype)initWithPagData:(NSData*)pagData
                       progress:(double)initProgress
            frameUpdateCallback:(FrameUpdateCallback)frameUpdateCallback
                  eventCallback:(PAGEventCallback)eventCallback
{
    return [self initWithPagData:pagData
                        progress:initProgress
                          images:nil
                           texts:nil
             frameUpdateCallback:frameUpdateCallback
                   eventCallback:eventCallback];
}

- (void)startRender
{
    if (!_displayLink) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    if(start <= 0){
       start = GetCurrentTimeUS();
    }
    _eventCallback(EventStart);
}

- (void)stopRender
{
    if (_displayLink) {
        [_displayLink invalidate];
        _displayLink = nil;
    }
    [_player setProgress:_initProgress];
    [_player flush];
    _frameUpdateCallback();
    if(!_endEvent){
        _endEvent = YES;
        _eventCallback(EventEnd);
    }
    _eventCallback(EventCancel);
}

- (void)pauseRender{
    if (_displayLink) {
        [_displayLink invalidate];
        _displayLink = nil;
    }
}
- (void)setRepeatCount:(int)repeatCount{
    _repeatCount = repeatCount;
}

- (void)setProgress:(double)progress{
    [_player setProgress:progress];
    [_player flush];
    _frameUpdateCallback();
}

- (NSArray<NSString *> *)getLayersUnderPoint:(CGPoint)point{
    NSArray<PAGLayer*>* layers = [_player getLayersUnderPoint:point];
    NSMutableArray<NSString *> *layerNames = [[NSMutableArray alloc] init];
    for (PAGLayer *layer in layers) {
        [layerNames addObject:layer.layerName];
    }
    return layerNames;
}

- (CGSize)size{
    return CGSizeMake(_pagFile.width, _pagFile.height);
}

- (void)update
{
    _frameUpdateCallback();
}

- (void)releaseRender{
    if (_displayLink) {
        [_displayLink invalidate];
        _displayLink = nil;
    }
}

- (void)dealloc {
    _frameUpdateCallback = nil;
    _eventCallback = nil;
    _surface = nil;
    self.pagFile = nil;
    self.player = nil;
}
@end
