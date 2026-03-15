; <<Copyright (C)  2022 Abel Granados>>
; <<https://es.fiverr.com/abelgranados>>

#InstallKeybdHook
#KeyHistory, 200
Process, Priority, , High
SetBatchLines, -1
ListLines, Off
SetKeyDelay, 10, 60
SetMouseDelay, 15
SetDefaultMouseSpeed, 4
SendMode, Event
CoordMode, Pixel, Window  
CoordMode, Mouse, Window  
CoordMode, ToolTip, Window 


MsgBox, Instructions`n`nCtrl + 9 Toggle On/Off script`nCtrl + 0 Shows/Hides overlay`nCtrl + 8 Pause/Unpause

mainWin := 0
stateNeutral := true
arrowPressed := false
regiones := []



hpBar := crearRegion(127, 31, 127 + 80, 31 + 4)


character := crearRegion(317, 170, 317 + 15, 170 + 50)
lootSquare := createLootSquare()
;hpBar := crearRegion(505, 80, 836, 100)

regiones.push(hpBar)
regiones.push(character)
regiones.push(lootSquare)

spell := []

if(FileExist("settings.ini")){
	loop, 2 {

		spell[A_Index] := new _spell(cargarSetting("hpThreshold", "threshold" . A_Index, default:=0)
			, cargarSetting("hpThreshold", "thresholdKey" . A_Index, default:=0)
			, 300)

	}

	timeToMove := cargarSetting("time", "timeToMove", default:=0)
}




Hotkey, ^0, showLayout
Hotkey, ^9, toggleScript
Hotkey, ^8, pause

gui(spell, timeToMove)
return

/*
1::
	testMap()
return

2::
	loot()
return

*/

esc::
	ExitApp
return

pause:
	Pause, Toggle, 1
	if(A_IsPaused){
		showNotificationMsg("Script Paused", 1)
	}else{
		showNotificationMsg("Script Unpaused", 1)
	}
return

toggleScript:
	if(toggleScript:=!toggleScript){
		setTimer, script, 10
		showNotificationMsg("Script On")
		return
	}

	setTimer, script, Off
	showNotificationMsg("Script will Off")
return


showLayout:

	if (toggleLayout:=!toggleLayout){
		
		winActiva := WinExist("A")
		idGrafico := crearColeccionGraficos(regiones.Count())
		dibujarColeccionRectangulos(idGrafico, regiones, winActiva)

	}else{

		destruirColeccionGraficos(idGrafico)
		idGrafico := []
	}

return

~Up::
~Right::
~Down::
~Left::
	arrowPressed := true
	setTimer, resetArrow, -900, 2
return

script(){

	Global
	static afkLimit := 0, lastAfkPrevention := 0
	static hp := 0, lastFoeDirection := ""

	hp := currentHP()

	;showNotificationMsg("hp: " . hp)
	if(hp = 0){
		;return
	}else{

		loop, % spell.MaxIndex() {

			if (hp <= spell[A_Index].threshold){
				
				;Tooltip, % "speel " spell[A_Index].Available()
				if(spell[A_Index].Available()){
					spell[A_Index].Cast()
					break
				}
			}
		}

	}
	
	
	foeDirection := findEnemyDirection()
	if(foeDirection = 0){
		showNotificationMsg("Waiting foe")
		lastFoeDirection := ""
		return
	}

	if(arrowPressed){
		showNotificationMsg("Arrow pressed")
		lastAfkPrevention := 0
		return
	}

	showNotificationMsg("Foe at " . foeDirection)

	
	if( lastAfkPrevention > 0 ){
		
		if(A_TickCount	- lastAfkPrevention >= afkLimit){

			if(stateNeutral = false){
				return
			}
			
			walk("right")
			randomSleep(120, 200)
			walk("left")
			Sleep, 900
			lastAfkPrevention := 0
		
		}


	}

	

	if(foeDirection = lastFoeDirection){

		attack()

		if(lastAfkPrevention = 0){

			Random, afkLimit, (timeToMove - 50) <= 0 ? 50 : timeToMove, timeToMove + 50
			afkLimit*=1000
			lastAfkPrevention := A_TickCount
		
		}
	
	}else{
	
		if(stateNeutral = false){
			return
		}

		lookToDirection(foeDirection)
		lastFoeDirection := foeDirection
	
	}
	

			

}


;#################### Script functions



attack(){

	Global stateNeutral
	static attacking := false

	if(attacking){

		SendInput, {Control down}
		setTimer, suspendAttack, -120
	
	}else{

		if(stateNeutral = false){
			return
		}

		SendInput, {Control down}
		setTimer, suspendAttack, -120
		attacking := true
		stateNeutral := false
	
	}

	return

	suspendAttack:
		SendInput, {Control up}
		attacking := false
		setTimer, goNeutral, -900
		;loot()
	return

}

