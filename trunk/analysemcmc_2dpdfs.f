!Routines to compute and plot two-dimensional PDFs


subroutine pdfs2d(exitcode)
  use constants
  use analysemcmc_settings
  use general_data
  use mcmcrun_data
  use plot_data
  use stats_data
  !use pdf2d_data
  implicit none
  integer :: i,j,j1,j2,p1,p2,ic,lw,io,exitcode,c,system,pgopen
  integer :: npdf,ncont,lw2,plotthis,truerange2d,countplots,totplots
  real :: rev360,rev24
  real :: a,rat,cont(11),tr(6),sch,plx,ply
  real :: xmin,xmax,ymin,ymax,dx,dy,xx(nchs*narr1),yy(nchs*narr1),zz(nchs*narr1)
  real,allocatable :: z(:,:),zs(:,:,:)  !These depend on nbin2d, allocate after reading input file
  character :: string*99,str*99,tempfile*99
  
  exitcode = 0
  countplots = 0
  ic = 1 !Can only do one chain
  
  !Columns in dat(): 1:logL 2:mc, 3:eta, 4:tc, 5:logdl, 6:spin, 7:kappa, 8: RA, 9:sindec,10:phase, 11:sinthJ0, 12:phiJ0, 13:alpha, 14:M1, 15:M2
  j1 = 2
  j2 = npar
  
  if(prprogress.ge.1.and.plot.eq.0.and.savepdf.eq.1.and.plpdf1d.eq.0) write(*,'(A,$)')'  Saving'
  if(prprogress.ge.1.and.update.eq.0.and.npdf2d.ge.0) write(*,'(A,$)')'  2D pdfs: '
  if(npdf2d.lt.0) then
     totplots = 0
     do i=j1,j2
        totplots = totplots + i - j1
     end do
     if(prprogress.ge.1.and.update.eq.0) then
        if(totplots.lt.100) write(*,'(A,I2,A,/)')'  *ALL* (',totplots,') 2D pdfs: '
        if(totplots.ge.100) write(*,'(A,I3,A,/)')'  *ALL* (',totplots,') 2D pdfs: '
     end if
  end if
  

  
  
  !Autodetermine number of bins for 2D PDFs:
  if(nbin2dx.le.0) then
     if(totpts.le.100) then
        nbin2dx = floor(2*sqrt(real(totpts))/pltrat)
        nbin2dx = max(nbin2dx,5)
        nbin2dy = floor(2*sqrt(real(totpts)))           !Same as for 1D case (~50)
     else
        nbin2dx = floor(10*log10(real(totpts))/pltrat)  
        nbin2dx = max(nbin2dx,5)
        nbin2dy = floor(10*log10(real(totpts)))         !Same as for 1D case (~50)
     end if
     if(prprogress.ge.2.and.plot.eq.1.and.update.eq.0) then
        if(nbin2dx.lt.100) write(*,'(A1,I2,A1,$)')'(',nbin2dx,'x'
        if(nbin2dx.ge.100) write(*,'(A1,I3,A1,$)')'(',nbin2dx,'x'
        if(nbin2dy.lt.100) write(*,'(I2,A7,$)')nbin2dy,' bins) '
        if(nbin2dy.ge.100) write(*,'(I3,A7,$)')nbin2dy,' bins) '
     end if
  end if
  if(nbin2dy.eq.0) nbin2dy = nbin2dx
  if(nbin2dy.le.-1) nbin2dy = nbin2dx*pltrat
  
  !Allocate memory:
  allocate(z(nbin2dx+1,nbin2dy+1),zs(nchs,nbin2dx+1,nbin2dy+1))
  
  if(plot.eq.1) then
     if(file.eq.0) then
        lw = 1
        lw2 = 1
        sch = 1.5
     end if
     if(file.ge.1) then
        if(file.ge.2) io = pgopen('pdf2d.eps'//trim(psclr))
        lw = 3
        lw2 = 2 !Font lw
        sch = 1.5
        if(quality.eq.3) then !Poster
           lw = 4
           lw2 = 3 !Font lw
           sch = 2.
        end if
        if(pssz.lt.5) sch = sch * sqrt(5.0/pssz)
     end if
     if(file.ge.2.and.io.le.0) then
        write(*,'(A,I4)')'  Cannot open PGPlot device.  Quitting the programme',io
        exitcode = 1
        return
     end if
     if(file.ge.2) call pgpap(pssz,psrat)
     if(file.ge.2) call pgscf(2)
     if(file.gt.1) call pginitl(colour,file,whitebg)
  end if !if(plot.eq.1)
  
  if(plotsky.eq.1) then
     j1 = 8
     j2 = 9
  end if
  
  if(savepdf.eq.1) then
     open(unit=30,action='write',form='formatted',status='replace',file=trim(outputdir)//'/'//trim(outputname)//'__pdf2d.dat')
     write(30,'(5I6,T100,A)')j1,j2,1,nbin2dx,nbin2dy,'Plot variable 1,2, total number of chains, number of bins x,y'
  end if
  
  npdf=0 !Count iterations to open windows with different numbers
  do p1=j1,j2
     do p2=j1,j2
        
        if(npdf2d.ge.0) then
           plotthis = 0  !Determine to plot or save this combination of j1/j2 or p1/p2
           do i=1,npdf2d
              if(p1.eq.pdf2dpairs(i,1).and.p2.eq.pdf2dpairs(i,2)) plotthis = 1  !Use the data from the input file
           end do
           if(plotthis.eq.0) cycle
           if(prprogress.ge.1.and.update.eq.0) write(*,'(A,$)')trim(varnames(p1))//'-'//trim(varnames(p2))//' '
        else
           if(p2.le.p1) cycle
           write(6,*)upline !Move cursor up 1 line
           if(prprogress.ge.1.and.update.eq.0) write(*,'(F7.1,A)')real(countplots+1)/real(totplots)*100,'%    ('//trim(varnames(p1))//'-'//trim(varnames(p2))//')                                      '
        end if
        
        
        
        if(plot.eq.1) then
           if(file.eq.0) then
              npdf=npdf+1
              write(str,'(I3,A3)')200+npdf,'/xs'
              io = pgopen(trim(str))
              call pgpap(scrsz,scrrat)
              call pginitl(colour,file,whitebg)
           end if
           if(file.eq.1) then
              write(tempfile,'(A)') trim(outputname)//'__pdf2d__'//trim(varnames(p1))//'-'//trim(varnames(p2))//'.ppm'
              io = pgopen(trim(tempfile)//'/ppm')
              call pgpap(bmpsz,bmprat)
              call pginitl(colour,file,whitebg)
           end if
           if(file.lt.2.and.io.le.0) then
              write(*,'(A,I4)')'Cannot open PGPlot device.  Quitting the programme',io
              exitcode = 1
              return
           end if

           !call pgscr(3,0.,0.5,0.)
           call pgsch(sch)
        end if

        xmin = minval(alldat(ic,p1,1:n(ic)))
        xmax = maxval(alldat(ic,p1,1:n(ic)))
        ymin = minval(alldat(ic,p2,1:n(ic)))
        ymax = maxval(alldat(ic,p2,1:n(ic)))
        dx = xmax - xmin
        dy = ymax - ymin
        !write(*,'(A,2F10.5)')'  Xmin,Xmax: ',xmin,xmax
        !write(*,'(A,2F10.5)')'  Ymin,Ymax: ',ymin,ymax

        xx(1:n(ic)) = alldat(ic,p1,1:n(ic)) !Parameter 1
        yy(1:n(ic)) = alldat(ic,p2,1:n(ic)) !Parameter 2
        zz(1:n(ic)) = alldat(ic,1,1:n(ic))   !Likelihood

        if(plotsky.eq.0) then
           xmin = xmin - 0.05*dx
           xmax = xmax + 0.05*dx
           ymin = ymin - 0.05*dy
           ymax = ymax + 0.05*dy
        end if


        !Plot a cute sky map in 2D PDF
        if(plot.eq.1.and.plotsky.eq.1) then
           !xmax = 18.2!14.
           !xmin = 14.8!20.
           !ymin = 20.!0.
           !ymax = 50.!70.
           rat = 0.5 !scrrat !0.75
           !call pgpap(11.,rat)
           !call pgpap(scrsz,scrrat) !This causes a 'pgpage' when pggray is called...
           dx = xmax - xmin
           dy = ymax - ymin
           !print*,abs(dx)*15,dy/rat
           if(abs(dx)*15.lt.dy/rat) then !Expand x
              dx = dy/(15*rat)
              a = (xmin+xmax)*0.5
              xmin = a - 0.5*dx
              xmax = a + 0.5*dx
              if(prprogress.ge.1) write(*,'(A,F6.1,A3,F6.1,A,$)')'  Changing RA range to ',xmin,' - ',xmax,' h.'
           end if
           if(abs(dx)*15.gt.dy/rat) then !Expand y
              dy = abs(dx)*rat*15
              a = (ymin+ymax)*0.5
              ymin = a - 0.5*dy
              ymax = a + 0.5*dy
              if(prprogress.ge.1) write(*,'(A,F6.1,A3,F6.1,A,$)')'  Changing declination range to ',ymin,' - ',ymax,' deg.'
           end if
        end if !if(plotsky.eq.1)

        !Force plotting and binning boundaries
        !if(1.eq.2.and.p1.eq.8.and.p2.eq.9) then
        if(1.eq.1..and.wrapdata.eq.0.and.p1.eq.8.and.p2.eq.9) then
           xmin = 0.
           xmax = 24.
           ymin = -90.
           ymax = 90.

           !xmin = 10.35767
           !xmax = 14.83440
           !ymin = -32.63011
           !ymax = 31.75267
        end if


        !'Normalise' 2D PDF
        if(normpdf2d.le.2.or.normpdf2d.eq.4) then
           !call bindata2dold(n(ic),xx(1:n(ic)),yy(1:n(ic)),0,nbin2dx,nbin2dy,xmin,xmax,ymin,ymax,z,tr)  !Count number of chain elements in each bin
           call bindata2d(n(ic),xx(1:n(ic)),yy(1:n(ic)),0,nbin2dx,nbin2dy,xmin,xmax,ymin,ymax,z,tr)  !Compute bin number rather than find it, ~10x faster
           if(normpdf2d.eq.1) z = max(0.,log10(z + 1.e-30))
           if(normpdf2d.eq.2) z = max(0.,sqrt(z + 1.e-30))
           if(normpdf2d.eq.4) then
              call identify_2d_ranges(nival,ivals,nbin2dx+1,nbin2dy+1,z,prprogress) !Get 2D probability ranges; identify to which range each bin belongs
              call calc_2d_areas(p1,p2,changevar,nival,nbin2dx+1,nbin2dy+1,z,tr,probarea) !Compute 2D probability areas; sum the areas of all bins
              trueranges2d(p1,p2) = truerange2d(z,nbin2dx+1,nbin2dy+1,startval(1,p1,1),startval(1,p2,1),tr)
              !write(*,'(/,A23,2(2x,A21))')'Probability interval:','Equivalent diameter:','Fraction of a sphere:'
              do i=1,nival
                 if(prival.ge.1.and.prprogress.ge.2 .and. (p1.eq.8.and.p2.eq.9 .or. p1.eq.11.and.p2.eq.12)) then  !For sky position and orientation only
                    if(i.eq.1) write(*,*)
                    write(*,'(I10,F13.2,3(2x,F21.5))')i,ivals(i),probarea(i),sqrt(probarea(i)/pi)*2,probarea(i)*(pi/180.)**2/(4*pi)  !4pi*(180/pi)^2 = 41252.961 sq. degrees in a sphere
                 end if
                 probareas(p1,p2,i,1) = probarea(i)*(pi/180.)**2/(4*pi)  !Fraction of the sky
                 probareas(p1,p2,i,2) = sqrt(probarea(i)/pi)*2           !Equivalent diameter
                 probareas(p1,p2,i,3) = probarea(i)                      !Square degrees
              end do
              !write(*,'(A2,$)')'  '
           end if
        end if
        if(normpdf2d.eq.3) then
           call bindata2da(n(ic),xx(1:n(ic)),yy(1:n(ic)),zz(1:n(ic)),0,nbin2dx,nbin2dy,xmin,xmax,ymin,ymax,z,tr)  !Measure amount of likelihood in each bin
        end if


        !Swap RA boundaries for RA-Dec plot in 2D PDF
        if(p1.eq.8.and.p2.eq.9) then
           a = xmin
           xmin = xmax
           xmax = a
           dx = -dx
        end if

        z = z/(maxval(z)+1.e-30)

        if(plot.eq.1.and.plotsky.eq.1.and.file.ge.2) z = 1. - z !Invert grey scales


        !Plot 2D PDF
        if(plot.eq.1) then

           !Force plotting boundaries (not binning)
           if(1.eq.2.and.p1.eq.8.and.p2.eq.9) then
              xmin = 24.
              xmax = 0.
              ymin = -90.
              ymax = 90.

              xmin = 14.83440
              xmax = 10.35767
              ymin = -32.63011
              ymax = 31.75267
           end if

           call pgsch(sch)
           !call pgsvp(0.12,0.95,0.12,0.95)
           call pgsvp(0.08*sch,0.95,0.08*sch,0.95)
           call pgswin(xmin,xmax,ymin,ymax)
           if(plotsky.eq.1.and.file.ge.2) then !Need dark background
              !call pgsvp(0.,1.,0.,1.)
              !call pgswin(0.,1.,0.,1.)
              call pgsci(1)
              call pgrect(xmin,xmax,ymin,ymax)
              !call pgsci(0)
           end if

           !Plot the actual 2D PDF (grey scales or colour)
           if(plpdf2d.eq.1.or.plpdf2d.eq.2) then
              if(normpdf2d.lt.4) call pggray(z,nbin2dx+1,nbin2dy+1,1,nbin2dx+1,1,nbin2dy+1,1.,0.,tr)
              if(normpdf2d.eq.4) then
                 if(colour.eq.0) then
                    call pgscr(30,1.,1.,1.) !BG colour
                    if(nival.eq.2) then
                       call pgscr(31,0.5,0.5,0.5) !Grey
                       call pgscr(32,0.,0.,0.) !Black
                    end if
                    if(nival.eq.3) then
                       call pgscr(31,0.7,0.7,0.7) !
                       call pgscr(32,0.4,0.4,0.4) !
                       call pgscr(33,0.0,0.0,0.0) !
                    end if
                    if(nival.eq.4) then
                       call pgscr(31,0.75,0.75,0.75) !
                       call pgscr(32,0.50,0.50,0.50) !
                       call pgscr(33,0.25,0.25,0.25) !
                       call pgscr(34,0.00,0.00,0.00) !
                    end if
                    if(nival.eq.5) then
                       call pgscr(31,0.8,0.8,0.8) !
                       call pgscr(32,0.6,0.6,0.6) !
                       call pgscr(33,0.4,0.4,0.4) !
                       call pgscr(34,0.2,0.2,0.2) !
                       call pgscr(35,0.0,0.0,0.0) !
                    end if
                 end if
                 if(colour.ge.1) then
                    call pgscr(30,1.,1.,1.) !BG colour
                    if(nival.eq.2) then
                       call pgscr(31,1.,1.,0.) !Yellow
                       if(file.ge.2) call pgscr(31,0.8,0.7,0.) !Dark yellow
                       call pgscr(32,1.,0.,0.) !Red
                    end if
                    if(nival.eq.3) then
                       call pgscr(31,0.,0.,1.) !Blue
                       call pgscr(32,1.,1.,0.) !Yellow
                       if(file.ge.2) call pgscr(32,0.8,0.7,0.) !Dark yellow
                       !call pgscr(32,0.,1.,0.) !Green
                       call pgscr(33,1.,0.,0.) !Red
                    end if
                    if(nival.eq.4) then
                       call pgscr(31,0.,0.,1.) !Blue
                       call pgscr(32,0.,1.,0.) !Green
                       call pgscr(33,1.,1.,0.) !Yellow
                       if(file.ge.2) call pgscr(33,0.8,0.7,0.) !Dark yellow
                       !call pgscr(34,1.,0.5,0.) !Orange
                       call pgscr(34,1.,0.,0.) !Red
                    end if
                    if(nival.eq.5) then
                       call pgscr(31,0.,0.,1.) !Blue
                       call pgscr(32,0.,1.,0.) !Green
                       call pgscr(33,1.,1.,0.) !Yellow
                       if(file.ge.2) call pgscr(33,0.8,0.7,0.) !Dark yellow
                       call pgscr(34,1.,0.5,0.) !Orange
                       call pgscr(35,1.,0.,0.) !Red
                    end if
                 end if
                 call pgscir(30,30+nival)
                 call pgimag(z,nbin2dx+1,nbin2dy+1,1,nbin2dx+1,1,nbin2dy+1,0.,1.,tr)
              end if
           end if

           !Plot stars in 2D PDF (over the grey scales, but underneath contours, lines, etc)
           if(plotsky.eq.1) then
              call pgswin(xmin*15,xmax*15,ymin,ymax) !Map works in degrees
              call plotthesky(xmin*15,xmax*15,ymin,ymax,rashift)
              call pgswin(xmin,xmax,ymin,ymax)
           end if
           call pgsci(1)
        end if !if(plot.eq.1)


        !Plot contours in 2D PDF
        if((plpdf2d.eq.1.or.plpdf2d.eq.3) .and. plot.eq.1) then
           if(normpdf2d.lt.4) then
              ncont = 11
              do i=1,ncont
                 cont(i) = 0.01 + 2*real(i-1)/real(ncont-1)
                 if(plotsky.eq.1) cont(i) = 1.-cont(i)
              end do
              ncont = min(4,ncont) !Only use the first 4
           end if
           if(normpdf2d.eq.4) then
              ncont = nival
              do i=1,ncont
                 cont(i) = max(1. - real(i-1)/real(ncont-1),0.001)
                 !if(plotsky.eq.1) cont(i) = 1.-cont(i)
              end do
           end if

           call pgsls(1)
           if(plotsky.eq.0 .and. normpdf2d.ne.4) then !First in bg colour
              call pgslw(2*lw)
              call pgsci(0)
              !call pgcont(z,nbin2dx+1,nbin2dy+1,1,nbin2dx+1,1,nbin2dy+1,cont,4,tr)
              call pgcont(z,nbin2dx+1,nbin2dy+1,1,nbin2dx+1,1,nbin2dy+1,cont(1:ncont),ncont,tr)
           end if
           call pgslw(lw)
           call pgsci(1)
           if(plotsky.eq.1) call pgsci(7)
           call pgcont(z,nbin2dx+1,nbin2dy+1,1,nbin2dx+1,1,nbin2dy+1,cont(1:ncont),ncont,tr)
        end if


        !Save binned 2D PDF data
        if(savepdf.eq.1) then
           write(30,'(3I6,T100,A)')ic,p1,p2,'Chain number and variable number 1,2'
           write(30,'(2ES15.7,T100,A)')startval(ic,p1,1:2),'True and starting value p1'
           write(30,'(2ES15.7,T100,A)')startval(ic,p2,1:2),'True and starting value p2'
           write(30,'(6ES15.7,T100,A)')stats(ic,p1,1:6),'Stats: median, mean, absvar1, absvar2, stdev1, stdev2 for p1'
           write(30,'(6ES15.7,T100,A)')stats(ic,p2,1:6),'Stats: median, mean, absvar1, absvar2, stdev1, stdev2 for p2'
           write(30,'(5ES15.7,T100,A)')ranges(ic,c0,p1,1:5),'Ranges: lower,upper limit, centre, width, relative width for p1'
           write(30,'(5ES15.7,T100,A)')ranges(ic,c0,p2,1:5),'Ranges: lower,upper limit, centre, width, relative width for p2'
           write(30,'(4ES15.7,T100,A)')xmin,xmax,ymin,ymax,'Xmin,Xmax,Ymin,Ymax of PDF'
           write(30,'(6ES15.7,T100,A)')tr,'Tr'              
           do i=1,nbin2dx+1
              do j=1,nbin2dy+1
                 write(30,'(ES15.7,$)')z(i,j)
              end do
              write(30,'(1x)')
           end do
        end if



        !Plot true value, median, ranges, etc. in 2D PDF
        if(plot.eq.1) then
           call pgsci(1)

           !Plot max likelihood in 2D PDF
           if(pllmax.ge.1) then
              call pgsci(1); call pgsls(5)

              plx = pldat(icloglmax,p1,iloglmax)
              if(p1.eq.8) plx = rev24(plx)
              if(p1.eq.10.or.p1.eq.12.or.p1.eq.13) plx = rev360(plx)
              call pgline(2,(/plx,plx/),(/-1.e20,1.e20/)) !Max logL
              if(p1.eq.8) then
                 call pgline(2,(/plx-24.,plx-24./),(/-1.e20,1.e20/)) !Max logL
                 call pgline(2,(/plx+24.,plx+24./),(/-1.e20,1.e20/)) !Max logL
              end if
              if(p1.eq.10.or.p1.eq.12.or.p1.eq.13) then
                 call pgline(2,(/plx-360.,plx-360./),(/-1.e20,1.e20/)) !Max logL
                 call pgline(2,(/plx+360.,plx+360./),(/-1.e20,1.e20/)) !Max logL
              end if

              ply = pldat(icloglmax,p2,iloglmax)
              if(p2.eq.8) ply = rev24(ply)
              if(p2.eq.10.or.p2.eq.12.or.p2.eq.13) ply = rev360(ply)
              call pgline(2,(/-1.e20,1.e20/),(/ply,ply/)) !Max logL
              if(p2.eq.8) then
                 call pgline(2,(/-1.e20,1.e20/),(/ply-24.,ply-24./)) !Max logL
                 call pgline(2,(/-1.e20,1.e20/),(/ply+24.,ply+24./)) !Max logL
              end if
              if(p2.eq.10.or.p2.eq.12.or.p2.eq.13) then
                 call pgline(2,(/-1.e20,1.e20/),(/ply-360.,ply-360./)) !Max logL
                 call pgline(2,(/-1.e20,1.e20/),(/ply+360.,ply+360./)) !Max logL
              end if

              call pgpoint(1,plx,ply,12)
           end if


           if(plotsky.eq.1) call pgsci(0)
           call pgsls(2)

           !Plot true value in 2D PDF
           if(pltrue.ge.1.and.plotsky.eq.0) then
              !call pgline(2,(/startval(ic,p1,1),startval(ic,p1,1)/),(/-1.e20,1.e20/))
              !call pgline(2,(/-1.e20,1.e20/),(/startval(ic,p2,1),startval(ic,p2,1)/))

              if(mergechains.ne.1.or.ic.le.1) then !The units of the true values haven't changed (e.g. from rad to deg) for ic>1 (but they have for the starting values, why?)
                 !x
                 call pgsls(2); call pgsci(1)
                 plx = startval(ic,p1,1)
                 if(p1.eq.8) plx = rev24(plx)
                 if(p1.eq.10.or.p1.eq.12.or.p1.eq.13) plx = rev360(plx)
                 call pgline(2,(/plx,plx/),(/-1.e20,1.e20/)) !True value
                 if(p1.eq.8) then
                    call pgline(2,(/plx-24.,plx-24./),(/-1.e20,1.e20/)) !True value
                    call pgline(2,(/plx+24.,plx+24./),(/-1.e20,1.e20/)) !True value
                 end if
                 if(p1.eq.10.or.p1.eq.12.or.p1.eq.13) then
                    call pgline(2,(/plx-360.,plx-360./),(/-1.e20,1.e20/)) !True value
                    call pgline(2,(/plx+360.,plx+360./),(/-1.e20,1.e20/)) !True value
                 end if

                 !y
                 call pgsls(2); call pgsci(1)
                 ply = startval(ic,p2,1)
                 if(p2.eq.8) ply = rev24(ply)
                 if(p2.eq.10.or.p2.eq.12.or.p2.eq.13) ply = rev360(ply)
                 call pgline(2,(/-1.e20,1.e20/),(/ply,ply/)) !True value
                 if(p2.eq.8) then
                    call pgline(2,(/-1.e20,1.e20/),(/ply-24.,ply-24./)) !True value
                    call pgline(2,(/-1.e20,1.e20/),(/ply+24.,ply+24./)) !True value
                 end if
                 if(p2.eq.10.or.p2.eq.12.or.p2.eq.13) then
                    call pgline(2,(/-1.e20,1.e20/),(/ply-360.,ply-360./)) !True value
                    call pgline(2,(/-1.e20,1.e20/),(/ply+360.,ply+360./)) !True value
                 end if

                 call pgpoint(1,plx,ply,18)
              end if
           end if
           call pgsci(1)
           call pgsls(4)


           !Plot starting values in 2D PDF
           !call pgline(2,(/startval(ic,p1,2),startval(ic,p1,2)/),(/-1.e20,1.e20/))
           !call pgline(2,(/-1.e20,1.e20/),(/startval(ic,p2,2),startval(ic,p2,2)/))

           call pgsci(2)

           !Plot interval ranges in 2D PDF
           if(plrange.eq.2.or.plrange.eq.3) then
              call pgsls(1)
              call pgsch(sch*0.6)
              call pgsah(1,45.,0.1)
              a = 0.0166667*sch
              call pgarro(ranges(ic,c0,p1,3),ymin+dy*a,ranges(ic,c0,p1,1),ymin+dy*a)
              call pgarro(ranges(ic,c0,p1,3),ymin+dy*a,ranges(ic,c0,p1,2),ymin+dy*a)
              a = 0.0333333*sch
              call pgptxt(ranges(ic,c0,p1,3),ymin+dy*a,0.,0.5,'\(2030)\d90%\u')
              a = 0.0233333*sch
              call pgarro(xmin+dx*a,ranges(ic,c0,p2,3),xmin+dx*a,ranges(ic,c0,p2,1))
              call pgarro(xmin+dx*a,ranges(ic,c0,p2,3),xmin+dx*a,ranges(ic,c0,p2,2))
              a = 0.01*sch
              call pgptxt(xmin+dx*a,ranges(ic,c0,p2,3),90.,0.5,'\(2030)\d90%\u')
           end if

           call pgsch(sch)
           call pgsls(2)


           !Plot medians in 2D PDF
           if(plmedian.eq.2.or.plmedian.eq.3) then
              call pgline(2,(/stats(ic,p1,1),stats(ic,p1,1)/),(/-1.e20,1.e20/))
              call pgline(2,(/-1.e20,1.e20/),(/stats(ic,p2,1),stats(ic,p2,1)/))
              call pgpoint(1,stats(ic,p1,1),stats(ic,p2,1),18)
           end if
           
           call pgsls(1)
           
           
           !Big star at true position in 2D PDF
           if(plotsky.eq.1.and.pltrue.eq.1) then
              call pgsch(sch*2)
              call pgsci(9)
              call pgpoint(1,startval(ic,p1,1),startval(ic,p2,1),18)
              call pgsch(sch)
              call pgsci(1)
           end if
           
           
           
           
           
           !Plot coordinate axes and axis labels in 2D PDF
           call pgsls(1)
           call pgslw(lw2)
           if(plotsky.eq.1) then
              !call pgsci(0)
              call pgsci(1)
              call pgbox('BCNTS',0.0,0,'BCNTS',0.0,0) !Box, ticks, etc in white
              call pgsci(1)
              call pgbox('N',0.0,0,'N',0.0,0) !Number labels in black
           else
              call pgsci(1)
              call pgbox('BCNTS',0.0,0,'BCNTS',0.0,0)
           end if
           call pgmtxt('B',2.2,0.5,0.5,trim(pgvarns(p1)))
           call pgmtxt('L',1.7,0.5,0.5,trim(pgvarns(p2)))


           !Print 2D probability ranges in plot title
           if(prival.ge.1.and.normpdf2d.eq.4.and. ((p1.eq.8.and.p2.eq.9) .or. (p1.eq.12.and.p2.eq.11))) then  !For sky position and orientation only
              string = ' '
              do c = 1,nival
                 i = 3  !2-use degrees, 3-square degrees
                 a = probareas(p1,p2,c,i)
                 if(i.eq.2) then
                    if(a.lt.1.) then
                       write(string,'(F5.1,A2,F5.2,A7)')ivals(c)*100,'%:',a,'\(2218)'
                    else if(a.lt.10.) then
                       write(string,'(F5.1,A2,F4.1,A7)')ivals(c)*100,'%:',a,'\(2218)'
                    else if(a.lt.100.) then
                       write(string,'(F5.1,A2,F5.1,A7)')ivals(c)*100,'%:',a,'\(2218)'
                    else
                       write(string,'(F5.1,A2,I4,A7)')ivals(c)*100,'%:',nint(a),'\(2218)'
                    end if
                 end if
                 if(i.eq.3) then
                    call pgsch(sch*0.9) !Needed to fit the square-degree sign in
                    if(a.lt.1.) then
                       write(string,'(F5.1,A2,F5.2,A9)')ivals(c)*100,'%:',a,'deg\u2\d'
                    else if(a.lt.10.) then
                       write(string,'(F5.1,A2,F4.1,A9)')ivals(c)*100,'%:',a,'deg\u2\d'
                    else if(a.lt.100.) then
                       write(string,'(F5.1,A2,F5.1,A9)')ivals(c)*100,'%:',a,'deg\u2\d'
                    else if(a.lt.1000.) then
                       write(string,'(F5.1,A2,I4,A9)')ivals(c)*100,'%:',nint(a),'deg\u2\d'
                    else if(a.lt.10000.) then
                       write(string,'(F5.1,A2,I5,A9)')ivals(c)*100,'%:',nint(a),'deg\u2\d'
                    else
                       write(string,'(F5.1,A2,I6,A9)')ivals(c)*100,'%:',nint(a),'deg\u2\d'
                    end if
                 end if
                 a = (real(c-1)/real(nival-1) - 0.5)*0.7 + 0.5
                 call pgsci(30+nival+1-c)
                 call pgmtxt('T',0.5,a,0.5,trim(string))  !Print title
                 call pgsch(sch)
              end do
              call pgsci(1)
           end if
           
           countplots = countplots + 1  !The current plot is number countplots
           
           !Convert plot
           if(file.eq.1) then
              call pgend
              if(countplots.eq.npdf2d) then !Convert the last plot in the foreground, so that the process finishes before deleting the original file
                 i = system('convert -resize '//trim(bmpxpix)//' -depth 8 -unsharp '//trim(unsharppdf2d)//' '//trim(tempfile)//' '// &
                      trim(outputdir)//'/'//trim(outputname)//'__pdf2d__'//trim(varnames(p1))//'-'//trim(varnames(p2))//'.png')
              else !in the background
                 i = system('convert -resize '//trim(bmpxpix)//' -depth 8 -unsharp '//trim(unsharppdf2d)//' '//trim(tempfile)//' '// &
                      trim(outputdir)//'/'//trim(outputname)//'__pdf2d__'//trim(varnames(p1))//'-'//trim(varnames(p2))//'.png &')
              end if
              if(i.ne.0) write(*,'(A,I6)')'  Error converting plot',i
              !i = system('rm -f '//trim(tempfile))
           end if
           if(file.ge.2) call pgpage
        end if !if(plot.eq.1)
        
     end do !p2
  end do !p1
  
  
  if(savepdf.eq.1) close(30)
  
  if(plot.eq.1) then
     if(file.ne.1) call pgend
     if(file.ge.2) then
        if(abs(j2-j1).le.1) then
           if(file.eq.3) i = system('eps2pdf pdf2d.eps  -o '//trim(outputdir)//'/'//trim(outputname)//'__pdf2d_'//trim(varnames(j1))//'-'//trim(varnames(j2))//'.pdf  &> /dev/null')
           i = system('mv -f pdf2d.eps '//trim(outputdir)//'/'//trim(outputname)//'__pdf2d_'//trim(varnames(j1))//'-'//trim(varnames(j2))//'.eps')
        else
           if(file.eq.3) i = system('eps2pdf pdf2d.eps  -o '//trim(outputdir)//'/'//trim(outputname)//'__pdf2d.pdf  &> /dev/null')
           i = system('mv -f pdf2d.eps '//trim(outputdir)//'/'//trim(outputname)//'__pdf2d.eps')
        end if
     end if
     
     !Remove all the .ppm files
     if(file.eq.1) then
        do p1=j1,j2
           do p2=j1,j2
              if(npdf2d.ge.0) then
                 plotthis = 0  !Determine to plot or save this combination of j1/j2 or p1/p2
                 do i=1,npdf2d
                    if(p1.eq.pdf2dpairs(i,1).and.p2.eq.pdf2dpairs(i,2)) plotthis = 1  !Use the data from the input file
                 end do
                 if(plotthis.eq.0) cycle
              else
                 if(p2.le.p1) cycle
              end if
              write(tempfile,'(A)') trim(outputname)//'__pdf2d__'//trim(varnames(p1))//'-'//trim(varnames(p2))//'.ppm'
              i = system('rm -f '//trim(tempfile))
           end do
        end do
     end if
     
  end if !plot.eq.1
  
  
  
end subroutine pdfs2d
!************************************************************************************************************************************






!************************************************************************************************************************************
subroutine bindata2dold(n,x,y,norm,nxbin,nybin,xmin1,xmax1,ymin1,ymax1,z,tr)  !Count the number of points in each bin
  !x - input: data, n points
  !norm - input: normalise (1) or not (0)
  !nbin - input: number of bins
  !xmin, xmax - in/output: set xmin=xmax to auto-determine
  !xbin, ybin - output: binned data (x, y).  The x values are the left side of the bin!
  
  implicit none
  integer :: i,n,bx,by,nxbin,nybin,norm
  real :: x(n),y(n),xbin(nxbin+1),ybin(nybin+1),z(nxbin+1,nybin+1)
  real :: xmin,xmax,ymin,ymax,dx,dy,xmin1,xmax1,ymin1,ymax1,tr(6)
  
  !write(*,'(A4,5I8)')'n:',norm,nxbin,nybin
  !write(*,'(A4,2F8.3)')'x:',xmin1,xmax1
  !write(*,'(A4,2F8.3)')'y:',ymin1,ymax1
  
  xmin = xmin1
  xmax = xmax1
  ymin = ymin1
  ymax = ymax1
  
  if(abs(xmin-xmax)/(xmax+1.e-30).lt.1.e-20) then !Autodetermine
     xmin = minval(x(1:n))
     xmax = maxval(x(1:n))
  end if
  dx = abs(xmax - xmin)/real(nxbin)
  if(abs(ymin-ymax)/(ymax+1.e-30).lt.1.e-20) then !Autodetermine
     ymin = minval(y(1:n))
     ymax = maxval(y(1:n))
  end if
  dy = abs(ymax - ymin)/real(nybin)
  do bx=1,nxbin+1
     !xbin(bx) = xmin + (real(bx)-0.5)*dx  !x is the centre of the bin
     xbin(bx) = xmin + (bx-1)*dx          !x is the left of the bin
  end do
  do by=1,nybin+1
     !ybin(by) = ymin + (real(by)-0.5)*dy  !y is the centre of the bin
     ybin(by) = ymin + (by-1)*dy          !y is the left of the bin
  end do
  
  !write(*,'(50F5.2)'),x(1:50)
  !write(*,'(50F5.2)'),y(1:50)
  !write(*,'(20F8.5)'),xbin
  !write(*,'(20F8.5)'),ybin
  
  z = 0.
  !ztot = 0.
  do i=1,n
     bxl: do bx=1,nxbin
        do by=1,nybin
           if(x(i).ge.xbin(bx)) then
              if(x(i).lt.xbin(bx+1)) then
                 if(y(i).ge.ybin(by)) then
                    if(y(i).lt.ybin(by+1)) then
                       z(bx,by) = z(bx,by) + 1.
                       exit bxl !exit bx loop; if point i fits this bin, don't try other bins. Speeds things up ~2x
                    end if
                 end if
              end if
           end if
           
        end do !by
     end do bxl !bx
  end do !i
  !if(norm.eq.1) z = z/(ztot+1.e-30)
  if(norm.eq.1) z = z/maxval(z+1.e-30)
  
  if(abs(xmin1-xmax1)/(xmax1+1.e-30).lt.1.e-20) then
     xmin1 = xmin
     xmax1 = xmax
  end if
  if(abs(ymin1-ymax1)/(ymax1+1.e-30).lt.1.e-20) then
     ymin1 = ymin
     ymax1 = ymax
  end if
  
  !Determine transformation elements for pgplot (pggray, pgcont, pgimag)
  tr(1) = xmin - dx/2.
  tr(2) = dx
  tr(3) = 0.
  tr(4) = ymin - dy/2.
  tr(5) = 0.
  tr(6) = dy
  
end subroutine bindata2dold
!************************************************************************************************************************************


!************************************************************************************************************************************
subroutine bindata2d(n,x,y,norm,nxbin,nybin,xmin1,xmax1,ymin1,ymax1,z,tr)  !Compute bin number rather than search for it ~10x faster
  !x - input: data, n points
  !norm - input: normalise (1) or not (0)
  !nbin - input: number of bins
  !xmin, xmax - in/output: set xmin=xmax to auto-determine
  
  implicit none
  integer :: i,n,bx,by,nxbin,nybin,norm
  real :: x(n),y(n),z(nxbin+1,nybin+1)
  real :: xmin,xmax,ymin,ymax,dx,dy,xmin1,xmax1,ymin1,ymax1,tr(6)
  
  xmin = xmin1
  xmax = xmax1
  ymin = ymin1
  ymax = ymax1
  
  if(abs(xmin-xmax)/(xmax+1.e-30).lt.1.e-20) then !Autodetermine
     xmin = minval(x(1:n))
     xmax = maxval(x(1:n))
  end if
  dx = abs(xmax - xmin)/real(nxbin)
  if(abs(ymin-ymax)/(ymax+1.e-30).lt.1.e-20) then !Autodetermine
     ymin = minval(y(1:n))
     ymax = maxval(y(1:n))
  end if
  dy = abs(ymax - ymin)/real(nybin)
  
  
  
  !Determine transformation elements for pgplot (pggray, pgcont, pgimag)
  tr(1) = xmin - dx/2.
  tr(2) = dx
  tr(3) = 0.
  tr(4) = ymin - dy/2.
  tr(5) = 0.
  tr(6) = dy
  
  z = 0.
  do i=1,n
     bx = floor((x(i) - xmin)/dx) + 1 
     by = floor((y(i) - ymin)/dy) + 1
     if(bx.lt.1.or.bx.gt.nxbin.or.by.lt.1.or.by.gt.nybin) then
        if(bx.lt.0.or.bx.gt.nxbin+1.or.by.lt.0.or.by.gt.nybin+1) then  !Treat an error of 1 bin as round-off
           bx = max(min(bx,nxbin),1)
           by = max(min(by,nybin),1)
           z(bx,by) = z(bx,by) + 1.
        else
           if(bx.lt.0.or.bx.gt.nxbin+1) write(*,'(A,I7,A2,F8.3,A,I4,A,I4,A1)')'  Bindata2d:  error for X data point',i,' (',x(i),').  I found bin',bx,', but it should lie between 1 and',nxbin,'.'
           if(by.lt.0.or.by.gt.nybin+1) write(*,'(A,I7,A2,F8.3,A,I4,A,I4,A1)')'  Bindata2d:  error for Y data point',i,' (',y(i),').  I found bin',by,', but it should lie between 1 and',nybin,'.'
        end if
     else
        z(bx,by) = z(bx,by) + 1.
     end if
  end do
  
  !if(norm.eq.1) z = z/(ztot+1.e-30)
  if(norm.eq.1) z = z/maxval(z+1.e-30)
  
  if(abs(xmin1-xmax1)/(xmax1+1.e-30).lt.1.e-20) then
     xmin1 = xmin
     xmax1 = xmax
  end if
  if(abs(ymin1-ymax1)/(ymax1+1.e-30).lt.1.e-20) then
     ymin1 = ymin
     ymax1 = ymax
  end if
  
end subroutine bindata2d
!************************************************************************************************************************************


!************************************************************************************************************************************
subroutine bindata2da(n,x,y,z,norm,nxbin,nybin,xmin1,xmax1,ymin1,ymax1,zz,tr)  !Measure the amount of likelihood in each bin
  !x,y - input: data, n points
  !z - input: amount for each point (x,y)
  !norm - input: normalise (1) or not (0)
  !nxbin,nybin - input: number of bins in each dimension
  !xmin1,xmax1 - in/output: ranges in x dimension, set xmin=xmax as input to auto-determine
  !ymin1,ymax1 - in/output: ranges in y dimension, set ymin=ymax as input to auto-determine
  !zz - output: binned data zz(x,y).  The x,y values are the left side of the bin(?)
  !tr - output: transformation elements for pgplot (pggray, pgcont)
  
  implicit none
  integer :: i,n,bx,by,nxbin,nybin,norm
  real :: x(n),y(n),z(n),xbin(nxbin+1),ybin(nybin+1),zz(nxbin+1,nybin+1),zztot,xmin,xmax,ymin,ymax,dx,dy,xmin1,xmax1,ymin1,ymax1
  real :: tr(6),zmin
  
  !write(*,'(A4,5I8)')'n:',norm,nxbin,nybin
  !write(*,'(A4,2F8.3)')'x:',xmin1,xmax1
  !write(*,'(A4,2F8.3)')'y:',ymin1,ymax1
  
  xmin = xmin1
  xmax = xmax1
  ymin = ymin1
  ymax = ymax1
  zmin = minval(z)
  
  if(abs(xmin-xmax)/(xmax+1.e-30).lt.1.e-20) then !Autodetermine
     xmin = minval(x(1:n))
     xmax = maxval(x(1:n))
  end if
  dx = abs(xmax - xmin)/real(nxbin)
  if(abs(ymin-ymax)/(ymax+1.e-30).lt.1.e-20) then !Autodetermine
     ymin = minval(y(1:n))
     ymax = maxval(y(1:n))
  end if
  dy = abs(ymax - ymin)/real(nybin)
  do bx=1,nxbin+1
     !xbin(bx) = xmin + (real(bx)-0.5)*dx  !x is the centre of the bin
     xbin(bx) = xmin + (bx-1)*dx          !x is the left of the bin
  end do
  do by=1,nybin+1
     !ybin(by) = ymin + (real(by)-0.5)*dy  !y is the centre of the bin
     ybin(by) = ymin + (by-1)*dy          !y is the left of the bin
  end do
  
  !write(*,'(50F5.2)'),x(1:50)
  !write(*,'(50F5.2)'),y(1:50)
  !write(*,'(20F8.5)'),xbin
  !write(*,'(20F8.5)'),ybin
  
  zz = 0.
  zztot = 0.
  !print*,xmin,xmax
  !print*,ymin,ymax
  do bx=1,nxbin
     !print*,bx,xbin(bx),xbin(bx+1)
     do by=1,nybin
        zz(bx,by) = 0.
        do i=1,n
           !if(x(i).ge.xbin(bx).and.x(i).lt.xbin(bx+1) .and. y(i).ge.ybin(by).and.y(i).lt.ybin(by+1)) zz(bx,by) = zz(bx,by) + 1.
           if(x(i).ge.xbin(bx).and.x(i).lt.xbin(bx+1) .and. y(i).ge.ybin(by).and.y(i).lt.ybin(by+1)) zz(bx,by) = zz(bx,by) + exp(z(i) - zmin)
           !write(*,'(2I4,8F10.5)')bx,by,x(i),xbin(bx),xbin(bx+1),y(i),ybin(by),ybin(by+1),zz(bx,by),z(i)
        end do
        zztot = zztot + zz(bx,by) 
        !write(*,'(2I4,5x,4F6.3,5x,10I8)')bx,by,xbin(bx),xbin(bx+1),ybin(by),ybin(by+1),nint(zz(bx,by))
     end do
     !write(*,'(I4,5x,2F6.3,5x,10I8)')bx,xbin(bx),xbin(bx+1),nint(zz(bx,1:nybin))
     end do
  !if(norm.eq.1) z = z/(zztot+1.e-30)
  if(norm.eq.1) z = z/maxval(z+1.e-30)
  
  if(abs(xmin1-xmax1)/(xmax1+1.e-30).lt.1.e-20) then
     xmin1 = xmin
     xmax1 = xmax
  end if
  if(abs(ymin1-ymax1)/(ymax1+1.e-30).lt.1.e-20) then
     ymin1 = ymin
     ymax1 = ymax
  end if
  
  !Determine transformation elements for pgplot (pggray, pgcont)
  tr(1) = xmin - dx/2.
  tr(2) = dx
  tr(3) = 0.
  tr(4) = ymin - dy/2.
  tr(5) = 0.
  tr(6) = dy
  
end subroutine bindata2da
!************************************************************************************************************************************






!************************************************************************************************************************************
subroutine plotthesky(bx1,bx2,by1,by2,rashift)
  implicit none
  integer, parameter :: ns=9110, nsn=80
  integer :: i,j,c(100,35),nc,snr(nsn),plcst,plstar,cf,spld,n,prslbl,rv
  real*8 :: ra(ns),dec(ns),d2r,r2d,r2h,pi,tpi,dx1,dx2,dy,ra1,dec1,rev,par
  real :: pma,pmd,vm(ns),x1,y1,x2,y2,constx(99),consty(99),r1,g1,b1,r4,g4,b4
  real :: schcon,sz1,schfac,schlbl,prinf,snlim,sllim,schmag,getmag,mag,bx1,bx2,by1,by2,x,y,mlim,rashift
  character :: cn(100)*3,con(100)*20,name*10,vsopdir*99,sn(ns)*10,snam(nsn)*10,sni*10,getsname*10,mult,var*9
  
  mlim = 6.
  cf = 2
  schmag = 0.07
  schlbl = 1.
  schfac = 1.
  schcon = 1.
  plstar = 1  !0-no, 1-yes no label, 2-symbol, 3-name, 4-name or symbol, 5-name and symbol
  plcst = 2   !0-no, 1-figures, 2-figures+abbreviations, 3-figures+names
  
  prinf = 150.**2
  
  x = 0.
  call pgqcr(1,r1,g1,b1) !Store colours
  call pgqcr(4,r4,g4,b4)
  call pgscr(1,1.,1.,1.) !'White' (for stars)
  call pgscr(4,x,x,1.) !Blue (for constellations)
  
  pi = 4*datan(1.d0)
  tpi = 2*pi
  d2r = pi/180.d0
  r2d = 180.d0/pi
  r2h = 12.d0/pi
  r2h = r2d
  
  
  if(bx1.gt.bx2) then
     x = bx1
     bx1 = bx2
     bx2 = x
  end if
  
  !Read BSC
  vsopdir = '/home/sluys/diverse/popular/TheSky/'           !Linux pc
  open(unit=20,form='formatted',status='old',file=trim(vsopdir)//'data/bsc.dat')
  rewind(20)
  do i=1,ns
     read(20,320)name,ra(i),dec(i),pma,pmd,rv,vm(i),par,mult,var
320  format(A10,1x,2F10.6,1x,2F7.3,I5,F6.2,F6.3,A2,A10)
     sn(i) = getsname(name)
     ra(i) = mod(ra(i)+rashift,tpi)-rashift
  end do
  close(20)


  !Read Constellation figure data
  open(unit=40,form='formatted',status='old',file=trim(vsopdir)//'data/bsc_const.dat')
  do i=1,ns
     read(40,'(I4)',end=340,advance='no')c(i,1)
     do j=1,c(i,1)
        read(40,'(I5)',advance='no')c(i,j+1)
     end do
     read(40,'(1x,A3,A20)')cn(i),con(i)
     !Get mean star position to place const. name
     dx1 = 0.d0
     dx2 = 0.d0
     dy = 0.d0
     do j=2,c(i,1)
        dx1 = dx1 + dsin(ra(c(i,j)))
        dx2 = dx2 + dcos(ra(c(i,j)))
        dy = dy + dec(c(i,j))
     end do
     dx1 = (dx1 + dsin(ra(c(i,j))))/real(c(i,1))
     dx2 = (dx2 + dcos(ra(c(i,j))))/real(c(i,1))
     ra1 = rev(datan2(dx1,dx2))
     dec1 = (dy + dec(c(i,j)))/real(c(i,1))
     !call eq2xy(ra1,dec1,l0,b0,x1,y1)
     !constx(i) = x1
     !consty(i) = y1
     !constx(i) = real(ra1*r2h)
     constx(i) = real((mod(ra1+rashift,tpi)-rashift)*r2h)
     consty(i) = real(dec1*r2d)
  end do
340 close(40)
  nc = i-1
  
  !Read Star names
  open(unit=50,form='formatted',status='old',file=trim(vsopdir)//'data/bsc_names.dat')
  do i=1,nsn
     read(50,'(I4,2x,A10)',end=350)snr(i),snam(i)
  end do
350 close(50)
  
  
  !!Read Milky Way data
  !do f=1,5
  !   write(mwfname,'(A10,I1,A4)')'milkyway_s',f,'.dat'
  !   open(unit=60,form='formatted',status='old',file=trim(vsopdir)//'data/'//mwfname)
  !   do i=1,mwn(f)
  !      read(60,'(F7.5,F9.5)')mwa(f,i),mwd(f,i)
  !      if(maptype.eq.1) call eq2az(mwa(f,i),mwd(f,i),agst)
  !      if(maptype.eq.2) call eq2ecl(mwa(f,i),mwd(f,i),eps)
  !   end do
  !end do
  !close(60)
  
  
  !Plot constellation figures
  if(plcst.gt.0) then
     !schcon = min(max(40./sz1,0.7),3.)
     call pgsch(schfac*schcon*schlbl)
     call pgscf(cf)
     call pgsci(4)
     call pgslw(2)
     do i=1,nc
        do j=2,c(i,1)
           !call eq2xy(ra(c(i,j)),dec(c(i,j)),l0,b0,x1,y1)
           !call eq2xy(ra(c(i,j+1)),dec(c(i,j+1)),l0,b0,x2,y2)
           x1 = real(ra(c(i,j))*r2h)
           y1 = real(dec(c(i,j))*r2d)
           x2 = real(ra(c(i,j+1))*r2h)
           y2 = real(dec(c(i,j+1))*r2d)
           !if((x1*x1+y1*y1.le.prinf.or.x2*x2+y2*y2.le.prinf).and.(x2-x1)**2+(y2-y1)**2.le.90.**2) & !Not too far from centre and each other 
           if((x2-x1)**2+(y2-y1)**2.le.90.**2) & !Not too far from centre and each other 
                call pgline(2,(/x1,x2/),(/y1,y2/))
	end do
        if(constx(i).lt.bx1.or.constx(i).gt.bx2.or.consty(i).lt.by1.or.consty(i).gt.by2) cycle
        if(plcst.eq.2) call pgptext(constx(i),consty(i),0.,0.5,cn(i))
        if(plcst.eq.3) call pgptext(constx(i),consty(i),0.,0.5,con(i))
     end do
     call pgsch(schfac)
     call pgscf(cf)
  end if !if(plcst.gt.0) then
  
  !Plot stars: BSC
  spld = 0
  if(plstar.gt.0) then
     n = 0
     do i=1,ns
        if(vm(i).lt.mlim.and.vm(i).ne.0.) then
           !call eq2xy(ra(i),dec(i),l0,b0,x,y)
           x = real(ra(i)*r2h)
           y = real(dec(i)*r2d)
           if(x.lt.bx1.or.x.gt.bx2.or.y.lt.by1.or.y.gt.by2) cycle
           call pgsci(1)
           mag = getmag(vm(i),mlim)*schmag
           call pgcirc(x,y,mag)
           !write(*,'(3F10.3)')x,y,mag
           call pgsch(schfac*schlbl)
           sni = sn(i)
           !if(sni(1:1).eq.'\') call pgsch(schlbl*max(1.33,schfac))  !Greek letters need larger font
           if(sni(1:1).eq.char(92)) call pgsch(schlbl*max(1.33,schfac))  !Greek letters need larger font.  Char(92) is a \, but this way it doesn't mess up emacs' parentheses count
	   call pgsci(14)
           if(vm(i).lt.sllim) then
              if((plstar.eq.2.or.plstar.eq.5)) call pgtext(x+0.02*sz1,y+0.02*sz1,sn(i))
              if(plstar.eq.4) then !Check if the name will be printed
                 prslbl = 1
                 if(vm(i).lt.snlim) then
                    do j=1,nsn
                       if(snr(j).eq.i) prslbl = 0 !Then the name will be printed, don't print the symbol
                    end do
                 end if
                 if(prslbl.eq.1) call pgtext(x+0.02*sz1,y+0.02*sz1,sn(i))
              end if
           end if
	   spld = spld+1
	end if
     end do
     if(plstar.ge.3) then !Plot star proper names
        call pgsch(schfac*schlbl)
        do i=1,nsn
           if(vm(snr(i)).lt.max(snlim,1.4)) then  !Regulus (1.35) will still be plotted, for conjunction maps
              !call eq2xy(ra(snr(i)),dec(snr(i)),l0,b0,x,y)
              x = real(ra(snr(i))*r2h)
              y = real(dec(snr(i))*r2d)
              if(x.lt.bx1.or.x.gt.bx2.or.y.lt.by1.or.y.gt.by2) cycle
              call pgtext(x+0.02*sz1,y-0.02*sz1,snam(i))
           end if
        end do
     end if !if(plstar.eq.3) then
  end if !if(plstar.gt.0) then
  
  !Restore colours
  call pgscr(1,r1,g1,b1)
  call pgscr(4,r4,g4,b4)
  
end subroutine plotthesky
!************************************************************************************************************************************

!************************************************************************
function getsname(name)               !Get star name from bsc info
  implicit none
  character :: getsname*10,name*10,num*3,grk*3,gn*1
  num = name(1:3)
  grk = name(4:6)
  gn  = name(7:7)
  !      gn = ' '
  
  getsname = '          '
  if(grk.ne.'   ') then  !Greek letter
     if(grk.eq.'Alp') getsname = '\(2127)\u'//gn
     if(grk.eq.'Bet') getsname = '\(2128)\u'//gn
     if(grk.eq.'Gam') getsname = '\(2129)\u'//gn
     if(grk.eq.'Del') getsname = '\(2130)\u'//gn
     if(grk.eq.'Eps') getsname = '\(2131)\u'//gn
     if(grk.eq.'Zet') getsname = '\(2132)\u'//gn
     if(grk.eq.'Eta') getsname = '\(2133)\u'//gn
     if(grk.eq.'The') getsname = '\(2134)\u'//gn
     if(grk.eq.'Iot') getsname = '\(2135)\u'//gn
     if(grk.eq.'Kap') getsname = '\(2136)\u'//gn
     if(grk.eq.'Lam') getsname = '\(2137)\u'//gn
     if(grk.eq.'Mu ') getsname = '\(2138)\u'//gn
     if(grk.eq.'Nu ') getsname = '\(2139)\u'//gn
     if(grk.eq.'Xi ') getsname = '\(2140)\u'//gn
     if(grk.eq.'Omi') getsname = '\(2141)\u'//gn
     if(grk.eq.'Pi ') getsname = '\(2142)\u'//gn
     if(grk.eq.'Rho') getsname = '\(2143)\u'//gn
     if(grk.eq.'Sig') getsname = '\(2144)\u'//gn
     if(grk.eq.'Tau') getsname = '\(2145)\u'//gn
     if(grk.eq.'Ups') getsname = '\(2146)\u'//gn
     if(grk.eq.'Phi') getsname = '\(2147)\u'//gn
     if(grk.eq.'Chi') getsname = '\(2148)\u'//gn
     if(grk.eq.'Psi') getsname = '\(2149)\u'//gn
     if(grk.eq.'Ome') getsname = '\(2150)\u'//gn
  else  !Then number
     if(num(1:1).eq.' ') num = num(2:3)//' '
     if(num(1:1).eq.' ') num = num(2:3)//' '
     getsname = num//'       '
  end if
  return
end function getsname
!************************************************************************

!************************************************************************
function getmag(m,mlim)  !Determine size of stellar 'disk'
  real :: getmag,m,m1,mlim
  m1 = m
  !      if(m1.lt.0.) m1 = m1*0.5  !Less excessive grow in diameter for the brightest objects
  if(m1.lt.-1.e-3) m1 = -sqrt(-m1)  !Less excessive grow in diameter for the brightest objects
  !getmag = max(mlim-m1+0.5,0.)
  getmag = max(mlim-m1+0.5,0.5) !Make sure the weakest stars are still plotted
  !getmag = max(mlim-m1+0.5,0.)+0.5
  return
end function getmag
!************************************************************************




!************************************************************************
subroutine identify_2d_ranges(ni,ivals,nx,ny,z,prprogress)
  !Get the 2d probability intervals; z lies between 1 (in 100% range) and ni (in lowest-% range, e.g. 90%)
  implicit none
  integer :: ni,nx,ny,nn,indx(nx*ny),i,b,ib,full(ni),prprogress
  real :: ivals(ni),z(nx,ny),x1(nx*ny),x2(nx*ny),tot,np
  
  nn = nx*ny
  x1 = reshape(z,(/nn/))  !x1 is the 1D array with the same data as the 2D array z
  call rindexx(nn,-x1(1:nn),indx(1:nn)) ! -x1: sort descending
  
  np = sum(z)
  tot = 0.
  full = 0
  do b=1,nn !Loop over bins in 1D array
     ib = indx(b)
     x2(ib) = 0.
     if(x1(ib).eq.0.) cycle
     tot = tot + x1(ib)
     do i=ni,1,-1 !Loop over intervals
        if(tot.le.np*ivals(i)) then
           x2(ib) = real(ni-i+1)  !e.g. x2(b) = ni if within 68%, ni-1 if within 95%, etc, and 1 if within 99.7%
        else
           if(prprogress.ge.3.and.full(i).eq.0) then !Report the number of points in the lastly selected bin
              if(i.eq.1) write(6,'(A,$)')'Last bin:'
              !write(6,'(F6.3,I5,$)')ivals(i),nint(x1(ib))
              write(6,'(I5,$)')nint(x1(ib))
              full(i) = 1
           end if
        end if
        !write(*,'(2I4, F6.2, 3F20.5)')b,i, ivals(i), np,tot,np*ivals(i)
     end do
  end do
  
  z = reshape(x2, (/nx,ny/))  ! z lies between 1 and ni
end subroutine identify_2d_ranges
!************************************************************************



!************************************************************************
!Compute 2D probability areas
subroutine calc_2d_areas(p1,p2,changevar,ni,nx,ny,z,tr,area)
  implicit none
  integer :: p1,p2,changevar,ni,nx,ny,ix,iy,i,i1,iv
  real :: z(nx,ny),tr(6),y,dx,dy,d2r,area(ni)
  
  d2r = atan(1.)/45.
  area = 0.
  
  !print*,ni,nx,ny
  do ix = 1,nx
     do iy = 1,ny
        dx = tr(2)
        dy = tr(6)
        if(changevar.eq.1 .and. (p1.eq.8.and.p2.eq.9 .or. p1.eq.12.and.p2.eq.11) ) then !Then: RA-Dec or phi/theta_Jo plot, convert lon -> lon * 15 * cos(lat)
           !x = tr(1) + tr(2)*ix + tr(3)*iy
           !y = tr(4) + tr(5)*ix + tr(6)*iy
           y = tr(4) + tr(6)*iy
           if(p1.eq.8) then
              dx = dx*cos(y*d2r)
           else if(p1.eq.12) then
              dx = dx*abs(sin(y*d2r))  !Necessary for i-psi plot?
           end if
           !print*,p1,y,cos(y*d2r)
           if(p1.eq.8) dx = dx*15
        end if
        iv = nint(z(ix,iy))
        !if(iv.gt.0) area(iv) = area(iv) + dx*dy
        do i=1,ni
           if(iv.ge.i) then
              i1 = ni-i+1
              area(i1) = area(i1) + dx*dy
           end if
        end do
        !if(iv.eq.3) write(*,'(7F10.2)')x,y,dx,dy,dx*dy,z(ix,iy),area(iv)
     end do
  end do
end subroutine calc_2d_areas
!************************************************************************


!************************************************************************
function truerange2d(z,nx,ny,truex,truey,tr)
  !Get the smallest probability area in which the true values lie
  implicit none
  integer :: nx,ny,ix,iy,truerange2d
  real :: truex,truey,z(nx,ny),tr(6)
  
  !x = tr(1) + tr(2)*ix + tr(3)*iy
  !y = tr(4) + tr(5)*ix + tr(6)*iy
  ix = floor((truex - tr(1))/tr(2))
  iy = floor((truey - tr(4))/tr(6))
  if(ix.lt.1.or.ix.gt.nx.or.iy.lt.1.or.iy.gt.ny) then
     truerange2d = 0
  else
     truerange2d = nint(z(ix,iy))
  end if
end function truerange2d
!************************************************************************


