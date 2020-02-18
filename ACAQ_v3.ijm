/*
Created on Wed June 14 14:43:49 2017

@author: Zoltan Cseresnyes
@affiliation: Research Group Applied Systems Biology, Leibniz Institute for 
Natural Product Research and Infection Biology – Hans Knöll Institute (HKI),
Beutenbergstrasse 11a, 07745 Jena, Germany.
@email: zoltan.cseresnyes@leibniz-hki.de or zcseresn@gmail.com
For advice and rights, please contact via
@email: thilo.figge@leibniz-hki.de

This is an implementation of the Hessian-based algorithm for macrophage segmentation.The 
full details of the work can be found in Cseresnyes et al. (2017), Hessian-based quantitative image analysis of host-pathogen confrontation assays, 
Cytometry A, currently under revision 
 If any part of the code is used for academic purposes or publications, please cite the 
above mentioned paper.

Copyright (c) 2016-2017, 
Leibniz Institute for Natural Product Research and Infection Biology – 
Hans Knöll Institute (HKI)

Licence: BSD-3-Clause, see ./LICENSE or 
https://opensource.org/licenses/BSD-3-Clause for full details

__version__ = "ACAQ-v3"

*/

versionNumber="ACAQ-v3";

function dateAndTime(){
	MonthNames = newArray("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
    DayNames = newArray("Sun", "Mon","Tue","Wed","Thu","Fri","Sat");
    getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	TimeString ="Date: "+DayNames[dayOfWeek]+" ";
	if (dayOfMonth<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+dayOfMonth+"-"+MonthNames[month]+"-"+year+"\nTime: ";
	if (hour<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+hour+":";
	if (minute<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+minute+":";
	if (second<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+second;
	return TimeString;
}

function getTag(tag) {
      info = getImageInfo();
      index1 = indexOf(info, tag);
      if (index1==-1) return "";
      index1 = indexOf(info, ":", index1);
      if (index1==-1) return "";
      index2 = indexOf(info, "\n", index1);
      value = substring(info, index1+2, index2);
      return value;
  }

function isElement(element, array) {
      value = false;
      for(i=0; i<array.length;i++){
      	if(element == array[i]){
      		value = true;
      	}
      }
      return value;
  }

print("Macrophages and Spores Analyser " + versionNumber);
print("**********************************************");
print(dateAndTime());
print(" ");
run("Clear Results");

//Initialize counters: 
nROI_greenSpores = 0;
nROI_spores = 0;
nROI_macrophages = 0;
nROI_blueSpores = 0;
nROI_greenSporesInside = 0;
nROI_greenSporesOutside = 0;
nROI_greenSpores_BrightSpots = 0;
//end of counter initialization

//start of Dialog box 0:
Dialog.create("Macrophages_Spores_Analyser_" + versionNumber + ": Dialog 0");
Dialog.addMessage(versionNumber + ": Macrophages and Spores Analyser ; Dialog 0");
Dialog.addCheckbox("Re-stiching Zeiss .lsm?", true);
Dialog.addCheckbox("Using Hanno and Kaswara format?", false);
Dialog.addCheckbox("Read multi-channel TIFF?", false);
Dialog.addCheckbox("Use MAX Hessian instead? (default: MIN)", false);
Dialog.addCheckbox("Do you want to save your results?", true);
Dialog.addCheckbox("Use subfolders?", false);
Dialog.addCheckbox("Analyse all images?", true);
Dialog.addCheckbox("Close all windows at end?", true);
Dialog.addCheckbox("Run it in Batch Mode?", false);
Dialog.addCheckbox("Illumination correction for TL images?", true);
Dialog.addNumber("Line thickness for ROIs?",0);
Dialog.addNumber("X tile number?",3);
Dialog.addNumber("Y tile number?",3);
Dialog.addNumber("Gaussian sigma for illumunation correction?",10);
Dialog.addNumber("Hessian smoothing factor for macrophages?",2);
Dialog.addNumber("Hessian smoothing factor for spores?",1);
Dialog.addNumber("Gaussian smoothing factor for macrophages?",5);
Dialog.addNumber("Gaussian smoothing factor for TL spores?",1);
Dialog.addNumber("Dilate/erode steps for macrophages?",2);
Dialog.addNumber("Additional erosion steps for macrophages?",3);
Dialog.addNumber("Dilate/erode steps for spores?",1);
Dialog.addNumber("Gaussian smoothing factor for fluorescence spores?",2);
Dialog.addNumber("Lower threshold multiplier for spores (only for Internal Gradient)?",1.0);
Dialog.addNumber("Upper threshold multiplier for spores (only for Internal Gradient)?",1.125);
Dialog.addNumber("Lower threshold multiplier for macrophages (only for Mohamed's Egyptian strain, try 0.6)?",1.00);
Dialog.addNumber("Upper threshold multiplier for macrophages (only for Mohamed's Egyptian strain)?",1.00);
Dialog.show();

rearrangeZeiss=Dialog.getCheckbox();
useHannoKaswaraFormat=Dialog.getCheckbox();
useMultichannelTiffFormat=Dialog.getCheckbox();
useMAXHessian=Dialog.getCheckbox();
saveResults=Dialog.getCheckbox();
useSubfolders=Dialog.getCheckbox();
analyseAllImages=Dialog.getCheckbox();
closeAllWindows=Dialog.getCheckbox();
runInBatchMode=Dialog.getCheckbox();
correctIlluminationForTL=Dialog.getCheckbox();
lineThicknessForObjects=Dialog.getNumber();
XTileNumber=Dialog.getNumber();
YTileNumber=Dialog.getNumber();
illuminationCorrectionSigmaForTL=Dialog.getNumber();
hessianSmoothingForMacrophages=Dialog.getNumber();
hessianSmoothingForSpores=Dialog.getNumber();
gaussianSmoothingForMacrophages=Dialog.getNumber();
gaussianSmoothingForSpores=Dialog.getNumber();
dilateErodeStepsForMacrophages=Dialog.getNumber();
additionalErodeStepsForMacrophages=Dialog.getNumber();
dilateErodeStepsForSpores=Dialog.getNumber();
gaussianBlurForSpores=Dialog.getNumber();
lowerThresholdMultiplier=Dialog.getNumber();
upperThresholdMultiplier=Dialog.getNumber();
lowerThresholdMultiplierMacrophages=Dialog.getNumber();
upperThresholdMultiplierMacrophages=Dialog.getNumber();
//end of Dialog box 0

//start of Dialog box 1:
Dialog.create("Macrophages_Spores_Analyser_" + versionNumber + ": Dialog 1");
Dialog.addMessage(versionNumber + ": Macrophages and Spores Analyser ; Dialog 1");
Dialog.addCheckbox("Exclude edges?", false);
Dialog.addCheckbox("Gather results for entire image set?", false);
Dialog.addCheckbox("Use image file name for results?", true);
Dialog.addCheckbox("Use specific image groups based on filename?", false);
Dialog.addString("Image type: ", ".lsm");
Dialog.addString("Search term #1: ", "");
Dialog.addString("Search term #2: ", "");
Dialog.addString("Search term #3: ", "");
Dialog.addString("Exclude term #1: ", "   ");
Dialog.addString("Exclude term #2: ", "   ");
Dialog.addString("Exclude term #3: ", "   ");
Dialog.addString("Name tag of saved files: ", "");
Dialog.addNumber("Background image number?",1);
Dialog.addNumber("First image number?",1);
Dialog.addNumber("Last image number?",1);
Dialog.addNumber("Test image number?",1);
Dialog.addNumber("Edge width (for Exclude Edges option)?",5);
Dialog.addNumber("Kaswara multiplier for phagocytosed conidia (try 1.125)?",1.0);
Dialog.addNumber("Kaswara multiplier for adherent conidia (try 1.333)?",1.0);
Dialog.addNumber("Green channel multiplier for dim image data (try 2)?",2);
Dialog.addNumber("Blue channel multiplier for dim image data (left at 1)?",1);

Dialog.show();

excludeEdges=Dialog.getCheckbox();
gatherResultsForEntireImageSet=Dialog.getCheckbox();
useImageFilename=Dialog.getCheckbox();
useSpecificImageGroups=Dialog.getCheckbox();
imageType=Dialog.getString();
searchTerm_1=Dialog.getString();
searchTerm_2=Dialog.getString();
searchTerm_3=Dialog.getString();
excludeTerm_1=Dialog.getString();
excludeTerm_2=Dialog.getString();
excludeTerm_3=Dialog.getString();
nameTagSavedFiles=Dialog.getString();
backgroundImageNumber=Dialog.getNumber();
firstImageNumber=Dialog.getNumber();
lastImageNumber=Dialog.getNumber();
testImageNumber=Dialog.getNumber();
edgeWidth=Dialog.getNumber();
multiplierPhagocytosedConidia=Dialog.getNumber();//this accounts for Kaswara's more lenient spore finder algo
multiplierAdherentConidia=Dialog.getNumber();//this accounts for Kaswara's more lenient spore finder algo
greenChannelMultiplierForDimData=Dialog.getNumber();
blueChannelMultiplierForDimData=Dialog.getNumber();
//end of Dialog box 1

//Start of Dialog box, #2:
Dialog.create("Macrophages_Spores_Analyser_" + versionNumber + ": Dialog 2");
Dialog.addMessage(versionNumber + ": Macrophages and Spores Analyser ; Dialog 2"); 
Dialog.addCheckbox("Watershed on macrophages?", true);
Dialog.addCheckbox("Watershed on spores?", true);
Dialog.addCheckbox("CLAHE on TL?", false);
Dialog.addCheckbox("CLAHE on FLSC?", true);
Dialog.addCheckbox("Combine Internal Gradient and Bright Spot results?", false);
Dialog.addNumber("Internal Gradient radius for green spores (try 2; use 0 for No)?", 2);
Dialog.addNumber("Internal Gradient radius for blue spores (try 2; use 0 for No)?", 0);
Dialog.addNumber("Rolling ball radius for spores background (try 20)?",10);
Dialog.addNumber("Remove outliers for macrophage ROI, step 1 (try 10) ? ", 10);
Dialog.addNumber("Remove outliers for macrophage ROI, step 2 (try 20) ? ", 20);
Dialog.addNumber("CLAHE blocks?",127);
Dialog.addNumber("CLAHE bins?",256);
Dialog.addNumber("CLAHE max slope?",3.0);
Dialog.addNumber("Min macrophage size?",73);
Dialog.addNumber("Max macrophage size?",900);
Dialog.addNumber("Min macrophage circularity?",0.0);
Dialog.addNumber("Max macrophage circularity?",0.99);
Dialog.addNumber("Min spore size?",5);
Dialog.addNumber("Max spore size?",50);
Dialog.addNumber("Min spore circularity?",0.0);
Dialog.addNumber("Max spore circularity?",0.99);
Dialog.addNumber("Blue threshold for green spore classifier (inside vs. outside) ?",37);
Dialog.addNumber("Green threshold for Bright Spots green spore classifier ?",20); 
thresholdMethodListHessian = newArray("Percentile", "Otsu", "Huang", "RenyiEntropy", "Triangle");
Dialog.addRadioButtonGroup("Threshold method for Hessian", thresholdMethodListHessian, 1, 5, "Otsu");
thresholdMethodListGreenFluorescence = newArray("Otsu", "Huang", "RenyiEntropy", "Triangle", "Li");
Dialog.addRadioButtonGroup("Threshold method for green fluorescence (NOT VALID for BS when combining IG and BS, see next button)", thresholdMethodListGreenFluorescence, 1, 5, "RenyiEntropy");
thresholdMethodListGreenFluorescenceBrightSpots = newArray("Otsu", "Huang", "RenyiEntropy", "Li");
Dialog.addRadioButtonGroup("Threshold method for green fluorescence Bright Spots method (only when combining IG and BS, otherwise see previous button)", thresholdMethodListGreenFluorescenceBrightSpots, 1, 5, "Li");
thresholdMethodListBlueFluorescence = newArray("Percentile", "Otsu", "Huang", "RenyiEntropy", "Triangle");
Dialog.addRadioButtonGroup("Threshold method for blue fluorescence", thresholdMethodListBlueFluorescence, 1, 5, "Otsu");
Dialog.show();

watershedOnMacrophages=Dialog.getCheckbox();
watershedOnSpores=Dialog.getCheckbox();
applyCLAHE=Dialog.getCheckbox();
applyCLAHEonFLSC=Dialog.getCheckbox();
combineInternalGradientAndBrightSpotResults=Dialog.getCheckbox();
internalGradientRadiusGreen=Dialog.getNumber();
internalGradientRadiusBlue=Dialog.getNumber();
rollingBallRadius=Dialog.getNumber();
removeOutliersStep1=Dialog.getNumber();
removeOutliersStep2=Dialog.getNumber();
CLAHEblocks=Dialog.getNumber();
CLAHEbins=Dialog.getNumber();
CLAHEslope=Dialog.getNumber();
minMacrophageSize=Dialog.getNumber();
maxMacrophageSize=Dialog.getNumber();
minMacrophageCircularity=Dialog.getNumber();
maxMacrophageCircularity=Dialog.getNumber();
minSporeSize=Dialog.getNumber();
maxSporeSize=Dialog.getNumber();
minSporeCircularity=Dialog.getNumber();
maxSporeCircularity=Dialog.getNumber();
blueThresholdForGreenSporeClassifier=Dialog.getNumber();
greenThresholdForGreenSporeClassifier=Dialog.getNumber();
thresholdMethodHessian = Dialog.getRadioButton;
thresholdMethodGreenFluorescence = Dialog.getRadioButton;
thresholdMethodGreenFluorescenceBrightSpots = Dialog.getRadioButton;
thresholdMethodBlueFluorescence = Dialog.getRadioButton;
//end of Dialog box 2

//Set up Results file where we'll save the main results:
saveAllFile = File.open("");//final results in a columnar format
if(multiplierPhagocytosedConidia>1.01 && multiplierAdherentConidia>1.01){ //applying Kaswara-correction
	print(saveAllFile, "Image" + "	\t" + "Nm(total)" + "	\t" + "Nc(total)" + "	\t" + "Nc(phag)" + "	\t" + "Nc(phag)_KaswCorr" + "	\t" + "Nc(adh)" + "	\t" + "Nc(adh)_KaswCorr" + "	\t" + "Nm(phag)" + "	\t" + "Nm" + "	\t" + "Fi(c)" + "	\t" + "Fi(c)_KaswCorr" + "	\t" + "Fi(m)" + "	\t" + "Fi(i)" + "	\t" + "Fi(i_sym)" + "	\t" + "Fi(i_sym)_KaswCorr" +  "	\n");
}
else { //without Kaswara-correction
	print(saveAllFile, "Image" + "	\t" + "Nm(total)" + "	\t" + "Nc(total)" + "	\t" + "Nc(phag)" + "	\t" + "Nc(adh)" + "	\t" + "Nm(phag)" + "	\t" + "Nm" + "	\t" + "Fi(c)" + "	\t" + "Fi(m)" + "	\t" + "Fi(i)" + "	\t" + "Fi(i_sym)" +  "	\n");	
}
//end of Results file set-up
		
dir = getDirectory("Choose a Directory ");
list = getFileList(dir);
print("Image folder: " + dir);
subFolders = newArray(list.length);
numSubfolders = 1;

if(useSubfolders==true){
	for (i=0; i<list.length; i++) {
		if (endsWith(list[i], "/")) {
          	subFolders[i] = ""+dir+list[i];
          	print("Subfolder found: " + subFolders[i]);
          }
	}
	numSubfolders=list.length;
	print("Number of subfolders = " + numSubfolders); //debugging
} 
else {
	numSubfolders=1;
	subFolders[0] = dir;
}

if(runInBatchMode==true){
   setBatchMode(true);
}


for(s=0; s<numSubfolders; s++){
	dir = subFolders[s];
	list = getFileList(dir);
	if(analyseAllImages==true){
		firstImageNumber = 0;
		lastImageNumber = list.length-1;
	}
	for(m=firstImageNumber;m<=lastImageNumber;m++){	
		testImageNumber = m;
		image_m = "" + dir + list[m];
		if(endsWith(image_m,imageType)==1){	
			if(useSpecificImageGroups==false || (useSpecificImageGroups==true && indexOf(image_m, searchTerm_1)>=0 && indexOf(image_m, searchTerm_2)>=0 && indexOf(image_m, searchTerm_3)>=0 && indexOf(image_m, excludeTerm_1)==-1 && indexOf(image_m, excludeTerm_2)==-1 && indexOf(image_m, excludeTerm_3)==-1)){
				
				if(useMultichannelTiffFormat==true){
					open(image_m);
					print("=================================================================================");
					print("Image name: " + image_m);
					run("Stack to Images");
					numOfChannels=nImages;//save original channel number to avoid confusion later
					currentImagename=list[m];//save image name for parameter file saving
					getDimensions(width, height, channels, slices, frames);
					imageWidth=width;
					imageHeight=height;
					imageBitDepth = bitDepth();
					print("Image size = " + width + " x " + height + " ; bit depth: " + imageBitDepth);
					width = getWidth();
					height = getHeight();
					channelNames = newArray(numOfChannels);
				}
				else {
					run("Bio-Formats Importer", "open=[" + image_m + "] color_mode=Default split_channels view=[Standard ImageJ] stack_order=Default");				
					print("=================================================================================");
					print("Image name: " + image_m);
					numOfChannels=nImages;//save original channel number to avoid confusion later
					currentImagename=list[m];//save image name for parameter file saving
					getDimensions(width, height, channels, slices, frames);
					imageWidth=width;
					imageHeight=height;
					imageBitDepth = bitDepth();
					print("Image size = " + width + " x " + height + " ; bit depth: " + imageBitDepth);
					width = getWidth();
					height = getHeight();
					channelNames = newArray(numOfChannels);
				}
				
				if(useHannoKaswaraFormat==true){
					if(useMultichannelTiffFormat == false){
						if(numOfChannels ==4){
							selectWindow(list[m] + " - C=0");
							rename("Red");
							selectWindow(list[m] + " - C=3");
							rename("Blue");
							selectWindow(list[m] + " - C=2");
							rename("TL");
							selectWindow(list[m] + " - C=1");
							rename("Green");
							channelNames[0]="Red";
							channelNames[1]="Green";
							channelNames[2]="TL";
							channelNames[3]="Blue";
						}
						else
							print("Incorrect number of image channels for Hanno&Kaswara, must equal 4");
					}
					else if (useMultichannelTiffFormat == true){
						imageList = getList("image.titles");
						for(llist=0; llist<imageList.length; llist++){
							currentImagename = imageList[llist];
							selectWindow(currentImagename);
							if(startsWith(currentImagename,"Ch1-T3")){
								rename("Blue");
								run("8-bit");
							}
							if(startsWith(currentImagename,"ChS1-T2")){
								rename("Green");
								run("8-bit");
							}
							if(endsWith(currentImagename,"PMT-T2")){
								rename("TL");
								run("8-bit");
							}
							if(startsWith(currentImagename,"Ch2-T1")){
								rename("Red");
								run("8-bit");
							}
						}
						channelNames[0]="Red";
						channelNames[1]="Green";
						channelNames[2]="TL";
						channelNames[3]="Blue";
					}
					else{
						print("Invalid combination of input parameters!");
					}
					
				}
				else if(useMultichannelTiffFormat==true && useHannoKaswaraFormat==false){
					if(numOfChannels == 3){	
						imageList = getList("image.titles");
						for(llist=0; llist<imageList.length; llist++){
							currentImagename = imageList[llist];
							selectWindow(currentImagename);
							if(endsWith(currentImagename,"_Ch0")){
								rename("Blue");
								run("8-bit");
							}
							if(endsWith(currentImagename,"_Ch1")){
								rename("Green");
								run("8-bit");
							}
							if(endsWith(currentImagename,"_Ch2")){
								rename("TL");
								run("8-bit");
							}
						}				
						channelNames[0]="Blue";
						channelNames[1]="Green";
						channelNames[2]="TL";
					}
					else if(numOfChannels == 4){
						imageList = getList("image.titles");
						for(llist=0; llist<imageList.length; llist++){
							currentImagename = imageList[llist];
							selectWindow(currentImagename);
							if(endsWith(currentImagename,"_Ch0")){
								rename("Blue");
								run("8-bit");
							}
							if(endsWith(currentImagename,"_Ch1")){
								rename("Green");
								run("8-bit");
							}
							if(endsWith(currentImagename,"_Ch3")){
								rename("TL");
								run("8-bit");
							}
							if(endsWith(currentImagename,"_Ch2")){
								close();
							}
						}				
						channelNames[0]="Blue";
						channelNames[1]="Green";
						channelNames[2]="TL";
					}
					else {
						print("Incorrect number of image channels, must equal 3 or 4");
					}
				}
				else{
					if(numOfChannels ==4){
						selectWindow(list[m] + " - C=2");
						close();
						selectWindow(list[m] + " - C=0");
						rename("Blue");
						selectWindow(list[m] + " - C=3");
						rename("TL");
						selectWindow(list[m] + " - C=1");
						rename("Green");
						channelNames[0]="Blue";
						channelNames[1]="Green";
						channelNames[2]=" ";
						channelNames[3]="TL";
					}
					else if(numOfChannels==3){
						selectWindow(list[m] + " - C=0");
						rename("Blue");
						selectWindow(list[m] + " - C=2");
						rename("TL");
						selectWindow(list[m] + " - C=1");
						rename("Green");	
						channelNames[0]="Blue";
						channelNames[1]="Green";
						channelNames[2]="TL";
					}
					else
						print("Incorrect number of image channels, must equal 3 or 4");
				}
				
				//*** now the re-stitching in the proper order: ***
				if(rearrangeZeiss==true){
					panelsizeX = width/XTileNumber;
					panelsizeY = height/YTileNumber;
					for(ch=0;ch<numOfChannels;ch++){ 
						selectWindow(channelNames[ch]);
						rename("RawData");
						for(mi=0;mi<XTileNumber;mi++){
							for(mj=0;mj<YTileNumber;mj++){
								selectWindow("RawData");
								makeRectangle(mi*panelsizeX + 1, mj*panelsizeY + 1, panelsizeX, panelsizeY);
								li=XTileNumber - mj - 1;
								lj=YTileNumber - mi - 1; 
								tilename = "panel_" + mi + "_" + mj;
								command1="title=" + tilename;
								run("Duplicate...", command1);
							}
						}
						if(XTileNumber == 3 && YTileNumber == 3){ //run for 3x3 matrix:
							run("Combine...", "stack1=panel_2_2 stack2=panel_2_1"); 
							run("Duplicate...", "title=combo01");
							run("Combine...", "stack1=combo01 stack2=panel_2_0");
							run("Duplicate...", "title=HorizontalLine1");
							
							run("Combine...", "stack1=panel_1_2 stack2=panel_1_1"); 
							run("Duplicate...", "title=combo02");
							run("Combine...", "stack1=combo02 stack2=panel_1_0");
							run("Duplicate...", "title=HorizontalLine2");
							
							run("Combine...", "stack1=panel_0_2 stack2=panel_0_1"); 
							run("Duplicate...", "title=combo03");
							run("Combine...", "stack1=combo03 stack2=panel_0_0");
							run("Duplicate...", "title=HorizontalLine3");
							
							//now the vertical stitching
							run("Combine...", "stack1=HorizontalLine1 stack2=HorizontalLine2 combine"); 
							run("Duplicate...", "title=VerticalCombo1");
							run("Combine...", "stack1=VerticalCombo1 stack2=HorizontalLine3 combine");
						}
						else if(XTileNumber == 5 && YTileNumber == 5){ //run for 5x5 matrix:
							run("Combine...", "stack1=panel_4_4 stack2=panel_4_3"); 
							run("Duplicate...", "title=combo01");
							run("Combine...", "stack1=combo01 stack2=panel_4_2");
							run("Duplicate...", "title=combo02");
							run("Combine...", "stack1=combo02 stack2=panel_4_1");
							run("Duplicate...", "title=combo03");
							run("Combine...", "stack1=combo03 stack2=panel_4_0");
							run("Duplicate...", "title=HorizontalLine0");
				
							run("Combine...", "stack1=panel_3_4 stack2=panel_3_3"); 
							run("Duplicate...", "title=combo11");
							run("Combine...", "stack1=combo11 stack2=panel_3_2");
							run("Duplicate...", "title=combo12");
							run("Combine...", "stack1=combo12 stack2=panel_3_1");
							run("Duplicate...", "title=combo13");
							run("Combine...", "stack1=combo13 stack2=panel_3_0");
							run("Duplicate...", "title=HorizontalLine1");
							
							run("Combine...", "stack1=panel_2_4 stack2=panel_2_3"); 
							run("Duplicate...", "title=combo21");
							run("Combine...", "stack1=combo21 stack2=panel_2_2");
							run("Duplicate...", "title=combo22");
							run("Combine...", "stack1=combo22 stack2=panel_2_1");
							run("Duplicate...", "title=combo23");
							run("Combine...", "stack1=combo23 stack2=panel_2_0");
							run("Duplicate...", "title=HorizontalLine2");
				
							run("Combine...", "stack1=panel_1_4 stack2=panel_1_3"); 
							run("Duplicate...", "title=combo31");
							run("Combine...", "stack1=combo31 stack2=panel_1_2");
							run("Duplicate...", "title=combo32");
							run("Combine...", "stack1=combo32 stack2=panel_1_1");
							run("Duplicate...", "title=combo33");
							run("Combine...", "stack1=combo33 stack2=panel_1_0");
							run("Duplicate...", "title=HorizontalLine3");
				
							run("Combine...", "stack1=panel_0_4 stack2=panel_0_3"); 
							run("Duplicate...", "title=combo41");
							run("Combine...", "stack1=combo41 stack2=panel_0_2");
							run("Duplicate...", "title=combo42");
							run("Combine...", "stack1=combo42 stack2=panel_0_1");
							run("Duplicate...", "title=combo43");
							run("Combine...", "stack1=combo43 stack2=panel_0_0");
							run("Duplicate...", "title=HorizontalLine4");
				
							//now the vertical stitching
							run("Combine...", "stack1=HorizontalLine0 stack2=HorizontalLine1 combine"); 
							run("Duplicate...", "title=VerticalCombo0");
							run("Combine...", "stack1=VerticalCombo0 stack2=HorizontalLine2 combine");
							run("Duplicate...", "title=VerticalCombo1");
							run("Combine...", "stack1=VerticalCombo1 stack2=HorizontalLine3 combine");
							run("Duplicate...", "title=VerticalCombo2");
							run("Combine...", "stack1=VerticalCombo2 stack2=HorizontalLine4 combine");
							run("Duplicate...", "title=VerticalCombo3");
						}
						else {
							print("Unhandled array size!  Must use 3x3 or 5x5 arrays!");
						}
		
						if(saveResults==true){
						   	if(useImageFilename==true){
								saveAs("png", dir + list[m] + "__" + nameTagSavedFiles + "__Channel_" + channelNames[ch] + "__Restitched.png");
							}
							else{
								saveAs("png", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__Channel_" + channelNames[ch] + "__Restitched.png");
							}
						}
						close();
						close("RawData");
					}
				}


				//*** reopen the correctly stitched images: ***
				if(rearrangeZeiss == true){
					for(cho=0;cho<numOfChannels;cho++){
					   	if(useImageFilename==true){
							open(dir + list[m] + "__" + nameTagSavedFiles + "__Channel_" + channelNames[cho] + "__Restitched.png");
						}
						else{
							open("png", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__Channel_" + channelNames[cho] + "__Restitched.png");
						}
						rename(channelNames[cho]);
						run("32-bit");
					}
				}

				//*** Illumination correction if desired for TL: ***
				if(correctIlluminationForTL==true){
					selectWindow("TL");
					run("32-bit");
					run("Duplicate...", "title=Illumination_mask ");
					run("Gaussian Blur...", "sigma=" + illuminationCorrectionSigmaForTL);
					getStatistics(TL_area, TL_mean, TL_min, TL_max);
					run("Divide...", "value=" + TL_max);
					imageCalculator("Divide create 32-bit", "TL","Illumination_mask");
					rename("TL_IlluminationCorrected");
					run("Duplicate...", "title=Macrophages");
					close("Normalized_TL");
				}
				else{
					selectWindow("TL");
					run("Duplicate...", "title=TL_IlluminationCorrected");
					run("Duplicate...", "title=Macrophages");
				}

				if(applyCLAHE==true){
					selectWindow("Macrophages");
					CLAHEmessage = "blocksize=" + CLAHEblocks + " histogram=" + CLAHEbins + " maximum=" + CLAHEslope + " mask=*None*";
					run("Enhance Local Contrast (CLAHE)", "blocksize=" + CLAHEblocks + " histogram=" + CLAHEbins + " maximum=" + CLAHEslope + " mask=*None*");
				}

				selectWindow("Macrophages");
				run("Duplicate...", "title=Spores_TL");


				//*** Create ROIs for excludeEdges option: ***
				roiManager("reset");
				makeRectangle(0, 0, edgeWidth, imageHeight);
				roiManager("Add");
				makeRectangle(imageWidth-edgeWidth, 0, edgeWidth, imageHeight);
				roiManager("Add");
				makeRectangle(0, 0, imageWidth, edgeWidth);
				roiManager("Add");
				makeRectangle(0, imageHeight-edgeWidth, imageWidth, edgeWidth);
				roiManager("Add");
				run("Select All");
				roiManager("Combine");
				roiManager("Add");
				if(useImageFilename==true){
					roiManager("save", dir + list[m] + "__Edges_ROIs.zip");
				}
				else{
					roiManager("save",  dir + "/Image_" + testImageNumber + "__Edges_ROIs.zip");
				}
				
//***************************************************************************************************************

				//*** Spore finder with Hessian starts: ***
				selectWindow("Spores_TL");
				run("Sharpen");
				run("FeatureJ Hessian", "largest smallest absolute smoothing=" + hessianSmoothingForSpores);
				selectWindow("Spores_TL largest Hessian eigenvalues");
				imageCalculator("Subtract create 32-bit", "Spores_TL largest Hessian eigenvalues","Spores_TL smallest Hessian eigenvalues");
				if(gaussianSmoothingForSpores>=1){
					run("Gaussian Blur...", "sigma=" + gaussianSmoothingForSpores);
				}
				setAutoThreshold(thresholdMethodHessian + " dark");
				setOption("BlackBackground", true);
				run("Convert to Mask");
				for(i=0;i<dilateErodeStepsForSpores;i++){
					run("Dilate");
				}
				run("Fill Holes");
				for(i=0;i<dilateErodeStepsForSpores;i++){
					run("Erode");
				}
				//run this again:
				for(i=0;i<dilateErodeStepsForSpores;i++){
					run("Dilate");
				}
				run("Fill Holes");
				for(i=0;i<dilateErodeStepsForSpores;i++){
					run("Erode");
				}
				run("Watershed");
				for(i=0;i<lineThicknessForObjects;i++){
					run("Erode");
				}
				
				roiManager("reset");
				if(excludeEdges==true){
					if(gatherResultsForEntireImageSet==true){
						run("Analyze Particles...", "size=" + minSporeSize + "-" + maxSporeSize + " circularity=" + minSporeCircularity + "-" + maxSporeCircularity + " show=[Bare Outlines] display exclude summarize add");	
					}
					else{
						run("Analyze Particles...", "size=" + minSporeSize + "-" + maxSporeSize + " circularity=" + minSporeCircularity + "-" + maxSporeCircularity + " show=[Bare Outlines] display exclude clear summarize add");
					}	
				}
				else{
					if(gatherResultsForEntireImageSet==true){
						run("Analyze Particles...", "size=" + minSporeSize + "-" + maxSporeSize + " circularity=" + minSporeCircularity + "-" + maxSporeCircularity + " show=[Bare Outlines] display summarize add");				
					}
					else{
						run("Analyze Particles...", "size=" + minSporeSize + "-" + maxSporeSize + " circularity=" + minSporeCircularity + "-" + maxSporeCircularity + " show=[Bare Outlines] display clear summarize add");
					}
				
				}

				nROI_spores = roiManager("count");
				if(saveResults==true && nROI_spores>0){
						if(useImageFilename==true){
							roiManager("save", dir + list[m] + "__Spores_ROIs.zip");
						}
						else{
							roiManager("save",  dir + "/Image_" + testImageNumber + "__Spores_ROIs.zip");
						}
				}
				for(i=0;i<lineThicknessForObjects;i++){
					run("Erode");
				}
				rename("SegmentedSpores");
				if(saveResults==true){
					if(useImageFilename==true){
						saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__SegmentedSpores.jpg");
					}
					else{
						saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__SegmentedSpores.jpg");
					}
				}
				//*** End of spore finder with Hessian ***

//***************************************************************************************************************
				
				//*** Object analysis for spores Hessian starts: ***
				nROI_spores = roiManager("count");
				if(nROI_spores>0){
					roiManager("Show All");
					updateResults();
					run("Summarize");
					updateResults();
					selectWindow("Results");
					for(ii=0;ii<nROI_spores;ii++){
						feretAngle = getResult("FeretAngle",ii);
						if(feretAngle > 90){
							normFeretAngle = 180-feretAngle;
						} 
						else{
							normFeretAngle = feretAngle;
						}
						setResult("NormalisedFeretAngle",ii,normFeretAngle);
						perimeter = getResult("Perim.",ii);
						feret = getResult("Feret",ii);
						perimFeretRatio=perimeter/feret;
						setResult("PerimeterFeretRatio",ii,perimFeretRatio);
						setResult("Label", ii, list[m]);//add image name to results table so that the results can be analysed image by image
					}
					
					updateResults();
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("results", dir + list[m] + "__" + nameTagSavedFiles + "__Segmentation_Results_Spores.txt");
						}
						else{
							saveAs("results", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__Segmentation_Results_Spores.txt");
						}
					}
					run("Distribution...", "parameter=Circ. automatic");
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__Circularity_Distribution_Spores.jpg");
						}
						else{
							saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__Circularity_Distribution_Spores.jpg");
						}
					}
					run("Distribution...", "parameter=Round automatic");
					if(saveResults==true){
					   if(useImageFilename==true){
					   		saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__Roundness_Distribution_Spores.jpg");
					   }
					   else{
					   		saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__Roundness_Distribution_Spores.jpg");
					   }
					}
					run("Distribution...", "parameter=AR automatic");
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__AspectRatio_Distribution_Spores.jpg");	
						}
						else{
							saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__AspectRatio_Distribution_Spores.jpg");
						}
					}
					run("Distribution...", "parameter=FeretAngle automatic");
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__FeretAngle_Distribution_Spores.jpg");
						}
						else{
							saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__FeretAngle_Distribution_Spores.jpg");
						}
					}
					run("Distribution...", "parameter=NormalisedFeretAngle automatic");
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__NormalisedFeretAngle_Distribution_Spores.jpg");
						}
						else{
							saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__NormalisedFeretAngle_Distribution_Spores.jpg");
						}
					}
					run("Distribution...", "parameter=PerimeterFeretRatio automatic");
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__PerimeterFeretRatio_Distribution_Spores.jpg");
						}
						else{
							saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__PerimeterFeretRatio_Distribution_Spores.jpg");
						}
					}
					run("Distribution...", "parameter=Area automatic");
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__Area_Distribution_Spores.jpg");
						}
						else{
							saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__Area_Distribution_Spores.jpg");
						}
					}
					run("Distribution...", "parameter=Perim. automatic");
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__Perimeter_Distribution_Spores.jpg");
						}
						else{
							saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__Perimeter_Distribution_Spores.jpg");
						}
					}
		
					selectWindow("TL_IlluminationCorrected");
					run("Duplicate...", "title=TL_image_with_final_objects");
					roiManager("Show All without labels");
					run("Colors...", "foreground=yellow background=black selection=yellow");
					run("Flatten");
					if(saveResults==true){
						if(useImageFilename==true){
					   		saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__TL_image_with_spores.jpg");
					   	}
					   	else{
					   		saveAs("Jpeg", dir + "/Image_" + "__" + testImageNumber + "__" + nameTagSavedFiles + "__TL_image_with_spores.jpg");
					   	}
					}
				} //end of 'if(nROI_spores>0)' block
				//*** End of object analysis for spores with Hessian***

