//
//  JWDInteractionLogger.m
//  JWDInputOutputStream
//
//  Created by 蒋伟东 on 2017/3/22.
//  Copyright © 2017年 YIXIA. All rights reserved.
//

#import "JWDInteractionLogger.h"
#import <UIKit/UIKit.h>
@interface JWDInteractionLogger ()<NSStreamDelegate,UIDocumentInteractionControllerDelegate>

@property (nonatomic, strong) NSOutputStream                    *writeLogStream;//!< <#value#>
@property (nonatomic, strong) UIDocumentInteractionController   *interactionController;//!< <#value#>

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

- (void)sendLogFileWithFileName:(NSString *)fileName {

    NSURL *fileurl = [self getPathWithFileName:fileName];
    
    if (!fileurl) {
        NSLog(@"日志文件不存在");
        return;
    }
    
    // 判断文件是否存在
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExists = [fileManager fileExistsAtPath:[fileurl path]];
    if (!isExists) {
        return;
    }
    // 获取文件大小
    NSError *error = nil;
    CGFloat fileSize = [[fileManager attributesOfItemAtPath:[fileurl path] error:&error] fileSize]/1024.0f;
    if (error) {
        NSLog(@"获取日志失败");
        return;
    }
    if (fileSize == 0) {
        NSLog(@"获取日志失败，文件不存在");
    }else {
        self.interactionController = [UIDocumentInteractionController interactionControllerWithURL:fileurl];
        self.interactionController.delegate = self;
        UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
        while (vc.presentedViewController) {
            vc = vc.presentedViewController;
        }
        if (vc!=nil) {
            [self.interactionController presentOptionsMenuFromRect:vc.view.bounds inView:vc.view animated:YES];
        }
    }
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

        tempString = [tempString stringByAppendingFormat:@"appName--%@,version--%@,date--%@ ,[文件名:%s]" "[函数名:%s]" "[行号:%d] \n %@ \n",appName,version,dateStr,[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __FUNCTION__,__LINE__,logString];
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
    
    NSString *cacheDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
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