proventAfk(){




}



currentHP(){

	Global hpBar
	static hpColor := 0x0000B5  ;piso OC296E, rojo 0x280EE2 ;0x0000B5, 0x003163
	static hpWidth := 0

	

	if(hpWidth = false){
		hpWidth := hpBar.x2 - hpBar.x1
	}

	point := pixelSearchDesdeArribaDerecha(hpBar, hpColor, 32)
	if(point = false){
		return false
	}

	currentHPWidth := point.x - hpBar.x1
	
	hp := Floor((currentHPWidth/hpWidth)*100)
	if(hp = 0){
		return hp
	}
	
	return (hp)
}








findEnemyDirection(){

	static mapPPlayer := new _Pixel(123, 126)
	static mapPTop := new _Pixel(mapPPlayer.x + 4, mapPPlayer.y - 4) 
	static mapPRigth := new _Pixel(mapPPlayer.x + 4, mapPPlayer.y + 4) 
	static mapPBottom := new _Pixel(mapPPlayer.x - 4, mapPPlayer.y + 4) 
	static mapPLeft := new _Pixel(mapPPlayer.x - 4, mapPPlayer.y - 4) 
	static enemyColor := 0x8B0913
	static playerColor := 0x27199B

	if(mapPLeft.IsBlue()){
		return "left"
	}

	if(mapPRigth.IsBlue()){
		return "right"
	}

	if(mapPBottom.IsBlue()){
		return "bottom"
	}

	if(mapPTop.IsBlue()){
		return "top"
	}

	return false

}

lookToDirection(direction){

	Global stateNeutral
	SetKeyDelay, 30, randomValue(60, 90)
	
	if(!stateNeutral){
		return false
	}

	Switch direction
	{
		Case "top":
			Send, {Up}
		Case "right":
			Send, {Right}
		Case "bottom":
			Send, {Down}
		Case "left":
			Send, {Left}
		Default:
			return false

	}

	stateNeutral := false
	setTimer, goNeutral, -200
	return true

}



walk(direction){

	holdTime := randomValue(250, 300)
	
	Switch direction
	{
		Case "top":
			Send, {Up down}
			Sleep, holdTime
			Send, {Up up}
		Case "right":
			Send, {Right down}
			Sleep, holdTime
			Send, {Right up}
		Case "bottom":
			Send, {Down down}
			Sleep, holdTime
			Send, {Down up}
		Case "left":
			Send, {Left down}
			Sleep, holdTime
			Send, {Left up}
		Default:
			return false
	}
	
	return true

}


resetArrow(){
	Global arrowPressed
	arrowPressed := false
}


createLootSquare(){

	static point := crearPunto(322, 221)
	static width := 70
	static height := 35
	static wHalf := width//2
	static hHalf := height//2

	lootSquare := crearRegion(point.x - wHalf, point.y - hHalf, point.x + wHalf, point.y + hHalf)
	
	return lootSquare
}


testMap(){

	static mapPPlayer := new _Pixel(123, 126)
	static mapPTop := new _Pixel(mapPPlayer.x + 4, mapPPlayer.y - 4) 
	static mapPRigth := new _Pixel(mapPPlayer.x + 4, mapPPlayer.y + 4) 
	static mapPBottom := new _Pixel(mapPPlayer.x - 4, mapPPlayer.y + 4) 
	static mapPLeft := new _Pixel(mapPPlayer.x - 4, mapPPlayer.y - 4)

	BlockInput, MouseMove
	MouseGetPos, oX, oY

	MouseMove, mapPPlayer.x, mapPPlayer.y
	Tooltip, Player point
	Sleep, 2000

	MouseMove, mapPTop.x, mapPTop.y
	Tooltip, Top point
	Sleep, 2000

	MouseMove, mapPRigth.x, mapPRigth.y
	Tooltip, Right point
	Sleep, 2000

	MouseMove, mapPBottom.x, mapPBottom.y
	Tooltip, Bottom point
	Sleep, 2000

	MouseMove, mapPLeft.x, mapPLeft.y
	Tooltip, Left point
	Sleep, 2000
	Tooltip

	MouseMove, oX, oY
	BlockInput, MouseMoveOff
}



