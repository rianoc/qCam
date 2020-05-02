\l qCam.q

width:640;
height:480;
pixelformat:`RGB3;

//Start the camera
camera:startcamera[width;height;pixelformat];

//Create the prototype dictionary
colourPic:`encoding`width`height`maxval`data!(`P6;width;height;255;());

//Grab a frame from the camera
colourPic[`data]:snap[camera;3*colourPic[`width]*colourPic[`height]];

saveppm[`:test/1_colour;colourPic];

greyPic:greyscale[colourPic];

savepgm[`:test/2_grey;greyPic];

rotatedPic:rotatePic[greyPic;2];

savepgm[`:test/3_rotate;rotatedPic];

croppedPic:crop[greyPic;greyPic[`height]-1;greyPic[`width]-1;`int$-1*greyPic[`height]%2;`int$-1*greyPic[`width]%2];

savepgm[`:test/4_crop;croppedPic];

zoomedPic:zoom[greyPic;100];

savepgm[`:test/5_zoom;zoomedPic];

resizedPic:resize[greyPic;2];

savepgm[`:test/6_resize;resizedPic];

//Define kernel to test convolute function
kernel:((0 1 0f);(1 -4 1f);(0 1 0f));

//Apply convolution function
convolutedPic:convolute[greyPic;kernel];

savepgm[`:test/7_convolute;@[;`data;`byte$] convolutedPic];

//Adjust values so that there are no negative values
normalisedPic:normalise[convolutedPic;0;255];

savepgm[`:test/8_normalise;@[;`data;`byte$] normalisedPic];

textPic:makePGM draw arialBold "This is a test";

savepgm[`:test/9_text;@[;`data;`byte$] textPic];

savepgm[`:test/10_overlay] overlay[textPic;greyPic;50;floor %[;2] greyPic[`width]-textPic[`width]];

\cd test

{system"convert ",x," ",(first "." vs x),".jpg"} each string key `:.;

exit 0
