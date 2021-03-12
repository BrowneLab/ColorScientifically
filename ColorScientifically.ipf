#pragma TextEncoding = "Windows-1252"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//based on: Crameri, F.; Shephard, G. E.; Heron, P. J. The Misuse of Colour in Science Communication. Nat. Commun. 2020, 11 (1), 5444.
//written by: Aroob S Abdelhamid 2.12.21

//This program is free software; you can redistribute it and/or
//modify it under the terms of the GNU General Public License
//as published by the Free Software Foundation.
//
//This program is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.

//Description: colors up to 25 visible traces on top graph based on a color scal chosen from the given drop down menu.
//To use: write into command line "ColorScientificallyPanel()" then use the drop down menu and button on panel

//notes:
//1. If you have multiple plots in the same graph window and you want them to share the same color scheme 
//(duplicate colors in the same window, hide each set of traces as you apply "ColorScientifically" to the visible traces and switch

//2. note your traces will be colored based on the order they were appended to the graph

//Panel
Function ColorScientificallyPanel()
	//If the window already exists, kills panel
	string windowExist = WinList("ColorScientifically",";","WIN:64") //
	if (strlen(windowExist) > 0 )
		Killwindow ColorScientifically
	endif
	
	//creates variables if necessary
	SVAR/Z ColorMapStr = root:ColorMapStr
	if(!SVAR_exists(ColorMapStr))
		String/g root:ColorMapStr
	endif
	
	NVAR/Z ColorMap = root:ColorMap; ColorMap=0
	//creates variables
	if(!NVAR_exists(ColorMap))
		Variable/g root:ColorMap
	endif
	
	SVAR/Z WinNm = root:WinNm
	if(!SVAR_exists(WinNm))
		String/g root:WinNm; 
	endif
	
	//Creates the panel
	Newpanel/K=1/M/N=ColorScientifically/W=(1,1,10,10);  
	
	//the color scheme names popup menu
	PopupMenu ColorMapStr size={75, 50}, Pos={25,20}, proc = ColorSchemeSet, title="Choose Color Scheme", win=ColorScientifically, value= ColorList()
	
	//graph window name - if empty, top graph is chosen
	SetVariable/Z WindowName size={300, 20}, Pos={25,40}, proc=WinNmset, title="Window Name (optional)", win=ColorScientifically, value= root:WinNm
	
	//Color Preview Plot
	Display/Host=ColorScientifically/N=ColorPreview/W=(-10, 60, 400, 280); Modifypanel cbrgb= (0,0,0); 
	Make/O/N=(25,1) PlotColorScheme = x; AppendImage PlotColorScheme; 
	Make/O/N=(25,3) root:RedGreenBlue/WAVE=RedGreenBlue; RedGreenBlue = NaN
   setdimlabel 1,0, Red, RedGreenBlue; setdimlabel 1,1 , Green, RedGreenBlue; setdimlabel 1,2 , Blue, RedGreenBlue
   
   //show first color
	RedGreenBlueFn(0)
	ModifyGraph axRGB=(0,0,0,0),tlblRGB=(0,0,0,0),alblRGB=(0,0,0,0); ModifyImage PlotColorScheme ctab= {*,*,RedGreenBlue,0}  //modifies preview window
	
	//the button that runs the procedure
	button DoIt, size={120,40}, pos={100,290},proc=ColorScientificallyProc, title="Color Scientifically!", win=ColorScientifically //The Color Scientifically button
End

//the actual coloring of the graph
Function ColorGraph(WinNm)
	string WinNm	
	
	variable topgraph = strlen(winnm)
	If(topgraph ==0)
		WinNm = WinName(0,1,1)
		print WinNm + " (top graph) was colored scientifically!"
	EndIf
	
	wave RedGreenBlue = Root:RedGreenBlue
	Variable nrows = dimsize(RedGreenBlue,0)
	
	string listtrcs = TraceNameList(WinNm,";",1+4); variable numtrcs = ItemsinList(listtrcs,";") //only visible trace colors are changed!!
	//Evenly space the colors and change colors
	variable separat = (nrows/(numtrcs-1))-(1/(numtrcs-1)); variable itrc 
	If(numtrcs >= nrows || numtrcs==1)
		separat=1
	EndIf
	
	//change the colors on the graph
	For(itrc=0; itrc<numtrcs; itrc++)
		string currtrc = stringfromlist(itrc, listtrcs); variable trcnum = mod(separat*itrc,nrows)
		Modifygraph/Z/W=$WinNm rgb($currtrc)=(RedGreenBlue[trcnum][0], RedGreenBlue[trcnum][1], RedGreenBlue[trcnum][2]) //change the color
	EndFor
		
