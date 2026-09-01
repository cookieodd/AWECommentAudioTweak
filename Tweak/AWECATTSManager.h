// 豆包 TTS 管理器
// @cookieodd | github.com/cookieodd | t.me/cookieodd

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#define kAWECATTSAppID        @"AWECATTSAppID"
#define kAWECATTSAccessToken  @"AWECATTSAccessToken"
#define kAWECATTSVoiceType    @"AWECATTSVoiceType"
#define kAWECATTSVoiceName    @"AWECATTSVoiceName"
#define kAWECATTSSpeedRatio   @"AWECATTSSpeedRatio"
#define kAWECATTSVolumeRatio  @"AWECATTSVolumeRatio"
#define kAWECATTSPitchRatio   @"AWECATTSPitchRatio"
#define kAWECATTSContextText  @"AWECATTSContextText"
#define kAWECATTSDialect      @"AWECATTSDialect"
#define kAWECATTSSilenceMs    @"AWECATTSSilenceMs"
#define kAWECATTSLastPath     @"AWECATTSLastPath"
#define kAWECATTSDialectSpeaker @"zh_female_vv_uranus_bigtts"
#define kAWECATTSVolcanoVoiceType @"AWECATTSVolcanoVoiceType"
#define kAWECATTSVolcanoVoiceName @"AWECATTSVolcanoVoiceName"

@interface AWECATTSManager : NSObject <AVAudioPlayerDelegate>

+ (instancetype)shared;

@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy) NSString *accessToken;

@property (nonatomic, copy) NSString *voiceType;
@property (nonatomic, copy) NSString *voiceName;

@property (nonatomic, assign) float speedRatio;
@property (nonatomic, assign) float volumeRatio;
@property (nonatomic, assign) float pitchRatio;

@property (nonatomic, copy) NSString *contextText;
@property (nonatomic, copy) NSString *explicitDialect;
@property (nonatomic, assign) NSInteger silenceDurationMs;

@property (nonatomic, copy, readonly) NSString *lastSynthesizedPath;

- (void)synthesizeText:(NSString *)text
            completion:(void(^)(BOOL success, NSString *audioPath, NSString *error))completion;

- (void)previewText:(NSString *)text
         completion:(void(^)(BOOL success, NSString *audioPath, NSString *error))completion;

- (void)synthesizeVolcanoPreviewText:(NSString *)text
                          completion:(void(^)(BOOL success, NSString *audioPath, NSString *error))completion;

- (void)applyVolcanoHTTPAuthToRequest:(NSMutableURLRequest *)request;

- (void)playAudioAtPath:(NSString *)path;
- (void)stopPlayback;
- (BOOL)isPlaying;

- (BOOL)currentVoiceSupportsDialect;
+ (NSString *)canonicalDialect:(NSString *)raw;

- (void)saveConfig;
- (void)loadConfig;

@end
