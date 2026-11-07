#import <UIKit/UIKit.h>

@interface CNCController : UIViewController <UITableViewDataSource,UITableViewDelegate,UITextViewDelegate>
@property(nonatomic,strong) UITextField *address;
@property(nonatomic,strong) UILabel *status;
@property(nonatomic,strong) UITableView *table;
@property(nonatomic,strong) UITextView *editor;
@property(nonatomic,strong) NSMutableArray *files;
@property(nonatomic,copy) NSString *selected;
@property(nonatomic,assign) BOOL dirty;
@property(nonatomic,strong) UISegmentedControl *tabs;
@end

@implementation CNCController
- (UIColor *)bg { return [UIColor colorWithRed:.035 green:.08 blue:.11 alpha:1]; }
- (UIColor *)panel { return [UIColor colorWithRed:.07 green:.15 blue:.19 alpha:1]; }
- (UIColor *)cyan { return [UIColor colorWithRed:.12 green:.85 blue:.80 alpha:1]; }
- (UIButton *)button:(NSString *)name action:(SEL)sel {
 UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem]; [b setTitle:name forState:UIControlStateNormal]; b.backgroundColor=self.panel; [b setTitleColor:self.cyan forState:UIControlStateNormal]; b.layer.cornerRadius=9; b.titleLabel.font=[UIFont boldSystemFontOfSize:14]; [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside]; return b;
}
- (void)viewDidLoad { [super viewDidLoad]; self.view.backgroundColor=self.bg; self.files=[NSMutableArray array];
 UILabel *title=[UILabel new]; title.text=@"CNC MyLink • iPad V1"; title.textColor=self.cyan; title.font=[UIFont boldSystemFontOfSize:23]; title.frame=CGRectMake(16,22,500,30); [self.view addSubview:title];
 self.address=[[UITextField alloc] initWithFrame:CGRectZero]; self.address.textColor=[UIColor whiteColor]; self.address.backgroundColor=self.panel; self.address.layer.cornerRadius=8; self.address.font=[UIFont systemFontOfSize:15]; self.address.autocapitalizationType=UITextAutocapitalizationTypeNone; self.address.autocorrectionType=UITextAutocorrectionTypeNo; self.address.keyboardType=UIKeyboardTypeURL;
 self.address.text=[[NSUserDefaults standardUserDefaults] stringForKey:@"pi-url"]?:@"http://192.168.0.169:8080"; [self.view addSubview:self.address];
 UIButton *connect=[self button:@"PRIPOJIŤ" action:@selector(checkConnection)]; connect.tag=11; [self.view addSubview:connect];
 self.status=[UILabel new]; self.status.text=@"Odpojené • pripravené na skúšku"; self.status.font=[UIFont systemFontOfSize:13]; self.status.textColor=[UIColor colorWithWhite:.8 alpha:1]; self.status.numberOfLines=2; [self.view addSubview:self.status];
 self.tabs=[[UISegmentedControl alloc] initWithItems:@[@"PROGRAMY",@"EDITOR"]]; self.tabs.selectedSegmentIndex=0; [self.tabs addTarget:self action:@selector(updateTabs) forControlEvents:UIControlEventValueChanged]; [self.view addSubview:self.tabs];
 self.table=[[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain]; self.table.backgroundColor=self.bg; self.table.dataSource=self; self.table.delegate=self; self.table.rowHeight=54; self.table.separatorColor=self.panel; [self.view addSubview:self.table];
 self.editor=[[UITextView alloc] initWithFrame:CGRectZero]; self.editor.backgroundColor=[UIColor colorWithRed:.015 green:.04 blue:.055 alpha:1]; self.editor.textColor=[UIColor whiteColor]; self.editor.font=[UIFont fontWithName:@"Menlo" size:15]?:[UIFont monospacedDigitSystemFontOfSize:15 weight:UIFontWeightRegular]; self.editor.autocapitalizationType=UITextAutocapitalizationTypeNone; self.editor.autocorrectionType=UITextAutocorrectionTypeNo; self.editor.delegate=self; [self.view addSubview:self.editor];
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
 self.status.frame=CGRectMake(16,top+108,w-32,38); self.tabs.frame=CGRectMake(16,top+151,w-32,38);
 CGFloat footer=h-bottom-65, space=(w-32-5*8)/6.0;
 for (NSInteger i=0;i<6;i++){ UIView *b=[self.view viewWithTag:100+i]; b.frame=CGRectMake(16+i*(space+8),footer,space,50); }
 CGRect content=CGRectMake(16,top+202,w-32,MAX(100,footer-(top+210)));
 self.table.frame=content; self.editor.frame=content;
}
- (void)updateTabs { BOOL e=self.tabs.selectedSegmentIndex==1; self.table.hidden=e; self.editor.hidden=!e; }
- (void)alert:(NSString *)message { UIAlertController *a=[UIAlertController alertControllerWithTitle:@"CNC MyLink" message:message preferredStyle:UIAlertControllerStyleAlert]; [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]]; [self presentViewController:a animated:YES completion:nil]; }
- (NSString *)base { NSString *v=[self.address.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]; while([v hasSuffix:@"/"])v=[v substringToIndex:v.length-1]; return v; }
- (void)request:(NSString *)method path:(NSString *)path body:(NSDictionary *)body done:(void (^)(NSDictionary *,NSError *))done {
 NSString *base=[self base]; NSURLComponents *parts=[NSURLComponents componentsWithString:base];
 if (!parts || ![@[@"http",@"https"] containsObject:parts.scheme] || !parts.host.length || parts.user || parts.password || parts.query || parts.fragment || (parts.path.length && ![parts.path isEqualToString:@"/"])) { [self alert:@"Zadaj presnú adresu Raspberry Pi, napríklad http://192.168.0.169:8080"]; return; }
 NSURL *url=[NSURL URLWithString:[base stringByAppendingString:path]]; if(!url){ [self alert:@"Neplatná adresa Raspberry Pi"]; return; }
 NSMutableURLRequest *req=[NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15]; req.HTTPMethod=method;
 if(body){ req.HTTPBody=[NSJSONSerialization dataWithJSONObject:body options:0 error:nil]; [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"]; }
 [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data,NSURLResponse *resp,NSError *err){
  NSDictionary *json=nil; if(data.length){ id val=[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]; if([val isKindOfClass:NSDictionary.class]) json=val; }
  NSHTTPURLResponse *http=(NSHTTPURLResponse *)resp; if(!err && (![resp isKindOfClass:NSHTTPURLResponse.class] || http.statusCode<200 || http.statusCode>=300)) err=[NSError errorWithDomain:@"HTTP" code:http.statusCode userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"HTTP %ld",(long)http.statusCode]}];
  dispatch_async(dispatch_get_main_queue(),^{ done(json,err); });
 }] resume];
}
- (void)failure:(NSDictionary *)json error:(NSError *)error { NSString *s=[json[@"error"] isKindOfClass:NSString.class]?json[@"error"]:error.localizedDescription; [self alert:s?:@"Raspberry Pi neodpovedá."]; }
- (void)checkConnection { [[NSUserDefaults standardUserDefaults] setObject:[self base] forKey:@"pi-url"];
 [self request:@"GET" path:@"/api/info" body:nil done:^(NSDictionary *j,NSError *e){ if(e||![j[@"ok"] boolValue]){self.status.text=@"Raspberry Pi: OFFLINE";[self failure:j error:e];return;} self.status.text=[NSString stringWithFormat:@"Raspberry Pi ONLINE • NUM %@",[j[@"connected"] boolValue]?@"PRIPOJENÉ":@"ODPOJENÉ"];[self refreshFiles]; }]; }
