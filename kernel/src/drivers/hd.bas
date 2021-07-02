const HD_PRIMARBASE = &h1f0
const HD_SECUNDBASE = &h170

dim shared DiskNames(0 to 3) as byte ptr
dim shared PartitionNames(0 to 3,0 to 3) as byte ptr

dim shared HD_BUFFER as byte ptr
sub HD_INIT()
    CONSOLE_WRITE_LINE(@"DETECTING HARD DISK")
    DiskNames(0) = @"HDA"
	DiskNames(1) = @"HDB"
	DiskNames(2) = @"HDC"
	DiskNames(3) = @"HDD"
	PartitionNames(0,0)=@"HDA1"
	PartitionNames(0,1)=@"HDA2"
	PartitionNames(0,2)=@"HDA3"
	PartitionNames(0,3)=@"HDA4"
	PartitionNames(1,0)=@"HDB1"
	PartitionNames(1,1)=@"HDB2"
	PartitionNames(1,2)=@"HDB3"
	PartitionNames(1,3)=@"HDB4"
	PartitionNames(2,0)=@"HDC1"
	PartitionNames(2,1)=@"HDC2"
	PartitionNames(2,2)=@"HDC3"
	PartitionNames(2,3)=@"HDC4"
	PartitionNames(3,0)=@"HDD1"
	PartitionNames(3,1)=@"HDD2"
	PartitionNames(3,2)=@"HDD3"
	PartitionNames(3,3)=@"HDD4"
    HD_BUFFER = KMM_ALLOCPAGE()
    
    HD_DETECT(HD_PRIMARBASE)
    HD_DETECT(HD_SECUNDBASE)
    
end sub

function HD_CREATE(_
    resname as unsigned byte ptr,_
    diskNum as integer,_
    Begin as unsigned integer,_
    sectCount as unsigned integer,_
    bytesCount as unsigned integer _
) as DISK ptr
    dim d as DISK PTR = KERNEL_ALLOC(sizeof(disk))
    d->MAGIC        = DISK_MAGIC
    d->DISKNUMBER   = diskNum
    d->Begin        = begin
    d->Present      = 1
    d->SectorCount  = sectCount
    d->BytesCount   = bytesCount
    if (sectCount>0) then
        BLOCK_DEVICE_CREATE(resname,cuint(d),@HD_READ,@HD_WRITE)
    end if
    return d
end function



sub HD_WAIT(abase as unsigned short)
    dim abase7 as unsigned short= abase+7
    dim val7 as unsigned byte
    do
        inb([abase7],[val7])
         
    loop until (val7 and &h80) = 0
END SUB



function HD_READ(d as DISK ptr,alba as unsigned integer,sectorcount as unsigned short,b as byte ptr) as unsigned integer
        HD_READ_INTERNAL(d,alba+d->BEGIN,sectorcount,b)
        TIMER_DELAY(1)
        return HD_READ_INTERNAL(d,alba+d->BEGIN,sectorcount,b)
end function

function HD_WRITE(d as DISK ptr,alba as unsigned integer,sectorcount as unsigned short,b as byte ptr) as unsigned integer
        HD_WRITE_INTERNAL(d,alba+d->BEGIN,sectorcount,b)
        TIMER_DELAY(1)
        return HD_WRITE_INTERNAL(d,alba+d->BEGIN,sectorcount,b)
end function

function HD_WRITE_INTERNAL(d as DISK PTR,alba as unsigned integer,sectorcount as unsigned short,b as byte ptr) as unsigned integer
	dim lba0 as unsigned byte
    dim lba1 as unsigned byte
    dim lba2 as unsigned byte
    dim lba3 as unsigned byte
    dim lba4 as unsigned byte
    dim lba5 as unsigned byte
    
	dim abase as unsigned short
    dim abase2 as unsigned short
    dim abase3 as unsigned short
    dim abase4 as unsigned short
    dim abase5 as unsigned short
    dim abase6 as unsigned short
    dim abase7 as unsigned short
    
    dim out1 as unsigned byte
    dim out2 as unsigned byte
    dim outwval as unsigned short
    
	dim mydrive as unsigned byte
	dim nanosleep as unsigned byte
	dim buffer as unsigned short ptr=cptr(unsigned short ptr,b)
	dim x as unsigned integer
	dim cpt as integer
	if (d->DISKNUMBER<4) then
		'//lba48 pio
		'//selection du controleur et du disque
		select case d->DISKNUMBER
			case 0:
				abase=HD_PRIMARBASE
				mydrive=&h40
			case 1:
				abase=HD_PRIMARBASE
				mydrive=&h50
			case 2:
				abase=HD_SECUNDBASE
				mydrive=&h40
			case 3:
				abase=HD_SECUNDBASE
				mydrive=&h50
		end select
        
        abase2 = abase+2
        abase3 = abase+3
        abase4 = abase+4
        abase5 = abase+5
        abase6 = abase+6
        abase7 = abase+7
        
		lba0 =  alba AND &h000000FF
		lba1 = (alba AND &h0000FF00) shr 8
		lba2 = (alba AND &h00FF0000) shr 16
		lba3 = (alba AND &hFF000000) shr 24
		'//limit to 32bits (should be suffisant to read up to 2Tera
		lba4 = &h0
		lba5 = &h0
		
        out1 = (sectorcount and &hFF00) shr 8
        out2 = (sectorcount AND &hff)
		outb([abase6],[mydrive])	'//quel disque
		'//high
		outb([abase2],[out1]) ';//sector count high
		outb([abase3],[lba3])	';//LBA 4rd
		outb([abase4],[lba4]) ';//LBA 5rd
		outb([abase5],[lba5]) ';//LBA 5rd
		'//low
		outb([abase2],[out2]) ';//sectorcount low byte
		outb([abase3],[lba0])	'//LBA 1st
		outb([abase4],[lba1])	'//LBA 2nd
		outb([abase5],[lba2])	'//LBA 3rd
		outb([abase7],&h34)	'//Send "WRITE SECTOR EXT

		'//Wait for device to become ready
        dim buff as unsigned integer = cast(unsigned integer,b)
		for cpt=0 to sectorcount-1
                HD_WAIT(abase)
                asm
                    mov esi,[buff]
                    mov ecx,256
                    mov edx,[abase]
                    rep outsw
                end asm
                buff+=512
		next
		outw([abase7],&he7) 'Cache flush
        return 1
	end if
	return 0
