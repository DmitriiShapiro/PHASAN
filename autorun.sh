#!/bin/bash

# executable file
#phits_exe=./LinIfort
phits_sh=${PHITSPATH}/bin/phits.sh

# input file name (D:autorun.inp)
inpfile=${1:-autorun.inp}

# set default parameters
phitsinput=${phitsinput: -phits.inp}
tallyfolder=${tallyfolder:-outfiles}
manatally=${manatally:-1}
ncycle=${ncycle:-1}


# read input (D:analysis.inp)
declare line   # used lower character
rdflg=0           # read data flag (c-type=1)
unset ncp         # Total product of nc
unset rdata

while read line || [ -n "${line}" ] ; do

   if [ `echo -n ${line} | wc -m` -gt 0 ] ; then
       line=$(echo ${line%%\$*})
      array=$(echo ${line%%=*})
      arrayset=$(echo ${line%%:*})

      if [ "$array" = "file" ] ; then
         if [ $rdflg -eq 1 ] ; then  exit 1 ; fi
         phitsinput=$(echo ${line##*=})
         pfn=$(echo ${phitsinput%.*})
         ext=$(echo ${phitsinput##*.})

      elif [ "$array" = "tallyfolder" ] ; then
         if [ $rdflg -eq 1 ] ; then  exit 1 ; fi
         # tallyfolder=$(echo ${line##*=})

      elif [ "$array" = "manatally" ] ; then
         if [ $rdflg -eq 1 ] ; then  exit 1 ; fi
         manatally=$(echo ${line##*=})

      elif [ "$array" = "ncycle" ] ; then
         if [ $rdflg -eq 1 ] ; then  exit 1 ; fi
         ncycle=$(echo ${line##*=})

      elif [ "$array" = "irestart" ] ; then
         if [ $rdflg -eq 1 ] ; then  exit 1 ; fi
         irestart=$(echo ${line##*=})

      elif [ "$arrayset" = "set" ] ; then
         if [ $rdflg -eq 1 ] ; then  exit 1 ; fi
         varc=$(echo ${line##*:})
         cnum=${varc##*c}

      elif [ "$array" = "c-type" ] ; then
         if [ $rdflg -eq 1 ] ; then  exit 1 ; fi
         ctype[$cnum]=$(echo ${line##*=})

      # cmin
      elif [ "$array" = "cmin" ] ; then
         if [ $rdflg -eq 1 ] ; then  exit 1 ; fi
         if [ ${ctype[$cnum]} -eq 1 ] ; then  exit 1 ; fi
         cmin[$cnum]=$(echo ${line##*=})

      # cmax
      elif [ "$array" = "cmax" ] ; then
         if [ $rdflg -eq 1 ] ; then  exit 1 ; fi
         if [ ${ctype[$cnum]} -eq 1 ] ; then  exit 1 ; fi
         cmax[$cnum]=$(echo ${line##*=})

      # nc
      elif [ "$array" = "nc" ] ; then
         if [ $rdflg -eq 1 ] ; then  exit 1 ; fi

         # c-type = 1, nc
         if [ ${ctype[$cnum]} -eq 1 ] ; then
            nc[$cnum]=$(echo ${line##*=})
          # nc[$cnum]=$(echo ${line##*=} + 1)
          # ncp=$(( ${ncp:-1} * nc[$cnum] ))
            rdflg=1

         # c-type = 2 or 3, nc
         elif [ ${ctype[$cnum]} -eq 2 -o ${ctype[$cnum]} -eq 3 ] ; then
            nc[$cnum]=$(echo ${line##*=})
          # ncp=$(( ${ncp:-1} * nc[$cnum] ))
            rdflg=0

         # c-type = 4 or 5
         elif [ ${ctype[$cnum]} -eq 4 -o ${ctype[$cnum]} -eq 5 ] ; then
            exit 1
         fi

      # cdel
      elif [ "$array" = "cdel" ] ; then
         if [ $rdflg -eq 1 ] ; then  exit 1 ; fi

         # c-type = 4
         if [ ${ctype[$cnum]} -eq 4 ] ; then
            cdel[$cnum]=$(echo ${line##*=})

         # c-type = 5
         elif [ ${ctype[$cnum]} -eq 5 ] ; then
            cdel[$cnum]=$(echo ${line##*=*log*(})
            cdel[$cnum]=$(echo ${cdel[$cnum]%%)*})
         elif [ ${ctype[$cnum]} -eq 1 -o ${ctype[$cnum]} -eq 2 -o ${ctype[$cnum]} -eq 3 ] ; then
            exit 1
         fi

      # [end]
      elif [ "${line:0:1}" = "[" ] ; then
         if [ $rdflg -eq 1 ] ; then  exit 1 ; fi
         break

      # data n
      elif [ ${ctype[$cnum]} -eq 1 -a $rdflg -eq 1 ] ; then
         rdata+=(${line})
         if [ ${#rdata[@]} -ge ${nc[$cnum]} ] ; then
            ncdata[$cnum]=${rdata[@]}             # Copy as scalar variable
            rdflg=0
            unset rdata
         fi
      fi

   fi
done < ${inpfile}


# set condition of variable parameter
unset cifa
unset ca
for i in ${!ctype[@]} ; do
   unset rdata

   # c-type = 1
   if [ ${ctype[$i]} -eq 1 ] ; then
      rdata=(${ncdata[$i]})
      cmin[$i]=${rdata[0]}
      cmax[$i]=${rdata[${nc[$i]}-1]}
      
   # c-type = 2
   elif [ ${ctype[$i]} -eq 2 ] ; then
      cdel[$i]=`echo "(${cmax[$i]}-(${cmin[$i]})) / (${nc[$i]}-1)" | bc`
      
   # c-type = 3
   elif [ ${ctype[$i]} -eq 3 ] ; then
      cdel[$i]=`echo "l(${cmax[$i]}/${cmin[$i]}) / ${nc[$i]}" | bc -l`
   
   # c-type = 4
   elif [ ${ctype[$i]} -eq 4 ] ; then
      nc[$i]=`echo "scale=0;(${cmax[$i]}-(${cmin[$i]})) / ${cdel[$i]}" | bc`
      nc[$i]=$(( ${nc[$i]}+1 ))
   
   # c-type = 5
   elif [ ${ctype[$i]} -eq 5 ] ; then
    # nc[$i]=`echo "scale=0;l(${cmax[$i]}/${cmin[$i]}) / l(${cdel[$i]})" | bc -l`
      nc[$i]=`echo "l(${cmax[$i]}/${cmin[$i]}) / l(${cdel[$i]})" | bc -l`
      nc[$i]=$(( ${nc[$i]%%.*} + 1 ))          # int( ans ) + 1
   
   # c-type = 6 random value
   elif [ ${ctype[$i]} -eq 6 ] ; then
      :                               # NOP command
   fi
   
   ca[$i]="${ncp:-1}"                          # product at each "ci"
   ncp=$(( ${ncp:-1} * ${nc[$i]} ))            # total product of "ci"
   (( ${cifa:=$i} ))                           # first ci address
   
done

# check ncp
if [ "${ncp:-UNDEF}" = "UNDEF" ] ; then
   echo total nc is smaller than 1
   exit 1
elif [ ${ncp} -lt 1 ] ; then
   echo total nc is smaller than 1
   exit 1
fi

# ............... write anatally parameter file (nc_info.inp) ...............
#rm -f nc_info.inp

echo ${#ctype[@]} > nc_info.inp                # number of Cn

#unset ncc
#ncc=$(printf "nc=%6d" "${ncp}")
#for i in ${!ctype[@]} ; do                     # loop of ci
#   ncc+=$(printf ", ")
#   ncc+=$(printf "nc%d=%6d" "${i}${nc[$i]}")
#done
#echo $ncc >> nc_info.inp                       # nc=xxx, nc1=xx,.... nc9=x

for i in ${!ctype[@]} ; do                     # loop of ci
   
   echo set:c${i} >> nc_info.inp
   echo c-type = ${ctype[$i]} >> nc_info.inp
   
   # c-type = 1
   if [ ${ctype[$i]} -eq 1 ] ; then
      echo nc = ${nc[$i]} >> nc_info.inp
      
      unset rdata
      rdata=(${ncdata[$i]})
      for (( j=0; j<${nc[$i]}; j++ )) do
         echo ${rdata[$j]} >> nc_info.inp
      done
   
   # c-type = 2
   elif [ ${ctype[$i]} -eq 2 ] ; then
      echo nc = ${nc[$i]} >> nc_info.inp
      echo cmin = ${cmin[$i]} >> nc_info.inp
      echo cmax = ${cmax[$i]} >> nc_info.inp
   
   # c-type = 3
   elif [ ${ctype[$i]} -eq 3 ] ; then
      echo nc = ${nc[$i]} >> nc_info.inp
      echo cmin = ${cmin[$i]} >> nc_info.inp
      echo cmax = ${cmax[$i]} >> nc_info.inp
   
   # c-type = 4
   elif [ ${ctype[$i]} -eq 4 ] ; then
      echo cdel = ${cdel[$i]} >> nc_info.inp
      echo cmin = ${cmin[$i]} >> nc_info.inp
      echo cmax = ${cmin[$i]} >> nc_info.inp
   
   # c-type = 5
   elif [ ${ctype[$i]} -eq 5 ] ; then
      echo cdel = "log(${cdel[$i]})" >> nc_info.inp
      echo cmin = ${cmin[$i]} >> nc_info.inp
      echo cmax = ${cmin[$i]} >> nc_info.inp
   
   # c-type = 6 random value
   elif [ ${ctype[$i]} -eq 6 ] ; then
      :                               # NOP command
   fi
   
done


# remove line feed
phitsinput=`echo ${phitsinput} | sed -e "s/[\r\n]\+//g"`
tallyfolder=`echo ${tallyfolder} | sed -e "s/[\r\n]\+//g"`


# ****************************************************************************************
# Pre-analysis (icntl=16 : phits.inp)
# make temporally phits input file
# (icntl=0  : phits_tmp.inp file)
# (icntl=17 : anatally.inp file)
#rm -f phits_tmp.inp
#rm -f anatally.inp


# ./$phits_exe < ${phitsinput} >> message.out
# $phits_sh ${phitsinput} >> message.out
# rm -f message.out
$phits_sh ${phitsinput}


# ****************************************************************************************


# read folder & file info ( serch anatally sub-section in anatally.inp )
cflag=0
nfolder=0
nsfile=0
nanatally=0
while read line ; do
   if [ "${line:0:1}" = "[" -a $cflag -gt 0 ] ; then   # next section
      cflag=0
      break
   
   elif [ ${cflag} -eq 4 ] ; then
      if [ "${line:0:12}" = "anatally end" ] ; then
         cflag=1
      
      else
         #tallyfolder=$(echo ${line%%/*})             # tallyout
         folder[$nfolder]=$(echo ${line%/*})          # tallyout/foldercout
         fname=$(echo ${line##*/})
         outname[$nfolder]=$(echo ${fname%.*})
         extname[$nfolder]=$(echo ${fname##*.})
         (( ++nfolder ))
      fi
   
   # elif [ ${cflag} -eq 0 ] ; then
   #    if [ "${line:0:19}" = "[ a n a t a l l y ]" ] ; then
   #         cflag=1
   #    fi
   # elif [ ${cflag} -eq 1 ] ; then
   elif [ ${cflag} -le 1 ] ; then
      if [ "${line:0:14}" = "anatally start" ] ; then
         cflag=2
         (( ++nanatally ))                           # count of anatally sub section(tally section)
      fi
   elif [ ${cflag} -eq 2 ] ; then
      array=$(echo ${line%%=*})
      if [ "$array" = "sfile" ] ; then
       # wsfile=$(echo ${line##*=})
         wsfile[$nsfile]=$(echo ${line##*=})
         (( ++nsfile ))                              # count of anatally plot files(sfiles)
         cflag=3
      fi
   elif [ ${cflag} -eq 3 ] ; then
      array=$(echo ${line%%=*})
      if [ "$array" = "nfile" ] ; then
         wnfile=$(echo ${line##*=})
         cflag=4
      fi
   fi
done < anatally_tmp.inp


if [ $nanatally -gt 0 ] ; then
   :                               # NOP command

# no-anatally sub section
else
   nfolder=$ncp
   #ncp=$nfolder
   for i in `seq ${nfolder}` ; do
      if [ ${ncp} -ge 100000 ] ; then
         foldercount=$(printf "%06d" "${i}")
      elif [ ${ncp} -ge 10000 ] ; then
         foldercount=$(printf "%05d" "${i}")
      elif [ ${ncp} -ge 1000 ] ; then
         foldercount=$(printf "%04d" "${i}")
      elif [ ${ncp} -ge 100 ] ; then
         foldercount=$(printf "%03d" "${i}")
      elif [ ${ncp} -ge 10 ] ; then
         foldercount=$(printf "%02d" "${i}")
      else
         foldercount=$(printf "%01d" "${i}")
      fi
      folder[$i-1]=${tallyfolder}/${foldercount}
      #echo folder=${folder[$i]}
   done
fi


# make directory to store outpot files
mkdir -p $tallyfolder


# ============================ start of loop of analysis =================================
i_cycle=1
#echo "loop analysis : $i_cycle $ncycle"
while [ $i_cycle -le $ncycle ] ; do
   echo "Autorun loop count $i_cycle"
   #echo "$(( $ncycle - $i_cycle ))" > batch_a.out
   if [ $i_cycle -eq 1 ] ; then
      echo $ncycle > batch_a.out
   fi


# ------------------------ start of loop of variable parameter ---------------------------
# Initialize of each ci variable counter
   for i in ${!ctype[@]} ; do
      if [ $i -gt $cifa ] ; then
         ci[$i]=1
      else
         ci[$i]=0
      fi
   done

# start of loop of variable parameter
   counter=1
   #echo "loop param : $counter $ncp"
   while [ $counter -le $ncp ] ; do
      echo "Calculating with condition $counter"


# set each ci variable counter
      unset foldercount
      cf=0                       # reset carry flag
      for i in ${!ctype[@]} ; do
         if [ $i -eq $cifa ] ; then
            (( ci[$i]++ ))       # variable parameter loop count up
         elif [ $cf -eq 1 ] ; then
            (( ci[$i]++ ))       # variable parameter loop count up
         fi
         
         cf=0                    # reset carry flag
         if [ ${ci[$i]} -gt ${nc[$i]} ] ; then
            ci[$i]=1             # address reset
            cf=1                 # set carry flag
         fi
         
# make varfile.inp
# write each ci value to varfile.inp file.
#         # c-type = 1
#         if [ ${ctype[$i]} -eq 1 ] ; then
#            rdata=(${ncdata[$i]})
#            val=${rdata[${ci[$i]}-1]}
#         
#         # c-type = 2
#         elif [ ${ctype[$i]} -eq 2 ] ; then
#            val=`echo "${cdel[$i]} * (${ci[$i]}-1) + ${cmin[$i]}" | bc`
#         
#         # c-type = 3
#         elif [ ${ctype[$i]} -eq 3 ] ; then
#            val=`echo "${cdel[$i]} * (${ci[$i]}-1) + l(${cmin[$i]})" | bc -l`
#         
#         # c-type = 4
#         elif [ ${ctype[$i]} -eq 4 ] ; then
#            val=`echo "${cdel[$i]} * (${ci[$i]}-1) + ${cmin[$i]}" | bc`
#         
#         # c-type = 5
#         elif [ ${ctype[$i]} -eq 5 ] ; then
#            val=`echo "l(${cdel[$i]}) * (${ci[$i]}-1) + l(${cmin[$i]})" | bc -l`
#         
#         # c-type = 6 random value
#         elif [ ${ctype[$i]} -eq 6 ] ; then
#            :                               # NOP command
#         fi
         
         if [ $i -gt $cifa ] ; then
            #echo set: c$i[$val] >> varfile.inp               # additional line in "varfile.inp" file
            #echo $val >> cvalue.out
            chksum=$(( $chksum + (${ca[$i]}*(${ci[$i]}-1)) )) # total product up to "ci"
         elif [ $i -eq $cifa ] ; then
            #echo set: c$i[$val] > varfile.inp                # first line of "varfile.inp" file
            #echo $val > cvalue.out
            chksum=${ci[$i]}                                 # total product up to the first "ci"
         fi

# make directory to store output files of each condition
#         if [ -z "${foldercount+UNDEF}" ] ; then
#            :                             # NOP command
#         else
#            foldercount+="_"
#         fi
#         
#         if [ ${nc[$i]} -ge 100000 ] ; then
#            foldercount+=$(printf "%06d" "${ci[$i]}")
#         elif [ ${nc[$i]} -ge 10000 ] ; then
#            foldercount+=$(printf "%05d" "${ci[$i]}")
#         elif [ ${nc[$i]} -ge 1000 ] ; then
#            foldercount+=$(printf "%04d" "${ci[$i]}")
#         elif [ ${nc[$i]} -ge 100 ] ; then
#            foldercount+=$(printf "%03d" "${ci[$i]}")
#         elif [ ${nc[$i]} -ge 10 ] ; then
#            foldercount+=$(printf "%02d" "${ci[$i]}")
#         else
#            foldercount+=$(printf "%01d" "${ci[$i]}")
#         fi
         
      done
      # check the product of Ci value and parameters loop counter value
      #echo "check counter : $chksum $counter"
      if [ $chksum -ne $counter ] ; then
         echo mismatch chksum=$chksum, counter=$counter
         exit 2 
      fi

      if [ ${ncp} -ge 100000 ] ; then
         foldercount=$(printf "%06d" "${counter}")
      elif [ ${ncp} -ge 10000 ] ; then
         foldercount=$(printf "%05d" "${counter}")
      elif [ ${ncp} -ge 1000 ] ; then
         foldercount=$(printf "%04d" "${counter}")
      elif [ ${ncp} -ge 100 ] ; then
         foldercount=$(printf "%03d" "${counter}")
      elif [ ${ncp} -ge 10 ] ; then
         foldercount=$(printf "%02d" "${counter}")
      else
         foldercount=$(printf "%01d" "${counter}")
      fi

# make directory to store output files of each condition
      if [ $i_cycle -eq 1 ] ; then
#         foldercount+=$(printf "\n")
         mkdir -p ${tallyfolder}/${foldercount}


# copy previous result file to current folder
      elif [ $i_cycle -gt 1 ] ; then
         for(( i=0; i<${nfolder}; i++ )) ; do
            if [ "${tallyfolder}/${foldercount}" = "${folder[$i]}" ] ; then
               if [ -e "${folder[$i]}/${outname[$i]}.${extname[$i]}" ] ; then
                  cp -f ${folder[$i]}/${outname[$i]}.${extname[$i]}  ${outname[$i]}.${extname[$i]}
               fi
               if [ -e "${folder[$i]}/${outname[$i]}_err.${extname[$i]}" ] ; then
                  cp -f ${folder[$i]}/${outname[$i]}_err.${extname[$i]} ${outname[$i]}_err.${extname[$i]}
               fi
            fi
         done
      fi


# rename set:Ci[**] files ( varlist??.inp ---> varfile.inp )
      if [ -e "varfile_${foldercount}.inp" ] ; then
         cp -f varfile_${foldercount}.inp varfile.inp
      else
         echo not found varfile_${foldercount}.inp
         exit 3
      fi


# ****************************************************************************************
# perform parameter analysis (icntl=0 : phits_tmp.inp file)


      # ./$phits_exe < phits_tmp.inp >> message.out
      # $phits_sh phits_tmp.inp >> message.out
      # rm -f message.out
      $phits_sh phits_tmp.inp


# ****************************************************************************************


# move result files to tallyout folder ( *.out, *_err.out, *.eps )
      for(( i=0; i<${nfolder}; i++ )) ; do
         if [ "${tallyfolder}/${foldercount}" = "${folder[$i]}" ] ; then
            #if [ -e "${outname[$i]}.${extname[$i]}" ] ; then
            #   mv -f ${outname[$i]}.${extname[$i]} ${folder[$i]}/${outname[$i]}.${extname[$i]}
            #fi
            #if [ -e "${outname[$i]}_err.${extname[$i]}" ] ; then
            #   mv -f ${outname[$i]}_err.${extname[$i]} ${folder[$i]}/${outname[$i]}_err.${extname[$i]}
            #fi
            #if [ -e "${outname[$i]}.eps" ] ; then
            #   mv -f ${outname[$i]}.eps ${folder[$i]}/${outname[$i]}.eps
            #fi
            #if [ -e "${outname[$i]}_err.eps" ] ; then
            #   mv -f ${outname[$i]}_err.eps ${folder[$i]}/${outname[$i]}_err.eps
            #fi
            mv -f *.out ${folder[$i]}/.
            mv -f *.eps ${folder[$i]}/.

            mv -f ${folder[$i]}/batch_a.out batch_a.out
            break
         fi
      done

# move input files and other output files
      for(( i=0; i<${nfolder}; i++ )) ; do
         if [ "${tallyfolder}/${foldercount}" = "${folder[$i]}" ] ; then
            if [ -e "phits_tmp.inp" ] ; then
               cp -f phits_tmp.inp ${folder[$i]}/phits.inp
            fi
            if [ -e "varfile.inp" ] ; then
               mv -f varfile.inp ${folder[$i]}/varfile.inp
            fi
            if [ -e "phits.out" ] ; then
               mv -f phits.out ${folder[$i]}/phits.out
            fi
            if [ -e "batch.out" ] ; then
               mv -f batch.out ${folder[$i]}/batch.out
            fi
            break
         fi
      done


      (( counter++ ))               # variable parameter loop count up
   done
# ------------------------- end of loop of variable parameter ----------------------------


# ****************************************************************************************
# check the result of one cycle (icntl=17 : anatally.inp)

   if [ $nanatally -gt 0 ] ; then
   
# ./$phits_exe < anatally.inp >> message.out
# $phits_sh anatally.inp >> message.out
# rm -f message.out
      $phits_sh anatally.inp

   elif [ $nanatally -eq 0 ] ; then
      if [ -e anatally.inp ] ; then
         rm -f anatally.inp
      fi
   fi

# ****************************************************************************************


# analysis loop counter check ( external loop variable )
   read line < batch_a.out
   if [ ${line} -gt 0 ] ; then
      (( i_cycle++ ))               # analysis loop count up
   else
      break
   fi


done
# ============================== end of loop of analysis =================================

# cleanup current directory
rm -f phits_tmp.inp
rm -f anatally_tmp.inp
rm -f nc_info.inp
rm -f varfile*.inp
rm -f batch_a.out

# making eps files.
# echo $wsfile
for(( i=0; i<${nsfile}; i++ )) ; do
   if [ -e ${wsfile[$i]} ] ; then
      ${PHITSPATH}/bin/angel.sh ${wsfile[$i]}
   fi
done


exit 0
