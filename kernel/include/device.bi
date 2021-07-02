TYPE DEVICE extends VFS_FILE_DESCRIPTOR field=1
    MAGIC_DEV as unsigned integer
    NEXT_DEVICE as DEVICE PTR
    PREV_DEVICE as DEVICE PTR
    
    DEVICENAME as unsigned byte ptr
    HANDLE as unsigned integer

    ENTRY as function(handle as unsigned integer,p1 as unsigned integer,p2 as unsigned integer,p3 as unsigned integer,p4 as unsigned integer,p5 as unsigned integer,p6 as unsigned integer) as unsigned integer
end type



dim shared FIRST_DEVICE as DEVICE ptr
dim shared LAST_DEVICE  as DEVICE ptr

#define DEV_NODE_MAGIC &h11223344
declare sub DEV_INIT()
declare function DEV_FIND(n as unsigned byte ptr) as DEVICE ptr
declare function DEV_OPEN(handle as unsigned integer,p as unsigned byte ptr,mode as unsigned integer) as unsigned integer
declare function DEV_READ(handle as unsigned integer,descriptor as unsigned integer,count as unsigned integer,dest as any ptr) as unsigned integer
declare function DEV_WRITE(handle as unsigned integer,descriptor as unsigned integer,count as unsigned integer,src as any ptr) as unsigned integer
declare function DEV_SEEK(handle as unsigned integer,descriptor as unsigned integer,p as unsigned integer,m as unsigned integer) as unsigned integer

declare function DEVICE_CREATE(devname as unsigned byte ptr,handle as unsigned integer,entry as any ptr) as DEVICE ptr
