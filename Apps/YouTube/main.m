#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface YTController : UIViewController <WKNavigationDelegate,WKUIDelegate>
@property(nonatomic,strong) WKWebView *web;
@property(nonatomic,strong) UILabel *status;
@property(nonatomic,strong) UIProgressView *progress;
@property(nonatomic,strong) UIActivityIndicatorView *loading;
@property(nonatomic,strong) UIButton *backBtn,*nextBtn;
@end
@implementation YTController
- (UIColor *)backgroundColor{return [UIColor colorWithRed:.035 green:.08 blue:.11 alpha:1];}
- (UIColor *)accentColor{return [UIColor colorWithRed:.12 green:.85 blue:.80 alpha:1];}
- (UIButton *)button:(NSString *)name selector:(SEL)sel {
 UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];
 [b setTitle:name forState:UIControlStateNormal];[b setTitleColor:[self accentColor] forState:UIControlStateNormal];
 b.titleLabel.font=[UIFont boldSystemFontOfSize:14]; b.backgroundColor=[UIColor colorWithRed:.07 green:.16 blue:.2 alpha:1];
 b.layer.cornerRadius=5;[b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
 return b;
}
- (void)viewDidLoad {
 [super viewDidLoad];self.view.backgroundColor=[self backgroundColor];
 WKWebViewConfiguration *cfg=[WKWebViewConfiguration new];
 cfg.allowsInlineMediaPlayback=YES;
 cfg.mediaTypesRequiringUserActionForPlayback=WKAudiovisualMediaTypeAll;
 self.web=[[WKWebView alloc] initWithFrame:CGRectZero configuration:cfg];
 self.web.navigationDelegate=self;self.web.UIDelegate=self;self.web.allowsBackForwardNavigationGestures=YES;
 self.web.scrollView.backgroundColor=[UIColor blackColor];
 self.web.opaque=NO;self.web.backgroundColor=[UIColor blackColor];
 [self.view addSubview:self.web];
 self.backBtn=[self button:@"‹ SPÄŤ" selector:@selector(goBack)];
 self.nextBtn=[self button:@"ĎALEJ ›" selector:@selector(goForward)];
 NSArray *others=@[self.backBtn,self.nextBtn,
 [self button:@"DOMOV" selector:@selector(goHome)],
 [self button:@"OBNOVIŤ" selector:@selector(reload)],
 [self button:@"SAFARI" selector:@selector(openSafari)],
 [self button:@"MOJE ▾" selector:@selector(openPersonalMenu)]];
 for(NSInteger i=0;i<others.count;i++){UIButton *b=others[i];b.tag=100+i;[self.view addSubview:b];}
 self.status=[UILabel new];self.status.textColor=[UIColor colorWithWhite:.85 alpha:1];
 self.status.font=[UIFont systemFontOfSize:12];self.status.text=@"YouTube Web • pripravené";self.status.numberOfLines=1;self.status.textAlignment=NSTextAlignmentRight;self.status.adjustsFontSizeToFitWidth=YES;
 [self.view addSubview:self.status];
 self.progress=[UIProgressView new];self.progress.progressTintColor=[self accentColor];[self.view addSubview:self.progress];
 self.loading=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];[self.view addSubview:self.loading];
 [self goHome];
}
- (void)viewDidLayoutSubviews {
 [super viewDidLayoutSubviews];
 CGFloat w=self.view.bounds.size.width,h=self.view.bounds.size.height;
 CGFloat top=self.view.safeAreaInsets.top,bottom=self.view.safeAreaInsets.bottom;
 CGFloat margin=8,gap=5,toolbarHeight=28,topY=top+3;
 CGFloat widths[]={76,76,69,90,70,89};
 CGFloat total=0;for(NSInteger i=0;i<6;i++)total+=widths[i];
 CGFloat statusWidth=MIN(210,MAX(90,w*.22));
 CGFloat scale=MIN(1,MAX(.70,(w-2*margin-statusWidth-20-5*gap)/total));
 CGFloat x=margin;
 for(NSInteger i=0;i<6;i++){
  CGFloat cw=widths[i]*scale;
  [self.view viewWithTag:100+i].frame=CGRectMake(x,topY,cw,toolbarHeight);
  x+=cw+gap;
 }
 CGFloat statusX=MAX(x+4,w-statusWidth-8);
 self.loading.frame=CGRectMake(statusX,topY+6,16,16);
 self.status.frame=CGRectMake(statusX+19,topY+2,MAX(15,w-statusX-27),toolbarHeight-2);
 self.progress.frame=CGRectMake(0,topY+toolbarHeight+2,w,2);
 CGFloat webY=topY+toolbarHeight+5;
 self.web.frame=CGRectMake(0,webY,w,MAX(100,h-webY-bottom));
}
- (void)sync {
 self.backBtn.enabled=self.web.canGoBack;self.nextBtn.enabled=self.web.canGoForward;
 self.backBtn.alpha=self.backBtn.enabled?1:.35;self.nextBtn.alpha=self.nextBtn.enabled?1:.35;
 self.progress.progress=self.web.estimatedProgress;
}
- (void)goHome {NSURL *u=[NSURL URLWithString:@"https://m.youtube.com/"];[self.web loadRequest:[NSURLRequest requestWithURL:u cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30]];}
- (void)reload {[self.web reload];}
- (void)openPersonalPath:(NSString *)path {
 NSURL *u=[NSURL URLWithString:[@"https://m.youtube.com" stringByAppendingString:path]];
 if(u)[self.web loadRequest:[NSURLRequest requestWithURL:u cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30]];
}
- (void)openPersonalMenu {
 UIAlertController *menu=[UIAlertController alertControllerWithTitle:@"Moje videá na YouTube"
  message:@"Otvoria sa príslušné stránky YouTube. Dostupnosť súkromných zoznamov závisí od prihlásenia v tomto okne." preferredStyle:UIAlertControllerStyleActionSheet];
 NSArray *labels=@[@"História",@"Pozrieť neskôr",@"Páči sa mi",@"Playlisty",@"Odbery"];
 NSArray *paths=@[@"/feed/history",@"/playlist?list=WL",@"/playlist?list=LL",@"/feed/playlists",@"/feed/subscriptions"];
 for(NSInteger i=0;i<labels.count;i++){
  NSString *path=paths[i];
  [menu addAction:[UIAlertAction actionWithTitle:labels[i] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){[self openPersonalPath:path];}]];
 }
 [menu addAction:[UIAlertAction actionWithTitle:@"OTVORIŤ V SAFARI" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){[self openSafari];}]];
 [menu addAction:[UIAlertAction actionWithTitle:@"ZRUŠIŤ" style:UIAlertActionStyleCancel handler:nil]];
 UIPopoverPresentationController *pop=menu.popoverPresentationController;
 UIView *origin=[self.view viewWithTag:105];
 if(pop){pop.sourceView=origin;pop.sourceRect=origin.bounds;}
 [self presentViewController:menu animated:YES completion:nil];
}
- (void)goBack {if(self.web.canGoBack)[self.web goBack];}
- (void)goForward {if(self.web.canGoForward)[self.web goForward];}
- (void)openSafari {
 NSURL *url=self.web.URL?:[NSURL URLWithString:@"https://m.youtube.com/"];
 if(![@[@"https",@"http"] containsObject:url.scheme])url=[NSURL URLWithString:@"https://m.youtube.com/"];
 [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}
- (void)webView:(WKWebView *)web didStartProvisionalNavigation:(WKNavigation *)nav {
 self.status.text=@"Načítavam YouTube...";[self.loading startAnimating];[self sync];
}
- (void)webView:(WKWebView *)web didFinishNavigation:(WKNavigation *)nav {
 [self.loading stopAnimating];self.status.text=@"Pripravené";[self sync];self.progress.progress=0;
}
- (void)webView:(WKWebView *)web didFailNavigation:(WKNavigation *)nav withError:(NSError *)error {
 [self failed:error];
}
- (void)webView:(WKWebView *)web didFailProvisionalNavigation:(WKNavigation *)nav withError:(NSError *)error {
 [self failed:error];
}
- (void)failed:(NSError *)error {
 [self.loading stopAnimating];[self sync];
 self.status.text=[NSString stringWithFormat:@"Načítanie zlyhalo: %@",error.localizedDescription?:@"neznáma chyba"];
}
- (void)webView:(WKWebView *)web decidePolicyForNavigationAction:(WKNavigationAction *)action decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
 NSURL *url=action.request.URL; NSString *scheme=url.scheme.lowercaseString;
 if([@[@"http",@"https"] containsObject:scheme])decisionHandler(WKNavigationActionPolicyAllow);
 else decisionHandler(WKNavigationActionPolicyCancel);
}
- (WKWebView *)webView:(WKWebView *)web createWebViewWithConfiguration:(WKWebViewConfiguration *)cfg forNavigationAction:(WKNavigationAction *)action windowFeatures:(WKWindowFeatures *)features {
 NSURL *url=action.request.URL;
 if(!action.targetFrame && [@[@"http",@"https"] containsObject:url.scheme.lowercaseString])[self.web loadRequest:[NSURLRequest requestWithURL:url]];
 return nil;
}
@end

@interface YTAppDelegate : UIResponder <UIApplicationDelegate>
@property(strong,nonatomic) UIWindow *window;
@end
@implementation YTAppDelegate
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)opts {
 self.window=[[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
 self.window.rootViewController=[YTController new];[self.window makeKeyAndVisible];return YES;
}
@end
int main(int argc,char **argv){@autoreleasepool{return UIApplicationMain(argc,argv,nil,NSStringFromClass(YTAppDelegate.class));}}
