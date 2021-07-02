sub RND_INIT()
    CONSOLE_WRITE_LINE(@"Initializing RANDOM device...")
    DEVICE_CREATE(@"random",1,@RND_IOCTL)
    DEVICE_CREATE(@"randomchar",1,@RNDCHAR_IOCTL)
end sub

function RND_IOCTL(handle as unsigned integer,p1 as unsigned integer,p2 as unsigned integer,p3 as unsigned integer,p4 as unsigned integer,p5 as unsigned integer,p6 as unsigned integer) as unsigned integer
    select case p1
        case 0
            return RND_READ(p2,cptr(any ptr,p3))
    end select
    return 0
end function


function RND_READ(count as unsigned integer,dest as any ptr) as unsigned integer
    if (count=0) then return 0
    dim buff as unsigned byte ptr=dest
    dim i as integer
    for i=0 to count-1
        dim r as unsigned integer = NextRandomNumber(0,255)
        buff[i]= r and &hFF
    next i
    return count
end function


function RNDCHAR_IOCTL(handle as unsigned integer,p1 as unsigned integer,p2 as unsigned integer,p3 as unsigned integer,p4 as unsigned integer,p5 as unsigned integer,p6 as unsigned integer) as unsigned integer
    select case p1
        case 0
            return RNDCHAR_READ(p2,cptr(any ptr,p3))
    end select
    return 0
end function


function RNDCHAR_READ(count as unsigned integer,dest as any ptr) as unsigned integer
    if (count=0) then return 0
    dim buff as unsigned byte ptr=dest
    dim i as integer
    for i=0 to count-1
        dim r as unsigned integer = NextRandomNumber(33,128)
        buff[i]= r and &hFF
    next i
    return count
end function
