// 豆包 TTS 音色
// @cookieodd | github.com/cookieodd | t.me/cookieodd

#import "AWECATTSVoiceListController.h"
#import "AWECATTSManager.h"
#import "AWECAUtils.h"
#import <objc/runtime.h>

#define kAWECARecommendedVoices @"AWECARecommendedVoices"

typedef NS_ENUM(NSInteger, AWECAVoiceSection) {
    AWECAVoiceSectionRecommended = 0,
    AWECAVoiceSectionAll,
    AWECAVoiceSectionCount
};

#define kCellFont [UIFont systemFontOfSize:15]

@interface AWECATTSVoiceListController ()
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *recommendedVoices;
@property (nonatomic, strong) NSArray<NSDictionary *> *allVoices;
@property (nonatomic, strong) NSArray<NSDictionary *> *filteredRecommended;
@property (nonatomic, strong) NSArray<NSDictionary *> *filteredAll;
@property (nonatomic, copy) NSString *searchText;
@end

@implementation AWECATTSVoiceListController

- (instancetype)init {
    self = [super initWithStyle:UITableViewStylePlain];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self buildVoiceData];
    [self loadRecommended];

    self.title = @"音色";
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"vc"];

    UISearchBar *sb = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    sb.placeholder = @"搜索音色...";
    sb.delegate = self;
    self.tableView.tableHeaderView = sb;
    self.searchBar = sb;

    self.filteredRecommended = [self.recommendedVoices mutableCopy];
    self.filteredAll = self.allVoices;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

#pragma mark - 推荐音色持久化

- (NSArray<NSDictionary *> *)defaultRecommended {
    return @[
        @{@"name": @"知性灿灿 2.0", @"voiceType": @"zh_female_cancan_uranus_bigtts"},
        @{@"name": @"Vivi 2.0", @"voiceType": @"zh_female_vv_uranus_bigtts"},
        @{@"name": @"小何 2.0", @"voiceType": @"zh_female_xiaohe_uranus_bigtts"},
        @{@"name": @"云舟 2.0", @"voiceType": @"zh_male_m191_uranus_bigtts"},
        @{@"name": @"小天 2.0", @"voiceType": @"zh_male_taocheng_uranus_bigtts"},
    ];
}

- (NSString *)recommendedKey {
    return kAWECARecommendedVoices;
}

- (void)loadRecommended {
    NSArray *saved = [[NSUserDefaults standardUserDefaults] arrayForKey:[self recommendedKey]];
    if (saved != nil) {
        self.recommendedVoices = [saved mutableCopy];
    } else {
        self.recommendedVoices = [[self defaultRecommended] mutableCopy];
        [self saveRecommended];
    }
}

- (void)saveRecommended {
    [[NSUserDefaults standardUserDefaults] setObject:[self.recommendedVoices copy] forKey:[self recommendedKey]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - 搜索

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.searchText = searchText;
    [self filterVoices];
    [self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)filterVoices {
    if (!self.searchText || self.searchText.length == 0) {
        self.filteredRecommended = [self.recommendedVoices mutableCopy];
        self.filteredAll = self.allVoices;
        return;
    }
    NSString *q = self.searchText.lowercaseString;
    NSPredicate *pred = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *v, NSDictionary *bindings) {
        return [[v[@"name"] lowercaseString] containsString:q] ||
               [[v[@"voiceType"] lowercaseString] containsString:q];
    }];
    self.filteredRecommended = [[self.recommendedVoices filteredArrayUsingPredicate:pred] mutableCopy];
    self.filteredAll = [self.allVoices filteredArrayUsingPredicate:pred];
}

#pragma mark - 数据源

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return AWECAVoiceSectionCount; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case AWECAVoiceSectionRecommended: return self.filteredRecommended.count;
        case AWECAVoiceSectionAll: return self.filteredAll.count;
        default: return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case AWECAVoiceSectionRecommended: return @"推荐音色";
        case AWECAVoiceSectionAll: return [NSString stringWithFormat:@"全部音色 (%lu)", (unsigned long)self.filteredAll.count];
        default: return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"vc" forIndexPath:indexPath];
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;

    NSArray *list = (indexPath.section == AWECAVoiceSectionRecommended) ? self.filteredRecommended : self.filteredAll;
    NSDictionary *voice = list[indexPath.row];
    NSString *name = voice[@"name"];
    NSString *type = voice[@"voiceType"];

    cell.textLabel.text = [NSString stringWithFormat:@"%@  %@", name, type];
    cell.textLabel.font = [UIFont systemFontOfSize:14];

    AWECATTSManager *mgr = [AWECATTSManager shared];
    NSString *cur = mgr.voiceType.length > 0 ? mgr.voiceType : @"zh_female_cancan_uranus_bigtts";
    if ([type isEqualToString:cur]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }

    UIButton *playBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightRegular];
    [playBtn setImage:[UIImage systemImageNamed:@"play.circle" withConfiguration:cfg] forState:UIControlStateNormal];
    playBtn.frame = CGRectMake(0, 0, 36, 36);
    objc_setAssociatedObject(playBtn, "voiceType", type, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [playBtn addTarget:self action:@selector(previewVoice:) forControlEvents:UIControlEventTouchUpInside];

    if (![type isEqualToString:cur]) {
        cell.accessoryView = playBtn;
    }

    return cell;
}

#pragma mark - 列表代理

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSArray *list = (indexPath.section == AWECAVoiceSectionRecommended) ? self.filteredRecommended : self.filteredAll;
    NSDictionary *voice = list[indexPath.row];

    AWECATTSManager *mgr = [AWECATTSManager shared];
    mgr.voiceType = voice[@"voiceType"];
    mgr.voiceName = voice[@"name"];
    [mgr saveConfig];

    if (self.onVoiceSelected) {
        self.onVoiceSelected(voice[@"voiceType"], voice[@"name"]);
    }
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - 推荐编辑

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.searchText.length > 0) return NO;
    return YES;
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.searchText.length > 0) return nil;

    if (indexPath.section == AWECAVoiceSectionRecommended) {
        UIContextualAction *removeAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
            title:@"移除" handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
            [self.recommendedVoices removeObjectAtIndex:indexPath.row];
            [self saveRecommended];
            self.filteredRecommended = [self.recommendedVoices mutableCopy];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            completionHandler(YES);
        }];
        return [UISwipeActionsConfiguration configurationWithActions:@[removeAction]];

    } else if (indexPath.section == AWECAVoiceSectionAll) {
        NSDictionary *voice = self.filteredAll[indexPath.row];
        NSString *vt = voice[@"voiceType"];
        for (NSDictionary *r in self.recommendedVoices) {
            if ([r[@"voiceType"] isEqualToString:vt]) return nil;
        }

        UIContextualAction *addAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
            title:@"加入推荐" handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
            [self.recommendedVoices addObject:voice];
            [self saveRecommended];
            self.filteredRecommended = [self.recommendedVoices mutableCopy];
            NSIndexPath *newIP = [NSIndexPath indexPathForRow:self.recommendedVoices.count - 1 inSection:AWECAVoiceSectionRecommended];
            [tableView insertRowsAtIndexPaths:@[newIP] withRowAnimation:UITableViewRowAnimationAutomatic];
            [AWECAUtils showToast:[NSString stringWithFormat:@"已加入推荐: %@", voice[@"name"]]];
            completionHandler(YES);
        }];
        addAction.backgroundColor = [UIColor systemBlueColor];
        return [UISwipeActionsConfiguration configurationWithActions:@[addAction]];
    }
    return nil;
}

#pragma mark - 试听

- (void)previewVoice:(UIButton *)btn {
    NSString *type = objc_getAssociatedObject(btn, "voiceType");
    if (!type) return;

    AWECATTSManager *mgr = [AWECATTSManager shared];

    if ([mgr isPlaying]) {
        [mgr stopPlayback];
        return;
    }

    NSString *origType = mgr.voiceType;
    NSString *origName = mgr.voiceName;

    mgr.voiceType = type;

    [AWECAUtils showToast:@"正在试听..."];
    [mgr previewText:@"你好，这是语音试听" completion:^(BOOL success, NSString *audioPath, NSString *error) {
        mgr.voiceType = origType;
        mgr.voiceName = origName;

        if (success && audioPath) {
            [mgr playAudioAtPath:audioPath];
        } else {
            [AWECAUtils showToast:error ?: @"试听失败"];
        }
    }];
}

