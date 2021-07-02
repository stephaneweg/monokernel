sub DEV_INIT()
    VFS_MKNOD(@"/dev",1,@DEV_OPEN,0,@DEV_READ,@DEV_WRITE,@DEV_SEEK,0,0,0)
    FIRST_DEVICE    = 0
    LAST_DEVICE     = 0
end sub

function DEV_FIND(n as unsigned byte ptr) as DEVICE ptr
    if (n[0]=asc("/")) then n+=1
    var dev = FIRST_DEVICE
    while dev<>0
        if (dev->MAGIC_DEV=DEV_NODE_MAGIC) then
            if (strcmpignorecase(dev->DEVICENAME,n)=0) then
                return dev
            end if
        end if
        dev=dev->NEXT_DEVICE
    wend
    return 0
end function

function DEV_OPEN(handle as unsigned integer,p as unsigned byte ptr,mode as unsigned integer) as unsigned integer
    'CONSOLE_WRITE(@"OPEN DEVICE "):Console_WRITE(p):Console_NEW_LINE()
    var dev = DEV_FIND(p)
    return cuint(dev)
end function

function DEV_READ(handle as unsigned integer,descriptor as unsigned integer,count as unsigned integer,dest as any ptr) as unsigned integer
    if (descriptor=0) then 
        CONSOLE_WRITE(@"INVALID DEVICE DESCRIPTOR")
        return 0
    end if
    var dev = cptr(DEVICE PTR,descriptor)
    
    if (dev->MAGIC_DEV = DEV_NODE_MAGIC) then
        if (dev->ENTRY<>0) then
            return dev->ENTRY(dev->HANDLE,0,count,cuint(dest),0,0,0)
        else
            CONSOLE_WRITE(@"NO ENTRY")
        end if
    else
        CONSOLE_WRITE(@"INVALID DEVICE DESCRIPTOR")
    end if
    return 0
end function

function DEV_WRITE(handle as unsigned integer,descriptor as unsigned integer,count as unsigned integer,src as any ptr) as unsigned integer
    if (descriptor=0) then 
        CONSOLE_WRITE(@"INVALID DEVICE DESCRIPTOR")
        return 0
    end if
    var dev = cptr(DEVICE PTR,descriptor)
    
    if (dev->MAGIC_DEV = DEV_NODE_MAGIC) then
        if (dev->ENTRY<>0) then
            dev->ENTRY(dev->HANDLE,1,count,cuint(src),0,0,0)
        end if
    else
        CONSOLE_WRITE(@"INVALID DEVICE DESCRIPTOR")
    end if
    return 0
end function

function DEV_SEEK(handle as unsigned integer,descriptor as unsigned integer,p as unsigned integer,m as unsigned integer) as unsigned integer
    if (descriptor=0) then 
        CONSOLE_WRITE(@"INVALID DEVICE DESCRIPTOR")
        return 0
    end if
    var dev = cptr(DEVICE PTR,descriptor)
    
    if (dev->MAGIC_DEV = DEV_NODE_MAGIC) then
        if (dev->ENTRY<>0) then
            return dev->ENTRY(dev->HANDLE,2,p,m,0,0,0)
        end if
    else
        CONSOLE_WRITE(@"INVALID DEVICE DESCRIPTOR")
    end if
    return 0
end function

function DEVICE_CREATE(devname as unsigned byte ptr,handle as unsigned integer,entry as any ptr) as DEVICE ptr
    CONSOLE_WRITE(@"CREATING DEVICE "):CONSOLE_WRITE(devname)
    if (DEV_FIND(devname) = 0) then
        dim dev as DEVICE PTR = KERNEL_ALLOC(sizeof(DEVICE))
        dev->DEVICENAME = KERNEL_ALLOC(strlen(devname)+1)
        strcpy(dev->DEVICENAME,devname)
        strtoupperfix(dev->DEVICENAME)
        
        dev->MAGIC          = VFS_FILE_DESCRIPTOR_MAGIC
        dev->FPOS           = 0
        dev->FSIZE          = -1
        dev->END_OF_FILE    = 0
        
        dev->MAGIC_DEV      = DEV_NODE_MAGIC
        dev->HANDLE         = handle
        dev->ENTRY          = entry
        dev->NEXT_DEVICE    = 0
        dev->PREV_DEVICE    = LAST_DEVICE
        if (LAST_DEVICE<>0) then 
            LAST_DEVICE->NEXT_DEVICE =dev
        else
            FIRST_DEVICE = dev
        end if
        LAST_DEVICE = dev
        
        CONSOLE_WRITE(@" ... CREATED")
        CONSOLE_PRINT_OK()
        
        CONSOLE_NEW_LINE()
        return DEV
    else
        CONSOLE_WRITE(@" ... ALREADY EXISTS")
        CONSOLE_NEW_LINE()
    end if
    return 0
end function
