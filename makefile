# REQUIRES GMAKE!!!!
#
# makefile for wgrib2
# 
# compiles every #@?! library needed by wgrib2
# then tries to compile wgrib2
#
# (1) must use gnu-make
# (2) the environment variable FC must be set to the fortran-90 or higher
#        in order to compile netcdf and the optional IPOLATES
# (3) the environment veriable CC must be set to the C compiler
#
#
# mod 1/07 M. Schwarb (libgrib2c name change)
# mod 4/09 W. Ebisuzaki (use config.h)
# mod 6/10 W. Ebisuzaki ipolates
# mod 8/11 W. Ebisuzaki support environment variable FC={fortran 90+ compiler}
#              needed by optional netcdf4 and ipolates
# mod 3/12 W. Ebisuzaki support openmp, gctpc
#
#   Optional modules:
#
# NETCDF3: link in netcdf3 library to write netcdf3 files
#    change: USE_NETCDF3=1 and USE_NETCDF4=0 in configuration below
#
# NETCDF4: link in netcdf4 library to write netcdf3/4 files
#    change: USE_NETCDF3=0 and USE_NETCDF4=1 in configuration below
#    need to download netcdf4 and hdf5 libraries and to put into grib2 directory
#    need to define environment variable FC to be the command for the fortran compiler
#
# IPOLATES: link in IPOLATES library to interpolate to new grids
#    change: USE_IPOLATES=1 in configuration below
#    need to define environment variable FC to be the command for the fortran compiler
#    need to modify makefile and perhaps source code
#
#  MYSQL: link in interface to MySQL to write to mysql database
#    change: USE_MYSQL=1 in configuration below
#    need to have mysql installed
#    may need to modify makefile
#
#  UDF: add commands for user-defined functions and shell commands
#    change: USE_UDF=1 in configuration below
#
#  REGEX: use regular expression library, on by default
#    change: USE_REGEX=0 to turn off (configuration below)
#
#  TIGGE: ability for TIGGE-like variable names, on by default
#    change: USE_TIGGE=0 to turn off (configuration below)
#
#
# this version uses netcdf 3 libraries -- compile C only version
#  get from UCAR if compile doesn't work
#
#
#
# on NCEP AIX
# export CC=/usr/vacpp/bin/xlc_r
# export CPP=/usr/bin/cpp
# export FC=xlf_r
#
# for OS-X: uncomment line for makefile -f scripts/makefile.darwin
#
SHELL=/bin/sh

# 
# netcdf3: write netcdf files with netcdf-3 library
# netcdf4: write netcdf files with netcdf-4 library
# regex: regular expression package used by (match,not), POSIX-2
# tigge: enable -tigge option for tigge names
# mysql: write to mysql files
# ipolates: fortran interpolation library
# udf: user defined functions
# openmp: ALPHA,  multicore support using OpenMP
#
# the flags are stored in wgrib2/config.h
#

# Warning do not set both USE_NETCDF3 and USE_NETCDF4 to one
USE_NETCDF3=1
USE_NETCDF4=0
USE_REGEX=0
USE_TIGGE=1
USE_MYSQL=0
USE_IPOLATES=0
USE_UDF=0
USE_OPENMP=0

# often enviroment variable FC=fortran compiler, if not, define it here
# FC=gfortran
bindir=${cwd}
prog=${bindir}/kwgrib2

ifeq ($(USE_NETCDF3),1)
  ifeq ($(USE_NETCDF4),1)
    $(error ERROR, USE_NETCDF3 = 1 and USE_NETCDF4 = 1: can not link in 2 netcdf libraries)
  endif
endif

ifeq ($(USE_NETCDF4),1)
  ifeq ($(FC),)
    $(error ERROR, USE_NETCDF4 = 1: must set fortran90 compiler by environement variable FC)
  endif
endif

ifeq ($(USE_IPOLATES),1)
  ifeq ($(FC),)
    $(error ERROR, USE_IPOLATES = 1: must set fortran90 compiler by environement variable FC)
  endif
endif


# wCPPFLAGS has the directory of the includes 
# wLDFLAGS has the directory/name of the library

ifeq ($(CC),gcc)
   wCPPFLAGS+=-Wall -Wmissing-prototypes -Wold-style-definition -ffast-math  -O3 -g
endif
ifeq ($(CC),opencc)
   wCPPFLAGS+=-O3 -Wall -ffast-math -opencc
endif
ifeq ($(CC),icc)
   wCPPFLAGS+=-O2
   $(error ERROR, makefile does not make jasper correctly with intel compiler)
endif
ifeq ($(CC),pgcc)
   wCPPFLAGS+=-O2
   $(error ERROR, makefile does not make jasper correctly with portland compiler)
endif
ifeq ($(notdir $(CC)),xlc_r)
   wCPPFLAGS+=-O3
