// 下载管理器impl，CDN直链下载简单粗暴
// @cookieodd | github.com/cookieodd | t.me/cookieodd

#import "AWECADownloadManager.h"
#import "AWECAUtils.h"

@interface AWECADownloadManager ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *urlCache;
@end

@implementation AWECADownloadManager

+ (instancetype)shared {
    static AWECADownloadManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AWECADownloadManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _urlCache = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - URL缓存

- (void)cacheURL:(NSString *)url forVID:(NSString *)vID {
    if (!url || !vID) return;
    self.urlCache[vID] = url;
}

- (NSString *)cachedURLForVID:(NSString *)vID {
    if (!vID) return nil;
    return self.urlCache[vID];
}

- (void)parseAndCacheVideoModelJSON:(NSString *)jsonStr {
    if (!jsonStr || jsonStr.length == 0) return;

    NSData *data = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) return;

    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (!json || error) {
        return;
    }

    NSString *vID = json[@"video_id"];
    NSArray *videoList = json[@"video_list"];
    if (!vID || !videoList || videoList.count == 0) return;

    NSString *mainURL = videoList[0][@"main_url"];
    if (mainURL && mainURL.length > 0) {
        [self cacheURL:mainURL forVID:vID];
    }
}

#pragma mark - 保存弹框

- (void)showSaveDialogAndDownload:(AWECommentModel *)comment {
    if (!comment || !comment.audioModel) {
        [AWECAUtils showToast:@"该评论没有语音"];
        return;
    }

    NSString *vID = comment.audioModel.vID;

    NSString *cdnURL = [self cachedURLForVID:vID];
    if (!cdnURL) {
        [AWECAUtils showToast:@"请先播放该语音再下载"];
        return;
    }

    [self showSaveDialogWithURL:cdnURL comment:comment];
}

- (void)showSaveDialogWithURL:(NSString *)cdnURL comment:(AWECommentModel *)comment {
    NSString *commentID = comment.commentID ?: @"unknown";
    long long durationMs = comment.audioModel.duration;
    double durationSec = durationMs / 1000.0;
    NSString *defaultName = [NSString stringWithFormat:@"评论语音_%@_%.0fs", commentID, durationSec];

    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *topVC = [AWECAUtils topViewController];
        if (!topVC) {
            return;
        }

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"保存语音"
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleAlert];

        [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
            tf.text = defaultName;
            tf.placeholder = @"文件名(不含扩展名)";
            tf.clearButtonMode = UITextFieldViewModeWhileEditing;
        }];

        [alert addAction:[UIAlertAction actionWithTitle:@"保存到默认目录" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSString *fileName = alert.textFields.firstObject.text;
            if (!fileName || fileName.length == 0) fileName = defaultName;
            NSString *savePath = [[AWECAUtils audioSavePath] stringByAppendingPathComponent:[fileName stringByAppendingPathExtension:@"m4a"]];
            [self downloadFromURL:cdnURL toPath:savePath];
        }]];

        [alert addAction:[UIAlertAction actionWithTitle:@"选择文件夹" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSString *fileName = alert.textFields.firstObject.text;
            if (!fileName || fileName.length == 0) fileName = defaultName;
            [self showFolderPicker:fileName cdnURL:cdnURL fromVC:topVC];
        }]];

        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];

        [topVC presentViewController:alert animated:YES completion:nil];
    });
}

#pragma mark - 文件夹选择

- (void)showFolderPicker:(NSString *)fileName cdnURL:(NSString *)cdnURL fromVC:(UIViewController *)vc {
    NSString *baseDir = [AWECAUtils audioSavePath];
    NSFileManager *fm = [NSFileManager defaultManager];

    NSArray *contents = [fm contentsOfDirectoryAtPath:baseDir error:nil];
    NSMutableArray *folders = [NSMutableArray array];
    for (NSString *item in contents) {
        BOOL isDir = NO;
        NSString *fullPath = [baseDir stringByAppendingPathComponent:item];
        if ([fm fileExistsAtPath:fullPath isDirectory:&isDir] && isDir) {
            [folders addObject:item];
        }
    }

    UIAlertController *picker = [UIAlertController alertControllerWithTitle:@"选择保存位置"
                                                                    message:baseDir
                                                             preferredStyle:UIAlertControllerStyleActionSheet];

    [picker addAction:[UIAlertAction actionWithTitle:@"默认目录" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *savePath = [baseDir stringByAppendingPathComponent:[fileName stringByAppendingPathExtension:@"m4a"]];
        [self downloadFromURL:cdnURL toPath:savePath];
    }]];

    for (NSString *folder in folders) {
        [picker addAction:[UIAlertAction actionWithTitle:folder style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSString *dir = [baseDir stringByAppendingPathComponent:folder];
            NSString *savePath = [dir stringByAppendingPathComponent:[fileName stringByAppendingPathExtension:@"m4a"]];
            [self downloadFromURL:cdnURL toPath:savePath];
        }]];
    }

    [picker addAction:[UIAlertAction actionWithTitle:@"新建文件夹" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self showCreateFolderDialog:fileName cdnURL:cdnURL baseDir:baseDir fromVC:vc];
    }]];

    [picker addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];

    if (picker.popoverPresentationController) {
        picker.popoverPresentationController.sourceView = vc.view;
        picker.popoverPresentationController.sourceRect = CGRectMake(vc.view.bounds.size.width / 2, vc.view.bounds.size.height, 0, 0);
    }

    [vc presentViewController:picker animated:YES completion:nil];
}

