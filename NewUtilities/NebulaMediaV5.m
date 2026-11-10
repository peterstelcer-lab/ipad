#import "Shared.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <math.h>
#import <MobileVLCKit/MobileVLCKit.h>
@interface V:UIViewController<UITableViewDelegate,UITableViewDataSource,UIDocumentPickerDelegate,VLCMediaPlayerDelegate>{
 NSString*folder,*currentPath;NSArray*files,*playlist;
 UITableView*list;UILabel*title,*location,*info;
 NSArray*buttons;UIView*playerScreen,*videoSurface,*controlPanel,*topPanel;
 UILabel*filename,*timeLabel;UIButton*backBtn,*playBtn,*stopBtn,*rewindBtn,*forwardBtn,*previousBtn,*nextBtn,*modeBtn,*audioBtn,*speedBtn,*settingsBtn;
 UISlider*timeline;VLCMediaPlayer*vlc;NSTimer*ticker;BOOL seeking,controlsVisible;NSUInteger playingIndex;NSInteger screenMode;
 MPVolumeView*volumeView;UISlider*volumeSlider;
 UILabel*swipeIndicator;CGFloat touchStartY,startBrightness,startVolume;
 BOOL swipeIsBrightness;float chosenRate;
 NSString*forcedAspect;BOOL subtitleImportMode,repeatOne,autoplayNext;NSTimer*sleepTimer;
}
@end
@implementation V
-(void)viewDidLoad{
 [super viewDidLoad];
 self.view.backgroundColor=C(0x07131D);
 folder=[[NSUserDefaults standardUserDefaults] stringForKey:@"nebulaFolder"]?:Shared();
 BOOL folderIsDir=NO; if(![[NSFileManager defaultManager]fileExistsAtPath:folder isDirectory:&folderIsDir]||!folderIsDir)folder=Shared();
 autoplayNext= ![[NSUserDefaults standardUserDefaults] objectForKey:@"nebulaAutoNext"] || [[NSUserDefaults standardUserDefaults] boolForKey:@"nebulaAutoNext"];
 repeatOne=[[NSUserDefaults standardUserDefaults] boolForKey:@"nebulaRepeatOne"];
 title=L(@"NEBULA MEDIA PLAYER   V5",23);title.textAlignment=NSTextAlignmentCenter;title.font=[UIFont boldSystemFontOfSize:23];[self.view addSubview:title];
 location=L(folder,12);location.textColor=C(0x42D5BE);[self.view addSubview:location];
 list=[[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStylePlain];list.delegate=self;list.dataSource=self;list.backgroundColor=C(0x152E3D);list.separatorColor=C(0x24495A);list.rowHeight=51;list.layer.cornerRadius=10;list.tableFooterView=[UIView new];[self.view addSubview:list];
 NSArray*names=@[@"↑ IMPORT",@"⌂ ZDIEĽANÉ",@"▤ MÉDIÁ IPADU",@"⌖ CESTA",@"↻ OBNOVIŤ"];
 NSMutableArray*a=[NSMutableArray array];for(int i=0;i<names.count;i++){UIButton*b=B(names[i],self,@selector(action:),i);[self.view addSubview:b];[a addObject:b];}buttons=a;
 info=L(@"AVI • MKV • MPEG • MP4 • MOV • MP3 • FLAC • WAV • AAC",13);info.textColor=C(0x42D5BE);info.textAlignment=NSTextAlignmentCenter;[self.view addSubview:info];
 playerScreen=[UIView new];playerScreen.backgroundColor=UIColor.blackColor;playerScreen.hidden=YES;[self.view addSubview:playerScreen];
 videoSurface=[UIView new];videoSurface.backgroundColor=UIColor.blackColor;[playerScreen addSubview:videoSurface];
 UITapGestureRecognizer*tap=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(toggleControls)];[videoSurface addGestureRecognizer:tap];
 UITapGestureRecognizer*doubleTap=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(changeMode)];doubleTap.numberOfTapsRequired=2;[videoSurface addGestureRecognizer:doubleTap];[tap requireGestureRecognizerToFail:doubleTap];
 UIPanGestureRecognizer*swipe=[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(verticalSwipe:)];
 swipe.maximumNumberOfTouches=1;[videoSurface addGestureRecognizer:swipe];
 topPanel=[UIView new];topPanel.backgroundColor=[C(0x08151E) colorWithAlphaComponent:0.27];[playerScreen addSubview:topPanel];
 controlPanel=[UIView new];controlPanel.backgroundColor=[C(0x0D202A) colorWithAlphaComponent:0.27];[playerScreen addSubview:controlPanel];
 filename=L(@"",16);filename.font=[UIFont boldSystemFontOfSize:16];filename.textAlignment=NSTextAlignmentCenter;[topPanel addSubview:filename];
 timeLabel=L(@"00:00 / 00:00",12);timeLabel.textColor=C(0x42D5BE);timeLabel.textAlignment=NSTextAlignmentCenter;[topPanel addSubview:timeLabel];
 timeline=[UISlider new];timeline.minimumValue=0;timeline.maximumValue=1;timeline.minimumTrackTintColor=C(0x42D5BE);
 [timeline addTarget:self action:@selector(seekBegin:) forControlEvents:UIControlEventTouchDown];
 [timeline addTarget:self action:@selector(seekChanged:) forControlEvents:UIControlEventValueChanged];
 [timeline addTarget:self action:@selector(seekEnd:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
 [controlPanel addSubview:timeline];
 backBtn=B(@"✕  ZAVRIEŤ",self,@selector(closePlayer),0);[topPanel addSubview:backBtn];
 modeBtn=B(@"▣ POMER",self,@selector(changeMode),0);[topPanel addSubview:modeBtn];modeBtn.accessibilityLabel=@"Prepnúť pomer strán";
 audioBtn=B(@"♫ STOPA",self,@selector(chooseAudioTrack),0);[topPanel addSubview:audioBtn];audioBtn.accessibilityLabel=@"Výber zvukovej stopy";
 speedBtn=B(@"1× RÝCHL.",self,@selector(chooseRate),0);[topPanel addSubview:speedBtn];speedBtn.accessibilityLabel=@"Rýchlosť prehrávania";
 settingsBtn=B(@"⚙",self,@selector(showSettings),0);[topPanel addSubview:settingsBtn];settingsBtn.accessibilityLabel=@"Pokročilé nastavenia prehrávača";settingsBtn.titleLabel.font=[UIFont boldSystemFontOfSize:24];
 for(UIButton*b in @[backBtn,modeBtn,audioBtn,speedBtn,settingsBtn]){
  b.backgroundColor=[[UIColor blackColor]colorWithAlphaComponent:0.18];
  b.layer.borderWidth=1;b.layer.borderColor=[UIColor colorWithWhite:1 alpha:0.32].CGColor;
  [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
 }
 previousBtn=B(@"|◀",self,@selector(previous),0);[controlPanel addSubview:previousBtn];previousBtn.accessibilityLabel=@"Predchádzajúci súbor";
 rewindBtn=B(@"◀◀",self,@selector(rewind15),0);[controlPanel addSubview:rewindBtn];rewindBtn.accessibilityLabel=@"O pätnásť sekúnd späť";
 stopBtn=B(@"■",self,@selector(stopPlayback),0);[controlPanel addSubview:stopBtn];stopBtn.accessibilityLabel=@"Stop";
 playBtn=B(@"Ⅱ",self,@selector(playPause),0);[controlPanel addSubview:playBtn];playBtn.accessibilityLabel=@"Prehrať alebo pozastaviť";
 forwardBtn=B(@"▶▶",self,@selector(forward15),0);[controlPanel addSubview:forwardBtn];forwardBtn.accessibilityLabel=@"O pätnásť sekúnd vpred";
 nextBtn=B(@"▶|",self,@selector(next),0);[controlPanel addSubview:nextBtn];nextBtn.accessibilityLabel=@"Nasledujúci súbor";
 for(UIButton*b in @[previousBtn,rewindBtn,stopBtn,playBtn,forwardBtn,nextBtn]){
  b.titleLabel.font=[UIFont boldSystemFontOfSize:29];
  b.backgroundColor=[[UIColor blackColor]colorWithAlphaComponent:0.18];
  b.layer.borderWidth=1.4;b.layer.borderColor=[UIColor colorWithWhite:1 alpha:0.45].CGColor;
  [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
 }
 playBtn.layer.borderColor=C(0x43E0CA).CGColor;playBtn.layer.borderWidth=2.5;
 controlsVisible=YES;screenMode=0;chosenRate=1.0f;
 float savedRate=[[NSUserDefaults standardUserDefaults] floatForKey:@"nebulaRate"];if(savedRate>=0.25f&&savedRate<=40.f)chosenRate=savedRate;
 swipeIndicator=L(@"",24);swipeIndicator.backgroundColor=[[UIColor blackColor]colorWithAlphaComponent:0.60];
 swipeIndicator.textAlignment=NSTextAlignmentCenter;swipeIndicator.layer.cornerRadius=14;swipeIndicator.clipsToBounds=YES;
 swipeIndicator.hidden=YES;[playerScreen addSubview:swipeIndicator];
 volumeView=[MPVolumeView new];volumeView.showsRouteButton=NO;volumeView.showsVolumeSlider=YES;
 volumeView.alpha=0.02;[playerScreen addSubview:volumeView];
 vlc=[VLCMediaPlayer new];vlc.delegate=self;vlc.drawable=videoSurface;
 [[AVAudioSession sharedInstance]setCategory:AVAudioSessionCategoryPlayback error:nil];
 ticker=[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(tick) userInfo:nil repeats:YES];
 [self refresh];
}
-(void)dealloc{[ticker invalidate];[sleepTimer invalidate];[vlc stop];vlc.delegate=nil;}
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
 CGFloat toolbarH=(w<h)?139:112;
 topPanel.frame=CGRectMake(0,0,w,t+53);
 controlPanel.frame=CGRectMake(0,h-toolbarH-b,w,toolbarH+b);
 backBtn.frame=CGRectMake(11,t+9,98,38);
 CGFloat right=10,buttonGap=6,extraWidth=88;
 settingsBtn.frame=CGRectMake(w-right-46,t+9,46,38);
 speedBtn.frame=CGRectMake(CGRectGetMinX(settingsBtn.frame)-buttonGap-extraWidth,t+9,extraWidth,38);
 audioBtn.frame=CGRectMake(CGRectGetMinX(speedBtn.frame)-buttonGap-extraWidth,t+9,extraWidth,38);
 modeBtn.frame=CGRectMake(CGRectGetMinX(audioBtn.frame)-buttonGap-extraWidth,t+9,extraWidth,38);
 CGFloat nameStart=117,nameWidth=MAX(70,CGRectGetMinX(modeBtn.frame)-nameStart-10);
 filename.frame=CGRectMake(nameStart,t+4,nameWidth,23);
 timeLabel.frame=CGRectMake(nameStart,t+26,nameWidth,22);
 timeline.frame=CGRectMake(28,6,w-56,33);
 CGFloat transportGap=(w<620)?8:14,diam=MIN(66,(w-28-5*transportGap)/6);
 CGFloat total=diam*6+transportGap*5,left=(w-total)*0.5,transportY=toolbarH-69;
 NSArray*transport=@[previousBtn,rewindBtn,stopBtn,playBtn,forwardBtn,nextBtn];
 for(NSInteger i=0;i<transport.count;i++){
  UIButton*btn=transport[i];btn.frame=CGRectMake(left+i*(diam+transportGap),transportY,diam,diam);
  btn.layer.cornerRadius=diam*0.5;
 }
 swipeIndicator.frame=CGRectMake(MAX(16,(w-210)*0.5),MAX(24,(h-92)*0.5),210,92);
 volumeView.frame=CGRectMake(1,1,1,1);
 [self updateVideoRatio];

}
-(BOOL)mediaFile:(NSString*)s{
 NSArray*ext=@[@"avi",@"mkv",@"mpg",@"mpeg",@"mp4",@"m4v",@"mov",@"wmv",@"flv",@"webm",@"ts",@"m2ts",@"3gp",@"vob",@"ogv",@"divx",@"mp3",@"flac",@"wav",@"aac",@"m4a",@"ogg",@"opus",@"wma",@"aiff",@"aif",@"ac3",@"mka",@"amr",@"ape",@"m4b",@"m3u",@"m3u8",@"mpegts"];
 return [ext containsObject:s.pathExtension.lowercaseString];
}
-(void)refresh{
 NSArray*arr=[[NSFileManager defaultManager]contentsOfDirectoryAtPath:folder error:nil];
 files=[arr sortedArrayUsingSelector:@selector(localizedStandardCompare:)]?:@[];
 [[NSUserDefaults standardUserDefaults]setObject:folder forKey:@"nebulaFolder"];
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
 [vlc play];vlc.rate=chosenRate;[playBtn setTitle:@"Ⅱ" forState:UIControlStateNormal];[self updateVideoRatio];[self setControls:YES schedule:YES];[self setNeedsStatusBarAppearanceUpdate];
}
-(void)closePlayer{
 [vlc stop];[sleepTimer invalidate];sleepTimer=nil;playerScreen.hidden=YES;[UIApplication sharedApplication].idleTimerDisabled=NO;
 [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideSwipeIndicator) object:nil];swipeIndicator.hidden=YES;
 [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(autoHideControls) object:nil];
 [self setNeedsStatusBarAppearanceUpdate];
}
-(BOOL)prefersStatusBarHidden{return !playerScreen.hidden;}
-(void)setControls:(BOOL)show schedule:(BOOL)sched{
 controlsVisible=show;topPanel.hidden=!show;controlPanel.hidden=!show;
 [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(autoHideControls) object:nil];
 if(show&&sched)[self performSelector:@selector(autoHideControls) withObject:nil afterDelay:5.0];
}
-(void)autoHideControls{if(!playerScreen.hidden&&!seeking&&self.presentedViewController==nil)[self setControls:NO schedule:NO];}
-(void)toggleControls{[self setControls:!controlsVisible schedule:YES];}
-(void)changeMode{forcedAspect=nil;screenMode=(screenMode+1)%3;[self updateVideoRatio];[self setControls:YES schedule:YES];}
-(void)updateVideoRatio{
 if(!vlc||playerScreen.hidden)return;
 CGFloat w=MAX(1,videoSurface.bounds.size.width),h=MAX(1,videoSurface.bounds.size.height);
 char aspect[40];snprintf(aspect,sizeof(aspect),"%ld:%ld",(long)round(w),(long)round(h));
 if(forcedAspect.length){vlc.videoCropGeometry=NULL;vlc.videoAspectRatio=(char*)forcedAspect.UTF8String;[modeBtn setTitle:[NSString stringWithFormat:@"▣ %@",forcedAspect] forState:UIControlStateNormal];return;}
 if(screenMode==0){vlc.videoCropGeometry=NULL;vlc.videoAspectRatio=NULL;[modeBtn setTitle:@"▣ POMER" forState:UIControlStateNormal];}
 else if(screenMode==1){vlc.videoAspectRatio=NULL;vlc.videoCropGeometry=aspect;[modeBtn setTitle:@"⛶ VYPLNIŤ" forState:UIControlStateNormal];}
 else{vlc.videoCropGeometry=NULL;vlc.videoAspectRatio=aspect;[modeBtn setTitle:@"⬌ ROZTIAH." forState:UIControlStateNormal];}
}

-(void)chooseAudioTrack{
 [self setControls:YES schedule:NO];
 NSArray*names=vlc.audioTrackNames;
 NSArray*indexes=vlc.audioTrackIndexes;
 NSUInteger count=MIN(names.count,indexes.count);
 if(count==0){A(self,@"Zvuková stopa",@"Nenašla sa žiadna zvuková stopa. Skús voľbu po začatí prehrávania.");[self setControls:YES schedule:YES];return;}
 UIAlertController*sheet=[UIAlertController alertControllerWithTitle:@"Zvukové stopy" message:@"Vyber zvukovú stopu videa" preferredStyle:UIAlertControllerStyleAlert];
 int current=vlc.currentAudioTrackIndex;
 for(NSUInteger i=0;i<count;i++){
  int ident=[indexes[i] intValue];
  NSString*name=[names[i] description];
  if(!name.length)name=[NSString stringWithFormat:@"Stopa %lu",(unsigned long)(i+1)];
  NSString*item=[NSString stringWithFormat:@"%@%@",ident==current?@"✓  ":@"",name];
  [sheet addAction:[UIAlertAction actionWithTitle:item style:UIAlertActionStyleDefault handler:^(UIAlertAction*x){
   self->vlc.currentAudioTrackIndex=ident;
   [self setControls:YES schedule:YES];
  }]];
 }
 [sheet addAction:[UIAlertAction actionWithTitle:@"Zrušiť" style:UIAlertActionStyleCancel handler:^(UIAlertAction*x){[self setControls:YES schedule:YES];}]];
 [self presentViewController:sheet animated:YES completion:nil];
}
-(void)chooseRate{
 [self setControls:YES schedule:NO];
 UIAlertController*sheet=[UIAlertController alertControllerWithTitle:@"Rýchlosť prehrávania" message:@"Pri vysokých rýchlostiach môže starší iPad vynechávať obraz alebo zvuk." preferredStyle:UIAlertControllerStyleAlert];
 NSArray*rates=@[@0.25,@0.5,@0.75,@1,@1.25,@1.5,@2,@3,@4,@6,@8,@12,@16,@24,@32,@40];
 for(NSNumber*r in rates){
  float rate=r.floatValue;
  NSString*name=[NSString stringWithFormat:@"%@  %g×",fabsf(rate-chosenRate)<0.01f?@"✓":@"",rate];
  [sheet addAction:[UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault handler:^(UIAlertAction*x){
   self->chosenRate=rate;self->vlc.rate=rate;[[NSUserDefaults standardUserDefaults]setFloat:rate forKey:@"nebulaRate"];
   [self->speedBtn setTitle:[NSString stringWithFormat:@"%g× RÝCHL.",rate] forState:UIControlStateNormal];
   [self setControls:YES schedule:YES];
  }]];
 }
 [sheet addAction:[UIAlertAction actionWithTitle:@"Zrušiť" style:UIAlertActionStyleCancel handler:^(UIAlertAction*x){[self setControls:YES schedule:YES];}]];
 [self presentViewController:sheet animated:YES completion:nil];
}

#pragma mark - Nebula V5 advanced controls
-(void)showSettings{
 [self setControls:YES schedule:NO];
 UIAlertController*m=[UIAlertController alertControllerWithTitle:@"NEBULA MEDIA V5 – NASTAVENIA" message:@"Pokročilé ovládanie prehrávania cez VLC" preferredStyle:UIAlertControllerStyleAlert];
 NSArray*labels=@[@"▤ Titulky – výber stopy",@"＋ Načítať titulky zo súboru",@"▣ Pomer strán a orez",@"♫ Zvukové stopy",@"◉ Ekvalizér",@"⏱ Synchronizácia zvuku",@"⏱ Synchronizácia titulkov",@"↻ Opakovanie / ďalšia stopa",@"☾ Časovač vypnutia",@"ⓘ Informácie o médiu"];
 SEL actions[]={@selector(chooseSubtitles),@selector(importSubtitle),@selector(chooseAspect),@selector(chooseAudioTrack),@selector(chooseEqualizer),@selector(audioDelayMenu),@selector(subtitleDelayMenu),@selector(repeatMenu),@selector(sleepMenu),@selector(showMediaInfo)};
 for(NSUInteger i=0;i<labels.count;i++){
  SEL action=actions[i];
  [m addAction:[UIAlertAction actionWithTitle:labels[i] style:UIAlertActionStyleDefault handler:^(UIAlertAction*x){
    [self performSelector:action];
  }]];
 }
 [m addAction:[UIAlertAction actionWithTitle:@"Zavrieť" style:UIAlertActionStyleCancel handler:^(UIAlertAction*x){[self setControls:YES schedule:YES];}]];
 [self presentViewController:m animated:YES completion:nil];
}
-(void)chooseSubtitles{
 NSArray*names=vlc.videoSubTitlesNames,*indexes=vlc.videoSubTitlesIndexes;
 NSUInteger n=MIN(names.count,indexes.count);
 if(n==0){A(self,@"Titulky",@"V tomto videu nie sú dostupné vstavané titulky. Skús načítať externý súbor.");return;}
 UIAlertController*m=[UIAlertController alertControllerWithTitle:@"Titulky" message:@"Zvoľ jazyk alebo vypni titulky" preferredStyle:UIAlertControllerStyleAlert];
 int current=vlc.currentVideoSubTitleIndex;
 for(NSUInteger i=0;i<n;i++){
  int track=[indexes[i] intValue];
  NSString*name=[names[i] description];
  if(name.length==0)name=[NSString stringWithFormat:@"Titulky %lu",(unsigned long)i];
  NSString*label=[NSString stringWithFormat:@"%@%@",track==current?@"✓  ":@"",name];
  [m addAction:[UIAlertAction actionWithTitle:label style:UIAlertActionStyleDefault handler:^(UIAlertAction*x){self->vlc.currentVideoSubTitleIndex=track;[self setControls:YES schedule:YES];}]];
 }
 [m addAction:[UIAlertAction actionWithTitle:@"Vypnúť titulky" style:UIAlertActionStyleDefault handler:^(UIAlertAction*x){self->vlc.currentVideoSubTitleIndex=-1;}]];
 [m addAction:[UIAlertAction actionWithTitle:@"Späť" style:UIAlertActionStyleCancel handler:nil]];
 [self presentViewController:m animated:YES completion:nil];
}
-(void)importSubtitle{
 subtitleImportMode=YES;
 UIDocumentPickerViewController*p=[[UIDocumentPickerViewController alloc]initWithDocumentTypes:@[@"public.text",@"public.data"] inMode:UIDocumentPickerModeImport];
 p.delegate=self;p.modalPresentationStyle=UIModalPresentationFormSheet;[self presentViewController:p animated:YES completion:nil];
}
-(void)documentPickerWasCancelled:(UIDocumentPickerViewController*)p{subtitleImportMode=NO;}
-(void)chooseAspect{
 UIAlertController*m=[UIAlertController alertControllerWithTitle:@"Zobrazenie videa" message:@"Originál / vyplniť / roztiahnuť alebo pevný pomer" preferredStyle:UIAlertControllerStyleAlert];
 NSArray*names=@[@"Originálny pomer",@"Vyplniť obrazovku (orez)",@"Roztiahnuť na celú obrazovku",@"16:9",@"4:3",@"21:9",@"1:1",@"2.35:1"];
 for(NSUInteger i=0;i<names.count;i++){
  NSUInteger choice=i;
  [m addAction:[UIAlertAction actionWithTitle:names[i] style:UIAlertActionStyleDefault handler:^(UIAlertAction*x){
    if(choice<3){self->screenMode=choice;self->forcedAspect=nil;}
    else{self->screenMode=0;self->forcedAspect=names[choice];}
    [self updateVideoRatio];[self setControls:YES schedule:YES];
  }]];
 }
 [m addAction:[UIAlertAction actionWithTitle:@"Späť" style:UIAlertActionStyleCancel handler:nil]];
 [self presentViewController:m animated:YES completion:nil];
}
-(void)chooseEqualizer{
 NSArray*profiles=vlc.equalizerProfiles?:@[];
 UIAlertController*m=[UIAlertController alertControllerWithTitle:@"Audio ekvalizér" message:vlc.equalizerEnabled?@"Ekvalizér je zapnutý":@"Ekvalizér je vypnutý" preferredStyle:UIAlertControllerStyleAlert];
 [m addAction:[UIAlertAction actionWithTitle:@"Vypnúť (pôvodný zvuk)" style:UIAlertActionStyleDefault handler:^(UIAlertAction*x){self->vlc.equalizerEnabled=NO;}]];
 for(NSUInteger i=0;i<profiles.count;i++){
  NSUInteger selected=i;
  NSString*name=[profiles[i] description];
  [m addAction:[UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault handler:^(UIAlertAction*x){
   self->vlc.equalizerEnabled=YES;[self->vlc resetEqualizerFromProfile:(unsigned)selected];
  }]];
 }
 [m addAction:[UIAlertAction actionWithTitle:@"Späť" style:UIAlertActionStyleCancel handler:nil]];
 [self presentViewController:m animated:YES completion:nil];
}
-(void)audioDelayMenu{[self delayMenu:NO];}
-(void)subtitleDelayMenu{[self delayMenu:YES];}
-(void)delayMenu:(BOOL)isSubtitle{
 NSInteger current=isSubtitle?vlc.currentVideoSubTitleDelay:vlc.currentAudioPlaybackDelay;
 UIAlertController*m=[UIAlertController alertControllerWithTitle:isSubtitle?@"Synchronizácia titulkov":@"Synchronizácia zvuku" message:[NSString stringWithFormat:@"Aktuálne oneskorenie: %+0.2f s",(double)current/1000000.0] preferredStyle:UIAlertControllerStyleAlert];
 NSArray*values=@[@(-500),@(-250),@(-100),@(0),@(100),@(250),@(500)];
 for(NSNumber*n in values){
  NSInteger ms=n.integerValue;
  NSString*label=ms==0?@"Vynulovať": [NSString stringWithFormat:@"%+ld ms",(long)ms];
  [m addAction:[UIAlertAction actionWithTitle:label style:UIAlertActionStyleDefault handler:^(UIAlertAction*x){
   NSInteger dest=(ms==0)?0:(current+ms*1000);
   if(isSubtitle)self->vlc.currentVideoSubTitleDelay=dest;else self->vlc.currentAudioPlaybackDelay=dest;
  }]];
 }
 [m addAction:[UIAlertAction actionWithTitle:@"Späť" style:UIAlertActionStyleCancel handler:nil]];
 [self presentViewController:m animated:YES completion:nil];
}
-(void)repeatMenu{
 UIAlertController*m=[UIAlertController alertControllerWithTitle:@"Režim prehrávania" message:@"Automatické pokračovanie a opakovanie súboru" preferredStyle:UIAlertControllerStyleAlert];
 NSString*one=[NSString stringWithFormat:@"%@ Opakovať aktuálny súbor",repeatOne?@"✓":@"○"];
 NSString*next=[NSString stringWithFormat:@"%@ Automaticky ďalší súbor",autoplayNext?@"✓":@"○"];
 [m addAction:[UIAlertAction actionWithTitle:one style:UIAlertActionStyleDefault handler:^(UIAlertAction*x){self->repeatOne=!self->repeatOne;[[NSUserDefaults standardUserDefaults]setBool:self->repeatOne forKey:@"nebulaRepeatOne"];}]];
 [m addAction:[UIAlertAction actionWithTitle:next style:UIAlertActionStyleDefault handler:^(UIAlertAction*x){self->autoplayNext=!self->autoplayNext;[[NSUserDefaults standardUserDefaults]setBool:self->autoplayNext forKey:@"nebulaAutoNext"];}]];
 [m addAction:[UIAlertAction actionWithTitle:@"Späť" style:UIAlertActionStyleCancel handler:nil]];
 [self presentViewController:m animated:YES completion:nil];
}
-(void)sleepMenu{
 UIAlertController*m=[UIAlertController alertControllerWithTitle:@"Časovač vypnutia" message:@"Prehrávanie sa automaticky zastaví" preferredStyle:UIAlertControllerStyleAlert];
 [m addAction:[UIAlertAction actionWithTitle:@"Vypnúť časovač" style:UIAlertActionStyleDefault handler:^(UIAlertAction*x){[self->sleepTimer invalidate];self->sleepTimer=nil;}]];
 for(NSNumber*minutes in @[@15,@30,@45,@60,@90,@120]){
  NSInteger amount=minutes.integerValue;
  [m addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%ld minút",(long)amount] style:UIAlertActionStyleDefault handler:^(UIAlertAction*x){
   [self->sleepTimer invalidate];self->sleepTimer=[NSTimer scheduledTimerWithTimeInterval:amount*60 target:self selector:@selector(sleepTimerFired) userInfo:nil repeats:NO];
   [self showSwipeValue:[NSString stringWithFormat:@"☾ Časovač %ld min",(long)amount]];
  }]];
 }
 [m addAction:[UIAlertAction actionWithTitle:@"Späť" style:UIAlertActionStyleCancel handler:nil]];
 [self presentViewController:m animated:YES completion:nil];
}
-(void)sleepTimerFired{[sleepTimer invalidate];sleepTimer=nil;[self stopPlayback];A(self,@"Časovač",@"Prehrávanie bolo zastavené.");}
-(void)showMediaInfo{
 CGSize size=vlc.videoSize;
 NSString*msg=[NSString stringWithFormat:@"Súbor: %@\nRozlíšenie: %.0f × %.0f\nRýchlosť: %g×\nZvukové stopy: %lu\nTitulkové stopy: %lu\nAuto ďalší: %@\nOpakovať: %@",currentPath.lastPathComponent?:@"—",size.width,size.height,chosenRate,(unsigned long)vlc.audioTrackNames.count,(unsigned long)vlc.videoSubTitlesNames.count,autoplayNext?@"Áno":@"Nie",repeatOne?@"Áno":@"Nie"];
 A(self,@"Informácie o prehrávaní",msg);
}

