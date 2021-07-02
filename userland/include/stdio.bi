declare function F_EOF(fd as unsigned integer) as unsigned integer
declare function F_LEN(fd as unsigned integer) as unsigned integer
declare function F_READ(fd as unsigned integer,count as unsigned integer,dst as any ptr) as unsigned integer
declare function F_WRITE(fd as unsigned integer,count as unsigned integer,src as any ptr) as unsigned integer
declare function F_READ_BYTE(f as unsigned integer) as unsigned byte
declare function F_WRITE_BYTE(f as unsigned integer,b as unsigned byte) as unsigned integer
    
declare sub STD_OUT(s as unsigned byte ptr)
declare function STD_IN() as unsigned byte
declare sub STD_NEWLINE()

declare sub CONSOLE_CLEAR()
declare sub CONSOLE_WRITE(s as unsigned byte ptr)
declare sub CONSOLE_WRITE_LINE(s as unsigned byte ptr)
declare sub CONSOLE_NEW_LINE()
declare sub CONSOLE_BACKSPACE()
declare sub CONSOLE_PUT_CHAR(b as unsigned byte)
declare sub CONSOLE_WRITE_NUMBER(num as unsigned integer,b as unsigned integer)
declare function STD_INPUT() as unsigned byte ptr
declare function FILE_EXISTS(path as unsigned byte ptr) as unsigned integer
dim shared input_data(0 to 1023) as unsigned byte
declare function F_OPEN(path as unsigned byte ptr,mode as unsigned integer) as unsigned integer
declare sub F_CLOSE(fd as unsigned integer)
declare function TaskExec(path as unsigned byte ptr,args as unsigned byte ptr,stdin as unsigned integer,stdout as unsigned integer) as unsigned integer
