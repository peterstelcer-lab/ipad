#import "Shared.h"
#import <AVFoundation/AVFoundation.h>
#import <MobileVLCKit/MobileVLCKit.h>
@interface V:UIViewController<UITableViewDelegate,UITableViewDataSource,UIDocumentPickerDelegate,VLCMediaPlayerDelegate>{
 NSString*folder,*currentPath;NSArray*files,*playlist;
 UITableView*list;UILabel*title,*location,*info;
 NSArray*buttons;UIView*playerScreen,*videoSurface,*controlPanel,*topPanel;
 UILabel*filename,*timeLabel;UIButton*backBtn,*playBtn,*stopBtn,*rewindBtn,*forwardBtn,*previousBtn,*nextBtn,*modeBtn;
 UISlider*timeline;VLCMediaPlayer*vlc;NSTimer*ticker;BOOL seeking,controlsVisible;NSUInteger playingIndex;NSInteger screenMode;
}
@end
@implementation V
-(void)viewDidLoad{
 [super viewDidLoad];
 self.view.backgroundColor=C(0x07131D);
 folder=Shared();
 title=L(@"NEBULA MEDIA PLAYER   V3",23);title.textAlignment=NSTextAlignmentCenter;title.font=[UIFont boldSystemFontOfSize:23];[self.view addSubview:title];
 location=L(folder,12);location.textColor=C(0x42D5BE);[self.view addSubview:location];
 list=[[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStylePlain];list.delegate=self;list.dataSource=self;list.backgroundColor=C(0x152E3D);list.separatorColor=C(0x24495A);list.rowHeight=51;list.layer.cornerRadius=10;list.tableFooterView=[UIView new];[self.view addSubview:list];
 NSArray*names=@[@"↑ IMPORT",@"⌂ ZDIEĽANÉ",@"▤ MÉDIÁ IPADU",@"⌖ CESTA",@"↻ OBNOVIŤ"];
 NSMutableArray*a=[NSMutableArray array];for(int i=0;i<names.count;i++){UIButton*b=B(names[i],self,@selector(action:),i);[self.view addSubview:b];[a addObject:b];}buttons=a;
 info=L(@"AVI • MKV • MPEG • MP4 • MOV • MP3 • FLAC • WAV • AAC",13);info.textColor=C(0x42D5BE);info.textAlignment=NSTextAlignmentCenter;[self.view addSubview:info];
 playerScreen=[UIView new];playerScreen.backgroundColor=UIColor.blackColor;playerScreen.hidden=YES;[self.view addSubview:playerScreen];
 videoSurface=[UIView new];videoSurface.backgroundColor=UIColor.blackColor;[playerScreen addSubview:videoSurface];
 UITapGestureRecognizer*tap=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(toggleControls)];[videoSurface addGestureRecognizer:tap];
 UITapGestureRecognizer*doubleTap=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(changeMode)];doubleTap.numberOfTapsRequired=2;[videoSurface addGestureRecognizer:doubleTap];[tap requireGestureRecognizerToFail:doubleTap];
 topPanel=[UIView new];topPanel.backgroundColor=[C(0x08151E) colorWithAlphaComponent:0.89];[playerScreen addSubview:topPanel];
 controlPanel=[UIView new];controlPanel.backgroundColor=[C(0x0D202A) colorWithAlphaComponent:0.90];[playerScreen addSubview:controlPanel];
 filename=L(@"",16);filename.font=[UIFont boldSystemFontOfSize:16];filename.textAlignment=NSTextAlignmentCenter;[topPanel addSubview:filename];
 timeLabel=L(@"00:00 / 00:00",12);timeLabel.textColor=C(0x42D5BE);timeLabel.textAlignment=NSTextAlignmentCenter;[topPanel addSubview:timeLabel];
 timeline=[UISlider new];timeline.minimumValue=0;timeline.maximumValue=1;timeline.minimumTrackTintColor=C(0x42D5BE);
 [timeline addTarget:self action:@selector(seekBegin:) forControlEvents:UIControlEventTouchDown];
 [timeline addTarget:self action:@selector(seekChanged:) forControlEvents:UIControlEventValueChanged];
 [timeline addTarget:self action:@selector(seekEnd:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
 [controlPanel addSubview:timeline];
 backBtn=B(@"✕  ZAVRIEŤ",self,@selector(closePlayer),0);[topPanel addSubview:backBtn];
 modeBtn=B(@"▣  POMER",self,@selector(changeMode),0);[topPanel addSubview:modeBtn];modeBtn.accessibilityLabel=@"Prepnúť pomer strán";
 previousBtn=B(@"|◀",self,@selector(previous),0);[controlPanel addSubview:previousBtn];previousBtn.accessibilityLabel=@"Predchádzajúci súbor";
 rewindBtn=B(@"◀◀",self,@selector(rewind15),0);[controlPanel addSubview:rewindBtn];rewindBtn.accessibilityLabel=@"O pätnásť sekúnd späť";
 stopBtn=B(@"■",self,@selector(stopPlayback),0);[controlPanel addSubview:stopBtn];stopBtn.accessibilityLabel=@"Stop";
 playBtn=B(@"Ⅱ",self,@selector(playPause),0);[controlPanel addSubview:playBtn];playBtn.accessibilityLabel=@"Prehrať alebo pozastaviť";
 forwardBtn=B(@"▶▶",self,@selector(forward15),0);[controlPanel addSubview:forwardBtn];forwardBtn.accessibilityLabel=@"O pätnásť sekúnd vpred";
 nextBtn=B(@"▶|",self,@selector(next),0);[controlPanel addSubview:nextBtn];nextBtn.accessibilityLabel=@"Nasledujúci súbor";
 for(UIButton*b in @[previousBtn,rewindBtn,stopBtn,playBtn,forwardBtn,nextBtn]){b.titleLabel.font=[UIFont boldSystemFontOfSize:32];b.layer.cornerRadius=12;b.backgroundColor=C(0x173D4D);}
 playBtn.backgroundColor=C(0x056A69);controlsVisible=YES;screenMode=0;
 vlc=[VLCMediaPlayer new];vlc.delegate=self;vlc.drawable=videoSurface;
 [[AVAudioSession sharedInstance]setCategory:AVAudioSessionCategoryPlayback error:nil];
 ticker=[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(tick) userInfo:nil repeats:YES];
 [self refresh];
}
-(void)dealloc{[ticker invalidate];[vlc stop];vlc.delegate=nil;}
-(void)viewDidLayoutSubviews{
 [super viewDidLayoutSubviews];
 CGFloat w=self.view.bounds.size.width,h=self.view.bounds.size.height,p=12,t=self.view.safeAreaInsets.top,b=self.view.safeAreaInsets.bottom;
 title.frame=CGRectMake(p,t+6,w-2*p,36);
 location.frame=CGRectMake(p,t+45,w-2*p,27);
 CGFloat y=t+80;CGFloat contentHeight=MAX(155,h-y-b-129);
 list.frame=CGRectMake(p,y,w-2*p,contentHeight);
 info.frame=CGRectMake(p,y+contentHeight+6,w-2*p,22);
 CGFloat gap=7,bw=(w-2*p-4*gap)/5;
 for(int i=0;i<buttons.count;i++)((UIButton*)buttons[i]).frame=CGRectMake(p+i*(bw+gap),y+contentHeight+38,bw,40);

 playerScreen.frame=self.view.bounds;
 videoSurface.frame=playerScreen.bounds; // obraz je pod panelmi na CELEJ obrazovke
 CGFloat toolbarH=(w<h)?180:164;
 topPanel.frame=CGRectMake(0,0,w,t+59);
 controlPanel.frame=CGRectMake(0,h-toolbarH-b,w,toolbarH+b);
 backBtn.frame=CGRectMake(12,t+8,114,43);
 modeBtn.frame=CGRectMake(w-154,t+8,142,43);
 filename.frame=CGRectMake(138,t+3,MAX(80,w-308),31);
 filename.textAlignment=NSTextAlignmentCenter;
 timeLabel.frame=CGRectMake(138,t+33,MAX(80,w-308),22);
 timeline.frame=CGRectMake(24,9,w-48,37);
 CGFloat sp=10,btnW=MIN(110,(w-30-5*sp)/6);
 CGFloat total=btnW*6+sp*5,left=(w-total)/2,by=toolbarH-91;
 NSArray*transport=@[previousBtn,rewindBtn,stopBtn,playBtn,forwardBtn,nextBtn];
 for(NSInteger i=0;i<transport.count;i++){UIButton*btn=transport[i];btn.frame=CGRectMake(left+i*(btnW+sp),by,btnW,72);}
 [self updateVideoRatio];

}
-(BOOL)mediaFile:(NSString*)s{
 NSArray*ext=@[@"avi",@"mkv",@"mpg",@"mpeg",@"mp4",@"m4v",@"mov",@"wmv",@"flv",@"webm",@"ts",@"m2ts",@"3gp",@"vob",@"ogv",@"divx",@"mp3",@"flac",@"wav",@"aac",@"m4a",@"ogg",@"opus",@"wma",@"aiff",@"aif",@"ac3",@"mka"];
 return [ext containsObject:s.pathExtension.lowercaseString];
}
-(void)refresh{
 NSArray*arr=[[NSFileManager defaultManager]contentsOfDirectoryAtPath:folder error:nil];
 files=[arr sortedArrayUsingSelector:@selector(localizedStandardCompare:)]?:@[];
 location.text=folder;[list reloadData];
}
-(NSInteger)tableView:(UITableView*)t numberOfRowsInSection:(NSInteger)section{return files.count+1;}
-(UITableViewCell*)tableView:(UITableView*)t cellForRowAtIndexPath:(NSIndexPath*)p{
 UITableViewCell*c=[t dequeueReusableCellWithIdentifier:@"m"];
 if(!c)c=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"m"];
 NSString*n=p.row?files[p.row-1]:@".. (vyššie)";
 BOOL d=p.row==0;if(p.row)[[NSFileManager defaultManager]fileExistsAtPath:[folder stringByAppendingPathComponent:n] isDirectory:&d];
 c.backgroundColor=C(0x152E3D);
 c.textLabel.text=[NSString stringWithFormat:@"%@  %@",d?@"📁":([self mediaFile:n]?@"▶️":@"📄"),n];
 c.textLabel.textColor=UIColor.whiteColor;c.textLabel.font=[UIFont systemFontOfSize:15];
 c.detailTextLabel.text=d?@"Priečinok":([self mediaFile:n]?@"Prehrať v jadre VLC":@"Pokúsiť sa prehrať");
 c.detailTextLabel.textColor=C(0x42D5BE);return c;
}
-(void)tableView:(UITableView*)t didSelectRowAtIndexPath:(NSIndexPath*)p{
 [t deselectRowAtIndexPath:p animated:YES];
 if(!p.row){folder=[folder stringByDeletingLastPathComponent];if(!folder.length)folder=@"/";[self refresh];return;}
 NSString*s=[folder stringByAppendingPathComponent:files[p.row-1]];
 BOOL d=NO;[[NSFileManager defaultManager]fileExistsAtPath:s isDirectory:&d];
 if(d){folder=s;[self refresh];return;}
 [self open:s];
}
-(void)open:(NSString*)s{
 if(![[NSFileManager defaultManager]isReadableFileAtPath:s]){A(self,@"Súbor nedostupný",@"Prístup k tomuto súboru iOS nepovolil.");return;}
 NSMutableArray*listOfMedia=[NSMutableArray array];
 for(NSString*n in files){NSString*p=[folder stringByAppendingPathComponent:n];BOOL d=NO;[[NSFileManager defaultManager]fileExistsAtPath:p isDirectory:&d];if(!d&&[self mediaFile:n])[listOfMedia addObject:p];}
 playlist=listOfMedia;
 NSUInteger found=[playlist indexOfObject:s];playingIndex=found==NSNotFound?NSNotFound:found;
 [self playPath:s];
}
-(void)playPath:(NSString*)s{
 [vlc stop];
 currentPath=s;filename.text=s.lastPathComponent;timeLabel.text=@"00:00 / 00:00";
 timeline.value=0;playerScreen.hidden=NO;[self.view bringSubviewToFront:playerScreen];
 [UIApplication sharedApplication].idleTimerDisabled=YES;[self setControls:YES schedule:YES];
 VLCMedia*media=[VLCMedia mediaWithPath:s];
 if(!media){A(self,@"Neplatný súbor",@"Nedá sa vytvoriť video stopa.");return;}
 vlc.drawable=videoSurface;vlc.media=media;
 [vlc play];[playBtn setTitle:@"Ⅱ" forState:UIControlStateNormal];[self updateVideoRatio];[self setNeedsStatusBarAppearanceUpdate];
}
-(void)closePlayer{
 [vlc stop];playerScreen.hidden=YES;[UIApplication sharedApplication].idleTimerDisabled=NO;
 [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(autoHideControls) object:nil];
 [self setNeedsStatusBarAppearanceUpdate];
}
-(BOOL)prefersStatusBarHidden{return !playerScreen.hidden;}
-(void)setControls:(BOOL)show schedule:(BOOL)sched{
 controlsVisible=show;topPanel.hidden=!show;controlPanel.hidden=!show;
 [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(autoHideControls) object:nil];
 if(show&&sched&&vlc.isPlaying)[self performSelector:@selector(autoHideControls) withObject:nil afterDelay:5.0];
}
-(void)autoHideControls{if(!playerScreen.hidden&&vlc.isPlaying&&!seeking)[self setControls:NO schedule:NO];}
-(void)toggleControls{[self setControls:!controlsVisible schedule:YES];}
-(void)changeMode{screenMode=(screenMode+1)%3;[self updateVideoRatio];[self setControls:YES schedule:YES];}
-(void)updateVideoRatio{
 if(!vlc||playerScreen.hidden)return;
 CGFloat w=MAX(1,videoSurface.bounds.size.width),h=MAX(1,videoSurface.bounds.size.height);
 char aspect[40];snprintf(aspect,sizeof(aspect),"%ld:%ld",(long)round(w),(long)round(h));
 if(screenMode==0){vlc.videoCropGeometry=NULL;vlc.videoAspectRatio=NULL;[modeBtn setTitle:@"▣ POMER" forState:UIControlStateNormal];}
 else if(screenMode==1){vlc.videoAspectRatio=NULL;vlc.videoCropGeometry=aspect;[modeBtn setTitle:@"⛶ VYPLNIŤ" forState:UIControlStateNormal];}
 else{vlc.videoCropGeometry=NULL;vlc.videoAspectRatio=aspect;[modeBtn setTitle:@"⬌ ROZTIAH." forState:UIControlStateNormal];}
}
-(void)jumpSeconds:(NSInteger)sec{
 if(!vlc.isSeekable)return;
 int length=vlc.media.length.intValue;if(length<=0)return;
 NSInteger target=MAX(0,MIN((NSInteger)length,(NSInteger)vlc.time.intValue+sec*1000));
 vlc.position=(float)target/(float)length;
 [self setControls:YES schedule:YES];
}
-(void)rewind15{[self jumpSeconds:-15];}
-(void)forward15{[self jumpSeconds:15];}
-(void)stopPlayback{[vlc stop];[playBtn setTitle:@"▶" forState:UIControlStateNormal];timeline.value=0;[self setControls:YES schedule:NO];}

