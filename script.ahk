
#NoEnv
#SingleInstance force
SetBatchLines, -1
SendMode event
SetWorkingDir %A_ScriptDir%
SetKeyDelay, -1, 1
SetMouseDelay, -1,play

rand:=1
rand_var:=5
mode:="taiko"
tName:=[]
tName.Insert("taiko")
tName.Insert("osu")

dataParse:=[]
dataParse["taiko"]:="taikoParse"
dataParse["osu"]:="osuParse"

gui, +ToolWindow +AlwaysOnTop
gui, add, radio, Checked gselect vradioGroup,Taiko
gui, add, radio, x+0 gselect,OSU!
gui, add, text, x50 y100, Drop file in there
gui, add, text, y+0 vtxt, Mode:Taiko
gui, show, x0 y0 w200 h200
radioGroup:=1
Return

select:
gui,Submit,NoHide
mode:=radioGroup
mode:=tName[radioGroup]
if(mode="taiko")
	GuiControl, ,txt, Mode:Taiko
Else if(mode="osu")
	GuiControl, ,txt, Mode:OSU!
Return

GuiClose:
ExitApp

GuiDropFiles:
; if(mode="osu")
; {
; 	Msgbox, OSU! mode is under construction...
; 	Return
; }
gui, Cancel

FileRead, file, % A_GuiEvent

detected:=0

osu:=Object()
osu.time:=Object()
osu.event:=Object()
osu.eventover:=Object()
DllCall("QueryPerformanceFrequency", "Int64P", freq)	;系统时钟频率

dataParse[mode].()

if(mode="osu")
	rand_var:=2


Loop
{
	if(GetKeyState("z","P")=1 or GetKeyState("x","P")=1)
	break
	Else
	Sleep, 0
}


ptr:=1
DllCall("QueryPerformanceCounter", "Int64P",  nowTime)
startTime:=nowTime//(freq/1000)-osu.time[1]
loop, % osu.time.Maxindex()-1
{
	ptr++
	DllCall("QueryPerformanceCounter", "Int64P",  nowTime)
	if(rand){
		rand_temp:=0
		Loop, 10
		{
			Random, _rand_, -rand_var, rand_var
			rand_temp+=_rand_
		}
		startTime+=rand_temp
	}
	while(nowTime//(freq/1000)-startTime<osu.time[ptr]-20)
	{
		DllCall("QueryPerformanceCounter", "Int64P",  nowTime)
	}
	if(mode="osu")
		eventHandlerOsu(osu.event[ptr])
	else if(mode="taiko")
		eventHandlerTaiko(osu.event[ptr])
	if(rand){
		startTime-=rand_temp
	}
}

Return

taikoParse()
{
	global
	Loop, Parse, file, `n
	{
		lineContext:=A_LoopField
		IfInString, lineContext, [HitObjects]
			detected:=1
		if(!detected)
			Continue
		if(RegExMatch(lineContext, "\d+,\d+,(\d+),(\d+),(\d+)", match))
		{
			osu.time.Insert(match1+0)
			osu.event.Insert(match3+0)
			if((match2+0)=2 and RegExMatch(lineContext, "(\d+),(\d+),(?:\d+,){3}L((?:\|\d+:\d+)+),\d+,(\d+)", matchEx))
			{
				tempPoint:=[]
				tempPoint.x:=matchEx1
				tempPoint.y:=matchEx2
				context:=matchEx3
				speed:=matchEx4
				distance:=0
				Loop, Parse, context, |
				{
					if(RegExMatch(A_LoopField, "(\d+):(\d+)", matchTemp))
					{
						distance+=((tempPoint.x-matchTemp1)**2+(tempPoint.y-matchTemp2)**2)**0.5
						tempPoint.x:=matchTemp1
						tempPoint.y:=matchTemp2
					}
				}
				time:=Round(1000*distance/speed)
				osu.event[osu.event.MaxIndex()]:=0xfe
				osu.eventover.Insert(match1+time)
			}
			else if((match2+0)=12 and RegExMatch(lineContext, "(?:\d+,){5}(\d+)", matchEx))
			{
				osu.event[osu.event.MaxIndex()]:=0xff
				osu.eventover.Insert(matchEx1+0)
			}
			else
			{
				osu.eventover.Insert(0)
			}
		}
	}

	ToolTip, % "File parse completed`nObject:"  osu.event.maxindex()
	Sleep, 500
	ToolTip
}

osuParse()
{
	global
	Loop, Parse, file, `n
	{
		lineContext:=A_LoopField
		IfInString, lineContext, [HitObjects]
			detected:=1
		if(!detected)
			Continue
		if(RegExMatch(lineContext, "\d+,\d+,(\d+),(\d+),(\d+)", match))
		{
			osu.time.Insert(match1+0)
			osu.event.Insert(match2+0)

			if((match2+0)=12 and RegExMatch(lineContext, "(?:\d+,){5}(\d+)", matchEx))	; spinner
			{
				osu.event[osu.event.MaxIndex()]:=0x7f
				osu.eventover.Insert(matchEx1+0)
				; Msgbox, % osu.time[osu.event.MaxIndex()] "`n" osu.event[osu.event.MaxIndex()] "`n" osu.eventover[osu.event.MaxIndex()] "`n" 
			}
			else if(match2&2 and RegExMatch(lineContext, "(\d+),(\d+),(?:\d+,){3}B((?:\|\d+:\d+)+),\d+,(\d+)", matchEx))	;slider
			{
				tempPoint:=[]
				tempPoint.x:=matchEx1
				tempPoint.y:=matchEx2
				context:=matchEx3
				speed:=matchEx4
				distance:=0
				Loop, Parse, context, |
				{
					if(RegExMatch(A_LoopField, "(\d+):(\d+)", matchTemp))
					{
						distance+=((tempPoint.x-matchTemp1)**2+(tempPoint.y-matchTemp2)**2)**0.5
						tempPoint.x:=matchTemp1
						tempPoint.y:=matchTemp2
					}
				}
				time:=Round(1000*distance/speed)
				; Msgbox, % match1 " " match1+time
				osu.event[osu.event.MaxIndex()]:=0x7e
				osu.eventover.Insert(match1+time)
			}
			else
			{
				osu.eventover.Insert(0)
			}
		}
	}

	ToolTip, % "File parse completed`nObject:"  osu.event.maxindex()
	Sleep, 500
	ToolTip

}


