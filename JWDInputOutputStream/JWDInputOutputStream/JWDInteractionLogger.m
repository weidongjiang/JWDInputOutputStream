//
//  JWDInteractionLogger.m
//  JWDInputOutputStream
//
//  Created by 蒋伟东 on 2017/3/22.
//  Copyright © 2017年 YIXIA. All rights reserved.
//

#import "JWDInteractionLogger.h"

@interface JWDInteractionLogger ()<NSStreamDelegate>

@property (nonatomic, strong) NSOutputStream      *writeLogStream;//!< <#value#>

@end


@implementation JWDInteractionLogger


static JWDInteractionLogger *interactionLogger = nil;

+(JWDInteractionLogger *)shareInteractionLogger {

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        interactionLogger = [[JWDInteractionLogger alloc] init];
    });
    return interactionLogger;
}

- (void)writeLogWithLogString:(NSString *)logString withfileName:(NSString *)fileName{
    
    if (self.writeLogStream == nil) {
        self.writeLogStream = [self creatStreamWithFileName:fileName];
    }
    NSData *data = [self getDataWithLogString:logString];
    [self.writeLogStream write:[data bytes] maxLength:data.length];
    [self.writeLogStream close];
    [self.writeLogStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    self.writeLogStream = nil;
    
}

- (NSData *)getDataWithLogString:(NSString *)logString {

    NSString *tempString = [[NSString alloc] init];
    if (logString.length == 0) {
        tempString = @"\n";
    }else {
        NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
        NSString *appName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
        NSString *version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
        
        NSDate *date = [NSDate date];
        NSDateFormatter *forMatter = [[NSDateFormatter alloc] init];
        [forMatter setDateFormat:@"yyyy年MM月dd日 HH时mm分ss秒"];
        NSString *dateStr = [forMatter stringFromDate:date];

        tempString = [tempString stringByAppendingFormat:@"appName--%@,version--%@,%@ \n %@ \n",appName,version,dateStr,logString];
    }
    NSData *data = [tempString dataUsingEncoding:NSUTF8StringEncoding];

    return data;
}


/**
 创建 流写 实例

 @param fileName 类型名
 */
- (NSOutputStream *)creatStreamWithFileName:(NSString *)fileName {

    NSURL *url = [self getPathWithFileName:fileName];
    NSOutputStream *outputStream = [[NSOutputStream alloc] initWithURL:url append:YES];
    outputStream.delegate = self;
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [outputStream open];
    return outputStream;
}


/**
 创建文件路径

 @param fileName 文件名称
 @return 路径
 */
-(NSURL *)getPathWithFileName:(NSString *)fileName {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *cacheDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    BOOL isDir = TRUE;
    BOOL isDirExists = [fileManager fileExistsAtPath:cacheDir isDirectory:&isDir];
    
    if (!isDirExists) {
        NSError *err = nil;
        BOOL isCreateDirSuccess = [fileManager createDirectoryAtPath:cacheDir withIntermediateDirectories:NO attributes:nil error:&err];
        if (!isCreateDirSuccess) {
            NSLog(@"创建cache路径失败：%@",err.description);
            return nil;
        }
    }
    
    NSString *filePath = [[cacheDir stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:@"txt"];
    BOOL isFileExists = [fileManager fileExistsAtPath:filePath];
    if (isFileExists) {
        //存在
        NSError *err = nil;
        float fileSizeKB = [[fileManager attributesOfItemAtPath:filePath error:&err] fileSize] / 1024.0f;
        if (err) {
            NSLog(@"获取文件大小失败：%@",err.description);
        }
        if (fileSizeKB > 10240) {
            NSError *err = nil;
            BOOL isRmSuccess = [fileManager removeItemAtPath:filePath error:&err];
            if (!isRmSuccess) {
                NSLog(@"删除文件失败：%@",err.description);
            }
            BOOL isCreateFileSuccess = [fileManager createFileAtPath:filePath contents:nil attributes:nil];
            if (!isCreateFileSuccess) {
                NSLog(@"创建文件失败：%@",err.description);
                return nil;
            }
        }
    } else {
        //不存在
        NSError *err = nil;
        BOOL isCreateFileSuccess = [fileManager createFileAtPath:filePath contents:nil attributes:nil];
        if (!isCreateFileSuccess) {
            NSLog(@"创建文件失败：%@",err.description);
            return nil;
        }
    }
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    if (!fileURL) {
        NSLog(@"获取沙盒相对文件URL失败");
        return nil;
    }
    return fileURL;
}
@end