endif

ifndef wCPPFLAGS
   wCPPFLAGS+=-O3
endif

wLDFLAGS:=
cwd:=${CURDIR}

CONFIG_H=${cwd}/wgrib2/config.h
a:=$(shell echo "/* config.h */" > ${CONFIG_H})

ifeq ($(USE_REGEX),1)
   a:=$(shell echo "\#define USE_REGEX" >> ${CONFIG_H})
else
   a:=$(shell echo "//\#define USE_REGEX" >> ${CONFIG_H})
endif

ifeq ($(USE_TIGGE),1)
   a:=$(shell echo "\#define USE_TIGGE" >> ${CONFIG_H})
else
   a:=$(shell echo "//\#define USE_TIGGE" >> ${CONFIG_H})
endif

# grib2c library

g:=${cwd}/g2clib-1.2.1
glib:=$g/libgrib2c.a
wLDFLAGS+=-L$g -lgrib2c
wCPPFLAGS+=-I$g

# gctpc library
gctpc:=${cwd}/gctpc
gctpclib:=${gctpc}/source/libgeo.a
wLDFLAGS+=-L${gctpc}/source -lgeo
wCPPFLAGS+=-I${gctpc}/source

# Jasper

j=${cwd}/jasper-1.900.1
jlib=$j/src/libjasper/.libs/libjasper.a
wLDFLAGS+=-L$j/src/libjasper/.libs -ljasper
wCPPFLAGS+=-I$j/src/libjasper/include


ifeq ($(USE_NETCDF3),1)
   n:=${cwd}/netcdf-3.6.2
   nlib:=$n/libsrc/.libs/libnetcdf.a
   wLDFLAGS+=-L$n/libsrc/.libs -lnetcdf
   wCPPFLAGS+=-I$n/libsrc
   a:=$(shell echo "\#define USE_NETCDF3" >> ${CONFIG_H})
else
   a:=$(shell echo "//\#define USE_NETCDF3" >> ${CONFIG_H})
endif

ifeq ($(USE_NETCDF4),1)
   n4:=${cwd}/netcdf-4.1.3
   n4lib:=${n4}/libsrc4/.libs/libnetcdf.a
   h5:=${cwd}/hdf5-1.8.6
   h5lib:=${h5}/src/.libs/libhdf5.a
#   wLDFLAGS+=-L${n4}/libsrc/.libs -lnetcdf
   wLDFLAGS+=-L${n4}/libsrc4/.libs -lnetcdf -L${h5}/hl/src/.libs -lhdf5_hl -L${h5}/src/.libs -lhdf5
   wCPPFLAGS+=-I${n4}/libsrc4
   a:=$(shell echo "\#define USE_NETCDF4" >> ${CONFIG_H})
else
   a:=$(shell echo "//\#define USE_NETCDF4" >> ${CONFIG_H})
endif

ifeq ($(USE_MYSQL),1)
   wCPPFLAGS+=`mysql_config --cflags`
   wLDFLAGS+=`mysql_config --libs`
   a:=$(shell echo "\#define USE_MYSQL" >> ${CONFIG_H})
else
   a:=$(shell echo "//\#define USE_MYSQL" >> ${CONFIG_H})
endif

ifeq ($(USE_IPOLATES),1)
   ip:=${cwd}/iplib.2012
   iplib:=${ip}/libipolate.a
   wLDFLAGS+=-L${ip} -lipolate 

#  for compiling with fortran library
#  wLDFLAGS+= (libraries need by the fortran code)
#  wCPPFLAGS+= -D(FORTRAN Name)   see New_grid.c

# for G95 - personal system
   ifeq ($(FC),g95)
#      wLDFLAGS+=-L/export/wesley/wd51we/g95-install/lib/gcc-lib/i686-unknown-linux-gnu/4.0.3 -lf95
      wLDFLAGS+=-L/export/wesley/wd51we/g95-install_64/lib/gcc-lib/x86_64-unknown-linux-gnu/4.0.3 -lf95
      wCPPFLAGS+=-DG95
      wFFLAGS+=-O2
    endif

# for gfortran - ubuntu and cygwin 1.7.7-1
   ifeq ($(FC),gfortran)
      wLDFLAGS+=-lgfortran
      wCPPFLAGS+=-DGFORTRAN
      wFFLAGS+=-O2
   endif

# for open64 fortran - personal system
   ifeq ($(FC),openf95)
      wLDFLAGS+=/export/wesley/wd51we/opt/x86_open64-4.5.1/lib/gcc-lib/x86_64-open64-linux/4.5.1/libfortran.a
      wLDFLAGS+=/export/wesley/wd51we/opt/x86_open64-4.5.1/lib/gcc-lib/x86_64-open64-linux/4.5.1/libffio.a
      wCPPFLAGS+=-DOPENF95
      wFFLAGS+=-O2
   endif

