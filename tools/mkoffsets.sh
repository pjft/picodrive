# usage: mkoffsets <output dir>
# automatically compute structure offsets for gcc targets in ELF format

CC=${CC:-gcc}

# endianess of target (automagically determined below)
ENDIAN=

compile_rodata ()
{
	$CC $CFLAGS -I .. -c /tmp/getoffs.c -o /tmp/getoffs.o || exit 1
	rosect=$(readelf -S /tmp/getoffs.o | grep '\.rodata' |
						sed 's/^[^.]*././;s/ .*//')
	objcopy --dump-section $rosect=/tmp/getoffs.ro /tmp/getoffs.o || exit 1
	ro=$(xxd -ps /tmp/getoffs.ro)
	if [ "$ENDIAN" = "le" ]; then
		# swap needed for le target
		hex=""
		for b in $(echo $ro | sed 's/\([0-9a-f]\{2\}\)/\1 /g'); do
			hex=$b$hex;
		done
	else
		hex=$ro
	fi
	rodata=$(printf "%d" 0x$hex)
}

get_define () # prefix struct member member...
{
	prefix=$1; shift
	struct=$1; shift
	field=$(echo $* | sed 's/ /./g')
	name=$(echo $* | sed 's/ /_/g')
	echo '#include "pico/pico_int.h"' > /tmp/getoffs.c
	echo "static const struct $struct p;" >> /tmp/getoffs.c
	echo "const int offs = (char *)&p.$field - (char*)&p;" >>/tmp/getoffs.c
	compile_rodata
	line=$(printf "#define %-20s 0x%04x" $prefix$name $rodata)
}

# determine endianess
echo "const int one = 1;" >/tmp/getoffs.c
compile_rodata
ENDIAN=$(if [ "$rodata" -eq 1 ]; then echo be; else echo le; fi)
# determine output file
echo "const int vsz = sizeof(void *);" >/tmp/getoffs.c
compile_rodata
fn="${1:-.}/pico_int_o$((8*$rodata)).h"
# output header
echo "/* autogenerated by mkoffset.sh, do not edit */" >$fn
echo "/* target endianess: $ENDIAN, compiled with: $CC $CFLAGS */" >>$fn
# output offsets
get_define OFS_Pico_ Pico video reg		; echo "$line" >>$fn
get_define OFS_Pico_ Pico m rotate		; echo "$line" >>$fn
get_define OFS_Pico_ Pico m z80Run		; echo "$line" >>$fn
get_define OFS_Pico_ Pico m dirtyPal		; echo "$line" >>$fn
get_define OFS_Pico_ Pico m hardware		; echo "$line" >>$fn
get_define OFS_Pico_ Pico m z80_reset		; echo "$line" >>$fn
get_define OFS_Pico_ Pico m sram_reg		; echo "$line" >>$fn
get_define OFS_Pico_ Pico sv			; echo "$line" >>$fn
get_define OFS_Pico_ Pico sv data		; echo "$line" >>$fn
get_define OFS_Pico_ Pico sv start		; echo "$line" >>$fn
get_define OFS_Pico_ Pico sv end		; echo "$line" >>$fn
get_define OFS_Pico_ Pico sv flags		; echo "$line" >>$fn
get_define OFS_Pico_ Pico rom			; echo "$line" >>$fn
get_define OFS_Pico_ Pico romsize		; echo "$line" >>$fn
get_define OFS_Pico_ Pico est			; echo "$line" >>$fn

get_define OFS_EST_ PicoEState DrawScanline	; echo "$line" >>$fn
get_define OFS_EST_ PicoEState rendstatus	; echo "$line" >>$fn
get_define OFS_EST_ PicoEState DrawLineDest	; echo "$line" >>$fn
get_define OFS_EST_ PicoEState HighCol		; echo "$line" >>$fn
get_define OFS_EST_ PicoEState HighPreSpr	; echo "$line" >>$fn
get_define OFS_EST_ PicoEState Pico		; echo "$line" >>$fn
get_define OFS_EST_ PicoEState PicoMem_vram	; echo "$line" >>$fn
get_define OFS_EST_ PicoEState PicoMem_cram	; echo "$line" >>$fn
get_define OFS_EST_ PicoEState PicoOpt		; echo "$line" >>$fn
get_define OFS_EST_ PicoEState Draw2FB		; echo "$line" >>$fn
get_define OFS_EST_ PicoEState HighPal		; echo "$line" >>$fn

get_define OFS_PMEM_ PicoMem vram		; echo "$line" >>$fn
get_define OFS_PMEM_ PicoMem vsram		; echo "$line" >>$fn
