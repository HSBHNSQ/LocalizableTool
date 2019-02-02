//
//  HSBFFmpegUtil.m
//  RemoveWaterMark
//
//  Created by 何少博 on 2018/7/23.
//  Copyright © 2018年 iOS小分队. All rights reserved.
//

#import "HSBFFmpegUtil.h"
#import "ffmpeg.h"

@implementation HSBFFmpegUtil

+(instancetype)shareInstance{
    static HSBFFmpegUtil * _instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_instance == nil) {
            _instance = [[HSBFFmpegUtil alloc]init];
        }
    });
    return _instance;
}

-(NSString *)getFFmpegTimeFormat:(CGFloat)time{
    int h = time / (60 * 60);
    int m =  (time - h * 60 * 60) / 60;
    CGFloat s = time - h * 60 * 60 - m * 60;
    NSString * format = [NSString stringWithFormat:@"%02d:%02d:%02d",h,m,(int)roundf(s)];
//    if (s < 10) {
//        NSString * sec = [NSString stringWithFormat:@"0%02.3f",s];
//        format = [NSString stringWithFormat:@"%02d:%02d:%@",h,m,sec];
//    }
    return format;
}

-(NSString *)getTmpImagesDir{
    return [self getTmpPath:@"images"];
}
-(void)removeTmpImagesDir{
    [self removeTmpPath:@"images"];
}
-(NSString *)getTmpVideoDir{
    NSString * path = [NSTemporaryDirectory() stringByAppendingFormat:@"/tmp"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}
-(void)removeTmpVideoDir{
    NSString * path = [NSTemporaryDirectory() stringByAppendingFormat:@"/tmp"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
}

-(NSString *)getTmpPath:(NSString *)name{
    
    NSString * tmpPath = [[self getTmpVideoDir] stringByAppendingPathComponent:name];
    if (![[NSFileManager defaultManager] fileExistsAtPath:tmpPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:tmpPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return tmpPath;
    
}
-(void)removeTmpPath:(NSString *)name{
    NSString * path = [self getTmpPath:name];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
}





-(void)videoCrop:(CGRect)cropFrame
        biteRate:(CGFloat)biteRate
       inputPath:(NSString *)inputPath
      outputPath:(NSString *) outputPath
   progressBlock:(FFmpegProgressBlock) progressblock{
    [FFmpegProgress shareInstance].progressBlock = progressblock;
    [self startVideoCrop:cropFrame biteRate:biteRate inputPath:inputPath outputPath:outputPath];
}

-(void)videoCrop:(NSDictionary *)info{
    //    ffmpeg -i input_video.mp4 -filter:v "crop=100:120:100:50" output_video.mp4]
//    其中的crop=1080:1080:0:420裁剪参数，具体含义是 crop=width:height:x:y，其中width 和height 表示裁剪后的尺寸，x:y 表示裁剪区域的左上角坐标。
    
    NSString *inputPath = info[@"inputPath"];
    NSString *outputPath = info[@"outputPath"];
#if TARGET_OS_IPHONE
    CGRect frame = CGRectFromString(info[@"cropFrame"]);
#elif TARGET_OS_MAC
    NSRect frame = NSRectFromString(info[@"cropFrame"]);
#endif

    NSString *position = [NSString stringWithFormat:@"crop=%d:%d:%d:%d",(int)frame.size.width,(int)frame.size.height,(int)frame.origin.x,(int)frame.origin.y];
    char *movie = (char *)[inputPath UTF8String];
    char *outPic = (char *)[outputPath UTF8String];
    char *p = (char *)[position UTF8String];
     CGFloat biteRate = [info[@"biteRate"] floatValue];
    NSString * bS = [NSString stringWithFormat:@"%dK",(int)biteRate/1000];
    char *b = (char *)[bS UTF8String];

    if (biteRate > 100) {
        char* argv[] = {
            "ffmpeg",
            "-i",
            movie,
            "-filter:v",
            p,
            "-b:v",
            b,
            "-vcodec",
            "mpeg4",
            outPic
        };
        
        int argc = sizeof(argv)/sizeof(*argv);
        ffmpeg_main(argc, argv);
        for(int i=0;i<argc;i++)
            free(argv[i]);
        free(argv);
    }else{
        char* argv[] = {
            "ffmpeg",
            "-i",
            movie,
            "-filter:v",
            p,
            "-vcodec",
            "mpeg4",
            outPic
        };
        int argc = sizeof(argv)/sizeof(*argv);
        ffmpeg_main(argc, argv);
        for(int i=0;i<argc;i++)
            free(argv[i]);
        free(argv);
    }
}


#if TARGET_OS_IPHONE
- (void)startVideoCrop:(CGRect)cropFrame
              biteRate:(CGFloat)biteRate
             inputPath:(NSString *)inputPath
            outputPath:(NSString *) outputPath{
    NSDictionary * info = @{@"cropFrame":NSStringFromCGRect(cropFrame),
                            @"inputPath":inputPath,
                            @"outputPath":outputPath,
                            @"biteRate":[NSNumber numberWithFloat:biteRate]
                            };
#elif TARGET_OS_MAC
- (void)startVideoCrop:(NSRect)cropFrame
              biteRate:(CGFloat)biteRate
             inputPath:(NSString *)inputPath
            outputPath:(NSString *) outputPath{
    NSDictionary * info = @{@"cropFrame":NSStringFromRect(cropFrame),
                            @"inputPath":inputPath,
                            @"outputPath":outputPath,
                            @"biteRate":[NSNumber numberWithFloat:biteRate]
                            };
#endif
    
    NSThread * newT = [[NSThread alloc]initWithTarget:self selector:@selector(videoCrop:) object:info];
    [newT start];
}

-(void)sliceVideoImages:(float) r
              inputPath:(NSString *)inputPath
             outputPath:(NSString *) outputPath
          progressBlock:(FFmpegProgressBlock) progressblock{
     [FFmpegProgress shareInstance].progressBlock = progressblock;
    [self startSliceVideoImages:r inputPath:inputPath outputPath:outputPath];
}

//2.提取图片序列命令
//
//ffmpeg -i example.avi -r 1 -ss 00:00:26 -t 00:00:07 %03d.png
//1
//其中参数意义分别为：
//-i:后面跟视频文件路径
//-r:后面跟帧率，如1表示每秒一帧的速度
//-ss:提取图片的起始时间
//-t:结束时间
//%03d.png：提取图片的命名格式，用 3 位数字自动生成从小到大的文件名
-(void)sliceVideoImages:(NSDictionary *)info{
    NSString *inputPath = info[@"inputPath"];
    NSString *outputPath = info[@"outputPath"];
    NSNumber * rnumber = info[@"r"];
    NSString *rString = [NSString stringWithFormat:@"%f",rnumber.floatValue];
    char *movie = (char *)[inputPath UTF8String];
    char *outPic = (char *)[outputPath UTF8String];
    char *r = (char *)[rString UTF8String];
    char* argv[] = {
        "ffmpeg",
        "-i",
        movie,
        "-r",
        r,
        outPic
    };
    int argc = sizeof(argv)/sizeof(*argv);
    ffmpeg_main(argc, argv);
    for(int i=0;i<argc;i++)
        free(argv[i]);
    free(argv);
}

- (void)startSliceVideoImages:(float) r
               inputPath:(NSString *)inputPath
              outputPath:(NSString *) outputPath
{
    NSNumber * number = [NSNumber numberWithFloat:r];
    NSDictionary * info = @{@"r":number,
                            @"inputPath":inputPath,
                            @"outputPath":outputPath
                            };
    NSThread * newT = [[NSThread alloc]initWithTarget:self selector:@selector(sliceVideoImages:) object:info];
    [newT start];
    
}


-(void)removeLogo:(CGRect)logoFrame
        inputPath:(NSString *)inputPath
       outputPath:(NSString *) outputPath
    progressBlock:(FFmpegProgressBlock) progressblock{
    [FFmpegProgress shareInstance].progressBlock = progressblock;
    [self startRemoveLogo:logoFrame biteRate:0  inputPath:inputPath outputPath:outputPath];
}

-(void)removeLogo:(CGRect)logoFrame
         biteRate:(CGFloat)biteRate
        inputPath:(NSString *)inputPath
       outputPath:(NSString *) outputPath
    progressBlock:(FFmpegProgressBlock) progressblock{
    [FFmpegProgress shareInstance].progressBlock = progressblock;
    [self startRemoveLogo:logoFrame biteRate:biteRate inputPath:inputPath outputPath:outputPath];
}

-(void)removeLogo:(NSDictionary *)info{
    //    ffmpeg -i a.mp4 -b:v 548k -vf delogo=x=495:y=10:w=120:h=45:show=1 delogo.mp4
#if TARGET_OS_IPHONE
    CGRect frame = CGRectFromString(info[@"logoFrame"]);
#elif TARGET_OS_MAC
    NSRect frame = NSRectFromString(info[@"logoFrame"]);
#endif
    CGFloat biteRate = [info[@"biteRate"] floatValue];
    NSString *inputPath = info[@"inputPath"];
    NSString *outputPath = info[@"outputPath"];
    NSString *position = [NSString stringWithFormat:@"delogo=x=%d:y=%d:w=%d:h=%d",(int)frame.origin.x,(int)frame.origin.y,(int)frame.size.width,(int)frame.size.height];
    NSString * bS = [NSString stringWithFormat:@"%dK",(int)biteRate/1000];
    char *movie = (char *)[inputPath UTF8String];
    char *outPic = (char *)[outputPath UTF8String];
    char *p = (char *)[position UTF8String];
    char *b = (char *)[bS UTF8String];
    if (biteRate > 100) {
        char* argv[] = {
            "ffmpeg",
            "-i",
            movie,
            "-vf",
            p,
            "-b:v",
            b,
            "-vcodec",
            "mpeg4",
            outPic
        };
        int argc = sizeof(argv)/sizeof(*argv);
        ffmpeg_main(argc, argv);
        for(int i=0;i<argc;i++)
            free(argv[i]);
        free(argv);
    }else{
        char* argv[] = {
            "ffmpeg",
            "-i",
            movie,
            "-vf",
            p,
            "-vcodec",
            "mpeg4",
            outPic
        };//-b:v 1500K
        int argc = sizeof(argv)/sizeof(*argv);
        ffmpeg_main(argc, argv);
        for(int i=0;i<argc;i++)
            free(argv[i]);
        free(argv);
    }
    

}

#if TARGET_OS_IPHONE
- (void)startRemoveLogo:(CGRect )logoFrame
               biteRate:(CGFloat)biteRate
              inputPath:(NSString *)inputPath
             outputPath:(NSString *) outputPath{
    NSString * logoFrame = NSStringFromCGRect(logoFrame);
#elif TARGET_OS_MAC
- (void)startRemoveLogo:(NSRect )logoFrame
               biteRate:(CGFloat)biteRate
              inputPath:(NSString *)inputPath
             outputPath:(NSString *) outputPath{
    NSString * logoFrameString = NSStringFromRect(logoFrame);
#endif
    NSDictionary * info = @{@"logoFrame":logoFrameString,
                            @"inputPath":inputPath,
                            @"outputPath":outputPath,
                            @"biteRate":[NSNumber numberWithFloat:biteRate]
                            };
    NSThread * newT = [[NSThread alloc]initWithTarget:self selector:@selector(removeLogo:) object:info];
    
    [newT start];
}

- (void)addLogo:(NSString *)logoPath
       biteRate:(CGFloat)biteRate
      logoFrame:(CGRect)logoFrame
      inputPath:(NSString *)inputPath
     outputPath:(NSString *) outputPath
  progressBlock:(FFmpegProgressBlock) progressblock{
    [FFmpegProgress shareInstance].progressBlock = progressblock;
    [self startAddLogo:logoPath biteRate:biteRate logoFrame:logoFrame inputPath:inputPath outputPath:outputPath];
    
}

-(void)addLogo:(NSDictionary *)info{
    
    NSString *logoPath = info[@"logoPath"];
#if TARGET_OS_IPHONE
    CGRect frame =  CGRectFromString(info[@"logoFrame"]);
#elif TARGET_OS_MAC
    NSRect frame =  NSRectFromString(info[@"logoFrame"]);
#endif
    
    NSString *inputPath = info[@"inputPath"];
    NSString *outputPath = info[@"outputPath"];
    char *outPic = (char *)[outputPath UTF8String];
    char *movie = (char *)[inputPath UTF8String];
    char logo[1024];
    // 左上
    NSString * logoString = [NSString stringWithFormat:@"movie=%@ [logo]; [in][logo] overlay=%d:%d [out]",logoPath,(int)frame.origin.x,(int)frame.origin.y];
    sprintf(logo, "%s", [logoString UTF8String]);
     CGFloat biteRate = [info[@"biteRate"] floatValue];
     NSString * bS = [NSString stringWithFormat:@"%dK",(int)biteRate/1000];
     char *b = (char *)[bS UTF8String];
    if (biteRate > 100) {
        char* argv[] = {
            "ffmpeg",
            "-i",
            movie,
            "-vf",
            logo,
            "-b:v",
            b,
            "-vcodec",
            "mpeg4",
            outPic
        };
        int argc = sizeof(argv)/sizeof(*argv);
        ffmpeg_main(argc, argv);
        for(int i=0;i<argc;i++)
            free(argv[i]);
        free(argv);
    }else{
        char* argv[] = {
            "ffmpeg",
            "-i",
            movie,
            "-vf",
            logo,
            outPic
        };
        int argc = sizeof(argv)/sizeof(*argv);
        ffmpeg_main(argc, argv);
        for(int i=0;i<argc;i++)
            free(argv[i]);
        free(argv);
    }
    // 左下
    //sprintf(logo, "movie=%s [logo]; [in][logo] overlay=30:main_h-overlay_h-10 [out]", [BundlePath(@"ff.jpg") UTF8String]);
    
    // 右下
    //sprintf(logo, "movie=%s [logo]; [in][logo] overlay=main_w-overlay_w-10:main_h-overlay_h-10 [out]", [BundlePath(@"ff.jpg") UTF8String]);
    
    // 右上
    //sprintf(logo, "movie=%s [logo]; [in][logo] overlay=main_w-overlay_w-10:10 [out]", [BundlePath(@"ff.jpg") UTF8String]);
    
    
    
   
}


#if TARGET_OS_IPHONE
- (void)startAddLogo:(NSString *)logoPath
            biteRate:(CGFloat)biteRate
            logoFrame:(CGRect)logoFrame
            inputPath:(NSString *)inputPath
            outputPath:(NSString *)outputPath{
      NSString * logoFrameString = NSStringFromCGRect(logoFrame);
#elif TARGET_OS_MAC
- (void)startAddLogo:(NSString *)logoPath
            biteRate:(CGFloat)biteRate
            logoFrame:(NSRect)logoFrame
            inputPath:(NSString *)inputPath
            outputPath:(NSString *)outputPath{
      NSString * logoFrameString = NSStringFromRect(logoFrame);
#endif
         
    NSDictionary * info = @{
                            @"logoPath":logoPath,
                            @"biteRate":[NSNumber numberWithFloat:biteRate],
                            @"logoFrame":logoFrameString,
                            @"inputPath":inputPath,
                            @"outputPath":outputPath
                            };
    NSThread * newT = [[NSThread alloc]initWithTarget:self selector:@selector(addLogo:) object:info];
    
    [newT start];
    
}


-(void)clipVideo:(NSString *)startTime
       duration:(NSString *)duration
       inputPath:(NSString *)inputPath
      outputPath:(NSString *)outputPath
   progressBlock:(FFmpegProgressBlock) progressblock{
    [FFmpegProgress shareInstance].progressBlock = progressblock;
    [self startClipVideo:startTime duration:duration inputPath:inputPath outputPath:outputPath];
}

-(void)clipVideo:(NSDictionary *)info{
//ffmpeg -ss 10 -t 15 -accurate_seek -i test.mp4 -codec copy -avoid_negative_ts 1 cut.mp4
    NSString *startTime = info[@"startTime"];
    NSString *duration = info[@"duration"];
    NSString *inputPath = info[@"inputPath"];
    NSString *outputPath = info[@"outputPath"];
    
    char *b = (char *)[startTime UTF8String];
    char *d = (char *)[duration UTF8String];
    char *movie = (char *)[inputPath UTF8String];
    char *outPic = (char *)[outputPath UTF8String];
    
    char* argv[] = {
        "ffmpeg",
        "-ss",
        b,
        "-t",
        d,
        "-accurate_seek",
        "-i",
        movie,
        "-vcodec",
        "copy",
        "-acodec",
        "copy",
        "-avoid_negative_ts",
        "1",
        outPic
    };
//    ffmpeg -ss 10 -t 15 -accurate_seek -i test.mp4 -codec copy -avoid_negative_ts 1 cut.mp4
//    char* argv[] = {
//        "ffmpeg",
//        "-ss",
//        b,
//        "-t",
//        d,
//        "-i",
//        movie,
//        "-vcodec",
//        "copy",
//        "-acodec",
//        "copy",
//        outPic
//    };
    int argc = sizeof(argv)/sizeof(*argv);
    ffmpeg_main(argc, argv);
    for(int i=0;i<argc;i++)
        free(argv[i]);
    free(argv);
}
-(void)startClipVideo:(NSString *)startTime
             duration:(NSString *)duration
            inputPath:(NSString *)inputPath
           outputPath:(NSString *)outputPath{
    NSDictionary * info = @{
                            @"startTime":startTime,
                            @"duration":duration,
                            @"inputPath":inputPath,
                            @"outputPath":outputPath
                            };
    
    NSThread * newT = [[NSThread alloc]initWithTarget:self selector:@selector(clipVideo:) object:info];
    
    [newT start];
}







-(void)cutVideoStartTime:(NSString *)startTime
                 endTime:(NSString *)endTime
               inputPath:(NSString *)inputPath
              outputPath:(NSString *)outputPath
           progressBlock:(FFmpegProgressBlock) progressblock{
     [FFmpegProgress shareInstance].progressBlock = progressblock;
    [self startCutVideoStartTime:startTime endTime:endTime inputPath:inputPath outputPath:outputPath];
}

-(void)startCutVideoStartTime:(NSString *)startTime endTime:(NSString *)endTime  inputPath:(NSString *)inputPath
                   outputPath:(NSString *)outputPath{
    NSDictionary * info = @{
                            @"startTime":startTime,
                            @"endTime":endTime,
                            @"inputPath":inputPath,
                            @"outputPath":outputPath
                            };
    
    NSThread * newT = [[NSThread alloc]initWithTarget:self selector:@selector(cutVideo:) object:info];
    
    [newT start];
}
-(void)cutVideo:(NSDictionary *)info{
//    ffmpeg  -i ./plutopr.mp4 -vcodec copy -acodec copy -ss 00:00:10 -to 00:00:15 ./cutout1.mp4
//    ffmpeg  -y -i 原视频.mp4 -vcodec copy -acodec copy -ss 00:00:04 -to 00:00:08 cut_time.mp4
    NSString *startTime = info[@"startTime"];
    NSString *endTime = info[@"endTime"];
    NSString *inputPath = info[@"inputPath"];
    NSString *outputPath = info[@"outputPath"];
    
    char *start = (char *)[startTime UTF8String];
    char *end = (char *)[endTime UTF8String];
    char *movie = (char *)[inputPath UTF8String];
    char *outPic = (char *)[outputPath UTF8String];
    
    char* argv[] = {
        "ffmpeg",
        "-y"
        "-i",
        movie,
        "-vcodec",
        "copy",
        "-acodec",
        "copy",
        "-ss",
        start,
        "-to",
        end,
        outPic
    };
//    ffmpeg -i input.wmv -ss 30 -c copy -to 40 output.wmv
    int argc = sizeof(argv)/sizeof(*argv);
    ffmpeg_main(argc, argv);
    for(int i=0;i<argc;i++)
        free(argv[i]);
    free(argv);
}









@end
