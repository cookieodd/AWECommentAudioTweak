// 工具方法
// @cookieodd | github.com/cookieodd | t.me/cookieodd

#import <UIKit/UIKit.h>

#define kAWECATweakID @"com.cookieodd.awecommentaudiotweak"

#define kAWECAAudioDir @"AWECommentAudio"
#define kAWECAImportDir @"AWECommentAudio/导入音频"
#define kAWECAReplacementEnabled @"AWECAReplacementEnabled"
#define kAWECAReplacementAudioPath @"AWECAReplacementAudioPath"

@interface AWECAUtils : NSObject

+ (NSString *)documentsPath;
+ (NSString *)audioSavePath;
+ (NSString *)importPath;
+ (NSString *)ttsPath;
+ (NSString *)ttsVolcanoPath;
+ (void)ensureDirectoriesExist;

+ (void)showToast:(NSString *)message;
+ (void)showToast:(NSString *)message duration:(NSTimeInterval)duration;

+ (void)convertAudioAtPath:(NSString *)inputPath
              toOutputPath:(NSString *)outputPath
                completion:(void(^)(BOOL success, NSError *error))completion;

+ (void)convertAudioAtPath:(NSString *)inputPath
              toWAV16kPath:(NSString *)outputPath
                completion:(void(^)(BOOL success, NSError *error))completion;

+ (double)audioDurationAtPath:(NSString *)path;
+ (NSString *)generateFilenameForCommentID:(NSString *)commentID duration:(long long)duration;
+ (NSString *)sanitizeFilename:(NSString *)name maxLength:(NSUInteger)maxLen;
+ (UIViewController *)topViewController;
+ (BOOL)extractZipAtPath:(NSString *)zipPath toDirectory:(NSString *)destDir error:(NSError **)error;

@end
