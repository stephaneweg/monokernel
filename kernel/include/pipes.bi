TYPE PIPE_TYPE extends VFS_FILE_DESCRIPTOR field=1
    MAGIC_PIPE      as unsigned integer
    NEXT_PIPE       as PIPE_TYPE PTR
    PREV_PIPE       as PIPE_TYPE PTR
    BUFFER          as unsigned byte ptr
    BUFFER_SIZE     as unsigned integer
    BUFFER_PAGES    as unsigned integer
    ID              as unsigned integer

    declare constructor()
    declare destructor()
    
    declare function READ(count as unsigned integer,dest as unsigned byte ptr) as unsigned integer
    declare function WRITE(count as unsigned integer,src as unsigned byte ptr) as unsigned integer
    declare sub CreateBuffer(newsize as unsigned integer)
end type


dim shared FIRST_PIPE as PIPE_TYPE ptr
dim shared LAST_PIPE  as PIPE_TYPE ptr
dim shared PIPE_IDS   as unsigned integer
#define PIPE_NODE_MAGIC &h11111111
declare sub PIPES_INIT()
'declare function PIPE_FIND(n as unsigned byte ptr) as PIPE_TYPE ptr
declare function PIPE_OPEN(handle as unsigned integer,p as unsigned byte ptr,mode as unsigned integer) as unsigned integer
declare function PIPE_CLOSE(handle as unsigned integer,descr as any ptr) as unsigned integer
declare function PIPE_READ(handle as unsigned integer,descriptor as unsigned integer,count as unsigned integer,dest as any ptr) as unsigned integer
declare function PIPE_WRITE(handle as unsigned integer,descriptor as unsigned integer,count as unsigned integer,src as any ptr) as unsigned integer
 