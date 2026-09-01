// 语音替换
// @cookieodd | github.com/cookieodd | t.me/cookieodd

#import "AWECAAudioReplacer.h"
#import "AWECAUtils.h"

#define kAWECATTSAudioPath @"AWECATTSAudioPath"

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

- (BOOL)isUsingTTS {
    if (!self.enabled || !self.replacementAudioPath || !self.ttsAudioPath) return NO;
    return [self.replacementAudioPath isEqualToString:self.ttsAudioPath];
}

- (void)setReplacementFromPath:(NSString *)path completion:(void(^)(BOOL success))completion {
    if (!path || ![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if (completion) completion(NO);
        return;
    }

    NSString *ext = path.pathExtension.lowercaseString;

    if ([ext isEqualToString:@"m4a"] || [ext isEqualToString:@"aac"]) {
        self.replacementAudioPath = path;
        self.enabled = YES;
        [self saveState];
        if (completion) completion(YES);
    } else {
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

#pragma mark - TTS 替换

- (void)setReplacementFromTTSPath:(NSString *)path
                             text:(NSString *)text
                        voiceName:(NSString *)voiceName
                       completion:(void(^)(BOOL success))completion {
    if (!path || ![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if (completion) completion(NO);
        return;
    }

    [AWECAUtils ensureDirectoriesExist];

    NSString *destDir = [AWECAUtils ttsVolcanoPath];

    NSString *cleanText = [AWECAUtils sanitizeFilename:text maxLength:20];
    NSString *cleanVoice = [AWECAUtils sanitizeFilename:voiceName maxLength:20];
    NSString *fileName = [NSString stringWithFormat:@"%@-%@.m4a", cleanText, cleanVoice];
    NSString *outputPath = [destDir stringByAppendingPathComponent:fileName];

    if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath]) {
        fileName = [NSString stringWithFormat:@"%@-%@_%.0f.m4a", cleanText, cleanVoice, [[NSDate date] timeIntervalSince1970]];
        outputPath = [destDir stringByAppendingPathComponent:fileName];
    }

    NSString *ext = path.pathExtension.lowercaseString;
    NSString *originalPath = [path copy];

    if ([ext isEqualToString:@"m4a"] || [ext isEqualToString:@"aac"]) {
        [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
        NSError *err = nil;
        BOOL ok = [[NSFileManager defaultManager] copyItemAtPath:path toPath:outputPath error:&err];
        if (ok) {
            [[NSFileManager defaultManager] removeItemAtPath:originalPath error:nil];
            self.replacementAudioPath = outputPath;
            self.enabled = YES;
            [self saveState];
        }
        if (completion) completion(ok);
    } else {
        [AWECAUtils convertAudioAtPath:path toOutputPath:outputPath completion:^(BOOL success, NSError *error) {
            if (success) {
                [[NSFileManager defaultManager] removeItemAtPath:originalPath error:nil];
                self.replacementAudioPath = outputPath;
                self.enabled = YES;
                [self saveState];
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
    [[NSFileManager defaultManager] removeItemAtPath:targetPath error:nil];
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
    [defaults setObject:self.ttsAudioPath forKey:kAWECATTSAudioPath];
    [defaults synchronize];
}

- (void)loadState {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.enabled = [defaults boolForKey:kAWECAReplacementEnabled];
    self.replacementAudioPath = [defaults objectForKey:kAWECAReplacementAudioPath];
    self.ttsAudioPath = [defaults objectForKey:kAWECATTSAudioPath];

    if (self.replacementAudioPath && ![[NSFileManager defaultManager] fileExistsAtPath:self.replacementAudioPath]) {
        self.enabled = NO;
        self.replacementAudioPath = nil;
        [self saveState];
    }
    if (self.ttsAudioPath && ![[NSFileManager defaultManager] fileExistsAtPath:self.ttsAudioPath]) {
        self.ttsAudioPath = nil;
        [self saveState];
    }
}

@end
