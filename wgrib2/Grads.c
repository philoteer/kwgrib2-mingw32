#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "grb2.h"
#include "wgrib2.h"
#include "fnlist.h"
#define RINT(x)         ((int) (floor((x) + 0.5)))

/*
 * here are options that are used g2ctl
 * (making GrADS control files for grib2 files
 *
 * this file can be deleted if not needed
 *
 *   This file is in the public domain  2007 Wesley Ebisuzaki
 * 1/2008 Sergey Varlamov double precision, bug fix
 * 1/2008 f_domain added
 * 11/2009 f_domain fixed E-W calculation
 */

//extern enum input_type input;
//extern int header, dump_rec, dump_submsg;
extern int mode, decode, latlon, ndata;
extern enum output_order_type output_order;

extern double *lat, *lon;

//extern int file_append;


/*
 * HEADER:-1:ctl_inv:inv:0:ctl inventory dump for g2ctl/GrADS
 */
int f_ctl_inv(ARG0) {

    char name[STRING_SIZE], desc[STRING_SIZE], unit[STRING_SIZE];
    float val1, val2;
    int level_type1, level_type2;
    int undef_val1, undef_val2, i;
    int stat_proc, interpolation;
    const char *string;

    if (mode == -1) return 0;
    if (mode == -2) return 0;

    if (getName(sec, mode, NULL, name, desc, unit) != 0) {
        return -1;
    }

    level_type1 = sec[4][22];
    undef_val1 = undef_val2 = 1;
    val1 = val2 = -999;

    if (sec[4][23] != 255 || sec[4][24] != 255 || sec[4][25] != 255 || sec[4][26] != 255 ||
                sec[4][27] != 255) {
        undef_val1 = 0;
        val1 = scaled2flt(INT1(sec[4][23]), int4(sec[4] + 24));
    }

    level_type2 = sec[4][28];
    if (sec[4][29] != 255 || sec[4][30] != 255 || sec[4][31] != 255 || sec[4][32] != 255 ||
         sec[4][33] != 255) {
        undef_val2 = 0;
        val2 = scaled2flt(INT1(sec[4][29]), int4(sec[4] + 30));
    }

    sprintf(inv_out,"%s %d", name,code_table_4_5a(sec));
    inv_out += strlen(inv_out);

    /* i is number of fields to print */    
    i = 3;
    if (level_type2 == 255) i = 1;
    if (level_type1 == level_type2) i = 2;
    if (i == 2 && undef_val2 == 1) i = 1;
    if (i == 1 && undef_val1 == 1) i = 0;

    if (i >= 1) {
        if (undef_val1) sprintf(inv_out,",");
        else if (val1 == (int) val1)  sprintf(inv_out,",%d", (int) val1);
        else sprintf(inv_out,",%g", val1);
        inv_out += strlen(inv_out);
    }
    if (i >= 2) {
        if (undef_val2) sprintf(inv_out,",");
        else if (val2 == (int) val2)  sprintf(inv_out,",%d", (int) val2);
        else sprintf(inv_out,",%g", val2);
        inv_out += strlen(inv_out);
    }
    if (i >= 3) {
        sprintf(inv_out,",%d", level_type2);
        inv_out += strlen(inv_out);
    }

    sprintf(inv_out," %d,%d,%d", GB2_Discipline(sec), GB2_ParmCat(sec), GB2_ParmNum(sec));
    inv_out += strlen(inv_out);

    /* statistical processing */
    string = NULL;
    stat_proc = code_table_4_10(sec);
    if (stat_proc != -1 && stat_proc != 255) {
        sprintf(inv_out,",%d", stat_proc);
        inv_out += strlen(inv_out);
    }

    // note will have to modify code when grads units is extended
    interpolation = code_table_4_15(sec);
    if (interpolation != -1 && interpolation != 255) {
        sprintf(inv_out,",%d", interpolation);
        inv_out += strlen(inv_out);
    }

    /* add stat processing term to description */
    if (stat_proc != -1) {
        string = NULL;
        switch(stat_proc) {
#include "CodeTable_4.10.dat"
        }
    }

    /* add prob process term to description */

    if (string == NULL) sprintf(inv_out," %s %s [%s]", "none", desc, unit);
    else sprintf(inv_out," %s %s [%s]", string, desc, unit);
    inv_out += strlen(inv_out);

    /* add interpolation term to description */
    if (interpolation != -1 && interpolation != 255) {
       sprintf(inv_out," table 4.15=%d", interpolation);
    }

    return 0;
}

/*
 * HEADER:-1:lev0:inv:0:level for g2ctl/GrADS
 */
