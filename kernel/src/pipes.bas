sub PIPES_INIT()
    VFS_MKNOD(@"/pipes",1,@PIPE_OPEN,@PIPE_CLOSE,@PIPE_READ,@PIPE_WRITE,0,0,0,0)
    FIRST_PIPE    = 0
    LAST_PIPE     = 0
    PIPE_IDS      = 1
end sub

'function PIPE_FIND(n as unsigned byte ptr) as PIPE_TYPE ptr
'    if (n[0]=asc("/")) then n+=1
'    var pipe_t = FIRST_PIPE
'    while pipe_t<>0
'        if (pipe_t->MAGIC_PIPE=PIPE_NODE_MAGIC) then
'            if (strcmpignorecase(pipe_t->PIPENAME,n)=0) then
'                return pipe_t
'            end if
'        end if
'        pipe_t=pipe_t->NEXT_PIPE
'    wend
'    return 0
'end function

function PIPE_OPEN(handle as unsigned integer,p as unsigned byte ptr,mode as unsigned integer) as unsigned integer
    'CONSOLE_WRITE(@"OPEN DEVICE "):Console_WRITE(p):Console_NEW_LINE()
   ' var pip = PIPE_FIND(p)
    
    'if (pip=0) then
    PIPE_IDS+=1
    dim pip as PIPE_TYPE ptr = KERNEL_ALLOC(sizeof(PIPE_TYPE ptr))
    pip->constructor()
    pip->ID = PIPE_IDS
    
    pip->NEXT_PIPE    = 0
    pip->PREV_PIPE    = LAST_PIPE
    if (LAST_PIPE<>0) then 
        LAST_PIPE->NEXT_PIPE =pip
    else
        FIRST_PIPE = pip
    end if
    LAST_PIPE = pip
    
    'end if
    return cuint(pip)
end function

function PIPE_CLOSE(handle as unsigned integer,descr as any ptr) as unsigned integer
    dim pip as PIPE_TYPE ptr = cptr(PIPE_TYPE ptr,descr)
    
    if (pip->PREV_PIPE<>0) then 
        pip->PREV_PIPE->NEXT_PIPE = pip->NEXT_PIPE
    else
        FIRST_PIPE = pip->NEXT_PIPE
    end if
    
    if (pip->NEXT_PIPE<>0) then
        pip->NEXT_PIPE->PREV_PIPE = pip->PREV_PIPE
    else
        LAST_PIPE = pip->PREV_PIPE
    end if
    
    pip->destructor()
    KERNEL_FREE(pip)
    
    return 1
end function

function PIPE_READ(handle as unsigned integer,descriptor as unsigned integer,count as unsigned integer,dest as any ptr) as unsigned integer
    if (descriptor=0) then 
        CONSOLE_WRITE(@"INVALID PIPE DESCRIPTOR")
        return 0
    end if
    var pip = cptr(PIPE_TYPE PTR,descriptor)
    
    if (pip->MAGIC_PIPE = PIPE_NODE_MAGIC) then
        return pip->READ(count,dest)
    else
        CONSOLE_WRITE(@"INVALID PIPE DESCRIPTOR")
    end if
    return 0
end function


function PIPE_WRITE(handle as unsigned integer,descriptor as unsigned integer,count as unsigned integer,src as any ptr) as unsigned integer
    if (descriptor=0) then 
        CONSOLE_WRITE(@"INVALID PIPE DESCRIPTOR")
        return 0
    end if
    var pip = cptr(PIPE_TYPE PTR,descriptor)
    
    if (pip->MAGIC_PIPE = PIPE_NODE_MAGIC) then
        return pip->WRITE(count,src)
    else
        CONSOLE_WRITE(@"INVALID PIPE DESCRIPTOR")
    end if
    return 0
end function


constructor PIPE_TYPE()
    MAGIC_PIPE      = PIPE_NODE_MAGIC
    MAGIC           = VFS_FILE_DESCRIPTOR_MAGIC
    FPOS            = 0
    FSIZE           = 0
    END_OF_FILE     = 0
    ID              = 0
    NEXT_PIPE       = 0
    PREV_PIPE       = 0
    BUFFER_SIZE     = 0 
    BUFFER_PAGES    = 0
    BUFFER          = 0
end constructor

destructor PIPE_TYPE()
    if (BUFFER<>0) then
        KMM_FREEPAGEMULTIPLES(BUFFER,BUFFER_PAGES)
        BUFFER = 0
        BUFFER_SIZE = 0
        BUFFER_PAGES = 0
    end if
end destructor

sub PIPE_TYPE.CreateBuffer(newsize as unsigned integer)
    if (newsize>BUFFER_SIZE) then
        var bsize     = newsize
        var bpages    = bsize shr 12
        if (bpages shl 12) < bsize then 
            bpages+=1
            bsize=bpages SHL 12
        end if
        
        dim newbuff as unsigned byte ptr = KMM_ALLOCPAGEMULTIPLES(bpages)
        if (BUFFER<>0) then
            memcpy(newbuff,BUFFER,BUFFER_SIZE)
            KMM_FREEPAGEMULTIPLES(BUFFER,BUFFER_PAGES)
            BUFFER = 0
            BUFFER_SIZE = 0
            BUFFER_PAGES = 0
        end if
        BUFFER          = newbuff
        BUFFER_SIZE     = bsize
        BUFFER_PAGES    = bpages
        
    end if
end sub

function PIPE_TYPE.WRITE(count as unsigned integer,src as unsigned byte ptr) as unsigned integer
    dim newSize as unsigned integer = FSIZE + count
    CreateBuffer(newSize)
    memcpy(BUFFER+FSIZE,src,count)
    FSIZE+=count
    END_OF_FILE = iif(FSIZE>0,0,1)
    return count
end function

function PIPE_TYPE.READ(count as unsigned integer,dst as unsigned byte ptr) as unsigned integer
    dim cpt as unsigned integer = count
    if (cpt>FSIZE) then cpt=fsize
    memcpy(dst,BUFFER,cpt)
    
    if (fsize-cpt>0) then
        memcpy(BUFFER,BUFFER+cpt,FSIZE-CPT)
    end if
    FSIZE-=cpt
    END_OF_FILE = iif(FSIZE>0,0,1)
    return cpt
end function