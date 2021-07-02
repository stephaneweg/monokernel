sub VFS_INIT()
    CONSOLE_WRITE(@"Initializing VFS")
    VFS_FIRST_NODE  = 0
    VFS_LAST_NODE   = 0
    CONSOLE_PRINT_OK()
    CONSOLE_NEW_LINE()
end sub

function VFS_CMP(s1 as unsigned byte ptr,s2 as unsigned byte ptr) as unsigned integer
    dim i as unsigned integer = 0
    while s1[i]<>0 and s2[i]<>0
        var c1 = s1[i]
        var c2 = s2[i]
        if (c1>=97 and c1<=122) then c1-=32
        if (c2>=97 and c2<=122) then c2-=32
        
        if (c1<>c2) then return 0
        i+=1
    wend
    'if (s1[i]=0 and s2[i]<>0 and s2[i]<>asc("/")) then return 0
    'if (s2[i]=0 and s1[i]<>0 and s1[i]<>asc("/")) then return 0 
    return i
end function

function VFS_FIND_NODE(path as unsigned byte ptr) as VFS_NODE ptr
    var node = VFS_FIRST_NODE
    dim deepestNode as VFS_NODE ptr
    dim deepestNodeLen as unsigned integer = 0
    while node<>0
        var i = VFS_CMP(node->PATH,path)
        if (i>deepestNodeLen) then
            deepestNodeLen = i
            deepestNode = node
        end if
        node=node->NEXT_NODE
    wend
    return deepestNode
end function

function VFS_NODE_EXISTS(path as unsigned byte ptr) as unsigned integer
    var node = VFS_FIRST_NODE
    while node<>0
        if (strcmp(node->PATH,path)=0) then return 1
        node=node->NEXT_NODE
    wend
    return 0
end function

function VFS_UMOUNT(p as unsigned byte ptr) as unsigned integer
    var node = VFS_FIND_NODE(p)
    if (node<>0) then
        if (node->UMOUNT_METHOD<>0) then
            node->UMOUNT_METHOD(node->HANDLE)
        end if
        if (node->NEXT_NODE<>0) then node->NEXT_NODE->PREV_NODE = node->PREV_NODE
        if (node->PREV_NODE<>0) then node->PREV_NODE->NEXT_NODE = node->NEXT_NODE
        if (VFS_LAST_NODE=node) then VFS_LAST_NODE = node->PREV_NODE
        if (VFS_FIRST_NODE = node) then VFS_FIRST_NODE = node->NEXT_NODE
        KERNEL_FREE(node)
    end if
    return 0
end function

function VFS_MKNOD(path as unsigned byte ptr,_
    handle as unsigned integer,_
    open_method as any ptr,_
    close_method as any ptr,_
    read_method as any ptr,_
    write_method as any ptr,_
    file_seek_method as any ptr,_
    ls_method as any ptr,_
    delete_method as any ptr, _
    umount_method as any ptr) as unsigned integer
    
    dim tmpPath as unsigned byte ptr= KERNEL_ALLOC(strlen(path)+2)
    strcpy(tmpPath,path)
    
    if (tmpPath[strlen(path)-1]<>asc("/")) then
        tmpPath[strlen(path)] = asc("/")
        tmpPath[strlen(path)+1] = 0
    end if
    strToUpperFix(tmpPath)
    
    if (VFS_NODE_EXISTS(tmpPath)=0) then
        dim node as VFS_NODE ptr = KERNEL_ALLOC(sizeof(VFS_NODE))
        node->PATH          = tmpPath
        node->MAGIC         = VFS_NODE_MAGIC
        node->HANDLE        = handle
        node->OPEN_METHOD   = open_method
        node->CLOSE_METHOD  = close_method
        node->READ_METHOD   = read_method
        node->WRITE_METHOD  = write_method
        node->LS_METHOD     = ls_method
        node->SEEK_METHOD   = file_seek_method
        node->UMOUNT_METHOD = umount_method
        
        
        node->NEXT_NODE = 0
        node->PREV_NODE = VFS_LAST_NODE
        if (VFS_LAST_NODE<>0) then 
            VFS_LAST_NODE->NEXT_NODE =node
        else
            VFS_FIRST_NODE = node
        end if
        VFS_LAST_NODE = node
        CONSOLE_WRITE(@"VFS NODE CREATED : "):CONSOLE_WRITE_LINE(node->PATH)
        return 1
    end if
    KERNEL_FREE(tmpPath)
    return 0