int f_lev0(ARG0) {
    int center;
    int level_type1, level_type2;
    int undef_val1, undef_val2;
    float val1, val2;
    char *p;

    if (mode < 0) return 0;
    center = GB2_Center(sec);

    inv_out[0] = 0;

    fixed_surfaces(sec, &level_type1, &val1, &undef_val1, &level_type2, &val2, 
        &undef_val2);

    if (level_type2 == 255) {
        if (center == 7 && level_type1 >= 192 && level_type1 <= 254) {
           switch(level_type1) {
           case 200: strcpy(inv_out,"clm"); return 0;
           case 201: strcpy(inv_out,"ocn"); return 0;
           case 204: strcpy(inv_out,"top0C"); return 0;
           case 206: strcpy(inv_out,"gclb"); return 0;
           case 207: strcpy(inv_out,"gclt"); return 0;
           case 209: strcpy(inv_out,"blclb"); return 0;
           case 210: strcpy(inv_out,"blclt"); return 0;
           case 211: strcpy(inv_out,"blcll"); return 0;
           case 212: strcpy(inv_out,"lclb"); return 0;
           case 213: strcpy(inv_out,"lclt"); return 0;
           case 214: strcpy(inv_out,"lcll"); return 0;
           case 215: strcpy(inv_out,"ceil"); return 0;
           case 220: strcpy(inv_out,"pbl"); return 0;
	   case 221: sprintf(inv_out,"hl%d_%d", (int) val1, (int) val2); return 0;
           case 222: strcpy(inv_out,"mclb"); return 0;
           case 223: strcpy(inv_out,"mclt"); return 0;
           case 224: strcpy(inv_out,"mcll"); return 0;
           case 232: strcpy(inv_out,"hclb"); return 0;
           case 233: strcpy(inv_out,"hclt"); return 0;
           case 234: strcpy(inv_out,"hcll"); return 0;
           case 235: sprintf(inv_out,"ocn%gC",val1/10);
		     for (p = inv_out; *p; p++) { if (*p == '.') *p = 'p'; }
		     return 0;
           case 237: sprintf(inv_out,"ocnml"); return 0;
           case 238: sprintf(inv_out,"ocnil"); return 0;
           case 239: sprintf(inv_out,"sfc_26C"); return 0;
           case 240: sprintf(inv_out,"oml"); return 0;
           case 241: if (val1 > 0) sprintf(inv_out,"_%d",(int) val1);
                     else sprintf(inv_out,"_neg%d",(int) -val1);
		     return 0;
           case 242: strcpy(inv_out,"cclb"); return 0;
           case 243: strcpy(inv_out,"cclt"); return 0;
           case 244: strcpy(inv_out,"ccll"); return 0;
           case 245: strcpy(inv_out,"lwb0"); return 0;
           case 246: strcpy(inv_out,"mept"); return 0;
           case 247: strcpy(inv_out,"eql"); return 0;
           case 248: strcpy(inv_out,"scclb"); return 0;
           case 249: strcpy(inv_out,"scclt"); return 0;
           case 251: strcpy(inv_out,"dcclb"); return 0;
           case 252: strcpy(inv_out,"dcclt"); return 0;
           case 253: strcpy(inv_out,"lblsw"); return 0;
           case 254: strcpy(inv_out,"htlsw"); return 0;
           }
        }

       switch(level_type1) {
       case 1: strcpy(inv_out,"sfc"); break;
       case 2: strcpy(inv_out,"clb"); break;
       case 3: strcpy(inv_out,"clt"); break;
       case 4: strcpy(inv_out,"0C"); break;
       case 6: strcpy(inv_out,"mwl"); break;
       case 7: strcpy(inv_out,"trop"); break;
       case 8: strcpy(inv_out,"toa"); break;
       case 9: strcpy(inv_out,"ocnb"); break;
       case 10: strcpy(inv_out,"clm"); break;
       case 11: strcpy(inv_out,"cbb"); break;
       case 12: strcpy(inv_out,"cbt"); break;
       case 20: sprintf(inv_out,"%d_K",RINT(val1)); break;		// temperature
       case 100: sprintf(inv_out,"%dmb",RINT(val1/100)); break;
       case 101: strcpy(inv_out,"msl"); break;
       case 102: sprintf(inv_out,"_%dm",RINT(val1)); break;		// m above MSL
       case 103: sprintf(inv_out,"%dm",RINT(val1)); break;		// m above ground
       case 104: sprintf(inv_out,"sig%d",RINT(1000*val1)); break;
       case 105: sprintf(inv_out,"hy%d",RINT(val1)); break;
       case 106: sprintf(inv_out,"%dcm",RINT(100*val1)); break;	// m underground
       case 107: sprintf(inv_out,"%dK",RINT(val1)); break;		// potential temperature
       case 109: // potential vorticity
		 if (val1 < 0) {
		    sprintf(inv_out,"neg");
		    inv_out += strlen(inv_out);
		    val1 = -val1;
		 }
		 sprintf(inv_out,"%lgpv",val1*1e6);
		 // change decimal point to 'p'
		 while (*inv_out) {
		     if(*inv_out == '.') *inv_out = 'p';
		     inv_out++;
		 }
                 break;
       case 160: sprintf(inv_out,"bsl%dm",RINT(val1)); break;
       case 161: sprintf(inv_out,"bwl%dm",RINT(val1)); break;
       case 255: break;				// no level information
       default: sprintf(inv_out,"l%d",level_type1); break;
       }
       return 0;
    }
    if (level_type1 == level_type2 && center == 7) {
        switch(level_type1) {
	case 236: sprintf(inv_out,"ocn%d_%dm",RINT(val1),RINT(val2)); return 0;
        }
    }
    if (level_type1 == level_type2) {
        switch(level_type1) {
        case 2: sprintf(inv_out,"%d_%d_K",RINT(val1),RINT(val2)); break;		// temp
        case 102: sprintf(inv_out,"_%d_%dm",RINT(val1),RINT(val2)); break;		// above MSL
        case 103: sprintf(inv_out,"%d_%dm",RINT(val1),RINT(val2)); break;		// above ground
        case 104: sprintf(inv_out,"sg%d_%d",RINT(1000*val1),RINT(1000*val2)); break;
	case 105: if ((val1 - val2) >= 0.9999 && (val1 - val2) <= 1.0001) {
		    sprintf(inv_out,"hy%dp5", (int) val1); break;	// 1 layer   .. hy10.5
		}
		sprintf(inv_out,"hy%d_%d", (int) val1, (int) val2); break; // multiple layers hy10_20
        case 106: sprintf(inv_out, "%d_%dcm",RINT(100*val1),RINT(100*val2)); break;
        case 107: sprintf(inv_out,"%d_%dK",RINT(val1),RINT(val2)); break;		// pot temp
        case 108: sprintf(inv_out, "%d_%dmb",RINT(val1/100),RINT(val2/100)); break;
        default: sprintf(inv_out,"l%d_%d",level_type1,level_type2); break;
        }
        return 0;
    }
    if (level_type1 != level_type2) {
	if (level_type1 == 1 && level_type2 == 8) {
	    sprintf(inv_out,"clm"); return 0;
	}
        return 0;
    }

   return 0;
}

