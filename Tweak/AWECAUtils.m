// 工具人实现，苦力都在这
// @cookieodd | github.com/cookieodd | t.me/cookieodd

#import "AWECAUtils.h"
#import <AVFoundation/AVFoundation.h>
#include <dlfcn.h>

// libarchive 类型和函数指针，运行时 dlsym 加载
typedef struct archive archive_t;
typedef struct archive_entry archive_entry_t;
typedef int64_t la_int64_t;

// 函数指针，dlsym 一把梭
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
    // Documents，音频的家
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return paths.firstObject;
}

+ (NSString *)audioSavePath {
    return [[self documentsPath] stringByAppendingPathComponent:kAWECAAudioDir];
}

+ (NSString *)importPath {
    return [[self documentsPath] stringByAppendingPathComponent:kAWECAImportDir];
}

+ (void)ensureDirectoriesExist {
    // 没目录就建，有就算了
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *audioDir = [self audioSavePath];
    NSString *importDir = [self importPath];

    if (![fm fileExistsAtPath:audioDir]) {
        [fm createDirectoryAtPath:audioDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if (![fm fileExistsAtPath:importDir]) {
        [fm createDirectoryAtPath:importDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

#pragma mark - Toast

+ (void)showToast:(NSString *)message {
    // 主线程弹 toast，UIKit 规矩不能破
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *topVC = [self topViewController];
        if (!topVC) return;

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

        CGSize maxSize = CGSizeMake(topVC.view.bounds.size.width - 80, CGFLOAT_MAX);
        CGSize textSize = [message boundingRectWithSize:maxSize
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                            attributes:@{NSFontAttributeName: toastLabel.font}
                                               context:nil].size;

        CGFloat width = textSize.width + 32;
        CGFloat height = textSize.height + 20;
        toastLabel.frame = CGRectMake((topVC.view.bounds.size.width - width) / 2,
                                      topVC.view.bounds.size.height - 160,
                                      width, height);

        [topVC.view addSubview:toastLabel];

        [UIView animateWithDuration:0.3 animations:^{
            toastLabel.alpha = 1;
        } completion:^(BOOL finished) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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
    // 文件都不在还转个啥
    if (![[NSFileManager defaultManager] fileExistsAtPath:inputPath]) {
        if (completion) completion(NO, nil);
        return;
    }

    // 本来就是 m4a/aac，直接 copy 完事
    NSString *ext = inputPath.pathExtension.lowercaseString;
    if ([ext isEqualToString:@"m4a"] || [ext isEqualToString:@"aac"]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
        BOOL ok = [[NSFileManager defaultManager] copyItemAtPath:inputPath toPath:outputPath error:&error];
        if (completion) completion(ok, error);
        return;
    }

    // 其他格式走 AVAssetExportSession
    NSURL *inputURL = [NSURL fileURLWithPath:inputPath];
    AVAsset *asset = [AVAsset assetWithURL:inputURL];

    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:asset
                                                                    presetName:AVAssetExportPresetAppleM4A];
    if (!session) {
        if (completion) completion(NO, nil);
        return;
    }

    // 先删旧文件，不然 export 会炸
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

#pragma mark - 时长

+ (double)audioDurationAtPath:(NSString *)path {
    if (!path || ![[NSFileManager defaultManager] fileExistsAtPath:path]) return 0;
    NSURL *url = [NSURL fileURLWithPath:path];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    return CMTimeGetSeconds(asset.duration);
}

#pragma mark - 文件名

+ (NSString *)generateFilenameForCommentID:(NSString *)commentID duration:(long long)duration {
    // 评论ID_时长_时间戳.m4a
    NSTimeInterval ts = [[NSDate date] timeIntervalSince1970];
    return [NSString stringWithFormat:@"评论_%@_%llds_%.0f.m4a",
            commentID ?: @"unknown", duration, ts];
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
    // 导航控制器就拿 top
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
        // 跳过 macOS 的 __MACOSX 垃圾
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
