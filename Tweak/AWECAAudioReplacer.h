// 音频替换器，偷天换日用你的音频顶包
// @cookieodd | github.com/cookieodd | t.me/cookieodd

#import <Foundation/Foundation.h>

@interface AWECAAudioReplacer : NSObject

+ (instancetype)shared;

// 开关，开了就偷梁换柱
@property (nonatomic, assign) BOOL enabled;

// 替换音频路径，转好的m4a
@property (nonatomic, copy) NSString *replacementAudioPath;

// 设置替换音频，不是m4a自动转
- (void)setReplacementFromPath:(NSString *)path completion:(void(^)(BOOL success))completion;

// 清除替换，恢复原装录音
- (void)clearReplacement;

// 执行替换，把音频copy到录音路径
- (BOOL)replaceAudioAtPath:(NSString *)targetPath;

// 状态持久化，重启不丢
- (void)saveState;
- (void)loadState;

@end
