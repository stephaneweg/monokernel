
declare sub CON_INIT()
declare function CON_IOCTL(handle as unsigned integer,p1 as unsigned integer,p2 as unsigned integer,p3 as unsigned integer,p4 as unsigned integer,p5 as unsigned integer,p6 as unsigned integer) as unsigned integer
declare function CON_READ(count as unsigned integer,dest as any ptr) as unsigned integer
declare function CON_WRITE(count as unsigned integer,src as any ptr) as unsigned integer

dim shared SHARED_CON as VFS_DESCRIPTOR ptr