//***************************************************************************************************************
				
				//*** Macrophage finder with Hessian: ***
				selectWindow("Macrophages");
				run("Sharpen");
				run("FeatureJ Hessian", "largest smallest absolute smoothing=" + hessianSmoothingForMacrophages);
				if(useMAXHessian == true) {
					selectWindow("Macrophages largest Hessian eigenvalues");
				}
				else {
					selectWindow("Macrophages smallest Hessian eigenvalues");
				}
				if(gaussianSmoothingForMacrophages>=1){
					run("Gaussian Blur...", "sigma=" + gaussianSmoothingForMacrophages);
				}
				setAutoThreshold(thresholdMethodHessian + " dark");
				setOption("BlackBackground", true);
				getThreshold(lower, upper);
				setThreshold(lower*lowerThresholdMultiplierMacrophages, upper*upperThresholdMultiplierMacrophages);
				run("Convert to Mask");

				for(i=0;i<dilateErodeStepsForMacrophages;i++){
					run("Dilate");
				}
				run("Fill Holes");
				for(i=0;i<dilateErodeStepsForMacrophages;i++){
					run("Erode");
				}

				run("Remove Outliers...", "radius=" + removeOutliersStep1 + " threshold=50 which=Bright");
				run("Remove Outliers...", "radius=" + removeOutliersStep2 + " threshold=50 which=Bright");
				run("Duplicate...", "title=Macrophages_before_watershed");
				if(watershedOnMacrophages==true){
					run("Watershed");
				}
				run("Duplicate...", "title=Macrophages_after_watershed");
				for(i=0;i<lineThicknessForObjects;i++){
					run("Erode");
				}
				for(i=0;i<additionalErodeStepsForMacrophages;i++){ //try this for macrophages 'cause the ROIs are too loose and the associated conidia are too many, esp. adherent
						run("Erode");
					}
				roiManager("reset");
				if(excludeEdges==true){
					if(gatherResultsForEntireImageSet==true){
						run("Analyze Particles...", "size=" + minMacrophageSize + "-" + maxMacrophageSize + " circularity=" + minMacrophageCircularity + "-" + maxMacrophageCircularity + " show=[Bare Outlines] display exclude summarize add");	
					}
					else{
						run("Analyze Particles...", "size=" + minMacrophageSize + "-" + maxMacrophageSize + " circularity=" + minMacrophageCircularity + "-" + maxMacrophageCircularity + " show=[Bare Outlines] display exclude clear summarize add");
					}	
				}
				else{
					if(gatherResultsForEntireImageSet==true){
						run("Analyze Particles...", "size=" + minMacrophageSize + "-" + maxMacrophageSize + " circularity=" + minMacrophageCircularity + "-" + maxMacrophageCircularity + " show=[Bare Outlines] display summarize add");				
					}
					else{
						run("Analyze Particles...", "size=" + minMacrophageSize + "-" + maxMacrophageSize + " circularity=" + minMacrophageCircularity + "-" + maxMacrophageCircularity + " show=[Bare Outlines] display clear summarize add");
					}
				}
				nROI_macrophages = roiManager("count");
				if(saveResults==true && nROI_macrophages>0){
						if(useImageFilename==true){
							roiManager("save", dir + list[m] + "__Macrophages_ROIs.zip");
						}
						else{
							roiManager("save",  dir + "/Image_" + testImageNumber + "__Macrophages_ROIs.zip");
						}
				}
				for(i=0;i<lineThicknessForObjects;i++){
					run("Erode");
				}
				rename("SegmentedMacrophages");
				if(saveResults==true){
					if(useImageFilename==true){
						saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__SegmentedMacrophages.jpg");
					}
					else{
						saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__SegmentedMacrophages.jpg");
					}
				}
				//*** End of macrophage finder with Hessian ***

