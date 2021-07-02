sub InterruptsManager_Init()
    CONSOLE_WRITE(@"Setup Interrupt manager")
	dim i as unsigned integer
	for i=0 to &h2f
		set_idt(i,cptr(unsigned integer ptr, @interrupt_tab)[i],&h8E)'_ring0_int_gate equ 10001110b 
        IRQ_ATTACH_HANDLER(i,0)
	next
	
	for i=&h30 to &hFF
		set_idt(i,cptr(unsigned integer ptr, @interrupt_tab)[i],&hEE)'_ring3_int_gate equ 11101110b 
		IRQ_ATTACH_HANDLER(i,0)
	next
	set_timer_freq(200)
	IRQ_Attach_Handler(&h20,@TIMER_IRQ)
	
	IDT_POINTER.IDT_BASE = cast(unsigned integer , @IDT_SEGMENT(0))
	IDT_POINTER.IDT_LIMIT = (sizeof(IDT_ENTRY) * &h100) -1
	IDT_POINTER.ALWAYS0 = &h0
	
	ASM lidt [IDT_POINTER]

	pic_init()
	CONSOLE_PRINT_OK()
    CONSOLE_NEW_LINE()
end sub


sub set_idt(intno as unsigned integer, irqhandler as unsigned integer,flag as unsigned byte)
	IDT_SEGMENT(intno).BASE_LO = (irqhandler and &hFFFF)
	IDT_SEGMENT(intno).BASE_HI = ((irqhandler shr 16) and &hFFFF)
	IDT_SEGMENT(intno).SEL = &h8
	IDT_SEGMENT(intno).ALWAYS0 = &h0
	IDT_SEGMENT(intno).FLAGS =  flag' 10001110b ;_ring0_int_gate
	
end sub


function int_handler (stack as irq_stack ptr) as irq_stack ptr
    dim returnStack as IRQ_Stack ptr =stack
	dim intno as unsigned integer = returnStack->intno
	
    select case intNo
        'case &h0 to &hC
        '    returnStack = ExceptionHandler(stack)
        'case &hD
        '    returnStack = ExceptionHandler(stack)
        'case &hE to &h1E
        '    returnStack = ExceptionHandler(stack)
            
        case else
            dim handler as function(stack as irq_stack ptr) as irq_stack ptr
            handler=IRQ_HANDLERS(intno)
            if (handler <> 0) then
                returnStack = handler(stack)
            end if
    end select
    
	IRQ_SEND_ACK(intno)
    
    return returnStack
end function



function TIMER_IRQ(stack as IRQ_STACK ptr) as IRQ_STACK ptr
	TIMER_COUNTER+=1
	if TIMER_WAIT>0 then TIMER_WAIT -=1
    return stack
end function

sub TIMER_DELAY(compteur as unsigned integer)

	TIMER_WAIT=compteur
	asm 
        pushfd
        sti
    end asm
    
	WHILE (TIMER_WAIT>0)
	WEND
    
    asm
        popfd
    end asm
end sub

sub IRQ_ENABLE(irq as unsigned byte)
	dim port as ushort
	dim b as unsigned byte
	if (irq < 8) then
		port = MASTER_DATA
	else
		port = SLAVE_DATA
		irq -= 8
	end if
    inb([port],[b])
	b = b and (not (1 shl irq))
    outb([port],[b])
end sub

sub IRQ_DISABLE(irq as unsigned byte)
	dim port as ushort
	dim b as unsigned byte
    
    if (irq < 8) then
		port = MASTER_DATA
	else
		port = SLAVE_DATA
		irq -= 8
	end if
    inb([port],[b])
    b = b or (1 shl irq)
    outb([port],[b])
end sub

sub IRQ_Attach_Handler(intno as unsigned integer,handler as function(stack as irq_stack ptr) as irq_stack ptr)
	IRQ_HANDLERS(intno)=handler
end sub


sub IRQ_Detach_Handler(intno as unsigned integer)
    IRQ_HANDLERS(intno)=0
end sub

sub IRQ_SEND_ACK(intno as unsigned integer)
    ASM
	mov ebx,[intno]
	cmp ebx,40
	jb int_handler.noout
		mov al,0x20
		out 0xa0,al
	int_handler.noout:
		mov al,0x20
		out 0x20,al

	END ASM
end sub