End

//the graph window name setting
Function WinNmSet(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			String/g WinNm = sva.sval
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//the popup menu
Function ColorSchemeSet(PU_Struct) : PopupMenuControl
	STRUCT WMPopupAction &PU_Struct
	
	//string popstr
	switch(PU_Struct.eventcode)
		case 2: //mouse up
			string/G root:colormapstr = PU_Struct.popstr
			variable/G root:colormap = PU_Struct.popnum-1
			UpdateTheDisplay(PU_Struct.eventcode) //color preview
		case -1: //control being killed
			break
	EndSwitch	
End

//the color preview display
Function UpdateTheDisplay(event)
	variable event
    
	wave RedGreenBlue = root:RedGreenBlue
	switch(event)    
		case 2:     // handle left mouse click         
			NVAR colormap = root:colormap
			RedGreenBlueFn(colormap)
			break                   
	endswitch
 
	return 1
End

//the Color Scientifically! button
Function ColorScientificallyProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	switch( ba.eventCode )
		case 2: // mouse up
			NVAR/Z Colormap = root:colormap
			RedGreenBlueFn(colormap) //what color scheme
			SVAR/Z WinNm = root:WinNm
			ColorGraph(WinNm)	//changes the colors
			break
		case -1: // control being killed
			break
	endswitch

	return 0 	
End	

//list of all the colors used in the popup
Function/S ColorList()
	string listofcolors =""
	listofcolors+= "acton (purple/pink);"
	listofcolors+= "bamako (green/yellow);"
	listofcolors+= "batlow (green/pink);"
	listofcolors+= "berlin (blue/black/red);"
	listofcolors+= "bilbao (white/yellow/red);"
	listofcolors+= "broc (blue/white/green);"
	listofcolors+= "buda (pink/yellow);"
	listofcolors+= "cork (blue/white/green);"
	listofcolors+= "davos (blue/snot/white);"
	listofcolors+= "devon (blue/purple/white);"
	listofcolors+= "grayC (white/grey/black);"
	listofcolors+= "hawaii (pink/yellow/blue);"
	listofcolors+= "imola (blue/green/yellow);"
	listofcolors+= "lajolla (yellow/red/black);"
	listofcolors+= "lapaz (blue/green/peach);"
	listofcolors+= "lisbon (blue/black/yellow);"
	listofcolors+= "nuuk (blue/green/yellow);"
	listofcolors+= "oleron (blue AND green);"
	listofcolors+= "oslo (blue);"
	listofcolors+= "roma (red/yellow/blue);"
	listofcolors+= "romaO (red/yellow/purple);"
	listofcolors+= "tofino (blue/black/green);"
	listofcolors+= "tokyo (purple/yellow);"
	listofcolors+= "turku (black/pink);"
	listofcolors+= "vik (blue/white/red);"
	listofcolors+= "vikO (blue/peach/red);"
	return listofcolors
End

//what color scheme are you using
Function RedGreenBlueFn(colormap)
	variable colormap 
	
	wave RedGreenBlue = Root:RedGreenBlue 
	If(colormap==0) //acton //purple to pink
		RedGreenBlue[][0]={46,57,68,80,92,105,119,133,146,159,170,183,196,206,212,213,212,211,212,213,215,218,222,225,230}
		RedGreenBlue[][1]={33,43,52,62,73,81,90,95,99,101,102,104,110,119,130,140,149,158,166,176,187,197,208,218,230}
		RedGreenBlue[][2]={77,87,96,106,116,125,134,140,144,147,148,150,155,162,170,177,184,190,196,203,210,217,225,232,240}
	elseif(colormap==1) //bamako //green to yellow
		RedGreenBlue[][0]={0,8,15,21,28,35,43,50,58,67,76,86,97,108,122,135,150,168,185,203,217,227,237,246,255}
		RedGreenBlue[][1]= {64,68,72,76,81,85,90,95,101,106,112,119,126,132,139,142,146,154,165,179,191,201,211,220,229}
		RedGreenBlue[][2]={77,73,69,65,60,56,52,47,42,37,32,26,20,14,6,3,6,20,37,58,79,97,117,134,153}
	elseif(colormap==2) //batlow //green to pink
		RedGreenBlue[][0] = {1,10,14,17,20,25,34,45,60,77,93,111,130,149,171,190,210,228,241,250,253,253,253,252,250}
		RedGreenBlue[][1]={25,42,55,67,78,87,96,103,109,115,120,125,130,135,140,144,147,151,157,164,172,180,188,195,204}
		RedGreenBlue[][2]= {89,92,94,96,98,98,97,93,86,77,68,58,49,44,45,53,67,86,107,133,158,180,203,225,250}
	elseif(colormap==3) //berlin //blue to red
		RedGreenBlue[][0]={158,133,108,81,60,49,40,33,26,20,17,17,25,36,49,63,80,101,123,146,168,188,210,231,255}
		RedGreenBlue[][1]= {176,173,169,159,142,124,104,85,66,48,33,20,12,12,15,18,24,35,50,70,90,109,131,151,173}
		RedGreenBlue[][2]= {255,243,230,211,185,161,134,110,86,62,42,24,9,2,0,1,3,14,28,50,74,97,122,146,173}
	elseif(colormap==4) //bilbao //white to yellow to red
		RedGreenBlue[][0]= {255,241,228,215,205,199,194,190,185,181,177,173,170,167,164,162,158,154,147,138,126,115,102,90,77}
		RedGreenBlue[][1]={255,241,228,215,203,195,188,182,175,165,155,144,134,126,116,107,97,86,75,63,50,39,26,14,0}
		RedGreenBlue[][2] = {255,240,227,211,195,181,166,153,139,124,114,106,101,98,93,89,85,79,71,61,49,38,27,17,1}
	elseif(colormap==5) //broc: snot to white to blue
		RedGreenBlue[][0]= {44,43,41,41,49,67,91,113,139,165,189,215,235,236,224,212,197,176,155,133,112,93,73,55,38}
		RedGreenBlue[][1]={26,42,57,75,94,111,130,147,167,187,205,224,238,236,224,212,197,176,155,133,112,93,73,56,38}
		RedGreenBlue[][2] = {76,93,108,125,142,155,169,181,194,208,220,233,236,219,193,170,143,117,98,79,61,45,29,16,0}
	elseif(colormap==6) //buda // yellow to pink
		RedGreenBlue[][0]= {179,179,179,179,181,184,188,191,194,197,200,203,205,208,210,212,215,217,219,222,224,227,233,242,255}
		RedGreenBlue[][1]= {1,22,35,47,58,68,78,87,97,106,115,124,133,142,151,160,170,180,189,199,209,219,230,242,255}
		RedGreenBlue[][2]= {179,169,162,156,151,148,144,141,138,135,132,129,126,124,122,119,117,115,112,110,107,105,103,102,102}
	elseif(colormap==7) //cork //green to white to blue
		RedGreenBlue[][0]= {44,43,42,42,50,65,87,108,132,157,179,203,219,212,191,171,149,127,107,86,71,65,65,66,66}
		RedGreenBlue[][1]= {26,41,56,73,91,108,126,143,161,180,198,216,230,229,218,206,193,180,168,153,135,118,102,90,77}
		RedGreenBlue[][2]= {76,92,107,123,139,153,166,178,190,203,215,227,229,215,194,174,153,131,112,89,65,46,29,16,3}
	elseif(colormap==8) //davos //white to green to blue
		RedGreenBlue[][0]= {0,5,12,20,29,37,47,57,67,78,87,98,108,117,128,139,153,169,187,208,227,239,247,252,254}
		RedGreenBlue[][1]= {5,22,35,50,64,77,90,101,112,121,128,135,142,148,155,163,173,185,199,216,231,240,247,251,254}
		RedGreenBlue[][2]= {74,90,104,119,132,142,150,155,157,157,155,151,147,143,139,136,136,139,148,164,184,203,222,238,254}
	elseif(colormap==9) //devon //white to purple to blue
		RedGreenBlue[][0]= {44,43,42,41,39,39,41,46,54,66,83,105,126,145,163,175,186,194,202,211,220,228,237,246,255}
		RedGreenBlue[][1]= {26,36,45,56,66,77,88,97,105,114,123,133,143,151,161,170,179,189,198,207,217,226,236,245,255}
		RedGreenBlue[][2]= {76,87,96,106,117,129,143,157,173,188,201,212,221,228,234,238,241,243,244,246,248,250,251,253,255}	
	elseif(colormap==10) //greyC //white to grey to black
		RedGreenBlue[][0]= {255,243,231,219,207,196,184,174,162,151,140,129,118,109,98,89,78,68,60,50,41,33,24,15,0}
		RedGreenBlue[][1]= {255,243,231,219,207,196,184,174,162,151,140,129,118,109,98,89,78,68,60,50,41,33,24,15,0}
		RedGreenBlue[][2]= {255,243,231,219,207,196,184,174,162,151,140,129,118,109,98,89,78,68,60,50,41,33,24,15,0}
	elseif(colormap==11) //hawaii //blue to yellow to pink
		RedGreenBlue[][0]= {140,143,145,146,148,149,151,152,153,155,156,157,156,153,146,138,128,117,108,99,95,102,122,149,179}
		RedGreenBlue[][1]= {2,22,35,46,57,67,78,87,99,111,122,136,150,164,177,188,197,205,212,219,226,232,238,241,242}
		RedGreenBlue[][2]= {115,104,95,85,77,69,62,55,48,40,34,29,28,36,53,72,95,118,140,165,189,211,231,244,253}
	elseif(colormap==12) //imola //yellow to green to blue
		RedGreenBlue[][0]= {26,30,34,37,41,44,48,52,57,63,69,76,84,92,103,112,123,134,145,157,172,189,211,232,255}
		RedGreenBlue[][1]= {51,59,66,73,80,87,94,100,107,113,119,126,134,143,153,163,174,185,195,207,219,230,240,247,255}
		RedGreenBlue[][2]= {179,175,171,168,164,161,157,153,148,142,137,131,127,124,121,119,116,113,111,108,105,103,102,102,102}
	elseif(colormap==13) //lajolla //black to red to yellow
		RedGreenBlue[][0]= {255,254,253,251,248,245,242,239,236,233,230,227,222,214,200,184,165,145,127,108,89,73,55,41,26}
		RedGreenBlue[][1]= {255,248,241,233,222,210,195,181,168,155,143,130,116,103,89,79,71,65,59,54,48,42,37,31,26}
		RedGreenBlue[][2]= {204,184,166,146,126,109,96,88,85,83,82,81,79,78,75,71,66,60,52,44,35,27,19,12,1}
	elseif(colormap==14) //lapaz //peach to green to blue
		RedGreenBlue[][0]= {26,30,33,36,38,41,45,48,54,61,69,80,92,104,119,133,148,164,179,199,218,234,245,251,254}
		RedGreenBlue[][1]= {12,26,38,50,61,72,83,93,103,113,122,132,140,147,153,158,162,167,172,181,193,206,219,231,242}
		RedGreenBlue[][2]= {100,109,117,126,134,140,147,152,157,160,162,164,163,162,159,156,152,149,150,156,168,185,205,223,243}
	elseif(colormap==15) //lisbon //white to black to blue
		RedGreenBlue[][0]= {230,200,173,144,116,91,65,45,30,22,18,18,23,33,50,67,87,107,127,150,173,193,215,234,255}
		RedGreenBlue[][1]= {229,208,188,167,146,127,106,87,67,51,37,27,25,32,47,63,81,101,120,141,164,186,210,231,255}
		RedGreenBlue[][2]= {255,237,222,204,187,171,151,130,104,79,58,37,25,24,31,40,52,64,76,92,112,135,162,188,217}
	elseif(colormap==16) //nuuk //yellow to blue
		RedGreenBlue[][0]= {230,200,173,144,116,91,65,45,30,22,18,18,23,33,50,67,87,107,127,150,173,193,215,234,255}
		RedGreenBlue[][1]= {89,92,96,100,105,111,119,126,135,143,151,158,166,171,177,181,185,190,194,201,209,219,232,243,254}
		RedGreenBlue[][2]= {140,136,133,131,130,130,133,136,141,145,149,151,152,151,148,145,141,137,133,131,132,138,149,163,178}
	elseif(colormap==17) //oleron //green and blue
		RedGreenBlue[][0]= {26,43,58,76,94,112,131,150,170,188,202,216,26,51,75,96,122,146,168,193,217,236,246,249,253}
		RedGreenBlue[][1]= {38,55,71,89,107,125,144,162,183,201,214,229,76,84,91,99,113,128,143,161,181,199,218,234,253}
		RedGreenBlue[][2]= {89,106,122,140,158,176,195,213,232,243,248,252,0,0,1,9,31,55,78,103,129,154,181,204,230}
	elseif(colormap==18) //oslo //blue
		RedGreenBlue[][0]= {1,7,12,14,16,18,21,25,31,38,48,62,80,96,111,123,137,150,162,176,191,206,222,238,255}
		RedGreenBlue[][1]= {1,13,22,30,38,47,57,66,76,87,97,109,123,134,144,152,160,169,176,186,197,209,224,238,255}
		RedGreenBlue[][2]= {1,21,32,46,61,75,91,106,123,140,156,174,188,197,201,202,202,201,202,203,207,215,226,239,255}
	elseif(colormap==19) //roma //blue to yellow to red
		RedGreenBlue[][0]= {127,139,150,161,172,181,193,205,217,225,226,219,202,179,149,122,97,82,72,64,56,50,43,36,26}
		RedGreenBlue[][1]= {25,53,75,97,118,138,162,184,207,223,231,235,235,231,221,208,189,170,152,133,116,100,83,68,51}
		RedGreenBlue[][2]= {0,9,18,28,37,46,60,79,109,139,163,185,201,211,215,215,211,204,197,189,181,174,167,160,153}
	elseif(colormap==20) //romaO //purple to yellow to red
		RedGreenBlue[][0]= {115,123,130,139,148,158,170,182,195,207,213,212,203,187,164,141,116,96,84,78,81,88,98,106,114}
		RedGreenBlue[][1]= {57,56,60,68,81,96,117,138,163,188,206,220,225,224,216,204,187,168,149,128,107,89,73,63,57}
		RedGreenBlue[][2]= {87,72,61,51,45,43,47,57,75,102,129,156,179,194,203,207,205,200,192,180,164,147,125,107,89}
	elseif(colormap==21) //tofino //green to purple
		RedGreenBlue[][0]= {222,192,166,136,107,83,62,50,39,29,22,16,13,16,21,28,36,45,55,70,95,124,157,186,219}
		RedGreenBlue[][1]= {217,196,177,157,135,115,94,77,60,45,32,22,22,30,44,59,77,97,115,137,160,179,197,212,230}
		RedGreenBlue[][2]= {255,242,230,217,202,182,154,128,101,74,52,32,19,18,24,31,40,50,60,73,89,105,123,138,155}
	elseif(colormap==22) //tokyo //snot to purple
		RedGreenBlue[][0]= {26,43,58,75,92,105,118,126,133,137,140,142,144,145,147,149,151,155,161,172,188,206,225,240,254}
		RedGreenBlue[][1]= {14,20,26,35,46,57,70,82,94,105,115,125,135,144,154,164,174,185,197,211,226,238,247,252,254}
		RedGreenBlue[][2]= {52,61,70,80,90,100,108,115,120,125,128,131,134,136,139,142,145,148,153,160,171,183,196,206,216}
	elseif(colormap==23) //turku //pink to snot
		RedGreenBlue[][0]= {0,18,29,40,52,62,73,84,95,107,118,131,147,162,179,194,207,219,228,238,246,251,254,255,255}
		RedGreenBlue[][1]= {0,18,29,40,51,62,73,83,95,106,116,128,140,149,158,163,166,168,170,176,185,195,207,218,230}
		RedGreenBlue[][2]= {0,17,26,35,44,51,58,63,68,73,78,84,91,98,107,115,124,133,143,158,174,189,204,217,230}
	elseif(colormap==24) //vik //red to white to blue
		RedGreenBlue[][0]= {0,2,2,3,6,21,48,78,113,148,179,213,236,237,228,220,211,203,195,186,169,148,126,108,89}
		RedGreenBlue[][1]= {18,35,51,68,86,103,125,146,168,190,209,227,229,213,191,172,151,131,114,94,69,47,29,14,0}
		RedGreenBlue[][2]= {97,108,118,129,140,152,166,180,196,210,223,233,224,200,170,144,116,90,67,42,18,6,6,7,8}
	elseif(colormap==25) //vikO //red to blue
		RedGreenBlue[][0]= {79,71,63,56,51,55,69,90,117,147,174,198,213,217,215,208,197,181,163,141,122,108,97,88,80}
		RedGreenBlue[][1]= {26,33,44,59,77,95,117,137,158,177,189,195,190,180,163,145,124,100,77,55,37,27,22,22,25}
		RedGreenBlue[][2]= {61,75,91,110,128,144,161,175,188,197,200,194,179,159,135,111,86,63,45,33,30,33,39,48,60}
	EndIf
	RedGreenBlue*=257	
End

