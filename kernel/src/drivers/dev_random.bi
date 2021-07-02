
declare sub RND_INIT()
declare function RND_IOCTL(handle as unsigned integer,p1 as unsigned integer,p2 as unsigned integer,p3 as unsigned integer,p4 as unsigned integer,p5 as unsigned integer,p6 as unsigned integer) as unsigned integer
declare function RND_READ(count as unsigned integer,dest as any ptr) as unsigned integer
declare function RNDCHAR_IOCTL(handle as unsigned integer,p1 as unsigned integer,p2 as unsigned integer,p3 as unsigned integer,p4 as unsigned integer,p5 as unsigned integer,p6 as unsigned integer) as unsigned integer
declare function RNDCHAR_READ(count as unsigned integer,dest as any ptr) as unsigned integer
