p=smallest_4

CC=gcc

$p:	$p.c
	${CC} ${CFLAGS} -o $p $p.c uint8.c

clean:
	touch $p ; rm $p
