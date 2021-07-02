declare sub KBD_INIT()
declare function KBD_HANDLER(stack as IRQ_STACK ptr) as IRQ_STACK ptr
declare sub KBD_LoadKeys()
declare function KBD_IOCTL(handle as unsigned integer,p1 as unsigned integer,p2 as unsigned integer,p3 as unsigned integer,p4 as unsigned integer,p5 as unsigned integer,p6 as unsigned integer) as unsigned integer
declare function KBD_READ(count as unsigned integer,dest as any ptr) as unsigned integer
declare sub KBD_PutChar(char as unsigned byte)
declare sub KBD_FLUSH()