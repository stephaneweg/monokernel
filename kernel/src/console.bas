dim shared consoleWidth     as integer
dim shared consoleHeight    as integer
dim shared consoleCursorX   as integer
dim shared consoleCursorY   as integer
dim shared consoleColor     as unsigned byte
dim shared consoleBackground    as unsigned byte
dim shared consoleForeground    as unsigned byte
dim shared consolePtr       as unsigned short ptr


sub CONSOLE_INIT()
    consolePtr      = cptr(unsigned short ptr,&hB8000)
    consoleWidth    = 80
    consoleHeight   = 25
    consoleCursorX  = 0
    consoleCursorY  = 0
    CONSOLE_SET_FOREGROUND(7)
    CONSOLE_SET_BACKGROUND(0)
    CONSOLE_CLEAR()
    
    
end sub

sub CONSOLE_SET_FOREGROUND(c as unsigned byte)
    consoleColor = (consoleColor and &hF0) or (c and &h0F)
    consoleForeground = c
end sub

sub CONSOLE_SET_BACKGROUND(c as unsigned byte)
    consoleColor = (consoleColor and &h0F) or ((c and &hF) shl 4)
    consoleBackground = c
end sub

sub CONSOLE_WRITE_LINE(src as unsigned byte ptr)
    CONSOLE_WRITE(src)
    CONSOLE_NEW_LINE()
end sub

sub CONSOLE_NEW_LINE()
    consoleCursorX=0
    consoleCursorY=consoleCursorY+1
    if (consoleCursorY>=consoleHeight) then CONSOLE_SCROLL()
    CONSOLE_UPDATE_CURSOR()
end sub


sub CONSOLE_PRINT_OK()
    dim dst as byte ptr
    dst = CPtr(Byte Ptr, consolePtr)
	
	dst[(consoleCursorY*consoleWidth+consoleWidth-6)*2]=91 '['
    dst[(consoleCursorY*consoleWidth+consoleWidth-5)*2]=32 ' '
    dst[(consoleCursorY*consoleWidth+consoleWidth-4)*2]=79 'O'
    dst[(consoleCursorY*consoleWidth+consoleWidth-3)*2]=75 'K'
    dst[(consoleCursorY*consoleWidth+consoleWidth-2)*2]=32 ' '
    dst[(consoleCursorY*consoleWidth+consoleWidth-1)*2]=93 ']'
    dst[(consoleCursorY*consoleWidth+consoleWidth-0)*2]=32 ' '
    
    
    dst[(consoleCursorY*consoleWidth+consoleWidth-6)*2+1]=(consoleBackGround* 16 +9)
    dst[(consoleCursorY*consoleWidth+consoleWidth-5)*2+1]=(consoleBackGround* 16 +consoleForeGround)
    dst[(consoleCursorY*consoleWidth+consoleWidth-4)*2+1]=(consoleBackGround* 16 +10)
    dst[(consoleCursorY*consoleWidth+consoleWidth-3)*2+1]=(consoleBackGround* 16 +10)
    dst[(consoleCursorY*consoleWidth+consoleWidth-2)*2+1]=(consoleBackGround* 16 +consoleForeGround)
    dst[(consoleCursorY*consoleWidth+consoleWidth-1)*2+1]=(consoleBackGround* 16 +9)
    dst[(consoleCursorY*consoleWidth+consoleWidth-0)*2+1]=(consoleBackGround* 16 +consoleForeGround)
end sub
    

dim shared PrevNewLine as unsigned integer
sub CONSOLE_PUT_CHAR(c as unsigned byte)
    
    dim dst as byte ptr
    dst = CPtr(Byte Ptr, consolePtr)
    
    if (c=10) then 
        CONSOLE_NEW_LINE()
    elseif (c=8) then 
        CONSOLE_BACKSPACE()
    elseif(c=9) then
        consoleCursorX +=5-(consoleCursorX mod 5)
		if (consoleCursorX>=consoleWidth) then CONSOLE_NEW_LINE()
    elseif(c=13) then
        CONSOLE_NEW_LINE()
    else
        dst[(consoleCursorY*consoleWidth+consoleCursorX)*2]=c
        dst[(consoleCursorY*consoleWidth+consoleCursorX)*2+1]=consoleColor
        consoleCursorX=consoleCursorX+1
        if (consoleCursorX>=consoleWidth) then CONSOLE_NEW_LINE()
    end if
    CONSOLE_UPDATE_CURSOR()
end sub

