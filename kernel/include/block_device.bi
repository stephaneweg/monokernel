TYPE BLOCK_DEVICE field = 1
    MAGIC_BLOCK_DEV as unsigned integer
    NEXT_DEVICE     as BLOCK_DEVICE ptr
    PREV_DEVICE     as BLOCK_DEVICE ptr
    DEVICENAME      as unsigned byte ptr
    
    HANDLE          as unsigned integer
    BLOCK_SIZE      as unsigned integer
    READ_METHOD            as function(handle as unsigned integer, blockNum as unsigned integer, blockCount as unsigned integer,dest as unsigned byte ptr) as unsigned integer
    WRITE_METHOD           as function(handle as unsigned integer, blockNum as unsigned integer, blockCount as unsigned integer,src as unsigned byte ptr) as unsigned integer

    declare function READ(blockNum as unsigned integer, blockCount as unsigned integer,dest as unsigned byte ptr) as unsigned integer
    declare function WRITE(blockNum as unsigned integer, blockCount as unsigned integer,dest as unsigned byte ptr) as unsigned integer
end type


dim shared FIRST_BLOCK_DEVICE as BLOCK_DEVICE ptr
dim shared LAST_BLOCK_DEVICE  as BLOCK_DEVICE ptr

#define BLOCK_DEV_NODE_MAGIC &h11223355
declare sub BLOCK_DEV_INIT()
declare function BLOC_DEV_FIND(n as unsigned byte ptr) as BLOCK_DEVICE ptr
declare function BLOCK_DEVICE_CREATE(devname as unsigned byte ptr,handle as unsigned integer,read_method as any ptr,write_method as any ptr) as BLOCK_DEVICE ptr


