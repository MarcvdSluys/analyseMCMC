!Read and plot the data output from the spinning MCMC code.  This programme replaces plotspins

program analysemcmc
  use constants
  use analysemcmc_settings
  use general_data
  use mcmcrun_data
  use stats_data
  use plot_data
  use chain_data
  implicit none
  integer :: i,ic,p,os,iargc,exitcode,tempintarray(99),getos
  real :: pltsz
  real*8 :: timestamp,timestamps(9)
  
  timestamps(1) = timestamp(os)
  write(*,*)
  
  os = getos() !1-Linux, 2-MacOS
  
  call setconstants           !Define mathematical constants
  call set_plotsettings()     !Set plot settings to 'default' values
  call read_settingsfile()    !Read the plot settings (overwrite the defaults)
  call write_settingsfile()   !Write the input file back to disc
  
  
  nchains0 = iargc()
  if(nchains0.lt.1) then
     write(*,'(A,/)')'  Syntax: analysemcmc <file1> [file2] ...'
     stop
  end if
  
  
  !Some of the stuff below will have to go to the input file
  
  par1 = 1          !First parameter to treat (stats, plot): 0-all
  par2 = 15         !Last parameter to treat (0: use npar)
  
  maxdots = 25000  !~Maximum number of dots to plot in e.g. chains plot, to prevent dots from being overplotted too much and eps/pdf files from becoming huge.  Use this to autoset chainpli
  
  
  !Determine plot sizes and ratios:   (ratio ~ y/x and usually < 1 ('landscape'))
  bmpsz = real(bmpxsz-1)/85. * scfac !Make png larger, so that convert interpolates and makes the plot smoother
  bmprat = real(bmpysz-1)/real(bmpxsz-1)
  write(bmpxpix,'(I4)')bmpxsz  !Used as a text string by convert
  if(file.eq.0) pltsz = scrsz
  if(file.eq.0) pltrat = scrrat
  if(file.eq.1) pltsz = bmpsz
  if(file.eq.1) pltrat = bmprat
  if(file.ge.2) pltsz = pssz
  if(file.ge.2) pltrat = psrat

  
  !Use full unsharp-mask strength for plots with many panels and dots, weaker for those with fewer panels and.or no dots
  write(unsharplogl,'(I4)')max(nint(real(unsharp)/2.),1)  !Only one panel with dots
  write(unsharpchain,'(I4)')unsharp                       !~12 panels with dots
  write(unsharppdf1d,'(I4)')max(nint(real(unsharp)/2.),1) !~12 panels, no dots
  write(unsharppdf2d,'(I4)')max(nint(real(unsharp)/4.),1) !1 panel, no dots
  
  !CHECK: still needed?
  !Trying to implement this, for chains plot at the moment
  !pssz   = 10.5   !Default: 10.5   \__ Gives same result as without pgpap
  !psrat  = 0.742  !Default: 0.742  /
  
  !if(quality.eq.2) then
  !   pssz   = 10.5
  !   psrat  = 0.82     !Nice for presentation (Beamer)
  !end if
  
  outputdir = '.'  !Directory where output is saved (either relative or absolute path)
  
  
  
  
  
  
  
  !Sort out implicit options:
  if(panels(1)*panels(2).lt.nplvar) panels = 0
  if(panels(1)*panels(2).lt.1) then
     if(nplvar.eq.1) panels = (/1,1/)
     if(nplvar.eq.2) panels = (/2,1/)
     if(nplvar.eq.3) panels = (/3,1/)
     if(nplvar.eq.4) panels = (/2,2/)
     if(nplvar.eq.5) panels = (/5,1/)
     if(nplvar.eq.6) panels = (/3,2/)
     if(nplvar.eq.7) panels = (/4,2/)
     if(nplvar.eq.8) panels = (/4,2/)
     if(nplvar.eq.9) panels = (/3,3/)
     if(nplvar.eq.10) panels = (/5,2/)
     if(nplvar.eq.11) panels = (/4,3/)
     if(nplvar.eq.12) panels = (/4,3/)
     if(nplvar.eq.12.and.quality.eq.3) panels = (/3,4/)
     if(nplvar.eq.13) panels = (/5,3/)
     if(nplvar.eq.14) panels = (/5,3/)
     if(nplvar.eq.15) panels = (/5,3/)
     if(nplvar.eq.16) panels = (/4,4/)
     if(nplvar.eq.17) panels = (/6,3/)
     if(nplvar.eq.18) panels = (/6,3/)
     if(nplvar.eq.19) panels = (/5,4/)
     if(nplvar.eq.20) panels = (/5,4/)
  end if
  
  
  psclr = '/cps'
  if(colour.eq.0) psclr = '/ps'
  
  ncolours = 5; colours(1:ncolours)=(/4,2,3,6,5/) !Paper
  ncolours = 10; colours(1:ncolours)=(/2,3,4,5,6,7,8,9,10,11/)
  nsymbols = 1; symbols(1:nsymbols)=(/chainsymbol/)
  if(colour.eq.1.and.quality.eq.2) then !Beamer
     ncolours = 5
     colours(1:ncolours)=(/4,2,5,11,15/)
  end if
  if(colour.ne.1) then
     ncolours=3
     colours(1:ncolours)=(/1,14,15/)
     !ncolours=6
     !colours(1:ncolours)=(/1,1,1,15,1,15/)
     if(chainsymbol.eq.-10) then
        nsymbols = 8
        symbols(1:nsymbols) = (/2,4,5,6,7,11,12,15/) !Thin/open symbols
     end if
     if(chainsymbol.eq.-11) then
        nsymbols = 6
        symbols(1:nsymbols) = (/-3,-4,16,17,18,-6/) !Filled symbols
     end if
     !print*,chainsymbol,nsymbols
  end if
  if(colour.eq.1.and.quality.eq.0.and.nchs.gt.5) then
     ncolours = 10
     colours(1:ncolours)=(/2,3,4,5,6,7,8,9,10,11/)
  end if
  !Overrule
  !ncolours = 1
  !colours(1:ncolours)=(/6/)
  !defcolour = 2 !Red e.g. in case of 1 chain
  defcolour = colours(1)
  
  
  if(reverseread.ge.2) then !Reverse colours too
     do i=1,ncolours
        tempintarray(i) = colours(i)
     end do
     !do i=1,ncolours
     !   colours(i) = tempintarray(ncolours-i+1) !Reverse colours too
     !end do
     do i=1,nchains0
        colours(i) = tempintarray(nchains0-i+1) !Reverse colours too, but use the same first nchains0 from the set
     end do
  end if
  
  if(plot.eq.0) then
     pllogl = 0
     plchain = 0
     pljump = 0
     plsigacc = 0
     if(savepdf.eq.0) then
        plpdf1d = 0
        plpdf2d = 0
     end if
     plmovie = 0
  end if
  if(savepdf.eq.1) then
     if(nplvar.ne.15) write(*,'(/,A)')'*** WARNING:  I changed nplvar to 15, since savepdf is selected ***'
     nplvar = 15; plvars(1:nplvar) = (/1,2,3,4,5,6,7,8,9,10,11,12,13,14,15/) !All 12 + m1,m2
     wrapdata = 0
  end if
  !if(par1.lt.2) par1 = 2
  if(par1.lt.1) par1 = 1 !Include log(L)
  if(plsigacc.ge.1.or.plmovie.ge.1) rdsigacc = 1
  if(file.eq.1) combinechainplots = 0
  if(file.ge.1) update = 0
  if(plmovie.eq.1) update = 0
  if(plotsky.ge.1) then
     plpdf2d = 1
     !wrapdata = 0
  end if
  
  colournames(1:15) = (/'white','red','dark green','dark blue','cyan','magenta','yellow','orange','light green','brown','dark red','purple','red-purple','dark grey','light grey'/)
  if(file.ge.2) colournames(1) = 'black'
  
  
  
  !Columns in dat(): 1:logL 2:mc, 3:eta, 4:tc, 5:logdl, 6:spin, 7:kappa, 8: RA, 9:sindec,10:phase, 11:sinthJ0, 12:phiJ0, 13:alpha
  varnames(1:15) = (/'logL','Mc','eta','tc','log_dl','spin','kappa','RA','sin_dec','phase','sin_thJo','phJo','alpha','M1','M2'/)
  pgvarns(1:15)  = (/'log Likelihood        ','M\dc\u (M\d\(2281)\u) ','\(2133)               ','t\dc\u (s)            ', &
       'logd\dL\u (Mpc)       ','a\dspin\u             ','\(2136)               ','R.A. (rad)            ', &
       'sin dec.              ','\(2147)\dc\u (rad)    ','sin \(2134)\dJ0\u     ','\(2147)\dJ0\u (rad)   ', &
       '\(2127)\dc\u (rad)    ','M\d1\u (M\d\(2281)\u) ','M\d2\u (M\d\(2281)\u) '/)
  pgvarnss(1:15)  = (/'log L    ','M\dc\u ','\(2133)','t\dc\u','log d\dL\u','a\dspin\u','\(2136)','R.A.','sin dec.','\(2147)\dc\u', &
       'sin \(2134)\dJ0\u','\(2147)\dJ0\u','\(2127)\dc\u','M\d1\u','M\d2\u'/)
  pgorigvarns(1:15)  = (/'log Likelihood        ','M\dc\u (M\d\(2281)\u) ','\(2133)               ','t\dc\u (s)            ', &
       'logd\dL\u (Mpc)       ','a\dspin\u             ','\(2136)               ','R.A. (rad)            ', &
       'sin dec.              ','\(2147)\dc\u (rad)    ','sin \(2134)\dJ0\u     ','\(2147)\dJ0\u (rad)   ', &
       '\(2127)\dc\u (rad)    ','M\d1\u (M\d\(2281)\u) ','M\d2\u (M\d\(2281)\u) '/)
  !pgorigvarns(1:15)  = (/'log L    ','M\dc\u ','\(2133)','t\dc\u','log d\dL\u','a\dspin\u','\(2136)','R.A.','sin dec.','\(2147)\dc\u', &
  !     'sin \(2134)\dJ0\u','\(2147)\dJ0\u','\(2127)\dc\u','M\d1\u','M\d2\u'/)
  pgunits(1:15)  = (/'','M\d\(2281)\u ','','s','Mpc','','rad','rad','','rad','','rad','rad','M\d\(2281)\u','M\d\(2281)\u'/)
  
  
  
  
  
  !if(prprogress+prruninfo+prinitial.ge.1) write(*,*)
  npar = 13
  if(nchains0.gt.nchs) write(*,'(A,I3,A)')'*** WARNING:  Too many input files (chains), please increase nchs in analysemcmc_functions.f. Only',nchs,' files can be read.'
  if(prchaininfo.ge.1) write(*,'(A,I3,A)')'  Reading',nchains0,' chains '
  nchains0 = min(nchains0,nchs)
  nchains = nchains0
  
  
  
  
  
  
  
  !*******************************************************************************************************************************
  !***   READ INPUT FILE(S)   ****************************************************************************************************
  !*******************************************************************************************************************************
  
