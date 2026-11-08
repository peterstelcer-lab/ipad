#import <UIKit/UIKit.h>
#import <math.h>

// Exact or conventional SI conversion factors; offline, no network required.
static NSArray *TCUnitsGroups(void) {
 static NSArray *groups=nil;static dispatch_once_t once;
 dispatch_once(&once,^{groups=@[
 @{@"name":@"Dĺžka",@"units":@[@[@"mm",@0.001],@[@"cm",@0.01],@[@"m",@1],@[@"km",@1000],@[@"µm",@0.000001],@[@"palec (in)",@0.0254],@[@"stopa (ft)",@0.3048],@[@"yard",@0.9144],@[@"míľa",@1609.344],@[@"námorná míľa",@1852]]},
 @{@"name":@"Plocha",@"units":@[@[@"mm²",@0.000001],@[@"cm²",@0.0001],@[@"m²",@1],@[@"km²",@1000000],@[@"ha",@10000],@[@"ft²",@0.09290304],@[@"in²",@0.00064516],@[@"aker",@4046.8564224]]},
 @{@"name":@"Objem",@"units":@[@[@"mm³",@0.000000001],@[@"cm³",@0.000001],@[@"m³",@1],@[@"L",@0.001],@[@"mL",@0.000001],@[@"US gal",@0.003785411784],@[@"UK gal",@0.00454609],@[@"ft³",@0.028316846592],@[@"in³",@0.000016387064]]},
 @{@"name":@"Hmotnosť",@"units":@[@[@"mg",@0.000001],@[@"g",@0.001],@[@"kg",@1],@[@"t",@1000],@[@"lb",@0.45359237],@[@"oz",@0.028349523125],@[@"karát",@0.0002]]},
 @{@"name":@"Teplota",@"units":@[@[@"°C",@1],@[@"°F",@1],@[@"K",@1],@[@"°R",@1]],@"temperature":@YES},
 @{@"name":@"Čas",@"units":@[@[@"ms",@0.001],@[@"s",@1],@[@"min",@60],@[@"hodina",@3600],@[@"deň",@86400],@[@"týždeň",@604800],@[@"rok (365,25 d)",@31557600]]},
 @{@"name":@"Rýchlosť",@"units":@[@[@"m/s",@1],@[@"km/h",@(1.0/3.6)],@[@"mph",@0.44704],@[@"uzol",@(1852.0/3600.0)],@[@"ft/s",@0.3048]]},
 @{@"name":@"Zrýchlenie",@"units":@[@[@"m/s²",@1],@[@"g",@9.80665],@[@"ft/s²",@0.3048],@[@"Gal",@0.01]]},
 @{@"name":@"Sila",@"units":@[@[@"N",@1],@[@"kN",@1000],@[@"MN",@1000000],@[@"dyn",@0.00001],@[@"kgf",@9.80665],@[@"lbf",@4.4482216152605]]},
 @{@"name":@"Tlak",@"units":@[@[@"Pa",@1],@[@"kPa",@1000],@[@"MPa",@1000000],@[@"bar",@100000],@[@"mbar",@100],@[@"psi",@6894.757293168],@[@"atm",@101325],@[@"mmHg",@133.322387415]]},
 @{@"name":@"Energia",@"units":@[@[@"J",@1],@[@"kJ",@1000],@[@"MJ",@1000000],@[@"Wh",@3600],@[@"kWh",@3600000],@[@"cal",@4.184],@[@"kcal",@4184],@[@"BTU",@1055.05585262],@[@"eV",@1.602176634e-19]]},
 @{@"name":@"Výkon",@"units":@[@[@"W",@1],@[@"kW",@1000],@[@"MW",@1000000],@[@"hp (mechanický)",@745.699871582],@[@"PS (metrický)",@735.49875],@[@"BTU/h",@0.29307107017]]},
 @{@"name":@"Uhol",@"units":@[@[@"stupeň (°)",@(M_PI/180.0)],@[@"rad",@1],@[@"uhlová minúta",@(M_PI/10800.0)],@[@"otáčka",@(2*M_PI)],@[@"grad",@(M_PI/200.0)]]},
 @{@"name":@"Krútiaci moment",@"units":@[@[@"N·m",@1],@[@"N·mm",@0.001],@[@"lbf·ft",@1.3558179483314],@[@"lbf·in",@0.1129848290276]]},
 @{@"name":@"Hustota",@"units":@[@[@"kg/m³",@1],@[@"g/cm³",@1000],@[@"g/L",@1],@[@"lb/ft³",@16.01846337396]]},
 @{@"name":@"Prietok objemu",@"units":@[@[@"L/min",@(0.001/60.0)],@[@"L/s",@0.001],@[@"m³/h",@(1.0/3600.0)],@[@"m³/s",@1],@[@"US gal/min",@(0.003785411784/60.0)]]},
 @{@"name":@"Prietok hmotnosti",@"units":@[@[@"kg/s",@1],@[@"kg/h",@(1.0/3600.0)],@[@"g/s",@0.001],@[@"t/h",@(1000.0/3600.0)],@[@"lb/min",@(0.45359237/60.0)]]},
 @{@"name":@"Frekvencia",@"units":@[@[@"Hz",@1],@[@"kHz",@1000],@[@"MHz",@1000000],@[@"GHz",@1000000000],@[@"ot/min",@(1.0/60.0)]]},
 @{@"name":@"Dáta",@"units":@[@[@"bit",@0.125],@[@"B",@1],@[@"kB",@1000],@[@"MB",@1000000],@[@"GB",@1000000000],@[@"KiB",@1024],@[@"MiB",@1048576],@[@"GiB",@1073741824],@[@"TiB",@1099511627776.0]]},
 @{@"name":@"Elektrický náboj",@"units":@[@[@"C",@1],@[@"mC",@0.001],@[@"µC",@0.000001],@[@"Ah",@3600],@[@"mAh",@3.6]]},
 @{@"name":@"Napätie",@"units":@[@[@"mV",@0.001],@[@"V",@1],@[@"kV",@1000]]},
 @{@"name":@"Prúd",@"units":@[@[@"µA",@0.000001],@[@"mA",@0.001],@[@"A",@1],@[@"kA",@1000]]},
 @{@"name":@"Odpor",@"units":@[@[@"mΩ",@0.001],@[@"Ω",@1],@[@"kΩ",@1000],@[@"MΩ",@1000000]]},
 @{@"name":@"Kapacita",@"units":@[@[@"pF",@1e-12],@[@"nF",@1e-9],@[@"µF",@1e-6],@[@"mF",@0.001],@[@"F",@1]]},
 @{@"name":@"Indukčnosť",@"units":@[@[@"µH",@0.000001],@[@"mH",@0.001],@[@"H",@1]]},
 @{@"name":@"Magnetické pole",@"units":@[@[@"gauss (G)",@0.0001],@[@"mT",@0.001],@[@"T",@1]]},
 @{@"name":@"Dynamická viskozita",@"units":@[@[@"Pa·s",@1],@[@"mPa·s",@0.001],@[@"cP",@0.001],@[@"P",@0.1]]},
 @{@"name":@"Svetelný tok",@"units":@[@[@"lm",@1],@[@"klm",@1000],@[@"mlm",@0.001]]}
 ];});
 return groups;
}
static UIColor *UBackground(void){return [UIColor colorWithRed:.018 green:.058 blue:.079 alpha:1];}
static UIColor *UPanel(void){return [UIColor colorWithRed:.062 green:.15 blue:.19 alpha:1];}
static UIColor *UAccent(void){return [UIColor colorWithRed:.10 green:.88 blue:.82 alpha:1];}
static UILabel *ULabel(NSString *s,CGFloat size){
 UILabel *l=[UILabel new];l.text=s;l.font=[UIFont systemFontOfSize:size];l.textColor=UIColor.whiteColor;l.numberOfLines=2;return l;
}
static UIButton *UButton(NSString *text,id target,SEL selector){
 UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];b.layer.cornerRadius=9;
 [b setTitle:text forState:UIControlStateNormal];[b setTitleColor:UAccent() forState:UIControlStateNormal];
 b.backgroundColor=UPanel();b.titleLabel.font=[UIFont boldSystemFontOfSize:19];b.titleLabel.adjustsFontSizeToFitWidth=YES;
 [b addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];return b;
}
@interface TCUnitsController:UIViewController <UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate>
@property(nonatomic,strong) UITableView *categories;
@property(nonatomic,strong) UILabel *titleLabel,*subtitle,*result,*details,*fromLabel,*toLabel;
@property(nonatomic,strong) UITextField *input;
@property(nonatomic,strong) UIButton *fromButton,*toButton,*swapButton,*doneButton;
@property(nonatomic,assign) NSInteger groupIndex,fromIndex,toIndex;
@end
@implementation TCUnitsController
- (void)viewDidLoad{
 [super viewDidLoad];self.view.backgroundColor=UBackground();
 self.groupIndex=0;self.fromIndex=0;self.toIndex=2;
 self.categories=[[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
 self.categories.backgroundColor=UBackground();self.categories.separatorColor=UPanel();self.categories.rowHeight=43;
 self.categories.dataSource=self;self.categories.delegate=self;[self.view addSubview:self.categories];
 self.titleLabel=ULabel(@"PREVOD JEDNOTIEK",23);
 self.titleLabel.textColor=UAccent();self.titleLabel.font=[UIFont boldSystemFontOfSize:23];[self.view addSubview:self.titleLabel];
 self.subtitle=ULabel(@"Vyber kategóriu vľavo a jednotky napravo.",16);self.subtitle.textColor=[UIColor colorWithWhite:.72 alpha:1];[self.view addSubview:self.subtitle];
 self.fromLabel=ULabel(@"Z JEDNOTKY",16);[self.view addSubview:self.fromLabel];
 self.toLabel=ULabel(@"NA JEDNOTKU",16);[self.view addSubview:self.toLabel];
 self.input=[UITextField new];self.input.text=@"1";self.input.backgroundColor=UPanel();self.input.textColor=UIColor.whiteColor;
 self.input.font=[UIFont monospacedDigitSystemFontOfSize:27 weight:UIFontWeightMedium];self.input.keyboardType=UIKeyboardTypeDecimalPad;
 self.input.textAlignment=NSTextAlignmentCenter;self.input.layer.cornerRadius=8;self.input.delegate=self;
 [self.input addTarget:self action:@selector(updateResult) forControlEvents:UIControlEventEditingChanged];
 [self.view addSubview:self.input];
 self.fromButton=UButton(@"mm",self,@selector(chooseFrom));self.toButton=UButton(@"m",self,@selector(chooseTo));
 self.swapButton=UButton(@"⇄  PREHODIŤ",self,@selector(swap));self.doneButton=UButton(@"HOTOVO",self,@selector(endKeyboard));
 for(UIView *v in @[self.fromButton,self.toButton,self.swapButton,self.doneButton])[self.view addSubview:v];
 self.result=ULabel(@"",38);self.result.textAlignment=NSTextAlignmentCenter;self.result.adjustsFontSizeToFitWidth=YES;
 self.result.font=[UIFont monospacedDigitSystemFontOfSize:38 weight:UIFontWeightSemibold];[self.view addSubview:self.result];
 self.details=ULabel(@"",17);self.details.textColor=UAccent();self.details.textAlignment=NSTextAlignmentCenter;
 [self.view addSubview:self.details];
 [self updateNames];
}
- (void)viewDidLayoutSubviews{
 [super viewDidLayoutSubviews];
 CGFloat w=self.view.bounds.size.width,h=self.view.bounds.size.height;
 CGFloat m=12,sidebar=MIN(245,w*.30);
 self.categories.frame=CGRectMake(m,6,sidebar,MAX(100,h-12));
 CGFloat x=m+sidebar+16,rightW=w-x-m,half=(rightW-12)/2;
 self.titleLabel.frame=CGRectMake(x,6,rightW,37);
 self.subtitle.frame=CGRectMake(x,45,rightW,38);
 self.fromLabel.frame=CGRectMake(x,94,half,29);self.toLabel.frame=CGRectMake(x+half+12,94,half,29);
 self.fromButton.frame=CGRectMake(x,126,half,51);self.toButton.frame=CGRectMake(x+half+12,126,half,51);
 self.input.frame=CGRectMake(x,193,half,58);
 self.swapButton.frame=CGRectMake(x+half+12,193,half,58);
 self.details.frame=CGRectMake(x,269,rightW,42);
 self.result.frame=CGRectMake(x,310,rightW,MIN(93,MAX(63,h-387)));
 self.doneButton.frame=CGRectMake(x,MIN(h-55,423),rightW,49);
}
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s {return TCUnitsGroups().count;}
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)p{
 UITableViewCell *c=[t dequeueReusableCellWithIdentifier:@"units"];
 if(!c)c=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"units"];
 c.textLabel.text=TCUnitsGroups()[p.row][@"name"];
 c.textLabel.font=[UIFont boldSystemFontOfSize:18];
 c.textLabel.textColor=p.row==self.groupIndex?UAccent():UIColor.whiteColor;
 c.backgroundColor=p.row==self.groupIndex?UPanel():UBackground();
 c.accessoryType=p.row==self.groupIndex?UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;
 return c;
}
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)p{
 self.groupIndex=p.row;self.fromIndex=0;self.toIndex=MIN(1,[TCUnitsGroups()[p.row][@"units"] count]-1);
 [self.categories reloadData];[self updateNames];
}
- (void)updateNames{
 NSDictionary *group=TCUnitsGroups()[self.groupIndex];NSArray *units=group[@"units"];
 [self.fromButton setTitle:units[self.fromIndex][0] forState:UIControlStateNormal];
 [self.toButton setTitle:units[self.toIndex][0] forState:UIControlStateNormal];
 self.titleLabel.text=[NSString stringWithFormat:@"PREVOD • %@",group[@"name"]];
 [self updateResult];
}
- (void)updateResult{
 NSDictionary *group=TCUnitsGroups()[self.groupIndex];NSArray *units=group[@"units"];
 NSString *s=[self.input.text stringByReplacingOccurrencesOfString:@"," withString:@"."];
 if(!s.length||[s isEqualToString:@"-"]){self.result.text=@"—";self.details.text=@"";return;}
 NSScanner *scanner=[NSScanner scannerWithString:s];scanner.locale=[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
 double value=0;if(![scanner scanDouble:&value]||!scanner.isAtEnd||!isfinite(value)){self.result.text=@"Neplatná hodnota";return;}
 double answer;
 if([group[@"temperature"] boolValue]){
  // Convert to kelvin then from kelvin.
  double kelvin=value;
  if(self.fromIndex==0)kelvin=value+273.15;
  if(self.fromIndex==1)kelvin=(value+459.67)*(5.0/9.0);
  if(self.fromIndex==3)kelvin=value*(5.0/9.0);
  answer=kelvin;
  if(self.toIndex==0)answer=kelvin-273.15;
  if(self.toIndex==1)answer=kelvin*(9.0/5.0)-459.67;
  if(self.toIndex==3)answer=kelvin*(9.0/5.0);
  if(kelvin<0){self.result.text=@"Pod absolútnou nulou";return;}
 }else{
  double f=[units[self.fromIndex][1] doubleValue];
  double t=[units[self.toIndex][1] doubleValue];
  answer=value*f/t;
 }
 if(!isfinite(answer)){self.result.text=@"Mimo rozsah";return;}
 NSString *str=[NSString stringWithFormat:@"%.12g",answer];
 self.result.text=[[str stringByReplacingOccurrencesOfString:@"." withString:@","] stringByAppendingFormat:@"  %@",units[self.toIndex][0]];
 self.details.text=[NSString stringWithFormat:@"%@ %@  =  %@ %@",
  self.input.text,units[self.fromIndex][0],
  [str stringByReplacingOccurrencesOfString:@"." withString:@","],units[self.toIndex][0]];
}
- (void)showChoices:(BOOL)from {
 NSArray *units=TCUnitsGroups()[self.groupIndex][@"units"];
 UIAlertController *menu=[UIAlertController alertControllerWithTitle:from?@"Z jednotky":@"Na jednotku" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
 for(NSInteger i=0;i<units.count;i++){
  NSInteger index=i;NSString *name=units[i][0];
  [menu addAction:[UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault handler:^(UIAlertAction *act){
   if(from)self.fromIndex=index;else self.toIndex=index;[self updateNames];
  }]];
 }
 [menu addAction:[UIAlertAction actionWithTitle:@"ZRUŠIŤ" style:UIAlertActionStyleCancel handler:nil]];
 UIPopoverPresentationController *pop=menu.popoverPresentationController;
 UIView *anchor=from?self.fromButton:self.toButton;if(pop){pop.sourceView=anchor;pop.sourceRect=anchor.bounds;}
 [self presentViewController:menu animated:YES completion:nil];
}
- (void)chooseFrom{[self showChoices:YES];}
- (void)chooseTo{[self showChoices:NO];}
- (void)swap{
 NSInteger tmp=self.fromIndex;self.fromIndex=self.toIndex;self.toIndex=tmp;[self updateNames];
}
- (void)endKeyboard{[self.view endEditing:YES];}
- (BOOL)textFieldShouldReturn:(UITextField *)t{[t resignFirstResponder];[self updateResult];return YES;}
@end
