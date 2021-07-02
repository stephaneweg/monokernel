#include once "multiboot.bi"
#include once "kernel.bi"
#include once "in_out.bi"
#include once "stdlib.bi"
#include once "console.bi"
#include once "pmm.bi"
#include once "vmm.bi"
#include once "pic.bi"
#include once "interrupt.bi"
#include once "gdt.bi"
#include once "elf.bi"
#include once "address_space.bi"

#include once "slab.bi"
#include once "vfs.bi"
#include once "device.bi"
#include once "block_device.bi"
#include once "pipes.bi"

#include once "task.bi"

#include once "drivers/dev_con.bi"
#include once "drivers/dev_random.bi"
#include once "drivers/keyboard.bi"
#include once "drivers/hd.bi"

#include once "drivers/dev_con.bas"
#include once "drivers/dev_random.bas"
#include once "drivers/keyboard.bas"
#include once "drivers/hd.bas"

#include once "fs/fatfs.bi"
#include once "fs/fatfs_file.bi"
#include once "fs/fatfs.bas"
#include once "fs/fatfs_file.bas"

#include once "syscall.bi"

function DUMMY_READ(handle as unsigned integer,descrHandle as unsigned integer,count as unsigned integer,buffer as any ptr) as unsigned integer
        CONSOLE_WRITE(@"READ LOCAL using vfs descriptor "):
        CONSOLE_WRITE_NUMBER(handle,10)
        CONSOLE_WRITE(@" - file descriptor ")
        CONSOLE_WRITE_NUMBER(descrHandle,10)
        CONSOLE_NEW_LINE()
        return 0
end function



sub MAIN (mb_info as multiboot_info ptr)
    asm cli
    CONSOLE_INIT()
    CONSOLE_SET_FOREGROUND(15)
    CONSOLE_WRITE_LINE(@"ONYX V0.1 Starting...")
    CONSOLE_SET_FOREGROUND(7)
    
    GDT_INIT()
    PMM_INIT(mb_info)
    VMM_INIT()
    VMM_INIT_LOCAL()
    SLAB_INIT()
    
    VFS_INIT()
    DEV_INIT()
    BLOCK_DEV_INIT()
    PIPES_INIT()
    
    InterruptsManager_Init()
    
    CON_INIT()
    RND_INIT()
    HD_INIT()
    
    
    FAT_MOUNT(@"hda1",@"/")
    
    
    KBD_INIT()
    
    
	IRQ_Attach_Handler(&h30,@SYSCALL_HANDLER)
    CURRENT_TASK = 0
    do
        var fp = TotalFreePages
        
        var result = TASK_EXECUTE(@"/bin/command",0,0,0)
        CONSOLE_WRITE(@"RESULT IS : "):CONSOLE_WRITE_NUMBER(result,10):CONSOLE_NEW_LINE()
        CONSOLE_WRITE(@"FREE PAGES BEFORE : "):CONSOLE_WRITE_NUMBER(fp,10):CONSOLE_NEW_LINE()
        CONSOLE_WRITE(@"FREE PAGES AFTER : "):CONSOLE_WRITE_NUMBER(TotalFreePages,10):CONSOLE_NEW_LINE()
        do:loop
    loop
    CONSOLE_WRITE(@"KERNEL HALTED")
    asm cli
    do
        asm hlt
    loop
end sub

sub KERNEL_ERROR(msg as unsigned byte ptr,code as unsigned integer)
    asm cli
    CONSOLE_SET_BACKGROUND(4)
    CONSOLE_SET_FOREGROUND(15)
    CONSOLE_CLEAR()
    CONSOLE_WRITE_LINE(@"KERNEL PANIC")
    CONSOLE_WRITE_LINE(msg)
    CONSOLE_WRITE_TEXT_AND_HEX(@"Code : ",code,true)
    CONSOLE_NEW_LINE()
    do:loop
    asm 
        cli
        .panic_halt:
            hlt
        jmp .panic_halt
    end asm
end sub


#include once "stdlib.bas"
#include once "console.bas"
#include once "pmm.bas"
#include once "arch/x86/pic.bas"
#include once "arch/x86/gdt.bas"
#include once "arch/x86/vmm.bas"
#include once "slab.bas"
#include once "vfs.bas"
#include once "device.bas"
#include once "block_device.bas"
#include once "pipes.bas"
#include once "interrupt.bas"
#include once "address_space.bas"

#include once "task.bas"
#include once "syscall.bas"