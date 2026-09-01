// 录音转音色
// @cookieodd | github.com/cookieodd | t.me/cookieodd

#import "AWECARecordEnhance.h"
#import "AWECATTSManager.h"
#import "AWECAAudioReplacer.h"
#import "AWECAUtils.h"
#import <UIKit/UIKit.h>

#define kASRFlashURL @"https://openspeech.bytedance.com/api/v3/auc/bigmodel/recognize/flash"
#define kASRResourceId @"volc.bigasr.auc_turbo"
#define kEnhanceTimeout 60.0

@interface AWECARecordEnhance ()
@property (nonatomic, assign) BOOL armed;
@property (nonatomic, assign) BOOL busy;
@property (nonatomic, copy) NSString *inFlightPath;
@property (nonatomic, copy) NSString *lastEnhancedPath;
@property (nonatomic, copy) NSString *lastFailedPath;
@property (nonatomic, copy) NSString *lastMessage;
@property (nonatomic, strong) NSMutableArray *waiters;
@property (nonatomic, assign) BOOL finishedOnce;
@property (nonatomic, assign) NSUInteger pipelineEpoch;
@end

@implementation AWECARecordEnhance

+ (instancetype)shared {
    static AWECARecordEnhance *inst;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        inst = [[AWECARecordEnhance alloc] init];
        inst.waiters = [NSMutableArray array];
        inst->_enhanceEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kAWECAEnhanceEnabled];
    });
    return inst;
}

+ (BOOL)shouldShowStatusDot {
    AWECARecordEnhance *enhance = [AWECARecordEnhance shared];
    return [AWECAAudioReplacer shared].enabled || enhance.enhanceEnabled;
}

- (void)setEnhanceEnabled:(BOOL)enhanceEnabled {
    if (_enhanceEnabled == enhanceEnabled) return;
    _enhanceEnabled = enhanceEnabled;
    [[NSUserDefaults standardUserDefaults] setBool:enhanceEnabled forKey:kAWECAEnhanceEnabled];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [AWECARecordEnhance refreshStatusDots];
}

static void AWECAWalkHideStatusDots(UIView *v, BOOL hide) {
    if (v.tag == kAWECAStatusDotTag) v.hidden = hide;
    for (UIView *s in v.subviews) AWECAWalkHideStatusDots(s, hide);
}

+ (void)refreshStatusDots {
    BOOL hide = ![self shouldShowStatusDot];
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        for (UIWindow *w in ((UIWindowScene *)scene).windows) AWECAWalkHideStatusDots(w, hide);
    }
}

- (void)armFromCommentButton {
    self.armed = YES;
}

- (void)markCommentTakeStarted {
    self.armed = YES;
}

- (void)markCommentTakeCancelled {
    if (self.busy) return;
    self.armed = NO;
}

- (BOOL)hasVolcanoCredentials {
    AWECATTSManager *mgr = [AWECATTSManager shared];
    return mgr.accessToken.length > 0 || mgr.appID.length > 0;
}

- (BOOL)shouldRunForCommentRecording {
    return self.enhanceEnabled && self.armed && [self hasVolcanoCredentials];
}

- (BOOL)shouldSkipStickyReplaceForPath:(NSString *)path {
    if (self.busy) return YES;
    if (self.enhanceEnabled && self.armed) return YES;
    if (path.length && [self.lastEnhancedPath isEqualToString:path]) return YES;
    if (path.length && [self.lastFailedPath isEqualToString:path]) return YES;
    return NO;
}

- (void)beginIfNeededAtPath:(NSString *)path {
    [self waitForEnhancedPath:path completion:nil];
}

- (void)waitForEnhancedPath:(NSString *)path
                 completion:(void(^)(BOOL ok, NSString *message))completion {
    if (!path.length) {
        if (completion) completion(NO, nil);
        return;
    }
    if (!self.busy && [self.lastEnhancedPath isEqualToString:path]) {
        if (completion) completion(YES, self.lastMessage);
        return;
    }
    if (!self.busy && [self.lastFailedPath isEqualToString:path]) {
        if (completion) completion(NO, self.lastMessage);
        return;
    }
    if (completion) [self.waiters addObject:[completion copy]];
    if (self.busy) return;
    [self startPipelineAtPath:path];
}

- (void)flushWaitersOk:(BOOL)ok message:(NSString *)msg {
    NSArray *list = [self.waiters copy];
    [self.waiters removeAllObjects];
    for (void (^cb)(BOOL, NSString *) in list) {
        cb(ok, msg);
    }
}

