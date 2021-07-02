type PARTINFO field=1
	bootflag    as unsigned byte
	head        as unsigned byte
	geom        as unsigned short
	id          as unsigned byte
	endhead     as unsigned byte
	endgeom     as unsigned short
	startpos    as unsigned integer
	nbrsect     as unsigned integer
end type

type DISK field = 1
    MAGIC       as unsigned integer
    DiskNumber  as unsigned integer
    Begin       as unsigned integer
    Present     as unsigned integer
    SectorCount as unsigned integer
    BytesCount  as unsigned integer
end type

declare sub HD_INIT()

declare function HD_CREATE(_
    resname as unsigned byte ptr,_
    diskNum as integer,_
    Begin as unsigned integer,_
    sectCount as unsigned integer,_
    bytesCount as unsigned integer _
) as DISK ptr

#define DISK_MAGIC &h14785236

declare function HD_READ_INTERNAL(d as DISK ptr,alba as unsigned integer,sectorcount as unsigned short,b as byte ptr) as unsigned integer
declare function HD_WRITE_INTERNAL(d as DISK PTR,alba as unsigned integer,sectorcount as unsigned short,b as byte ptr) as unsigned integer

declare function HD_READ(d as DISK ptr,alba as unsigned integer,sectorcount as unsigned short,b as byte ptr) as unsigned integer
declare function HD_WRITE(d as DISK PTR,alba as unsigned integer,sectorcount as unsigned short,b as byte ptr) as unsigned integer

declare sub HD_WAIT(abase as unsigned short)

declare sub HD_DETECT(pbase as unsigned short)
declare sub HD_DETECT_PARTITIONS(d as DISK ptr)