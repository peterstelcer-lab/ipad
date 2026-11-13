#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonDigest.h>
#import <math.h>

@interface CNCTurningController : UIViewController
- (instancetype)initWithBaseURL:(NSString *)baseURL;
@end

@interface CNCController : UIViewController <UITableViewDataSource,UITableViewDelegate,UITextViewDelegate,UIDocumentPickerDelegate>
@property(nonatomic,strong) UITextField *address;
@property(nonatomic,strong) UILabel *status;
@property(nonatomic,strong) UITableView *table;
@property(nonatomic,strong) UITextView *editor;
@property(nonatomic,strong) NSMutableArray *files;
@property(nonatomic,copy) NSString *selected;
@property(nonatomic,assign) BOOL dirty;
@property(nonatomic,strong) UISegmentedControl *tabs;
@property(nonatomic,assign) NSInteger machineMode; // 0=offline, 1=NUM1040, 2=AlphaLink
@property(nonatomic,copy) NSString *connectedBase;
@property(nonatomic,copy) NSString *editorOriginal;
@property(nonatomic,strong) UIView *programPage,*libraryPanel,*transferPanel,*settingsPage;
@property(nonatomic,strong) UILabel *headerTitle,*piLight,*machineLight,*libraryTitle,*queueStatus,*selectedStatus,*progressStatus,*profileStatus,*transferStatus,*validationStatus,*transferTitle,*libraryHint;
@property(nonatomic,strong) UIProgressView *progressBar;
@property(nonatomic,strong) NSArray *navButtons,*libraryActions,*transferActions;
@property(nonatomic,strong) UIButton *queueClearButton,*uploadButton;
@property(nonatomic,strong) NSMutableArray *projects,*isoFiles;
@property(nonatomic,copy) NSString *queuedName;
@property(nonatomic,assign) NSInteger pageIndex;
@property(nonatomic,assign) BOOL transferBusy;
@property(nonatomic,assign) NSUInteger activeRequestSerial;

@end