- (void)finishPipelineOk:(BOOL)ok path:(NSString *)path message:(NSString *)msg {
    if (self.finishedOnce) return;
    self.finishedOnce = YES;
    self.pipelineEpoch += 1;
    self.busy = NO;
    self.inFlightPath = nil;
    self.lastMessage = msg;
    if (ok) {
        self.lastEnhancedPath = path;
        self.lastFailedPath = nil;
    } else {
        self.lastFailedPath = path;
    }
    [self flushWaitersOk:ok message:msg];
}

- (void)startPipelineAtPath:(NSString *)path {
    self.busy = YES;
    self.finishedOnce = NO;
    self.inFlightPath = path;
    self.lastFailedPath = nil;
    NSUInteger epoch = ++self.pipelineEpoch;

    [AWECAUtils showToast:@"识别合成中..." duration:2.0];

    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kEnhanceTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (weakSelf.pipelineEpoch != epoch) return;
        [weakSelf finishPipelineOk:NO path:path message:@"识别合成超时，已保留原声"];
    });

    [self recognizeAudioAtPath:path completion:^(NSString *text, NSString *error) {
        if (weakSelf.finishedOnce || weakSelf.pipelineEpoch != epoch) return;
        if (!text.length) {
            [weakSelf finishPipelineOk:NO path:path message:error.length ? error : @"识别失败，已保留原声"];
            return;
        }
        [AWECAUtils showToast:@"正在合成..." duration:2.0];
        [[AWECATTSManager shared] synthesizeVolcanoPreviewText:text completion:^(BOOL success, NSString *audioPath, NSString *ttsError) {
            if (weakSelf.finishedOnce || weakSelf.pipelineEpoch != epoch) return;
            if (!success || !audioPath.length) {
                [weakSelf finishPipelineOk:NO path:path message:ttsError.length ? [NSString stringWithFormat:@"%@，已保留原声", ttsError] : @"合成失败，已保留原声"];
                return;
            }
            [weakSelf installSynthesizedAudio:audioPath ontoPath:path completion:^(BOOL installed) {
                if (weakSelf.finishedOnce || weakSelf.pipelineEpoch != epoch) return;
                if (installed) {
                    [weakSelf finishPipelineOk:YES path:path message:@"已转换为所选音色"];
                } else {
                    [weakSelf finishPipelineOk:NO path:path message:@"写入失败，已保留原声"];
                }
            }];
        }];
    }];
}

#pragma mark - 语音识别

- (NSString *)audioFormatForPath:(NSString *)path {
    NSString *ext = path.pathExtension.lowercaseString;
    if ([ext isEqualToString:@"m4a"] || [ext isEqualToString:@"aac"] ||
        [ext isEqualToString:@"mp3"] || [ext isEqualToString:@"wav"] ||
        [ext isEqualToString:@"ogg"] || [ext isEqualToString:@"mp4"]) {
        return ext;
    }
    if ([ext isEqualToString:@"caf"]) return @"aac";
    return @"m4a";
}

