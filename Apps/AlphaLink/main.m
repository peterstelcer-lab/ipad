#import <UIKit/UIKit.h>

@interface CNCTurningController : UIViewController
- (instancetype)initWithBaseURL:(NSString *)baseURL;
@end

@interface CNCController : UIViewController <UITableViewDataSource,UITableViewDelegate,UITextViewDelegate>
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
@end

@implementation CNCController
- (UIColor *)bg { return [UIColor colorWithRed:.035 green:.08 blue:.11 alpha:1]; }
- (UIColor *)panel { return [UIColor colorWithRed:.07 green:.15 blue:.19 alpha:1]; }
- (UIColor *)cyan { return [UIColor colorWithRed:.12 green:.85 blue:.80 alpha:1]; }
- (UIButton *)button:(NSString *)name action:(SEL)sel {
 UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem]; [b setTitle:name forState:UIControlStateNormal]; b.backgroundColor=self.panel; [b setTitleColor:self.cyan forState:UIControlStateNormal]; b.layer.cornerRadius=9; b.titleLabel.font=[UIFont boldSystemFontOfSize:16]; [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside]; return b;
}
- (void)viewDidLoad { [super viewDidLoad]; self.view.backgroundColor=self.bg; self.files=[NSMutableArray array]; self.machineMode=0;
 UILabel *title=[UILabel new]; title.text=@"AlphaLink CAM • iPad V1.5"; title.textColor=self.cyan; title.font=[UIFont boldSystemFontOfSize:23]; title.frame=CGRectMake(16,22,500,30); [self.view addSubview:title];
 self.address=[[UITextField alloc] initWithFrame:CGRectZero]; self.address.textColor=[UIColor whiteColor]; self.address.backgroundColor=self.panel; self.address.layer.cornerRadius=8; self.address.font=[UIFont systemFontOfSize:17]; self.address.autocapitalizationType=UITextAutocapitalizationTypeNone; self.address.autocorrectionType=UITextAutocorrectionTypeNo; self.address.keyboardType=UIKeyboardTypeURL;
 self.address.text=[[NSUserDefaults standardUserDefaults] stringForKey:@"alphalink-url"]?:@"http://alphalink.local:8081"; [self.view addSubview:self.address];
 UIButton *connect=[self button:@"PRIPOJIŤ" action:@selector(checkConnection)]; connect.tag=11; [self.view addSubview:connect];
 self.status=[UILabel new]; self.status.text=@"Odpojené • pripravené na skúšku"; self.status.font=[UIFont systemFontOfSize:15]; self.status.textColor=[UIColor colorWithWhite:.8 alpha:1]; self.status.numberOfLines=3; [self.view addSubview:self.status];
 self.tabs=[[UISegmentedControl alloc] initWithItems:@[@"PROGRAMY",@"G-KÓD",@"OPERÁCIE + 2D"]]; self.tabs.selectedSegmentIndex=0; [self.tabs setTitleTextAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:16]} forState:UIControlStateNormal]; [self.tabs addTarget:self action:@selector(updateTabs) forControlEvents:UIControlEventValueChanged]; [self.view addSubview:self.tabs];
 self.table=[[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain]; self.table.backgroundColor=self.bg; self.table.dataSource=self; self.table.delegate=self; self.table.rowHeight=62; self.table.separatorColor=self.panel; [self.view addSubview:self.table];
 self.editor=[[UITextView alloc] initWithFrame:CGRectZero]; self.editor.backgroundColor=[UIColor colorWithRed:.015 green:.04 blue:.055 alpha:1]; self.editor.textColor=[UIColor whiteColor]; self.editor.font=[UIFont fontWithName:@"Menlo" size:18]?:[UIFont monospacedDigitSystemFontOfSize:18 weight:UIFontWeightRegular]; self.editor.autocapitalizationType=UITextAutocapitalizationTypeNone; self.editor.autocorrectionType=UITextAutocorrectionTypeNo; self.editor.delegate=self; [self.view addSubview:self.editor];
 NSArray *labels=@[@"OBNOVIŤ",@"OTVORIŤ",@"ULOŽIŤ",@"DO NUM",@"Z NUM",@"STOP"];
 NSArray *sels=@[NSStringFromSelector(@selector(refreshFiles)),NSStringFromSelector(@selector(openSelected)),NSStringFromSelector(@selector(saveEditor)),NSStringFromSelector(@selector(sendSelected)),NSStringFromSelector(@selector(receiveProgram)),NSStringFromSelector(@selector(stopTransfer))];
 for (NSInteger i=0;i<labels.count;i++){ UIButton *b=[self button:labels[i] action:NSSelectorFromString(sels[i])]; b.tag=100+i; [self.view addSubview:b]; }
 [self updateTabs]; [self layoutContent];
}
- (void)viewDidLayoutSubviews { [super viewDidLayoutSubviews]; [self layoutContent]; }
- (void)layoutContent {
 CGFloat w=self.view.bounds.size.width,h=self.view.bounds.size.height;
 CGFloat top= self.view.safeAreaInsets.top; CGFloat bottom=self.view.safeAreaInsets.bottom;
 UIView *conn=[self.view viewWithTag:11]; self.address.frame=CGRectMake(16,top+58,w-156,42); conn.frame=CGRectMake(w-132,top+58,116,42);
 self.status.frame=CGRectMake(16,top+106,w-32,56); self.tabs.frame=CGRectMake(16,top+168,w-32,38);
 CGFloat footer=h-bottom-65, space=(w-32-5*8)/6.0;
 for (NSInteger i=0;i<6;i++){ UIView *b=[self.view viewWithTag:100+i]; b.frame=CGRectMake(16+i*(space+8),footer,space,50); }
 CGRect content=CGRectMake(16,top+213,w-32,MAX(100,footer-(top+221)));
 self.table.frame=content; self.editor.frame=content;
}
- (void)updateTabs {
 if(self.tabs.selectedSegmentIndex==2) {
  self.tabs.selectedSegmentIndex=0; self.table.hidden=NO; self.editor.hidden=YES;
  if(self.machineMode!=2 || ![self.connectedBase isEqualToString:[self base]]) {
   [self alert:@"Editor obrábacích operácií je určený pre pripojený AlphaLink / Harrison Alpha 400. Najprv stlač PRIPOJIŤ a over server."];
   return;
  }
  CNCTurningController *editor=[[CNCTurningController alloc] initWithBaseURL:[self base]];
  editor.modalPresentationStyle=UIModalPresentationFullScreen;
  [self presentViewController:editor animated:YES completion:nil];
  return;
 }
 BOOL e=self.tabs.selectedSegmentIndex==1; self.table.hidden=e; self.editor.hidden=!e;
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
  if(e){self.status.text=@"ALPHALINK: OFFLINE";[self failure:j error:e];return;}
  BOOL valid=[j isKindOfClass:NSDictionary.class]&&(j[@"transfer"]||j[@"serial_port"]||j[@"program_count"]||j[@"ports"]);
  if(!valid){self.status.text=@"Server odpovedá, ale nie je AlphaLink";[self alert:@"Server nemá očakávané AlphaLink API /api/status. Skontroluj port 8081."];return;}
  [self applyMode:2 info:j];
 }];
}
- (void)refreshFiles {
 if(![self isReady])return;
 NSInteger mode=self.machineMode;
 [self request:@"GET" path:@"/api/files" body:nil done:^(NSDictionary *j,NSError *e){
  if(e || ![j isKindOfClass:NSDictionary.class] || (mode==1 && ![j[@"ok"] boolValue])) {
    [self failure:j error:e]; return;
  }
  NSArray *a=[j[@"files"] isKindOfClass:NSArray.class]?j[@"files"]:@[];
  NSMutableArray *valid=[NSMutableArray array];
  for(id item in a) {
    if(![item isKindOfClass:NSDictionary.class])continue;
    NSString *name=[item[@"name"] isKindOfClass:NSString.class]?item[@"name"]:@"";
    if(mode==2 && ![[name lowercaseString] hasSuffix:@".600"])continue;
    if(name.length)[valid addObject:item];
  }
  self.files=valid; [self.table reloadData];
  self.status.text=[NSString stringWithFormat:@"%@ • %lu programov na Raspberry Pi",mode==2?@"ALPHALINK":@"NUM 1040",(unsigned long)valid.count];
 }];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{return self.files.count;}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)p {UITableViewCell *c=[tableView dequeueReusableCellWithIdentifier:@"file"];if(!c)c=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"file"];NSDictionary *f=self.files[p.row];NSString *n=f[@"name"]?:@"?";c.textLabel.text=n;c.textLabel.textColor=[UIColor whiteColor]; c.detailTextLabel.text=[NSString stringWithFormat:@"%@ bytes",f[@"size"]?:@0];c.detailTextLabel.textColor=[UIColor lightGrayColor];c.backgroundColor=[n isEqualToString:self.selected]?[UIColor colorWithRed:.05 green:.25 blue:.29 alpha:1]:self.bg;return c;}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)p {self.selected=self.files[p.row][@"name"];[self.table reloadData];}
