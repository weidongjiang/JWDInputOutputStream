//
//  JWDInteractionLogger.h
//  JWDInputOutputStream
//
//  Created by 蒋伟东 on 2017/3/22.
//  Copyright © 2017年 YIXIA. All rights reserved.
//



#import <Foundation/Foundation.h>

/**
 日志文件名在这里 统一 标记，作为全局的名称

 */
#define JWDlogName     @"star"
#define JWDINSlogName  @"more-star"

/**
 只需要引入 宏 传递相应的参数

 @param logString 需要记录的日志内容
 @param fileName 日志文件名
 @return 日志宏
 */
#define JWDINSlog(logString,fileName) [[JWDInteractionLogger shareInteractionLogger] writeLogWithLogString:logString withfileName:fileName]



@interface JWDInteractionLogger : NSObject

+(JWDInteractionLogger *)shareInteractionLogger;

/**
 使用单例 调用

 @param logString 需要记录的日志内容
 @param fileName 日志文件名
 */
- (void)writeLogWithLogString:(NSString *)logString withfileName:(NSString *)fileName;

/**
 发送 和 分享日志文件，便于查阅

 @param fileName 文件名
 */
- (void)sendLogFileWithFileName:(NSString *)fileName;

@end