end function


function HD_READ_INTERNAL(d as DISK ptr,alba as unsigned integer,sectorcount as unsigned short,b as byte ptr) as unsigned integer	
    dim lba0 as unsigned byte
    dim lba1 as unsigned byte
    dim lba2 as unsigned byte
    dim lba3 as unsigned byte
    dim lba4 as unsigned byte
    dim lba5 as unsigned byte
    
	dim abase as unsigned short
    dim abase2 as unsigned short
    dim abase3 as unsigned short
    dim abase4 as unsigned short
    dim abase5 as unsigned short
    dim abase6 as unsigned short
    dim abase7 as unsigned short
    dim out1 as unsigned byte
    dim out2 as unsigned byte
	dim mydrive as unsigned byte
	dim nanosleep as unsigned byte
	dim buffer as unsigned short ptr=cptr(unsigned short ptr,b)
	dim x as unsigned integer
	dim cpt as integer
    dim inwres as unsigned short
	if (d->DiskNumber<4) then
		'//lba48 pio
		'//selection du controleur et du disque
		select case d->DiskNumber
			case 0:
				abase=HD_PRIMARBASE
				mydrive=&h40
			case 1:
				abase=HD_PRIMARBASE
				mydrive=&h50
			case 2:
				abase=HD_SECUNDBASE
				mydrive=&h40
			case 3:
				abase=HD_SECUNDBASE
				mydrive=&h50
		end select
        abase2 = abase+2
        abase3 = abase+3
        abase4 = abase+4
        abase5 = abase+5
        abase6 = abase+6
        abase7 = abase+7
		lba0 =  alba AND &h000000FF
		lba1 = (alba AND &h0000FF00) shr 8
		lba2 = (alba AND &h00FF0000) shr 16
		lba3 = (alba AND &hFF000000) shr 24
		'//limit to 32bits (should be suffisant to read up to 2Tera
		lba4 = &h0
		lba5 = &h0
        
        out1 = (sectorcount and &hFF00) shr 8
        out2 = (sectorcount AND &hff)
		
		outb([abase6],[mydrive])	'//quel disque
		'//high
		outb([abase2],[out1]) ';//sector count high
		outb([abase3],[lba3])	';//LBA 4rd
		outb([abase4],[lba4]) ';//LBA 5rd
		outb([abase5],[lba5]) ';//LBA 5rd
		'//low
		outb([abase2],[out2]) ';//sectorcount low byte
		outb([abase3],[lba0])	'//LBA 1st
		outb([abase4],[lba1])	'//LBA 2nd
		outb([abase5],[lba2])	'//LBA 3rd
		outb([abase7],&h24)	'//Send "READ SECTOR EXT

		'//Wait for device to become ready
        dim buff as unsigned integer = cast(unsigned integer,b)
		for cpt=0 to sectorcount-1
                HD_WAIT(abase)
                asm
                    mov edi,[buff]
                    mov ecx,256
                    mov edx,[abase]
                    rep insw
                end asm
                buff+=512
                
		next
		return 1
	end if
	return 0
end function


sub HD_DETECT(pbase as unsigned short)
    dim rv1 as unsigned byte,rv2 as unsigned byte
    dim inpbase7 as unsigned integer
	dim cpt as integer
    dim pbase3 as unsigned short = pbase+3
    dim pbase6 as unsigned short = pbase+6
    dim pbase7 as unsigned short = pbase+7
	dim entry as DISK ptr
    
	outb([pbase3],&h88)
	inb([pbase3],[rv1])
	outb([pbase3],&h88)
	inb([pbase3],[rv2])
    if pbase=HD_PRIMARBASE then
        cpt=0
    else 
        cpt=2
    end if
	if (rv1 = &h88) then
		outb([pbase6],&hA0)
        TIMER_DELAY(1)
        inb([pbase7],[inpbase7])
		if (inpbase7 AND &h40)>0 then
                entry = HD_CREATE(DiskNames(cpt),cpt,0,0,0)
				HD_DETECT_PARTITIONS(entry)
		end if
		outb([pbase6],&hB0)
        TIMER_DELAY(1)
        inb([pbase7],[inpbase7])
		if (inpbase7 AND &h40)>0 then
                entry=HD_CREATE(DiskNames(cpt+1),cpt+1,0,0,0)
				HD_DETECT_PARTITIONS(entry)
		end if
	end if
end sub

sub HD_DETECT_PARTITIONS(d as DISK ptr)
    dim cpt as integer
	dim entry as DISK ptr
	dim table as PARTINFO ptr = cptr(PARTINFO ptr,HD_BUFFER+446)
    HD_READ_INTERNAL(d,0,1,HD_BUFFER)
	for cpt = 0 to 3
		if (table[cpt].ID AND &hFF) >0 then
            entry=HD_CREATE(PartitionNames(d->DiskNumber,cpt),d->DiskNumber,table[cpt].startpos,table[cpt].nbrsect,table[cpt].nbrsect shl 9)
		end if
	next
end sub