#import "Shared.h"
#import <SafariServices/SafariServices.h>
static NSString* S(id o){return (o&&o!=(id)[NSNull null])?[o description]:@"—";}
static NSString* Icon(NSString*code) {
 NSString*c=[[S(code) lowercaseString] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
 if([c containsString:@"thunder"])return @"⛈️";
 if([c containsString:@"snow"]&&[c containsString:@"rain"])return @"🌨️";
 if([c containsString:@"snow"])return @"❄️";
 if([c containsString:@"rain"]||[c containsString:@"drizzle"])return @"🌧️";
 if([c containsString:@"fog"]||[c containsString:@"mist"])return @"🌫️";
 if([c containsString:@"overcast"])return @"☁️";
 if([c containsString:@"broken"]||[c containsString:@"scattered"])return @"🌥️";
 if([c containsString:@"few"])return @"🌤️";
 if([c containsString:@"clear"])return @"☀️";
 return @"⛅️";
}
static NSString* Descr(NSString*code) {
 NSString*c=S(code);
 if([c containsString:@"thunder"])return @"Búrky";
 if([c containsString:@"snow"])return @"Sneženie";
 if([c containsString:@"rain"])return @"Dážď";
 if([c containsString:@"fog"]||[c containsString:@"mist"])return @"Hmla";
 if([c containsString:@"overcast"])return @"Zamračené";
 if([c containsString:@"broken"]||[c containsString:@"scattered"])return @"Oblačno";
 if([c containsString:@"few"])return @"Polooblačno";
 if([c containsString:@"clear"])return @"Jasno";
 return @"Premenlivé";
}
static NSString* Day(NSString*iso){
 if(iso.length<10)return iso?:@"";
 NSDateFormatter*f=[NSDateFormatter new];f.locale=[NSLocale localeWithLocaleIdentifier:@"sk_SK"];f.timeZone=[NSTimeZone timeZoneWithName:@"Europe/Bratislava"];f.dateFormat=@"yyyy-MM-dd";
 NSDate*d=[f dateFromString:[iso substringToIndex:10]];f.dateFormat=@"EEEE, d. MMM";return d?[f stringFromDate:d]:iso;
}
@interface WeatherDayCell:UITableViewCell
@property(nonatomic,strong)UILabel*sym;
@property(nonatomic,strong)UILabel*day;
@property(nonatomic,strong)UILabel*desc;
@property(nonatomic,strong)UILabel*temp;
@property(nonatomic,strong)UILabel*rain;
@end
@implementation WeatherDayCell
-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)ident{
 if((self=[super initWithStyle:style reuseIdentifier:ident])){
 self.backgroundColor=C(0x172E3B);
 _sym=L(@"☀️",48);_sym.textAlignment=NSTextAlignmentCenter;
 _day=L(@"",18);_day.font=[UIFont boldSystemFontOfSize:18];
 _desc=L(@"",15);_desc.textColor=C(0x9FC3C9);
 _temp=L(@"",22);_temp.font=[UIFont boldSystemFontOfSize:22];_temp.textAlignment=NSTextAlignmentRight;
 _rain=L(@"",13);_rain.textAlignment=NSTextAlignmentRight;_rain.textColor=C(0x40DBC3);
 for(UIView*v in @[_sym,_day,_desc,_temp,_rain]){[self.contentView addSubview:v];}
 self.selectionStyle=UITableViewCellSelectionStyleNone;
 }return self;
}
-(void)layoutSubviews{
 [super layoutSubviews];CGFloat w=self.contentView.bounds.size.width;
 _sym.frame=CGRectMake(6,9,79,78);
 _day.frame=CGRectMake(96,10,MAX(80,w-265),29);
 _desc.frame=CGRectMake(96,43,MAX(80,w-260),25);
 _temp.frame=CGRectMake(MAX(w-180,170),10,170,36);
 _rain.frame=CGRectMake(MAX(w-225,150),53,215,37);
}
@end
@interface V:UIViewController<UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate>{
 NSString*station,*city;NSArray*days,*stations;BOOL searching;
 UITableView*table;UIView*hero;UILabel*header,*cityLabel,*nowIcon,*nowTemp,*nowText,*status;
 UITextField*query;NSArray*buttons;NSUInteger token;
}
@end
@implementation V
-(void)viewDidLoad{
 [super viewDidLoad];self.view.backgroundColor=C(0x091620);
 station=[[NSUserDefaults standardUserDefaults]stringForKey:@"station"]?:@"32801";
 city=[[NSUserDefaults standardUserDefaults]stringForKey:@"city"]?:@"Žilina";
 header=L(@"SHMÚ  •  WEATHER V2",22);header.font=[UIFont boldSystemFontOfSize:22];[self.view addSubview:header];
 query=[UITextField new];query.backgroundColor=C(0x1B3442);query.textColor=UIColor.whiteColor;query.layer.cornerRadius=9;
 query.leftView=[[UIView alloc]initWithFrame:CGRectMake(0,0,12,42)];query.leftViewMode=UITextFieldViewModeAlways;
 query.attributedPlaceholder=[[NSAttributedString alloc]initWithString:@"Vyhľadať mesto..." attributes:@{NSForegroundColorAttributeName:C(0x97AFBA)}];
 query.returnKeyType=UIReturnKeySearch;query.delegate=self;query.autocorrectionType=UITextAutocorrectionTypeNo;[self.view addSubview:query];
 NSArray*names=@[@"⌕  HĽADAŤ",@"↻  OBNOVIŤ",@"10 DNÍ ▸"];NSMutableArray*arr=[NSMutableArray array];
 for(int i=0;i<3;i++){UIButton*b=B(names[i],self,@selector(tap:),i);[self.view addSubview:b];[arr addObject:b];}buttons=arr;
 hero=[UIView new];hero.backgroundColor=C(0x153442);hero.layer.cornerRadius=14;[self.view addSubview:hero];
 cityLabel=L(city,24);cityLabel.font=[UIFont boldSystemFontOfSize:24];[hero addSubview:cityLabel];
 nowIcon=L(@"⛅️",68);nowIcon.textAlignment=NSTextAlignmentCenter;[hero addSubview:nowIcon];
 nowTemp=L(@"— °C",34);nowTemp.font=[UIFont boldSystemFontOfSize:36];nowTemp.textColor=C(0x42D5BE);[hero addSubview:nowTemp];
 nowText=L(@"Predpoveď ALADIN pre teraz",14);nowText.textColor=C(0xC4D7DD);[hero addSubview:nowText];
 table=[[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStylePlain];table.dataSource=self;table.delegate=self;table.backgroundColor=UIColor.clearColor;table.rowHeight=103;table.separatorColor=C(0x0C202C);table.layer.cornerRadius=10;table.tableFooterView=[UIView new];[self.view addSubview:table];
 status=L(@"Údaje z modelu SHMÚ ALADIN (nie živé meranie)",12);status.textColor=C(0x9FC3C9);[self.view addSubview:status];
 NSData*cache=[[NSUserDefaults standardUserDefaults]objectForKey:[@"cache" stringByAppendingString:station]];
 if(cache){id x=[NSJSONSerialization JSONObjectWithData:cache options:0 error:nil];if([x isKindOfClass:[NSArray class]])days=x;}
 [self refresh];
}
-(void)viewDidLayoutSubviews{
 [super viewDidLayoutSubviews];CGFloat w=self.view.bounds.size.width,h=self.view.bounds.size.height,t=self.view.safeAreaInsets.top,p=14;
 header.frame=CGRectMake(p,t+5,w-2*p,32);
 query.frame=CGRectMake(p,t+42,w-2*p,41);
 CGFloat sp=8,bw=(w-2*p-2*sp)/3;
 for(int i=0;i<3;i++)((UIButton*)buttons[i]).frame=CGRectMake(p+i*(bw+sp),t+91,bw,39);
 CGFloat hh=(h<680?132:157);
 hero.frame=CGRectMake(p,t+139,w-2*p,hh);
 cityLabel.frame=CGRectMake(18,9,hero.bounds.size.width-36,34);
 nowIcon.frame=CGRectMake(12,45,87,hh-49);
 nowTemp.frame=CGRectMake(115,48,MIN(200,hero.bounds.size.width-125),50);
 nowText.frame=CGRectMake(116,102,MAX(80,hero.bounds.size.width-135),38);
 CGFloat rowY=CGRectGetMaxY(hero.frame)+12;
 status.frame=CGRectMake(p,h-self.view.safeAreaInsets.bottom-33,w-2*p,27);
 table.frame=CGRectMake(p,rowY,w-2*p,MAX(135,CGRectGetMinY(status.frame)-rowY-8));
}
-(void)req:(NSString*)suffix done:(void(^)(NSDictionary*,NSError*))cb {
 NSString*url=[@"https://shmu.bmikuska.com/api/v1" stringByAppendingString:suffix];
 NSURLSessionDataTask*task=[NSURLSession.sharedSession dataTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSData*d,NSURLResponse*r,NSError*e){
  NSError*x=e;NSDictionary*j=nil;
  if(!x&&[(NSHTTPURLResponse*)r statusCode]>=400)x=[NSError errorWithDomain:@"SHMU" code:((NSHTTPURLResponse*)r).statusCode userInfo:@{NSLocalizedDescriptionKey:@"Server nevrátil predpoveď."}];
  if(!x&&d){id o=[NSJSONSerialization JSONObjectWithData:d options:0 error:&x];if([o isKindOfClass:[NSDictionary class]])j=o;}
  dispatch_async(dispatch_get_main_queue(),^{cb(j,x);});
 }];[task resume];
}
-(BOOL)textFieldShouldReturn:(UITextField*)t{[t resignFirstResponder];[self search];return YES;}
-(void)search{
 NSString*q=[query.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
 if(!q.length){A(self,@"Zadaj mesto",@"Napríklad Žilina alebo Poprad.");return;}
 [query resignFirstResponder];status.text=@"Vyhľadávam lokality SHMÚ…";
 NSString*enc=[q stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
 [self req:[NSString stringWithFormat:@"/stations?q=%@&page_size=80",enc] done:^(NSDictionary*j,NSError*e){
  if(e){A(self,@"Vyhľadávanie zlyhalo",e.localizedDescription);self->status.text=@"Skontroluj internet.";return;}
  self->stations=[j[@"stations"] isKindOfClass:[NSArray class]]?j[@"stations"]:@[];
  self->searching=YES;self->table.rowHeight=58;[self->table reloadData];
  self->status.text=[NSString stringWithFormat:@"Nájdených %lu miest • vyber dotykom",(unsigned long)self->stations.count];
 }];
}
-(void)refresh{
 searching=NO;table.rowHeight=103;cityLabel.text=city;[table reloadData];
 status.text=@"Načítavam predpoveď SHMÚ ALADIN…";NSUInteger requestID=++token;
 [self req:[NSString stringWithFormat:@"/forecast/daily?station=%@&days=3",station] done:^(NSDictionary*j,NSError*e){
  if(requestID!=self->token)return;
  NSArray*a=j[@"list"];
  if(e||![a isKindOfClass:[NSArray class]]){self->status.text=@"Nedostupný server • zobrazené staršie dáta, ak existujú";return;}
  self->days=a;[self->table reloadData];NSData*b=[NSJSONSerialization dataWithJSONObject:a options:0 error:nil];
  if(b)[[NSUserDefaults standardUserDefaults]setObject:b forKey:[@"cache" stringByAppendingString:self->station]];
  self->status.text=@"SHMÚ ALADIN • 3-dňová predpoveď (model)";
 }];
 [self req:[NSString stringWithFormat:@"/now?station=%@",station] done:^(NSDictionary*j,NSError*e){
  if(requestID!=self->token)return;
  NSDictionary*c=j[@"current"];if(![c isKindOfClass:[NSDictionary class]])return;
  NSArray*w=c[@"weather"];NSDictionary*v=w.count>0?w[0]:@{};NSString*code=S(v[@"code"]);
  self->nowIcon.text=Icon(code);
  id temp=c[@"main"][@"temp"];self->nowTemp.text=[NSString stringWithFormat:@"%.0f °C",[temp doubleValue]];
  NSString*wind=[NSString stringWithFormat:@"%.1f m/s",[c[@"wind"][@"speed"] doubleValue]];
  self->nowText.text=[NSString stringWithFormat:@"%@   •   vietor %@",Descr(code),wind];
 }];
}
-(NSInteger)tableView:(UITableView*)t numberOfRowsInSection:(NSInteger)s{return searching?stations.count:days.count;}
-(UITableViewCell*)tableView:(UITableView*)t cellForRowAtIndexPath:(NSIndexPath*)p{
 if(searching){
  UITableViewCell*c=[t dequeueReusableCellWithIdentifier:@"station"];
  if(!c)c=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"station"];
  NSDictionary*d=stations[p.row];c.textLabel.text=S(d[@"name"]);c.textLabel.textColor=UIColor.whiteColor;
  c.detailTextLabel.text=[NSString stringWithFormat:@"Meteorologická lokalita %@",S(d[@"id"])];
  c.detailTextLabel.textColor=C(0x42D5BE);c.backgroundColor=C(0x17303C);return c;
 }
 WeatherDayCell*c=[t dequeueReusableCellWithIdentifier:@"forecast"];
 if(!c)c=[[WeatherDayCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"forecast"];
 NSDictionary*d=days[p.row];NSDictionary*w=[d[@"weather"] isKindOfClass:NSDictionary.class]?d[@"weather"]:@{};
 NSString*code=S(w[@"code"]);c.sym.text=Icon(code);c.day.text=Day(S(d[@"date"]));
 c.desc.text=Descr(code);
 c.temp.text=[NSString stringWithFormat:@"%.0f° / %.0f°",[d[@"temp_max"] doubleValue],[d[@"temp_min"] doubleValue]];
 c.rain.text=[NSString stringWithFormat:@"💧 %.1f mm    💨 %.1f m/s",[d[@"precipitation_total"] doubleValue],[d[@"wind_speed_max"] doubleValue]];
 return c;
}
-(void)tableView:(UITableView*)t didSelectRowAtIndexPath:(NSIndexPath*)p{
 [t deselectRowAtIndexPath:p animated:YES];if(!searching)return;
 NSDictionary*d=stations[p.row];station=S(d[@"id"]);city=S(d[@"name"]);days=@[];
 [[NSUserDefaults standardUserDefaults]setObject:station forKey:@"station"];
 [[NSUserDefaults standardUserDefaults]setObject:city forKey:@"city"];
 nowIcon.text=@"⛅️";nowTemp.text=@"— °C";nowText.text=@"Načítavam aktuálnu predpoveď";
 [self refresh];
}
-(void)tap:(UIButton*)b{
 if(b.tag==0)[self search];if(b.tag==1)[self refresh];
 if(b.tag==2){SFSafariViewController*s=[[SFSafariViewController alloc]initWithURL:[NSURL URLWithString:@"https://www.shmu.sk/sk/?page=1&id=meteo_num_mgram10"]];[self presentViewController:s animated:YES completion:nil];}
}
@end
@implementation D
-(BOOL)application:(UIApplication*)a didFinishLaunchingWithOptions:(NSDictionary*)o{self.window=[[UIWindow alloc]initWithFrame:UIScreen.mainScreen.bounds];self.window.rootViewController=[V new];[self.window makeKeyAndVisible];return YES;}
@end
int main(int c,char**v){@autoreleasepool{return UIApplicationMain(c,v,nil,NSStringFromClass(D.class));}}