rands(min=0,max=100)
{
	Random, OutputVar, % Min, % Max
	Return, OutputVar
}

eventHandlerTaiko(event)
{
	global ptr, nowTime, freq, startTime, osu
	ToolTip, % ptr
	if(event=0 or event=1)
	{
		MouseClick, Left
		Return
	}
	else if(event=2 or event=8)
	{
		MouseClick, Right
		Return
	}
	else if(event=4)
	{
		Send, c
		Send, x
		Return
	}
	else if(event=6 or event=12)
	{
		Send, v
		Send, z
		Return
	}
	else if(event=254)
	{
		while((nowTime//(freq/1000)-startTime)<(osu.eventover[ptr]-50))
		{
			DllCall("QueryPerformanceCounter", "Int64P",  nowTime)
			MouseClick, Left
			Sleep, 60
			MouseClick, Right
			Sleep, 60
		}
	}
	else if(event=255)
	{
		while((nowTime//(freq/1000)-startTime)<(osu.eventover[ptr]-50))
		{

			DllCall("QueryPerformanceCounter", "Int64P",  nowTime)
			Send, z
			Sleep, 60
			Send, x
			Sleep, 60
		}
	}
}

eventHandlerOsu(event)
{
	global ptr, nowTime, freq, startTime, osu
	static red:=0
	ToolTip, % "osu:"ptr
	; if(ptr>14)
	; Msgbox, % event " " event&1
	if(event=0x7e)
	{
		if(red=0)
		{
			; Send, {z Down}
			Click, Left Down
			red:=1
		}
		Else
		{
			; Send, {x Down}
			Click, Right Down
			red:=0
		}
		while((nowTime//(freq/1000)-startTime)<(osu.time[ptr+1]-100))
		{
			DllCall("QueryPerformanceCounter", "Int64P",  nowTime)
			Sleep, 1
		}
		if(red=0)
		{
			Click, Right Up
		}
		Else
		{
			Click, Left Up
		}
		
		; Send, {z up}
		; Send, {x up}
	}
	else if(event=0x7f)
	{
		; DllCall("QueryPerformanceCounter", "Int64P",  nowTime)
		static centerX:=A_ScreenWidth//2
		static centerY:=A_ScreenHeight//2
		MouseGetPos, tempX, tempY
		Send, {x Down}
		while(1)
		{
			DllCall("QueryPerformanceCounter", "Int64P",  nowTime)
			Sleep, 11
			MouseMove, % centerX, % centerY-150, 0
			Sleep, 11
			MouseMove, % centerX+150, % centerY, 0
			Sleep, 11
			MouseMove, % centerX, % centerY+150, 0
			Sleep, 11
			MouseMove, % centerX-150, % centerY, 0
			if( (nowTime//(freq/1000)-startTime)>(osu.eventover[ptr]-350) 
				and (nowTime//(freq/1000)-startTime)>osu.time[ptr]+500)
			break
		}
		Send, {x up}
		; MouseMove, % tempX, % tempY,0
	}
	else if(event&1)
	{
		; Send, {x up}
		; Send, {z up}
		if(red=0)
		{
			; Send, z
			; Click, Left
			MouseClick, Left
		}
		else if(red=1)
		{
			; Send, x
			; Click, Right
			MouseClick, Right
		}
		; else if(red=2)
		; MouseClick, Left
		; else
		; MouseClick, Right

		; red:=mod(red+1,4)
		red:=!red
		Return
	}
	else if(event&2)
	{
		; Send, {x up}
		; Send, {z up}
		if(red=0)
		{
			Click, Left down
			; Send, {z down}
			red:=1
		}
		else
		{
			Click, Right down
			; Send, {x down}
			red:=0
		}
		while((nowTime//(freq/1000)-startTime)<(osu.time[ptr+1]-50))
		{
			DllCall("QueryPerformanceCounter", "Int64P",  nowTime)
			Sleep, 1
		}
		if(red=0)
		{
			Click, Right Up
		}
		Else
		{
			Click, Left Up
		}
		Return
	}
	
}


F5::ExitApp
F6::Reload

killTT:
ToolTip
Return

#IfWinActive, osu!
~Left::
startTime-=5
; ToolTip, % startTime
; SetTimer, killTT, -500
Return

~Right::
startTime+=5
; ToolTip, % startTime
; SetTimer, killTT, -500
Return
