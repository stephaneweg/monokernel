
function F_EOF(fd as unsigned integer) as unsigned integer
    asm
        mov eax,0x0
        mov ebx,[fd]
        int 0x30
        mov [function],eax
    end asm
end function

function F_LEN(fd as unsigned integer) as unsigned integer
    asm
        mov eax,0x3
        mov ebx,[fd]
        int 0x30
        mov [function],eax
    end asm
end function

function F_READ(fd as unsigned integer,count as unsigned integer,dst as any ptr) as unsigned integer
    asm
        mov eax,0x01
        mov ebx,[fd]
        mov ecx,[count]
        mov edi,[dst]
        int 0x30
        mov [function],eax
    end asm
end function

function F_WRITE(fd as unsigned integer,count as unsigned integer,src as any ptr) as unsigned integer
    asm
        mov eax,0x02
        mov ebx,[fd]
        mov ecx,[count]
        mov esi,[src]
        int 0x30
        mov [function],eax
    end asm
end function

sub STD_OUT(s as unsigned byte ptr)
    dim i as unsigned integer=0
    while s[i]<>0
        F_WRITE(0,1,s+i)
        i+=1
    wend
end sub

function F_READ_BYTE(f as unsigned integer) as unsigned byte
    dim b as unsigned byte = 0
    if (F_READ(f,1,@b)<>0) then return b
    return 0
end function

function F_WRITE_BYTE(f as unsigned integer,b as unsigned byte) as unsigned integer
   return F_WRITE(0,1,@b)
end function

function STD_IN() as unsigned byte
    return F_READ_BYTE(0)
end function

sub STD_NEWLINE()
    dim b as unsigned byte = 10
    F_WRITE(0,1,@b)
end sub

sub CONSOLE_CLEAR()
    asm
        mov eax,&hF0
        int 0x30
    end asm
end sub

sub CONSOLE_WRITE(s as unsigned byte ptr)
    asm
        mov eax,&hF1
        mov esi,[s]
        int 0x30
    end asm
end sub

sub CONSOLE_WRITE_LINE(s as unsigned byte ptr)
    asm
        mov eax,&hF2
        mov esi,[s]
        int 0x30
    end asm
end sub

sub CONSOLE_NEW_LINE()
    asm
        mov eax,&hF3
        int 0x30
    end asm
end sub

sub CONSOLE_BACKSPACE()
    asm
        mov eax,&hF4
        int 0x30
    end asm
end sub

sub CONSOLE_PUT_CHAR(b as unsigned byte)
    dim bb as unsigned integer = b
    asm
        mov eax,&hF5
        mov ebx,[bb]
        int 0x30
    end asm
end sub

sub CONSOLE_WRITE_NUMBER(num as unsigned integer,b as unsigned integer)
    asm
        mov eax, &hF6
        mov ebx,[num]
        mov ecx,[b]
        int 0x30
    end asm
end sub

function STD_INPUT() as unsigned byte ptr
    if (F_EOF(0)=1) then
        CONSOLE_WRITE(@"END OF FILE")
        return 0
    end if
    CONSOLE_WRITE(@"root@onyx:#")
    dim i as unsigned integer = 0
    while F_EOF(0)=0
        var b = STD_IN()
        if (b=13) or (b=10) then
            if (i>0) then
                CONSOLE_NEW_LINE()
                input_data(i)=0
                if (i>0) then
                    return @input_data(0)
                else
                    return 0
                end if
            end if
        end if
        if (b=8) then
            if (i>0) then
                CONSOLE_BACKSPACE()
                i-=1
                input_data(i)=0
            end if
        end if
        if (b>=32) then
            CONSOLE_PUT_CHAR(b)
            input_data(i)=b
            i+=1
        end if
    wend
    if (i>0) then
        CONSOLE_NEW_LINE()
        input_data(i)=0
        return @input_data(0)
    end if
    return 0
end function

function FILE_EXISTS(path as unsigned byte ptr) as unsigned integer
    asm
        mov eax,&h10
        mov esi,[path]
        int 0x30
        mov [function],eax
    end asm
end function

function F_OPEN(path as unsigned byte ptr,mode as unsigned integer) as unsigned integer
    if (path<>0) then
        asm
            mov eax,&h11
            mov ebx,[path]
            mov ecx,[mode]
            int 0x30
            mov [function],eax
        end asm
    else
        return 0
    end if
end function

sub F_CLOSE(fd as unsigned integer)
    if (fd <>0) then
        asm
            mov eax,&h12
            mov ebx,[fd]
            int 0x30
        end asm
    end if
end sub

function TaskExec(path as unsigned byte ptr,args as unsigned byte ptr,stdin as unsigned integer,stdout as unsigned integer) as unsigned integer
    asm 
        mov eax,&h100
        mov ebx,[path]
        mov ecx,[stdin]
        mov edx,[stdout]
        mov esi,[args]
        int 0x30
        mov [function],eax
    end asm
end function
