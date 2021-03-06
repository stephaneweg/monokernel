#include once "gdt.bi"
#include once "console.bi"


dim shared gdt(0 to 255) as gdt_entry
dim shared gp as gdt_ptr
dim shared KTSS as tss_struct
dim shared os_tss as unsigned integer
sub KTSS_INIT()
    dim curCR3 as unsigned integer
    os_tss = &h28 or 3
    KTSS.registres.esp = 0
    KTSS.cs = &h8
    KTSS.ds = &h10
    KTSS.es = &h10
    KTSS.fs = &h10
    KTSS.gs = &h10
    KTSS.ss = &h10
    
    KTSS.esp0 = 0
    KTSS.ss0 = &h10
    KTSS.esp1 = 0
    KTSS.ss1 = &h10
    KTSS.esp2 = 0
    KTSS.ss2 = &h10
    KTSS.eflags = &h202
    asm
        mov ebx,cr3
        mov [curCR3],ebx
    end asm
    KTSS.cr3 = curCR3
    KTSS.eip = 0
    KTSS.iomap_base=cast(unsigned short, cast(unsigned integer,@KTSS.iomap(0))-cast(unsigned integer,@KTSS)) '128
    dim i as integer
    for i=0 to 255
        KTSS.iomap(i) = &hff
    next i
    
    'do:loop
    asm
	mov eax ,[os_tss]
	ltr ax
    end asm
end sub

sub KTSS_SET(esp0 as unsigned integer,codeseg as unsigned short,dataseg as unsigned short,eflags as unsigned integer)
	KTSS.esp0 = esp0
	KTSS.SS0 = dataseg
	KTSS.ds = dataseg
	KTSS.es = dataseg
	KTSS.fs = dataseg
	KTSS.gs = dataseg
	KTSS.cs = codeseg
	KTSS.eflags = eflags
end sub

sub KTSS_SET_CR3(cr3 as unsigned integer)
	KTSS.CR3 = cr3
end sub

SUB GDT_INIT()
	CONSOLE_WRITE(@"Installing GDT ... ")
	
    gp.thelimit = (sizeof(gdt_entry) * 256) - 1
    gp.thebase = cast(unsigned integer,@gdt(0))
	
    
    dim i as integer
    for i = 0 to 255
        gdt(i).limit_low = 0
        gdt(i).base_low = 0
        gdt(i).base_middle = 0
        gdt(i).access = 0
        gdt(i).granularity = 0
        gdt(i).base_high = 0
    next
    
    'null seg
    gdt_set_gate(0,0,0,0,0)
    'for protected mode
    gdt_set_gate(1,0,&hffffffff,&h9a,0)	'0x8        'ring 0 code
    gdt_set_gate(2,0,&hffffffff,&h92,0)	'0x10       'ring 0 data
    gdt_set_gate(3,0,&hffffffff,&hFa,0)	'0x18       'ring 3 code
    gdt_set_gate(4,0,&hffffffff,&hF2,0)	'0x20       'ring 3 data
    gdt_set_gate(5,cast(unsigned integer,@KTSS),sizeof(tss_struct),&h89,0) '0x28 kernel TSS
    'for real mode call
    gdt_set_gate(6,0,&h0000ffff,&h9A,1)		'0x30   'realmode code
    gdt_set_gate(7,0,&h0000ffff,&h92,1)		'0x38   'realmode data
    
    
    ASM
	gdt_flush:
		lgdt [gp]
		jmp 0x8:flushed
		flushed:
		
		mov ax,0x10
		mov ds,ax 
		mov es,ax
		mov fs,ax
		mov gs,ax
		mov ss,ax
	END ASM
	CONSOLE_PRINT_OK()
    CONSOLE_NEW_LINE()
    
    'CONSOLE_WRITE(@"Initializing kernel TSS ...")
    'KTSS_INIT()
	'CONSOLE_PRINT_OK()
    'CONSOLE_NEW_LINE()
    
END SUB



sub gdt_set_gate(num as unsigned integer,thebase as unsigned integer, thelimit as unsigned integer, theaccess as byte,realmode as byte = 0)
    ldt_set_gate(@gdt(num),thebase,thelimit,theaccess,realmode)
end sub


sub ldt_set_gate(theLdt as gdt_entry ptr,thebase as unsigned integer, thelimit as unsigned integer, theaccess as byte,realmode as byte = 0)
   
    '== Setup the descriptor base address ==
    theLdt->base_low = (thebase and &hFFFF)
    theLdt->base_middle = (thebase shr 16) and &hFF
    theLdt->base_high = (thebase shr 24) and &hFF

    dim limit as unsigned integer = thelimit
    if (realmode=1) then
            theldt->granularity = &h0
    else
        if (limit>65536) then 'adjust granularity if required
            limit = limit shr 12
            theLdt->granularity = &hC0
        else
            theLdt->granularity = &h40
        end if
    end if
    '== Setup the descriptor limits ==
    theLdt->limit_low = (thelimit and &hFFFF)
    theLdt->granularity = theLdt->granularity or  ((limit shr 16) and &h0F)
    theLdt->access = theaccess
end sub