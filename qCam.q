\l arialBold.q

//Starts the camera
startcamera:{[width;height;pixelformat]
  //Start the driver which creates /dev/video0
  system"modprobe bcm2835-v4l2";
  //Start the camera
  system"v4l2-ctl -v width=",string[width],",height=",string[height],",pixelformat=",string[pixelformat];
  //Return a handle to the named pipe
  hopen`:fifo:///dev/video0
 };

//Snap returns a byte list of image data
snap:{[handle;size]
 picture:();
 while[65536~count read1 handle;`];
 while[(size-65536) >= count picture,:read1 handle;`];
 :picture,:read1 handle
 };

//Saves a ppm as a P6 encoded RGB image to disk
saveppm:{[filename;pic]
 hsym[`$"." sv string filename,`ppm] 1:
 string[pic`encoding],"\n",(" " sv string pic`width`height`maxval),"\n","c"$pic[`data];
 };

//Converts our image to greyscale
//Updates the encoding from P6 to P5
greyscale:{[pic]
 pic[`encoding]:`P5;
 pic[`data]:"x"$floor avg peach 3 cut `int$pic[`data];
 pic
 }

//Saves pgm saves a P5 encoded greyscale image to disk
savepgm:{[filename;pic]
 hsym[`$"." sv string filename,`pgm] 1:
 string[pic`encoding],"\n",(" " sv string pic`width`height`maxval),"\n",
 "c"$pic`data;
 };

rotatePic:{[pic;times]
 img:pic[`width] cut pic[`data];
 do[times;img: reverse flip img];
 pic[`data]:raze img;pic
 };

crop:{[pic;startX;startY;takeX;takeY]
 x:$[0<takeX;til takeX;-1* til abs takeX];
 y:$[0<takeY;til takeY;-1* til abs takeY];
 pic[`data]:raze "x"$(pic[`width] cut `int$pic`data)[asc startX+x;asc startY+y];
 pic[`height]:abs takeX;
 pic[`width]:abs takeY;
 pic
 };

//Zooms in an image
zoom:{[pic;pixels] crop[pic;pixels-1;pixels-1;
 -1+pic[`height]-pixels*2;-1+pic[`width]-pixels*2]
 };

//Resize an image by k pixels
resize:{[pic;k]
 pic[`width]-:k; pic[`height]-:k; k+:1;
 x: til[(count pic[`data])-pic[`width]]; y:til k;
 pic[`data]:avg peach (k*k) cut raze
 {[x;y;z;k] z[`data][(x + y*z`width) + til k]}[;;pic;k] .' x cross y;
 pic[`data]:"x"$raze `int$floor _[1-k] peach
 pic[`width] cut pic`data;
 pic
 };

//Applies a specific kernel to the image
convolute:{[pic;kernel]
 pic[`data]:"f"$pic[`data];
 pic[`data]:{[y;kernel;pic]
  (raze kernel)$(raze (pic[`data][y+til (count kernel)];
  pic[`data][(y+pic[`width])+til (count kernel)];
  pic[`data][(y+2*pic[`width])+til (count kernel)]))
 }[;kernel;pic] peach til count pic[`data];
 pic
 };

//Normalises pixel values to within certain range
normalise:{[pic;lowerB;upperB]
 pixels:`int$pic[`data];
 c:min pixels;
 d:max pixels;
 pic[`data]:"x"${[x;c;d;b;a]((x-c)*((b-a)%(d-c)))+a}[;c;d;upperB;lowerB] peach pixels;
 pic
 };

drawSingle:{
 x:raze {x:vs[2;x];(count[x]_8#0),x} peach x;
 16 cut @[x;where x=0;:;0N]
 };

draw:{
 raze peach flip drawSingle peach x
 };

makePGM:{
 `encoding`width`height`maxval`data!(`P5;count x[0];count x;max raze x;raze x)
 };

overlay:{[img;bk;xCoor;yCoor]
 imgPix:img[`width] cut `int$img[`data];
 imgPix:((bk[`width]-(yCoor+img[`width]))#0N){y,x}/:(yCoor#0N),/: imgPix;
 imgPix:(xCoor#enlist bk[`width]#0N),imgPix,((bk[`height]-(xCoor+img[`height]))#enlist bk[`width]#0N);
 bk[`data]:`byte${@[x;where not y=0N;:;y where not y=0N]}[`int$bk[`data];raze imgPix];
 bk
 };
