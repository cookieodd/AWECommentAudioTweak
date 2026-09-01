// 工具方法
// @cookieodd | github.com/cookieodd | t.me/cookieodd

#import "AWECAUtils.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#include <dlfcn.h>

typedef struct archive archive_t;
typedef struct archive_entry archive_entry_t;
typedef int64_t la_int64_t;

static archive_t* (*p_archive_read_new)(void);
static int (*p_archive_read_support_format_zip)(archive_t*);
static int (*p_archive_read_support_filter_all)(archive_t*);
static int (*p_archive_read_open_filename)(archive_t*, const char*, size_t);
static int (*p_archive_read_next_header)(archive_t*, archive_entry_t**);
static const char* (*p_archive_entry_pathname)(archive_entry_t*);
static int (*p_archive_entry_filetype)(archive_entry_t*);
static int (*p_archive_read_data_block)(archive_t*, const void**, size_t*, la_int64_t*);
static int (*p_archive_read_data_skip)(archive_t*);
static int (*p_archive_read_close)(archive_t*);
static int (*p_archive_read_free)(archive_t*);
static const char* (*p_archive_error_string)(archive_t*);

#define ARCHIVE_OK 0
#define AE_IFDIR 0040000
#define AE_IFREG 0100000

static BOOL s_archiveLoaded = NO;

static BOOL loadArchiveLibrary(void) {
    if (s_archiveLoaded) return YES;
    void *handle = dlopen("/usr/lib/libarchive.2.dylib", RTLD_LAZY);
    if (!handle) {
        handle = dlopen("/usr/lib/libarchive.dylib", RTLD_LAZY);
    }
    if (!handle) return NO;

    p_archive_read_new = dlsym(handle, "archive_read_new");
    p_archive_read_support_format_zip = dlsym(handle, "archive_read_support_format_zip");
    p_archive_read_support_filter_all = dlsym(handle, "archive_read_support_filter_all");
    p_archive_read_open_filename = dlsym(handle, "archive_read_open_filename");
    p_archive_read_next_header = dlsym(handle, "archive_read_next_header");
    p_archive_entry_pathname = dlsym(handle, "archive_entry_pathname");
    p_archive_entry_filetype = dlsym(handle, "archive_entry_filetype");
    p_archive_read_data_block = dlsym(handle, "archive_read_data_block");
    p_archive_read_data_skip = dlsym(handle, "archive_read_data_skip");
    p_archive_read_close = dlsym(handle, "archive_read_close");
    p_archive_read_free = dlsym(handle, "archive_read_free");
    p_archive_error_string = dlsym(handle, "archive_error_string");

    s_archiveLoaded = (p_archive_read_new && p_archive_read_next_header && p_archive_read_data_block);
    return s_archiveLoaded;
}

@implementation AWECAUtils

#pragma mark - 路径

+ (NSString *)documentsPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return paths.firstObject;
}

+ (NSString *)audioSavePath {
    return [[self documentsPath] stringByAppendingPathComponent:kAWECAAudioDir];
}

+ (NSString *)importPath {
    return [[self documentsPath] stringByAppendingPathComponent:kAWECAImportDir];
}

+ (NSString *)ttsPath {
    return [[self documentsPath] stringByAppendingPathComponent:@"AWECommentAudio/Ai合成"];
}

+ (NSString *)ttsVolcanoPath {
    return [[self ttsPath] stringByAppendingPathComponent:@"火山引擎"];
}