end function

function VFS_DUMMY_OPEN(handle as unsigned integer,p as unsigned byte ptr) as unsigned integer
        return 1
end function

function VFS_FILE_EXISTS(p as unsigned byte ptr) as unsigned integer
    var retval = 0
    var e = VFS_OPEN(p,0)
    if (e<>0) then
        retval = 1
        VFS_CLOSE(e)
    end if
    return retval
end function


function VFS_OPEN(path as unsigned byte ptr,mode as unsigned integer) as VFS_DESCRIPTOR ptr
    var node = VFS_FIND_NODE(path)
    if (node<>0) then
        'CONSOLE_WRITE(@"OPEN "):CONSOLE_WRITE(path):CONSOLE_WRITE(@" using vfs node : "):CONSOLE_WRITE_LINE(node->PATH)
        if (node->OPEN_METHOD<>0) then
            var h = node->OPEN_METHOD(node->HANDLE,path+strlen(node->PATH),mode)
            if (h<>0) then
                dim descr as VFS_DESCRIPTOR ptr = KERNEL_ALLOC(sizeof(VFS_DESCRIPTOR))
                descr->VFS = node
                descr->HANDLE = h
                descr->MAGIC = VFS_DESCRIPTOR_MAGIC
                return descr
            end if
        end if
    end if
    return 0
end function

sub VFS_CLOSE(descr as VFS_DESCRIPTOR ptr)
    if (descr<>0) then
        if (descr->MAGIC=VFS_DESCRIPTOR_MAGIC) then
            if (descr->VFS<>0) then
                if (descr->VFS->MAGIC=VFS_NODE_MAGIC) then
                    if (descr->VFS->CLOSE_METHOD<>0) then
                        VFS_ERR = descr->VFS->CLOSE_METHOD(descr->VFS->HANDLE,descr->HANDLE)
                    end if
                end if
            else
                CONSOLE_WRITE(@"NO HANDLE")
            end if
        else
            CONSOLE_WRITE(@"INVALID MAGIC")
        end if
    else
        CONSOLE_WRITE_LINE(@"NULL DESCRIPTOR")
    end if
end sub

function VFS_READ(descr as VFS_DESCRIPTOR ptr,count as unsigned integer,buffer as any ptr) as unsigned integer
    if (descr<>0) then
        if (descr->MAGIC=VFS_DESCRIPTOR_MAGIC) then
            if (descr->VFS<>0) then
                if (descr->VFS->MAGIC=VFS_NODE_MAGIC) then
                    if (descr->VFS->READ_METHOD<>0) then
                        VFS_ERR = descr->VFS->READ_METHOD(descr->VFS->HANDLE,descr->HANDLE,count,buffer)
                        return VFS_ERR
                    else
                        CONSOLE_WRITE(@"NO READ METHOD")
                    end if
                else
                    CONSOLE_WRITE(@"INVALID NODE MAGIC")
                end if
            else
                CONSOLE_WRITE(@"NO HANDLE")
            end if
        else
            CONSOLE_WRITE(@"INVALID DESCRIPTOR_MAGIC")
        end if
    else
        CONSOLE_WRITE_LINE(@"NULL DESCRIPTOR")
    end if
    return 0
end function

function VFS_WRITE(descr as VFS_DESCRIPTOR ptr,count as unsigned integer,buffer as any ptr) as unsigned integer
    if (descr<>0) then
        if (descr->MAGIC=VFS_DESCRIPTOR_MAGIC) then
            if (descr->VFS<>0) then
                if (descr->VFS->MAGIC=VFS_NODE_MAGIC) then
                    if (descr->VFS->WRITE_METHOD<>0) then
                        VFS_ERR = descr->VFS->WRITE_METHOD(descr->VFS->HANDLE,descr->HANDLE,count,buffer)
                        return VFS_ERR
                    end if
                end if
            end if
        end if
    end if
    return 0
end function


function VFS_WRITESTRING(descr as VFS_DESCRIPTOR ptr,txt as unsigned byte ptr) as unsigned integer
    return VFS_WRITE(descr,strlen(txt),txt)
end function

function VFS_WRITELINE(descr as VFS_DESCRIPTOR ptr,txt as unsigned byte ptr) as unsigned integer
    dim bnewline(0 to 1) as unsigned byte
    bnewline(0) = 13
    bnewline(1) = 10
    VFS_WRITESTRING(descr,txt)
    return VFS_WRITE(descr,2,@bnewline(0))