@implementation CNCController
- (UIColor *)bg { return [UIColor colorWithRed:.035 green:.08 blue:.11 alpha:1]; }
- (UIColor *)panel { return [UIColor colorWithRed:.07 green:.15 blue:.19 alpha:1]; }
- (UIColor *)cyan { return [UIColor colorWithRed:.12 green:.85 blue:.80 alpha:1]; }
- (UIButton *)button:(NSString *)name action:(SEL)sel {
 UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem]; [b setTitle:name forState:UIControlStateNormal]; b.backgroundColor=self.panel; [b setTitleColor:self.cyan forState:UIControlStateNormal]; b.layer.cornerRadius=9; b.titleLabel.font=[UIFont boldSystemFontOfSize:16]; [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside]; return b;
}
- (UILabel *)dashboardLabel:(NSString *)text size:(CGFloat)font color:(UIColor *)color {
 UILabel *l=[UILabel new];l.text=text;l.font=[UIFont systemFontOfSize:font];l.textColor=color;
 l.adjustsFontSizeToFitWidth=YES;l.minimumScaleFactor=.65;l.numberOfLines=2;return l;
}
- (void)decoratePanel:(UIView *)view {
 view.backgroundColor=[UIColor colorWithRed:.025 green:.105 blue:.14 alpha:1];
 view.layer.cornerRadius=10;view.layer.borderColor=[[self cyan] colorWithAlphaComponent:.52].CGColor;
 view.layer.borderWidth=1.0;
}
- (UIButton *)dashboardButton:(NSString *)text action:(SEL)method tint:(UIColor *)tint {
 UIButton *b=[self button:text action:method];
 b.titleLabel.font=[UIFont boldSystemFontOfSize:15];
 b.titleLabel.adjustsFontSizeToFitWidth=YES;
 b.titleLabel.minimumScaleFactor=.65;b.layer.cornerRadius=7;b.layer.borderWidth=1;
 if(tint){b.backgroundColor=[tint colorWithAlphaComponent:.28];b.layer.borderColor=[tint colorWithAlphaComponent:.8].CGColor;
 [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];}
 else {b.backgroundColor=[UIColor colorWithRed:.035 green:.18 blue:.23 alpha:1];b.layer.borderColor=[[self cyan] colorWithAlphaComponent:.48].CGColor;}
 return b;
}
- (void)viewDidLoad {
 [super viewDidLoad];
 self.view.backgroundColor=self.bg;self.files=[NSMutableArray array];self.projects=[NSMutableArray array];self.isoFiles=[NSMutableArray array];
 self.machineMode=0;self.pageIndex=2;self.transferBusy=NO;
 self.headerTitle=[self dashboardLabel:@"ALPHALINK CAM V1.11" size:22 color:UIColor.whiteColor];
 self.headerTitle.font=[UIFont boldSystemFontOfSize:22];[self.view addSubview:self.headerTitle];
 self.piLight=[self dashboardLabel:@"● PI ODPOJENÉ" size:14 color:[UIColor colorWithRed:1 green:.58 blue:.30 alpha:1]];
 self.piLight.textAlignment=NSTextAlignmentCenter;[self.view addSubview:self.piLight];
 self.machineLight=[self dashboardLabel:@"● CNC NEOVERENÉ" size:13 color:[UIColor colorWithRed:1 green:.70 blue:.32 alpha:1]];
 self.machineLight.textAlignment=NSTextAlignmentRight;[self.view addSubview:self.machineLight];
 self.status=[self dashboardLabel:@"Pripravené • pripoj Raspberry Pi" size:13 color:[UIColor colorWithWhite:.80 alpha:1]];
 self.status.textAlignment=NSTextAlignmentCenter;[self.view addSubview:self.status];
 NSArray *titles=@[@"01 EDITÁCIA",@"02 G-KÓD .600",@"03 PRENOS / KNIŽNICA",@"04 NASTAVENIA"];
 NSMutableArray *nav=[NSMutableArray array];
 for(NSInteger i=0;i<titles.count;i++){UIButton *b=[self dashboardButton:titles[i] action:@selector(navigate:) tint:nil];
 b.tag=810+i;[self.view addSubview:b];[nav addObject:b];}self.navButtons=nav;
 // Kept as internal selection state for the existing editor API.
 self.tabs=[[UISegmentedControl alloc] initWithItems:@[@"PROGRAMY",@"G-KÓD",@"OPERÁCIE"]];
 self.tabs.selectedSegmentIndex=0;
 self.programPage=[UIView new];[self.view addSubview:self.programPage];
 self.libraryPanel=[UIView new];[self decoratePanel:self.libraryPanel];[self.programPage addSubview:self.libraryPanel];
 self.transferPanel=[UIView new];[self decoratePanel:self.transferPanel];[self.programPage addSubview:self.transferPanel];
 self.libraryTitle=[self dashboardLabel:@"▣  KNIŽNICA RASPBERRY PI" size:19 color:self.cyan];
 self.libraryTitle.font=[UIFont boldSystemFontOfSize:19];[self.libraryPanel addSubview:self.libraryTitle];
 // Redundant explanatory label removed to give the library more space.
 self.uploadButton=[self dashboardButton:@"⇧  NAHRAŤ .600 DO PI" action:@selector(uploadToPi) tint:self.cyan];[self.libraryPanel addSubview:self.uploadButton];
 self.table=[[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
 self.table.backgroundColor=[UIColor colorWithRed:.015 green:.067 blue:.089 alpha:1];self.table.dataSource=self;self.table.delegate=self;
 self.table.rowHeight=39;self.table.sectionHeaderHeight=0;
 self.table.separatorColor=[UIColor colorWithRed:.09 green:.28 blue:.33 alpha:1];
 [self.libraryPanel addSubview:self.table];
 self.queueStatus=[self dashboardLabel:@"FRONTA NA ODOSLANIE • prázdna" size:15 color:self.cyan];
 [self.libraryPanel addSubview:self.queueStatus];
 self.queueClearButton=[self dashboardButton:@"VYPRÁZDNIŤ" action:@selector(clearQueue) tint:nil];
 [self.libraryPanel addSubview:self.queueClearButton];
 self.selectedStatus=[self dashboardLabel:@"Vybraný program: žiadny" size:15 color:UIColor.whiteColor];[self.libraryPanel addSubview:self.selectedStatus];
 self.progressBar=[[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
 self.progressBar.progressTintColor=[UIColor colorWithRed:.04 green:.93 blue:.40 alpha:1];
 self.progressBar.trackTintColor=[UIColor colorWithWhite:.34 alpha:1];
 self.progressBar.progress=0;[self.libraryPanel addSubview:self.progressBar];
 self.progressStatus=[self dashboardLabel:@"0 / 0 B • 0 % • neprebieha prenos" size:13 color:self.cyan];
 self.progressStatus.textAlignment=NSTextAlignmentCenter;[self.libraryPanel addSubview:self.progressStatus];
 NSArray *actions=@[@"PRIPRAVIŤ DO FRONTY",@"ODOSLAŤ DO ALPHA 400",@"OTVORIŤ / UPRAVIŤ",@"ZMAZAŤ Z RASPBERRY PI",@"KONTROLA G-KÓDU",@"OBNOVIŤ KNIŽNICU"];
 NSArray *sels=@[@"prepareQueue",@"sendSelected",@"openSelected",@"deleteFromPi",@"validateSelected",@"refreshFiles"];
 NSMutableArray *leftButtons=[NSMutableArray array];
 for(NSInteger i=0;i<actions.count;i++){
 UIColor *tint=i==1?self.cyan:(i==2?[UIColor colorWithRed:.08 green:.77 blue:.37 alpha:1]:(i==3?[UIColor colorWithRed:.91 green:.19 blue:.29 alpha:1]:nil));
 UIButton *b=[self dashboardButton:actions[i] action:NSSelectorFromString(sels[i]) tint:tint];
 [self.libraryPanel addSubview:b];[leftButtons addObject:b];
 }self.libraryActions=leftButtons;
 self.transferTitle=[self dashboardLabel:@"⇄  ODOSIELANIE / PRÍJEM ALPHA 400" size:18 color:self.cyan];
 self.transferTitle.font=[UIFont boldSystemFontOfSize:18];[self.transferPanel addSubview:self.transferTitle];
 self.profileStatus=[self dashboardLabel:@"Profil: 9600 / 7E2 / XON-XOFF / RAW .600" size:14 color:UIColor.whiteColor];
 [self.transferPanel addSubview:self.profileStatus];
 NSArray *rightLabels=@[@"▷  ODOSLAŤ PROGRAM Z FRONTY",@"⇩  ČAKAŤ NA PRÍJEM ZO STROJA",@"■  STOP PRENOS / PRÍJEM"];
 NSArray *rightSels=@[@"sendQueued",@"receiveProgram",@"stopTransfer"];
 NSMutableArray *rightButtons=[NSMutableArray array];
 for(NSInteger i=0;i<rightLabels.count;i++){
 UIColor *c=i==1?[UIColor colorWithRed:.04 green:.73 blue:.35 alpha:1]:(i==2?[UIColor colorWithRed:.88 green:.16 blue:.23 alpha:1]:self.cyan);
 UIButton *b=[self dashboardButton:rightLabels[i] action:NSSelectorFromString(rightSels[i]) tint:c];
 [self.transferPanel addSubview:b];[rightButtons addObject:b];
 }self.transferActions=rightButtons;
 self.transferStatus=[self dashboardLabel:@"Server sa ešte nekontroloval." size:14 color:UIColor.whiteColor];
 [self.transferPanel addSubview:self.transferStatus];
 self.validationStatus=[self dashboardLabel:@"KONTROLA: vyber program .600 a stlač KONTROLA G-KÓDU." size:14 color:self.cyan];
 [self.transferPanel addSubview:self.validationStatus];
 UILabel *warning=[self dashboardLabel:@"● RS-232 pripravenosť neurčuje, či CNC program prijalo. Potvrdenie príjmu zo stroja nie je dostupné." size:13 color:[UIColor colorWithRed:1 green:.75 blue:.39 alpha:1]];
 warning.tag=917;warning.numberOfLines=3;[self.transferPanel addSubview:warning];
 UIButton *settingsShortcut=[self dashboardButton:@"NASTAVENIA →" action:@selector(showSettings) tint:nil];settingsShortcut.tag=918;[self.transferPanel addSubview:settingsShortcut];
 self.editor=[[UITextView alloc] initWithFrame:CGRectZero];
 self.editor.backgroundColor=[UIColor colorWithRed:.015 green:.04 blue:.055 alpha:1];
 self.editor.textColor=UIColor.whiteColor;self.editor.font=[UIFont fontWithName:@"Menlo" size:18]?:[UIFont monospacedDigitSystemFontOfSize:18 weight:UIFontWeightRegular];
 self.editor.autocorrectionType=UITextAutocorrectionTypeNo;self.editor.autocapitalizationType=UITextAutocapitalizationTypeNone;
 self.editor.delegate=self;[self.view addSubview:self.editor];
 self.settingsPage=[UIView new];[self.view addSubview:self.settingsPage];
 UILabel *settingsTitle=[self dashboardLabel:@"NASTAVENIA ALPHALINK • RASPBERRY PI V34" size:20 color:self.cyan];
 settingsTitle.tag=903;[self.settingsPage addSubview:settingsTitle];
 UILabel *settingsHint=[self dashboardLabel:@"Adresa servera • prenos prebieha na Raspberry Pi. Zariadenie CNC nedáva spätné potvrdenie o prijatí programu." size:16 color:UIColor.whiteColor];
 settingsHint.tag=904;[self.settingsPage addSubview:settingsHint];
 self.address=[[UITextField alloc] initWithFrame:CGRectZero];
 self.address.textColor=UIColor.whiteColor;self.address.backgroundColor=self.panel;self.address.layer.cornerRadius=8;
 self.address.font=[UIFont systemFontOfSize:18];self.address.autocapitalizationType=UITextAutocapitalizationTypeNone;
 self.address.autocorrectionType=UITextAutocorrectionTypeNo;self.address.keyboardType=UIKeyboardTypeURL;
 self.address.text=[[NSUserDefaults standardUserDefaults] stringForKey:@"alphalink-url"]?:@"http://alphalink.local:8081";
 [self.settingsPage addSubview:self.address];
 UIButton *connect=[self dashboardButton:@"PRIPOJIŤ / OBNOVIŤ" action:@selector(checkConnection) tint:self.cyan];
 connect.tag=11;[self.settingsPage addSubview:connect];
 UIButton *back=[self dashboardButton:@"← SPÄŤ NA PROGRAMY" action:@selector(showPrograms) tint:nil];
 back.tag=905;[self.settingsPage addSubview:back];
 [self showPrograms];
 [self checkConnection];
}

- (void)viewDidLayoutSubviews { [super viewDidLayoutSubviews]; [self layoutContent]; }
- (void)layoutContent {
 CGFloat w=self.view.bounds.size.width,h=self.view.bounds.size.height,top=self.view.safeAreaInsets.top,bottom=self.view.safeAreaInsets.bottom;
 self.headerTitle.frame=CGRectMake(15,top+5,MIN(275,w*.30),27);
 self.piLight.frame=CGRectMake(w*.31,top+6,MIN(180,w*.19),26);
 self.machineLight.frame=CGRectMake(w*.56,top+6,w*.41,26);
 self.status.frame=CGRectMake(14,top+34,w-28,21);
 CGFloat navY=top+58,navGap=6,navWidth=(w-30-navGap*3)/4;
 for(NSInteger i=0;i<self.navButtons.count;i++){
  UIButton *btn=self.navButtons[i];btn.frame=CGRectMake(15+i*(navWidth+navGap),navY,navWidth,40);
  BOOL active=self.pageIndex==i;
  btn.backgroundColor=active?[UIColor colorWithRed:.025 green:.45 blue:.51 alpha:1]:self.panel;
  btn.layer.borderColor=(active?self.cyan:[self cyan]).CGColor;
  [btn setTitleColor:active?UIColor.whiteColor:self.cyan forState:UIControlStateNormal];
 }
 CGRect region=CGRectMake(14,navY+48,w-28,MAX(180,h-(navY+48)-bottom-7));
 self.programPage.frame=region;self.editor.frame=region;self.settingsPage.frame=region;
 CGFloat pw=region.size.width,ph=region.size.height,inter=11;
 CGFloat leftW=MAX(350,pw*.575),rightW=pw-leftW-inter;
 self.libraryPanel.frame=CGRectMake(0,0,leftW,ph);
 self.transferPanel.frame=CGRectMake(leftW+inter,0,rightW,ph);
 CGFloat m=10,innerW=leftW-2*m;
 self.libraryTitle.frame=CGRectMake(m,7,innerW-240,26);
 self.uploadButton.frame=CGRectMake(leftW-232,6,222,33);
 CGFloat tableY=46,actionsRowH=38,actionsGap=6;
 CGFloat tableH=MAX(130,ph-260);
 self.table.frame=CGRectMake(m,tableY,innerW,tableH);
 CGFloat queueY=tableY+tableH+5;
 self.queueStatus.frame=CGRectMake(m,queueY,innerW-115,33);
 self.queueClearButton.frame=CGRectMake(leftW-116,queueY+2,106,28);
 self.selectedStatus.frame=CGRectMake(m,queueY+39,innerW,29);
 self.progressBar.frame=CGRectMake(m+1,queueY+76,innerW-2,11);
 self.progressStatus.frame=CGRectMake(m,queueY+91,innerW,20);
 CGFloat buttonsY=queueY+117,cellW=(innerW-12)/3;
 for(NSInteger i=0;i<self.libraryActions.count;i++){
  NSInteger row=i/3,col=i%3;
  UIButton *b=self.libraryActions[i];b.frame=CGRectMake(m+col*(cellW+6),buttonsY+row*(actionsRowH+actionsGap),cellW,actionsRowH);
 }
 CGFloat rW=rightW-2*m;
 self.transferTitle.frame=CGRectMake(m,7,rW,30);
 self.profileStatus.frame=CGRectMake(m,43,rW,39);
 for(NSInteger i=0;i<self.transferActions.count;i++){
  UIButton *b=self.transferActions[i];b.frame=CGRectMake(m,90+i*56,rW,47);
 }
 self.transferStatus.frame=CGRectMake(m,266,rW,65);
 self.validationStatus.frame=CGRectMake(m,341,rW,MAX(62,MIN(112,ph*.17)));
 UIView *warning=[self.transferPanel viewWithTag:917];
 warning.frame=CGRectMake(m,462,rW,69);
 UIView *settingsShortcut=[self.transferPanel viewWithTag:918];
 settingsShortcut.frame=CGRectMake(MAX(m,rightW-166),MIN(ph-48,542),MIN(155,rW),37);
 CGFloat settingsW=MIN(690,pw-36),sx=(pw-settingsW)*.5;
 [self.settingsPage viewWithTag:903].frame=CGRectMake(sx,23,settingsW,40);
 [self.settingsPage viewWithTag:904].frame=CGRectMake(sx,76,settingsW,71);
 self.address.frame=CGRectMake(sx,160,settingsW-190,49);
 [self.settingsPage viewWithTag:11].frame=CGRectMake(sx+settingsW-182,160,182,49);
 [self.settingsPage viewWithTag:905].frame=CGRectMake(sx,235,settingsW,45);
}
- (void)navigate:(UIButton *)sender {
 NSInteger tab=sender.tag-810;
 if(tab==0){
  if(self.machineMode!=2 || ![self.connectedBase isEqualToString:[self base]]) {
   [self alert:@"Editor obrábacích operácií vyžaduje pripojený AlphaLink V34. Najprv pripoj Raspberry Pi."];
   return;
  }
  // The real geometry/operations/G-code/projects editor belongs in "01 EDITÁCIA".
  self.pageIndex=0;[self layoutContent];
  CNCTurningController *turning=[[CNCTurningController alloc] initWithBaseURL:[self base]];
  turning.modalPresentationStyle=UIModalPresentationFullScreen;
  [self presentViewController:turning animated:YES completion:^{
   self.pageIndex=2;[self layoutContent];
  }];
  return;
 }
 if(tab==1){
  // Keep a lightweight raw .600 text editor for programs opened from the library.
  self.tabs.selectedSegmentIndex=1;[self updateTabs];
 } else if(tab==2)[self showPrograms];
 else [self showSettings];
 [self layoutContent];
}
- (void)showPrograms {
 self.pageIndex=2;self.tabs.selectedSegmentIndex=0;[self updateTabs];
}
- (void)showSettings {
 self.pageIndex=3;self.programPage.hidden=YES;self.editor.hidden=YES;self.settingsPage.hidden=NO;[self layoutContent];
}
- (void)updateTabs {
 if(self.tabs.selectedSegmentIndex==2){
  self.tabs.selectedSegmentIndex=0;[self showPrograms];return;
 }
 BOOL edit=self.tabs.selectedSegmentIndex==1;
 self.pageIndex=edit?1:2;
 self.programPage.hidden=edit;self.editor.hidden=!edit;self.settingsPage.hidden=YES;
 [self layoutContent];
}

- (void)alert:(NSString *)message { UIAlertController *a=[UIAlertController alertControllerWithTitle:@"CNC MyLink" message:message preferredStyle:UIAlertControllerStyleAlert]; [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]]; [self presentViewController:a animated:YES completion:nil]; }
- (NSString *)base { NSString *v=[self.address.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]; if(v.length && [v rangeOfString:@"://"].location==NSNotFound) v=[@"http://" stringByAppendingString:v]; while([v hasSuffix:@"/"])v=[v substringToIndex:v.length-1]; return v; }
- (void)request:(NSString *)method path:(NSString *)path body:(NSDictionary *)body done:(void (^)(NSDictionary *,NSError *))done {
 NSString *base=[self base]; NSURLComponents *parts=[NSURLComponents componentsWithString:base];
 if (!parts || ![@[@"http",@"https"] containsObject:parts.scheme] || !parts.host.length || parts.user || parts.password || parts.query || parts.fragment || (parts.path.length && ![parts.path isEqualToString:@"/"])) { done(nil,[NSError errorWithDomain:@"CNCMyLink" code:1 userInfo:@{NSLocalizedDescriptionKey:@"Neplatná adresa. Príklad: http://192.168.0.169:8080"}]); return; }
 NSURL *url=[NSURL URLWithString:[base stringByAppendingString:path]]; if(!url){ done(nil,[NSError errorWithDomain:@"CNCMyLink" code:2 userInfo:@{NSLocalizedDescriptionKey:@"Neplatná adresa Raspberry Pi"}]); return; }
 NSMutableURLRequest *req=[NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15]; req.HTTPMethod=method;
 if(body){ req.HTTPBody=[NSJSONSerialization dataWithJSONObject:body options:0 error:nil]; [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"]; }
 [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data,NSURLResponse *resp,NSError *err){
  NSDictionary *json=nil; if(data.length){ id val=[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]; if([val isKindOfClass:NSDictionary.class]) json=val; }
  NSHTTPURLResponse *http=(NSHTTPURLResponse *)resp; if(!err && (![resp isKindOfClass:NSHTTPURLResponse.class] || http.statusCode<200 || http.statusCode>=300)) err=[NSError errorWithDomain:@"HTTP" code:http.statusCode userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"HTTP %ld",(long)http.statusCode]}];
  dispatch_async(dispatch_get_main_queue(),^{ done(json,err); });
 }] resume];
}
- (NSString *)networkExplanation:(NSError *)e {
 if(!e) return @"Server nevrátil očakávané údaje.";
 if([e.domain isEqualToString:NSURLErrorDomain]) {
   if(e.code==NSURLErrorCannotFindHost) return @"Názov hostiteľa sa nepodarilo nájsť (DNS/mDNS). Skús IP adresu Raspberry Pi namiesto .local.";
   if(e.code==NSURLErrorCannotConnectToHost) return @"Hostiteľ odmietol spojenie. Raspberry Pi môže byť vypnuté, služba nebeží alebo je nesprávny port.";
   if(e.code==NSURLErrorTimedOut) return @"Časový limit. Skontroluj, či je iPad v rovnakej Wi-Fi/LAN sieti ako Raspberry Pi a či IP adresa stále platí.";
   if(e.code==NSURLErrorNotConnectedToInternet || e.code==NSURLErrorNetworkConnectionLost) return @"Sieťové pripojenie nie je dostupné. Skontroluj Wi-Fi.";
   if(e.code==NSURLErrorAppTransportSecurityRequiresSecureConnection) return @"iOS zablokoval HTTP spojenie (ATS).";
 }
 if([e.domain isEqualToString:@"HTTP"]) return [NSString stringWithFormat:@"HTTP %ld: server odpovedal, ale požadovanú cestu odmietol.",(long)e.code];
 return e.localizedDescription?:@"Spojenie sa nepodarilo.";
}
- (void)failure:(NSDictionary *)json error:(NSError *)error {
 NSString *serverError=[json[@"error"] isKindOfClass:NSString.class]?json[@"error"]:nil;
 NSString *explanation=serverError?:[self networkExplanation:error];
 NSString *details=[NSString stringWithFormat:@"Adresa: %@\n%@\n%@\nSkontroluj zapnutie Raspberry Pi, jeho aktuálnu IP adresu a spoločnú lokálnu sieť.",[self base],explanation,error?[NSString stringWithFormat:@"Chyba: %@ (%ld)",error.domain,(long)error.code]:@"Odpoveď nezodpovedá NUM1040 API."];
 [self alert:details];
}
- (BOOL)isReady {
 if(self.machineMode==0 || ![self.connectedBase isEqualToString:[self base]]) {
  [self alert:@"Najprv stlač PRIPOJIŤ, aby sa overil typ servera. Po zmene adresy je potrebné nové pripojenie."];
  return NO;
 }
 return YES;
}
- (void)applyMode:(NSInteger)mode info:(NSDictionary *)info {
 self.machineMode=mode;
 self.connectedBase=[self base];
 self.selected=nil; self.editorOriginal=nil; self.editor.text=@""; self.dirty=NO;
 [self.files removeAllObjects]; [self.table reloadData];
 UIButton *send=(UIButton *)[self.view viewWithTag:103];
 UIButton *receive=(UIButton *)[self.view viewWithTag:104];
 [send setTitle:(mode==2?@"DO ALPHA":@"DO NUM") forState:UIControlStateNormal];
 [receive setTitle:(mode==2?@"Z ALPHA":@"Z NUM") forState:UIControlStateNormal];
 if(mode==1) {
  self.status.text=[NSString stringWithFormat:@"NUM 1040 • PI ONLINE • stroj %@",[info[@"connected"] boolValue]?@"PRIPOJENÝ":@"ODPOJENÝ"];
 } else {
  self.status.text=@"ALPHALINK • server ONLINE • Harrison Alpha 400";
 }
 [self updateConnectionPanel:info];
 [self refreshFiles];
}
- (void)checkAlphaLinkAfterNUM:(NSError *)numError {
 self.status.text=@"Kontrolujem AlphaLink API...";
 [self request:@"GET" path:@"/api/status" body:nil done:^(NSDictionary *j,NSError *e){
  BOOL alpha=(!e && [j isKindOfClass:NSDictionary.class] &&
    (j[@"transfer"] || j[@"serial_port"] || j[@"program_count"] || j[@"ports"]));
  if(alpha) { [self applyMode:2 info:j]; return; }
  self.machineMode=0; self.connectedBase=nil;
  if(e && ![e.domain isEqualToString:@"HTTP"]){self.status.text=@"SERVER NEDOSTUPNÝ";[self failure:j error:e];return;}
  self.status.text=@"SERVER ONLINE • neznáme API";
  [self alert:[NSString stringWithFormat:@"Server %@ odpovedá, ale nepodarilo sa potvrdiť API NUM1040 ani AlphaLink.\nNUM /api/info: %@.\nAlphaLink /api/status: %@.\nPrenos do CNC je z bezpečnostných dôvodov zablokovaný.",[self base],[self networkExplanation:numError],[self networkExplanation:e]]];
 }];
}
- (void)checkConnection {
 if(self.dirty){[self alert:@"V editore máš neuložené zmeny. Najprv ich ulož."];return;}
 self.address.text=[self base];[self.view endEditing:YES];
 [[NSUserDefaults standardUserDefaults] setObject:[self base] forKey:@"alphalink-url"];
 self.machineMode=0;self.connectedBase=nil;
 self.status.text=@"Pripájam AlphaLink / Harrison Alpha 400...";
 [self request:@"GET" path:@"/api/status" body:nil done:^(NSDictionary *j,NSError *e){
  if(e){self.status.text=@"ALPHALINK: OFFLINE";[self setPiOnline:NO];[self failure:j error:e];return;}
  BOOL valid=[j isKindOfClass:NSDictionary.class]&&(j[@"transfer"]||j[@"serial_port"]||j[@"program_count"]||j[@"ports"]);
  if(!valid){self.status.text=@"Server odpovedá, ale nie je AlphaLink";[self setPiOnline:NO];[self alert:@"Server nemá očakávané AlphaLink API /api/status. Skontroluj port 8081."];return;}
  [self applyMode:2 info:j];
 }];
}
- (void)refreshFiles {
 if(![self isReady])return;
 NSInteger mode=self.machineMode;
 [self request:@"GET" path:@"/api/files" body:nil done:^(NSDictionary *j,NSError *e){
  if(e||![j isKindOfClass:NSDictionary.class]){[self failure:j error:e];return;}
  NSArray *incoming=[j[@"files"] isKindOfClass:NSArray.class]?j[@"files"]:@[];
  NSMutableArray *clean=[NSMutableArray array];
  for(id item in incoming) {
   if(![item isKindOfClass:NSDictionary.class])continue;
   NSString *name=[item[@"name"] isKindOfClass:NSString.class]?item[@"name"]:@"";
   if(name.length && (mode!=2||[[name lowercaseString] hasSuffix:@".600"]))[clean addObject:item];
  }
  self.files=clean;
  if(self.selected.length) {
   BOOL exists=NO;for(NSDictionary *f in clean)if([f[@"name"] isEqualToString:self.selected]){exists=YES;break;}
   if(!exists){self.selected=nil;self.editorOriginal=nil;}
  }
  [self updateSelectedStatus];
  [self.table reloadData];
  self.status.text=[NSString stringWithFormat:@"ALPHALINK • %lu programov na Raspberry Pi",(unsigned long)clean.count];
 }];
 if(mode==2)[self fetchTransferStatus];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {return 1;}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {return self.files.count;}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)p {
 UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"program-one-line"];
 if(!cell)cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"program-one-line"];
 NSDictionary *f=self.files[p.row];
 NSString *name=[f[@"name"] isKindOfClass:NSString.class]?f[@"name"]:@"?";
 NSString *when=[f[@"modified"] isKindOfClass:NSString.class]?f[@"modified"]:@"";
 id size=f[@"size"]?:@0;
 NSString *metadata=when.length?[NSString stringWithFormat:@"   %@  •  %@ B",when,size]:[NSString stringWithFormat:@"   %@ B",size];
 NSMutableAttributedString *line=[[NSMutableAttributedString alloc] initWithString:name
  attributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:16],NSForegroundColorAttributeName:UIColor.whiteColor}];
 [line appendAttributedString:[[NSAttributedString alloc] initWithString:metadata attributes:
  @{NSFontAttributeName:[UIFont systemFontOfSize:13],NSForegroundColorAttributeName:[UIColor colorWithWhite:.75 alpha:1]}]];
 cell.textLabel.attributedText=line;
 cell.textLabel.numberOfLines=1;cell.textLabel.adjustsFontSizeToFitWidth=YES;cell.textLabel.minimumScaleFactor=.75;
 BOOL selected=[name isEqualToString:self.selected];
 cell.backgroundColor=selected?[UIColor colorWithRed:.024 green:.32 blue:.33 alpha:1]:[UIColor colorWithRed:.018 green:.085 blue:.11 alpha:1];
 cell.accessoryType=selected?UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;
 cell.tintColor=self.cyan;return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)p {
 self.selected=self.files[p.row][@"name"];
 [self updateSelectedStatus];[self.table reloadData];
}
- (NSString *)encodedName {
 NSMutableCharacterSet *safe=[[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
 [safe removeCharactersInString:@"&=+#?/"];
 return [self.selected stringByAddingPercentEncodingWithAllowedCharacters:safe];
}
- (void)updateSelectedStatus {
 self.selectedStatus.text=[NSString stringWithFormat:@"Vybraný v knižnici: %@",self.selected.length?self.selected:@"žiadny"];
}


- (void)setPiOnline:(BOOL)online {
 self.piLight.text=online?@"● PI PRIPOJENÉ":@"● PI ODPOJENÉ";
 self.piLight.textColor=online?[UIColor colorWithRed:.25 green:1 blue:.53 alpha:1]:[UIColor colorWithRed:1 green:.47 blue:.35 alpha:1];
 self.machineLight.text=@"● CNC PRÍJEM NEOVERENÝ";
 self.machineLight.textColor=[UIColor colorWithRed:1 green:.74 blue:.29 alpha:1];
}
- (void)updateConnectionPanel:(NSDictionary *)statusInfo {
 [self setPiOnline:self.machineMode==2];
 NSString *profile=[statusInfo[@"profile"] isKindOfClass:NSString.class]?statusInfo[@"profile"]:@"9600 / EVEN / 7 / 2 / XON-XOFF / CAM RAW";
 NSString *port=[statusInfo[@"serial_port"] isKindOfClass:NSString.class]?statusInfo[@"serial_port"]:@"neznámy";
 self.profileStatus.text=[NSString stringWithFormat:@"Profil: %@\nPort: %@",profile,port];
 NSDictionary *transfer=[statusInfo[@"transfer"] isKindOfClass:NSDictionary.class]?statusInfo[@"transfer"]:nil;
 NSDictionary *queue=[statusInfo[@"queue"] isKindOfClass:NSDictionary.class]?statusInfo[@"queue"]:nil;
 if(transfer)[self updateTransferPanel:transfer queue:queue];
}
- (void)updateTransferPanel:(NSDictionary *)transfer queue:(NSDictionary *)queue {
 if(![transfer isKindOfClass:NSDictionary.class])return;
 NSInteger sent=MAX(0,[transfer[@"sent"] respondsToSelector:@selector(integerValue)]?[transfer[@"sent"] integerValue]:0);
 NSInteger total=MAX(0,[transfer[@"total"] respondsToSelector:@selector(integerValue)]?[transfer[@"total"] integerValue]:0);
 NSInteger percent=MAX(0,MIN(100,[transfer[@"progress"] respondsToSelector:@selector(integerValue)]?[transfer[@"progress"] integerValue]:0));
 // Prefer actual transferred byte count so the bar fills in step with the data.
 if(total>0)percent=MAX(0,MIN(100,(NSInteger)llround(100.0*(double)sent/(double)total)));
 BOOL sending=[transfer[@"sending"] boolValue],receiving=[transfer[@"receiving"] boolValue];
 self.transferBusy=sending||receiving;
 [self.progressBar setProgress:(float)percent/100.f animated:YES];
 NSInteger rest=MAX(0,total-sent);
 self.progressStatus.text=[NSString stringWithFormat:@"%ld / %ld B • %ld %% • zostáva %ld B",(long)sent,(long)total,(long)percent,(long)rest];
 NSString *msg=[transfer[@"message"] isKindOfClass:NSString.class]?transfer[@"message"]:@"";
 NSString *filename=[transfer[@"file"] isKindOfClass:NSString.class]?transfer[@"file"]:@"";
 NSString *phase=sending?@"ODOSIELANIE":(receiving?@"PRÍJEM":@"IDLE");
 self.transferStatus.text=[NSString stringWithFormat:@"%@ • %@\n%@",phase,filename,msg.length?msg:@"Bez aktívneho prenosu."];
 BOOL error=!self.transferBusy && [transfer[@"finished"] isKindOfClass:NSString.class] && ![transfer[@"ok"] boolValue];
 self.transferStatus.textColor=error?[UIColor colorWithRed:1 green:.43 blue:.39 alpha:1]:(self.transferBusy?[UIColor colorWithRed:.95 green:.75 blue:.34 alpha:1]:UIColor.whiteColor);
 NSString *queued=[queue[@"name"] isKindOfClass:NSString.class]?queue[@"name"]:@"";
 self.queuedName=queued.length?queued:nil;
 self.queueStatus.text=queued.length?[NSString stringWithFormat:@"FRONTA • %@",queued]:@"FRONTA NA ODOSLANIE • prázdna";
 self.queueClearButton.enabled=queued.length>0 && !self.transferBusy;
}
- (void)fetchTransferStatus {
 if(self.machineMode!=2 || ![self.connectedBase isEqualToString:[self base]])return;
 [self request:@"GET" path:@"/api/transfer/status" body:nil done:^(NSDictionary *j,NSError *e){
  if(e){[self setPiOnline:NO];self.transferStatus.text=@"Raspberry Pi neodpovedá.";return;}
  [self setPiOnline:YES];
  [self updateTransferPanel:j[@"transfer"] queue:j[@"queue"]];
 }];
}
- (void)uploadToPi {
 if(![self isReady]||self.transferBusy)return;
 UIDocumentPickerViewController *picker=[[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.data",@"public.item"] inMode:UIDocumentPickerModeImport];
 picker.delegate=self;picker.modalPresentationStyle=UIModalPresentationFormSheet;
 [self presentViewController:picker animated:YES completion:nil];
}
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
 NSURL *file=urls.firstObject;
 if(!file)return;
 NSString *name=file.lastPathComponent;
 if(![[name lowercaseString] hasSuffix:@".600"]){[self alert:@"Vyber súbor s príponou .600. ISO .nc vyžaduje samostatný režim READ."];return;}
 NSError *readError=nil;NSData *payload=[NSData dataWithContentsOfURL:file options:0 error:&readError];
 if(!payload || readError){[self alert:@"Nepodarilo sa prečítať vybraný súbor iPadu."];return;}
 if(payload.length==0 || payload.length>16*1024*1024){[self alert:@"Súbor je prázdny alebo prekračuje limit 16 MB."];return;}
 BOOL collision=NO;for(NSDictionary *row in self.files)if([row[@"name"] isEqualToString:name]){collision=YES;break;}
 if(collision){
  UIAlertController *dialog=[UIAlertController alertControllerWithTitle:@"Existujúci súbor na Raspberry Pi" message:[NSString stringWithFormat:@"%@ už existuje. Nahratie ho nahradí. Pred prepísaním zálohuj pôvodný súbor.",name] preferredStyle:UIAlertControllerStyleAlert];
  [dialog addAction:[UIAlertAction actionWithTitle:@"ZRUŠIŤ" style:UIAlertActionStyleCancel handler:nil]];
  [dialog addAction:[UIAlertAction actionWithTitle:@"NAHRADIŤ" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a){[self uploadData:payload name:name];}]];
  [self presentViewController:dialog animated:YES completion:nil];
 } else [self uploadData:payload name:name];
}
- (void)uploadData:(NSData *)payload name:(NSString *)name {
 if(![self isReady]||self.transferBusy)return;
 NSString *preIssue=[self camRawError:payload filename:name program:NULL];
 if(preIssue){[self alert:[NSString stringWithFormat:@"Súbor .600 sa neodošle na Raspberry Pi: %@",preIssue]];return;}
 NSURL *url=[NSURL URLWithString:[[self base] stringByAppendingString:@"/api/upload"]];
 NSMutableURLRequest *req=[NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:45];
 req.HTTPMethod=@"POST";req.HTTPBody=payload;
 [req setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
 NSString *encoded=[name stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
 [req setValue:encoded forHTTPHeaderField:@"X-Filename"];
 self.status.text=[NSString stringWithFormat:@"Nahrávam %@ na Raspberry Pi...",name];
 [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data,NSURLResponse *response,NSError *e){
  id responseObj=data.length?[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]:nil;
  NSDictionary *json=[responseObj isKindOfClass:NSDictionary.class]?responseObj:nil;
  NSInteger code=[response isKindOfClass:NSHTTPURLResponse.class]?((NSHTTPURLResponse *)response).statusCode:0;
  dispatch_async(dispatch_get_main_queue(),^{
   if(e || code<200 || code>=300 || ![json[@"stored"] boolValue]){
    [self alert:[NSString stringWithFormat:@"Nahratie zlyhalo: %@",json[@"error"]?:e.localizedDescription?:@"neznáma chyba"]];
    return;
   }
   NSDictionary *valid=[json[@"validation"] isKindOfClass:NSDictionary.class]?json[@"validation"]:nil;
   self.status.text=[NSString stringWithFormat:@"%@ • %lu B uložených do Pi",name,(unsigned long)payload.length];
   self.selected=name;[self updateSelectedStatus];[self refreshFiles];
   NSString *check=[valid[@"valid"] boolValue]?@"Prešiel formálnou kontrolou.":@"NEPREŠIEL formálnou kontrolou; neposielaj ho do CNC.";
   [self alert:[NSString stringWithFormat:@"%@\n%@",name,check]];
  });
 }] resume];
}
- (void)deleteFromPi {
 if(![self isReady]||self.transferBusy)return;
 if(!self.selected.length){[self alert:@"Najprv vyber súbor .600 z knižnice."];return;}
 NSString *name=[self.selected copy];
 UIAlertController *dialog=[UIAlertController alertControllerWithTitle:@"Vymazať súbor z Raspberry Pi?"
 message:[NSString stringWithFormat:@"Vymazať iba %@ z Raspberry Pi? Obsah CNC stroja sa nemení. Tento krok nemožno vrátiť bez zálohy.",name] preferredStyle:UIAlertControllerStyleAlert];
 [dialog addAction:[UIAlertAction actionWithTitle:@"ZRUŠIŤ" style:UIAlertActionStyleCancel handler:nil]];
 [dialog addAction:[UIAlertAction actionWithTitle:@"VYMAZAŤ Z PI" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
  NSString *url=[@"/api/delete?name=" stringByAppendingString:[self encodedName]];
  [self request:@"POST" path:url body:nil done:^(NSDictionary *j,NSError *e){
   if(e||![j[@"ok"] boolValue]){[self failure:j error:e];return;}
   self.selected=nil;self.queuedName=nil;[self refreshFiles];
  }];
 }]];
 [self presentViewController:dialog animated:YES completion:nil];
}
- (void)validateSelected {
 if(![self isReady] || !self.selected.length){[self alert:@"Najprv vyber program .600 v knižnici."];return;}
 NSString *name=[self.selected copy];
 self.validationStatus.text=@"Prebieha hĺbková kontrola RAW .600...";
 [self preflightCAM:name done:^(NSString *digest,NSString *number,NSString *error){
  if(error){
   self.validationStatus.text=[NSString stringWithFormat:@"ZABLOKOVANÉ: %@",error];
   self.validationStatus.textColor=UIColor.redColor;
   [self alert:[NSString stringWithFormat:@"Súbor %@ nespĺňa kontrolný profil pre skúšobný prenos.\n\n%@\n\nDo CNC sa nič neodoslalo.",name,error]];
   return;
  }
  self.validationStatus.text=[NSString stringWithFormat:@"CAM RAW OK • %@ • SHA-256 overené",number];
  self.validationStatus.textColor=[UIColor colorWithRed:.2 green:.9 blue:.5 alpha:1];
  [self alert:[NSString stringWithFormat:
   @"%@ (%@)\n7-bit ASCII • CRLF • M16 • %%\nCAM G00/G01 • RAW SHA-256: %@\n\nOverená je štruktúra programu, NIE dostupná pamäť CNC, obsadenie čísla ani bezpečnosť pohybov nástroja.",
   name,number,digest]];
 }];
}
- (void)prepareQueue {
 if(![self isReady]||self.transferBusy)return;
 if(!self.selected.length||self.dirty){[self alert:@"Vyber uložený .600 súbor bez neuložených zmien."];return;}
 NSString *name=[self.selected copy];
 [self preflightCAM:name done:^(NSString *digest,NSString *number,NSString *error){
  if(error){[self alert:[NSString stringWithFormat:@"Fronta sa nepripravila.\n%@",error]];return;}
  [self stageCAM:name digest:digest number:number andSend:NO];
 }];
}
- (void)clearQueue {
 if(![self isReady]||self.transferBusy)return;
 UIAlertController *dialog=[UIAlertController alertControllerWithTitle:@"Vyprázdniť frontu?" message:@"Vyprázdni iba pripravený prenos. Súbory v knižnici ani v CNC nevymaže." preferredStyle:UIAlertControllerStyleAlert];
 [dialog addAction:[UIAlertAction actionWithTitle:@"ZRUŠIŤ" style:UIAlertActionStyleCancel handler:nil]];
 [dialog addAction:[UIAlertAction actionWithTitle:@"VYPRÁZDNIŤ" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a){
  [self request:@"POST" path:@"/api/queue/clear" body:@{} done:^(NSDictionary *j,NSError *e){
   if(e){[self failure:j error:e];return;}
   self.queuedName=nil;[self fetchTransferStatus];
  }];
 }]];
 [self presentViewController:dialog animated:YES completion:nil];
}
- (void)sendQueued {
 if(![self isReady]||self.transferBusy)return;
 if(!self.queuedName.length){[self alert:@"Fronta je prázdna."];return;}
 // Same exact preflight as the other send button. Never bypass by using an existing queue.
 [self sendAlphaValidated:[self.queuedName copy]];
}
- (void)openSelected {
 if(![self isReady])return;
 if(!self.selected.length){[self alert:@"Najprv vyber program zo zoznamu."];return;}
 if(self.dirty){[self alert:@"V editore sú neuložené zmeny. Najprv ich ulož."];return;}
 NSInteger mode=self.machineMode; NSString *name=self.selected;
 [self request:@"GET" path:[@"/api/file?name=" stringByAppendingString:[self encodedName]] body:nil done:^(NSDictionary *j,NSError *e){
  if(e || ![j isKindOfClass:NSDictionary.class] || (mode==1 && ![j[@"ok"] boolValue])) {[self failure:j error:e];return;}
  id raw=(mode==2?j[@"text"]:j[@"content"]);
  if(![raw isKindOfClass:NSString.class]){
   [self alert:@"Server nevrátil text programu v očakávanom formáte. Súbor sa neotvoril."];return;
  }
  self.editorOriginal=name;
  self.editor.text=(NSString *)raw; self.dirty=NO;
  self.tabs.selectedSegmentIndex=1;[self updateTabs];
  self.status.text=[NSString stringWithFormat:@"%@ • editor: %@",mode==2?@"ALPHALINK":@"NUM 1040",name];
 }];
}
- (void)textViewDidChange:(UITextView *)v { self.dirty=YES; }
- (void)saveEditor {
 if(![self isReady])return;
 if(!self.selected.length || !self.editorOriginal.length){[self alert:@"Najprv otvor program zo zoznamu."];return;}
 if(![self.selected isEqualToString:self.editorOriginal]){[self alert:@"Vybraný program sa zmenil. Znovu ho otvor, aby sa nepremenoval nesprávny súbor."];return;}
 NSInteger mode=self.machineMode;
 if(mode==2 && ![[self.selected lowercaseString] hasSuffix:@".600"]) {
  [self alert:@"AlphaLink CAM ukladá v tomto režime iba programy .600."];return;
 }
 NSDictionary *body=(mode==2?@{@"name":self.selected,@"text":self.editor.text?:@""}:@{@"name":self.selected,@"content":self.editor.text?:@"",@"overwrite":@YES});
 NSString *path=(mode==2?@"/api/save":@"/api/file/save");
 [self request:@"POST" path:path body:body done:^(NSDictionary *j,NSError *e) {
  if(e || (mode==1 && ![j[@"ok"] boolValue])) {[self failure:j error:e];return;}
  self.dirty=NO;
  self.status.text=[NSString stringWithFormat:@"%@ • program uložený",mode==2?@"ALPHALINK":@"NUM 1040"];
  [self refreshFiles];
 }];
}
// Safety gate for V34 CAM RAW .600. Parsing only: does not prove toolpath safety.
- (NSString *)camRawError:(NSData *)bytes filename:(NSString *)name program:(NSString **)program {
 if(![[name lowercaseString] hasSuffix:@".600"])return @"Na CAM RAW možno odoslať iba .600 súbory.";
 if(bytes.length<40 || bytes.length>16000)return @"Na skúšobný prenos povoľujem iba .600 súbory 40 až 16 000 B. Voľná pamäť CNC sa nedá z aplikácie zistiť.";
 const unsigned char *p=bytes.bytes;
 for(NSUInteger i=0;i<bytes.length;i++){
  unsigned char b=p[i];
  if(b>127 || b==0 || (b<32 && b!=10 && b!=13))return [NSString stringWithFormat:@"Súbor obsahuje nepovolený bajt na pozícii %lu.",(unsigned long)i];
  if(b==10 && (i==0 || p[i-1]!=13))return @"Súbor má LF bez CR. CAM RAW V34 vyžaduje čisté CRLF.";
  if(b==13 && (i+1>=bytes.length || p[i+1]!=10))return @"Súbor má CR bez LF. CAM RAW V34 vyžaduje čisté CRLF.";
 }
 if(bytes.length<2 || p[bytes.length-2]!=13 || p[bytes.length-1]!=10)return @"Súbor nemá koncové CRLF.";
 NSString *content=[[NSString alloc] initWithData:bytes encoding:NSASCIIStringEncoding];
 if(!content)return @"Súbor nie je ASCII.";
 NSArray *raw=[content componentsSeparatedByString:@"\r\n"];
 NSMutableArray *lines=[NSMutableArray array];
 for(NSString *l in raw)if(l.length)[lines addObject:l];
 if(lines.count<5)return @"Program je príliš krátky.";
 NSRegularExpression *header=[NSRegularExpression regularExpressionWithPattern:@"^O[0-9]{4}$" options:0 error:nil];
 NSString *number=lines[0];
 if([header numberOfMatchesInString:number options:0 range:NSMakeRange(0,number.length)]!=1)return @"Chýba platná hlavička O0001 (O + 4 číslice).";
 // For the first on-machine test, keep the exact user-proven single-program CAM O0001 flow.
 if(![number isEqualToString:@"O0001"])return @"Skúšobný CAM prenos povoľuje iba už odskúšané číslo O0001. Nejde o kontrolu duplicity v pamäti CNC.";
 if(![lines[1] isEqualToString:@"(AZ PS)"])return @"Chýba presná CAM hlavička (AZ PS).";
 if(![lines[lines.count-2] isEqualToString:@"M16"] || ![lines.lastObject isEqualToString:@"%"])return @"Na konci musí byť presne M16 a %.";
 NSInteger m16=0,pct=0;
 for(NSString *l in lines){if([l isEqualToString:@"M16"])m16++;if([l isEqualToString:@"%"])pct++;}
 if(m16!=1||pct!=1)return @"M16 a % sa môžu nachádzať iba raz a na konci.";
 NSRegularExpression *motion=[NSRegularExpression regularExpressionWithPattern:@"^G0[01](?: [XZF][+-]?(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+))+$" options:0 error:nil];
 NSInteger movementCount=0;
 for(NSUInteger i=2;i+2<lines.count;i++){
  NSString *line=lines[i];
  if([motion numberOfMatchesInString:line options:0 range:NSMakeRange(0,line.length)]!=1)
   return [NSString stringWithFormat:@"Nepodporovaný CAM príkaz na riadku %lu: %@",(unsigned long)i+1,line];
  NSArray *parts=[line componentsSeparatedByString:@" "];
  NSMutableSet *axis=[NSMutableSet set];BOOL displacement=NO;
  for(NSUInteger k=1;k<parts.count;k++){
   NSString *token=parts[k];
   NSString *letter=[token substringToIndex:1];
   if([axis containsObject:letter])return [NSString stringWithFormat:@"Duplicitná adresa na riadku %lu.",(unsigned long)i+1];
   [axis addObject:letter];
   double val=[[token substringFromIndex:1] doubleValue];
   if(!isfinite(val))return @"V príkaze je neplatná číselná hodnota.";
   if([letter isEqualToString:@"X"]){displacement=YES;if(val<0||val>1500)return @"X mimo bezpečnostného intervalu predbežnej kontroly."; }
   if([letter isEqualToString:@"Z"]){displacement=YES;if(val< -3000||val>100)return @"Z mimo bezpečnostného intervalu predbežnej kontroly.";}
   if([letter isEqualToString:@"F"] && (val<0.005||val>2.0))return @"Posuv F mimo povoleného rozsahu kontrolného profilu.";
  }
  if(!displacement)return [NSString stringWithFormat:@"Príkaz bez pohybu X/Z na riadku %lu.",(unsigned long)i+1];
  movementCount++;
 }
 if(movementCount<1)return @"V súbore nie sú obrábacie pohyby.";
 if(program)*program=number;
 return nil;
}
- (NSString *)camSHA256:(NSData *)bytes {
 unsigned char hash[CC_SHA256_DIGEST_LENGTH];
 CC_SHA256(bytes.bytes,(CC_LONG)bytes.length,hash);
 NSMutableString *value=[NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH*2];
 for(int i=0;i<CC_SHA256_DIGEST_LENGTH;i++)[value appendFormat:@"%02X",hash[i]];
 return value;
}
- (void)requestCAMBytes:(NSString *)name done:(void (^)(NSData *,NSError *))done {
 NSString *encoded=[name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
 NSURL *url=[NSURL URLWithString:[[self base] stringByAppendingFormat:@"/api/download?name=%@",encoded]];
 if(!url){done(nil,[NSError errorWithDomain:@"AlphaLink" code:1 userInfo:@{NSLocalizedDescriptionKey:@"Neplatná adresa servera."}]);return;}
 NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20];
 [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data,NSURLResponse *response,NSError *err){
  NSInteger code=[response isKindOfClass:NSHTTPURLResponse.class]?((NSHTTPURLResponse *)response).statusCode:0;
  if(!err && (code<200||code>=300))err=[NSError errorWithDomain:@"HTTP" code:code userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Sťahovanie RAW .600: HTTP %ld",(long)code]}];
  dispatch_async(dispatch_get_main_queue(),^{done(data,err);});
 }] resume];
}
// Read-only preflight: exact V34 profile, serial port, server file, binary SHA and strict CAM dialect.
- (void)preflightCAM:(NSString *)name done:(void (^)(NSString *digest,NSString *number,NSString *error))done {
 if(![self isReady] || self.transferBusy){done(nil,nil,@"Raspberry Pi je odpojené alebo prebieha prenos.");return;}
 NSString *base=[self base];
 [self request:@"GET" path:@"/api/status" body:nil done:^(NSDictionary *status,NSError *err){
  if(err || ![status isKindOfClass:NSDictionary.class]){done(nil,nil,@"Raspberry Pi /api/status neodpovedá.");return;}
  if(![base isEqualToString:[self base]]){done(nil,nil,@"Adresa servera sa počas kontroly zmenila.");return;}
  if(![status[@"version"] isEqualToString:@"V34"] ||
     ![status[@"profile"] isEqualToString:@"9600 / EVEN / 7 / 2 / XON-XOFF / CAM RAW"]){
   done(nil,nil,@"Nesúhlasí server V34 alebo sériový profil. Prenos blokovaný.");return;
  }
  NSString *port=[status[@"serial_port"] isKindOfClass:NSString.class]?status[@"serial_port"]:@"";
  NSArray *ports=[status[@"ports"] isKindOfClass:NSArray.class]?status[@"ports"]:@[];
  if(!port.length || ![ports containsObject:port]){
   done(nil,nil,@"Sériový port nie je dostupný v zozname Raspberry Pi.");return;
  }
  NSDictionary *transfer=[status[@"transfer"] isKindOfClass:NSDictionary.class]?status[@"transfer"]:@{};
  if([transfer[@"sending"] boolValue] || [transfer[@"receiving"] boolValue]){
   done(nil,nil,@"Sériový port je obsadený odosielaním alebo príjmom.");return;
  }
  NSString *escaped=[name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
  [self request:@"GET" path:[@"/api/file?name=" stringByAppendingString:escaped] body:nil done:^(NSDictionary *file,NSError *fileError){
   if(fileError||![file isKindOfClass:NSDictionary.class]){done(nil,nil,@"Program .600 nemožno overiť na Raspberry Pi.");return;}
   NSDictionary *v=[file[@"validation"] isKindOfClass:NSDictionary.class]?file[@"validation"]:nil;
   NSString *expected=[file[@"sha256"] isKindOfClass:NSString.class]?[file[@"sha256"] uppercaseString]:@"";
   if(![v[@"valid"] boolValue]||expected.length!=64 || ![file[@"name"] isEqualToString:name]){
    done(nil,nil,@"Kontrola programu alebo SHA-256 na Raspberry Pi zlyhala.");return;
   }
   [self requestCAMBytes:name done:^(NSData *bytes,NSError *rawError){
    if(rawError || !bytes){done(nil,nil,rawError.localizedDescription?:@"RAW dáta .600 sa nepodarilo stiahnuť.");return;}
    NSString *number=nil;
    NSString *issue=[self camRawError:bytes filename:name program:&number];
    if(issue){done(nil,nil,issue);return;}
    NSString *digest=[self camSHA256:bytes];
    if(![digest isEqualToString:expected] || bytes.length!=[file[@"size"] unsignedIntegerValue]){
     done(nil,nil,@"Súbor RAW .600 sa nezhoduje s veľkosťou alebo SHA-256 Raspberry Pi. Neodosielam.");return;
    }
    done(digest,number,nil);
   }];
  }];
 }];
}
- (void)confirmAndSendCAM:(NSString *)name digest:(NSString *)digest number:(NSString *)number {
 if(![self isReady]||self.transferBusy)return;
 NSString *msg=[NSString stringWithFormat:
  @"Program: %@ (%@)\nSHA-256 overené.\n\nRežim CAM podľa tvojho testu automaticky nahrádza predchádzajúci O0001.\n\nNa Harrison Alpha 400:\n1. Zvoľ CAM → LOAD CAM FILE (nie ISO READ).\n2. Zálohuj dôležité programy a skontroluj, že stroj nie je v cykle.\n3. Skontroluj, že riadenie je pripravené na prijímanie.\n\nSériový zápis nie je potvrdením prijatia CNC. Potvrď až po kontrole stroja.",name,number];
 UIAlertController *a=[UIAlertController alertControllerWithTitle:@"POSLEDNÁ KONTROLA PRED CNC" message:msg preferredStyle:UIAlertControllerStyleAlert];
 [a addAction:[UIAlertAction actionWithTitle:@"ZRUŠIŤ" style:UIAlertActionStyleCancel handler:nil]];
 [a addAction:[UIAlertAction actionWithTitle:@"SKONTROLOVANÉ – ODOSLAŤ" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *act){
  if(![self isReady]||self.transferBusy)return;
  NSString *escaped=[name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
  [self request:@"GET" path:[@"/api/file?name=" stringByAppendingString:escaped] body:nil done:^(NSDictionary *f,NSError *e){
   if(e || ![[f[@"sha256"] uppercaseString] isEqualToString:digest]){
    [self alert:@"Súbor sa od kontroly zmenil. Prenos nie je povolený."];return;
   }
   [self request:@"POST" path:@"/api/send" body:@{@"name":name,@"force":@NO} done:^(NSDictionary *reply,NSError *sendError){
    if(sendError||![reply[@"started"] boolValue]){[self failure:reply error:sendError];return;}
    self.status.text=[NSString stringWithFormat:@"Pi V34 odosiela %@ • prijatie CNC zatiaľ NEPOTVRDENÉ",name];
    [self pollJob];
   }];
  }];
 }]];
 [self presentViewController:a animated:YES completion:nil];
}
- (void)stageCAM:(NSString *)name digest:(NSString *)digest number:(NSString *)number andSend:(BOOL)send {
 [self request:@"POST" path:@"/api/queue/stage" body:@{@"name":name} done:^(NSDictionary *response,NSError *error){
  if(error){[self failure:response error:error];return;}
  NSDictionary *q=[response[@"queue"] isKindOfClass:NSDictionary.class]?response[@"queue"]:nil;
  if(![q[@"name"] isEqualToString:name] || ![[q[@"sha256"] uppercaseString] isEqualToString:digest]){
   [self alert:@"Fronta neobsahuje overené identické RAW bajty (SHA-256). Prenos zablokovaný."];return;
  }
  self.queuedName=name;self.queueStatus.text=[NSString stringWithFormat:@"FRONTA OVERENÁ: %@",name];
  self.status.text=[NSString stringWithFormat:@"%@ • overené na Pi, bez potvrdenia CNC",name];
  [self fetchTransferStatus];
  if(send)[self confirmAndSendCAM:name digest:digest number:number];
 }];
}

- (void)sendAlphaValidated:(NSString *)name {
 if(![self isReady]||self.transferBusy||self.dirty)return;
 self.status.text=[NSString stringWithFormat:@"BEZPEČNOSTNÁ KONTROLA • %@",name];
 [self preflightCAM:name done:^(NSString *digest,NSString *number,NSString *error){
  if(error){self.validationStatus.text=[NSString stringWithFormat:@"KONTROLA: %@",error];self.validationStatus.textColor=UIColor.redColor;
   [self alert:[NSString stringWithFormat:@"Do CNC sa nič neodoslalo.\n\n%@",error]];return;}
  self.validationStatus.text=[NSString stringWithFormat:@"OVERENÉ: %@ • SHA-256 • CAM RAW",number];
  self.validationStatus.textColor=[UIColor colorWithRed:.3 green:1 blue:.52 alpha:1];
  [self stageCAM:name digest:digest number:number andSend:YES];
 }];
}
- (void)sendSelected {
 if(![self isReady])return;
 if(!self.selected.length){[self alert:@"Vyber program na Raspberry Pi."];return;}
 if(self.dirty){[self alert:@"Neuložené zmeny v editore. Najprv ich ulož."];return;}
 NSInteger mode=self.machineMode; NSString *name=[self.selected copy];
 if(mode==2 && ![[name lowercaseString] hasSuffix:@".600"]) {
   [self alert:@"Do AlphaLink CAM možno odoslať iba overený .600 program. ISO .nc používa iný režim READ a nie je v tejto verzii podporovaný."];return;
 }
 if(mode==2){[self sendAlphaValidated:name];return;}
 NSString *prompt=(mode==2?@"ALPHA 400: na stroji nastav CAM → LOAD CAM FILE. Pred odoslaním skontroluj program .600 a pracovné podmienky.":@"NUM 1040: priprav na stroji LOAD / IN CYC. Pred odoslaním skontroluj G-kód.");
 UIAlertController *a=[UIAlertController alertControllerWithTitle:(mode==2?@"Odoslať do Harrison Alpha 400?":@"Odoslať do NUM 1040?")
 message:[NSString stringWithFormat:@"Program: %@\n%@\nPrenos vykoná Raspberry Pi.",name,prompt] preferredStyle:UIAlertControllerStyleAlert];
 [a addAction:[UIAlertAction actionWithTitle:@"ZRUŠIŤ" style:UIAlertActionStyleCancel handler:nil]];
 [a addAction:[UIAlertAction actionWithTitle:@"ODOSLAŤ" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
   if(![self isReady] || self.machineMode!=mode || ![self.selected isEqualToString:name])return;
   if(mode==2) {
    [self sendAlphaValidated:name];
    return;
   }
   [self request:@"POST" path:@"/api/cnc/send" body:@{@"name":name} done:^(NSDictionary *j,NSError *e){
    if(e||![j[@"ok"] boolValue]){[self failure:j error:e];return;}
    self.status.text=@"NUM 1040 • prenos spustený";
    [self pollJob];
   }];
 }]];
 [self presentViewController:a animated:YES completion:nil];
}
- (void)receiveProgram {
 if(![self isReady])return;
 NSInteger mode=self.machineMode;
 UIAlertController *a=[UIAlertController alertControllerWithTitle:(mode==2?@"Prijať z Alpha 400?":@"Prijať z NUM 1040?")
 message:(mode==2?@"Na stroji priprav odoslanie programu PUNCH. Raspberry Pi bude čakať na dáta.":@"Zadaj názov pre prijatý program.")
 preferredStyle:UIAlertControllerStyleAlert];
 if(mode==1)[a addTextFieldWithConfigurationHandler:^(UITextField *f){f.placeholder=@"PRIJATY.NC";f.text=@"PRIJATY.NC";}];
 [a addAction:[UIAlertAction actionWithTitle:@"ZRUŠIŤ" style:UIAlertActionStyleCancel handler:nil]];
 [a addAction:[UIAlertAction actionWithTitle:@"PRIJAŤ" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act){
   if(![self isReady] || self.machineMode!=mode)return;
   NSString *path=(mode==2?@"/api/receive":@"/api/cnc/receive");
   NSDictionary *body=(mode==2?nil:@{@"name":a.textFields.firstObject.text?:@""});
   [self request:@"POST" path:path body:body done:^(NSDictionary *j,NSError *e) {
     if(e || (mode==1 && ![j[@"ok"] boolValue])){[self failure:j error:e];return;}
     if(mode==2 && ![j[@"started"] boolValue]){[self alert:@"Príjem zo stroja sa nepodarilo spustiť."];return;}
     self.status.text=@"Čakám na program zo stroja";
     [self pollJob];
   }];
 }]];
 [self presentViewController:a animated:YES completion:nil];
}
- (void)stopTransfer {
 if(![self isReady])return;
 NSInteger mode=self.machineMode;
 [self request:@"POST" path:(mode==2?@"/api/cancel":@"/api/cnc/stop") body:nil done:^(NSDictionary *j,NSError *e){
  if(e || (mode==1 && ![j[@"ok"] boolValue])){[self failure:j error:e];return;}
  self.status.text=@"Požiadavka STOP bola odoslaná";[self refreshFiles];
 }];
}
- (void)pollJob {
 if(![self isReady])return;
 NSInteger mode=self.machineMode;
 [self request:@"GET" path:(mode==2?@"/api/transfer/status":@"/api/job") body:nil done:^(NSDictionary *j,NSError *e){
  if(e || ![j isKindOfClass:NSDictionary.class]){[self setPiOnline:NO];[self failure:j error:e];return;}
  if(mode==2)[self setPiOnline:YES];
  NSDictionary *job=(mode==2?j[@"transfer"]:j[@"job"]);
  if(![job isKindOfClass:NSDictionary.class]){self.status.text=@"Server nevrátil stav prenosu.";return;}
  NSString *message=[job[@"message"] isKindOfClass:NSString.class]?job[@"message"]:@"";
  id progress=job[@"progress"]?:@0;
  BOOL active=NO;
  if(mode==2)active=[job[@"sending"] boolValue] || [job[@"receiving"] boolValue];
  else {
   NSString *state=[job[@"state"] isKindOfClass:NSString.class]?job[@"state"]:@"idle";
   active=[@[@"running",@"pending",@"waiting",@"receiving",@"sending"] containsObject:state.lowercaseString];
  }
  self.status.text=[NSString stringWithFormat:@"%@ • %@%% • %@",mode==2?@"ALPHALINK":@"NUM 1040",progress,message];
  if(mode==2)[self updateTransferPanel:job queue:j[@"queue"]];
  if(active)dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(1*NSEC_PER_SEC)),dispatch_get_main_queue(),^{if(self.machineMode==mode)[self pollJob];});
  else {
   if(mode==2 && [job[@"finished"] length] && ![job[@"ok"] boolValue]) {
    [self alert:[NSString stringWithFormat:@"Raspberry Pi hlási chybu sériového prenosu:\n%@",message]];
   }
   [self refreshFiles];
  }
 }];
}
@end

@interface CNCAppDelegate : UIResponder <UIApplicationDelegate>
@property(strong,nonatomic) UIWindow *window;
@end
@implementation CNCAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {self.window=[[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];self.window.rootViewController=[CNCController new];[self.window makeKeyAndVisible];return YES;}
@end
int main(int argc,char **argv){@autoreleasepool{return UIApplicationMain(argc,argv,nil,NSStringFromClass(CNCAppDelegate.class));}}
