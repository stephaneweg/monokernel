function SYSCALL_HANDLER(stack as IRQ_STACK ptr) as IRQ_STACK ptr
    select case stack->EAX
        case &h00 'FEOF
            dim descr as VFS_DESCRIPTOR ptr
            if (stack->EBX = 0) then
                descr = CURRENT_TASK->STDIN
            else
                descr = cptr(VFS_DESCRIPTOR ptr,stack->EBX)
            end if
            stack->EAX = VFS_EOF(descr)
            
        case &h01 'FREAD
            dim descr as VFS_DESCRIPTOR ptr
            if (stack->EBX = 0) then
                descr = CURRENT_TASK->STDIN
            else
                descr = cptr(VFS_DESCRIPTOR ptr,stack->EBX)
            end if
            stack->EAX = VFS_READ(descr,stack->ECX,cptr(any ptr,stack->EDI))
        case &h02 'FWRITE
            dim descr as VFS_DESCRIPTOR ptr
            if (stack->EBX = 0) then
                descr = CURRENT_TASK->STDOUT
            else
                descr = cptr(VFS_DESCRIPTOR ptr,stack->EBX)
            end if
            stack->EAX = VFS_WRITE(descr,stack->ECX,cptr(any ptr,stack->ESI))
            
        case &h03 'FLEN
            dim descr as VFS_DESCRIPTOR ptr
            if (stack->EBX = 0) then
                descr = CURRENT_TASK->STDIN
            else
                descr = cptr(VFS_DESCRIPTOR ptr,stack->EBX)
            end if
            stack->EAX = VFS_FSIZE(descr)
            
        case &h10 'file exists
            stack->EAX = VFS_FILE_EXISTS(cptr(unsigned byte ptr,stack->ESI))
        case &h11 'file open
            stack->EAX =cuint( VFS_OPEN(cptr(unsigned byte ptr,stack->EBX),stack->ECX))
        case &h12
            VFS_CLOSE(cptr(VFS_DESCRIPTOR ptr,stack->EBX))
        
       
        case &hF0
            CONSOLE_CLEAR()
        case &hF1
            if (stack->ESI<>0) then
                CONSOLE_WRITE(cptr(unsigned byte ptr,stack->ESI))
            end if
        case &hF2
            if (stack->ESI<>0) then
                CONSOLE_WRITE_LINE(cptr(unsigned byte ptr,stack->ESI))
            else
                CONSOLE_NEW_LINE()
            end if
        case &hF3
            CONSOLE_NEW_LINE()
        case &hF4
            CONSOLE_BACKSPACE()
        case &hF5
            CONSOLE_PUT_CHAR(stack->EBX)
        case &hF6
            CONSOLE_WRITE_NUMBER(stack->EBX,stack->ECX)
            
         case &h100 'execute
            stack->EAX = TASK_EXECUTE(cptr(unsigned byte ptr,stack->EBX),cptr(unsigned byte ptr,stack->ESI),stack->ECX,stack->EDX)
    end select
    return stack
end function