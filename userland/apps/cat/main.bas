#include once "stdio.bi"
#include once "stdio.bas"
#include once "stdlib.bi"
#include once "stdlib.bas"
declare function main cdecl alias "main" (args as unsigned byte ptr) as unsigned integer
declare sub DO_COMMAND(cmd as unsigned byte ptr)
declare function GET_EXEC_PATH(cmd as unsigned byte ptr) as unsigned byte ptr

dim shared data_(0 to 4096) as unsigned byte
function main cdecl alias "main" (args as unsigned byte ptr) as unsigned integer
    
	dim i as unsigned integer =0
    if (args<>0) then
		var f = F_OPEN(args,0)
		if (f<>0) then
            WHILE F_EOF(f)=0
                F_WRITE_BYTE(0,F_READ_BYTE(f))
                i+=1
                if (STD_IN()=26) then exit while
            WEND
            dim l as unsigned integer = F_LEN(f)
			F_CLOSE(f)
            CONSOLE_WRITE_NUMBER(i,10):CONSOLE_WRITE(@" byte")
            if (i>1) then CONSOLE_WRITE(@"s")
            CONSOLE_WRITE_LINE(@" written")
		end if
	
    end if
    return 0
end function


    
