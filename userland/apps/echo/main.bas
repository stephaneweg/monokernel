#include once "stdio.bi"
#include once "stdio.bas"
#include once "stdlib.bi"
#include once "stdlib.bas"
declare function main cdecl alias "main" (args as unsigned byte ptr) as unsigned integer
declare sub DO_COMMAND(cmd as unsigned byte ptr)
declare function GET_EXEC_PATH(cmd as unsigned byte ptr) as unsigned byte ptr

function main cdecl alias "main" (args as unsigned byte ptr) as unsigned integer
    
    if (args<>0) then
        if (strlen(args)>0) then
            STD_OUT(args)
        end if
    end if
    return 0
end function


    