//***************************************************************************************************************
			
				//*** Object analysis for macrophages with Hessian starts: ***
				nROI_macrophages = roiManager("count");
				numberOfMacrophages = nROI_macrophages; //save for later use
				if(nROI_macrophages>0){
					roiManager("Show All");
					updateResults();
					run("Summarize");
					updateResults();
					selectWindow("Results");
					for(ii=0;ii<nROI_macrophages;ii++){
						feretAngle = getResult("FeretAngle",ii);
						if(feretAngle > 90){
							normFeretAngle = 180-feretAngle;
						} 
						else{
							normFeretAngle = feretAngle;
						}
						setResult("NormalisedFeretAngle",ii,normFeretAngle);
						perimeter = getResult("Perim.",ii);
						feret = getResult("Feret",ii);
						perimFeretRatio=perimeter/feret;
						setResult("PerimeterFeretRatio",ii,perimFeretRatio);
						setResult("Label", ii, list[m]);//add image name to results table so that the results can be analysed image by image
					}
					
					updateResults();
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("results", dir + list[m] + "__" + nameTagSavedFiles + "__Segmentation_Results_Macrophages.txt");
						}
						else{
							saveAs("results", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__Segmentation_Results_Macrophages.txt");
						}
					}
					run("Distribution...", "parameter=Circ. automatic");
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__Circularity_Distribution.jpg");
						}
						else{
							saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__Circularity_Distribution.jpg");
						}
					}
					run("Distribution...", "parameter=Round automatic");
					if(saveResults==true){
					   if(useImageFilename==true){
					   		saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__Roundness_Distribution.jpg");
					   }
					   else{
					   		saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__Roundness_Distribution.jpg");
					   }
					}
					run("Distribution...", "parameter=AR automatic");
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__AspectRatio_Distribution.jpg");	
						}
						else{
							saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__AspectRatio_Distribution.jpg");
						}
					}
					run("Distribution...", "parameter=FeretAngle automatic");
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__FeretAngle_Distribution.jpg");
						}
						else{
							saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__FeretAngle_Distribution.jpg");
						}
					}
					run("Distribution...", "parameter=NormalisedFeretAngle automatic");
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__NormalisedFeretAngle_Distribution.jpg");
						}
						else{
							saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__NormalisedFeretAngle_Distribution.jpg");
						}
					}
					run("Distribution...", "parameter=PerimeterFeretRatio automatic");
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__PerimeterFeretRatio_Distribution.jpg");
						}
						else{
							saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__PerimeterFeretRatio_Distribution.jpg");
						}
					}
					run("Distribution...", "parameter=Area automatic");
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__Area_Distribution.jpg");
						}
						else{
							saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__Area_Distribution.jpg");
						}
					}
					run("Distribution...", "parameter=Perim. automatic");
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__Perimeter_Distribution.jpg");
						}
						else{
							saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__Perimeter_Distribution.jpg");
						}
					}
		
					selectWindow("TL_IlluminationCorrected");
					run("Duplicate...", "title=TL_image_with_final_objects");
					roiManager("Show All without labels");
					run("Colors...", "foreground=yellow background=black selection=yellow");
					run("Flatten");
					if(saveResults==true){
						if(useImageFilename==true){
					   		saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__TL_image_with_macrophages.jpg");
					   	}
					   	else{
					   		saveAs("Jpeg", dir + "/Image_" + "__" + testImageNumber + "__" + nameTagSavedFiles + "__TL_image_with_macrophages.jpg");
					   	}
					}
				} //end of 'if(nROI_macrophages>0)' block
				//*** End of object analysis for macrophages with Hessian ***

