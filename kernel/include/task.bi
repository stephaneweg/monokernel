TYPE EXECUTABLE_Header field =1
    Magic       as unsigned integer
end type

TYPE task field = 1
    MAGIC       as unsigned integer
    STDIN       as VFS_DESCRIPTOR ptr
    STDOUT      as VFS_DESCRIPTOR ptr
    ENTRY       as function(args as unsigned byte ptr) as unsigned integer
  
    
    VMM_Context     as VMMContext
    TmpArgs         as unsigned byte ptr
    AddressSpace    as AddressSpaceEntry ptr
    
    declare constructor()
    declare destructor()
    declare function CreateAddressSpace(virt as unsigned integer) as AddressSpaceEntry ptr
    declare function LOAD(image as EXECUTABLE_Header ptr)  as function (args as unsigned byte ptr) as unsigned integer
    declare function LOAD_ELF(elfHeader as ELF_HEADER ptr)  as function (args as unsigned byte ptr)  as unsigned integer
end type

declare function TASK_EXECUTE(path as unsigned byte ptr,args as unsigned byte ptr,_stdin as unsigned integer,_stdout as unsigned integer) as unsigned integer

#define TASK_MAGIC = 0xAABBCCDD
dim shared CURRENT_TASK as TASK ptr