- (void)refreshFiles { [self request:@"GET" path:@"/api/files" body:nil done:^(NSDictionary *j,NSError *e){if(e||![j[@"ok"] boolValue]){[self failure:j error:e];return;} NSArray *a=[j[@"files"] isKindOfClass:NSArray.class]?j[@"files"]:@[];self.files=[a mutableCopy];[self.table reloadData]; self.status.text=[NSString stringWithFormat:@"Na Raspberry Pi: %lu programov",(unsigned long)a.count];}]; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{return self.files.count;}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)p {UITableViewCell *c=[tableView dequeueReusableCellWithIdentifier:@"file"];if(!c)c=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"file"];NSDictionary *f=self.files[p.row];NSString *n=f[@"name"]?:@"?";c.textLabel.text=n;c.textLabel.textColor=[UIColor whiteColor]; c.detailTextLabel.text=[NSString stringWithFormat:@"%@ bytes",f[@"size"]?:@0];c.detailTextLabel.textColor=[UIColor lightGrayColor];c.backgroundColor=[n isEqualToString:self.selected]?[UIColor colorWithRed:.05 green:.25 blue:.29 alpha:1]:self.bg;return c;}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)p {self.selected=self.files[p.row][@"name"];[self.table reloadData];}
- (NSString *)encodedName {NSMutableCharacterSet *safe=[[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy]; [safe removeCharactersInString:@"&=+#?/"]; return [self.selected stringByAddingPercentEncodingWithAllowedCharacters:safe];}
- (void)openSelected { if(!self.selected.length){[self alert:@"Najprv vyber program zo zoznamu."];return;} if(self.dirty){[self alert:@"V editore sú neuložené zmeny. Pred otvorením ďalšieho súboru ich ulož."];return;}
 NSString *name=self.selected; [self request:@"GET" path:[@"/api/file?name=" stringByAppendingString:[self encodedName]] body:nil done:^(NSDictionary *j,NSError *e){if(e||![j[@"ok"] boolValue]){[self failure:j error:e];return;}self.selected=j[@"name"]?:name;self.editor.text=j[@"content"]?:@"";self.dirty=NO;self.tabs.selectedSegmentIndex=1;[self updateTabs];self.status.text=[@"Editor: " stringByAppendingString:self.selected];}]; }
- (void)textViewDidChange:(UITextView *)v { self.dirty=YES; }
- (void)saveEditor {if(!self.selected.length){[self alert:@"Najprv otvor program."];return;} [self request:@"POST" path:@"/api/file/save" body:@{@"name":self.selected,@"content":self.editor.text?:@"",@"overwrite":@YES} done:^(NSDictionary *j,NSError *e){if(e||![j[@"ok"] boolValue]){[self failure:j error:e];return;}self.dirty=NO;self.status.text=@"Zmeny uložené na Raspberry Pi";[self refreshFiles];}];}
- (void)sendSelected {if(!self.selected.length){[self alert:@"Vyber program na Raspberry Pi."];return;}if(self.dirty){[self alert:@"Neuložené zmeny v editore. Najprv ich ulož."];return;}
 UIAlertController *a=[UIAlertController alertControllerWithTitle:@"Odoslať do NUM 1040?" message:[NSString stringWithFormat:@"Program: %@\nNa stroji musí byť pripravený režim LOAD / IN CYC. Prenos vykoná Raspberry Pi.",self.selected] preferredStyle:UIAlertControllerStyleAlert];[a addAction:[UIAlertAction actionWithTitle:@"ZRUŠIŤ" style:UIAlertActionStyleCancel handler:nil]];[a addAction:[UIAlertAction actionWithTitle:@"ODOSLAŤ" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){[self request:@"POST" path:@"/api/cnc/send" body:@{@"name":self.selected} done:^(NSDictionary *j,NSError *e){if(e||![j[@"ok"] boolValue]){[self failure:j error:e];return;}self.status.text=@"Prenos do NUM spustený";[self pollJob];}];}]];[self presentViewController:a animated:YES completion:nil]; }
