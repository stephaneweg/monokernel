#include once "stdio.bi"
#include once "stdio.bas"
#include once "stdlib.bi"
#include once "stdlib.bas"
declare function main cdecl alias "main" (args as unsigned byte ptr) as unsigned integer
declare sub DO_COMMAND(cmd as unsigned byte ptr)
declare function GET_EXEC_PATH(cmd as unsigned byte ptr) as unsigned byte ptr

dim shared data_(0 to 4096) as unsigned byte
function main cdecl alias "main" (args as unsigned byte ptr) as unsigned integer
     
    if (args<>0) then
		var cpt = atoi(args)
		if (cpt>0) then
            dim i as unsigned integer
            dim l as unsigned integer = F_LEN(0)
            if (l>0) then
                F_READ(0,l,@data_(0))
                
                for n as unsigned integer = 1 to cpt
                    F_WRITE(0,l,@data_(0))
                    STD_NEWLINE()
                next n
            
            end if
		end if
    end if
    return 0
end function


    
