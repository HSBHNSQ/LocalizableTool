//
//  HSBFFmpegUtil.h
//  RemoveWaterMark
//
//  Created by 何少博 on 2018/7/23.
//  Copyright © 2018年 iOS小分队. All rights reserved.
//

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>

#elif TARGET_OS_MAC
#import <Foundation/Foundation.h>
#endif



#import "FFmpegProgress.h"

@interface HSBFFmpegUtil : NSObject

+(instancetype)shareInstance;

-(NSString *)getFFmpegTimeFormat:(CGFloat)time;

-(NSString *)getTmpVideoDir;
-(void)removeTmpVideoDir;



#if TARGET_OS_IPHONE
-(void)videoCrop:(CGRect)cropFrame
        biteRate:(CGFloat)biteRate
       inputPath:(NSString *)inputPath
      outputPath:(NSString *) outputPath
   progressBlock:(FFmpegProgressBlock) progressblock;

-(void)removeLogo:(CGRect)logoFrame
        inputPath:(NSString *)inputPath
       outputPath:(NSString *) outputPath
    progressBlock:(FFmpegProgressBlock) progressblock;

-(void)removeLogo:(CGRect)logoFrame
         biteRate:(CGFloat)biteRate
        inputPath:(NSString *)inputPath
       outputPath:(NSString *) outputPath
    progressBlock:(FFmpegProgressBlock) progressblock;

- (void)addLogo:(NSString *)logoPath
       biteRate:(CGFloat)biteRate
      logoFrame:(CGRect)logoFrame
      inputPath:(NSString *)inputPath
     outputPath:(NSString *) outputPath
  progressBlock:(FFmpegProgressBlock) progressblock;

#elif TARGET_OS_MAC
-(void)videoCrop:(NSRect)cropFrame
        biteRate:(CGFloat)biteRate
       inputPath:(NSString *)inputPath
      outputPath:(NSString *) outputPath
   progressBlock:(FFmpegProgressBlock) progressblock;

-(void)removeLogo:(NSRect)logoFrame
        inputPath:(NSString *)inputPath
       outputPath:(NSString *) outputPath
    progressBlock:(FFmpegProgressBlock) progressblock;

-(void)removeLogo:(NSRect)logoFrame
         biteRate:(CGFloat)biteRate
        inputPath:(NSString *)inputPath
       outputPath:(NSString *) outputPath
    progressBlock:(FFmpegProgressBlock) progressblock;

- (void)addLogo:(NSString *)logoPath
       biteRate:(CGFloat)biteRate
      logoFrame:(NSRect)logoFrame
      inputPath:(NSString *)inputPath
     outputPath:(NSString *) outputPath
  progressBlock:(FFmpegProgressBlock) progressblock;
#endif


/**
 提取图片

 @param r 每秒几张
 */
-(void)sliceVideoImages:(float)r
              inputPath:(NSString *)inputPath
             outputPath:(NSString *)outputPath
          progressBlock:(FFmpegProgressBlock) progressblock;

-(void)clipVideo:(NSString *)startTime
        duration:(NSString *)duration
       inputPath:(NSString *)inputPath
      outputPath:(NSString *)outputPath
   progressBlock:(FFmpegProgressBlock) progressblock;

-(void)cutVideoStartTime:(NSString *)startTime
        endTime:(NSString *)endTime
       inputPath:(NSString *)inputPath
      outputPath:(NSString *)outputPath
   progressBlock:(FFmpegProgressBlock) progressblock;
@end
