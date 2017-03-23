//
//  JWDOutputInputStream.h
//  JWDInputOutputStream
//
//  Created by 蒋伟东 on 2017/3/23.
//  Copyright © 2017年 YIXIA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JWDOutputInputStream : NSObject

+ (JWDOutputInputStream *)shareOutputInputStream;

/**
 读取文件
 
 @param filePath 需要读取文件的地址
 */
- (void)creatInputStreamWithFilePath:(NSString *) filePath;
/**
 创建 写入流
 
 @param filePath 内容写入的文件地址
 */
- (void)creatOutputStreamWithFilePath:(NSString *) filePath;
@end
