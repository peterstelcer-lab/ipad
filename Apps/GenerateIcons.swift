import AppKit
import Foundation

let root = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "build"
let aqua = NSColor(calibratedRed:0.11,green:0.90,blue:0.91,alpha:1)
let white = NSColor(calibratedRed:0.95,green:0.97,blue:1,alpha:1)
let red = NSColor(calibratedRed:0.96,green:0.09,blue:0.14,alpha:1)
func rgb(_ r:CGFloat,_ g:CGFloat,_ b:CGFloat,_ a:CGFloat=1)->NSColor {return NSColor(calibratedRed:r,green:g,blue:b,alpha:a)}
func rounded(_ r:NSRect,_ radius:CGFloat,_ fill:NSColor,_ stroke:NSColor?=nil,_ sw:CGFloat=2){
 let p=NSBezierPath(roundedRect:r,xRadius:radius,yRadius:radius)
 fill.setFill();p.fill()
 if let c=stroke{c.setStroke();p.lineWidth=sw;p.stroke()}
}
func oval(_ r:NSRect,_ fill:NSColor,_ stroke:NSColor?=nil,_ sw:CGFloat=2){
 let p=NSBezierPath(ovalIn:r);fill.setFill();p.fill()
 if let c=stroke{c.setStroke();p.lineWidth=sw;p.stroke()}
}
func poly(_ pts:[NSPoint],_ fill:NSColor,_ stroke:NSColor?=nil,_ sw:CGFloat=2){
 guard pts.count>2 else{return}
 let p=NSBezierPath();p.move(to:pts[0])
 for v in pts.dropFirst(){p.line(to:v)};p.close()
 fill.setFill();p.fill()
 if let c=stroke{c.setStroke();p.lineWidth=sw;p.stroke()}
}
func stroke(_ pts:[NSPoint],_ col:NSColor,_ width:CGFloat){
 guard let first=pts.first else{return}
 let p=NSBezierPath();p.move(to:first)
 for pt in pts.dropFirst(){p.line(to:pt)}
 p.lineWidth=width;p.lineJoinStyle = .round;p.lineCapStyle = .round;col.setStroke();p.stroke()
}
func makeIcon(_ kind:String){
 let size:NSSize=NSSize(width:256,height:256)
 let im=NSImage(size:size)
 im.lockFocus()
 let bounds=NSRect(origin:.zero,size:size)
 let youtube=(kind=="YouTube")
 let milling=(kind=="NUM1040")
 let edge=youtube?red:aqua
 let gradient=NSGradient(colors:youtube?[rgb(0.35,0.025,0.045),rgb(0.05,0.012,0.024)]:[rgb(0.015,0.21,0.27),rgb(0.015,0.055,0.08)])!
 gradient.draw(in:bounds,angle:95)
 rounded(NSRect(x:9,y:9,width:238,height:238),43,rgb(0.012,0.07,0.10,0.48),edge,7)
 rounded(NSRect(x:21,y:21,width:214,height:214),29,youtube?rgb(0.22,0.015,0.034):rgb(0.022,0.10,0.13),edge.withAlphaComponent(0.28),2)
 if youtube {
  rounded(NSRect(x:41,y:62,width:174,height:133),25,rgb(0.07,0.012,0.025),rgb(0.86,0.87,0.92),6)
  let triangle=[NSPoint(x:104,y:93),NSPoint(x:104,y:167),NSPoint(x:169,y:130)]
  poly(triangle,white)
  rounded(NSRect(x:53,y:73,width:149,height:9),4,rgb(0.36,0.39,0.44))
  rounded(NSRect(x:53,y:73,width:87,height:9),4,red)
  oval(NSRect(x:134,y:68,width:18,height:18),white)
 }else if milling {
  // Frézovací nástroj, rezná dráha a obrobok – rovnaká vizuálna rodina ako sústruh.
  rounded(NSRect(x:45,y:53,width:166,height:56),5,rgb(0.32,0.47,0.54),rgb(0.65,0.83,0.87),2)
  poly([NSPoint(x:61,y:107),NSPoint(x:61,y:138),NSPoint(x:111,y:138),NSPoint(x:111,y:121),NSPoint(x:162,y:121),NSPoint(x:162,y:107)],rgb(0.36,0.59,0.67),aqua,3)
  rounded(NSRect(x:108,y:160,width:40,height:39),6,rgb(0.64,0.70,0.74),white,3)
  rounded(NSRect(x:119,y:115,width:19,height:49),4,rgb(0.50,0.60,0.64),aqua,2)
  for n in 0..<4{let y:CGFloat=121+CGFloat(n)*10;stroke([NSPoint(x:120,y:y),NSPoint(x:137,y:y+8)],rgb(0.04,0.22,0.30),3)}
  stroke([NSPoint(x:51,y:73),NSPoint(x:93,y:73),NSPoint(x:93,y:89),NSPoint(x:174,y:89),NSPoint(x:174,y:100)],aqua,4)
  oval(NSRect(x:162,y:99,width:17,height:17),aqua)
 }else{
  // Sústružnícka hlava a stupňovitý rotačný diel.
  oval(NSRect(x:33,y:73,width:85,height:122),rgb(0.43,0.55,0.61),rgb(0.77,0.88,0.92),4)
  oval(NSRect(x:50,y:88,width:50,height:92),rgb(0.02,0.09,0.13),aqua,2)
  poly([NSPoint(x:77,y:100),NSPoint(x:77,y:169),NSPoint(x:123,y:169),NSPoint(x:123,y:151),NSPoint(x:150,y:151),NSPoint(x:150,y:134),NSPoint(x:179,y:134),NSPoint(x:179,y:113),NSPoint(x:210,y:113),NSPoint(x:210,y:100)],rgb(0.34,0.57,0.65),aqua,4)
  poly([NSPoint(x:170,y:223),NSPoint(x:213,y:223),NSPoint(x:211,y:188),NSPoint(x:188,y:166),NSPoint(x:174,y:186)],rgb(0.60,0.67,0.70),white,2)
  poly([NSPoint(x:174,y:183),NSPoint(x:190,y:164),NSPoint(x:185,y:191)],rgb(0.98,0.68,0.17),rgb(0.95,0.77,0.3),2)
  stroke([NSPoint(x:75,y:99),NSPoint(x:211,y:99)],aqua,2)
 }
 im.unlockFocus()
 let outDir=URL(fileURLWithPath:root).appendingPathComponent(kind).appendingPathComponent("Applications").appendingPathComponent(kind=="AlphaLink"?"AlphaLinkiPad.app":kind=="NUM1040"?"NUM1040Transfer.app":"YouTubeWebiPad.app")
 try! FileManager.default.createDirectory(at:outDir,withIntermediateDirectories:true)
 let bitmap=NSBitmapImageRep(data:im.tiffRepresentation!)!
 for (name,n) in [("AppIcon76.png",76),("AppIcon76@2x.png",152),("AppIcon83.5@2x.png",167)]{
  let resized=NSImage(size:NSSize(width:n,height:n))
  resized.lockFocus()
  NSGraphicsContext.current?.imageInterpolation = .high
  im.draw(in:NSRect(x:0,y:0,width:n,height:n),from:NSRect(x:0,y:0,width:256,height:256),operation:.copy,fraction:1)
  resized.unlockFocus()
  let repr=NSBitmapImageRep(data:resized.tiffRepresentation!)!
  let png=repr.representation(using:.png,properties:[:])!
  try! png.write(to:outDir.appendingPathComponent(name))
 }
 _ = bitmap
}
for x in ["AlphaLink","NUM1040","YouTube"] {makeIcon(x)}
print("Created three icon families at 76/152/167 pixels.")
