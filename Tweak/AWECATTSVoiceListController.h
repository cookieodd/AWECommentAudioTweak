// 豆包 TTS 音色
// @cookieodd | github.com/cookieodd | t.me/cookieodd

#import <UIKit/UIKit.h>
#import "AWECATTSManager.h"

@interface AWECATTSVoiceListController : UITableViewController <UISearchBarDelegate>

@property (nonatomic, copy) void(^onVoiceSelected)(NSString *voiceType, NSString *voiceName);

@end
