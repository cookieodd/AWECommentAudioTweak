// 音频替换器impl，录音？不存在的
// @cookieodd | github.com/cookieodd | t.me/cookieodd

#import "AWECAAudioReplacer.h"
#import "AWECAUtils.h"

@implementation AWECAAudioReplacer

+ (instancetype)shared {
    static AWECAAudioReplacer *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AWECAAudioReplacer alloc] init];
        [instance loadState];
    });
    return instance;
}

#pragma mark - 设置替换

- (void)setReplacementFromPath:(NSString *)path completion:(void(^)(BOOL success))completion {
    if (!path || ![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if (completion) completion(NO);
        return;
    }

    NSString *ext = path.pathExtension.lowercaseString;

    // m4a/aac直接上，其他的转一下
    if ([ext isEqualToString:@"m4a"] || [ext isEqualToString:@"aac"]) {
        self.replacementAudioPath = path;
        self.enabled = YES;
        [self saveState];
        if (completion) completion(YES);
    } else {
        // 格式不对，转码走起
        [AWECAUtils ensureDirectoriesExist];
        NSString *outputName = [NSString stringWithFormat:@"converted_%.0f.m4a",
                                [[NSDate date] timeIntervalSince1970]];
        NSString *outputPath = [[AWECAUtils importPath] stringByAppendingPathComponent:outputName];

        [AWECAUtils convertAudioAtPath:path toOutputPath:outputPath completion:^(BOOL success, NSError *error) {
            if (success) {
                self.replacementAudioPath = outputPath;
                self.enabled = YES;
                [self saveState];
                [AWECAUtils showToast:@"音频已转码并设置"];
            } else {
                [AWECAUtils showToast:@"音频转码失败"];
            }
            if (completion) completion(success);
        }];
    }
}

#pragma mark - 清除

- (void)clearReplacement {
    self.enabled = NO;
    self.replacementAudioPath = nil;
    [self saveState];
    [AWECAUtils showToast:@"已关闭语音替换"];
}

#pragma mark - 执行替换

- (BOOL)replaceAudioAtPath:(NSString *)targetPath {
    if (!self.enabled || !self.replacementAudioPath) {
        return NO;
    }

    if (![[NSFileManager defaultManager] fileExistsAtPath:self.replacementAudioPath]) {
        [self clearReplacement];
        return NO;
    }

    NSError *error = nil;
    // 干掉原始录音
    [[NSFileManager defaultManager] removeItemAtPath:targetPath error:nil];
    // 替换音频copy过去
    BOOL ok = [[NSFileManager defaultManager] copyItemAtPath:self.replacementAudioPath
                                                      toPath:targetPath
                                                       error:&error];
    return ok;
}

#pragma mark - 持久化

- (void)saveState {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:self.enabled forKey:kAWECAReplacementEnabled];
    [defaults setObject:self.replacementAudioPath forKey:kAWECAReplacementAudioPath];
    [defaults synchronize];
}

- (void)loadState {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.enabled = [defaults boolForKey:kAWECAReplacementEnabled];
    self.replacementAudioPath = [defaults objectForKey:kAWECAReplacementAudioPath];

    // 路径没了就自动关掉
    if (self.replacementAudioPath && ![[NSFileManager defaultManager] fileExistsAtPath:self.replacementAudioPath]) {
        self.enabled = NO;
        self.replacementAudioPath = nil;
        [self saveState];
    }
}

@end