101 continue
  !Read the input files:
  call read_mcmcfiles(exitcode)
  if(exitcode.ne.0) goto 9999
  
  
  !Get and print some basic chain statistics:
  timestamps(2) = timestamp(os)
  call mcmcruninfo(exitcode)
  
  
  
  
  
  ! **********************************************************************************************************************************
  ! ***  DO STATISTICS   *************************************************************************************************************
  ! **********************************************************************************************************************************
  
  timestamps(3) = timestamp(os)
  
  call statistics(exitcode)
  if(exitcode.ne.0) goto 9999
  
  
  
  
  
  
  
  !Change the original chain data
  if(changevar.eq.1) then
     do ic=1,nchains0
        !Columns in dat(): 1:logL 2:mc, 3:eta, 4:tc, 5:dl, 6:spin,  7:theta_SL, 8: RA,   9:dec, 10:phase, 11:thJ0, 12:phiJ0, 13:alpha
        !if(prprogress.ge.2.and.update.eq.0) write(*,'(A,$)')'Changing some variables...   '
        do p=par1,par2
           if(p.eq.5) pldat(ic,p,1:ntot(ic)) = exp(pldat(ic,p,1:ntot(ic)))
           !if(p.eq.9.or.p.eq.11) pldat(ic,p,1:ntot(ic)) = asin(pldat(ic,p,1:ntot(ic)))*r2d
           if(p.eq.9) pldat(ic,p,1:ntot(ic)) = asin(pldat(ic,p,1:ntot(ic)))*r2d
           if(p.eq.7) pldat(ic,p,1:ntot(ic)) = acos(pldat(ic,p,1:ntot(ic)))*r2d
           if(p.eq.8) pldat(ic,p,1:ntot(ic)) = pldat(ic,p,1:ntot(ic))*r2h
           !if(p.eq.10.or.p.eq.12.or.p.eq.13) pldat(ic,p,1:ntot(ic)) = pldat(ic,p,1:ntot(ic))*r2d
           if(p.ge.10.and.p.le.13) pldat(ic,p,1:ntot(ic)) = pldat(ic,p,1:ntot(ic))*r2d
        end do !p
     end do
     !if(prprogress.ge.2.and.update.eq.0) write(*,'(A)')'  Done.'
  end if !if(changevar.eq.1)
  
  
  
  
  deallocate(dat)
  
  
  
  ! **********************************************************************************************************************************
  ! ***  CREATE PLOTS   **************************************************************************************************************
  ! **********************************************************************************************************************************
  
  timestamps(4) = timestamp(os)
  
  if(prprogress.ge.2) write(*,*)''
  if(plot.eq.1.and.prprogress.ge.1.and.update.eq.0) write(*,'(/,A,$)')'  Plotting: '

  
  !***********************************************************************************************************************************      
  !Plot (1d) chains: logL, parameter chains, jumps, etc.
  if(plot.eq.1) then
     call chains(exitcode)
     if(exitcode.ne.0) goto 9999
  end if




  
  
  
  
  
  
  timestamps(5) = timestamp(os)
  
  
  !***********************************************************************************************************************************      
  !Plot pdfs (1d)
  if(plpdf1d.eq.1) then
     call pdfs1d(exitcode)
     if(exitcode.ne.0) goto 9999
  end if !if(plpdf1d.eq.1)
  
  
  
  
  
  
  
  
  
  
  
  timestamps(6) = timestamp(os)
  
  !***********************************************************************************************************************************      
  if(plpdf2d.ge.1.and.mergechains.eq.0) then
     write(*,'(A,$)')', (skipping 2D PDFs since mergechains=0), '
     plpdf2d = 0
  end if
  
  if(plpdf2d.ge.1) then
     call pdfs2d(exitcode)
     if(exitcode.ne.0) goto 9999
  end if !if(plpdf2d.eq.1)
  
  if(npdf2d.lt.0) then !Then we just plotted all 2D PDFs
     write(*,*)
  else
     if(prprogress.ge.1.and.update.eq.0) write(*,'(A,/)')'done.  '
  end if
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  !***********************************************************************************************************************************      
  !***********************************************************************************************************************************      
  !***********************************************************************************************************************************      
  
  
  
  
  timestamps(7) = timestamp(os)
  
  !Write statistics to file
  if(savestats.ge.1.and.nchains.gt.1) write(*,'(A)')' ******   Cannot write statistics if the number of chains is greater than one   ******'
  if(savestats.ge.1.and.nchains.eq.1) then
     call printstats(exitcode)
     if(exitcode.ne.0) goto 9999
     write(*,*)''
  end if !if(savestats.ge.1.and.nchains.eq.1) then
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  !***********************************************************************************************************************************      
  !***********************************************************************************************************************************      
  !***********************************************************************************************************************************      
  
  timestamps(8) = timestamp(os)
  
  if(plmovie.eq.1) then
     call animation(exitcode)
     if(exitcode.ne.0) goto 9999
  end if
  
  
  
  
  
  
  
  
  
  if(update.eq.1) then
     deallocate(pldat,alldat)
     call sleep(5)
     if(sum(ntot).gt.1.e4) call sleep(5)
     if(sum(ntot).gt.1.e5) call sleep(10)
     if(sum(ntot).gt.1.e6) call sleep(20)
     goto 101
  end if
  
  !write(*,'(A)')'  Waiting for you to finish me off...'
  !pause
  