end function

function VFS_WRITEBYTE(descr as VFS_DESCRIPTOR ptr,b as unsigned byte) as unsigned integer
    return VFS_WRITE(descr,1,@b)
end function

function VFS_SEEK(descr as VFS_DESCRIPTOR ptr,p as unsigned integer,m as unsigned integer) as unsigned integer
      if (descr<>0) then
        if (descr->MAGIC=VFS_DESCRIPTOR_MAGIC) then
            if (descr->VFS<>0) then
                if (descr->VFS->MAGIC=VFS_NODE_MAGIC) then
                    if (descr->VFS->SEEK_METHOD<>0) then
                        VFS_ERR = descr->VFS->SEEK_METHOD(descr->VFS->HANDLE,descr->HANDLE,p,m)
                        return VFS_ERR
                    end if
                end if
            end if
        end if
    end if
    return 0
end function


function VFS_EOF(descr as VFS_DESCRIPTOR ptr) as unsigned integer
    var h = cptr(VFS_FILE_DESCRIPTOR ptr,descr->HANDLE)
    if (h->MAGIC = VFS_FILE_DESCRIPTOR_MAGIC) then
        return h->END_OF_FILE
    else
        return 1
    end if
end function

function VFS_READBYTE(descr as VFS_DESCRIPTOR ptr) as unsigned byte
    dim result as unsigned byte
    VFS_READ(descr,sizeof(unsigned byte),@result)
    return result
end function

function VFS_READSHORT(descr as VFS_DESCRIPTOR ptr) as unsigned short
    dim result as unsigned short
    VFS_READ(descr,sizeof(unsigned short),@result)
    return result
end function

function VFS_READINTEGER(descr as VFS_DESCRIPTOR ptr) as unsigned integer
    dim result as unsigned integer
    VFS_READ(descr,sizeof(unsigned integer),@result)
    return result
end function
    
function VFS_READLONG(descr as VFS_DESCRIPTOR ptr) as unsigned longint
    dim result as unsigned longint
    VFS_READ(descr,sizeof(unsigned longint),@result)
    return result
end function
    
function VFS_FILENAME(path as unsigned byte ptr) as unsigned byte ptr
    var l = strlen(path)
    if (l>0) then
        for i as integer = l-1 to 0 step -1
            if (path[i] = asc("/")) then
                return path+i+1
            end if
        next i
    end if
    return path
end function

function VFS_PARENTPATH(path as unsigned byte ptr) as unsigned byte ptr
    dim tmpPath as unsigned byte ptr = KERNEL_ALLOC(strlen(path)+1)
    strcpy(tmpPath,path)
    StrToUpperFix(tmpPath)
    var l = strlen(tmpPath)
    if (l>0) then
        for i as integer = l-1 to 0 step -1
            if (tmpPath[i] = asc("/")) then
                tmpPath[i] = 0
                return tmpPath
            end if
        next i
    end if
    KERNEL_FREE(tmpPath)
    return 0
end function

function VFS_FSIZE(descr as VFS_DESCRIPTOR ptr) as unsigned integer
    var h = cptr(VFS_FILE_DESCRIPTOR ptr,descr->HANDLE)
    if (h->MAGIC = VFS_FILE_DESCRIPTOR_MAGIC) then
        return h->FSIZE
    else
        return 0
    end if
end function

dim shared input_data(0 to 1024) as unsigned byte
function VFS_INPUT(descr as VFS_DESCriPTOR ptr) as unsigned byte ptr
    var h = cptr(VFS_FILE_DESCRIPTOR ptr,descr->HANDLE)
    if (h->MAGIC = VFS_FILE_DESCRIPTOR_MAGIC) then
        if (h->END_OF_FILE=1) then 
            CONSOLE_WRITE(@"END OF FILE")
            return 0
        end if
        CONSOLE_WRITE(@"root@onyx:#")
        dim i as unsigned integer = 0
        while VFS_EOF(descr)=0
            var b = VFS_READBYTE(descr)
            if (b=13) or (b=10) then
                CONSOLE_NEW_LINE()
                input_data(i)=0
                if (i>0) then
                    return @input_data(0)
                else
                    return 0
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
    else
        CONSOLE_WRITE(@"INVALID INPUT DEVICE")
        return 0
    end if
    return 0
end function
            