//***************************************************************************************************************
			
				//*** Fluorescence-based segmentation for green spores starts: ***
				selectWindow("Green");
				run("Duplicate...", "title=Spores_green");
				if(applyCLAHEonFLSC==true){
					selectWindow("Spores_green");
					CLAHEmessage = "blocksize=" + CLAHEblocks + " histogram=" + CLAHEbins + " maximum=" + CLAHEslope + " mask=*None*";
					run("Enhance Local Contrast (CLAHE)", "blocksize=" + CLAHEblocks + " histogram=" + CLAHEbins + " maximum=" + CLAHEslope + " mask=*None*");
				}
				run("Subtract Background...", "rolling=" + rollingBallRadius);
				run("Multiply...", "value="  + greenChannelMultiplierForDimData);
				// Offer choice between Internal Gradient (to find objects with a hole inside) and simple bright spot analysis:
				if(internalGradientRadiusGreen >= 1){ 
					run("Morphological Filters", "operation=[Internal Gradient] element=Square radius=" + internalGradientRadiusGreen);
					run("Duplicate...", "title=GreenSpores_afterIG_onlyIG");//for the paper, create a copy of this image
					run("Invert");
					run("Duplicate...", "title=GreenSpores_afterInvert_onlyIG");//for the paper, create a copy of this image
					setAutoThreshold(thresholdMethodGreenFluorescence);
					getThreshold(lower, upper);
					setThreshold(lower*lowerThresholdMultiplier, upper*upperThresholdMultiplier);
					run("Convert to Mask");
					run("Fill Holes");
					if(watershedOnSpores==true){
						run("Watershed");
					}
					run("Duplicate...", "title=GreenSpores_afterWSh_onlyIG");//for the paper, create a copy of this image
				}
				else{
					setAutoThreshold(thresholdMethodGreenFluorescence + " dark");
					setOption("BlackBackground", true);
					run("Convert to Mask");
					for(i=0;i<dilateErodeStepsForSpores;i++){
						run("Dilate");
					}
					run("Fill Holes");
					for(i=0;i<dilateErodeStepsForSpores;i++){
						run("Erode");
					}
					
					if(gaussianBlurForSpores>=1){
						run("Gaussian Blur...", "sigma=" + gaussianBlurForSpores);
					}
					setAutoThreshold(thresholdMethodGreenFluorescence + " dark");
					setOption("BlackBackground", true);
					run("Convert to Mask");
					if(watershedOnSpores==true){
						run("Watershed");
					}
					run("Duplicate...", "title=GreenSpores_afterWSh_onlyBS");//for the paper, create a copy of this image
				}
				for(i=0;i<lineThicknessForObjects;i++){
					run("Erode");
				}

				roiManager("reset");
				if(excludeEdges==true){
					if(gatherResultsForEntireImageSet==true){
						run("Analyze Particles...", "size=" + minSporeSize + "-" + maxSporeSize + " circularity=" + minSporeCircularity + "-" + maxSporeCircularity + " show=[Bare Outlines] display exclude summarize add");	
					}
					else{
						run("Analyze Particles...", "size=" + minSporeSize + "-" + maxSporeSize + " circularity=" + minSporeCircularity + "-" + maxSporeCircularity + " show=[Bare Outlines] display exclude clear summarize add");
					}	
				}
				else{
					if(gatherResultsForEntireImageSet==true){
						run("Analyze Particles...", "size=" + minSporeSize + "-" + maxSporeSize + " circularity=" + minSporeCircularity + "-" + maxSporeCircularity + " show=[Bare Outlines] display summarize add");				
					}
					else{
						run("Analyze Particles...", "size=" + minSporeSize + "-" + maxSporeSize + " circularity=" + minSporeCircularity + "-" + maxSporeCircularity + " show=[Bare Outlines] display clear summarize add");
					}
				}
				nROI_greenSpores = roiManager("count");
				print("Total spore count  = " + nROI_greenSpores);
				if(saveResults==true && nROI_greenSpores>0){
						if(useImageFilename==true){
							roiManager("save", dir + list[m] + "__GreenSpores_ROIs.zip");
						}
						else{
							roiManager("save",  dir + "/Image_" + testImageNumber + "__GreenSpores_ROIs.zip");
						}
						
						if(internalGradientRadiusGreen >= 1){ 
							if(useImageFilename==true){
								roiManager("save", dir + list[m] + "__GreenSpores_ROIs_InternalGradient.zip");
							}
							else{
								roiManager("save",  dir + "/Image_" + testImageNumber + "__GreenSpores_ROIs_InternalGradient.zip");
							}
						}						
				}
				
				for(i=0;i<lineThicknessForObjects;i++){
					run("Erode");
				}
				rename("SegmentedGreenSpores");
				if(saveResults==true){
					if(useImageFilename==true){
						saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "SegmentedGreenSpores.jpg");
					}
					else{
						saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "SegmentedGreenSpores.jpg");
					}
				}
				
				//*** End of fluorescence-based segmentation for green spores ***

//***************************************************************************************************************
		
				//*** Object analysis for green spores starts: ***
				nROI_greenSpores = roiManager("count");
				if(nROI_greenSpores>0){
					roiManager("Show All");
					updateResults();
					run("Summarize");
					updateResults();
					selectWindow("Results");
					for(ii=0;ii<nROI_greenSpores;ii++){
						feretAngle = getResult("FeretAngle",ii);
						if(feretAngle > 90){
							normFeretAngle = 180-feretAngle;
						} 
						else{
							normFeretAngle = feretAngle;
						}
						setResult("NormalisedFeretAngle",ii,normFeretAngle);
						perimeter = getResult("Perim.",ii);
						feret = getResult("Feret",ii);
						perimFeretRatio=perimeter/feret;
						setResult("PerimeterFeretRatio",ii,perimFeretRatio);
						setResult("Label", ii, list[m]);//add image name to results table so that the results can be analysed image by image
					}
					
					updateResults();
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("results", dir + list[m] + "__" + nameTagSavedFiles + "__Segmentation_Results_GreenSpores.txt");
						}
						else{
							saveAs("results", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__Segmentation_Results_GreenSpores.txt");
						}
					}
					run("Distribution...", "parameter=Circ. automatic");
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__Circularity_Distribution.jpg");
						}
						else{
							saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__Circularity_Distribution.jpg");
						}
					}
					run("Distribution...", "parameter=Round automatic");
					if(saveResults==true){
					   if(useImageFilename==true){
					   		saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__Roundness_Distribution.jpg");
					   }
					   else{
					   		saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__Roundness_Distribution.jpg");
					   }
					}
					run("Distribution...", "parameter=AR automatic");
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__AspectRatio_Distribution.jpg");	
						}
						else{
							saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__AspectRatio_Distribution.jpg");
						}
					}
					run("Distribution...", "parameter=FeretAngle automatic");
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__FeretAngle_Distribution.jpg");
						}
						else{
							saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__FeretAngle_Distribution.jpg");
						}
					}
					run("Distribution...", "parameter=NormalisedFeretAngle automatic");
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__NormalisedFeretAngle_Distribution.jpg");
						}
						else{
							saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__NormalisedFeretAngle_Distribution.jpg");
						}
					}
					run("Distribution...", "parameter=PerimeterFeretRatio automatic");
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__PerimeterFeretRatio_Distribution.jpg");
						}
						else{
							saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__PerimeterFeretRatio_Distribution.jpg");
						}
					}
					run("Distribution...", "parameter=Area automatic");
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__Area_Distribution.jpg");
						}
						else{
							saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__Area_Distribution.jpg");
						}
					}
					run("Distribution...", "parameter=Perim. automatic");
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__Perimeter_Distribution.jpg");
						}
						else{
							saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__Perimeter_Distribution.jpg");
						}
					}
		
					selectWindow("TL_IlluminationCorrected");
					run("Duplicate...", "title=TL_image_with_greenSpores");
					roiManager("Show All without labels");
					run("Colors...", "foreground=green background=black selection=green");
					run("Flatten");
					if(saveResults==true){
						if(useImageFilename==true){
					   		saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "TL_image_with_greenSpores.jpg");
					   	}
					   	else{
					   		saveAs("Jpeg", dir + "/Image_" + "__" + testImageNumber + "__" + nameTagSavedFiles + "TL_image_with_greenSpores.jpg");
					   	}
					}

					selectWindow("Green");
					run("Duplicate...", "title=Green_image_with_greenSpores");
					run("Enhance Contrast", "saturated=0.35");
					roiManager("Show All without labels");
					run("Colors...", "foreground=green background=black selection=green");
					run("Flatten");
					if(saveResults==true){
						if(useImageFilename==true){
					   		saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "Green_image_with_greenSpores.jpg");
					   	}
					   	else{
					   		saveAs("Jpeg", dir + "/Image_" + "__" + testImageNumber + "__" + nameTagSavedFiles + "Green_image_with_greenSpores.jpg");
					   	}
					}
				} //end of 'if(nROI_greenSpores>0)' block
				//*** End of object analysis for green spores ***
				
