//
//  JWDInteractionLogger.h
//  JWDInputOutputStream
//
//  Created by 蒋伟东 on 2017/3/22.
//  Copyright © 2017年 YIXIA. All rights reserved.
//



#import <Foundation/Foundation.h>

#define JWDINSlog(logString,fileName) [JWDInteractionLogger writeLogWithLogString:logString fileName:fileName]

@interface JWDInteractionLogger : NSObject

+(JWDInteractionLogger *)shareInteractionLogger;

- (void)writeLogWithLogString:(NSString *)logString fileName:(NSString *)fileName;

@end

