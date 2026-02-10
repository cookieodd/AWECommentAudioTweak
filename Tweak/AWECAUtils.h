// 工具人，啥脏活都干
// @cookieodd | github.com/cookieodd | t.me/cookieodd

#import <UIKit/UIKit.h>

// bundle id
#define kAWECATweakID @"com.cookieodd.awecommentaudiotweak"

// 沙盒路径
#define kAWECAAudioDir @"AWECommentAudio"
#define kAWECAImportDir @"AWECommentAudio/Imported"
// 持久化 key
#define kAWECAReplacementEnabled @"AWECAReplacementEnabled"
#define kAWECAReplacementAudioPath @"AWECAReplacementAudioPath"

@interface AWECAUtils : NSObject

// 路径三件套
+ (NSString *)documentsPath;
+ (NSString *)audioSavePath;
+ (NSString *)importPath;
// 没目录就建，佛系操作
+ (void)ensureDirectoriesExist;

// 弹个 toast 告诉用户咋回事
+ (void)showToast:(NSString *)message;

// 转码成 m4a，格式统一才是正义
+ (void)convertAudioAtPath:(NSString *)inputPath
              toOutputPath:(NSString *)outputPath
                completion:(void(^)(BOOL success, NSError *error))completion;

// 拿音频时长
+ (double)audioDurationAtPath:(NSString *)path;

// 生成文件名
+ (NSString *)generateFilenameForCommentID:(NSString *)commentID duration:(long long)duration;

// 拿最顶层 VC，弹窗得找对人
+ (UIViewController *)topViewController;

// 解压 zip，libarchive 系统自带真香
+ (BOOL)extractZipAtPath:(NSString *)zipPath toDirectory:(NSString *)destDir error:(NSError **)error;

@end