//***************************************************************************************************************
		
				//*** Fluorescence-based segmentation with Bright Spots for green spores starts (when combining Internal Gradient and Bright Spots): ***

				if(combineInternalGradientAndBrightSpotResults==true){
					selectWindow("Green");
					run("Duplicate...", "title=Spores_green_BrightSpots");
					if(applyCLAHEonFLSC==true){
						selectWindow("Spores_green_BrightSpots");
						CLAHEmessage = "blocksize=" + CLAHEblocks + " histogram=" + CLAHEbins + " maximum=" + CLAHEslope + " mask=*None*";
						run("Enhance Local Contrast (CLAHE)", "blocksize=" + CLAHEblocks + " histogram=" + CLAHEbins + " maximum=" + CLAHEslope + " mask=*None*");
					}
					run("Subtract Background...", "rolling=" + rollingBallRadius);
					run("Multiply...", "value="  + greenChannelMultiplierForDimData);

					setAutoThreshold(thresholdMethodGreenFluorescenceBrightSpots + " dark"); //option to use different background method for Bright Spots method when combining IG and BS-based ROIs for green
					setOption("BlackBackground", true);
					run("Convert to Mask");
					for(i=0;i<dilateErodeStepsForSpores;i++){
						run("Dilate");
					}
					run("Fill Holes");
					for(i=0;i<dilateErodeStepsForSpores;i++){
						run("Erode");
					}
					
					if(gaussianBlurForSpores>=1){
						run("Gaussian Blur...", "sigma=" + gaussianBlurForSpores);
					}
					setAutoThreshold(thresholdMethodGreenFluorescence + " dark");
					setOption("BlackBackground", true);
					run("Convert to Mask");
					if(watershedOnSpores==true){
						run("Watershed");
					}
					
					for(i=0;i<lineThicknessForObjects;i++){
						run("Erode");
					}

					for(i=0;i<2;i++){ //try this for Bright Spots 'cause the ROIs are too loose
						run("Erode");
					}
	
					roiManager("reset");
					if(excludeEdges==true){
						if(gatherResultsForEntireImageSet==true){
							run("Analyze Particles...", "size=" + minSporeSize + "-" + maxSporeSize + " circularity=" + minSporeCircularity + "-" + maxSporeCircularity + " show=[Bare Outlines] display exclude summarize add");	
						}
						else{
							run("Analyze Particles...", "size=" + minSporeSize + "-" + maxSporeSize + " circularity=" + minSporeCircularity + "-" + maxSporeCircularity + " show=[Bare Outlines] display exclude clear summarize add");
						}	
					}
					else{
						if(gatherResultsForEntireImageSet==true){
							run("Analyze Particles...", "size=" + minSporeSize + "-" + maxSporeSize + " circularity=" + minSporeCircularity + "-" + maxSporeCircularity + " show=[Bare Outlines] display summarize add");				
						}
						else{
							run("Analyze Particles...", "size=" + minSporeSize + "-" + maxSporeSize + " circularity=" + minSporeCircularity + "-" + maxSporeCircularity + " show=[Bare Outlines] display clear summarize add");
						}
					}
					nROI_greenSpores_BrightSpots = roiManager("count");
					print("Bright Spots spore count = " + nROI_greenSpores_BrightSpots);
					if(saveResults==true && nROI_greenSpores_BrightSpots>0){
							if(useImageFilename==true){
								roiManager("save", dir + list[m] + "__GreenSpores_ROIs_BrightSpots.zip");
							}
							else{
								roiManager("save",  dir + "/Image_" + testImageNumber + "__GreenSpores_ROIs_BrightSpots.zip");
							}						
					}
					
					rename("SegmentedGreenSpores_BrightSpots");
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "SegmentedGreenSpores_BrightSpots.jpg");
						}
						else{
							saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "SegmentedGreenSpores_BrightSpots.jpg");
						}
					}
				}
				//*** End of Fluorescence-based segmentation with Bright Spots for green spores (when combining Internal Gradient and Bright Spots) ***

//***************************************************************************************************************

				//*** Fluorescence-based segmentation for blue spores starts: ***
				selectWindow("Blue");
				run("Duplicate...", "title=Spores_blue");
				if(applyCLAHEonFLSC==true){
					selectWindow("Spores_blue");
					CLAHEmessage = "blocksize=" + CLAHEblocks + " histogram=" + CLAHEbins + " maximum=" + CLAHEslope + " mask=*None*";
					run("Enhance Local Contrast (CLAHE)", "blocksize=" + CLAHEblocks + " histogram=" + CLAHEbins + " maximum=" + CLAHEslope + " mask=*None*");
				}
				run("Subtract Background...", "rolling=" + rollingBallRadius);
				run("Multiply...", "value="  + blueChannelMultiplierForDimData);
				// Offer choice between Internal Gradient (to find objects with a hole inside) and simple bright spot analysis:
				if(internalGradientRadiusBlue >= 1){ 
					run("Morphological Filters", "operation=[Internal Gradient] element=Square radius=" + internalGradientRadiusBlue);
					run("Invert");
					setAutoThreshold(thresholdMethodBlueFluorescence);
					getThreshold(lower, upper);
					setThreshold(lower*lowerThresholdMultiplier, upper*upperThresholdMultiplier);
					run("Convert to Mask");
					run("Fill Holes");
					if(watershedOnSpores==true){
						run("Watershed");
					}
				}
				else{
					setAutoThreshold(thresholdMethodBlueFluorescence + " dark");
					setOption("BlackBackground", true);
					run("Convert to Mask");
					for(i=0;i<dilateErodeStepsForSpores;i++){
						run("Dilate");
					}
					run("Fill Holes");
					for(i=0;i<dilateErodeStepsForSpores;i++){
						run("Erode");
					}
					if(gaussianBlurForSpores>=1){
						run("Gaussian Blur...", "sigma=" + gaussianBlurForSpores);
					}
					setAutoThreshold("Otsu dark");
					setOption("BlackBackground", true);
					run("Convert to Mask");
					
					if(watershedOnSpores==true){
						run("Watershed");
					}
				}
				for(i=0;i<lineThicknessForObjects;i++){
					run("Erode");
				}
				roiManager("reset");
				if(excludeEdges==true){
					if(gatherResultsForEntireImageSet==true){
						run("Analyze Particles...", "size=" + minSporeSize + "-" + maxSporeSize + " circularity=" + minSporeCircularity + "-" + maxSporeCircularity + " show=[Bare Outlines] display exclude summarize add");	
					}
					else{
						run("Analyze Particles...", "size=" + minSporeSize + "-" + maxSporeSize + " circularity=" + minSporeCircularity + "-" + maxSporeCircularity + " show=[Bare Outlines] display exclude clear summarize add");
					}	
				}
				else{
					if(gatherResultsForEntireImageSet==true){
						run("Analyze Particles...", "size=" + minSporeSize + "-" + maxSporeSize + " circularity=" + minSporeCircularity + "-" + maxSporeCircularity + " show=[Bare Outlines] display summarize add");				
					}
					else{
						run("Analyze Particles...", "size=" + minSporeSize + "-" + maxSporeSize + " circularity=" + minSporeCircularity + "-" + maxSporeCircularity + " show=[Bare Outlines] display clear summarize add");
					}
				}
				nROI_blueSpores = roiManager("count");
				if(saveResults==true && nROI_blueSpores>0){
						if(useImageFilename==true){
							roiManager("save", dir + list[m] + "__BlueSpores_ROIs.zip");
						}
						else{
							roiManager("save",  dir + "/Image_" + testImageNumber + "__BlueSpores_ROIs.zip");
						}
				}
				for(i=0;i<lineThicknessForObjects;i++){
					run("Erode");
				}
				rename("SegmentedBlueSpores");
				if(saveResults==true){
					if(useImageFilename==true){
						saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "SegmentedBlueSpores.jpg");
					}
					else{
						saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "SegmentedBlueSpores.jpg");
					}
				}
				
				//*** End of fluorescence-based segmentation for blue spores ***
				
//***************************************************************************************************************
			
				//*** Object analysis for blue spores starts: ***
				nROI_blueSpores = roiManager("count");
				if(nROI_blueSpores>0){
					roiManager("Show All");
					updateResults();
					run("Summarize");
					updateResults();
					selectWindow("Results");
					for(ii=0;ii<nROI_blueSpores;ii++){
						feretAngle = getResult("FeretAngle",ii);
						if(feretAngle > 90){
							normFeretAngle = 180-feretAngle;
						} 
						else{
							normFeretAngle = feretAngle;
						}
						setResult("NormalisedFeretAngle",ii,normFeretAngle);
						perimeter = getResult("Perim.",ii);
						feret = getResult("Feret",ii);
						perimFeretRatio=perimeter/feret;
						setResult("PerimeterFeretRatio",ii,perimFeretRatio);
						setResult("Label", ii, list[m]);//add image name to results table so that the results can be analysed image by image
					}
					
					updateResults();
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("results", dir + list[m] + "__" + nameTagSavedFiles + "__Segmentation_Results_BlueSpores.txt");
						}
						else{
							saveAs("results", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__Segmentation_Results_BlueSpores.txt");
						}
					}
					run("Distribution...", "parameter=Circ. automatic");
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__Circularity_Distribution.jpg");
						}
						else{
							saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__Circularity_Distribution.jpg");
						}
					}
					run("Distribution...", "parameter=Round automatic");
					if(saveResults==true){
					   if(useImageFilename==true){
					   		saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__Roundness_Distribution.jpg");
					   }
					   else{
					   		saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__Roundness_Distribution.jpg");
					   }
					}
					run("Distribution...", "parameter=AR automatic");
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__AspectRatio_Distribution.jpg");	
						}
						else{
							saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__AspectRatio_Distribution.jpg");
						}
					}
					run("Distribution...", "parameter=FeretAngle automatic");
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__FeretAngle_Distribution.jpg");
						}
						else{
							saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__FeretAngle_Distribution.jpg");
						}
					}
					run("Distribution...", "parameter=NormalisedFeretAngle automatic");
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__NormalisedFeretAngle_Distribution.jpg");
						}
						else{
							saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__NormalisedFeretAngle_Distribution.jpg");
						}
					}
					run("Distribution...", "parameter=PerimeterFeretRatio automatic");
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__PerimeterFeretRatio_Distribution.jpg");
						}
						else{
							saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__PerimeterFeretRatio_Distribution.jpg");
						}
					}
					run("Distribution...", "parameter=Area automatic");
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__Area_Distribution.jpg");
						}
						else{
							saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__Area_Distribution.jpg");
						}
					}
					run("Distribution...", "parameter=Perim. automatic");
					if(saveResults==true){
						if(useImageFilename==true){
							saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__Perimeter_Distribution.jpg");
						}
						else{
							saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__Perimeter_Distribution.jpg");
						}
					}
		
					selectWindow("TL_IlluminationCorrected");
					run("Duplicate...", "title=TL_image_with_blueSpores");
					roiManager("Show All without labels");
					run("Colors...", "foreground=blue background=black selection=blue");
					run("Flatten");
					if(saveResults==true){
						if(useImageFilename==true){
					   		saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "TL_image_with_blueSpores.jpg");
					   	}
					   	else{
					   		saveAs("Jpeg", dir + "/Image_" + "__" + testImageNumber + "__" + nameTagSavedFiles + "TL_image_with_blueSpores.jpg");
					   	}
					}

					selectWindow("Blue");
					run("Duplicate...", "title=Blue_image_with_blueSpores");
					run("Enhance Contrast", "saturated=0.35");
					roiManager("Show All without labels");
					run("Colors...", "foreground=blue background=black selection=blue");
					run("Flatten");
					if(saveResults==true){
						if(useImageFilename==true){
					   		saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "Blue_image_with_blueSpores.jpg");
					   	}
					   	else{
					   		saveAs("Jpeg", dir + "/Image_" + "__" + testImageNumber + "__" + nameTagSavedFiles + "Blue_image_with_blueSpores.jpg");
					   	}
					}
				} //end of 'if(nROI_blueSpores>0)' block
				//*** End of object analysis for blue spores ***

//***************************************************************************************************************
			
				//*** Hard thresholding the Bright Spots-method green ROIs for green channel fluorescence to eliminate dim spores, used only when merging Internal Gradient and Bright Spots: ***
				if(nROI_greenSpores_BrightSpots>0){
					GreenSporesAboveGreenThreshold = newArray(nROI_greenSpores_BrightSpots);
					GreenSporesBelowGreenThreshold = newArray(nROI_greenSpores_BrightSpots);
					GreenSporesAboveGreenThresholdCounter = 0;
					GreenSporesBelowGreenThresholdCounter = 0;
					roiManager("reset");
					run("Clear Results");
					selectWindow("Green");
					run("Duplicate...", "title=Green_image_with_aboveThreshold_BrightSpots_greenSpores");
					selectWindow("Green_image_with_aboveThreshold_BrightSpots_greenSpores");
					run("8-bit");
					if(nROI_greenSpores_BrightSpots>0){
						if(useImageFilename==true){
							roiManager("open", dir + list[m] + "__GreenSpores_ROIs_BrightSpots.zip");
						}
						else{
							roiManager("open",  dir + "/Image_" + testImageNumber + "__GreenSpores_ROIs_BrightSpots.zip");
						}
					}
					for (green=0; green<nROI_greenSpores_BrightSpots; green++) {
						roiManager("Select", green);
						roiManager("Measure");
						updateResults();
						meanGreenAtGreenROI = getResult("Mean",green);
						if(meanGreenAtGreenROI >= greenThresholdForGreenSporeClassifier){
							GreenSporesAboveGreenThreshold[green] = green;
							GreenSporesBelowGreenThreshold[green] = 0;
							GreenSporesAboveGreenThresholdCounter++;
						}
						else{
							GreenSporesBelowGreenThreshold[green] = green;
							GreenSporesAboveGreenThreshold[green] = 0;
							GreenSporesBelowGreenThresholdCounter++;
						}
					}
					roiManager("Set Line Width", 2);
					roiManager("Set Color", "green");
					run("Colors...", "foreground=blue background=black selection=green");
					roiManager("Select", GreenSporesAboveGreenThreshold);
					roiManager("Draw");
					run("Flatten");
					run("Colors...", "foreground=yellow background=black selection=yellow");
					roiManager("Select", GreenSporesBelowGreenThreshold);
					roiManager("Draw");
					run("Flatten");
					if(saveResults==true){
						if(useImageFilename==true){
					   		saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "Green_image_with_aboveThreshold_BrightSpots_greenSpores.jpg");
					   	}
					   	else{
					   		saveAs("Jpeg", dir + "/Image_" + "__" + testImageNumber + "__" + nameTagSavedFiles + "Green_image_with_aboveThreshold_BrightSpots_greenSpores.jpg");
					   	}
					}
					print("Number of above-threshold and below-threshold green spores = " + GreenSporesAboveGreenThresholdCounter + " ; " + GreenSporesBelowGreenThresholdCounter);
					
					if(GreenSporesBelowGreenThresholdCounter>0){
						roiManager("Select", GreenSporesBelowGreenThreshold);
						if(GreenSporesBelowGreenThresholdCounter >= 2){ //Combine only works with >=2 ROIs
							roiManager("Combine");
						}
						roiManager("Delete");
					}
					nROI_greenSporesAboveGreenThreshold = roiManager("count");
					nROI_greenSpores_BrightSpots = nROI_greenSporesAboveGreenThreshold;
					if(saveResults==true && nROI_greenSporesAboveGreenThreshold>0){
							if(useImageFilename==true){
								roiManager("save", dir + list[m] + "__GreenSpores_ROIs_BrightSpots.zip");
							}
							else{
								roiManager("save",  dir + "/Image_" + testImageNumber + "__GreenSpores_ROIs_BrightSpots.zip");
							}
					}
				}

				//*** End of hard thresholding the Bright Spots-method green ROIs for green channel fluorescence to eliminate dim spores, used only when merging Internal Gradient and Bright Spots ***

