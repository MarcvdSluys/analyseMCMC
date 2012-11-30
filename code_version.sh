#!/bin/sh

##  code_version.sh:
##  Write the git hash or release-version number of the code and the compiler name to a Fortran source file
##  24/07/2010, AF: initial version for AnalyseMCMC, svn
##  06/10/2011, AF: svn -> bzr
##  09/11/2011, AF: generate 2 files: PG/PLplot; use bzr rev.no or release version
##  11/05/2012, AF: bzr -> git



if [[ ${#} -ne 4 && ${#} -ne 5 ]]; then
    
    echo -e "\n  syntax:   code_version.sh  <CMake base dir>  <f90 output file>  <Fortran compiler name>  <Compiler flags>  [<PLPLOT>]\n"

else
    
    BASEDIR=${1}                        # CMake base dir
    F90FILE=${1}/${2}                   # Fortran-90 output file
    COMPILER=${3}                       # Compiler name
    COMPILER_FLAGS=${4}                 # Compiler flags
    
    PLPLOT='no'
    if [[ ${#} -eq 5 ]]; then
	PLPLOT=${5}                     # PLPLOT (true if "yes")
    fi
    
    
    
    
    
    cd ${BASEDIR}
    
    if [[ ! -e .git/  && -e ${F90FILE} ]]
    then
	echo "${F90FILE} already exists, no need to create it"
	exit 0
    else
	echo "Generating ${F90FILE}"
    fi
    
    
    echo "!> \file code_version.f90  Source file automatically generated by Makefile to report the code version used." > ${F90FILE}
    echo "" >> ${F90FILE}
    echo "!***********************************************************************************************************************************" >> ${F90FILE}
    echo "!> \brief  Subroutine automatically generated by Makefile to report the code version used." >> ${F90FILE}
    echo "" >> ${F90FILE}
    echo "subroutine print_code_version(unit, use_PLplot)" >> ${F90FILE}
    echo "  implicit none" >> ${F90FILE}
    echo "  integer, intent(in) :: unit" >> ${F90FILE}
    echo "  logical, intent(out) :: use_PLplot" >> ${F90FILE}
    if [ -e .git/ ]; then  # Prefer revision number over release number
	echo "  character :: code_version*(99) = 'rev."`git rev-list --abbrev-commit HEAD | wc -l`", hash "`git log --pretty="%h (%ad)" --date=short -n1`"'" >> ${F90FILE}
	#echo "  character :: code_version*(99) = 'rev."`git rev-list --abbrev-commit HEAD | wc -l`", "`git describe --tags`" "`git log --pretty="(%ad)" --date=short -n1`"'" >> ${F90FILE}  # Doesn't work on Mac OS(?)
    elif [ -e .bzr/ ]; then  # Prefer bzr revision number over release number
	echo "  character :: code_version*(99) = 'revision "`bzr revno`"'" >> ${F90FILE}
    elif [ -e VERSION ]; then
	echo "  character :: code_version*(99) = 'v"`grep 'Release version' VERSION | awk '{print $3}'`"'" >> ${F90FILE}
    elif [ -e doc/VERSION ]; then
	echo "  character :: code_version*(99) = 'v"`grep 'Release version' doc/VERSION | awk '{print $3}'`"'" >> ${F90FILE}
    else
	echo "  character :: code_version*(99) = '(unknown version)'" >> ${F90FILE}
    fi
    echo "  character :: compile_date*(99) = '"`date`"'" >> ${F90FILE}
    echo "  character :: compiler*(99) = '"${COMPILER}"'" >> ${F90FILE}
    echo "  character :: compiler_flags*(99) = '"${COMPILER_FLAGS}"'" >> ${F90FILE}
    if [ ${PLPLOT} == 'yes' ]; then
	echo "  character :: PGPLplot*(99) = 'PLplot'" >> ${F90FILE}
	echo "" >> ${F90FILE}
	echo "  use_PLplot = .true." >> ${F90FILE}
    else
	echo "  character :: PGPLplot*(99) = 'PGPlot'" >> ${F90FILE}
	echo "" >> ${F90FILE}
	echo "  use_PLplot = .false." >> ${F90FILE}
    fi
    echo "  write(unit,'(/,A)')'  AnalyseMCMC '//trim(code_version)//', compiled on '//trim(compile_date)//' with '// &" >> ${F90FILE}
    echo "       trim(compiler)//' '//trim(compiler_flags)//', using '//trim(PGPLplot)//'.'" >> ${F90FILE}
    echo "" >> ${F90FILE}
    echo "end subroutine print_code_version" >> ${F90FILE}
    echo "!***********************************************************************************************************************************" >> ${F90FILE}
    
    # touch -d doesn't work on FreeBSD
    #touch -d "1 Jan 2001" ${F90FILE}            # Make the file look old
    
fi