# for portland f95
   ifeq ($(FC),pgf95)
#      wLDFLAGS+=/export/wesley/wd51we/opt/x86_open64-4.2.5.1/lib/gcc-lib/x86_64-open64-linux/4.2.5.1/libfortran.a
#      wLDFLAGS+=/export/wesley/wd51we/opt/x86_open64-4.2.5.1/lib/gcc-lib/x86_64-open64-linux/4.2.5.1/libffio.a
      wCPPFLAGS+=-DPGF95
      wFFLAGS+=-O2
   endif

# intel fortran
   ifeq ($(FC),ifort)
      wCPPFLAGS+=-DIFORT -cxxlib
      wLDFLAGS+=-lifcore -lc -limf -lintlc
      wFFLAGS+=-O2 -nofor_main  -cxxlib
   endif

# NCEP CCS:
   ifeq ($(FC),xlf_r)
      wLDFLAGS+=-L/usr/lib - -lxlf90_r
      wCPPFLAGS+=-DXLF
      wFFLAGS+=-O2
   endif

   a:=$(shell echo "\#define USE_IPOLATES" >> ${CONFIG_H})
else
   a:=$(shell echo "//\#define USE_IPOLATES" >> ${CONFIG_H})
endif

ifeq ($(USE_UDF),1)
   a:=$(shell echo "\#define USE_UDF" >> ${CONFIG_H})
else
   a:=$(shell echo "//\#define USE_UDF" >> ${CONFIG_H})
endif

# OPENMP .. only select configurations
ifeq ($(USE_OPENMP),1)
   ifeq ($(CC),gcc)
      ifeq ($(FC),gfortran)
         a:=$(shell echo "\#define USE_OPENMP" >> ${CONFIG_H})
         wCPPFLAGS+=-fopenmp
         wFFLAGS+=-fopenmp
      endif
   endif
   ifeq ($(CC),opencc)
      ifeq ($(FC),openf95)
         a:=$(shell echo "\#define USE_OPENMP" >> ${CONFIG_H})
         wCPPFLAGS+=-fopenmp
         wFFLAGS+=-fopenmp
      endif
   endif
   ifeq ($(CC),icc)
      ifeq ($(FC),ifort)
         a:=$(shell echo "\#define USE_OPENMP" >> ${CONFIG_H})
         wCPPFLAGS+=-openmp
         wFFLAGS+=-openmp
      endif
   endif
   ifeq ($(notdir $(CC)),xlc_r)
      ifeq ($(FC),xlf_r)
         a:=$(shell echo "\#define USE_OPENMP" >> ${CONFIG_H})
         wCPPFLAGS+=-qsmp=omp
         wFFLAGS+=-qsmp=omp
      endif
   endif
endif


# save fortran and C compiler names in config.h file

a:=$(shell echo "\#define CC \"${CC}\"" >> ${CONFIG_H})
a:=$(shell echo "\#define FORTRAN \"${FC}\"" >> ${CONFIG_H})

# png 

p=${cwd}/libpng-1.2.44
plib=$p/.libs/libpng.a
wLDFLAGS+=-L$p/.libs -lpng
wCPPFLAGS+=-I$p

# z

z=${cwd}/zlib-master
zlib=$z/libz.a
wLDFLAGS+=-L$z -lz
wCPPFLAGS+=-I$z

wLDFLAGS+=-lm
wCPPFLAGS+=-I/usr/include ${CPPFLAGS}

# -----------------------------------------------------

wLDFLAGS+=-lm
wCPPFLAGS+=-I/usr/include ${CPPFLAGS}

# -----------------------------------------------------

# check if make is GNU make else use gmake
make_is_gnu:=$(word 1,$(shell make -v))
ifeq ($(make_is_gnu),GNU)
   MAKE:=make
else
   MAKE:=gmake
endif




w=${cwd}/wgrib2

all:	${prog} aux_progs/gmerge aux_progs/smallest_grib2 aux_progs/smallest_4