//***************************************************************************************************************
				
				//*** Merging Inside Gradient and Bright Spot ROIs if such option selected: ***
				if(combineInternalGradientAndBrightSpotResults==true){
					roiManager("reset");
					if(nROI_greenSpores>0){
						if(useImageFilename==true){
							roiManager("open", dir + list[m] + "__GreenSpores_ROIs.zip");
						}
						else{
							roiManager("open",  dir + "/Image_" + testImageNumber + "__GreenSpores_ROIs.zip");
						}
					
						run("Select All");
						if(nROI_greenSpores>=2){
							roiManager("Combine");
						}
						roiManager("Add");	//now the merged ROI is in position "nROI_greenSpores" of the ROI array
					}
					
					if(nROI_greenSpores_BrightSpots>0){
						if(useImageFilename==true){
							roiManager("open", dir + list[m] + "__GreenSpores_ROIs_BrightSpots.zip");
						}
						else{
							roiManager("open",  dir + "/Image_" + testImageNumber + "__GreenSpores_ROIs_BrightSpots.zip");
						}
						GreenSporesAlreadyCounted = newArray(nROI_greenSpores_BrightSpots);
						GreenSporesAlreadyCountedCounter = 0;
						for (ibrightspot=nROI_greenSpores+1; ibrightspot<nROI_greenSpores_BrightSpots+nROI_greenSpores+1; ibrightspot++) {
							roiManager("Select", newArray(ibrightspot,nROI_greenSpores));
							roiManager("AND");
							if(selectionType != (-1)){ //already counted green spore
								GreenSporesAlreadyCounted[GreenSporesAlreadyCountedCounter]=ibrightspot;
								GreenSporesAlreadyCountedCounter++;	
							}
						}
	
						if(GreenSporesAlreadyCountedCounter>0){
							roiManager("Select", GreenSporesAlreadyCounted);
							if(GreenSporesAlreadyCountedCounter >= 2){ //Combine only works with >=2 ROIs
								roiManager("Combine");
							}
							roiManager("Delete");
						}
						roiManager("Select", nROI_greenSpores);
						roiManager("Delete");	//delete the merged original green ROIs
						nROI_greenSpores = roiManager("count");	//refresh and save the green ROI number, now including Bright Spot spores 
						print("New total spore count after Bright Spots added = " + nROI_greenSpores);
						if(saveResults==true && nROI_greenSpores>0){
							if(useImageFilename==true){
								roiManager("save", dir + list[m] + "__GreenSpores_ROIs.zip");
							}
							else{
								roiManager("save",  dir + "/Image_" + testImageNumber + "__GreenSpores_ROIs.zip");
							}
						}
					}
				}
				
				//*** End of merging Inside Gradient and Bright Spot ROIs ***
				
//***************************************************************************************************************
			
				//*** Analysis of green ROIs for blue spore fluorescence to classify in- and outside spores: ***
				GreenSporesOutside = newArray(nROI_greenSpores);
				GreenSporesInside = newArray(nROI_greenSpores);
				GreenSporesOutsideCounter = 0;
				GreenSporesInsideCounter = 0;
				roiManager("reset");
				run("Clear Results");
				selectWindow("Blue");
				run("Duplicate...", "title=Blue_image_with_classified_greenSpores");
				selectWindow("Blue_image_with_classified_greenSpores");
				run("8-bit");
				if(nROI_greenSpores>0){
					if(useImageFilename==true){
						roiManager("open", dir + list[m] + "__GreenSpores_ROIs.zip");
					}
					else{
						roiManager("open",  dir + "/Image_" + testImageNumber + "__GreenSpores_ROIs.zip");
					}
				}
				for (greenSp=0; greenSp<nROI_greenSpores; greenSp++) {
					roiManager("Select", greenSp);
					roiManager("Measure");
					updateResults();
					meanBlueAtGreenROI = getResult("Mean",greenSp);
					if(meanBlueAtGreenROI >= blueThresholdForGreenSporeClassifier){
						GreenSporesOutside[greenSp] = greenSp;
						GreenSporesInside[greenSp] = 0;
						GreenSporesOutsideCounter++;
					}
					else{
						GreenSporesInside[greenSp] = greenSp;
						GreenSporesOutside[greenSp] = 0;
						GreenSporesInsideCounter++;
					}
				}
				roiManager("Set Line Width", 2);
				roiManager("Set Color", "green");
				run("Colors...", "foreground=blue background=black selection=green");
				roiManager("Select", GreenSporesInside);
				roiManager("Draw");
				run("Flatten");
				run("Colors...", "foreground=yellow background=black selection=yellow");
				roiManager("Select", GreenSporesOutside);
				roiManager("Draw");
				run("Flatten");
				if(saveResults==true){
					if(useImageFilename==true){
				   		saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "Blue_image_with_classified_greenSpores.jpg");
				   	}
				   	else{
				   		saveAs("Jpeg", dir + "/Image_" + "__" + testImageNumber + "__" + nameTagSavedFiles + "Blue_image_with_classified_greenSpores.jpg");
				   	}
				}
				print("Number of outside and inside green spores = " + GreenSporesOutsideCounter + " ; " + GreenSporesInsideCounter);
				
				selectWindow("Green");
				run("Duplicate...", "title=Green_image_with_classified_greenSpores");
				selectWindow("Green_image_with_classified_greenSpores");
				roiManager("Set Line Width", 2);
				run("Colors...", "foreground=blue background=black selection=green");
				if(GreenSporesInsideCounter>0){
					roiManager("Select", GreenSporesInside);
					roiManager("Draw");
					run("Flatten");
				}
				run("Colors...", "foreground=yellow background=black selection=yellow");
				if(GreenSporesOutsideCounter>0){
					roiManager("Select", GreenSporesOutside);
					roiManager("Draw");
					run("Flatten");
				}
				if(saveResults==true){
					if(useImageFilename==true){
				   		saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "Green_image_with_classified_greenSpores.jpg");
				   	}
				   	else{
				   		saveAs("Jpeg", dir + "/Image_" + "__" + testImageNumber + "__" + nameTagSavedFiles + "Green_image_with_classified_greenSpores.jpg");
				   	}
				}

				roiManager("reset");//save ROIs for green spores that are NOT blue, i.e. they are inside MPs
				if(nROI_greenSpores>0){
					if(useImageFilename==true){
						roiManager("open", dir + list[m] + "__GreenSpores_ROIs.zip");
					}
					else{
						roiManager("open",  dir + "/Image_" + testImageNumber + "__GreenSpores_ROIs.zip");
					}
				}
				if(GreenSporesOutsideCounter>0){
					roiManager("Select", GreenSporesOutside);
					roiManager("Update");
					if(GreenSporesOutsideCounter >= 2){ //Combine only works with >=2 ROIs
						roiManager("Combine");
					}
					roiManager("Delete");
				}
				nROI_greenSporesInside = roiManager("count");
				if(saveResults==true && nROI_greenSporesInside>0){
						if(useImageFilename==true){
							roiManager("save", dir + list[m] + "__GreenSporesInside_ROIs.zip");
						}
						else{
							roiManager("save",  dir + "/Image_" + testImageNumber + "__GreenSporesInside_ROIs.zip");
						}
				}

				roiManager("reset");//save ROIs for green spores that are also blue, i.e. they are outside MPs
				if(nROI_greenSpores>0){
					if(useImageFilename==true){
						roiManager("open", dir + list[m] + "__GreenSpores_ROIs.zip");
					}
					else{
						roiManager("open",  dir + "/Image_" + testImageNumber + "__GreenSpores_ROIs.zip");
					}
				}
				if(GreenSporesInsideCounter>0){
					roiManager("Select", GreenSporesInside);
					roiManager("Update");
					if(GreenSporesInsideCounter >= 2){ //Combine only works with >=2 ROIs
						roiManager("Combine");
					}
					roiManager("Delete");
				}
				nROI_greenSporesOutside = roiManager("count");
				if(saveResults==true && nROI_greenSporesOutside>0){
						if(useImageFilename==true){
							roiManager("save", dir + list[m] + "__GreenSporesOutside_ROIs.zip");
						}
						else{
							roiManager("save",  dir + "/Image_" + testImageNumber + "__GreenSporesOutside_ROIs.zip");
						}
				}
				
				//*** End of analysis of green ROIs for blue spore fluorescence to classify in- and outside spores: ***