- (void)showCreateFolderDialog:(NSString *)fileName cdnURL:(NSString *)cdnURL baseDir:(NSString *)baseDir fromVC:(UIViewController *)vc {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"新建文件夹"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.placeholder = @"文件夹名称";
    }];

    [alert addAction:[UIAlertAction actionWithTitle:@"创建并保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *folderName = alert.textFields.firstObject.text;
        if (!folderName || folderName.length == 0) {
            [AWECAUtils showToast:@"文件夹名不能为空"];
            return;
        }
        NSString *newDir = [baseDir stringByAppendingPathComponent:folderName];
        [[NSFileManager defaultManager] createDirectoryAtPath:newDir withIntermediateDirectories:YES attributes:nil error:nil];
        NSString *savePath = [newDir stringByAppendingPathComponent:[fileName stringByAppendingPathExtension:@"m4a"]];
        [self downloadFromURL:cdnURL toPath:savePath];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];

    [vc presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 下载核心

- (void)downloadFromURL:(NSString *)urlStr toPath:(NSString *)savePath {
    [AWECAUtils showToast:@"正在下载..."];

    NSURL *url = [NSURL URLWithString:urlStr];
    if (!url) {
        [AWECAUtils showToast:@"下载失败: URL 无效"];
        return;
    }

    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.timeoutIntervalForRequest = 30;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];

    [[session downloadTaskWithURL:url completionHandler:^(NSURL *tmpFile, NSURLResponse *response, NSError *error) {
        if (error || !tmpFile) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [AWECAUtils showToast:@"下载失败"];
            });
            return;
        }

        NSFileManager *fm = [NSFileManager defaultManager];
        NSString *dir = [savePath stringByDeletingLastPathComponent];
        [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
        [fm removeItemAtPath:savePath error:nil];

        NSError *moveError = nil;
        BOOL ok = [fm moveItemAtURL:tmpFile toURL:[NSURL fileURLWithPath:savePath] error:&moveError];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (ok) {
                [AWECAUtils showToast:[NSString stringWithFormat:@"已保存 %@", savePath.lastPathComponent]];
            } else {
                [AWECAUtils showToast:@"保存失败"];
            }
        });
    }] resume];
}

#pragma mark - 文件列表

- (NSArray<NSString *> *)downloadedAudioFiles {
    [AWECAUtils ensureDirectoriesExist];
    NSString *dir = [AWECAUtils audioSavePath];
    NSFileManager *fm = [NSFileManager defaultManager];

    NSMutableArray *result = [NSMutableArray array];
    NSDirectoryEnumerator *enumerator = [fm enumeratorAtPath:dir];
    NSString *file;
    while ((file = [enumerator nextObject])) {
        NSString *ext = file.pathExtension.lowercaseString;
        if ([ext isEqualToString:@"m4a"] || [ext isEqualToString:@"aac"] ||
            [ext isEqualToString:@"mp3"] || [ext isEqualToString:@"wav"] ||
            [ext isEqualToString:@"mp4"]) {
            [result addObject:[dir stringByAppendingPathComponent:file]];
        }
    }

    [result sortUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
        NSDictionary *attrA = [fm attributesOfItemAtPath:a error:nil];
        NSDictionary *attrB = [fm attributesOfItemAtPath:b error:nil];
        return [attrB[NSFileModificationDate] compare:attrA[NSFileModificationDate]];
    }];

    return result;
}

- (NSArray<NSString *> *)downloadedAudioDisplayNames {
    NSArray *files = [self downloadedAudioFiles];
    NSMutableArray *names = [NSMutableArray array];
    for (NSString *path in files) {
        NSString *filename = path.lastPathComponent;
        double dur = [AWECAUtils audioDurationAtPath:path];
        [names addObject:[NSString stringWithFormat:@"%@ (%.0f秒)", filename, dur]];
    }
    return names;
}

@end