#pragma mark - 音色数据

- (void)buildVoiceData {
    self.allVoices = @[
        @{@"name": @"Vivi 2.0", @"voiceType": @"zh_female_vv_uranus_bigtts"},
        @{@"name": @"小何 2.0", @"voiceType": @"zh_female_xiaohe_uranus_bigtts"},
        @{@"name": @"云舟 2.0", @"voiceType": @"zh_male_m191_uranus_bigtts"},
        @{@"name": @"小天 2.0", @"voiceType": @"zh_male_taocheng_uranus_bigtts"},
        @{@"name": @"刘飞 2.0", @"voiceType": @"zh_male_liufei_uranus_bigtts"},
        @{@"name": @"魅力苏菲 2.0", @"voiceType": @"zh_female_sophie_uranus_bigtts"},
        @{@"name": @"清新女声 2.0", @"voiceType": @"zh_female_qingxinnvsheng_uranus_bigtts"},
        @{@"name": @"知性灿灿 2.0", @"voiceType": @"zh_female_cancan_uranus_bigtts"},
        @{@"name": @"撒娇学妹 2.0", @"voiceType": @"zh_female_sajiaoxuemei_uranus_bigtts"},
        @{@"name": @"甜美小源 2.0", @"voiceType": @"zh_female_tianmeixiaoyuan_uranus_bigtts"},
        @{@"name": @"甜美桃子 2.0", @"voiceType": @"zh_female_tianmeitaozi_uranus_bigtts"},
        @{@"name": @"爽快思思 2.0", @"voiceType": @"zh_female_shuangkuaisisi_uranus_bigtts"},
        @{@"name": @"佩奇猪 2.0", @"voiceType": @"zh_female_peiqi_uranus_bigtts"},
        @{@"name": @"邻家女孩 2.0", @"voiceType": @"zh_female_linjianvhai_uranus_bigtts"},
        @{@"name": @"少年梓辛 2.0", @"voiceType": @"zh_male_shaonianzixin_uranus_bigtts"},
        @{@"name": @"猴哥 2.0", @"voiceType": @"zh_male_sunwukong_uranus_bigtts"},
        @{@"name": @"Tina老师 2.0", @"voiceType": @"zh_female_yingyujiaoxue_uranus_bigtts"},
        @{@"name": @"暖阳女声 2.0", @"voiceType": @"zh_female_kefunvsheng_uranus_bigtts"},
        @{@"name": @"儿童绘本 2.0", @"voiceType": @"zh_female_xiaoxue_uranus_bigtts"},
        @{@"name": @"大壹 2.0", @"voiceType": @"zh_male_dayi_uranus_bigtts"},
        @{@"name": @"黑猫侦探社咪仔 2.0", @"voiceType": @"zh_female_mizai_uranus_bigtts"},
        @{@"name": @"鸡汤女 2.0", @"voiceType": @"zh_female_jitangnv_uranus_bigtts"},
        @{@"name": @"魅力女友 2.0", @"voiceType": @"zh_female_meilinvyou_uranus_bigtts"},
        @{@"name": @"流畅女声 2.0", @"voiceType": @"zh_female_liuchangnv_uranus_bigtts"},
        @{@"name": @"儒雅逸辰 2.0", @"voiceType": @"zh_male_ruyayichen_uranus_bigtts"},
        @{@"name": @"Tim", @"voiceType": @"en_male_tim_uranus_bigtts"},
        @{@"name": @"Dacey", @"voiceType": @"en_female_dacey_uranus_bigtts"},
        @{@"name": @"Stokie", @"voiceType": @"en_female_stokie_uranus_bigtts"},
        @{@"name": @"温柔妈妈 2.0", @"voiceType": @"zh_female_wenroumama_uranus_bigtts"},
        @{@"name": @"解说小明 2.0", @"voiceType": @"zh_male_jieshuoxiaoming_uranus_bigtts"},
        @{@"name": @"TVB女声 2.0", @"voiceType": @"zh_female_tvbnv_uranus_bigtts"},
        @{@"name": @"译制片男 2.0", @"voiceType": @"zh_male_yizhipiannan_uranus_bigtts"},
        @{@"name": @"俏皮女声 2.0", @"voiceType": @"zh_female_qiaopinv_uranus_bigtts"},
        @{@"name": @"直率英子 2.0", @"voiceType": @"zh_female_zhishuaiyingzi_uranus_bigtts"},
        @{@"name": @"邻家男孩 2.0", @"voiceType": @"zh_male_linjiananhai_uranus_bigtts"},
        @{@"name": @"四郎 2.0", @"voiceType": @"zh_male_silang_uranus_bigtts"},
        @{@"name": @"儒雅青年 2.0", @"voiceType": @"zh_male_ruyaqingnian_uranus_bigtts"},
        @{@"name": @"擎苍 2.0", @"voiceType": @"zh_male_qingcang_uranus_bigtts"},
        @{@"name": @"熊二 2.0", @"voiceType": @"zh_male_xionger_uranus_bigtts"},
        @{@"name": @"樱桃丸子 2.0", @"voiceType": @"zh_female_yingtaowanzi_uranus_bigtts"},
        @{@"name": @"温暖阿虎 2.0", @"voiceType": @"zh_male_wennuanahu_uranus_bigtts"},
        @{@"name": @"奶气萌娃 2.0", @"voiceType": @"zh_male_naiqimengwa_uranus_bigtts"},
        @{@"name": @"婆婆 2.0", @"voiceType": @"zh_female_popo_uranus_bigtts"},
        @{@"name": @"高冷御姐 2.0", @"voiceType": @"zh_female_gaolengyujie_uranus_bigtts"},
        @{@"name": @"傲娇霸总 2.0", @"voiceType": @"zh_male_aojiaobazong_uranus_bigtts"},
        @{@"name": @"懒音绵宝 2.0", @"voiceType": @"zh_male_lanyinmianbao_uranus_bigtts"},
        @{@"name": @"反卷青年 2.0", @"voiceType": @"zh_male_fanjuanqingnian_uranus_bigtts"},
        @{@"name": @"温柔淑女 2.0", @"voiceType": @"zh_female_wenroushunv_uranus_bigtts"},
        @{@"name": @"古风少御 2.0", @"voiceType": @"zh_female_gufengshaoyu_uranus_bigtts"},
        @{@"name": @"活力小哥 2.0", @"voiceType": @"zh_male_huolixiaoge_uranus_bigtts"},
        @{@"name": @"霸气青叔 2.0", @"voiceType": @"zh_male_baqiqingshu_uranus_bigtts"},
        @{@"name": @"悬疑解说 2.0", @"voiceType": @"zh_male_xuanyijieshuo_uranus_bigtts"},
        @{@"name": @"萌丫头 2.0", @"voiceType": @"zh_female_mengyatou_uranus_bigtts"},
        @{@"name": @"贴心女声 2.0", @"voiceType": @"zh_female_tiexinnvsheng_uranus_bigtts"},
        @{@"name": @"鸡汤妹妹 2.0", @"voiceType": @"zh_female_jitangmei_uranus_bigtts"},
        @{@"name": @"磁性解说男声 2.0", @"voiceType": @"zh_male_cixingjieshuonan_uranus_bigtts"},
        @{@"name": @"亮嗓萌仔 2.0", @"voiceType": @"zh_male_liangsangmengzai_uranus_bigtts"},
        @{@"name": @"开朗姐姐 2.0", @"voiceType": @"zh_female_kailangjiejie_uranus_bigtts"},
        @{@"name": @"高冷沉稳 2.0", @"voiceType": @"zh_male_gaolengchenwen_uranus_bigtts"},
        @{@"name": @"深夜播客 2.0", @"voiceType": @"zh_male_shenyeboke_uranus_bigtts"},
        @{@"name": @"鲁班七号 2.0", @"voiceType": @"zh_male_lubanqihao_uranus_bigtts"},
        @{@"name": @"娇喘女声 2.0", @"voiceType": @"zh_female_jiaochuannv_uranus_bigtts"},
        @{@"name": @"林潇 2.0", @"voiceType": @"zh_female_linxiao_uranus_bigtts"},
        @{@"name": @"玲玲姐姐 2.0", @"voiceType": @"zh_female_lingling_uranus_bigtts"},
        @{@"name": @"春日部姐姐 2.0", @"voiceType": @"zh_female_chunribu_uranus_bigtts"},
        @{@"name": @"唐僧 2.0", @"voiceType": @"zh_male_tangseng_uranus_bigtts"},
        @{@"name": @"庄周 2.0", @"voiceType": @"zh_male_zhuangzhou_uranus_bigtts"},
        @{@"name": @"开朗弟弟 2.0", @"voiceType": @"zh_male_kailangdidi_uranus_bigtts"},
        @{@"name": @"猪八戒 2.0", @"voiceType": @"zh_male_zhubajie_uranus_bigtts"},
        @{@"name": @"感冒电音姐姐 2.0", @"voiceType": @"zh_female_ganmaodianyin_uranus_bigtts"},
        @{@"name": @"谄媚女声 2.0", @"voiceType": @"zh_female_chanmeinv_uranus_bigtts"},
        @{@"name": @"女雷神 2.0", @"voiceType": @"zh_female_nvleishen_uranus_bigtts"},
        @{@"name": @"亲切女声 2.0", @"voiceType": @"zh_female_qinqienv_uranus_bigtts"},
        @{@"name": @"快乐小东 2.0", @"voiceType": @"zh_male_kuailexiaodong_uranus_bigtts"},
        @{@"name": @"开朗学长 2.0", @"voiceType": @"zh_male_kailangxuezhang_uranus_bigtts"},
        @{@"name": @"悠悠君子 2.0", @"voiceType": @"zh_male_youyoujunzi_uranus_bigtts"},
        @{@"name": @"文静毛毛 2.0", @"voiceType": @"zh_female_wenjingmaomao_uranus_bigtts"},
        @{@"name": @"知性女声 2.0", @"voiceType": @"zh_female_zhixingnv_uranus_bigtts"},
        @{@"name": @"清爽男大 2.0", @"voiceType": @"zh_male_qingshuangnanda_uranus_bigtts"},
        @{@"name": @"渊博小叔 2.0", @"voiceType": @"zh_male_yuanboxiaoshu_uranus_bigtts"},
        @{@"name": @"阳光青年 2.0", @"voiceType": @"zh_male_yangguangqingnian_uranus_bigtts"},
        @{@"name": @"清澈梓梓 2.0", @"voiceType": @"zh_female_qingchezizi_uranus_bigtts"},
        @{@"name": @"甜美悦悦 2.0", @"voiceType": @"zh_female_tianmeiyueyue_uranus_bigtts"},
        @{@"name": @"心灵鸡汤 2.0", @"voiceType": @"zh_female_xinlingjitang_uranus_bigtts"},
        @{@"name": @"温柔小哥 2.0", @"voiceType": @"zh_male_wenrouxiaoge_uranus_bigtts"},
        @{@"name": @"柔美女友 2.0", @"voiceType": @"zh_female_roumeinvyou_uranus_bigtts"},
        @{@"name": @"东方浩然 2.0", @"voiceType": @"zh_male_dongfanghaoran_uranus_bigtts"},
        @{@"name": @"温柔小雅 2.0", @"voiceType": @"zh_female_wenrouxiaoya_uranus_bigtts"},
        @{@"name": @"天才童声 2.0", @"voiceType": @"zh_male_tiancaitongsheng_uranus_bigtts"},
        @{@"name": @"武则天 2.0", @"voiceType": @"zh_female_wuzetian_uranus_bigtts"},
        @{@"name": @"顾姐 2.0", @"voiceType": @"zh_female_gujie_uranus_bigtts"},
        @{@"name": @"广告解说 2.0", @"voiceType": @"zh_male_guanggaojieshuo_uranus_bigtts"},
        @{@"name": @"少儿故事 2.0", @"voiceType": @"zh_female_shaoergushi_uranus_bigtts"},
        @{@"name": @"Charlie 2.0", @"voiceType": @"ICL_uranus_en_female_charlie_tob"},
        @{@"name": @"Ethan 2.0", @"voiceType": @"ICL_uranus_en_male_ethan_tob"},
        @{@"name": @"Alastor 2.0", @"voiceType": @"ICL_uranus_en_male_alastor_tob"},
        @{@"name": @"Chucky 2.0", @"voiceType": @"ICL_uranus_en_male_chucky_tob"},
        @{@"name": @"Noah 2.0", @"voiceType": @"ICL_uranus_en_male_noah_tob"},
        @{@"name": @"Jigsaw 2.0", @"voiceType": @"ICL_uranus_en_male_jigsaw_tob"},
        @{@"name": @"Clown Man 2.0", @"voiceType": @"ICL_uranus_en_male_clown_man_tob"},
        @{@"name": @"Cartoon Chef 2.0", @"voiceType": @"ICL_uranus_en_male_cartoon_chef_tob"},
        @{@"name": @"Frosty Man 2.0", @"voiceType": @"ICL_uranus_en_male_frosty_man_tob"},
        @{@"name": @"The Grinch 2.0", @"voiceType": @"ICL_uranus_en_male_the_grinch_tob"},
        @{@"name": @"Kevin McCallister 2.0", @"voiceType": @"ICL_uranus_en_male_kevin_mccallister_tob"},
        @{@"name": @"Michael 2.0", @"voiceType": @"ICL_uranus_en_male_michael_tob"},
        @{@"name": @"Big Boogie 2.0", @"voiceType": @"ICL_uranus_en_male_big_boogie_tob"},
        @{@"name": @"Xavier 2.0", @"voiceType": @"ICL_uranus_en_male_xavier_tob"},
        @{@"name": @"Zayne 2.0", @"voiceType": @"ICL_uranus_en_male_zayne_tob"},
        @{@"name": @"客服婉君 2.0", @"voiceType": @"ICL_uranus_zh_female_kefuwanjun_tob"},
        @{@"name": @"营销小楠 2.0", @"voiceType": @"ICL_uranus_zh_female_yingxiaokefu_v2_tob"},
        @{@"name": @"傲娇女友 2.0", @"voiceType": @"ICL_uranus_zh_female_aojiaonvyou_tob"},
        @{@"name": @"傲慢娇声 2.0", @"voiceType": @"ICL_uranus_zh_female_aomanjiaosheng_tob"},
        @{@"name": @"邪魅女王 2.0", @"voiceType": @"ICL_uranus_zh_female_xiemeinvwang_tob"},
        @{@"name": @"病娇姐姐 2.0", @"voiceType": @"ICL_uranus_zh_female_bingjiaojiejie_tob"},
        @{@"name": @"病娇萌妹 2.0", @"voiceType": @"ICL_uranus_zh_female_bingjiaomengmei_tob"},
        @{@"name": @"病弱少女 2.0", @"voiceType": @"ICL_uranus_zh_female_bingruoshaonv_tob"},
        @{@"name": @"成熟温柔 2.0", @"voiceType": @"ICL_uranus_zh_female_chengshuwenrou_tob"},
        @{@"name": @"成熟姐姐 2.0", @"voiceType": @"ICL_uranus_zh_female_chengshujiejie_tob"},
        @{@"name": @"纯真少女 2.0", @"voiceType": @"ICL_uranus_zh_female_chunzhenshaonv_tob"},
        @{@"name": @"纯澈女生 2.0", @"voiceType": @"ICL_uranus_zh_female_chunchenvsheng_tob"},
        @{@"name": @"妩媚可人 2.0", @"voiceType": @"ICL_uranus_zh_female_wumeikeren_tob"},
        @{@"name": @"乖巧可儿 2.0", @"voiceType": @"ICL_uranus_zh_female_guaiqiaokeer_tob"},
        @{@"name": @"和蔼奶奶 2.0", @"voiceType": @"ICL_uranus_zh_female_heainainai_tob"},
        @{@"name": @"活泼刁蛮 2.0", @"voiceType": @"ICL_uranus_zh_female_huopodiaoman_tob"},
        @{@"name": @"活泼女孩 2.0", @"voiceType": @"ICL_uranus_zh_female_huoponvhai_tob"},
        @{@"name": @"娇憨女王 2.0", @"voiceType": @"ICL_uranus_zh_female_jiaohannvwang_tob"},
        @{@"name": @"娇弱萝莉 2.0", @"voiceType": @"ICL_uranus_zh_female_jiaoruoluoli_tob"},
        @{@"name": @"假小子 2.0", @"voiceType": @"ICL_uranus_zh_female_jiaxiaozi_tob"},
        @{@"name": @"精灵向导 2.0", @"voiceType": @"ICL_uranus_zh_female_jinglingxiangdao_tob"},
        @{@"name": @"开朗婷婷 2.0", @"voiceType": @"ICL_uranus_zh_female_kailangtingting_tob"},
        @{@"name": @"开心小鸿 2.0", @"voiceType": @"ICL_uranus_zh_female_kaixinxiaohong_tob"},
        @{@"name": @"可爱女生 2.0", @"voiceType": @"ICL_uranus_zh_female_keainvsheng_tob"},
        @{@"name": @"灵动欣欣 2.0", @"voiceType": @"ICL_uranus_zh_female_lingdongxinxin_tob"},
        @{@"name": @"邻居阿姨 2.0", @"voiceType": @"ICL_uranus_zh_female_linjuayi_tob"},
        @{@"name": @"甜美娇俏 2.0", @"voiceType": @"ICL_uranus_zh_female_tianmeijiaoqiao_tob"},
        @{@"name": @"清冷高雅 2.0", @"voiceType": @"ICL_uranus_zh_female_qinglenggaoya_tob"},
        @{@"name": @"理性圆子 2.0", @"voiceType": @"ICL_uranus_zh_female_lixingyuanzi_tob"},
        @{@"name": @"性感魅惑 2.0", @"voiceType": @"ICL_uranus_zh_female_xingganmeihuo_tob"},
        @{@"name": @"暖心茜茜 2.0", @"voiceType": @"ICL_uranus_zh_female_nuanxinqianqian_tob"},
        @{@"name": @"暖心学姐 2.0", @"voiceType": @"ICL_uranus_zh_female_nuanxinxuejie_tob"},
        @{@"name": @"清甜莓莓 2.0", @"voiceType": @"ICL_uranus_zh_female_qingtianmeimei_tob"},
        @{@"name": @"清甜桃桃 2.0", @"voiceType": @"ICL_uranus_zh_female_qingtiantaotao_tob"},
        @{@"name": @"清晰小雪 2.0", @"voiceType": @"ICL_uranus_zh_female_qingxixiaoxue_tob"},
        @{@"name": @"倾心少女 2.0", @"voiceType": @"ICL_uranus_zh_female_qingxinshaonv_tob"},
        @{@"name": @"柔骨魂师 2.0", @"voiceType": @"ICL_uranus_zh_female_rouguhunshi_tob"},
        @{@"name": @"软萌糖糖 2.0", @"voiceType": @"ICL_uranus_zh_female_ruanmengtangtang_tob"},
        @{@"name": @"软萌团子 2.0", @"voiceType": @"ICL_uranus_zh_female_ruanmengtuanzi_tob"},
        @{@"name": @"甜美活泼 2.0", @"voiceType": @"ICL_uranus_zh_female_tianmeihuopo_tob"},
        @{@"name": @"甜美小橘 2.0", @"voiceType": @"ICL_uranus_zh_female_tianmeixiaoju_tob"},
        @{@"name": @"甜美小雨 2.0", @"voiceType": @"ICL_uranus_zh_female_tianmeixiaoyu_tob"},
        @{@"name": @"调皮公主 2.0", @"voiceType": @"ICL_uranus_zh_female_tiaopigongzhu_tob"},
        @{@"name": @"贴心女友 2.0", @"voiceType": @"ICL_uranus_zh_female_tiexinnvyou_tob"},
        @{@"name": @"温柔女神 2.0", @"voiceType": @"ICL_uranus_zh_female_wenrounvshen_tob"},
        @{@"name": @"温柔文雅 2.0", @"voiceType": @"ICL_uranus_zh_female_wenrouwenya_tob"},
        @{@"name": @"知心姐姐 2.0", @"voiceType": @"ICL_uranus_zh_female_zhixinjiejie_tob"},
        @{@"name": @"妩媚御姐 2.0", @"voiceType": @"ICL_uranus_zh_female_wumeiyujie_tob"},
        @{@"name": @"元气甜妹 2.0", @"voiceType": @"ICL_uranus_zh_female_yuanqitianmei_tob"},
        @{@"name": @"邪魅御姐 2.0", @"voiceType": @"ICL_uranus_zh_female_xiemeiyujie_tob"},
        @{@"name": @"性感御姐 2.0", @"voiceType": @"ICL_uranus_zh_female_xingganyujie_tob"},
        @{@"name": @"秀丽倩倩 2.0", @"voiceType": @"ICL_uranus_zh_female_xiuliqianqian_tob"},
        @{@"name": @"贴心闺蜜 2.0", @"voiceType": @"ICL_uranus_zh_female_tiexinguimi_tob"},
        @{@"name": @"贴心妹妹 2.0", @"voiceType": @"ICL_uranus_zh_female_tiexinmeimei_tob"},
        @{@"name": @"温柔白月光 2.0", @"voiceType": @"ICL_uranus_zh_female_wenroubaiyueguang_tob"},
        @{@"name": @"初恋女友 2.0", @"voiceType": @"ICL_uranus_zh_female_chuliannvyou_tob"},
        @{@"name": @"知性温婉 2.0", @"voiceType": @"ICL_uranus_zh_female_zhixingwenwan_tob"},
        @{@"name": @"傲气凌人 2.0", @"voiceType": @"ICL_uranus_zh_male_aoqilingren_tob"},
        @{@"name": @"黯刃秦主 2.0", @"voiceType": @"ICL_uranus_zh_male_anrenqinzhu_tob"},
        @{@"name": @"傲娇公子 2.0", @"voiceType": @"ICL_uranus_zh_male_aojiaogongzi_tob"},
        @{@"name": @"傲娇精英 2.0", @"voiceType": @"ICL_uranus_zh_male_aojiaojingying_tob"},
        @{@"name": @"傲慢青年 2.0", @"voiceType": @"ICL_uranus_zh_male_aomanqingnian_tob"},
        @{@"name": @"傲慢少爷 2.0", @"voiceType": @"ICL_uranus_zh_male_aomanshaoye_tob"},
        @{@"name": @"枕边低语 2.0", @"voiceType": @"ICL_uranus_zh_male_zhenbiandiyu_tob"},
        @{@"name": @"霸道少爷 2.0", @"voiceType": @"ICL_uranus_zh_male_badaoshaoye_tob"},
        @{@"name": @"霸道总裁 2.0", @"voiceType": @"ICL_uranus_zh_male_badaozongcai_tob"},
        @{@"name": @"病娇白莲 2.0", @"voiceType": @"ICL_uranus_zh_male_bingjiaobailian_tob"},
        @{@"name": @"病娇弟弟 2.0", @"voiceType": @"ICL_uranus_zh_male_bingjiaodidi_tob"},
        @{@"name": @"病娇哥哥 2.0", @"voiceType": @"ICL_uranus_zh_male_bingjiaogege_tob"},
        @{@"name": @"病娇男友 2.0", @"voiceType": @"ICL_uranus_zh_male_bingjiaonanyou_tob"},
        @{@"name": @"病娇少年 2.0", @"voiceType": @"ICL_uranus_zh_male_bingjiaoshaonian_tob"},
        @{@"name": @"病弱公子 2.0", @"voiceType": @"ICL_uranus_zh_male_bingruogongzi_tob"},
        @{@"name": @"病弱少年 2.0", @"voiceType": @"ICL_uranus_zh_male_bingruoshaonian_tob"},
        @{@"name": @"不羁青年 2.0", @"voiceType": @"ICL_uranus_zh_male_bujiqingnian_tob"},
        @{@"name": @"醇厚低音 2.0", @"voiceType": @"ICL_uranus_zh_male_chunhoudiyin_tob"},
        @{@"name": @"咆哮小哥 2.0", @"voiceType": @"ICL_uranus_zh_male_paoxiaoxiaoge_tob"},
        @{@"name": @"炀炀 2.0", @"voiceType": @"ICL_uranus_zh_male_yangyang_tob"},
        @{@"name": @"孱弱少爷 2.0", @"voiceType": @"ICL_uranus_zh_male_chanruoshaoye_tob"},
        @{@"name": @"成熟总裁 2.0", @"voiceType": @"ICL_uranus_zh_male_chengshuzongcai_tob"},
        @{@"name": @"沉稳明仔 2.0", @"voiceType": @"ICL_uranus_zh_male_chenwenmingzai_tob"},
        @{@"name": @"清逸苏感 2.0", @"voiceType": @"ICL_uranus_zh_male_qingyisugan_tob"},
        @{@"name": @"纯真学弟 2.0", @"voiceType": @"ICL_uranus_zh_male_chunzhenxuedi_tob"},
        @{@"name": @"磁性男嗓 2.0", @"voiceType": @"ICL_uranus_zh_male_cixingnansang_tob"},
        @{@"name": @"醋精男生 2.0", @"voiceType": @"ICL_uranus_zh_male_cujingnansheng_tob"},
        @{@"name": @"醋精男友 2.0", @"voiceType": @"ICL_uranus_zh_male_cujingnanyou_tob"},
        @{@"name": @"低音沉郁 2.0", @"voiceType": @"ICL_uranus_zh_male_diyinchenyu_tob"},
        @{@"name": @"风发少年 2.0", @"voiceType": @"ICL_uranus_zh_male_fengfashaonian_tob"},
        @{@"name": @"儒雅公子 2.0", @"voiceType": @"ICL_uranus_zh_male_ruyagongzi_tob"},
        @{@"name": @"腹黑公子 2.0", @"voiceType": @"ICL_uranus_zh_male_fuheigongzi_tob"},
        @{@"name": @"干净少年 2.0", @"voiceType": @"ICL_uranus_zh_male_ganjingshaonian_tob"},
        @{@"name": @"高冷总裁 2.0", @"voiceType": @"ICL_uranus_zh_male_gaolengzongcai_tob"},
        @{@"name": @"孤傲公子 2.0", @"voiceType": @"ICL_uranus_zh_male_guaogongzi_tob"},
        @{@"name": @"孤高公子 2.0", @"voiceType": @"ICL_uranus_zh_male_gugaogongzi_tob"},
        @{@"name": @"诡异神秘 2.0", @"voiceType": @"ICL_uranus_zh_male_guiyishenmi_tob"},
        @{@"name": @"固执病娇 2.0", @"voiceType": @"ICL_uranus_zh_male_guzhibingjiao_tob"},
        @{@"name": @"憨厚敦实 2.0", @"voiceType": @"ICL_uranus_zh_male_hanhoudunshi_tob"},
        @{@"name": @"活力青年 2.0", @"voiceType": @"ICL_uranus_zh_male_huoliqingnian_tob"},
        @{@"name": @"活泼男友 2.0", @"voiceType": @"ICL_uranus_zh_male_huoponanyou_tob"},
        @{@"name": @"活泼爽朗 2.0", @"voiceType": @"ICL_uranus_zh_male_huoposhuanglang_tob"},
        @{@"name": @"胡子叔叔 2.0", @"voiceType": @"ICL_uranus_zh_male_huzishushu_tob"},
        @{@"name": @"机甲智能 2.0", @"voiceType": @"ICL_uranus_zh_male_jijiazhineng_tob"},
        @{@"name": @"精英青年 2.0", @"voiceType": @"ICL_uranus_zh_male_jingyingqingnian_tob"},
        @{@"name": @"俊逸公子 2.0", @"voiceType": @"ICL_uranus_zh_male_junyigongzi_tob"},
        @{@"name": @"开朗轻快 2.0", @"voiceType": @"ICL_uranus_zh_male_kailangqingkuai_tob"},
        @{@"name": @"开朗青年 2.0", @"voiceType": @"ICL_uranus_zh_male_kailangqingnian_tob"},
        @{@"name": @"蓝银草魂师 2.0", @"voiceType": @"ICL_uranus_zh_male_lanyincaohunshi_tob"},
        @{@"name": @"冷傲总裁 2.0", @"voiceType": @"ICL_uranus_zh_male_lengaozongcai_tob"},
        @{@"name": @"冷淡疏离 2.0", @"voiceType": @"ICL_uranus_zh_male_lengdanshuli_tob"},
        @{@"name": @"冷峻高智 2.0", @"voiceType": @"ICL_uranus_zh_male_lengjungaozhi_tob"},
        @{@"name": @"冷峻上司 2.0", @"voiceType": @"ICL_uranus_zh_male_lengjunshangsi_tob"},
        @{@"name": @"冷酷哥哥 2.0", @"voiceType": @"ICL_uranus_zh_male_lengkugege_tob"},
        @{@"name": @"冷脸兄长 2.0", @"voiceType": @"ICL_uranus_zh_male_lenglianxiongzhang_tob"},
        @{@"name": @"冷脸学霸 2.0", @"voiceType": @"ICL_uranus_zh_male_lenglianxueba_tob"},
        @{@"name": @"冷漠男友 2.0", @"voiceType": @"ICL_uranus_zh_male_lengmonanyou_tob"},
        @{@"name": @"冷漠兄长 2.0", @"voiceType": @"ICL_uranus_zh_male_lengmoxiongzhang_tob"},
        @{@"name": @"凌云青年 2.0", @"voiceType": @"ICL_uranus_zh_male_lingyunqingnian_tob"},
        @{@"name": @"清冷矜贵 2.0", @"voiceType": @"ICL_uranus_zh_male_qinglengjingui_tob"},
        @{@"name": @"绿茶小哥 2.0", @"voiceType": @"ICL_uranus_zh_male_lvchaxiaoge_tob"},
        @{@"name": @"懵懂青年 2.0", @"voiceType": @"ICL_uranus_zh_male_mengdongqingnian_tob"},
        @{@"name": @"闷油瓶小哥 2.0", @"voiceType": @"ICL_uranus_zh_male_menyoupingxiaoge_tob"},
        @{@"name": @"嚣张小哥 2.0", @"voiceType": @"ICL_uranus_zh_male_xiaozhangxiaoge_tob"},
        @{@"name": @"粘人男友 2.0", @"voiceType": @"ICL_uranus_zh_male_nianrennanyou_tob"},
        @{@"name": @"内敛才俊 2.0", @"voiceType": @"ICL_uranus_zh_male_neiliancaijun_tob"},
        @{@"name": @"暖心体贴 2.0", @"voiceType": @"ICL_uranus_zh_male_nuanxintitie_tob"},
        @{@"name": @"翩翩公子 2.0", @"voiceType": @"ICL_uranus_zh_male_pianpiangongzi_tob"},
        @{@"name": @"沉稳优雅 2.0", @"voiceType": @"ICL_uranus_zh_male_chenwenyouya_tob"},
        @{@"name": @"青涩小生 2.0", @"voiceType": @"ICL_uranus_zh_male_qingsexiaosheng_tob"},
        @{@"name": @"青涩青年 2.0", @"voiceType": @"ICL_uranus_zh_male_qingseqingnian_tob"},
        @{@"name": @"清爽少年 2.0", @"voiceType": @"ICL_uranus_zh_male_qingshuangshaonian_tob"},
        @{@"name": @"清新波波 2.0", @"voiceType": @"ICL_uranus_zh_male_qingxinbobo_tob"},
        @{@"name": @"亲切青年 2.0", @"voiceType": @"ICL_uranus_zh_male_qinqieqingnian_tob"},
        @{@"name": @"亲切小卓 2.0", @"voiceType": @"ICL_uranus_zh_male_qinqiexiaozhuo_tob"},
        @{@"name": @"清朗温润 2.0", @"voiceType": @"ICL_uranus_zh_male_qinglangwenrun_tob"},
        @{@"name": @"热血少年 2.0", @"voiceType": @"ICL_uranus_zh_male_rexueshaonian_tob"},
        @{@"name": @"儒雅才俊 2.0", @"voiceType": @"ICL_uranus_zh_male_ruyacaijun_tob"},
        @{@"name": @"儒雅君子 2.0", @"voiceType": @"ICL_uranus_zh_male_ruyajunzi_tob"},
        @{@"name": @"儒雅总裁 2.0", @"voiceType": @"ICL_uranus_zh_male_ruyazongcai_tob"},
        @{@"name": @"撒娇男生 2.0", @"voiceType": @"ICL_uranus_zh_male_sajiaonansheng_tob"},
        @{@"name": @"撒娇男友 2.0", @"voiceType": @"ICL_uranus_zh_male_sajiaonanyou_tob"},
        @{@"name": @"撒娇粘人 2.0", @"voiceType": @"ICL_uranus_zh_male_sajiaonianren_tob"},
        @{@"name": @"洒脱青年 2.0", @"voiceType": @"ICL_uranus_zh_male_satuoqingnian_tob"},
        @{@"name": @"少年将军 2.0", @"voiceType": @"ICL_uranus_zh_male_shaonianjiangjun_tob"},
        @{@"name": @"深沉总裁 2.0", @"voiceType": @"ICL_uranus_zh_male_shenchenzongcai_tob"},
        @{@"name": @"机灵小伙 2.0", @"voiceType": @"ICL_uranus_zh_male_jilingxiaohuo_tob"},
        @{@"name": @"神秘法师 2.0", @"voiceType": @"ICL_uranus_zh_male_shenmifashi_tob"},
        @{@"name": @"率真小伙 2.0", @"voiceType": @"ICL_uranus_zh_male_shuaizhenxiaohuo_tob"},
        @{@"name": @"爽朗小阳 2.0", @"voiceType": @"ICL_uranus_zh_male_shuanglangxiaoyang_tob"},
        @{@"name": @"低沉缱绻 2.0", @"voiceType": @"ICL_uranus_zh_male_dichenqianquan_tob"},
        @{@"name": @"斯文青年 2.0", @"voiceType": @"ICL_uranus_zh_male_siwenqingnian_tob"},
        @{@"name": @"甜系男友 2.0", @"voiceType": @"ICL_uranus_zh_male_tianxinanyou_tob"},
        @{@"name": @"贴心男友 2.0", @"voiceType": @"ICL_uranus_zh_male_tiexinnanyou_tob"},
        @{@"name": @"温柔男同桌 2.0", @"voiceType": @"ICL_uranus_zh_male_wenrounantongzhuo_tob"},
        @{@"name": @"温柔男友 2.0", @"voiceType": @"ICL_uranus_zh_male_wenrounanyou_tob"},
        @{@"name": @"温柔学长 2.0", @"voiceType": @"ICL_uranus_zh_male_wenrouxuezhang_tob"},
        @{@"name": @"温润学者 2.0", @"voiceType": @"ICL_uranus_zh_male_wenrunxuezhe_tob"},
        @{@"name": @"温顺少年 2.0", @"voiceType": @"ICL_uranus_zh_male_wenshunshaonian_tob"},
        @{@"name": @"寡言小哥 2.0", @"voiceType": @"ICL_uranus_zh_male_guayanxiaoge_tob"},
        @{@"name": @"小侯爷 2.0", @"voiceType": @"ICL_uranus_zh_male_xiaohouye_tob"},
        @{@"name": @"奶气小生 2.0", @"voiceType": @"ICL_uranus_zh_male_naiqixiaosheng_tob"},
        @{@"name": @"潇洒随性 2.0", @"voiceType": @"ICL_uranus_zh_male_xiaosasuixing_tob"},
        @{@"name": @"温柔内敛 2.0", @"voiceType": @"ICL_uranus_zh_male_wenrouneilian_tob"},
        @{@"name": @"学霸男同桌 2.0", @"voiceType": @"ICL_uranus_zh_male_xuebanantongzhuo_tob"},
        @{@"name": @"学霸同桌 2.0", @"voiceType": @"ICL_uranus_zh_male_xuebatongzhuo_tob"},
        @{@"name": @"阳光洋洋 2.0", @"voiceType": @"ICL_uranus_zh_male_yangguangyangyang_tob"},
        @{@"name": @"温暖少年 2.0", @"voiceType": @"ICL_uranus_zh_male_wennuanshaonian_tob"},
        @{@"name": @"意气少年 2.0", @"voiceType": @"ICL_uranus_zh_male_yiqishaonian_tob"},
        @{@"name": @"油腻大叔 2.0", @"voiceType": @"ICL_uranus_zh_male_younidashu_tob"},
        @{@"name": @"幽默大爷 2.0", @"voiceType": @"ICL_uranus_zh_male_youmodaye_tob"},
        @{@"name": @"幽默叔叔 2.0", @"voiceType": @"ICL_uranus_zh_male_youmoshushu_tob"},
        @{@"name": @"优柔帮主 2.0", @"voiceType": @"ICL_uranus_zh_male_youroubangzhu_tob"},
        @{@"name": @"优柔公子 2.0", @"voiceType": @"ICL_uranus_zh_male_yourougongzi_tob"},
        @{@"name": @"元气少年 2.0", @"voiceType": @"ICL_uranus_zh_male_yuanqishaonian_tob"},
        @{@"name": @"仗剑君子 2.0", @"voiceType": @"ICL_uranus_zh_male_zhangjianjunzi_tob"},
        @{@"name": @"仗剑侠客 2.0", @"voiceType": @"ICL_uranus_zh_male_zhangjianxiake_tob"},
        @{@"name": @"正直青年 2.0", @"voiceType": @"ICL_uranus_zh_male_zhengzhiqingnian_tob"},
        @{@"name": @"直率青年 2.0", @"voiceType": @"ICL_uranus_zh_male_zhishuaiqingnian_tob"},
        @{@"name": @"中二青年 2.0", @"voiceType": @"ICL_uranus_zh_male_zhongerqingnian_tob"},
        @{@"name": @"自负青年 2.0", @"voiceType": @"ICL_uranus_zh_male_zifuqingnian_tob"},
        @{@"name": @"自信青年 2.0", @"voiceType": @"ICL_uranus_zh_male_zixinqingnian_tob"},
        @{@"name": @"天才同桌 2.0", @"voiceType": @"ICL_uranus_zh_male_tiancaitongzhuo_tob"},
        @{@"name": @"清新沐沐 2.0", @"voiceType": @"ICL_uranus_zh_male_qingxinmumu_tob"},
        @{@"name": @"温婉珊珊 2.0", @"voiceType": @"ICL_uranus_zh_female_wenwanshanshan_tob"},
        @{@"name": @"热情艾娜 2.0", @"voiceType": @"ICL_uranus_zh_female_reqingaina_tob"},
        @{@"name": @"爽朗少年 2.0", @"voiceType": @"ICL_uranus_zh_male_shuanglangshaonian_tob"},
        @{@"name": @"轻盈朵朵 2.0", @"voiceType": @"ICL_uranus_zh_female_qingyingduoduo_tob"},
        @{@"name": @"Dina", @"voiceType": @"ar_female_dina_uranus_bigtts"},
        @{@"name": @"Fatma", @"voiceType": @"ar_female_fatma_uranus_bigtts"},
        @{@"name": @"Youssef", @"voiceType": @"ar_male_youssef_uranus_bigtts"},
        @{@"name": @"Stella", @"voiceType": @"de_female_bv081_uranus_bigtts"},
        @{@"name": @"Sven", @"voiceType": @"de_male_sven_uranus_bigtts"},
        @{@"name": @"Rowan", @"voiceType": @"en_male_adam-imitation_uranus_bigtts"},
        @{@"name": @"Alberto", @"voiceType": @"en_male_alberto_uranus_bigtts"},
        @{@"name": @"Alex", @"voiceType": @"en_male_alex_uranus_bigtts"},
        @{@"name": @"Allison", @"voiceType": @"en_female_allison_uranus_bigtts"},
        @{@"name": @"Charlotte", @"voiceType": @"en_female_authoritative-british_uranus_bigtts"},
        @{@"name": @"Margaret", @"voiceType": @"en_female_authoritative-informative_uranus_bigtts"},
        @{@"name": @"Jones", @"voiceType": @"en_male_bill-jones_uranus_bigtts"},
        @{@"name": @"Bill", @"voiceType": @"en_male_bill_jones_corey_uranus_bigtts"},
        @{@"name": @"Brad_Pitt", @"voiceType": @"en_male_brad_pitt_p1_uranus_bigtts"},
        @{@"name": @"Brittney", @"voiceType": @"en_female_brittney_uranus_bigtts"},
        @{@"name": @"Zoe", @"voiceType": @"en_female_brittney_pimintel_uranus_bigtts"},
        @{@"name": @"Adrian", @"voiceType": @"en_male_bruce_uranus_bigtts"},
        @{@"name": @"Leo", @"voiceType": @"en_male_chandler_p1_uranus_bigtts"},
        @{@"name": @"Bob", @"voiceType": @"en_male_cowboy-bob_uranus_bigtts"},
        @{@"name": @"John", @"voiceType": @"en_male_cowboy_john_b_uranus_bigtts"},
        @{@"name": @"David", @"voiceType": @"en_male_david_uranus_bigtts"},
        @{@"name": @"Orion", @"voiceType": @"en_male_deep-voice_uranus_bigtts"},
        @{@"name": @"Julian", @"voiceType": @"en_male_diyuwenrounan_uranus_bigtts"},
        @{@"name": @"Harrison", @"voiceType": @"en_male_evil-guy-oxley_uranus_bigtts"},
        @{@"name": @"Jasper", @"voiceType": @"en_male_excited-male-voice_uranus_bigtts"},
        @{@"name": @"Alfred", @"voiceType": @"en_male_father-christmas_uranus_bigtts"},
        @{@"name": @"Holly", @"voiceType": @"en_female_female_tutor_ms-jenny_uranus_bigtts"},
        @{@"name": @"Felix", @"voiceType": @"en_male_fernando-martinez_uranus_bigtts"},
        @{@"name": @"Godfather", @"voiceType": @"en_male_godfather_uranus_bigtts"},
        @{@"name": @"Gollum", @"voiceType": @"en_male_gollum_uranus_bigtts"},
        @{@"name": @"Beau", @"voiceType": @"en_male_hades_uranus_bigtts"},
        @{@"name": @"Hayley", @"voiceType": @"en_female_hayley_uranus_bigtts"},
        @{@"name": @"Jamie", @"voiceType": @"en_male_jamie_uranus_bigtts"},
        @{@"name": @"Jane", @"voiceType": @"en_female_jane_uranus_bigtts"},
        @{@"name": @"Jenny", @"voiceType": @"en_female_jenny_uranus_bigtts"},
        @{@"name": @"Blaze", @"voiceType": @"en_male_jidongchuanjiaoshi_uranus_bigtts"},
        @{@"name": @"Jimmy", @"voiceType": @"en_male_jimmy_uranus_bigtts"},
        @{@"name": @"Joanne", @"voiceType": @"en_female_joanne_uranus_bigtts"},
        @{@"name": @"Joker", @"voiceType": @"en_male_joker_uranus_bigtts"},
        @{@"name": @"Josh", @"voiceType": @"en_male_josh_uranus_bigtts"},
        @{@"name": @"Josiah", @"voiceType": @"en_male_josh_coery_uranus_bigtts"},
        @{@"name": @"Kevin", @"voiceType": @"en_male_kevin_uranus_bigtts"},
        @{@"name": @"Knightley", @"voiceType": @"en_male_knightley_uranus_bigtts"},
        @{@"name": @"Lynn", @"voiceType": @"en_female_lana_del_rey_kelley_d_p1_uranus_bigtts"},
        @{@"name": @"Ivy", @"voiceType": @"en_female_lana_del_rey_parky_s_p1_uranus_bigtts"},
        @{@"name": @"Marcus", @"voiceType": @"en_male_marcus_uranus_bigtts"},
        @{@"name": @"Mel", @"voiceType": @"en_female_mel_uranus_bigtts"},
        @{@"name": @"Hank", @"voiceType": @"en_male_michael_uranus_bigtts"},
        @{@"name": @"Chip", @"voiceType": @"en_male_michael-mouse_uranus_bigtts"},
        @{@"name": @"Michael_Kevin", @"voiceType": @"en_male_michael_kevin_uranus_bigtts"},
        @{@"name": @"Rory", @"voiceType": @"en_male_motivational-coach_uranus_bigtts"},
        @{@"name": @"Myra", @"voiceType": @"en_female_myra_uranus_bigtts"},
        @{@"name": @"Sunny", @"voiceType": @"en_female_myra_cmb_uranus_bigtts"},
        @{@"name": @"Blair", @"voiceType": @"en_female_nadia_uranus_bigtts"},
        @{@"name": @"Natasha", @"voiceType": @"en_female_natasha_uranus_bigtts"},
        @{@"name": @"Elaine", @"voiceType": @"en_female_pleasant-female_uranus_bigtts"},
        @{@"name": @"Rachel", @"voiceType": @"en_female_rachel_p1_uranus_bigtts"},
        @{@"name": @"Ronald", @"voiceType": @"en_male_ronald_uranus_bigtts"},
        @{@"name": @"Russell", @"voiceType": @"en_male_russell_uranus_bigtts"},
        @{@"name": @"Scarlet", @"voiceType": @"en_female_scarlet_p1_uranus_bigtts"},
        @{@"name": @"Sharron", @"voiceType": @"en_female_sharron_uranus_bigtts"},
        @{@"name": @"Simba", @"voiceType": @"en_male_simba_p1_uranus_bigtts"},
        @{@"name": @"Skye", @"voiceType": @"en_female_skye_uranus_bigtts"},
        @{@"name": @"Tom", @"voiceType": @"en_male_tom_hiddleston_p1_uranus_bigtts"},
        @{@"name": @"Valentino", @"voiceType": @"en_male_valentino_uranus_bigtts"},
        @{@"name": @"Clark", @"voiceType": @"en_male_valentino_corey_uranus_bigtts"},
        @{@"name": @"Megan", @"voiceType": @"en_female_wenrouzhishijieshuonv_uranus_bigtts"},
        @{@"name": @"Kayla", @"voiceType": @"en_female_xinwenjieshuonv_uranus_bigtts"},
        @{@"name": @"Dylan", @"voiceType": @"en_male_yangguangjieshuonan_uranus_bigtts"},
        @{@"name": @"Zendaya", @"voiceType": @"en_female_zendaya_p1_uranus_bigtts"},
        @{@"name": @"Gracie", @"voiceType": @"es_female_bv084_uranus_bigtts"},
        @{@"name": @"Dani", @"voiceType": @"es_male_dani_uranus_bigtts"},
        @{@"name": @"Guillem", @"voiceType": @"es_male_guillem_uranus_bigtts"},
        @{@"name": @"Marisol", @"voiceType": @"es_female_ht_mx_f6_uranus_bigtts"},
        @{@"name": @"Simone", @"voiceType": @"fr_female_fr_bv078_uranus_bigtts"},
        @{@"name": @"Camille", @"voiceType": @"fr_female_fr_f47_uranus_bigtts"},
        @{@"name": @"Maurice", @"voiceType": @"fr_male_fr_m29_uranus_bigtts"},
        @{@"name": @"Usseau", @"voiceType": @"fr_male_usseau_uranus_bigtts"},
        @{@"name": @"Rocco", @"voiceType": @"id_male_bv160_uranus_bigtts"},
        @{@"name": @"Jude", @"voiceType": @"id_male_bv160dialogue_uranus_bigtts"},
        @{@"name": @"Hugo", @"voiceType": @"id_male_bv160narration_uranus_bigtts"},
        @{@"name": @"Clara", @"voiceType": @"id_female_bv161_uranus_bigtts"},
        @{@"name": @"Sylvia", @"voiceType": @"id_female_bv161dialogue_uranus_bigtts"},
        @{@"name": @"Celeste", @"voiceType": @"id_female_bv161narration_uranus_bigtts"},
        @{@"name": @"Crew", @"voiceType": @"id_female_bv164_uranus_bigtts"},
        @{@"name": @"Elian", @"voiceType": @"id_male_bv164dialogue_uranus_bigtts"},
        @{@"name": @"Ronan", @"voiceType": @"id_male_bv164narration_uranus_bigtts"},
        @{@"name": @"Chloe", @"voiceType": @"id_female_f20_uranus_bigtts"},
        @{@"name": @"Han", @"voiceType": @"id_male_han_uranus_bigtts"},
        @{@"name": @"Kyle", @"voiceType": @"id_male_m08_uranus_bigtts"},
        @{@"name": @"Phulia", @"voiceType": @"id_female_phulia_uranus_bigtts"},
        @{@"name": @"Bonnie", @"voiceType": @"ja_female_bv024_uranus_bigtts"},
        @{@"name": @"Poppy", @"voiceType": @"ja_female_bv520_uranus_bigtts"},
        @{@"name": @"Aoi", @"voiceType": @"ja_female_bv521_uranus_bigtts"},
        @{@"name": @"Hana", @"voiceType": @"ja_female_bv522_uranus_bigtts"},
        @{@"name": @"Lily", @"voiceType": @"ja_female_bv523_uranus_bigtts"},
        @{@"name": @"Ken", @"voiceType": @"ja_male_bv524_uranus_bigtts"},
        @{@"name": @"Minimi", @"voiceType": @"ja_female_minimi_uranus_bigtts"},
        @{@"name": @"Shirou", @"voiceType": @"ja_female_shirou_uranus_bigtts"},
        @{@"name": @"Jay", @"voiceType": @"ko_male_bv545_uranus_bigtts"},
        @{@"name": @"Momo", @"voiceType": @"ko_female_bv546_uranus_bigtts"},
        @{@"name": @"Minho", @"voiceType": @"ko_male_m03_uranus_bigtts"},
        @{@"name": @"Shane", @"voiceType": @"ko_male_shane_uranus_bigtts"},
        @{@"name": @"Ham", @"voiceType": @"ms_male_ham_uranus_bigtts"},
        @{@"name": @"Naim", @"voiceType": @"ms_male_naim_uranus_bigtts"},
        @{@"name": @"Irene", @"voiceType": @"mx_female_bv065_uranus_bigtts"},
        @{@"name": @"Diego", @"voiceType": @"mx_male_bv165dialogue_uranus_bigtts"},
        @{@"name": @"Marcos", @"voiceType": @"mx_male_bv165narrator_uranus_bigtts"},
        @{@"name": @"Lucy", @"voiceType": @"mx_female_bv166dialogue_uranus_bigtts"},
        @{@"name": @"Rosa", @"voiceType": @"mx_female_bv166emotion_uranus_bigtts"},
        @{@"name": @"Freya", @"voiceType": @"mx_female_bv166narrator_uranus_bigtts"},
        @{@"name": @"Felipe", @"voiceType": @"mx_male_felipe_uranus_bigtts"},
        @{@"name": @"Derek", @"voiceType": @"mx_male_ht_mx_m012_uranus_bigtts"},
        @{@"name": @"Leslie", @"voiceType": @"mx_female_leslie_uranus_bigtts"},
        @{@"name": @"Marcelo", @"voiceType": @"mx_male_marcelo_uranus_bigtts"},
        @{@"name": @"Sam", @"voiceType": @"pt_male_bv172_uranus_bigtts"},
        @{@"name": @"Walter", @"voiceType": @"pt_male_bv172dialogue_uranus_bigtts"},
        @{@"name": @"Vincent", @"voiceType": @"pt_male_bv172emotion_uranus_bigtts"},
        @{@"name": @"Miles", @"voiceType": @"pt_male_bv172narrator_uranus_bigtts"},
        @{@"name": @"Diana", @"voiceType": @"pt_female_bv173_uranus_bigtts"},
        @{@"name": @"Elena", @"voiceType": @"pt_female_bv173dialogue_uranus_bigtts"},
        @{@"name": @"Lola", @"voiceType": @"pt_female_bv173emotion_uranus_bigtts"},
        @{@"name": @"Emma", @"voiceType": @"pt_female_bv173narrator_uranus_bigtts"},
        @{@"name": @"Sofia", @"voiceType": @"pt_female_bv530_uranus_bigtts"},
        @{@"name": @"Arthur", @"voiceType": @"pt_male_bv531_uranus_bigtts"},
        @{@"name": @"Mari", @"voiceType": @"pt_female_mari_uranus_bigtts"},
        @{@"name": @"Toby", @"voiceType": @"pt_male_martins_uranus_bigtts"},
        @{@"name": @"Rael", @"voiceType": @"pt_male_rael_uranus_bigtts"},
        @{@"name": @"Amelia", @"voiceType": @"ru_female_af07_uranus_bigtts"},
        @{@"name": @"Irinae", @"voiceType": @"ru_female_irinae_uranus_bigtts"},
        @{@"name": @"Pavel", @"voiceType": @"ru_male_pavel_uranus_bigtts"},
        @{@"name": @"Ksenia", @"voiceType": @"ru_female_sophie_uranus_bigtts"},
        @{@"name": @"Silas", @"voiceType": @"ru_male_vlad_uranus_bigtts"},
        @{@"name": @"Valeria", @"voiceType": @"th_female_bv568_angry_uranus_bigtts"},
        @{@"name": @"Iris", @"voiceType": @"th_female_bv568_fear_uranus_bigtts"},
        @{@"name": @"Zara", @"voiceType": @"th_female_bv568_happy_uranus_bigtts"},
        @{@"name": @"Valentina", @"voiceType": @"th_female_bv568_hate_uranus_bigtts"},
        @{@"name": @"Mildred", @"voiceType": @"th_female_bv568_neutral_uranus_bigtts"},
        @{@"name": @"Lydia", @"voiceType": @"th_female_bv568_sad_uranus_bigtts"},
        @{@"name": @"Phoebe", @"voiceType": @"th_female_bv568_suprise_uranus_bigtts"},
        @{@"name": @"Annika", @"voiceType": @"tl_female_annika_uranus_bigtts"},
        @{@"name": @"Ed", @"voiceType": @"tl_male_ed_uranus_bigtts"},
        @{@"name": @"Hervie", @"voiceType": @"tl_female_hervie_uranus_bigtts"},
        @{@"name": @"Hong", @"voiceType": @"vi_female_hong_uranus_bigtts"},
        @{@"name": @"Ling", @"voiceType": @"vi_female_ling_uranus_bigtts"},
        @{@"name": @"Linh", @"voiceType": @"vi_female_linh_uranus_bigtts"},
        @{@"name": @"Partner", @"voiceType": @"vi_female_partner_uranus_bigtts"},
        @{@"name": @"Ruan", @"voiceType": @"vi_female_ruan_uranus_bigtts"},
        @{@"name": @"Wu", @"voiceType": @"vi_female_wu_uranus_bigtts"},
        @{@"name": @"Wumg", @"voiceType": @"vi_male_wumg_uranus_bigtts"},
        @{@"name": @"Enzo", @"voiceType": @"it_male_enzo_uranus_bigtts"},
    ];
}

@end
