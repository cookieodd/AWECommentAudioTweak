// 下载管理器，CDN直链一把梭
// @cookieodd | github.com/cookieodd | t.me/cookieodd

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AWECAHeaders.h"

@interface AWECADownloadManager : NSObject

+ (instancetype)shared;

// vID → URL 缓存，播放时偷偷存起来
- (void)cacheURL:(NSString *)url forVID:(NSString *)vID;
- (NSString *)cachedURLForVID:(NSString *)vID;

// 从JSON里扒CDN链接
- (void)parseAndCacheVideoModelJSON:(NSString *)jsonStr;

// 长按触发，弹框问你存哪
- (void)showSaveDialogAndDownload:(AWECommentModel *)comment;

// 列出已下载的音频
- (NSArray<NSString *> *)downloadedAudioFiles;
- (NSArray<NSString *> *)downloadedAudioDisplayNames;

@end
