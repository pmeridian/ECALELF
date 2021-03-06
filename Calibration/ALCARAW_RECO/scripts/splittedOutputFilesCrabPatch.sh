#!/bin/bash
#By default the output module split the files exceeding 5GB, but CRAB
#is not able to handle this additional files and to copy them in the
#output directory. For this reason, this script modifies the crab
#scripts in order to copy also the splitted files.

usage(){
    echo "`basename $0` -u crab_workind_dir"
    echo " -u | --ui_working_dir crab_working_dir"
}

if ! options=$(getopt -u -o hu: -l help,ui_working_dir: -- "$@")
then
    # something went wrong, getopt will put out an error message for us
    exit 1
fi

set -- $options

while [ $# -gt 0 ]
do
    case $1 in
	-h|--help) usage; exit 0;;
	-u | --ui_working_dir) UI_WORKING_DIR=$2; shift;;
    (--) shift; break;;
    (-*) echo "$0: error - unrecognized option $1" 1>&2; usage >> /dev/stderr; exit 1;;
    (*) break;;
    esac
    shift
done

if [ -z "${UI_WORKING_DIR}" ]; then
    echo "[ERROR] crab working directory not specified" >> /dev/stderr
    usage >> /dev/stderr
    exit 1
fi


echo "" > tmp/sed.sed
outFiles=`grep  'if \[ -e .*root' ${UI_WORKING_DIR}/job/CMSSW.sh | sed 's|.*-e ./||;s|.root.*|.root|'`
#echo $outFiles
for outFile in $outFiles
  do
  outFile_base=`basename $outFile .root`
  #echo $outFile_base
  outFiles_base="${outFiles_base},${outFile_base}"
done

outFiles_base=`echo $outFiles_base | sed 's|^,|{|;s|$|}|'`
#echo $outFiles_base
for outFile in $outFiles
  do
  outFile_base=`basename $outFile .root`
  cat >> tmp/sed.sed <<EOF
\#if \[ -e ./$outFile#,+8 d
/# check output file/ a outFile_base=${outFile_base}
/# check output file/ a for file in ${outFile_base}*.root; do\n  if [ -e "\$file" ] ; then\n    newFile=\`basename \$file .root\`_\$OutUniqueID.root;\n    mv \$file \$newFile;\n    ln -s \`pwd\`/\$newFile \$RUNTIME_AREA/\`basename \$file\`;\n else\n    job_exit_code=60302;\n    echo "WARNING: Output file \$file not found";\n  fi;\ndone;\nfile_list=""\nfor file in \$SOFTWARE_DIR/\${outFiles_base}*\$OutUniqueID.root;  do  file_list="\$file_list,\$file";done;file_list=\`echo \$file_list\| sed 's\|,\|\|'\`\n echo \${file_list}
EOF
done

#grep  -B1 'if \[ -e .*root'  | 

sed -i -f tmp/sed.sed ${UI_WORKING_DIR}/job/CMSSW.sh

#grep -v -A6 'if \[ -e .*root'  ${UI_WORKING_DIR}/job/CMSSW.sh > tmp/CMSSW.sh