+ (void)ensureDirectoriesExist {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *audioDir = [self audioSavePath];
    NSString *importDir = [self importPath];
    NSString *volcanoDir = [self ttsVolcanoPath];

    if (![fm fileExistsAtPath:audioDir]) {
        [fm createDirectoryAtPath:audioDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if (![fm fileExistsAtPath:importDir]) {
        [fm createDirectoryAtPath:importDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if (![fm fileExistsAtPath:volcanoDir]) {
        [fm createDirectoryAtPath:volcanoDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

#pragma mark - Toast

+ (void)showToast:(NSString *)message {
    [self showToast:message duration:1.8];
}

+ (void)showToast:(NSString *)message duration:(NSTimeInterval)duration {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = nil;
        for (UIScene *s in [UIApplication sharedApplication].connectedScenes) {
            if (s.activationState == UISceneActivationStateForegroundActive && [s isKindOfClass:[UIWindowScene class]]) {
                for (UIWindow *w in ((UIWindowScene *)s).windows) {
                    if (w.isKeyWindow) {
                        keyWindow = w;
                        break;
                    }
                }
                if (keyWindow) break;
            }
        }
        if (!keyWindow) return;

        UILabel *toastLabel = [[UILabel alloc] init];
        toastLabel.text = message;
        toastLabel.textColor = [UIColor whiteColor];
        toastLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.78];
        toastLabel.textAlignment = NSTextAlignmentCenter;
        toastLabel.font = [UIFont systemFontOfSize:14];
        toastLabel.numberOfLines = 0;
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds = YES;
        toastLabel.alpha = 0;

        CGSize maxSize = CGSizeMake(keyWindow.bounds.size.width - 80, CGFLOAT_MAX);
        CGSize textSize = [message boundingRectWithSize:maxSize
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                            attributes:@{NSFontAttributeName: toastLabel.font}
                                               context:nil].size;

        CGFloat width = textSize.width + 32;
        CGFloat height = textSize.height + 20;
        toastLabel.frame = CGRectMake((keyWindow.bounds.size.width - width) / 2,
                                      (keyWindow.bounds.size.height - height) / 2,
                                      width, height);

        [keyWindow addSubview:toastLabel];

        [UIView animateWithDuration:0.3 animations:^{
            toastLabel.alpha = 1;
        } completion:^(BOOL finished) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.3 animations:^{
                    toastLabel.alpha = 0;
                } completion:^(BOOL finished) {
                    [toastLabel removeFromSuperview];
                }];
            });
        }];
    });
}

#pragma mark - 转码

+ (void)convertAudioAtPath:(NSString *)inputPath
              toOutputPath:(NSString *)outputPath
                completion:(void(^)(BOOL success, NSError *error))completion {
    if (![[NSFileManager defaultManager] fileExistsAtPath:inputPath]) {
        if (completion) completion(NO, nil);
        return;
    }

    NSString *ext = inputPath.pathExtension.lowercaseString;
    if ([ext isEqualToString:@"m4a"] || [ext isEqualToString:@"aac"]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
        BOOL ok = [[NSFileManager defaultManager] copyItemAtPath:inputPath toPath:outputPath error:&error];
        if (completion) completion(ok, error);
        return;
    }

    NSURL *inputURL = [NSURL fileURLWithPath:inputPath];
    AVAsset *asset = [AVAsset assetWithURL:inputURL];

    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:asset
                                                                    presetName:AVAssetExportPresetAppleM4A];
    if (!session) {
        if (completion) completion(NO, nil);
        return;
    }

    [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];

    session.outputURL = [NSURL fileURLWithPath:outputPath];
    session.outputFileType = AVFileTypeAppleM4A;

    [session exportAsynchronouslyWithCompletionHandler:^{
        BOOL success = (session.status == AVAssetExportSessionStatusCompleted);
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(success, session.error);
            });
        }
    }];
}

static NSData *AWECABuildWAV(NSData *pcm, uint32_t sampleRate, uint16_t channels, uint16_t bits) {
    uint32_t dataSize = (uint32_t)pcm.length;
    uint32_t byteRate = sampleRate * channels * (bits / 8);
    uint16_t blockAlign = channels * (bits / 8);
    uint32_t chunkSize = 36 + dataSize;
    uint32_t fmtSize = 16;
    uint16_t audioFormat = 1;
    NSMutableData *wav = [NSMutableData dataWithCapacity:44 + dataSize];
    [wav appendBytes:"RIFF" length:4];
    [wav appendBytes:&chunkSize length:4];
    [wav appendBytes:"WAVE" length:4];
    [wav appendBytes:"fmt " length:4];
    [wav appendBytes:&fmtSize length:4];
    [wav appendBytes:&audioFormat length:2];
    [wav appendBytes:&channels length:2];
    [wav appendBytes:&sampleRate length:4];
    [wav appendBytes:&byteRate length:4];
    [wav appendBytes:&blockAlign length:2];
    [wav appendBytes:&bits length:2];
    [wav appendBytes:"data" length:4];
    [wav appendBytes:&dataSize length:4];
    [wav appendData:pcm];
    return wav;
}