loot(){

	Global lootSquare
	
	x := lootSquare.x1
	y := lootSquare.y1
	Click, %x% %y%

	x := lootSquare.x2
	y := lootSquare.y1
	Click, %x% %y%

	x := lootSquare.x2
	y := lootSquare.y2
	Click, %x% %y%

	x := lootSquare.x1
	y := lootSquare.y2
	Click, %x% %y%
	
}

gui(ByRef spell, Byref timeToMove){

	Global
	
	loop, 2 {

		if(spell[A_Index].threshold){
			threshold%A_Index% := spell[A_Index].threshold
		}else{
			threshold%A_Index% := 50
		}


		if(spell[A_Index].key){
			thresholdKey%A_Index% := spell[A_Index].key
		}else{
			thresholdKey%A_Index% := "0" ;0 = unused
		}
	
	}
 

	;Gui attributes
	static width := 600
	static wParte := width//3
	static fontSize := 9

	Gui, New
	Gui, Color, 272727, E0E0E0
	Gui, Font, cECECEC s%fontSize%, Verdana
	Gui, Margin, 0, 10


	;#Treshold section
	Gui, Add, GroupBox, section x20  w560 Center h160, Threshold Settings (key = 0 means disable)
	Gui, Add, Text, % "yp+20 xs+20 Center w"wParte, #1 if hp  < `%:
	Gui, Add, Slider, % "yp xs+"(wParte+20) " w240 TickInterval10  Range1-100 ToolTipBottom vthreshold1 gSave", %threshold1% 
	Gui, Add, Edit, % "yp xs+"(wParte + 30 + 240) " w80 vthresholdKey1 gSave c272727", %thresholdKey1%
	
	Gui, Add, Text,  % "yp+30 xs+20 Center w" wParte, #2 if hp  < `%:
	Gui, Add, Slider, % "yp xs+"(wParte+20) " w240 TickInterval10  Range1-100 ToolTipBottom vthreshold2 gSave", %threshold2%
	Gui, Add, Edit, % "yp xs+"(wParte + 30 + 240) " w80 vthresholdKey2 gSave c272727", %thresholdKey2%

	Gui, Add, Text,  % "yp+50 xs+20 Center w" wParte, Move every (seconds)
	Gui, Add, Edit, % "yp xs+"(wParte+20) " w120 vtimeToMove gSave Number c272727", %timeToMove%



	;El orden en la gui determina la importancia, para lansar un spell urgente poner de primero
	;Desde most urgen firts - less urgen
	
	Gui, Show, w%width%

	return

	GuiClose:
		ExitApp
	return

	Save:
		Gui, Submit, NoHide
		
		loop, 2 {
			 
			 spell[A_Index].threshold := threshold%A_Index%
			 registrarSetting("hpThreshold", "threshold" . A_Index, threshold%A_Index%)

			 spell[A_Index].key := thresholdKey%A_Index%
			 registrarSetting("hpThreshold", "thresholdKey" . A_Index, thresholdKey%A_Index%)
		}

		registrarSetting("time", "timeToMove", timeToMove)

	return

}


goNeutral(){

	Global stateNeutral
	stateNeutral := true

}

class _spell {

	__New(threshold, key, coldown){

		this.threshold := threshold
		this.key := key 
		this.coldown := coldown
		this.ready := key ? true : false
		this.getReady := ObjBindMethod(this, "ReadyToTrue")
	
	}

	Available(){

		return this.ready

	}


	Cast(){
		
		;SetKeyDelay, 10, randomValue(40, 90)
		SendInput, % "{Blind}{" this.key "}"
		this.ready := false
		goReady := this.getReady
		setTimer, % goReady, % - this.coldown, 1
	
	}


	ReadyToTrue(){
		this.ready := true
	}

}






;#################### libreria func


class _Pixel {
	
	__New(x:=0, y:=0, color:=0xffffff){
		this.x := x
		this.y := y
		this.color := color
	}

	Is(color, variation){
		
		PixelSearch, fx, fy, this.x, this.y, this.x, this.y, color, variation, Fast

		if(ErrorLevel){
			return false
		}
		
		return true
	}

	IsBlue() {

		PixelGetColor, bgr, this.x, this.y
	    r := bgr & 0xff
	    g := (bgr >> 8) & 0xff
	    b := ((bgr >> 16) & 0xff) - 32
	    return b > r && b > g
	}

}

pixelSearchDesdeArribaDerecha(region, colorHex, variacion:=0){

	PixelSearch, fx, fy, region.x2, region.y1, region.x1, region.y2, colorHex, variacion, fast
	if(ErrorLevel){
		return false	
	}

	return {"x":fx, "y":fy}

}