/*
 * HEADER:100:domain:inv:0:find rectangular domain for g2ctl/GrADS plots
 */
int f_domain(ARG0) {
    double n,s,e,w,last,current,offset;
    unsigned int i;

    if (mode == -1) {
	decode = latlon = 1;
	return 0;
    }
    if (mode < -1) return 0;

    if (output_order != wesn) fatal_error("-domain requires WESN order","");
    if (lat == NULL || lon == NULL) return -1;

    // find the n and s extrema

    n = s = 999.0;
    for (i = 1; i < ndata; i++) {
	if (lat[i] < 999.0 && lon[i] < 999.0) {
            if (n >= 999.0) {
		s = n = lat[i];
	    }
	    else {
	        n = n >= lat[i] ? n : lat[i];
	        s = s <= lat[i] ? s : lat[i];
	    }
	}
    }

    // find the e and w extrema
    // more difficult because of the 0/360 split

    last = e = w = 999.0;
    offset = 0.0;
    for (i = 1; i < ndata; i++) {
	if (lat[i] >= 999.0 && lon[i] >= 999.0) continue;
	if (w >= 999.0) {
	    last = e = w = lon[i];
	    offset = 0.0;
	    continue;
	}

	current = lon[i] + offset;
        if (last > 270.0 && current < 90.0) {
	    current += 360.0;
	    offset += 360.0;
	}

       if ( (current - last) > 120.0) { // start of new row
// printf("endo of y %d  x %d current %f last %f lon[i] %f e %f\n",i/349,i % 349, current , last, lon[i],e) ;
	    if (last < e) e = last;
            last = lon[i];
	    offset = 0.0;
	    if (last < w) w = last;
	    continue;
        }
	else {
	    if (current > e) e = current;
	    if (current < w) w = current;
	    last = current;
	}

	if (e - w > 360.0) {
// printf(">>2 e %f w %f current %f i %d\n", e, w, current,i);
	    // global
	    e = 180.0;
	    w = -180.0;
            break;
	}
    }

    if (e > 360.0) {
	e -= 360.0;
	w -= 360.0;
    }
    if (w > 180.0) {
	e -= 360.0;
	w -= 360.0;
    }

    sprintf(inv_out,"N=%lf S=%lf W=%lf E=%lf",n,s,w,e);
    return 0;
}


/*
 * HEADER:-1:ctl_ens:inv:0:ens info for g2ctl/GrADS
 */

int f_ctl_ens(ARG0) {
    int pdt, typefcst, type, n;
    if (mode >= 0) {
        pdt = code_table_4_0(sec);
        typefcst = code_table_4_7(sec);
        if (pdt == 1 || pdt == 11) {
            type = code_table_4_6(sec);
            n = sec[4][35];
	    sprintf(inv_out,"ens=%d,%d", type, n);
	}
	else if (pdt == 2  || pdt == 12) {
	    sprintf(inv_out,"ens=%d", typefcst);
	}
    }
    return 0;
}