- (NSString *)encodedName {NSMutableCharacterSet *safe=[[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy]; [safe removeCharactersInString:@"&=+#?/"]; return [self.selected stringByAddingPercentEncodingWithAllowedCharacters:safe];}
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
- (void)sendSelected {
 if(![self isReady])return;
 if(!self.selected.length){[self alert:@"Vyber program na Raspberry Pi."];return;}
 if(self.dirty){[self alert:@"Neuložené zmeny v editore. Najprv ich ulož."];return;}
 NSInteger mode=self.machineMode; NSString *name=[self.selected copy];
 if(mode==2 && ![[name lowercaseString] hasSuffix:@".600"]) {
   [self alert:@"Do AlphaLink CAM možno odoslať iba overený .600 program. ISO .nc používa iný režim READ a nie je v tejto verzii podporovaný."];return;
 }
 NSString *prompt=(mode==2?@"ALPHA 400: na stroji nastav CAM → LOAD CAM FILE. Pred odoslaním skontroluj program .600 a pracovné podmienky.":@"NUM 1040: priprav na stroji LOAD / IN CYC. Pred odoslaním skontroluj G-kód.");
 UIAlertController *a=[UIAlertController alertControllerWithTitle:(mode==2?@"Odoslať do Harrison Alpha 400?":@"Odoslať do NUM 1040?")
 message:[NSString stringWithFormat:@"Program: %@\n%@\nPrenos vykoná Raspberry Pi.",name,prompt] preferredStyle:UIAlertControllerStyleAlert];
 [a addAction:[UIAlertAction actionWithTitle:@"ZRUŠIŤ" style:UIAlertActionStyleCancel handler:nil]];
 [a addAction:[UIAlertAction actionWithTitle:@"ODOSLAŤ" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
   if(![self isReady] || self.machineMode!=mode || ![self.selected isEqualToString:name])return;
   NSString *path=(mode==2?@"/api/send":@"/api/cnc/send");
   NSDictionary *body=(mode==2?@{@"name":name,@"force":@NO}:@{@"name":name});
   [self request:@"POST" path:path body:body done:^(NSDictionary *j,NSError *e){
    if(e || (mode==1 && ![j[@"ok"] boolValue])) {
      if(mode==2 && [e.domain isEqualToString:@"HTTP"] && e.code==409) {
        [self alert:@"AlphaLink odmietol prenos pri validácii (HTTP 409). Oprav program v editore. Neoverený RAW prenos nie je povolený."];
      }else [self failure:j error:e];
      return;
    }
    self.status.text=[NSString stringWithFormat:@"%@ • prenos spustený",mode==2?@"ALPHALINK":@"NUM 1040"];
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
 [self request:@"GET" path:(mode==2?@"/api/status":@"/api/job") body:nil done:^(NSDictionary *j,NSError *e){
  if(e || ![j isKindOfClass:NSDictionary.class]){[self failure:j error:e];return;}
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
  if(active)dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(1*NSEC_PER_SEC)),dispatch_get_main_queue(),^{if(self.machineMode==mode)[self pollJob];});
  else [self refreshFiles];
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
