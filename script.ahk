; last version for taiko only;
; a new repository that supports `osu!` and `taiko` will be create soon;


#NoEnv
#SingleInstance force
SetBatchLines, -1
SendMode event
SetWorkingDir %A_ScriptDir%
SetKeyDelay, 1, 1

rand:=1

gui, +ToolWindow +AlwaysOnTop
gui, add, text,, Drop file on it
gui, show, x0 y0 w200 h200
Return

GuiClose:
ExitApp

GuiDropFiles:
gui, Cancel

FileRead, file, % A_GuiEvent

detected:=0

osu:=Object()
osu.time:=Object()
osu.event:=Object()
osu.eventover:=Object()
DllCall("QueryPerformanceFrequency", "Int64P", freq)	;系统时钟频率



Loop, Parse, file, `n
{
	lineContext:=A_LoopField
	IfInString, lineContext, [HitObjects]
		detected:=1
	if(!detected)
		Continue
	if(RegExMatch(lineContext, "\d+,\d+,(\d+),(\d+),(\d+)", match))
	{
		; Msgbox, % match1 " " match2
		osu.time.Insert(match1+0)
		osu.event.Insert(match3+0)

; example:
; 272,256,69085,2,0,L|400:240|88:240,1,420
; distance:441
; speed:420
; time:441/420 sec
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
			osu.event[osu.event.MaxIndex()]:=254
			osu.eventover.Insert(match1+time)
		}
		else if((match2+0)=12 and RegExMatch(lineContext, "(?:\d+,){5}(\d+)", matchEx))
		{
			osu.event[osu.event.MaxIndex()]:=255
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
; KeyWait, z, D
; KeyWait, x, D
Loop
{
	if(GetKeyState("z","P")=1 or GetKeyState("x","P")=1)
	break
	Else
	Sleep, 0
}
; Msgbox, testz
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
			Random, _rand_, -5, 5
			rand_temp+=_rand_
		}
		startTime+=rand_temp
	}
	while(nowTime//(freq/1000)-startTime<osu.time[ptr]-20)
	{
		DllCall("QueryPerformanceCounter", "Int64P",  nowTime)
	}
	eventHandler(osu.event[ptr])
	if(rand){
		startTime-=rand_temp
	}

}

Return

rands(min=0,max=100)
{
	Random, OutputVar, % Min, % Max
	Return, OutputVar
}

eventHandler(event)
{
	global ptr, nowTime, freq, startTime, osu
	ToolTip, % ptr
	if(event=0 or event=1)
	{
		; static red:=0
		; if(red=0)
		; Send, x
		; else if(red=1)
		; Send, c
		; else
		MouseClick, Left

		; red:=mod(red+1,3)
		Return
	}
	else if(event=2 or event=8)
	{
		; static blue:=0
		; if(blue=0)
		; Send, z
		; else if(blue=1)
		; Send, v
		; else
		MouseClick, Right

		; blue:=mod(blue+1,3)
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
		; MouseClick, Right
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
		; DllCall("QueryPerformanceCounter", "Int64P",  nowTime)
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
