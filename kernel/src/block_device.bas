sub BLOCK_DEV_INIT()
    FIRST_BLOCK_DEVICE    = 0
    LAST_BLOCK_DEVICE     = 0
end sub

function BLOC_DEV_FIND(n as unsigned byte ptr) as BLOCK_DEVICE ptr
    if (n[0]=asc("/")) then n+=1
    var dev = FIRST_BLOCK_DEVICE
    while dev<>0
        if (dev->MAGIC_BLOCK_DEV=BLOCK_DEV_NODE_MAGIC) then
            if (strcmpignorecase(dev->DEVICENAME,n)=0) then
                return dev
            end if
        end if
        dev=dev->NEXT_DEVICE
    wend
    return 0
end function


function BLOCK_DEVICE_CREATE(devname as unsigned byte ptr,handle as unsigned integer,read_method as any ptr,write_method as any ptr) as BLOCK_DEVICE ptr
    CONSOLE_WRITE(@"CREATING BLOCK DEVICE "):CONSOLE_WRITE(devname)
    if (BLOC_DEV_FIND(devname) = 0) then
        dim dev as BLOCK_DEVICE PTR = KERNEL_ALLOC(sizeof(BLOCK_DEVICE))
        dev->DEVICENAME = KERNEL_ALLOC(strlen(devname)+1)
        strcpy(dev->DEVICENAME,devname)
        strtoupperfix(dev->DEVICENAME)
        
        dev->MAGIC_BLOCK_DEV        = BLOCK_DEV_NODE_MAGIC
        dev->HANDLE                 = handle
        dev->READ_METHOD            = read_method
        dev->WRITE_METHOD           = write_method
        dev->NEXT_DEVICE    = 0
        dev->PREV_DEVICE    = LAST_BLOCK_DEVICE
        if (LAST_BLOCK_DEVICE<>0) then 
            LAST_BLOCK_DEVICE->NEXT_DEVICE =dev
        else
            FIRST_BLOCK_DEVICE = dev
        end if
        LAST_BLOCK_DEVICE = dev
        
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

function BLOCK_DEVICE.READ(blockNum as unsigned integer, blockCount as unsigned integer,dest as unsigned byte ptr) as unsigned integer
    if (@this<>0) then
        if (this.MAGIC_BLOCK_DEV = BLOCK_DEV_NODE_MAGIC) then
            if (this.READ_METHOD<>0) then
                return this.READ_METHOD(this.HANDLE,blockNum,blockCount,dest)
            else
                CONSOLE_WRITE_LINE(@"NO READ METHOD FOR BLOCK DEVICE")
            end if
        else
            CONSOLE_WRITE_LINE(@"INVALID BLOCK DEVICE DESCRIPTOR")
        end if
    else
        CONSOLE_WRITE_LINE(@"NULL POINTER FOR BLOCK DEVICE")
    end if
    return 0
end function

function BLOCK_DEVICE.WRITE(blockNum as unsigned integer, blockCount as unsigned integer,dest as unsigned byte ptr) as unsigned integer
    if (@this<>0) then
        if (this.MAGIC_BLOCK_DEV = BLOCK_DEV_NODE_MAGIC) then
            if (this.WRITE_METHOD<>0) then
                return this.WRITE_METHOD(this.HANDLE,blockNum,blockCount,dest)
            else
                CONSOLE_WRITE_LINE(@"NO READ METHOD FOR BLOCK DEVICE")
            end if
        else
            CONSOLE_WRITE_LINE(@"INVALID BLOCK DEVICE DESCRIPTOR")
        end if
    else
        CONSOLE_WRITE_LINE(@"NULL POINTER FOR BLOCK DEVICE")
    end if
    return 0
end function