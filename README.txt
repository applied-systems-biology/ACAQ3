read.me 
-------------------------------------------------------------------------------
This package contains code that implements the Hessian-based macrophage segmentation algorithm. 
In addition, the macro provides segmentation tools for fungal conidia and spores, based on their 
fluorescence labelling. 
Full details of the algorithm and the rest of the macro can be found in 
the paper by Cseresnyes et al. (2017), Hessian-based quantitative image analysis of host-pathogen confrontation assays, 
Cytometry A, currently under revision . The paper can be found by 
contacting the corresponding author using the email address 
thilo.figge@leibniz-hki.de.

With all questions, please contact:
thilo.figge@leibniz-hki.de.

If any part of this code is used for academic purposes please cite the paper above.

Contents
-------------------------------------------------------------------------------
ACAQ-v3:
	The Fiji macro implements a Hessian-based segmentation algorithm to detect macrophages in transmitted light images,
	as well as the corresponding fungal spores based on their fluorescence labelling. The details are 
	described in Cseresnyes et al., 2017
read.me:
	What you currently have open.
license:
	Licencing details of this software (BSD License 2.0).
Data/:
	Folder containing some example images and their segmented end-results that is appropriate to test ACAQ-v3 on.

Requirements:
-------------------------------------------------------------------------------
ImageJ:
	Code is developed and tested using ImageJ 1.51n


Version history:
//v.0.1 Macro to cut and rearrange Zeiss tilescans (.lsm, .czi)
//v.0.2 Correctly cuts up the stitched image
//v.0.3 Merges the slices in the proper order
//v.0.4 Handles both 3x3 and 5x5 arrays
//v.0.6 Adds the analysis tools, based mostly on Hessian filtering, 1.9.16
//v.0.7 Creating blue and red channel masks, multichannel images are handled by re-stitching, 1.9.16
//v.0.8 Implements Hessian-based object finder for macrophages, 1.9.16
//v.0.9 Implements Hessian-based object finder for spores, 2.9.16
//v.0.10 Implements Hough-based line removal from the spore Hessian images, 5-9.9.16
//v.0.11 Implements fluorescence-based segmentation for spores, 12.9.16
//v.0.12 Implements rolling ball background correction for the flsc based spore segmentation, 13.9.16
//v.0.13 Implements matching between macrophages and the two types of spores (blue, green), 14.9.16
//v.0.14 Allows the use of Hanno's data type; Ch0: red Ab, 1: green, 2: TL, 3: blue; also works with subfolders, 29.9.16
//v.0.15 Fixes a bug with the Hanno format (no need to restitch); Implements the spore finder, not yet complete, 7.11.16
//v.0.16 Improves the macrophage finder by removing the 2nd set of dilate-fill-erode cycle, and now using Unsharp Mask instead of just "Sharpen"; 18.11.17
//v.0.17 Starts adding the calculations for the various phagocytosis measures and outputs them (not yet complete); used for Kaswara and Hanno's data as well; 9.12.17
//v.0.18 Improves the macrophage finder by applying "Remove Outliers", also clears up the 3rd GUI, and creates an image with all components merged and saved; 14.12.16 
//v.0.19 Continues with the phagocytosis index calculations ; 14.12.16 
//v.0.20 Adding the option to use Internal Gradient, which focuses on finding the black centers of the spores; 3.-4.1.17  
//v.0.21 Adding spore classifier based on blue fluorescence inside the green spores
//v.0.22 Adding the option to ignore macrophages at the edge; 12-13.1.17
//v.0.23 Adding various phagocytosis measures; 16-17.1.17
//v.0.24 Adding option to read multi-channel TIFF images; 18.1.17
//v.0.25 New saving format as matrix for phagocytosis measures; 19.1.17
//v.0.26 Adds correction factor possibility (NOT used any more, June 2017); 20.1.17
//v.0.27 Allows to correct the macrophage threshold with a multiplier so as to make segmentation better for Mohamed's Egyptian data; 24.1.17
//v.0.28 Add TIFF reader; 24.1.17
//v.0.29 Rearrange the way green and blue spores are IDd and calculated, so as to make it easier to follow and debug; 26.1.17
//v.0.30 Also saves the edge-inclusive results; 30.1.17  
//v.0.31 Saves the total conidia number, plus adds the option to combine spore finders' results with and without Internal Gradient; 6.2.17 
//v.0.32 Adds the option to hard-threshold the green channel for the Bright Spots method; 3.3.17
//v.0.33 Saves to total number of macrophages; makes the macrophage ROIs tighter by GUI-determined # of pixels; lowers the min size of macrophages to 50; 13-15.3.17
//v.0.34 Fixes the problem where the total number of conidia is smaller than the sum of phagocytosed and adherent ones; also adds additional erosion steps for macrophages; 16.3.17
