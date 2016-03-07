//
//  ModelVersionInfo.m
//  JumooreOA
//
//  Created by john on 15/7/4.
//  Copyright (c) 2015年 john. All rights reserved.
//

#import "ModelVersionInfo.h"
#import "HttpRequestUtil.h"

@implementation ModelVersionInfo

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        [self setValuesForKeysWithDictionary:dictionary];
    }
    return self;
}

+ (instancetype)ModelWithDictionary:(NSDictionary *)dictionary {
    return [[self alloc] initWithDictionary:dictionary];
}

// 必须都有，多了没关系，不能少，如果少了要实现 - (void)setValue:(id)value forUndefinedKey:(NSString *)key 方法，要不程序会闪退。
- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    if ([key isEqualToString:@"id"]) {// 替换 id 为 myId

    }
}

/** 将 获取到的 app store 上的 app 版本信息 转换成 ModelVersionInfo
app store 上的 app 信息：
{
    resultCount = 1;
    results =     (
                   {
                       bundleId = "com.jumoore.app.goldroad";
                       currentVersionReleaseDate = "2015-12-10T05:45:34Z";
                       description = "\U300a\U805a\U8d38\U91d1\U8def\U300b\U662f";
                       trackCensoredName = "\U805a\U8d38\U91d1\U8def";
                       trackName = "\U805a\U8d38\U91d1\U8def";
                       trackViewUrl = "https://itunes.apple.com/us/app/ju-mao-jin-lu/id1055904232?mt=8&uo=4";
                       version = "1.0.2";
                   }
                   );
}
 //*/
+ (ModelVersionInfo *)modelWithAppStoreVersionInfo:(NSDictionary *)versionInfo {
    if (!versionInfo) {
        return nil;
    }
    
    ModelVersionInfo *info = [[ModelVersionInfo alloc] init];
    
    @try {
        info.versionCode = [versionInfo objectForKey:@"version"];
        info.downloadUrl = [versionInfo objectForKey:@"trackViewUrl"];
        info.updateLog = [versionInfo objectForKey:@"releaseNotes"];
        info.forceUpdate = @"N";
    }
    @catch (NSException *exception) {
        NSLog(@"%@, %s", exception.description, __func__);
    }

    return info;
}

- (void)setVersionCode:(NSString *)versionCode {
    _versionCode = versionCode;
    
    NSString *version = [ModelVersionInfo getLocalVersion];// 本地版本
    version = [version stringByReplacingOccurrencesOfString:@"." withString:@""];
    
    // 本地版本 小于 线上版本，isNewestVersion 为 NO
    if (version.integerValue < _versionCode.integerValue) {// "1.1.0"
        self.isNewestVersion = NO;
    }
    else {
        self.isNewestVersion = YES;
    }
}

- (void)setForceUpdate:(NSString *)forceUpdate {
    _forceUpdate = forceUpdate;
    
    if (forceUpdate && [forceUpdate caseInsensitiveCompare:@"Y"] == NSOrderedSame) {
        self.isForceUpdate = YES;
    }
    else {
        self.isForceUpdate = NO;
    }
}

#pragma mark - AppStore 上的 app
//http://www.jianshu.com/p/ed449c6b4d4a
// 检查 app store 上的程序版本
- (void)checkAppVersionOfAppStore
{
    NSString *currentVersion = [ModelVersionInfo getLocalVersion];
    NSString *lastVersion = [ModelVersionInfo getCurrentAppStoreVersion];
    
    if (![lastVersion isEqualToString:currentVersion]) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"更新" message:@"有新的版本更新，是否前往更新？" delegate:self cancelButtonTitle:@"关闭" otherButtonTitles:@"更新", nil];
        alert.tag = 10000;
        [alert show];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"更新" message:@"此版本为最新版本" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        alert.tag = 10001;
        [alert show];
    }
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag==10000) {
        NSString *title = [alertView buttonTitleAtIndex:buttonIndex];

        if ([title isEqualToString:@"更新"]) {
            NSURL *url = [NSURL URLWithString:@"itms-apps://itunes.apple.com/us/app/id550383618?mt=8"];
            [[UIApplication sharedApplication]openURL:url];
        }
    }
}

// 本机版本号
+ (NSString *)getLocalVersion
{    
    NSDictionary *appInfo = [[NSBundle mainBundle] infoDictionary];
    NSString *currentVersion = [appInfo objectForKey:@"CFBundleVersion"];
    return currentVersion;
}

// 线上版本号
+ (NSDictionary *)getAppStoreVersion
{
    NSDictionary *versionInfo;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString: APPUPDATE_URL]];
    [request setHTTPMethod:@"POST"];
    NSHTTPURLResponse *urlResponse = nil;
    NSError *error = nil;
    NSData *recervedData = [NSURLConnection sendSynchronousRequest:request 
                                                returningResponse:&urlResponse 
                                                            error:&error];
    
    if (!error) {
        versionInfo = [NSJSONSerialization JSONObjectWithData:recervedData options:NSJSONReadingMutableContainers error:&error];
        
        if (versionInfo) {
            NSArray *infoArray = [versionInfo objectForKey:@"results"];
            versionInfo = infoArray.firstObject;
        }
    }
    
    if (error) {
        NSLog(@"%@, %s", error.localizedDescription, __FUNCTION__);
    }
    
    return versionInfo;
}

+ (NSString *)getCurrentAppStoreVersion
{
    NSDictionary *dic = [ModelVersionInfo getAppStoreVersion];

    NSString *lastVersion = [dic objectForKey:@"version"];
    DLog(@"HAHAHAHA%@",lastVersion);

    return lastVersion;
}

// 企业账号版本号
+ (NSDictionary *)getHouseVersion
{
    NSDictionary *versionInfo;
    
    versionInfo = [NSDictionary dictionaryWithContentsOfURL:
                   [NSURL URLWithString:[HttpRequestUtil VersionAddress]]];
    return versionInfo;
}

/** 获取版本号。它根据 gsIsAppOfAppStore 来决定调用 公司或企业的 app 版本信息
 * @param result: ModelVersionInfo
 */
void GetVersionInfoAsync(void(^successBlock)(id result), void(^errorBlock)(void))
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) 
                   {
                       NSDictionary *versionInfo;
                       
                       if (gsIsAppOfAppStore) // appStore 版本号
                       {
                           versionInfo = [ModelVersionInfo getAppStoreVersion];
                           
                           if ([GlobalMembers IsDictionarySafe:versionInfo]) {
                               ModelVersionInfo *version = [ModelVersionInfo modelWithAppStoreVersionInfo:versionInfo];
                               successBlock(version);
                           }
                           else {
                               errorBlock();
                           }
                       }
                       else // 企业账号版本号
                       {
                           versionInfo = [ModelVersionInfo getHouseVersion];
                           
                           if ([GlobalMembers IsDictionarySafe:versionInfo]) {
                               ModelVersionInfo *version = [[ModelVersionInfo alloc] initWithDictionary:versionInfo];
                               successBlock(version);
                           }
                           else {
                               errorBlock();
                           }
                       }
                   });
}
@end
