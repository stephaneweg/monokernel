dim shared KBD_BUFFER as unsigned byte ptr
dim shared KBD_BUFFERPOS as unsigned integer

dim shared keymapPtr as unsigned integer ptr
dim shared KEYMAP as unsigned byte ptr
dim shared KEYMAP_ALT as unsigned byte ptr
dim shared KEYMAP_SHIFT as unsigned byte ptr

dim shared KBD_CTRL as byte
dim shared KBD_ALT as byte
dim shared KBD_SHIFT as byte
dim shared KBD_CIRC as byte
dim shared KBD_GUILLEMETS as byte
dim shared NextArrow as unsigned byte

const KEY_LEFT=&h4B
const KEY_RIGHT=&h4D
const KEY_UP=&h48
const KEY_DOWN=&h50
const KEY_CTRL=29
const KEY_ALT=56
const KEY_ALTOFF=184
const KEY_SHIFT1=42             
const KEY_SHIFT2=54

sub KBD_LOADKEYS()
    var f = VFS_OPEN(@"/KEYS/FR.MAP",0)
    if (f<>0) then
        var fsize = VFS_FSIZE(f)
        var pages = fsize shr 12
        if (pages shl 12)<fsize then pages+=1
        keymapPtr = KMM_ALLOCPAGEMULTIPLES(pages)
        if (keymapPtr<>0) then
            VFS_READ(f,fsize,keymapPtr)
            var kmapBase = cast(unsigned integer,keymapPtr)
            KEYMAP = cptr(unsigned byte ptr, keymapPtr[0] + kmapBase)
            KEYMAP_ALT = cptr(unsigned byte ptr, keymapPtr[1] + kmapBase)
            KEYMAP_SHIFT = cptr(unsigned byte ptr, keymapPtr[2] + kmapBase)
            
            KBD_CTRL=0
            KBD_ALT=0
            KBD_SHIFT=0
            KBD_CIRC=0
            KBD_GUILLEMETS=0
        end if
        
        VFS_CLOSE(f)
    end if
    
end sub



function KBD_IOCTL(handle as unsigned integer,p1 as unsigned integer,p2 as unsigned integer,p3 as unsigned integer,p4 as unsigned integer,p5 as unsigned integer,p6 as unsigned integer) as unsigned integer
    if (p1=0) then
        return KBD_READ(p2,cptr(any ptr,p3))
    end if
    return 0
end function

function KBD_READ(count as unsigned integer,dest as any ptr) as unsigned integer
    if count=0 then return 0
    if (count>KBD_BUFFERPOS) then return 0
    'if count>KBD_BUFFERPOS then return 0
    if (count>KBD_BUFFERPOS) then
        asm 
            pushfd
            sti
        end asm
        
            while count>KBD_BUFFERPOS:wend
      
        asm
            popfd
        end asm
    end if
    
    for i as unsigned integer = 0 to count-1
        cptr(unsigned byte ptr,dest)[i] = KBD_BUFFER[i]
    next
    memcpy(KBD_BUFFER,KBD_BUFFER+count,KBD_BUFFERPOS-count)
    KBD_BUFFERPOS-=count
    return count
end function


sub KBD_INIT()
    CONSOLE_WRITE(@"INSTALLING KEYBOARD")
	KBD_BUFFER=KMM_ALLOCPAGE()
    KBD_BUFFERPOS = 0
	KBD_FLUSH()
    IRQ_ENABLE(&h1)
	IRQ_Attach_Handler(&h21,@KBD_HANDLER)
    CONSOLE_PRINT_OK()
    CONSOLE_NEW_LINE()
    KBD_LOADKEYS()
    DEVICE_CREATE(@"KBD",1,@KBD_IOCTL)
end sub

sub KBD_PutChar(char as unsigned byte)
    if (char = asc("c")) and (KBD_CTRL=1) then
        if (CURRENT_TASK<>0) then
            if (CURRENT_TASK->STDIN<>0) then
                dim  handle as VFS_FILE_DESCRIPTOR ptr = cptr(VFS_FILE_DESCRIPTOR ptr,CURRENT_TASK->STDIN)
                
                if (handle->MAGIC<>VFS_FILE_DESCRIPTOR_MAGIC) then
                    handle=0
                    dim handle2 as VFS_DESCRIPTOR ptr = cptr(VFS_DESCRIPTOR ptr,CURRENT_TASK->STDIN)
                    if (handle2<>SHARED_CON) then
                        if (handle2->MAGIC=VFS_DESCRIPTOR_MAGIC) then
                            handle = cptr(VFS_FILE_DESCRIPTOR ptr,handle2->handle)
                            if (handle->MAGIC<>VFS_FILE_DESCRIPTOR_MAGIC) then
                                handle=0
                            end if
                        end if
                    end if
                end if
                if (handle<>0) then
                    handle->END_OF_FILE=1
                end if
            end if
        end if
        KBD_BUFFER[KBD_BUFFERPOS] = 26
        KBD_BUFFERPOS+=1
    else
        if (KBD_BUFFERPOS<255) then
            KBD_BUFFER[KBD_BUFFERPOS] = char
            KBD_BUFFERPOS+=1
        end if
    end if
end sub

sub KBD_FLUSH()
	KBD_BUFFERPOS=0
    asm
		pusha
		INIT_KBD.FLUSH:
			xor eax,eax
			in al,0x60
			cmp al,0x0
		je INIT_KBD.FLUSH
		popa
	end ASM
end sub

function KBD_HANDLER(stack as IRQ_STACK ptr) as IRQ_STACK ptr
    
    dim akey as unsigned byte
	inb(&h60,[akey])
    if (akey=224) then
        NextArrow = 128
    else
        select case akey
            case KEY_CTRL:
                KBD_CTRL=1
            case KEY_CTRL+128:
                KBD_CTRL=0
            case KEY_ALT:
                KBD_ALT=1
            case KEY_ALT+128:
                KBD_ALT=0
            case KEY_SHIFT1:
                KBD_SHIFT=1
            case KEY_SHIFT2:
                KBD_SHIFT=2
            case KEY_SHIFT1+128:
                KBD_SHIFT=KBD_SHIFT AND 2
            case KEY_SHIFT2+128:
                KBD_SHIFT=KBD_SHIFT AND 1
            case else:
                if akey<128 then
                    dim k as unsigned byte=0
                    if KBD_SHIFT>0 then 
                        k=KEYMAP_SHIFT[akey]
                    elseif KBD_ALT>0 then
                        k=KEYMAP_ALT[akey]
                    else
                        k=KEYMAP[akey]
                    end if
                    
                    if k=94 then
                        KBD_CIRC=1
                        k=0
                    elseif k=249 then
                        KBD_GUILLEMETS=1
                        k=0
                    else
                        if KBD_CIRC=1 then
                            select case k
                            case 97: k=131 'â
                            case 101:k=136 'ê
                            case 105:k=140 'î
                            case 111:k=147 'ô
                            case 117:k=150 'û
                            end select
                        elseif KBD_GUILLEMETS=1 then
                            select case k
                            case 97: k=132 'ä
                            case 101:k=137 'ë
                            case 105:k=139 'ï
                            case 111:k=148 'ö
                            case 117:k=129 'ü
                            end select
                        end if
                        KBD_CIRC=0
                        KBD_GUILLEMETS=0
                    end if
                    
                    
                    if (k<>0) then 
                        KBD_PutChar(k or NextArrow)
                    end if
                end if
        end select
        NextArrow = 0
    end if
	return stack
end function