+ (void)convertAudioAtPath:(NSString *)inputPath
              toWAV16kPath:(NSString *)outputPath
                completion:(void(^)(BOOL success, NSError *error))completion {
    void (^done)(BOOL, NSError *) = ^(BOOL ok, NSError *err) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{ completion(ok, err); });
        }
    };
    if (![[NSFileManager defaultManager] fileExistsAtPath:inputPath]) {
        done(NO, nil);
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *err = nil;
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:inputPath]
                                                options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @YES}];
        AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        if (!track) { done(NO, nil); return; }

        AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:asset error:&err];
        if (!reader) { done(NO, err); return; }

        NSDictionary *settings = @{
            AVFormatIDKey: @(kAudioFormatLinearPCM),
            AVSampleRateKey: @16000,
            AVNumberOfChannelsKey: @1,
            AVLinearPCMBitDepthKey: @16,
            AVLinearPCMIsNonInterleaved: @NO,
            AVLinearPCMIsFloatKey: @NO,
            AVLinearPCMIsBigEndianKey: @NO
        };
        AVAssetReaderTrackOutput *output = [[AVAssetReaderTrackOutput alloc] initWithTrack:track outputSettings:settings];
        output.alwaysCopiesSampleData = YES;
        if (![reader canAddOutput:output]) { done(NO, nil); return; }
        [reader addOutput:output];
        if (![reader startReading]) { done(NO, reader.error); return; }

        NSMutableData *pcm = [NSMutableData data];
        while (reader.status == AVAssetReaderStatusReading) {
            CMSampleBufferRef sb = [output copyNextSampleBuffer];
            if (!sb) break;
            CMBlockBufferRef bb = CMSampleBufferGetDataBuffer(sb);
            if (bb) {
                size_t len = CMBlockBufferGetDataLength(bb);
                if (len > 0) {
                    NSMutableData *chunk = [NSMutableData dataWithLength:len];
                    if (CMBlockBufferCopyDataBytes(bb, 0, len, chunk.mutableBytes) == kCMBlockBufferNoErr) {
                        [pcm appendData:chunk];
                    }
                }
            }
            CFRelease(sb);
        }
        if (pcm.length == 0) { done(NO, reader.error); return; }

        NSData *wav = AWECABuildWAV(pcm, 16000, 1, 16);
        [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
        BOOL ok = [wav writeToFile:outputPath atomically:YES];
        done(ok, nil);
    });
}

#pragma mark - 时长

+ (double)audioDurationAtPath:(NSString *)path {
    if (!path || ![[NSFileManager defaultManager] fileExistsAtPath:path]) return 0;
    NSURL *url = [NSURL fileURLWithPath:path];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    return CMTimeGetSeconds(asset.duration);
}

#pragma mark - 文件名

+ (NSString *)generateFilenameForCommentID:(NSString *)commentID duration:(long long)duration {
    NSTimeInterval ts = [[NSDate date] timeIntervalSince1970];
    return [NSString stringWithFormat:@"评论_%@_%llds_%.0f.m4a",
            commentID ?: @"unknown", duration, ts];
}