- (void)receiveProgram {UIAlertController *a=[UIAlertController alertControllerWithTitle:@"Prijať z NUM" message:@"Zadaj názov pre prijatý program." preferredStyle:UIAlertControllerStyleAlert];[a addTextFieldWithConfigurationHandler:^(UITextField *f){f.placeholder=@"PRIJATY.NC";f.text=@"PRIJATY.NC";}];[a addAction:[UIAlertAction actionWithTitle:@"ZRUŠIŤ" style:UIAlertActionStyleCancel handler:nil]];[a addAction:[UIAlertAction actionWithTitle:@"PRIJAŤ" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act){NSString *name=a.textFields.firstObject.text?:@"";[self request:@"POST" path:@"/api/cnc/receive" body:@{@"name":name} done:^(NSDictionary *j,NSError *e){if(e||![j[@"ok"] boolValue]){[self failure:j error:e];return;}self.status.text=@"Čakám na program z NUM";[self pollJob];}];}]];[self presentViewController:a animated:YES completion:nil];}
- (void)stopTransfer {[self request:@"POST" path:@"/api/cnc/stop" body:nil done:^(NSDictionary *j,NSError *e){if(e||![j[@"ok"] boolValue]){[self failure:j error:e];return;}self.status.text=@"STOP požiadavka odoslaná";}];}
- (void)pollJob { [self request:@"GET" path:@"/api/job" body:nil done:^(NSDictionary *j,NSError *e){if(e||![j[@"ok"] boolValue])return;NSDictionary *job=j[@"job"];if(![job isKindOfClass:NSDictionary.class])return; NSString *state=job[@"state"]?:@"?";self.status.text=[NSString stringWithFormat:@"%@ • %@%% • %@",state,job[@"progress"]?:@0,job[@"message"]?:@""];if([@[@"running",@"pending",@"waiting",@"receiving",@"sending"] containsObject:[state lowercaseString]])dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(1*NSEC_PER_SEC)),dispatch_get_main_queue(),^{[self pollJob];});else [self refreshFiles];}];}
@end

@interface CNCAppDelegate : UIResponder <UIApplicationDelegate>
@property(strong,nonatomic) UIWindow *window;
@end
@implementation CNCAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {self.window=[[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];self.window.rootViewController=[CNCController new];[self.window makeKeyAndVisible];return YES;}
@end
int main(int argc,char **argv){@autoreleasepool{return UIApplicationMain(argc,argv,nil,NSStringFromClass(CNCAppDelegate.class));}}