crearRegion(x1, y1, x2, y2){

	if (x1<0 or y1<0 or x2<0 or y2<0){
		return 0
	}

	if(x2 < x1){
		temp := x1
		x1 := x2
		x2 := temp
	}

	if(y2 < y1){
		temp := y1
		y1 := y2
		y2 := temp
	}

	return {"x1":x1, "y1":y1, "x2":x2, "y2":y2}

}

crearGrafico(cc:="0x3CFF3C") {

	Gui, New, +HwndGrafico  +AlwaysOnTop -Caption +E0x00000020 +E0x08000000
	Gui, Color, %cc%
	return Grafico

}

crearColeccionGraficos(cantidad){

	ids := []
	loop, %cantidad%
		ids[A_Index] := crearGrafico()
	
	return ids
}

dibujarRectangulo(winHwnd:=0, punto:=0, hwndGrafico:=0, x1:=0, y1:=0, x2:=0, y2:=0, borde:=2){
    
    if (!hwndGrafico or x1<0 or y1<0 or x2<0 or y2<0){
        return 1
    }

    addX := 0, addY := 0 
    if (winHwnd != 0){
        
        win := WinExist("ahk_id " winHwnd)
        if !win
            return 2
        
        WinGetPos, wx, wy, , , ahk_id %win%
      	addX := wx
       	addY := wy
    }

    if(punto != 0){
        addX += punto.x
        addY += punto.y
    }

    x1+=addX
    y1+=addY
    x2+=addX
    y2+=addY

    w := x2 - x1
    h := y2 - y1
    w2:= w - borde
    h2:= h - borde
  
    Gui, %hwndGrafico%: Show, w%w% h%h% x%x1% y%y1% NA
    WinSet, Transparent, 255
    WinSet, Region, 0-0 %w%-0 %w%-%h% 0-%h% 0-0 %borde%-%borde% %w2%-%borde% %w2%-%h2% %borde%-%h2% %borde%-%borde%, ahk_id %hwndGrafico%

}

dibujarColeccionRectangulos(idGraficos, regiones, winHwnd:=0, punto:=0){

	loop, % idGraficos.Count()
		dibujarRectangulo(winHwnd, punto, idGraficos[A_Index], regiones[A_Index].x1, regiones[A_Index].y1, regiones[A_Index].x2, regiones[A_Index].y2)
	
}

destruirGrafico(hwndGrafico){
	
	if (!hwndGrafico)
		return

	Gui, %hwndGrafico%:Destroy
}

destruirColeccionGraficos(ids){
	
	loop, % ids.Count()
		destruirGrafico(ids[A_Index]) 
	
}

distribucionAlObjetivo(ini, objetivo, fin){
  
    Random, izq, ini, objetivo
    Random, der, objetivo, fin
    Random, cerca, izq, der
    return cerca

}

clicRegion(region, insetX:=0, insetY:=0){

    ;El caller se aseguro de que la region es valida
    mex := (region.x1 + region.x2)//2
    rax := distribucionAlObjetivo((region.x1+insetX), mex, (region.x2-insetX))

    mey := (region.y1 + region.y2)//2
    ray := distribucionAlObjetivo((region.y1+insetY), mey, (region.y2-insetY))

    SetDefaultMouseSpeed, randomValue(1, 4)
    MouseMove, rax, ray
    randomSleep(80, 120) 

    SetMouseDelay, randomValue(60, 110)
    Click
    randomSleep(30, 80) 
    return 0

}

showNotificationMsg(msg:="", centrar :=0){
    
   	CoordMode, ToolTip, Window
    
    if(centrar){
    	WinGetPos, X, Y, Width, Height, A
    	Tooltip, % msg, Width//2, Height//2, 1
    }else{
    	Tooltip, % msg , , , 1
    }

    setTimer, quitarTooltip, -2000
    return

    quitarTooltip:
        Tooltip, , , , 1
    return

}

showErrorMsg(msg){

	CoordMode, ToolTip, Window
    
    WinGetPos,,, Width, Height, A
    Tooltip, % msg, Width//2, Height//2, 20

}

randomSleep(min:=30, max:=1000){
    Sleep,  distribucionAlObjetivo(min, ((min+max)//2), max)
}

randomValue(min, max){
    return  distribucionAlObjetivo(min, ((min+max)//2), max)
}

registrarSetting(seccion, key, valor){

    IniWrite, %valor%, settings.ini, %seccion%, %key%

}

cargarSetting(seccion, key, default:=0){   
    
    IniRead, OutputVar, settings.ini, %seccion%, %key% , %default%
    return OutputVar
}

crearPunto(x, y){
	
	if (x<0 or y<0){
		return 0
	}	
	return {"x":x, "y":y}
}