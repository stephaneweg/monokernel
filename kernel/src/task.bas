function TASK_EXECUTE(path as unsigned byte ptr,args as unsigned byte ptr,_stdin as unsigned integer,_stdout as unsigned integer) as unsigned integer
    dim result as unsigned integer = 0
    var f = VFS_OPEN(path,0)
    if (f<>0) then
       
        var fsize = VFS_FSIZE(f)
        if (fsize>0) then
            var neededPAGES = fsize shr 12
            if (neededPages shl 12)<fsize then neededPAGES+=1
            dim image as EXECUTABLE_HEADER ptr = KMM_ALLOCPAGEMULTIPLES(neededPAGES)
            VFS_READ(f,fsize,image)
            
            var t = cptr(TASK ptr,KERNEL_ALLOC(sizeof(TASK)))
            t->CONSTRUCTOR()
            
            
            var entry = t->LOAD(image)
            if (entry<>0) then
              
                if (_stdin<>0) then
                    t->STDIN = cptr(VFS_DESCRIPTOR ptr,_stdin)
                else
                    if (CURRENT_TASK<>0) then
                        t->STDIN = CURRENT_TASK->STDIN
                    else
                        t->STDIN = SHARED_CON
                    end if
                end if
                
                if (_stdout<>0) then
                    t->STDOUT = cptr(VFS_DESCRIPTOR ptr,_stdout)
                else
                    if (CURRENT_TASK<>0) then
                        t->STDOUT = CURRENT_TASK->STDOUT
                    else
                        t->STDOUT = SHARED_CON
                    end if
                end if
                
                var prevTASK = CURRENT_TASK
                CURRENT_TASK = t
                var ctx = current_context
                
                dim tmpArgs as unsigned byte ptr = 0
                if (args<>0) then
                    dim l as unsigned integer = strlen(args)
                    if (l>0) then 
                        tmpArgs = KERNEL_ALLOC(l+1)
                        strcpy(tmpArgs,args)
                    end if
                end if
                t->VMM_Context.ACTIVATE()
               
                result = entry(tmpArgs)
                
                ctx->ACTIVATE()
                if (tmpArgs<>0) then
                    KERNEL_FREE(tmpArgs)
                end if
                CURRENT_TASK = prevTASK
                
                
            else
                CONSOLE_WRITE_LINE(@"LOADING ABORTED")
            end if
            t->DESTRUCTOR()
            KERNEL_FREE(t)
            KMM_FREEPAGEMULTIPLES(image,neededPAGES)
        else
            CONSOLE_WRITE(@"EXEC - FILE IS EMPTY : "):CONSOLE_WRITE_LINE(path)
        end if
        VFS_CLOSE(f)
    else
        CONSOLE_WRITE(@"EXEC - FILE NOT FOUND : "):CONSOLE_WRITE_LINE(path)
    end if
    return result
end function

constructor TASK() 
    VMM_Context.Initialize()
    MAGIC           = 0
    STDIN           = 0
    STDOUT          = 0
    ENTRY           = 0
    AddressSpace    = 0
    TMPArgs         = 0
end constructor

destructor TASK()
    if (AddressSpace<>0) then
        AddressSpace->Destructor()
        KERNEL_FREE(AddressSpace)
        AddressSpace = 0
    end if
end destructor

function TASK.CreateAddressSpace(virt as unsigned integer) as AddressSpaceEntry ptr
    var address_space = cptr(AddressSpaceEntry ptr,KERNEL_ALLOC(sizeof(AddressSpaceEntry)))
   
    
    address_space->VMM_Context  = @VMM_Context
    address_space->VirtAddr     = virt
    
    address_space->NextEntry    = AddressSpace
    address_space->PrevEntry    = 0
    if (AddressSpace<>0) then AddressSpace->PrevEntry=address_space
    
    AddressSpace = address_space
    
    return address_space
end function
    

function TASK.LOAD(image as EXECUTABLE_Header ptr) as function (args as unsigned byte ptr) as unsigned integer
   
    dim entry as unsigned integer = 0
    if (image->Magic = ELF_MAGIC) then
        return LOAD_ELF(cptr(ELF_HEADER ptr,image))
    else
        CONSOLE_WRITE_LINE(@"EXEC - NOT A VALID ELF")
    end if
    return 0
end function

function TASK.LOAD_ELF(elfHeader as ELF_HEADER ptr)  as function (args as unsigned byte ptr)  as unsigned integer
    dim program_header as ELF_PROG_HEADER_ENTRY ptr = cast(ELF_PROG_HEADER_ENTRY ptr, cuint(elfHeader) + elfHeader->ProgHeaderTable)
    for counter as uinteger = 0 to elfHeader->ProgEntryCount-1
        dim start as unsigned integer       = program_header[counter].Segment_V_ADDR and VMM_PAGE_MASK
        dim real_size as unsigned integer   = program_header[counter].SegmentFSize + (program_header[counter].Segment_V_ADDR - start)
		dim real_mem_size as uinteger       = program_header[counter].SegmentMSize + (program_header[counter].Segment_V_ADDR - start)
        
        dim addr as uinteger = start
		dim end_addr as uinteger = start + real_size
		dim end_addr_mem as uinteger = start + real_mem_size
        
        var area = this.CreateAddressSpace(addr)
        var neededPages = (real_mem_size shr 12)
        if (neededPages shl 12)<real_mem_size then neededPages+=1
        
        
        area->SBRK(neededPages)
        
        if program_header[counter].SegmentType<>ELF_SEGMENT_TYPE_LOAD then
            'zone reserved
        else
            area->CopyFrom(cptr(any ptr,cuint(elfHeader)+ cuint(program_header[counter].Segment_P_ADDR)),real_size)
        end if
    next
    return cptr(function (args as unsigned byte ptr) as unsigned integer,elfHeader->ENTRY_POINT)
end function