//***************************************************************************************************************

				//*** Saving images begins: ***
				roiManager("reset");
				selectWindow("TL_IlluminationCorrected");
				if(saveResults==true){
					if(useImageFilename==true){
				   		saveAs("png", dir + list[m] + "__" + nameTagSavedFiles + "__TL_image_Illumination_corrected.png");
				   	}
				   	else{
				   		saveAs("png", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__TL_image_Illumination_corrected.png");
				   	}
				}
				
				if(nROI_macrophages>0){
					if(useImageFilename==true){
						roiManager("open", dir + list[m] + "__Macrophages_ROIs.zip");
					}
					else{
						roiManager("open",  dir + "/Image_" + testImageNumber + "__Macrophages_ROIs.zip");
					}
					nr_macrophages=roiManager("count");
					Macrophages_01 = newArray(nr_macrophages);
					roiManager("Set Fill Color", "green");
					roiManager("Set Color", "yellow");
					roiManager("Set Line Width", 2);
					for (i=0; i<nr_macrophages; i++) {
						Macrophages_01[i] = i;
						roiManager("select", Macrophages_01);
						roiManager("Draw");
					}
				}
				run("Flatten");
				if(saveResults==true){
					if(useImageFilename==true){
				   		saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__Raw_image_with_macrophages.jpg");
				   	}
				   	else{
				   		saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__Raw_image_with_macrophages.jpg");
				   	}
				}
				//*** Saving images ends ***

				//*** Merge all components into one image and save it ***
				if(useImageFilename==true){
			   		macrophageWindowName=list[m] + "__" + nameTagSavedFiles + "__Raw_image_with_macrophages.jpg";
			   		blueSporesWindowName=list[m] + "__" + nameTagSavedFiles + "SegmentedBlueSpores.jpg";
			   		greenSporesWindowName=list[m] + "__" + nameTagSavedFiles + "SegmentedGreenSpores.jpg";
			   		selectWindow(macrophageWindowName);
			   		selectWindow(blueSporesWindowName);
			   		run("Invert");
					run("Blue");
					run("RGB Color");
					run("Merge Channels...", "c3=" + blueSporesWindowName + " c4=" + macrophageWindowName + " keep");
					selectWindow(greenSporesWindowName);
					run("Invert");
					run("Green");
					run("RGB Color");
					selectWindow("RGB");
					run("Merge Channels...", "c2=" + greenSporesWindowName + " c4=RGB keep");
			   	}
			   	else{
			   		macrophageWindowName="/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__Raw_image_with_macrophages.jpg";
			   		blueSporesWindowName="/Image_" + testImageNumber + "__" + nameTagSavedFiles + "SegmentedBlueSpores.jpg";
			   		greenSporesWindowName="/Image_" + testImageNumber + "__" + nameTagSavedFiles + "SegmentedGreenSpores.jpg";
			   		selectWindow(macrophageWindowName);
			   		selectWindow(blueSporesWindowName);
			   		run("Invert");
					run("Blue");
					run("RGB Color");
					run("Merge Channels...", "c3=" + blueSporesWindowName + " c4=" + macrophageWindowName + " keep");
					selectWindow(greenSporesWindowName);
					run("Invert");
					run("Green");
					run("RGB Color");
					selectWindow("RGB");
					run("Merge Channels...", "c2=" + greenSporesWindowName + " c4=RGB keep");
			   	}
			   	if(saveResults==true){
					if(useImageFilename==true){
				   		saveAs("Jpeg", dir + list[m] + "__" + nameTagSavedFiles + "__AllComponents_Merged.jpg");
				   	}
				   	else{
				   		saveAs("Jpeg", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__AllComponents_Merged.jpg");
				   	}
				}
				//*** End of image merging and saving ***

//***************************************************************************************************************

				//*** Calculate ROI overlap for macrophages and green spores *** 
				roiManager("reset");
				if(nROI_macrophages>0){
					if(useImageFilename==true){
						roiManager("open", dir + list[m] + "__Macrophages_ROIs.zip");
					}
					else{
						roiManager("open",  dir + "/Image_" + testImageNumber + "__Macrophages_ROIs.zip");
					}
					if(nROI_greenSpores>0){
						if(useImageFilename==true){
							roiManager("open", dir + list[m] + "__GreenSpores_ROIs.zip");
						}
						else{
							roiManager("open",  dir + "/Image_" + testImageNumber + "__GreenSpores_ROIs.zip");
						}
					}
					if(useImageFilename==true){
				   		mergedWindowName=list[m] + "__" + nameTagSavedFiles + "__AllComponents_Merged.jpg";
				   	}
				   	else{
				   		mergedWindowName="/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__AllComponents_Merged.jpg";
				   	}
					numberOfGreenSporesInsideMacrophages = 0;
					numberOfNotBlueGreenSporesInsideMacrophages = 0;
					alreadyCounted = newArray(nROI_greenSpores);//in order to avoid counting the same spore twice if it overlaps two macrophages
					roiManager("Set Color", "red");
					roiManager("Set Line Width", 2);
					for (imacro=0; imacro<nROI_macrophages; imacro++) {
						for (ispore=nROI_macrophages; ispore<nROI_greenSpores+nROI_macrophages; ispore++) {
							roiManager("Select", newArray(imacro,ispore));
							roiManager("AND");
							if(selectionType>-1){ //spore overlaps with macrophage
								if(!isElement(ispore - nROI_macrophages,alreadyCounted)){
									numberOfGreenSporesInsideMacrophages++;
									alreadyCounted[ispore - nROI_macrophages]= ispore - nROI_macrophages;
									roiManager("Draw");
									if(GreenSporesInside[ispore - nROI_macrophages] != 0){//== ispore - nROI_macrophages){
										 numberOfNotBlueGreenSporesInsideMacrophages++;
									}
								}
							}
						}
					}
					print("Number of unclassified green spores inside or touching macrophages = " + numberOfGreenSporesInsideMacrophages);
					numberOfUnclassifiedGreenSporesPerMacrophage = numberOfGreenSporesInsideMacrophages / nROI_macrophages;
					print("Number of unclassified green spores per macrophage (inside or adherent) = " + numberOfUnclassifiedGreenSporesPerMacrophage);
					numberOfClassifiedGreenSporesPerMacrophage = GreenSporesInsideCounter / nROI_macrophages;
					print("Number of classified phagocytosed green spores per macrophage = " + numberOfClassifiedGreenSporesPerMacrophage);
					print("Total number of macrophages = " + nROI_macrophages);
					numberOfAdherentGreenSpores = numberOfGreenSporesInsideMacrophages - numberOfNotBlueGreenSporesInsideMacrophages;//GreenSporesInsideCounter;
					numberOfAdherentGreenSporesPerMacrophage = numberOfAdherentGreenSpores / nROI_macrophages;
					print("Total number of adherent green spores = " + numberOfAdherentGreenSpores);
					print("Number of classified adherent green spores per macrophage = " + numberOfAdherentGreenSporesPerMacrophage);
				}
				//*** End of ROI overlap calculation for macrophages and green spores ***


				//*** Calculate ROI overlap for macrophages and blue spores *** 
				roiManager("reset");
				if(nROI_macrophages>0){
					if(useImageFilename==true){
						roiManager("open", dir + list[m] + "__Macrophages_ROIs.zip");
					}
					else{
						roiManager("open",  dir + "/Image_" + testImageNumber + "__Macrophages_ROIs.zip");
					}
					if(nROI_greenSporesOutside>0){
						if(useImageFilename==true){
							roiManager("open", dir + list[m] + "__GreenSporesOutside_ROIs.zip");
						}
						else{
							roiManager("open",  dir + "/Image_" + testImageNumber + "__GreenSporesOutside_ROIs.zip");
						}
					}
					if(useImageFilename==true){
				   		mergedWindowName=list[m] + "__" + nameTagSavedFiles + "__AllComponents_Merged.jpg";
				   	}
				   	else{
				   		mergedWindowName="/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__AllComponents_Merged.jpg";
				   	}
					numberOfBlueSporesOverlappingMacrophages= 0;
					alreadyCounted = newArray(nROI_greenSporesOutside);//in order to avoid counting the same spore twice if it overlaps two macrophages
					roiManager("Set Color", "red");
					roiManager("Set Line Width", 2);
					for (imacro=0; imacro<nROI_macrophages; imacro++) {
						for (ispore=nROI_macrophages; ispore<nROI_greenSporesOutside+nROI_macrophages; ispore++) {
							roiManager("Select", newArray(imacro,ispore));
							roiManager("AND");
							if(selectionType>-1){ //spore overlaps with macrophage
								if(!isElement(ispore - nROI_macrophages,alreadyCounted)){
									numberOfBlueSporesOverlappingMacrophages++;
									alreadyCounted[ispore - nROI_macrophages]= ispore - nROI_macrophages;
									roiManager("Draw");
								}
							}
						}
					}
					numberOfAdherentBlueSpores = numberOfBlueSporesOverlappingMacrophages;//numberOfNotBlueGreenSporesInsideMacrophages;//GreenSporesInsideCounter;
					numberOfAdherentGreenSporesPerMacrophage = numberOfAdherentBlueSpores / nROI_macrophages;
					print("Total number of adherent blue spores = " + numberOfAdherentBlueSpores);
					print("Number of classified adherent spores per macrophage = " + numberOfAdherentGreenSporesPerMacrophage);
				}
				//*** End of ROI overlap calculation for macrophages and blue spores ***

				//*** Calculate ROI overlap for macrophages and spores, excluding edges *** 
				if(excludeEdges == true){
					//Count all green spores (w/ and w/o blue) and non-edge macrophages:
					roiManager("reset");
					if(nROI_macrophages>0){
						if(useImageFilename==true){
							roiManager("open", dir + list[m] + "__Macrophages_ROIs.zip");
						}
						else{
							roiManager("open",  dir + "/Image_" + testImageNumber + "__Macrophages_ROIs.zip");
						}
						if(nROI_greenSpores>0){
							if(useImageFilename==true){
								roiManager("open", dir + list[m] + "__GreenSpores_ROIs.zip");
							}
							else{
								roiManager("open",  dir + "/Image_" + testImageNumber + "__GreenSpores_ROIs.zip");
							}
						}
						if(useImageFilename==true){
							roiManager("open", dir + list[m] + "__Edges_ROIs.zip");
						}
						else{
							roiManager("open",  dir + "/Image_" + testImageNumber + "__Edges_ROIs.zip");
						}
						if(useImageFilename==true){
					   		mergedWindowNameNonEdge=list[m] + "__" + nameTagSavedFiles + "__AllComponents_NonEdge_Merged.jpg";
					   	}
					   	else{
					   		mergedWindowNameNonEdge="/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__AllComponents_NonEdge_Merged.jpg";
					   	}
						numberOfGreenSporesInsideMacrophages_excludingEdges = 0;
						numberOfMacrophages_excludingEdges = 0;
						alreadyCounted = newArray(nROI_greenSpores);//in order to avoid counting the same spore twice if it overlaps two macrophages
						for (imacro=0; imacro<nROI_macrophages; imacro++) {
							roiManager("Select", newArray(imacro,nROI_greenSpores+nROI_macrophages+4));
							roiManager("AND");
							if(selectionType == (-1)){ //non-edge macrophage
								numberOfMacrophages_excludingEdges++;
								for (ispore=nROI_macrophages; ispore<nROI_greenSpores+nROI_macrophages; ispore++) {
									roiManager("Select", newArray(imacro,ispore));
									roiManager("AND");
									if(selectionType>-1){ //spore and macrophage overlap
										if(!isElement(ispore - nROI_macrophages,alreadyCounted)){
											numberOfGreenSporesInsideMacrophages_excludingEdges++;
											alreadyCounted[ispore - nROI_macrophages]= ispore - nROI_macrophages;
											roiManager("Draw");
										}
									}	
								}
							}
						}
						print("Number of unclassified green spores inside or touching macrophages excluding the edge = " + numberOfGreenSporesInsideMacrophages_excludingEdges);
						numberOfUnclassifiedGreenSporesPerMacrophage_excludingEdges = numberOfGreenSporesInsideMacrophages_excludingEdges / numberOfMacrophages_excludingEdges;
						print("Number of unclassified green spores per macrophage excluding the edge (inside or adherent) = " + numberOfUnclassifiedGreenSporesPerMacrophage);
					}

					//Count green-only spores and non-edge macrophages:
					roiManager("reset");
					if(nROI_macrophages>0){
						if(useImageFilename==true){
							roiManager("open", dir + list[m] + "__Macrophages_ROIs.zip");
						}
						else{
							roiManager("open",  dir + "/Image_" + testImageNumber + "__Macrophages_ROIs.zip");
						}
						if(nROI_greenSporesInside>0){
							if(useImageFilename==true){
								roiManager("open", dir + list[m] + "__GreenSporesInside_ROIs.zip");
							}
							else{
								roiManager("open",  dir + "/Image_" + testImageNumber + "__GreenSporesInside_ROIs.zip");
							}
						}
						if(useImageFilename==true){
							roiManager("open", dir + list[m] + "__Edges_ROIs.zip");
						}
						else{
							roiManager("open",  dir + "/Image_" + testImageNumber + "__Edges_ROIs.zip");
						}
						if(useImageFilename==true){
					   		mergedWindowNameNonEdge=list[m] + "__" + nameTagSavedFiles + "__AllComponents_NonEdge_Merged.jpg";
					   	}
					   	else{
					   		mergedWindowNameNonEdge="/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__AllComponents_NonEdge_Merged.jpg";
					   	}
						numberOfGreenOnlySporesInsideMacrophages_excludingEdges = 0;
						alreadyCounted = newArray(nROI_greenSporesInside);//in order to avoid counting the same spore twice if it overlaps two macrophages
						for (imacro=0; imacro<nROI_macrophages; imacro++) {
							roiManager("Select", newArray(imacro,nROI_greenSporesInside+nROI_macrophages+4));
							roiManager("AND");
							if(selectionType == (-1)){ //non-edge macrophage
								for (ispore=nROI_macrophages; ispore<nROI_greenSporesInside+nROI_macrophages; ispore++) {
									roiManager("Select", newArray(imacro,ispore));
									roiManager("AND");
									if(selectionType>-1){ //spore and macrophage overlap
										if(!isElement(ispore - nROI_macrophages,alreadyCounted)){
											numberOfGreenOnlySporesInsideMacrophages_excludingEdges++;
											alreadyCounted[ispore - nROI_macrophages]= ispore - nROI_macrophages;
											roiManager("Draw");
										}
									}	
								}
							}
						}
						numberOfClassifiedGreenOnlySporesPerMacrophage_excludingEdges = numberOfGreenOnlySporesInsideMacrophages_excludingEdges / numberOfMacrophages_excludingEdges;
						print("Number of classified phagocytosed green spores excluding the edge = " + numberOfGreenOnlySporesInsideMacrophages_excludingEdges);
						print("Number of classified phagocytosed green spores per macrophage excluding the edge = " + numberOfClassifiedGreenOnlySporesPerMacrophage_excludingEdges);
					}

					//Count blue spores and non-edge macrophages:
					roiManager("reset");
					if(nROI_macrophages>0){
						if(useImageFilename==true){
							roiManager("open", dir + list[m] + "__Macrophages_ROIs.zip");
						}
						else{
							roiManager("open",  dir + "/Image_" + testImageNumber + "__Macrophages_ROIs.zip");
						}
						if(nROI_greenSporesOutside>0){
							if(useImageFilename==true){
								roiManager("open", dir + list[m] + "__GreenSporesOutside_ROIs.zip");
							}
							else{
								roiManager("open",  dir + "/Image_" + testImageNumber + "__GreenSporesOutside_ROIs.zip");
							}
						}
						if(useImageFilename==true){
							roiManager("open", dir + list[m] + "__Edges_ROIs.zip");
						}
						else{
							roiManager("open",  dir + "/Image_" + testImageNumber + "__Edges_ROIs.zip");
						}
						if(useImageFilename==true){
					   		mergedWindowNameNonEdge=list[m] + "__" + nameTagSavedFiles + "__BlueSpores_NonEdge_Merged.jpg";
					   	}
					   	else{
					   		mergedWindowNameNonEdge="/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__BlueSPores_NonEdge_Merged.jpg";
					   	}
						numberOfBlueSporesOverlappingMacrophages_excludingEdges = 0;
						alreadyCounted = newArray(nROI_greenSpores);//in order to avoid counting the same spore twice if it overlaps two macrophages
						for (imacro=0; imacro<nROI_macrophages; imacro++) {
							roiManager("Select", newArray(imacro,nROI_greenSporesOutside+nROI_macrophages+4));
							roiManager("AND");
							if(selectionType == (-1)){ //non-edge macrophage
								for (ispore=nROI_macrophages; ispore<nROI_greenSporesOutside+nROI_macrophages; ispore++) {
									roiManager("Select", newArray(imacro,ispore));
									roiManager("AND");
									if(selectionType>-1){ //spore and macrophage overlap
										if(!isElement(ispore - nROI_macrophages,alreadyCounted)){
											numberOfBlueSporesOverlappingMacrophages_excludingEdges++;
											alreadyCounted[ispore - nROI_macrophages]= ispore - nROI_macrophages;
											roiManager("Draw");
										}
									}	
								}
							}
						}
						numberOfBlueSporesPerMacrophage_excludingEdges = numberOfBlueSporesOverlappingMacrophages_excludingEdges / numberOfMacrophages_excludingEdges;
						print("Number of overlapping blue spores per macrophage excluding the edge = " + numberOfBlueSporesPerMacrophage_excludingEdges);
						numberOfAdherentBlueSpores_excludingEdges = numberOfBlueSporesOverlappingMacrophages_excludingEdges;
						numberOfAdherentBlueSporesPerMacrophage_excludingEdges = numberOfAdherentBlueSpores_excludingEdges / numberOfMacrophages_excludingEdges;
						print("Total number of adherent blue spores excluding the edge = " + numberOfAdherentBlueSpores_excludingEdges);
						print("Number of adherent blue spores per macrophage excluding the edge = " + numberOfAdherentBlueSporesPerMacrophage_excludingEdges);
					}

					//Calculate phagocytosis ratio:
					roiManager("reset");
					if(nROI_macrophages>0){
						if(useImageFilename==true){
							roiManager("open", dir + list[m] + "__Macrophages_ROIs.zip");
						}
						else{
							roiManager("open",  dir + "/Image_" + testImageNumber + "__Macrophages_ROIs.zip");
						}
						if(nROI_greenSporesInside>0){
							if(useImageFilename==true){
								roiManager("open", dir + list[m] + "__GreenSporesInside_ROIs.zip");
							}
							else{
								roiManager("open",  dir + "/Image_" + testImageNumber + "__GreenSporesInside_ROIs.zip");
							}
						}
						if(useImageFilename==true){
							roiManager("open", dir + list[m] + "__Edges_ROIs.zip");
						}
						else{
							roiManager("open",  dir + "/Image_" + testImageNumber + "__Edges_ROIs.zip");
						}
						
						numberOfInsideGreenSporesInsideMacrophages_excludingEdges = 0;
						alreadyCounted = newArray(nROI_greenSpores);//in order to avoid counting the same spore twice if it overlaps two macrophages
						for (imacro=0; imacro<nROI_macrophages; imacro++) {
							roiManager("Select", newArray(imacro,nROI_greenSporesInside+nROI_macrophages+4));
							roiManager("AND");
							if(selectionType == (-1) && nROI_greenSporesInside>=1){ //non-edge macrophage
								for (ispore=nROI_macrophages; ispore<nROI_greenSporesInside+nROI_macrophages; ispore++) {
									roiManager("Select", newArray(imacro,ispore));
									roiManager("AND");
									if(selectionType>-1){
										if(!isElement(ispore - nROI_macrophages,alreadyCounted)){
											numberOfInsideGreenSporesInsideMacrophages_excludingEdges++;
											alreadyCounted[ispore - nROI_macrophages]= ispore - nROI_macrophages;
											roiManager("Draw");
										}
									}	
								}
							}
						}
						numberOfPhagocytosedGreenSporesPerMacrophage = nROI_greenSporesInside / numberOfMacrophages;
						numberOfPhagocytosedGreenSporesPerMacrophage_excludingEdges = numberOfInsideGreenSporesInsideMacrophages_excludingEdges / numberOfMacrophages_excludingEdges;
						print("Number of phagocytosed green spores, total = " + nROI_greenSporesInside);
						print("Number of phagocytosed green spores, excluding edges = " + numberOfInsideGreenSporesInsideMacrophages_excludingEdges);
						print("Number of phagocytosed green spores per macrophage, total = " + numberOfPhagocytosedGreenSporesPerMacrophage);
						print("Number of phagocytosed green spores per macrophage, excluding edges = " + numberOfPhagocytosedGreenSporesPerMacrophage_excludingEdges);
						phagocytosisRatio_excludingEdges = numberOfInsideGreenSporesInsideMacrophages_excludingEdges / (numberOfInsideGreenSporesInsideMacrophages_excludingEdges + numberOfAdherentBlueSpores_excludingEdges);
						print("Phagocytosis ratio, excluding edges = " + phagocytosisRatio_excludingEdges);
						phagocytosisRatioWithKaswaraCorrection_excludingEdges = (numberOfInsideGreenSporesInsideMacrophages_excludingEdges*multiplierPhagocytosedConidia) / (numberOfInsideGreenSporesInsideMacrophages_excludingEdges*multiplierPhagocytosedConidia + numberOfAdherentBlueSpores_excludingEdges*multiplierAdherentConidia);
						print("Phagocytosis ratio with Kaswara-correction, excluding edges = " + phagocytosisRatioWithKaswaraCorrection_excludingEdges);
					}

					//Calculate uptake ratio:
					roiManager("reset");
					if(nROI_macrophages>0){
						if(useImageFilename==true){
							roiManager("open", dir + list[m] + "__Macrophages_ROIs.zip");
						}
						else{
							roiManager("open",  dir + "/Image_" + testImageNumber + "__Macrophages_ROIs.zip");
						}
						if(nROI_greenSporesInside>0){
							if(useImageFilename==true){
								roiManager("open", dir + list[m] + "__GreenSporesInside_ROIs.zip");
							}
							else{
								roiManager("open",  dir + "/Image_" + testImageNumber + "__GreenSporesInside_ROIs.zip");
							}
						}
						if(useImageFilename==true){
							roiManager("open", dir + list[m] + "__Edges_ROIs.zip");
						}
						else{
							roiManager("open",  dir + "/Image_" + testImageNumber + "__Edges_ROIs.zip");
						}
						
						numberOfMacrophagesWithPhagocytosedGreenSpores = 0;
						alreadyCounted = newArray(nROI_greenSpores);//in order to avoid counting the same spore twice if it overlaps two macrophages
						for (imacro=0; imacro<nROI_macrophages; imacro++) {
							numberOfInsideGreenSpores_excludingEdges = 0;
							roiManager("Select", newArray(imacro,nROI_greenSporesInside+nROI_macrophages+4));
							roiManager("AND");
							if(selectionType == (-1) && nROI_greenSporesInside>=1){ //non-edge macrophage
								for (ispore=nROI_macrophages; ispore<nROI_greenSporesInside+nROI_macrophages; ispore++) {
									roiManager("Select", newArray(imacro,ispore));
									roiManager("AND");
									if(selectionType>-1){
										if(!isElement(ispore - nROI_macrophages,alreadyCounted)){
											numberOfInsideGreenSpores_excludingEdges++;
											alreadyCounted[ispore - nROI_macrophages]= ispore - nROI_macrophages;
											roiManager("Draw");
										}
									}	
								}
								if(numberOfInsideGreenSpores_excludingEdges >= 1){
									numberOfMacrophagesWithPhagocytosedGreenSpores++;
								}
							}
						}
						uptakeRatio_excludingEdges = numberOfMacrophagesWithPhagocytosedGreenSpores / numberOfMacrophages_excludingEdges; 
						print("M_phag and M_total, excl edgs = " + numberOfMacrophagesWithPhagocytosedGreenSpores + " ; " + numberOfMacrophages_excludingEdges);
						print("Uptake ratio, excluding edges = " + uptakeRatio_excludingEdges);
						phagocyticIndex_excludingEdges = uptakeRatio_excludingEdges * numberOfInsideGreenSporesInsideMacrophages_excludingEdges / numberOfMacrophages_excludingEdges;
						print("Phagocytic index, excluding edges = " + phagocyticIndex_excludingEdges);
						symmetrizedPhagocyticIndex_excludingEdges = uptakeRatio_excludingEdges * phagocytosisRatio_excludingEdges;
						print("Symmetrized phagocytic index, excluding edges = " + symmetrizedPhagocyticIndex_excludingEdges);
						symmetrizedPhagocyticIndexWithKaswaraCorrection_excludingEdges = uptakeRatio_excludingEdges * phagocytosisRatioWithKaswaraCorrection_excludingEdges;
						print("Symmetrized phagocytic index with Kaswara-correction, excluding edges = " + symmetrizedPhagocyticIndexWithKaswaraCorrection_excludingEdges);
						
						//Save the results file in a spreadsheet-compatible format, either with or without Kaswara-correction
						if(multiplierPhagocytosedConidia>1.01 && multiplierAdherentConidia>1.01){ //using Kaswara-correction for out-of-focus conidia
							print(saveAllFile, currentImagename + "	\t" + d2s(numberOfMacrophages,0) + "	\t" + d2s(nROI_greenSpores,0) + "	\t" + d2s(numberOfInsideGreenSporesInsideMacrophages_excludingEdges,0) + "	\t" + d2s(numberOfInsideGreenSporesInsideMacrophages_excludingEdges*multiplierPhagocytosedConidia,0) + "	\t" + d2s(numberOfAdherentBlueSpores_excludingEdges,0) + "	\t" + d2s(numberOfAdherentBlueSpores_excludingEdges*multiplierAdherentConidia,0) + "	\t" + d2s(numberOfMacrophagesWithPhagocytosedGreenSpores,0) + "	\t" + d2s(numberOfMacrophages_excludingEdges,0) + "	\t" + d2s(phagocytosisRatio_excludingEdges,3) + "	\t" + d2s(phagocytosisRatioWithKaswaraCorrection_excludingEdges,3) + "	\t" + d2s(uptakeRatio_excludingEdges,3) + "	\t" + d2s(phagocyticIndex_excludingEdges,3) + "	\t" + d2s(symmetrizedPhagocyticIndex_excludingEdges,3) + "	\t" + d2s(symmetrizedPhagocyticIndexWithKaswaraCorrection_excludingEdges,3) +  "	\n");
						}
						else { //no correction necessary
							print(saveAllFile, currentImagename + "	\t" + d2s(numberOfMacrophages,0) + "	\t" + d2s(nROI_greenSpores,0) + "	\t" + d2s(numberOfInsideGreenSporesInsideMacrophages_excludingEdges,0) + "	\t" + d2s(numberOfAdherentBlueSpores_excludingEdges,0) + "	\t" + d2s(numberOfMacrophagesWithPhagocytosedGreenSpores,0) + "	\t" + d2s(numberOfMacrophages_excludingEdges,0) + "	\t" + d2s(phagocytosisRatio_excludingEdges,3) + "	\t" + d2s(uptakeRatio_excludingEdges,3) + "	\t" + d2s(phagocyticIndex_excludingEdges,3) + "	\t" + d2s(symmetrizedPhagocyticIndex_excludingEdges,3) +  "	\n");
						}						
					}
				} //end of if(excludeEdges == true)
				//*** End of ROI overlap calculation, excluding edges ***

				if(closeAllWindows==true){
					run("Close All");
				}		
			} //end of image type 'if' block
		} //end of 'if' block that finds specific image file names
	} //end of main 'for' loop that goes thru all images in a folder
} //end of loop for subfolders 5.10.16

