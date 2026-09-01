// 语音替换
// @cookieodd | github.com/cookieodd | t.me/cookieodd

#import <Foundation/Foundation.h>

@interface AWECAAudioReplacer : NSObject

+ (instancetype)shared;

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, copy) NSString *replacementAudioPath;
@property (nonatomic, copy) NSString *ttsAudioPath;
@property (nonatomic, readonly) BOOL isUsingTTS;

- (void)setReplacementFromPath:(NSString *)path completion:(void(^)(BOOL success))completion;

- (void)setReplacementFromTTSPath:(NSString *)path
                             text:(NSString *)text
                        voiceName:(NSString *)voiceName
                       completion:(void(^)(BOOL success))completion;

- (void)clearReplacement;
- (BOOL)replaceAudioAtPath:(NSString *)targetPath;
- (void)saveState;
- (void)loadState;

@end
