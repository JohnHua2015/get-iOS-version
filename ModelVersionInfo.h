//
//  ModelVersionInfo.h
//  JumooreOA
//
//  Created by john on 15/7/4.
//  Copyright (c) 2015年 john. All rights reserved.
//

// 更新请求地址 
static NSString *const APPUPDATE_URL = @"https://itunes.apple.com/lookup?id=1090313458";// 1055904232;

static BOOL gsIsAppOfAppStore = YES;// 是不是 appStore 上的 app

#import <Foundation/Foundation.h>

@interface ModelVersionInfo : NSObject

@property (strong, nonatomic) NSString *versionCode;// @"1.1.3"
@property (strong, nonatomic) NSString *downloadUrl;// @"http://www.cnmsl.cn/OA/app/html/view/download.html"
@property (strong, nonatomic) NSString *updateLog;// @"最新版本已经发布，为避免影响您的使用......
@property (strong, nonatomic) NSString *forceUpdate;// 是否强制更新

@property (assign, nonatomic) BOOL isNewestVersion;// 是否是最新版本。YES：是
@property (assign, nonatomic) BOOL isForceUpdate;


- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
+ (instancetype)ModelWithDictionary:(NSDictionary *)dictionary;

// 将 获取到的 app store 上的 app 版本信息 转换成 ModelVersionInfo
+ (ModelVersionInfo *)modelWithAppStoreVersionInfo:(NSDictionary *)versionInfo;


// 本机版本号
+ (NSString *)getLocalVersion;

/** 获取版本号。它根据 gsIsAppOfAppStore 来决定调用 公司或企业的 app 版本信息
 * @param result: ModelVersionInfo
 */
void GetVersionInfoAsync(void(^successBlock)(id result), void(^errorBlock)(void));

@end