+ (NSString *)sanitizeFilename:(NSString *)name maxLength:(NSUInteger)maxLen {
    if (!name || name.length == 0) return @"未命名";
    NSCharacterSet *illegal = [NSCharacterSet characterSetWithCharactersInString:@"/\\:*?\"<>|"];
    NSString *clean = [[name componentsSeparatedByCharactersInSet:illegal] componentsJoinedByString:@""];
    clean = [clean stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (clean.length == 0) return @"未命名";
    if (clean.length > maxLen) clean = [clean substringToIndex:maxLen];
    return clean;
}

#pragma mark - 顶层VC

+ (UIViewController *)topViewController {
    UIWindowScene *scene = nil;
    for (UIScene *s in [UIApplication sharedApplication].connectedScenes) {
        if (s.activationState == UISceneActivationStateForegroundActive && [s isKindOfClass:[UIWindowScene class]]) {
            scene = (UIWindowScene *)s;
            break;
        }
    }
    if (!scene) return nil;

    UIWindow *keyWindow = nil;
    for (UIWindow *w in scene.windows) {
        if (w.isKeyWindow) {
            keyWindow = w;
            break;
        }
    }
    if (!keyWindow) return nil;

    UIViewController *vc = keyWindow.rootViewController;
    while (vc.presentedViewController) {
        vc = vc.presentedViewController;
    }
    if ([vc isKindOfClass:[UINavigationController class]]) {
        vc = ((UINavigationController *)vc).topViewController;
    }
    if ([vc isKindOfClass:[UITabBarController class]]) {
        vc = ((UITabBarController *)vc).selectedViewController;
    }
    return vc;
}

#pragma mark - 解压

+ (BOOL)extractZipAtPath:(NSString *)zipPath toDirectory:(NSString *)destDir error:(NSError **)error {
    if (!zipPath || !destDir) {
        if (error) *error = [NSError errorWithDomain:@"AWECAUtils" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"路径为空"}];
        return NO;
    }

    if (!loadArchiveLibrary()) {
        if (error) *error = [NSError errorWithDomain:@"AWECAUtils" code:-2 userInfo:@{NSLocalizedDescriptionKey: @"libarchive 不可用"}];
        return NO;
    }

    [[NSFileManager defaultManager] createDirectoryAtPath:destDir withIntermediateDirectories:YES attributes:nil error:nil];

    archive_t *a = p_archive_read_new();
    p_archive_read_support_format_zip(a);
    p_archive_read_support_filter_all(a);

    int r = p_archive_read_open_filename(a, zipPath.UTF8String, 10240);
    if (r != ARCHIVE_OK) {
        NSString *msg = [NSString stringWithFormat:@"打开 zip 失败: %s", p_archive_error_string(a)];
        if (error) *error = [NSError errorWithDomain:@"AWECAUtils" code:r userInfo:@{NSLocalizedDescriptionKey: msg}];
        p_archive_read_free(a);
        return NO;
    }

    archive_entry_t *entry;
    BOOL success = YES;

    while (p_archive_read_next_header(a, &entry) == ARCHIVE_OK) {
        const char *entryPath = p_archive_entry_pathname(entry);
        if (!entryPath) continue;

        NSString *entryName = [NSString stringWithUTF8String:entryPath];
        if ([entryName hasPrefix:@"__MACOSX"] || [entryName hasPrefix:@"."]) {
            p_archive_read_data_skip(a);
            continue;
        }

        NSString *fullPath = [destDir stringByAppendingPathComponent:entryName];

        int type = p_archive_entry_filetype(entry);
        if (type == AE_IFDIR) {
            [[NSFileManager defaultManager] createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:nil];
        } else if (type == AE_IFREG) {
            [[NSFileManager defaultManager] createDirectoryAtPath:[fullPath stringByDeletingLastPathComponent]
                                      withIntermediateDirectories:YES attributes:nil error:nil];

            FILE *f = fopen(fullPath.UTF8String, "wb");
            if (!f) {
                p_archive_read_data_skip(a);
                continue;
            }

            const void *buff;
            size_t size;
            la_int64_t offset;
            while (p_archive_read_data_block(a, &buff, &size, &offset) == ARCHIVE_OK) {
                fwrite(buff, 1, size, f);
            }
            fclose(f);
        } else {
            p_archive_read_data_skip(a);
        }
    }

    p_archive_read_close(a);
    p_archive_read_free(a);

    return success;
}
@end
