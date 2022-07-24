!> \file MCMCstats.f90  Read MCMC statistics output file created by AnalyseMCMC, and reduce data.

! 
! LICENCE:
! 
! Copyright (c) 2007-2022  Marc van der Sluys
!  
! This file is part of the AnalyseMCMC package, see http://analysemcmc.sf.net and https://github.com/Astronomy/AnalyseMCMC.
!  
! This is free software: you can redistribute it and/or modify it under the terms of the European Union
! Public Licence 1.2 (EUPL 1.2).
! 
! This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the EU Public License for more details.
! 
! You should have received a copy of the European Union Public License along with this code.  If not, see
! <https://www.eupl.eu/1.2/en/>.
! 



!***********************************************************************************************************************************
program mcmcstats
  use SUFR_dummy, only: dumstr
  use analysemcmc_settings, only: fonttype
  use general_data, only: parNames, pgParNs,pgParNss
  
  implicit none
  integer, parameter :: nf1=100,nifo1=3,npar1=22,nival1=5
  integer :: i,j,iv,iv1,iv2,fi,nf,o,p,io,pgopen,system
  integer :: prinput,plfile
  character :: infile*(99),str*(99),output*(1000)
  
  integer :: totiter(nf1),totlines(nf1),totpts(nf1),totburn(nf1),totchains(nf1),usedchains(nf1),ndet(nf1),seed(nf1)
  integer :: detnr(nf1,nifo1),samplerate(nf1,nifo1),samplesize(nf1,nifo1),FTsize(nf1,nifo1)
  integer :: npar(nf1),ncol(nf1),nival(nf1),tbase(nf1), parID(npar1)  !, revID(99)
  real :: nullh(nf1),snr(nf1,nifo1),totsnr(nf1)
  real :: flow(nf1,nifo1),fhigh(nf1,nifo1),t_before(nf1,nifo1),t_after(nf1,nifo1),FTstart(nf1,nifo1),deltaFT(nf1,nifo1)
  real :: model(nf1,npar1),median(nf1,npar1),mean(nf1,npar1),stdev1(nf1,npar1),stdev2(nf1,npar1),absvar1(nf1,npar1)
  real :: absvar2(nf1,npar1),corrs(nf1,npar1,1:npar1)
  real :: ival0,ivals(nf1,1:nival1),ivlcntr(nf1,npar1,nival1),ivldelta(nf1,npar1,nival1),ivlinrnge(nf1,npar1,nival1)
  real :: ivldelta2d(nf1,npar1,nival1)
  character :: detname(nf1,nifo1)*(25),varnames(nf1,npar1)*(25),outputnames(nf1)*(99),ivlok(nf1,npar1,nival1)*(3)
  character :: ivlok2d(nf1,npar1,nival1)*(3),letters(5)
  
  integer :: npdf2d(nf1),nbin2dx(nf1),nbin2dy(nf1),pdfpar2dx(nf1,npar1),pdfpar2dy(nf1,npar1)
  
  integer :: sym,ci,ci0,ls,ls0,p0,p01,p02,p1,p2,p3,p10,p11,p22  ! ,p20
  real :: xmin,xmax,dx,ymin,ymax,dy,x0,y0,x1,y1,clr
  real :: par1,par2,par3
  
  integer :: rel,nplpar,plpars(99),docycle
  real :: x,pi,d2r
  real :: papsize,paprat
  character :: plParNs(npar1)*(25)
  
  integer :: plotdeltas,plotsnrs,plotcorrelations,plotcorrmatrix,printdeltastable
  
  
  prinput = 1  ! Print input to screen: 0-no, 1-yes
  plfile  = 2  ! Plot to file: 0-no (screen), 1-png, 2-eps, 3-pdf, 4-eps & pdf
  
  plotdeltas = 0        ! 0 or 1x
  plotsnrs = 0          ! 0 or 1
  plotcorrelations = 1  ! 0 or 1
  plotcorrmatrix = 1    ! 0-2; 2: swap rows/columns
  printdeltastable = 0  ! 0 or 1,2
  
  !ival0 = 0.90  ! 
  ival0 = 0.95450  ! "2 sigma"
  
  fonttype = 1  ! 1-"arial", 2-"roman"
  
  p10 = 0  ! Make sure it is initialised
  
  if(plfile.eq.0) then
     papsize = 10.81  ! Screen size (Gentoo: 10.81, Fink: 16.4)
     paprat = 0.575   ! Screen ratio (Gentoo: 0.575, Fink: 0.57)
  else
     papsize = 10.6
     paprat = 0.75
  end if
  
  nf = command_argument_count()
  if(nf.eq.0) then
     write(*,'(/,A,/)')'  Syntax:  mcmcstats <file1 file2 ...>'
     stop
  end if
  if(nf.gt.nf1) then
     write(6,'(A,I3)')" Too many input files, I'll use the first",nf1
     nf = nf1
  end if
  
  pi = 4*atan(1.)
  d2r = pi/180.
  
  ivlok = ' y '
  ls0 = 1  ! Default linestyle
  
  ! Set parameter names:
  !call set_originalParameterNames()  ! Needs fonttype defined
  call set_derivedParameterNames()  ! Needs fonttype defined
  
  
  letters = [character(len=1) :: 'a','b','c','d','e']
  
  ! Read input files:
  o = 20
  !write(6,*)''
  do fi=1,nf
     call get_command_argument(fi,infile)
     if(prinput.eq.0) write(6,'(A)', advance='no')' Reading file: '//trim(infile)
     if(prinput.eq.1) write(6,'(A)')' Reading file: '//trim(infile)
     open(unit=o, form='formatted', status='old',file=trim(infile))
     
     read(o,'(A)')outputnames(fi)
     if(prinput.eq.1) write(6,*)''
     if(prinput.eq.1) write(6,'(A)')outputnames(fi)
     
     
     ! Read general run info:
     read(o,*) dumstr
     read(o,*) dumstr
     read(o,'(6x,5I12,I5,I11,F22.10,I8)')totiter(fi),totlines(fi),totpts(fi),totburn(fi),totchains(fi),usedchains(fi),seed(fi), &
          nullh(fi),ndet(fi)
     if(prinput.eq.1) write(6,'(/,A)')'           totiter    totlines      totpts     totburn   totchains used       seed     '// &
          '  null likelihood    ndet'
     if(prinput.eq.1) write(6,'(6x,4I12,I12, I5,I11,F22.10,I8)')totiter(fi),totlines(fi),totpts(fi),totburn(fi),totchains(fi), &
          usedchains(fi),seed(fi),nullh(fi),ndet(fi)
     !if(prinput.eq.0) write(6,'(6x,2I12,2I8)')totiter(fi),totburn(fi),ndet(fi),seed(fi)
     if(prinput.eq.0) write(6,'(6x,A,2(I7,A1),A,2(I2,A1))')'Data points: ',totpts(fi),'/',totlines(fi),',',' chains:', &
          usedchains(fi),'/',totchains(fi),'.'
     
     
     
     ! Read detector info:
     read(o,*) dumstr
     if(prinput.eq.1) write(6,*)''
     if(prinput.eq.1) write(6,'(A)')'        Detector Nr               SNR       f_low      f_high   before tc    after tc    '// &
          'Sample start (GPS)    Sample length   Sample rate   Sample size       FT size'
     totsnr(fi) = 0.
     do i=1,ndet(fi)
        read(o,'(A16,I3,F18.8,4F12.2,F22.8,F17.7,3I14)')detname(fi,i),detnr(fi,i),snr(fi,i),flow(fi,i),fhigh(fi,i),t_before(fi,i), &
             t_after(fi,i),FTstart(fi,i),deltaFT(fi,i),samplerate(fi,i),samplesize(fi,i),FTsize(fi,i)
        if(prinput.eq.1) write(6,'(A16,I3,F18.8,4F12.2,F22.8,F17.7,3I14)')detname(fi,i),detnr(fi,i),snr(fi,i),flow(fi,i), &
             fhigh(fi,i),t_before(fi,i),t_after(fi,i),FTstart(fi,i),deltaFT(fi,i),samplerate(fi,i),samplesize(fi,i),FTsize(fi,i)
        totsnr(fi) = totsnr(fi) + snr(fi,i)*snr(fi,i)
     end do
     totsnr(fi) = sqrt(totsnr(fi))
     read(o,*) dumstr,tbase(fi)
     if(prinput.eq.1) write(6,*)''
     if(prinput.eq.1) write(6,'(A,I12)')' t0:',tbase(fi)
     
     
     ! Read basic statistics:
     read(o,*) dumstr
     read(o,*) dumstr,dumstr,npar(fi),ncol(fi)
     if(prinput.eq.1) write(6,*)''
     if(prinput.eq.1) write(6,'(A,2I3)')' Npar,ncol: ',npar(fi),ncol(fi)
     read(o,*) dumstr  ! Statistics headers
     if(prinput.eq.1) write(6,'(A)')'  param.       model      median        mean      stdev1      stdev2      abvar1      abvar2'
     do p=1,npar(fi)
        read(o,'(A8,7F12.6)') varnames(fi,p),model(fi,p),median(fi,p),mean(fi,p),stdev1(fi,p),stdev2(fi,p),absvar1(fi,p), &
             absvar2(fi,p)
        if(prinput.eq.1) write(6,'(A8,7F12.6)') trim(varnames(fi,p)),model(fi,p),median(fi,p),mean(fi,p), &
             stdev1(fi,p),stdev2(fi,p), absvar1(fi,p),absvar2(fi,p)
        
        ! Get parameter IDs:
        do p1=1,99
           if(trim(parNames(p1)).eq.varnames(fi,p)) parID(p) = p1
        end do
     end do  ! p
     
     !do p=1,99
     !   do p1=1,npar(fi)
     !      if(parID(p1).eq.p) revID(p) = p1
     !   end do
     !end do
     
     ! Read correlations:
     read(o,*) dumstr
     if(prinput.eq.1) write(6,'(A)')''
     read(o,*) dumstr
     read(o,*) dumstr  ! Correlation headers
     if(prinput.eq.1) then
        write(6,'(A,2I3)')' Npar: ',npar(fi)
        write(6,'(A)')'              logL        Mc       eta        tc        dl      spin     th_SL        RA       Dec     '// &
             'phase      thJo      phJo     alpha        M1        M2 '
     end if
     do p=1,npar(fi)
        read(o,*)varnames(fi,p),corrs(fi,p,1:npar(fi))
        if(prinput.eq.1) write(6,'(A8,20F10.5)')trim(varnames(fi,p)),corrs(fi,p,1:npar(fi))
     end do
     
     
     ! Read 1D intervals:
     read(o,*) dumstr
     if(prinput.eq.1) write(6,'(A)')''
     read(o,*) dumstr,nival(fi)
     if(prinput.eq.1) write(6,'(A,I3)')' Nival: ',nival(fi)
     nival(fi) = nival(fi)   !+ 1  ! Since 100% interval is not counted in AnalyseMCMC
     read(o,*) dumstr,ivals(fi,1:nival(fi))
     if(prinput.eq.1) write(6,'(A22,10(F20.5,14x))')'Interval:',ivals(fi,1:nival(fi))
     
     read(o,*) dumstr  ! Interval headers
     if(prinput.eq.1) write(6,'(A)')'  param.        centre       delta in rnge        centre       delta in rnge        centre'// &
          '       delta in rnge        centre       delta in rnge '
     do p=1,npar(fi)
        read(o,*)varnames(fi,p),(ivlcntr(fi,p,iv),ivldelta(fi,p,iv),ivlinrnge(fi,p,iv),dumstr,iv=1,nival(fi))
        do iv=1,nival(fi)
           if(ivlinrnge(fi,p,iv).gt.1.) ivlok(fi,p,iv) = '*N*'
        end do
        if(prinput.eq.1) write(6,'(A8,2x,5(2F12.6,F6.3,A3,1x))')trim(varnames(fi,p)),(ivlcntr(fi,p,iv),ivldelta(fi,p,iv), &
             ivlinrnge(fi,p,iv),ivlok(fi,p,iv),iv=1,nival(fi))
        iv = nival(fi)  ! 100%
        iv = 3  ! 99%
        if(p.gt.1.and.ivlinrnge(fi,p,iv).gt.1.) then  ! Don't print LogL (p=1)
           write(6,'(A16,A8,5x,2F12.6,5x,2F12.6,F6.3,A3,A3,F5.1,A2)')trim(outputnames(fi)),trim(varnames(fi,p)), &
                model(fi,p),median(fi,p),ivlcntr(fi,p,iv),ivldelta(fi,p,iv),ivlinrnge(fi,p,iv),ivlok(fi,p,iv),'  (', &
                ivals(fi,iv)*100,'%)'
        end if
     end do  ! p
     if(prinput.eq.1) write(6,*)''
     
     
     
     ! Read 2D intervals:
     read(o,*) dumstr
     read(o,*) dumstr,npdf2d(fi)
     if(prinput.eq.1) write(*,'(A,I6)')' Npdf2d:',npdf2d(fi)
     read(o,*) dumstr,dumstr,nbin2dx(fi),nbin2dy(fi)
     if(prinput.eq.1) write(*,'(A,2I6)')' Nbin2dx,y:',nbin2dx(fi),nbin2dy(fi)
     read(o,*) dumstr
     read(o,*) dumstr
     
     do p=1,npdf2d(fi)
        read(o,*)pdfpar2dx(fi,p),pdfpar2dy(fi,p),dumstr,dumstr,(ivldelta2d(fi,p,iv),ivlok2d(fi,p,iv),iv=1,nival(fi))
        do iv=1,nival(fi)
           if(ivlok2d(fi,p,iv).eq.'y  ') ivlok2d(fi,p,iv) = ' y '
           if(ivlok2d(fi,p,iv).eq.'n  ') ivlok2d(fi,p,iv) = '*N*'
        end do
        if(prinput.eq.1) write(*,'(2I4,5(F12.6,A3))')pdfpar2dx(fi,p),pdfpar2dy(fi,p),(ivldelta2d(fi,p,iv),ivlok2d(fi,p,iv), &
             iv=1,nival(fi))
        iv = nival(fi)  ! 100%
        !iv = 3  ! 99%
        if(p.gt.1.and.ivlok2d(fi,p,iv).eq.'*N*') then  ! Don't print LogL (p=1)
           write(6,'(A16,A8,5x,2F12.6,5x,2F12.6,F6.3,A3,A3,F5.1,A2)')trim(outputnames(fi)),trim(varnames(fi,p)), &
                model(fi,p),median(fi,p),ivlcntr(fi,p,iv),ivldelta(fi,p,iv),ivlinrnge(fi,p,iv),ivlok(fi,p,iv),'  (', &
                ivals(fi,iv)*100,'%)'
        end if
     end do  ! p
     if(prinput.eq.1) write(6,*)''
     
     
     
     
     close(o)  ! Statistics file
  end do  ! f
  ! End reading input files
  
  
  
  
  
  
  
  
  
  
  
  !*********************************************************************************************************************************
  ! Plot deltas:
  if(plotdeltas.eq.1.and.nf.gt.2) then
     !write(6,*)''
     write(6,'(A)')' Plotting probability range deltas...'
     if(plfile.eq.0) then
        io = pgopen('12/xs')
     end if
     if(plfile.eq.1) io = pgopen('deltas.ppm/ppm')
     if(plfile.ge.2) io = pgopen('deltas.eps/cps')
     
     if(io.le.0) then
        write(6,'(A,I6,/)')'Cannot open PGPlot device.  Quitting the programme',io
        stop
     end if
     call pgsch(1.5)
     call pgpap(papsize,paprat)
     
     call pgsubp(4,3)
     call pgscr(3,0.,0.5,0.)
     
     iv = 1
     write(6,'(A,I2,A1,F8.3,A1)')' Plotting deltas for probability range',iv,':',ivals(1,iv)*100,'%'
     
     
     do p=1,12
        call pgpage()
        call pgsch(2.)
        ci = 1
        ci0 = ci+1
        xmin = 0.
        xmax = 1.
        dx = abs(xmax-xmin)*0.1
        ymin =  1.e30
        ymax = -1.e30
        do fi=1,nf
           ymin = min(ymin,ivldelta(fi,p,iv))
           ymax = max(ymax,ivldelta(fi,p,iv))
        end do
        ymin = 0.  ! Only in linear
        dy = abs(ymax-ymin)*0.1
        
        
        call pgswin(xmin-dx,xmax+dx,ymin-dy,ymax+dy)
        call pgbox('BCNTS',0.0,0,'BCNTS',0.0,0)
        
        call pgsch(3.)
        do p1=1,3         ! Ndet, or detnr
           do p2=0,180,5  ! Theta_SL
              do p3=0,10  ! Spin magnitude * 10
                 par1 = real(p1)
                 par2 = real(p2)
                 par3 = real(p3)*0.1
                 
                 do fi=1,nf
                    !if(nint(par1).ne.ndet(fi)) cycle        ! Multiple numbers of detectors
                    !if(nint(par1).ne.detnr(fi,1)) cycle      ! Multiple 1-detector cases
                    !if(nint(par2).ne.nint(model(fi,6))) cycle
                    !if(nint(par3*10).ne.nint(model(fi,5)*10)) cycle
                    
                    !ci = ci+1
                    
                    if(p1.ne.p10) then
                       ci = ci+1
                       if(p.eq.1) write(6,'(A,I3,A,I2)')' ci:',ci,' Ndet:',ndet(fi)
                    end if
                    ci = mod(fi+1,10)
                    call pgsci(ci)
                    sym = 2
                    if(ivlinrnge(fi,p,iv).gt.1.0) sym = 18
                    ls = 1
                    if(p2.eq.55) ls = 2
                    x1 = model(fi,5)
                    y1 = ivldelta(fi,p,iv)
                    call pgpoint(1,x1,y1,sym)
                    if(ci.eq.ci0.and.ls.eq.ls0) then
                       call pgsls(ls)
                       !call pgline(2,(/x0,x1/),(/y0,y1/))
                    end if
                    x0  = x1
                    y0  = y1
                    ci0 = ci
                    ls0 = ls
                    p10 = p1
                    !p20 = p2
                 end do
              end do
           end do
        end do
        
        call pgsci(1)
        call pgsls(1)
        call pgsch(2.)
        !call pgmtxt('T',1.,0.5,0.5,trim(varnames(1,p)) )
        call pgmtxt('T',1.,0.5,0.5,trim(pgParNs(parID(p))) )
        !write(6,*)''
     end do
     
     
     call pgend()
     
     if(plfile.eq.1) then
        i = system('convert -depth 8 deltas.ppm deltas.png')
        i = system('rm -f deltas.ppm')
     end if
     if(plfile.gt.2) then
        i = system('eps2pdf deltas.eps  -o deltas.pdf   >& /dev/null')
        if(plfile.eq.3) i = system('rm -f detas.eps')
     end if
  end if  ! if(plotdeltas.eq.1.and.nf.gt.2) then
  
  
  
  
  
  
  
  
  
  !*********************************************************************************************************************************
  ! Plot SNRs:
  if(plotsnrs.eq.1.and.nf.gt.2) then
     write(6,'(A)')' Plotting SNRs...'
     if(plfile.eq.0) then
        io = pgopen('13/xs')
     end if
     if(plfile.eq.1) io = pgopen('snrs.ppm/ppm')
     if(plfile.ge.2) io = pgopen('snrs.eps/cps')
     
     if(io.le.0) then
        write(6,'(A,I6,/)')'Cannot open PGPlot device.  Quitting the programme',io
        stop
     end if
     call pgsch(1.5)
     call pgpap(papsize,paprat)
     
     call pgscr(3,0.,0.5,0.)
     
     
     call pgsch(2.)
     ci = 1
     ci0 = ci+1
     xmin = 0.
     xmax = 1.
     dx = abs(xmax-xmin)*0.1
     ymin =  1.e30
     ymax = -1.e30
     do fi=1,nf
        ymin = min(ymin,totsnr(fi))
        ymax = max(ymax,totsnr(fi))
     end do
     dy = abs(ymax-ymin)*0.1
     
     
     call pgswin(xmin-dx,xmax+dx,ymin-dy,ymax+dy)
     call pgbox('BCNTS',0.0,0,'BCNTS',0.0,0)
     
     call pgsch(3.)
     do p1=1,3         ! Ndet
        do p2=0,180,5  ! Theta_SL
           do p3=0,10  ! Spin magnitude * 10
              par1 = real(p1)
              par2 = real(p2)
              par3 = real(p3)*0.1
              
              do fi=1,nf
                 if(nint(par1).ne.ndet(fi)) cycle        ! Multiple numbers of detectors
                 !if(nint(par1).ne.detnr(fi,1)) cycle      ! Multiple 1-detector cases
                 if(nint(par2).ne.nint(model(fi,6))) cycle
                 if(nint(par3*10).ne.nint(model(fi,5)*10)) cycle
                 
                 !ci = ci+1
                 
                 if(p1.ne.p10) then
                    ci = ci+1
                    if(p.eq.1) write(6,'(A,I3,A,I2)')' ci:',ci,' Ndet:',ndet(fi)
                 end if
                 
                 call pgsci(ci)
                 sym = 2
                 !if(ivlinrnge(fi,p,iv).gt.1.0) sym = 18
                 ls = 1
                 if(p2.eq.55) ls = 2
                 x1 = model(fi,5)
                 y1 = totsnr(fi)
                 call pgpoint(1,x1,y1,sym)
                 if(ci.eq.ci0.and.ls.eq.ls0) then
                    call pgsls(ls)
                    call pgline(2,(/x0,x1/),(/y0,y1/))
                 end if
                 
                 x0  = x1
                 y0  = y1
                 ci0 = ci
                 ls0 = ls
                 p10 = p1
                 !p20 = p2
              end do
           end do
        end do
     end do
     
     call pgsci(1)
     call pgsls(1)
     call pgsch(2.)
     call pgmtxt('T',1.,0.5,0.5,'SNR' )
     
     
     call pgend()
     
     if(plfile.eq.1) then
        i = system('convert -depth 8 snrs.ppm snrs.png')
        i = system('rm -f snrs.ppm')
     end if
     if(plfile.gt.2) then
        i = system('eps2pdf snrs.eps  -o snrs.pdf   >& /dev/null')
        if(plfile.eq.3) i = system('rm -f snrs.eps')
     end if
  end if  ! if(plotsnrs.eq.1.and.nf.gt.2) then
  
  
  
  
  
  
  
  
  
  !*********************************************************************************************************************************
  ! Plot correlations:
  if(plotcorrelations.eq.1.and.nf.gt.2) then
     write(6,'(A)')' Plotting correlations...'
     
     do p0 = 1,12
        write(6,'(A)')' Plotting correlations with '//trim(varnames(1,p0))
        
        if(plfile.eq.0) then
           io = pgopen('12/xs')
        end if
        if(plfile.eq.1) io = pgopen('corrs.ppm/ppm')
        if(plfile.ge.2) io = pgopen('corrs.eps/cps')
        
        if(io.le.0) then
           write(6,'(A,I6,/)')'Cannot open PGPlot device.  Quitting the programme',io
           stop
        end if
        call pgsch(1.5)
        call pgpap(papsize,paprat)
        
        call pgsubp(4,3)
        call pgscr(3,0.,0.5,0.)
        
        
        do p=1,12
           call pgpage()
           call pgsch(2.)
           ci = 1
           ci0 = ci+1
           xmin = 0.
           xmax = 1.
           dx = abs(xmax-xmin)*0.1
           ymin = -1.
           !ymin = 0.  ! If abs()
           ymax = 1.
           dy = abs(ymax-ymin)*0.1
           !ymin = ymin+dy  ! Force it to be zero, if abs()
           
           
           call pgswin(xmin-dx,xmax+dx,ymin-dy,ymax+dy)
           call pgbox('ABCNTS',0.0,0,'BCNTS',0.0,0)
           
           call pgsch(3.)
           do p1=1,3         ! Ndet
              do p2=0,180,5  ! Theta_SL
                 do p3=0,10  ! Spin magnitude * 10
                    par1 = real(p1)
                    par2 = real(p2)
                    par3 = real(p3)*0.1
                    
                    do fi=1,nf
                       !if(nint(par1).ne.ndet(fi)) cycle        ! Multiple numbers of detectors
                       !if(nint(par1).ne.detnr(fi,1)) cycle      ! Multiple 1-detector cases
                       !if(nint(par2).ne.nint(model(fi,6))) cycle
                       !if(nint(par3*10).ne.nint(model(fi,5)*10)) cycle
                       
                       !ci = ci+1
                       
                       if(p1.ne.p10) then
                          ci = ci+1
                          if(p.eq.1) write(6,'(A,I3,A,I2)')' ci:',ci,' Ndet:',ndet(fi)
                       end if
                       ci = mod(fi+1,10)
                       call pgsci(ci)
                       sym = 2
                       if(ivlinrnge(fi,p,iv).gt.1.0) sym = 18
                       ls = 1
                       if(p2.eq.55) ls = 2
                       x1 = model(fi,5)
                       y1 = corrs(fi,p0,p)
                       !y1 = abs(corrs(fi,p0,p))
                       !call pgpoint(1,x1,y1,sym)
                       call pgpoint(1,x1,y1,2)
                       if(ci.eq.ci0.and.ls.eq.ls0) then
                          call pgsls(ls)
                          !call pgline(2,(/x0,x1/),(/y0,y1/))
                       end if
                       x0  = x1
                       y0  = y1
                       ci0 = ci
                       ls0 = ls
                       p10 = p1
                       !p20 = p2
                    end do
                 end do
              end do
           end do
           
           call pgsci(1)
           call pgsls(1)
           call pgsch(2.)
           !call pgmtxt('T',1.,0.5,0.5,trim(varnames(1,p)) )
           call pgmtxt('T',1.,0.5,0.5,trim(pgParNs(parID(p))) )
           !write(6,*)''
        end do
        
        
        call pgend()
        
        if(plfile.eq.1) then
           i = system('convert -depth 8 corrs.ppm corrs.png')
           i = system('rm -f corrs.ppm')
        end if
        if(plfile.ge.2) then
           write(str,'(I2.2)')p0
           if(plfile.gt.2) i = system('eps2pdf corrs.eps  -o corrs_'//trim(str)//'.pdf   >& /dev/null')
           if(plfile.eq.2.or.plfile.eq.4) i = system('mv -f corrs.eps  corrs_'//trim(str)//'.eps')
           if(plfile.eq.3) i = system('rm -f corrs.eps')
        end if
     end do  ! p0
  end if  ! if(plotcorrelations.eq.1.and.nf.gt.2) then
  
  
  
  
  
  
  
  !*********************************************************************************************************************************
  ! Plot correlation matrix:
  if(plotcorrmatrix.eq.1.and.nf.le.2) then
     write(6,'(A)')' Plotting correlation matrix...'
     
     if(plfile.eq.0) then
        io = pgopen('12/xs')
     end if
     if(plfile.eq.1) io = pgopen('corr_matrix.ppm/ppm')
     if(plfile.ge.2) io = pgopen('corr_matrix.eps/cps')
     
     if(io.le.0) then
        write(6,'(A,I6,/)')'Cannot open PGPlot device.  Quitting the programme',io
        stop
     end if
     call pgpap(papsize,paprat)
     
     plpars = 0
     !plParNs(1:18) = [character(len=25) :: 'Mc','eta','tc','dl','RA','dec','incl','phase','psi','spin1','th1','phi1', &
     !     'spin2','th2','phi2','M1','M2','Mtot']
     !plParNs(1:15) = [character(len=25) :: 'Mc','eta','tc','dl','RA','dec','incl','phase','psi','spin1','th1','phi1', &
     !     'spin2','th2','phi2']
     plParNs(1:15) = [character(len=25) :: 'Mc','eta','spin1','th1','phi1','spin2','th2','phi2', &
          'tc','dl','RA','dec','incl','phase','psi']
     
     nPlPar = 0
     do p1=1,npar1
        do p2=1,npar1
           if(trim(varNames(1,p1)).eq.trim(plParNs(p2)) .and. len_trim(plParNs(p2)).ne.0.and. len_trim(plParNs(p2)).ne.25) then
              !print*,trim(varNames(1,p1)),trim(plParNs(p2)),len_trim(plParNs(p2))
              plPars(p1) = p2
              nPlPar = nPlPar + 1
              !print*,nPlPar,p1,p2,varNames(1,p1),plParNs(p2)
           end if
        end do
     end do
     
     call pgscr(3,0.,0.5,0.)
     call pgsvp(0.,1.0,0.,1.0)
     call pgswin(-1.,real(nplpar+1),real(nplpar+1),-1.)
     call pgslw(3)
     call pgsch(sqrt(12./real(nplpar)))
     call pgscf(fonttype)
     
     ci = 20
     
     call pgsci(1)
     
     dx = 6./real(nplpar)
     p11 = 0
     do p0=1,nPlPar
        do p=1,nPlPar
           if(plPars(p).eq.p0) exit
        end do
        if(plPars(p).ne.0) then
           p11 = p11+1
        else
           cycle
        end if
        
        call pgptxt( real(p11)-0.5, -dx*0.5-0.0167*real(nplpar), 0., 0.5, trim(pgParNss(parID(p))) )  ! At top
        call pgptxt(-dx*0.5-0.0167*real(nplpar),real(p11)-0.5+0.0167*real(nplpar),0.,0.5,trim(pgParNss(parID(p))))   ! At left
     end do
     
     do fi=1,nf
        p11 = 0
        do p01=1,nPlPar
           do p1=1,nPlPar
              if(plPars(p1).eq.p01) exit
           end do
           p11 = p11+1
           
           p22 = 0
           do p02=1,nPlPar
              do p2=1,nPlPar
                 if(plPars(p2).eq.p02) exit
              end do
              p22 = p22+1
              
              if(fi.eq.1.and.p22.ge.p11) cycle  ! Use upper triangle
              if(fi.eq.2.and.p22.le.p11) cycle  ! Use lower triangle
              
              y1 = corrs(fi,p2,p1)
              if(fi.eq.2) y1 = corrs(fi,p1,p2)
              
              if(plfile.lt.2) then                           ! Screen/bitmap have black backgrounds
                 if(fi.eq.1) call pgscr(ci,0.,0.,abs(y1)**2)  ! Blue
                 if(fi.eq.2) call pgscr(ci,abs(y1)**2,0.,0.)  ! Red
              else                                           ! eps/pdf have white backgrounds
                 if(fi.eq.1) call pgscr(ci,1.-abs(y1)**2,1.-abs(y1)**2,1.)  ! Blue
                 if(fi.eq.2) call pgscr(ci,1.,1.-abs(y1)**2,1.-abs(y1)**2)  ! Red 
              end if
              call pgsci(ci)
              call pgrect(real(p11-1),real(p11),real(p22-1),real(p22))
              
              write(str,'(F5.2)')y1
              clr = 0.
              if(plfile.lt.2) clr = 1.
              if(plfile.lt.2.and.abs(y1).lt.0.25) clr = abs(y1)*4.       ! Fade out the numbers
              if(plfile.ge.2.and.abs(y1).lt.0.25) clr = 1. - abs(y1)*4.
              if(abs(y1).gt.0.75) clr = 1.  ! White on dark background for the strongest correlations
              call pgscr(ci,clr,clr,clr)
              call pgptxt(real(p11)-0.5,real(p22)-0.5+0.0167*real(nplpar),0.,0.5,trim(str))
           end do  ! p2
        end do  ! p1
     end do  ! fi
     
     call pgsci(1)
     call pgslw(5)
     call pgline(2,(/0.,real(nplpar)/),(/0.,real(nplpar)/))
     call pgline(2,(/0.,0./),(/0.,real(nplpar)/))
     call pgline(2,(/0.,real(nplpar)/),(/0.,0.0/))
     call pgline(2,(/0.0,real(nplpar)/),(/real(nplpar),real(nplpar)/))
     call pgline(2,(/real(nplpar),real(nplpar)/),(/0.,real(nplpar)/))
     
     
     ! Draw dotted lines between two groups of parameters:
     !call pgsls(4)
     !call pgline(2,(/-1.,real(nplpar)/),(/8.,8./))
     !call pgline(2,(/8.,8./),(/-1.,real(nplpar)/))
     
     call pgend()
     
     if(plfile.eq.1) then
        i = system('convert -depth 8 corr_matrix.ppm corr_matrix.png')
        i = system('rm -f corr_matrix.ppm')
     end if
     if(plfile.gt.2) then
        i = system('eps2pdf corr_matrix.eps  -o corr_matrix.pdf   >& /dev/null')
        if(plfile.eq.3) i = system('rm -f corr_matrix.eps')
     end if
  end if  ! if(plotcorrmatrix.eq.1.and.nf.le.2) then
  
  
  
  
  
  
  
  !*******************************************************************************************
  ! Create a table of Delta's
  !*******************************************************************************************
  
  if(printdeltastable.eq.1) then
     open(unit=30, form='formatted', status='unknown', position='append', file='table.tex')
     do fi=1,nf
        iv = 0
        do i=1,nival(fi)
           if(abs(ivals(fi,i)-ival0).lt.1.e-5) iv = i
        end do
        if(iv.eq.0) then
           write(6,'(A)')'  Interval not found, file '//trim(outputnames(fi))
        else
           ! Write the number of detectors, a_spin and theta_sl:
           !write(output,'(I3,A,I6,A,F6.1,A)')ndet(fi),'  &  ',nint(model(fi,6)),'$^\circ$  &  ',model(fi,5),'  &  '
           
           ! Write the number of detectors, a_spin, theta_sl, and SNR:
           !write(output,'(I3,A,F6.1,A,I6,A,F6.1,A)')ndet(fi),'  $\!\!\!\!$ &  ',model(fi,6),'  $\!\!\!\!$ &  ',nint(model(fi,7)), &
           !'  $\!\!\!\!$ &  ',totsnr(fi),'  $\!\!\!\!$ &  ' 
           
           ! Write the number of detectors, a_spin, theta_sl, distance and SNR:
           !write(output,'(I3,A,F6.1,A,I6,A,F6.1,A,F6.1,A)')ndet(fi),'  $\!\!\!\!$ &  ',model(fi,6),'  $\!\!\!\!$ &  ', &
           !nint(model(fi,7)),'  $\!\!\!\!$ &  ',model(fi,5),'  $\!\!\!\!$ &  ',totsnr(fi),'  $\!\!\!\!$ &  ' 
           
           !Write the number of detectors, a_spin, theta_sl and distance:
           write(output,'(I3,A,F6.1,A,I6,A,F6.1,A)')ndet(fi),'  $\!\!\!\!$ &  ',model(fi,6),'  $\!\!\!\!$ &  ',nint(model(fi,7)), &
                '  $\!\!\!\!$ &  ',model(fi,5),'  $\!\!\!\!$ &  ' 
           
           ! Write the number of detectors, a_spin, theta_sl and distance, AND the number of chains used:
           !write(output,'(I3,A,F6.1,A,I6,A,F6.1,A,I6,A,I8,A2,I2,A)')ndet(fi),'  $\!\!\!\!$ &  ',model(fi,6),'  $\!\!\!\!$ &  ', &
           !nint(model(fi,7)),'  $\!\!\!\!$ &  ',model(fi,5),'  $\!\!\!\!$ &  ',totchains(fi),'  $\!\!\!\!$ &  '
           
           ! Write the number of detectors, a_spin, theta_sl and distance, AND the number of chains used, number of data points:
           !write(output,'(I3,A,F6.1,A,I6,A,F6.1,A,I6,A,I8,A2,I2,A)')ndet(fi),'  $\!\!\!\!$ &  ',model(fi,6),'  $\!\!\!\!$ &  ', &
           !nint(model(fi,7)),'  $\!\!\!\!$ &  ',model(fi,5),'  $\!\!\!\!$ &  ',totchains(fi),'  $\!\!\!\!$ &  ',totpts(fi), &
           !' (',nint(real(totpts(fi))/real(totlines(fi))*100.),'\%)  $\!\!\!\!$ &  '
           
           ! Write the number of detectors and SNR:
           !write(output,'(I3,A,F6.1,A)')ndet(fi),'  $\!\!\!\!$ &  ',totsnr(fi),'  $\!\!\!\!$ &  ' 
           
           
           
           ! Print probability ranges:
           do p1=2,npar(fi)  !Leave out logL
              !do p1=4,npar(fi)  !Leave out logL, M1, M2
              !print*,p,npar(fi)
              
              ! Display M1,M2 iso Mc,eta:
              !p = p1
              !if(p.gt.12) cycle
              !if(1.eq.2) then !replace Mc,eta by M1,M2
              !   if(p1.eq.1) p=13
              !   if(p1.eq.2) p=14
              !end if
              
              ! Display M1,M2 iso Mc,eta:
              p = p1-2
              !if(p.gt.13) cycle
              if(1.eq.1) then !replace Mc,eta by M1,M2
                 !if(p1.eq.1) p=14
                 !if(p1.eq.2) p=15
                 if(p.eq.0) p=14
                 if(p.eq.1) p=15
              end if
              
              
              !if(p.ge.8.and.p.le.13) cycle !Skip RA, dec, phi_c, theta_Jo, phi_Jo, alpha_c
              if(p.eq.8.or.p.eq.9.or.p.eq.11.or.p.eq.12) cycle !Skip RA, dec, theta_Jo, phi_Jo
              
              iv1 = 0
              iv2 = 1
              !do iv=iv1,iv2 !90 and 95%
              do iv=iv2,iv2 !90% only
                 x = ivldelta(fi,p,iv)
                 rel = 0
                 !if(p.eq.2.or.p.eq.3.or.p.eq.5.or.p.eq.6.or.p.eq.14.or.p.eq.15) rel=1  !Use relative deltas (%)
                 if(p.eq.2.or.p.eq.3.or.p.eq.5.or.p.eq.14.or.p.eq.15) rel=1  !Use relative deltas (%), not for a_spin
                 if(p.eq.4) x = x*1000                            !Time in ms
                 !if(p.eq.8) x = x*cos(40*d2r)*15                 !Convert RA to RA*cos(decl) and from hrs to deg
                 !if(p.eq.8) x = x*15                              !Convert RA from hrs to deg
                 if(p.eq.8) x = x*15 * cos(model(fi,p)*d2r)            !Convert RA from hrs to deg and take into account decl
                 if(rel.eq.1) x = x/ivlcntr(fi,p,iv)*100
                 
                 
                 if((p.eq.7.or.p.eq.13) .and. model(fi,6).lt.9.e-4) then  !For theta_SL or alpha_c, when a_spin=0
                    write(output,'(A)')trim(output)//'---'
                 else  !Normal case
                    if(x.gt.10.) then
                       write(output,'(A,I6)')trim(output),nint(x)
                    else if(x.gt.1.) then
                       write(output,'(A,F6.1)')trim(output),x
                    else  if(x.gt.0.1) then
                       write(output,'(A,F6.2)')trim(output),x
                    else
                       write(output,'(A,F6.3)')trim(output),x
                    end if
                    !print*,p1,p,x,ivldelta(fi,p,iv),ivlcntr(fi,p,iv)
                    
                    !if(iv.eq.iv2.and.rel.eq.1) write(output,'(A)')trim(output)//'\%'
                    if(iv.eq.iv1.and.iv1.ne.iv2) write(output,'(A)')trim(output)//';'
                    
                    ! Flag if outside range:
                    !if(ivlinrnge(fi,p,1).gt.1.) write(output,'(A)')trim(output)//'*'
                    !if(ivlinrnge(fi,p,2).gt.1.) write(output,'(A)')trim(output)//'*'
                    !if(ivlinrnge(fi,p,3).gt.1.) write(output,'(A)')trim(output)//'*'
                    !if(ivlinrnge(fi,p,4).gt.1.) write(output,'(A)')trim(output)//'*'
                    j = 0
                    do i=1,nival(fi)
                       if(ivlinrnge(fi,p,i).gt.1.) j = j+1
                    end do
                    !if(j.gt.0) write(output,'(A,I1,A)')trim(output)//'$^',j,'$'
                    !if(j.gt.0) write(output,'(A,I1,A)')trim(output)//'\color{red}$^',j,'$\color{black}'
                    if(j.gt.0) write(output,'(A)')trim(output)//'$^'//letters(j)//'$'
                 end if
                 
                 ! Add latex codes:
                 !if(iv.eq.iv2.and.p.lt.npar(fi)) write(output,'(A)')trim(output)//'  $\!\!\!\!$  &'
                 ! Add latex codes (p1.lt.12 iso p.lt.npar, in case npar=14):
                 !if(iv.eq.iv2.and.p1.lt.12) write(output,'(A)')trim(output)//'  $\!\!\!\!$  &'
                 ! Add latex codes (p1.lt.12 iso p.lt.npar, in case npar=14):
                 !if(iv.eq.iv2.and.p1.ne.npar(fi)) write(output,'(A)')trim(output)//'  $\!\!\!\!$  &'
                 ! Add latex codes (p1.lt.12 iso p.lt.npar, in case npar=14):
                 !if(iv.eq.iv2.and.p1.ne.npar(fi)) write(output,'(A)')trim(output)//'  &'
                 ! Add latex codes:
                 if(iv.eq.iv2.and.p1.lt.npar(fi)) write(output,'(A)')trim(output)//'   $\!\!\!$ &'
              end do !iv
           end do !p1/p
           
           
           ! Add 2D probability ranges/areas:
           do p=1,npdf2d(fi)
              p1 = pdfpar2dx(fi,p)
              p2 = pdfpar2dy(fi,p)
              !print*,p1,p2
              !print*,pdfpar2dx
              
              docycle = 1
              if(p1.eq.8.and.p2.eq.9) docycle = 0   ! Sky position
              if(p1.eq.12.and.p2.eq.11) docycle = 0   ! Binary orientation
              if(docycle.eq.1) cycle
              
              iv1 = 1
              iv2 = 1
              do iv=iv1,iv2
                 x = ivldelta2d(fi,p,iv)*(4*pi)*(180./pi)**2   ! Sky fraction -> square degrees
                 !x = sqrt(x/pi)*2                             ! Square degrees -> equivalent diameter
                 
                 ! LaTeX codes:
                 ! Add latex codes:
                 write(output,'(A)')trim(output)//'   $\!\!\!$ &'
                 ! Add latex codes, if last parameter (p1=npar) not printed:
                 !if(p.gt.1) write(output,'(A)')trim(output)//'   $\!\!\!$ &'
                 
                 ! Print range:
                 if(x.gt.100.) then
                    write(output,'(A,I6)')trim(output),nint(x)
                 else if(x.gt.1.) then
                    write(output,'(A,F6.1)')trim(output),x
                 else  if(x.gt.0.1) then
                    write(output,'(A,F6.2)')trim(output),x
                 else
                    write(output,'(A,F6.3)')trim(output),x
                 end if
                 
                 ! Flag if outside range:
                 j = 0
                 do i=1,nival(fi)
                    !if(ivlok2d(fi,p,i).eq.'*N*') write(output,'(A)')trim(output)//'*'
                    if(ivlok2d(fi,p,i).eq.'*N*') j = j+1
                 end do
                 !if(j.gt.0) write(output,'(A,I1,A1)')trim(output)//'$^',j,'$'
                 !if(j.gt.0) write(output,'(A,I1,A)')trim(output)//'\color{red}$^',j,'$\color{black}'
                 if(j.gt.0) write(output,'(A)')trim(output)//'$^'//letters(j)//'$'
                 
              end do  ! iv
           end do  ! p
           
           
           !write(6,*)''
           !if(fi.ne.nf) write(output,'(A)')trim(output)//'  \\'  ! Add latex codes
           write(output,'(A)')trim(output)//'  \\'  ! Add latex codes
           
           ! Remove ', ' from output:
           do j=1,10
              do i=1,len_trim(output)-1
                 if(output(i:i+1).eq.'; ') write(output(i+1:len_trim(output)),'(A)')output(i+2:len_trim(output)+1)
              end do
           end do
           
           write(30,'(A)')trim(output)
        end if
     end do  ! f
     close(30)
  end if  ! if(printdeltastable.eq.1)
  
  
  ! Swap columns and rows:
  if(printdeltastable.eq.2) then
     !write(6,*)''
     do p=1,npar(1)
        do fi=1,nf
           iv = 0
           do i=1,nival(fi)
              if(abs(ivals(fi,i)-ival0).lt.1.e-5) iv = i
           end do
           if(iv.eq.0) then
              write(6,'(A)')'  Interval not found, file '//trim(outputnames(fi))
           else
              !write(6,'(I3,2F10.2,$)')ndet(fi),model(fi,5),model(fi,6)  ! Write the number of detectors, a_spin and theta_sl
              !write(6,'(I3,A5,F6.1,A5,I6,A5,$)')ndet(fi),'  &  ',model(fi,5),'  &  ',nint(model(fi,6)), &
              !'  &  '  ! Write the number of detectors, a_spin and theta_sl
              x = ivldelta(fi,p,iv)
              rel = 0
              if(p.eq.1.or.p.eq.2.or.p.eq.4.or.p.eq.5) rel=1  ! Use relative deltas (%)
              if(rel.eq.1) x = x/ivlcntr(fi,p,iv)*100
              if(x.gt.10.) then
                 write(output,'(I6)')nint(x)
              else if(x.gt.1.) then
                 write(output,'(A,F6.1)')trim(output),x
              else  if(x.gt.0.1) then
                 write(output,'(A,F6.2)')trim(output),x
              else
                 write(output,'(A,F6.3)')trim(output),x
              end if
              
              if(rel.eq.1) then
                 write(output,'(A)')trim(output)//'%'
              else
                 write(output,'(A)')trim(output)//' '
              end if
              
              write(output,'(A)')trim(output)//'  &  '  ! Add latex codes
              
           end if
        end do
        write(output,'(A)')trim(output)//'  \\'  ! Add latex codes
        
        write(6,'(A)')trim(output)
     end do
  end if  ! if(printdeltastable.eq.2)
  
  
  
  
  
  
  
  
  write(6,*)''
end program mcmcstats
!***********************************************************************************************************************************