sub CONSOLE_BACKSPACE()
    
    dim dst as byte ptr
    dst = CPtr(Byte Ptr, consolePtr)
    if (consoleCursorX=0) then
        if (consoleCursorY>0) then
            consoleCursorX=consoleWidth-1
			consoleCursorY-=1
        end if
        
    else
        consoleCursorX-=1
    end if
    dst[(consoleCursorY*consoleWidth+consoleCursorX)*2]=0
    'dst[(consoleCursorY*consoleWidth+consoleCursorX)*2+1]=consoleColor
    CONSOLE_UPDATE_CURSOR()
    
end sub

sub CONSOLE_WRITE(src as unsigned byte ptr)
    
    dim cpt as integer
    dim dst as byte ptr
    dst = CPtr(Byte Ptr, consolePtr)
    cpt=0
    WHILE src[cpt] <> 0
		if (src[cpt]=10) then 
			CONSOLE_NEW_LINE()
		elseif(src[cpt]=9) then
			consoleCursorX=consoleCursorX+5
			if (consoleCursorX>=consoleWidth) then CONSOLE_NEW_LINE()
		elseif(src[cpt]=13) then
		else
			dst[(consoleCursorY*consoleWidth+consoleCursorX)*2]=src[cpt]
			dst[(consoleCursorY*consoleWidth+consoleCursorX)*2+1]=consoleColor
			consoleCursorX=consoleCursorX+1
			if (consoleCursorX>=consoleWidth) then CONSOLE_NEW_LINE()
		end if
        cpt=cpt+1
    WEND
    CONSOLE_UPDATE_CURSOR()
end sub


sub CONSOLE_CLEAR()
	dim size as unsigned integer
	size=consoleWidth*consoleHeight
    for cpt as unsigned integer = 0 to size-1
        consolePTR[cpt]=0 or (ConsoleColor shl 8)
    next
    consoleCursorX = 0
    consoleCursorY = 0
    CONSOLE_UPDATE_CURSOR()
end sub


sub CONSOLE_UPDATE_CURSOR()
    dim position as unsigned short=consoleCursorY*consoleWidth+consoleCursorX
 
    dim p1 as unsigned byte  = position and &hFF
    dim p2 as unsigned byte = (position shr 8) and &hFF
    '// cursor LOW port to vga INDEX register
    outb(&h3D4, &h0F)
    outb(&h3D5, [p1])
    '// cursor HIGH port to vga INDEX register
    outb(&h3D4, &h0E)
    outb(&h3D5,[p2])
end sub


sub CONSOLE_SCROLL()
	dim y as integer
	dim x as integer
	dim scanLine as integer
	dim dst as byte ptr
    dst = CPtr(Byte Ptr, consolePtr)
	scanLine=consoleWidth*2
	
	y=0
	while y <consoleHeight-1
		x=0
		while x<scanLine
			dst[x]=dst[x+scanLine]
			x=x+1
		wend
		dst = dst+scanLine
		y=y+1
	WEND
	x=0
	while x<scanLine
		dst[x]=0
		dst[x+1]=consoleColor
		x=x+2
	wend
	consoleCursorY=consoleCursorY-1
    CONSOLE_UPDATE_CURSOR()
end sub


sub CONSOLE_WRITE_NUMBER(number as unsigned integer,abase as unsigned integer)
    CONSOLE_WRITE(IntToStr(number,abase))
end sub

sub CONSOLE_WRITE_TEXT_AND_HEX(src as unsigned byte ptr,n as unsigned integer,newline as boolean)
    CONSOLE_WRITE(src)
    CONSOLE_WRITE(@" 0x")
    CONSOLE_WRITE_NUMBER(n,16)
    if (newline) then CONSOLE_NEW_LINE()
end sub


sub CONSOLE_WRITE_TEXT_AND_DEC(src as unsigned byte ptr,n as unsigned integer,newline as boolean)
    CONSOLE_WRITE(src)
    CONSOLE_WRITE(@" ")
    CONSOLE_WRITE_NUMBER(n,10)
    if (newline) then CONSOLE_NEW_LINE()
end sub

sub CONSOLE_WRITE_TEXT_AND_SIZE(src as unsigned byte ptr,s as unsigned integer,newline as boolean)
    CONSOLE_WRITE(src)
    CONSOLE_WRITE(@" ")
    if (s<&h400) then 
        CONSOLE_WRITE_NUMBER(s,10)
        CONSOLE_WRITE(@" Bytes")
    elseif (s<&h100000) then
        CONSOLE_WRITE_NUMBER(s shr 10,10)
        CONSOLE_WRITE(@" KB")
    else
        CONSOLE_WRITE_NUMBER(s shr 20,10)
        CONSOLE_WRITE(@" MB")
    end if
    
    if (newline) then CONSOLE_NEW_LINE()
end sub