-(void)playPause{
 if(vlc.isPlaying){[vlc pause];[playBtn setTitle:@"▶" forState:UIControlStateNormal];[self setControls:YES schedule:NO];}
 else {[vlc play];[playBtn setTitle:@"Ⅱ" forState:UIControlStateNormal];[self setControls:YES schedule:YES];}
}
-(void)previous{[self step:-1];}
-(void)next{[self step:1];}
-(void)step:(NSInteger)d{
 if(!playlist.count)return;
 if(playingIndex==NSNotFound){playingIndex=0;}
 else playingIndex=(playingIndex+playlist.count+d)%playlist.count;
 [self playPath:playlist[playingIndex]];
}
-(void)seekBegin:(UISlider*)s{seeking=YES;[self setControls:YES schedule:NO];}
-(void)seekChanged:(UISlider*)s{
 if(vlc.isSeekable)vlc.position=s.value;
}
-(void)seekEnd:(UISlider*)s{if(vlc.isSeekable)vlc.position=s.value;seeking=NO;[self setControls:YES schedule:YES];}
-(NSString*)clock:(NSInteger)ms{
 if(ms<0)ms=0;NSInteger n=ms/1000;
 return [NSString stringWithFormat:@"%02ld:%02ld",(long)(n/60),(long)(n%60)];
}
-(void)tick{
 if(playerScreen.hidden)return;
 if(!seeking)timeline.value=vlc.position;
 VLCTime*cur=vlc.time,*len=vlc.media.length;
 timeLabel.text=[NSString stringWithFormat:@"%@ / %@",[self clock:cur.intValue],[self clock:len.intValue]];
}
-(void)mediaPlayerStateChanged:(NSNotification*)notification {
 dispatch_async(dispatch_get_main_queue(),^{
  if(self->vlc.state==VLCMediaPlayerStateError){
   A(self,@"Prehrávanie zlyhalo",@"Jadro VLC nedokázalo otvoriť tento súbor. Skontroluj, či nie je poškodený.");
  }
 });
}
-(void)action:(UIButton*)b{
 if(b.tag==0){
  UIDocumentPickerViewController*p=[[UIDocumentPickerViewController alloc]initWithDocumentTypes:@[@"public.item"] inMode:UIDocumentPickerModeImport];p.delegate=self;
  p.modalPresentationStyle=UIModalPresentationFormSheet;[self presentViewController:p animated:YES completion:nil];
 }else if(b.tag==1){folder=Shared();[self refresh];}
 else if(b.tag==2){folder=@"/var/mobile/Media";[self refresh];}
 else if(b.tag==3){
  UIAlertController*a=[UIAlertController alertControllerWithTitle:@"Otvoriť cestu" message:nil preferredStyle:UIAlertControllerStyleAlert];
  [a addTextFieldWithConfigurationHandler:^(UITextField*f){f.text=self->folder;f.autocorrectionType=UITextAutocorrectionTypeNo;}];
  [a addAction:[UIAlertAction actionWithTitle:@"Zrušiť" style:UIAlertActionStyleCancel handler:nil]];
  [a addAction:[UIAlertAction actionWithTitle:@"Otvoriť" style:UIAlertActionStyleDefault handler:^(UIAlertAction*x){
   NSString*s=[a.textFields.firstObject.text stringByStandardizingPath];BOOL d=NO;
   if([[NSFileManager defaultManager]fileExistsAtPath:s isDirectory:&d]&&d){self->folder=s;[self refresh];}else A(self,@"Neplatná cesta",s);
  }]];[self presentViewController:a animated:YES completion:nil];
 }else if(b.tag==4){[self refresh];}
}
-(void)documentPicker:(UIDocumentPickerViewController*)p didPickDocumentAtURL:(NSURL*)u{
 NSString*target=[Shared() stringByAppendingPathComponent:u.lastPathComponent];
 if([[NSFileManager defaultManager]fileExistsAtPath:target]){A(self,@"Súbor už existuje",u.lastPathComponent);return;}
 NSError*e=nil;if(![[NSFileManager defaultManager]copyItemAtURL:u toURL:[NSURL fileURLWithPath:target] error:&e])A(self,@"Import zlyhal",e.localizedDescription);
 folder=Shared();[self refresh];
}
@end
@implementation D
-(BOOL)application:(UIApplication*)a didFinishLaunchingWithOptions:(NSDictionary*)o{
 self.window=[[UIWindow alloc]initWithFrame:UIScreen.mainScreen.bounds];self.window.rootViewController=[V new];[self.window makeKeyAndVisible];return YES;
}
@end
int main(int c,char**v){@autoreleasepool{return UIApplicationMain(c,v,nil,NSStringFromClass(D.class));}}