${prog}:        $w/*.c $w/*.h ${jlib} ${nlib} ${zlib} ${plib} ${h5lib} ${glib} ${n4lib} ${iplib} ${gctpclib}
	cd $w && export LDFLAGS="${wLDFLAGS}" && export CPPFLAGS="${wCPPFLAGS}" && export prog=${prog} && ${MAKE}

fast:        $w/*.c $w/*.h ${jlib} ${nlib} ${zlib} ${plib} ${h5lib} ${glib} ${n4lib} ${iplib} ${gctpclib}
	cd $w && export LDFLAGS="${wLDFLAGS}" && export CPPFLAGS="${wCPPFLAGS}" && ${MAKE}


${jlib}:
	cp $j.tar.gz tmpj.tar.gz
	gunzip -f tmpj.tar.gz
	tar -xvf tmpj.tar
	rm tmpj.tar
	cd $j && export CFLAGS="${wCPPFLAGS}" && ./configure --without-x --disable-libjpeg --disable-opengl && ${MAKE}

${plib}:	${zlib}
	cp $p.tar.gz tmpp.tar.gz
	gunzip -f tmpp.tar.gz
	tar -xvf tmpp.tar
	rm tmpp.tar
#       for OSX
#	export LDFLAGS="-L$z" && cd $p && export CPPFLAGS="${wCPPFLAGS}" && make -f scripts/makefile.darwin
#	for everybody else
	export LDFLAGS="-L$z" && cd $p && export CPPFLAGS="${wCPPFLAGS}" && ./configure --disable-shared && ${MAKE}

${zlib}:
	cp $z.tar.gz tmpz.tar.gz
	gunzip -f tmpz.tar.gz
	tar -xvf tmpz.tar
	rm tmpz.tar
	cd $z && export CFLAGS="${wCPPFLAGS}" && ${MAKE} -f win32/makefile.gcc


${glib}:	${jlib} ${plib} ${zlib}
	touch ${glib}
	rm ${glib}
	cd $g && export CPPFLAGS="${wCPPFLAGS}" && ${MAKE}

${gctpclib}:
	cp gctpc20.tar.gz tmpgctpc.tar.gz
	gunzip -f tmpgctpc.tar.gz
	tar -xvf tmpgctpc.tar
	rm tmpgctpc.tar
	cp makefile.gctpc proj.h ${gctpc}/source/
	cd ${gctpc}/source && export CPPFLAGS="${wCPPFLAGS}" && ${MAKE} -f makefile.gctpc

${nlib}:
	cp netcdf.tar.gz tmpn.tar.gz
	gunzip -f tmpn.tar.gz
	tar -xvf tmpn.tar
	rm tmpn.tar
	cd $n && export CPPFLAGS="${wCPPFLAGS}" && ./configure --enable-c-only && ${MAKE} check

${n4lib}:	${zlib} ${h5lib}
	mkdir -p ${cwd}/zlib/include
	mkdir -p ${cwd}/zlib/lib
	cp ${z}/*.h ${cwd}/zlib/include/
	cp ${z}/*.a ${cwd}/zlib/lib/

	mkdir -p ${cwd}/hdf5/include
	cp  ${h5}/src/*.h ${h5}/hl/src/*.h ${cwd}/hdf5/include
	mkdir -p ${cwd}/hdf5/lib
	cp ${h5}/src/.libs/*a ${h5}/hl/src/.libs/*a ${cwd}/hdf5/lib/

	cp ${n4}.tar.gz tmpn.tar.gz
	gunzip -f tmpn.tar.gz
	tar -xvf tmpn.tar
	rm tmpn.tar
	cd ${n4} && export CPPFLAGS="${wCPPFLAGS}" && ./configure --disable-fortran --disable-cxx --disable-dap --enable-netcdf-4 --with-zlib=${cwd}/zlib --with-hdf5=${cwd}/hdf5 && ${MAKE}

${h5lib}:
	cp ${h5}.tar.gz tmph5.tar.gz
	gunzip -f tmph5.tar.gz
	tar -xvf tmph5.tar
	rm tmph5.tar
	cd ${h5} && export CPPFLAGS="${CPPFLAGS}" && ./configure --disable-shared --disable-fortran --with-zlib=$z && ${MAKE} && ${MAKE}

${iplib}:
	cd ${ip} && export F90=${F90} && export FFLAGS="${wFFLAGS}" && ${MAKE}

aux_progs/gmerge:	aux_progs/gmerge.c		
	cd aux_progs && ${MAKE} -f gmerge.make

aux_progs/smallest_grib2:	aux_progs/smallest_grib2.c
	cd aux_progs && ${MAKE} -f smallest_grib2.make

aux_progs/smallest_4:	aux_progs/smallest_4.c
	cd aux_progs && ${MAKE} -f smallest_4.make

clean:
	cd $w && ${MAKE} clean
	cd $g && touch junk.a junk.o && rm *.o *.a
	cd ${gctpc}/source && ${MAKE} -f makefile.gctpc clean
	rm -rf $n
	rm -rf $j
	rm -rf $p
	rm -rf $z
	rm -rf ${prog}
	cd aux_progs && ${MAKE} clean -f gmerge.make
	cd aux_progs && ${MAKE} clean -f smallest_grib2.make
	cd aux_progs && ${MAKE} clean -f smallest_4.make
	[ -d ${ip} ] && touch ${ip}/junk.o ${ip}/junk.a && rm ${ip}/*.o ${ip}/*.a
	[ -d ${n4} ] && rm -rf ${n4}
	[ -d ${h5} ] && rm -rf ${h6}