//Save parameters from GUI:
print(" ");
print("################################ PARAMETERS ################################");
print("Illumination correction sigma for TL: " + illuminationCorrectionSigmaForTL);
print("Excluding edges?: " + excludeEdges);
print("Data from entire population?: " + gatherResultsForEntireImageSet);
print("Using specific image groups?: " + useSpecificImageGroups);
print("Image search terms: " + imageType + ", " + searchTerm_1 + ", " + searchTerm_2 + ", " + searchTerm_3);
print("Image numbers for background, 1st, last, test: " + backgroundImageNumber + ", " + firstImageNumber + ", " + lastImageNumber + ", " + testImageNumber);
print("Macrophage-finding criteria: min size, max size, min circularity, max circularity: " + minMacrophageSize + ", " + maxMacrophageSize + ", " + minMacrophageCircularity + ", " + maxMacrophageCircularity);
print("Spore-finding criteria: min size, max size, min circularity, max circularity: " + minSporeSize + ", " + maxSporeSize + ", " + minSporeCircularity + ", " + maxSporeCircularity);
print("Watershed for macrophages, spores: " + watershedOnMacrophages + ", " + watershedOnSpores);
print("Pre-processing: CLAHE y/n, blocks, bins, max slope: " + applyCLAHE + ", " + CLAHEblocks + ", " + CLAHEbins + ", " + CLAHEslope);
print("Threshold method for Hessian, for green fluorescence, and for blue fluorescence: " + thresholdMethodHessian + " ; " + thresholdMethodGreenFluorescence + " ; " + thresholdMethodBlueFluorescence);
print("Internal Gradients radius; Threshold multiplier for lower and upper autothreshold for green fluorescence when using Internal Gradient method: " + internalGradientRadiusGreen + " ; " + lowerThresholdMultiplier + " ; " + upperThresholdMultiplier);
print("Rolling ball radius spores background: " + rollingBallRadius);
print("Remove outliers for macrophages ROI, step 1, step 2: " + removeOutliersStep1 + " , " + removeOutliersStep2);
print("Gaussian smoothing for macrophages, TL spores, FLSC spores: " + gaussianSmoothingForMacrophages + ", " + gaussianSmoothingForSpores + ", " + gaussianBlurForSpores);
print("Hessian smoothing for macrophages, TL spores: " + hessianSmoothingForMacrophages + ", " + hessianSmoothingForSpores);
print("Dilate/erode for macrophages, spores: " + dilateErodeStepsForMacrophages + ", " + dilateErodeStepsForSpores);
print("Additional erosion steps for macrophages: " + additionalErodeStepsForMacrophages);
print("Exclude edges?; by how many pixels? " + excludeEdges + " ; " + edgeWidth);
print("Kaswara correction factor for phagocytosed and adherent conidia? " + multiplierPhagocytosedConidia + " ; " + multiplierAdherentConidia);
print("Lower and upper threshold multiplier for macrophages, used for Mohamed's Egyptian strain: " + lowerThresholdMultiplierMacrophages + " ; " + upperThresholdMultiplierMacrophages);
print("Blue threshold for green spore classifier (if not using segmented blue channel) " + blueThresholdForGreenSporeClassifier);
print("Green threshold for green spore classifier (if using Bright Spots or Combo method) " + greenThresholdForGreenSporeClassifier);
print("Dim channel multipler for green, blue channel: " + greenChannelMultiplierForDimData + " ; " + blueChannelMultiplierForDimData);
selectWindow("Log");

if(saveResults==true){
	if(useImageFilename==true){
   		saveAs("Text", dir + currentImagename + "__" + nameTagSavedFiles +  "__Parameter_settings.txt");
   	}
   	else{
   		saveAs("Text", dir + "/Image_" + testImageNumber + "__" + nameTagSavedFiles + "__Parameter_settings.txt");
   	}
}

File.close(saveAllFile); 

//end of parameter saving



if(closeAllWindows==true){
	run("Close All");
	if (isOpen("Log")){ 
		selectWindow("Log");
		run("Close");
	}
	if (isOpen("Summary")){ 
		selectWindow("Summary");
		run("Close");
	}
    if (isOpen("Results")){ 
		selectWindow("Results");
		run("Close");
    }
    if (isOpen("ROI Manager")){ 
		selectWindow("ROI Manager");
		run("Close");
    }
}
 