- (NSString *)textFromASRJSON:(NSDictionary *)json {
    id result = json[@"result"];
    if ([result isKindOfClass:[NSString class]]) return [(NSString *)result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([result isKindOfClass:[NSDictionary class]]) {
        NSString *text = result[@"text"];
        if (text.length) return [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSArray *utterances = result[@"utterances"];
        if ([utterances isKindOfClass:[NSArray class]]) {
            NSMutableString *buf = [NSMutableString string];
            for (id u in utterances) {
                if (![u isKindOfClass:[NSDictionary class]]) continue;
                NSString *t = u[@"text"];
                if (t.length) [buf appendString:t];
            }
            if (buf.length) return [buf stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
    }
    NSString *text = json[@"text"];
    if ([text isKindOfClass:[NSString class]] && text.length) {
        return [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    return nil;
}

- (void)recognizeAudioAtPath:(NSString *)path completion:(void(^)(NSString *text, NSString *error))completion {
    NSString *wavPath = [path stringByAppendingString:@".aweca.wav"];
    [AWECAUtils convertAudioAtPath:path toWAV16kPath:wavPath completion:^(BOOL success, NSError *error) {
        NSString *sendPath = success ? wavPath : path;
        [self postFlashASRAtPath:sendPath completion:^(NSString *text, NSString *err) {
            [[NSFileManager defaultManager] removeItemAtPath:wavPath error:nil];
            if (completion) completion(text, err);
        }];
    }];
}

- (void)postFlashASRAtPath:(NSString *)path completion:(void(^)(NSString *text, NSString *error))completion {
    AWECATTSManager *mgr = [AWECATTSManager shared];
    NSData *audio = [NSData dataWithContentsOfFile:path];
    if (!audio.length) {
        if (completion) completion(nil, @"录音文件为空");
        return;
    }

    NSString *b64 = [audio base64EncodedStringWithOptions:0];
    BOOL isWav = [[path.pathExtension lowercaseString] isEqualToString:@"wav"];
    NSMutableDictionary *audioDict = [@{
        @"data": b64,
        @"format": isWav ? @"wav" : [self audioFormatForPath:path]
    } mutableCopy];
    if (isWav) {
        audioDict[@"rate"] = @16000;
        audioDict[@"bits"] = @16;
        audioDict[@"channel"] = @1;
        audioDict[@"codec"] = @"raw";
    }
    audioDict[@"language"] = @"zh-CN";

    NSDictionary *body = @{
        @"user": @{ @"uid": mgr.appID.length ? mgr.appID : @"aweca_user" },
        @"audio": audioDict,
        @"request": @{
            @"model_name": @"bigmodel",
            @"enable_itn": @YES,
            @"enable_punc": @YES
        }
    };
    NSError *jsonErr = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jsonErr];
    if (!jsonData) {
        if (completion) completion(nil, @"识别请求构造失败");
        return;
    }

    NSString *reqId = [[NSUUID UUID] UUIDString];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kASRFlashURL]];
    req.HTTPMethod = @"POST";
    req.HTTPBody = jsonData;
    req.timeoutInterval = 45;
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [mgr applyVolcanoHTTPAuthToRequest:req];
    [req setValue:kASRResourceId forHTTPHeaderField:@"X-Api-Resource-Id"];
    [req setValue:reqId forHTTPHeaderField:@"X-Api-Request-Id"];
    [req setValue:@"-1" forHTTPHeaderField:@"X-Api-Sequence"];

    [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        void (^fail)(NSString *) = ^(NSString *msg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(nil, msg);
            });
        };
        if (error) {
            fail([NSString stringWithFormat:@"识别网络错误: %@", error.localizedDescription]);
            return;
        }
        NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
        NSString *apiCode = http.allHeaderFields[@"X-Api-Status-Code"];
        if (!apiCode) apiCode = http.allHeaderFields[@"x-api-status-code"];
        NSString *apiMsg = http.allHeaderFields[@"X-Api-Message"] ?: http.allHeaderFields[@"x-api-message"];
        if (apiCode.length && ![apiCode isEqualToString:@"20000000"] && ![apiCode isEqualToString:@"0"]) {
            NSString *hint = apiMsg.length ? apiMsg : @"失败";
            if ([apiCode isEqualToString:@"45001115"]) hint = @"音频解码失败";
            fail([NSString stringWithFormat:@"识别错误(%@): %@", apiCode, hint]);
            return;
        }
        if (!data.length) {
            fail(@"识别无响应");
            return;
        }
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (![json isKindOfClass:[NSDictionary class]]) {
            fail(@"识别响应解析失败");
            return;
        }
        NSInteger code = [json[@"code"] integerValue];
        if (json[@"code"] && code != 0 && code != 20000000 && code != 3000) {
            NSString *msg = json[@"message"] ?: json[@"msg"] ?: @"识别失败";
            fail([NSString stringWithFormat:@"识别错误(%ld): %@", (long)code, msg]);
            return;
        }
        NSString *text = [self textFromASRJSON:json];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(text.length ? text : nil, text.length ? nil : @"未识别到文字");
        });
    }] resume];
}

#pragma mark - 覆盖本次录音

- (void)installSynthesizedAudio:(NSString *)synthPath ontoPath:(NSString *)targetPath completion:(void(^)(BOOL ok))completion {
    if (![[NSFileManager defaultManager] fileExistsAtPath:synthPath]) {
        if (completion) completion(NO);
        return;
    }
    NSString *ext = synthPath.pathExtension.lowercaseString;
    if ([ext isEqualToString:@"m4a"] || [ext isEqualToString:@"aac"]) {
        NSError *err = nil;
        [[NSFileManager defaultManager] removeItemAtPath:targetPath error:nil];
        BOOL ok = [[NSFileManager defaultManager] copyItemAtPath:synthPath toPath:targetPath error:&err];
        if (completion) completion(ok);
        return;
    }

    NSString *tmp = [targetPath stringByAppendingString:@".aweca.m4a"];
    [[NSFileManager defaultManager] removeItemAtPath:tmp error:nil];
    [AWECAUtils convertAudioAtPath:synthPath toOutputPath:tmp completion:^(BOOL success, NSError *error) {
        if (!success) {
            if (completion) completion(NO);
            return;
        }
        [[NSFileManager defaultManager] removeItemAtPath:targetPath error:nil];
        NSError *mvErr = nil;
        BOOL ok = [[NSFileManager defaultManager] moveItemAtPath:tmp toPath:targetPath error:&mvErr];
        if (!ok) {
            ok = [[NSFileManager defaultManager] copyItemAtPath:tmp toPath:targetPath error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:tmp error:nil];
        }
        if (completion) completion(ok);
    }];
}

@end