9999 continue
  deallocate(pldat,alldat)
  !if(prprogress.ge.1) write(*,*)''
  
  timestamps(9) = timestamp(os)
  
  if(prprogress.ge.1) then
     write(*,'(A,$)')'  Run time: '
     write(*,'(A,F5.1,A,$)')'   input:',min(dabs(timestamps(2)-timestamps(1)),999.9),'s,'
     !write(*,'(A,F5.1,A,$)')'   info:',min(dabs(timestamps(3)-timestamps(2)),999.9),'s,'
     !write(*,'(A,F5.1,A,$)')'   stats:',min(dabs(timestamps(4)-timestamps(3)),999.9),'s,'
     write(*,'(A,F5.1,A,$)')'   stats:',min(dabs(timestamps(4)-timestamps(2)),999.9),'s,'
     if(plot.eq.1.and.pllogl+plchain+pljump+plsigacc+placorr.gt.0) then
        write(*,'(A,F5.1,A,$)')'   chains:',min(dabs(timestamps(5)-timestamps(4)),999.9),'s,'
     end if
     if(plot.eq.1.or.savepdf.ge.1) then
        if(plpdf1d.ge.1) write(*,'(A,F5.1,A,$)')'   1d pdfs:',min(dabs(timestamps(6)-timestamps(5)),999.9),'s,'
        if(plpdf2d.ge.1) write(*,'(A,F6.1,A,$)')'   2d pdfs:',min(dabs(timestamps(7)-timestamps(6)),999.9),'s,'
     end if
     !write(*,'(A,F6.1,A,$)')'   plots:',min(dabs(timestamps(7)-timestamps(4)),999.9),'s,'
     !write(*,'(A,F5.1,A,$)')'   save stats:',min(dabs(timestamps(8)-timestamps(7)),999.9),'s,'
     if(plmovie.eq.1) write(*,'(A,F5.1,A,$)')'   movie:',min(dabs(timestamps(9)-timestamps(8)),999.9),'s,'
     write(*,'(A,F6.1,A)')'   total:',min(dabs(timestamps(9)-timestamps(1)),999.9),'s.'
  end if
  
  write(*,*)''
end program analysemcmc
!************************************************************************************************************************************




