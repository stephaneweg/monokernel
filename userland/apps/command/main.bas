#include once "stdio.bi"
#include once "stdio.bas"
#include once "stdlib.bi"
#include once "stdlib.bas"
declare function main cdecl alias "main" (args as unsigned byte ptr) as unsigned integer
declare sub DO_COMMAND(cmd as unsigned byte ptr,_stdin as unsigned integer,_stdout as unsigned integer)
declare sub DO_COMMANDX(cmd as unsigned byte ptr,_stdin as unsigned integer)
declare function GET_EXEC_PATH(cmd as unsigned byte ptr) as unsigned byte ptr

function main cdecl alias "main" (args as unsigned byte ptr) as unsigned integer
    CONSOLE_WRITE_LINE(@"SHELL READY")
    if (args<>0) then
        CONSOLE_WRITE(@"arguments are : "):CONSOLE_WRITE_LINE(args)
    end if
    do
        var cmd = STD_INPUT()
        if cmd>0 then
            if (strcmp(cmd,@"exit")=0) then 
                exit do
            elseif (strcmp(cmd,@"ping")=0) then
                STD_OUT(@"pong")
            else
                DO_COMMANDX(cmd,0)
            end if
        end if
    loop until F_EOF(0)=1 'until end of stream
    return 55
end function

function str_TRIMX(x as unsigned byte ptr) as unsigned byte ptr
	dim s as unsigned byte ptr = x
	while (s[0]=32) or (s[0]=9) 
		s+=1
	wend
	var i = strlen(s)-1
	while (i>0) and (s[i]=32)
		s[i]=0
		i-=1
	wend
	return s
end function
	
	
sub DO_COMMANDX(cmd as unsigned byte ptr,_stdin as unsigned integer)
	cmd = str_TRIMX(cmd)
	dim i as unsigned integer = 0
	var inQuote = 0
	while cmd[i]<>0
		if (cmd[i]=34) then
			if (inQuote=0) then 
				inQuote=1
			else
				inQuote=0
			end if
		elseif (cmd[i]=asc("|")) and (inQuote=0) then
			cmd[i]=0
			var leftCMD  = str_TRIMX(cmd)
			var rightCMD = str_TRIMX(cmd+i+1)
			
			var p = F_OPEN(@"/pipes/x",1)
			DO_COMMAND(leftCMD,_stdin,p)
			DO_COMMANDX(rightCMD,p)
			F_CLOSE(p)
			exit sub
		end if
		i+=1
	wend
	
	DO_COMMAND(cmd,_stdin,0)
end sub

sub DO_COMMAND(cmd as unsigned byte ptr,_stdin as unsigned integer,_stdout as unsigned integer)
    if (cmd<>0) then
        dim i as unsigned integer
        dim cmdArgs as unsigned byte ptr = 0
        dim cmdName as unsigned byte ptr = cmd
        
        dim stdOutPath as unsigned byte ptr = 0
        dim stdInPath as unsigned byte ptr = 0
        
        var inQuote = 0
        
        
        while cmd[i]<>0
            if (cmd[i]=34) then
                if (inQuote=0) then 
                    inQuote=1
                else
                    inQuote=0
                end if
            elseif (cmd[i]=asc(">")) and (inQuote=0) then
                stdOutPath = cmd+i+1
                cmd[i]=0
            elseif (cmd[i]=asc("<")) and (inQuote=0) then 
                stdInPath = cmd+i+1
                cmd[i]=0
            end if
            i+=1
        wend
        i=0
        while cmd[i]<>0
            if (cmd[i]=32) then
                cmd[i]=0
                cmdArgs=cmd+i+1
                exit while
            end if
            i+=1
        wend
        if (stdInPath<>0) then
            while stdInPath[0]=32:stdInPath+=1:wend
            i = strlen(stdInPath)-1
            while (i>0) and (stdInPath[i]=32)
                stdInPath[i]=0
                i-=1
            wend
        end if
        if (stdOutPath<>0) then
            while stdOutPath[0]=32:stdOutPath+=1:wend
            i = strlen(stdOutPath)-1
            while (i>0) and (stdOutPath[i]=32)
                stdOutPath[i]=0
                i-=1
            wend
        end if
        
        if (cmdArgs<>0) then
            while cmdArgs[0]=32:cmdArgs+=1:wend
            i = strlen(cmdArgs)-1
            while (i>0) and (cmdArgs[i]=32)
                cmdArgs[i]=0
                i-=1
            wend
        end if
                
        var path = GET_EXEC_PATH(cmd)
        
        if (path<>0) then
			dim _astdin as unsigned integer = 0
			dim _astdout as unsigned integer = 0
			if (stdInPath<>0 and _stdin=0) 	then _astdin = F_OPEN(stdInPath,0)
			if (stdOutPath<>0 and _stdout=0)	then _astdout = F_OPEN(stdOutPath,1)
            
           
            var result = TaskExec(path,cmdArgs,iif(_stdin<>0,_stdin,_astdin),iif(_stdout<>0,_stdout,_astdout))
			
            F_CLOSE(_astdin)
            F_CLOSE(_astdout)
            
        else
            CONSOLE_WRITE(@"COMMAND NOT FOUND : "):CONSOLE_WRITE_LINE(cmd)
        end if
        
        
    end if
end sub

function GET_EXEC_PATH(cmd as unsigned byte ptr) as unsigned byte ptr
    dim path as unsigned byte ptr = cmd
    if (FILE_EXISTS(path)) then return path
    path = strcat(@"/bin/",cmd)
    if (FILE_EXISTS(path)) then return path
    
    return 0
end function



    