-(UISlider*)findVolumeSlider:(UIView*)view{
 if([view isKindOfClass:UISlider.class])return(UISlider*)view;
 for(UIView*subview in view.subviews){UISlider*s=[self findVolumeSlider:subview];if(s)return s;}
 return nil;
}
-(void)showSwipeValue:(NSString*)s{
 swipeIndicator.text=s;swipeIndicator.hidden=NO;
 [playerScreen bringSubviewToFront:swipeIndicator];
 [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideSwipeIndicator) object:nil];
 [self performSelector:@selector(hideSwipeIndicator) withObject:nil afterDelay:1.0];
}
-(void)hideSwipeIndicator{swipeIndicator.hidden=YES;}
-(void)verticalSwipe:(UIPanGestureRecognizer*)g{
 CGPoint pt=[g locationInView:videoSurface];
 if(g.state==UIGestureRecognizerStateBegan){
  touchStartY=pt.y;swipeIsBrightness=pt.x<videoSurface.bounds.size.width*0.5;
  startBrightness=UIScreen.mainScreen.brightness;
  volumeSlider=[self findVolumeSlider:volumeView];
  startVolume=volumeSlider?volumeSlider.value:0;
 }else if(g.state==UIGestureRecognizerStateChanged){
  CGFloat change=(touchStartY-pt.y)/MAX(120.0,videoSurface.bounds.size.height*0.70);
  if(swipeIsBrightness){
   CGFloat value=MAX(0.02,MIN(1.0,startBrightness+change));
   UIScreen.mainScreen.brightness=value;
   [self showSwipeValue:[NSString stringWithFormat:@"☀ Jas %d%%",(int)round(value*100)]];
  }else if(volumeSlider){
   float value=MAX(0.f,MIN(1.f,startVolume+change));
   [volumeSlider setValue:value animated:NO];
   [volumeSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
   [self showSwipeValue:[NSString stringWithFormat:@"♫ Hlasitosť %d%%",(int)round(value*100)]];
  }else{
   [self showSwipeValue:@"Hlasitosť nie je dostupná"];
  }
 }else if(g.state==UIGestureRecognizerStateEnded||g.state==UIGestureRecognizerStateCancelled){
  [self setControls:controlsVisible schedule:YES];
 }
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
  }else if(self->vlc.state==VLCMediaPlayerStateEnded&&!self->playerScreen.hidden){
   if(self->repeatOne&&self->currentPath.length)[self playPath:self->currentPath];
   else if(self->autoplayNext&&self->playlist.count>0&&self->playingIndex!=NSNotFound&&self->playingIndex+1<self->playlist.count)[self step:1];
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
 if(subtitleImportMode){
  subtitleImportMode=NO;
  NSString*ext=u.pathExtension.lowercaseString;
  if(![@[@"srt",@"ass",@"ssa",@"sub",@"vtt",@"txt"] containsObject:ext]){A(self,@"Nepodporované titulky",@"Vyber SRT, ASS, SSA, SUB alebo VTT.");return;}
  NSString*dir=[Shared() stringByAppendingPathComponent:@"Titulky"];[[NSFileManager defaultManager]createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
  NSString*target=[dir stringByAppendingPathComponent:u.lastPathComponent];
  if(![[NSFileManager defaultManager]fileExistsAtPath:target]){
    NSError*err=nil;if(![[NSFileManager defaultManager]copyItemAtURL:u toURL:[NSURL fileURLWithPath:target] error:&err]){A(self,@"Import titulkov zlyhal",err.localizedDescription);return;}
  }
  BOOL ok=[vlc openVideoSubTitlesFromFile:target];A(self,ok?@"Titulky pridané":@"Titulky sa nepodarilo načítať",ok?target:@"Skontroluj formát a prebiehajúce prehrávanie.");return;
 }
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
