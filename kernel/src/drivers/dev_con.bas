sub CON_INIT()
    CONSOLE_WRITE_LINE(@"Initializing CONSOLE device...")
    DEVICE_CREATE(@"con",1,@CON_IOCTL)
    SHARED_CON = VFS_OPEN(@"/dev/con",1)
end sub

function CON_IOCTL(handle as unsigned integer,p1 as unsigned integer,p2 as unsigned integer,p3 as unsigned integer,p4 as unsigned integer,p5 as unsigned integer,p6 as unsigned integer) as unsigned integer
    select case p1
        case 0
            return CON_READ(p2,cptr(any ptr,p3))
        case 1
            return CON_WRITE(p2,cptr(any ptr,p3))
    end select
    return 0
end function


function CON_READ(count as unsigned integer,dest as any ptr) as unsigned integer
    return KBD_READ(count,dest)
end function

function CON_WRITE(count as unsigned integer,src as any ptr) as unsigned integer
    if (count<1) then return 0
    var b = cptr(unsigned byte ptr,src)
    for i as unsigned integer = 0 to count-1
        CONSOLE_PUT_CHAR(b[i])
    next i
    return count
end function
