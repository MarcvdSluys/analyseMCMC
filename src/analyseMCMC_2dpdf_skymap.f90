!> \file analyseMCMC_2dpdf_skymap.f90  Routines to plot a 2D PDF on a sky map

! 
! LICENCE:
! 
! Copyright (c) 2007-2022  Marc van der Sluys, Vivien Raymond, Ben Farr, Chris Chambers
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
!> \brief  Plot a sky map
!!
!! \param bx10     RA boundary 1
!! \param bx20     RA boundary 2
!! \param by1      Dec boundary 1
!! \param by2      Dec boundary 2
!! \param raShift  Shift in RA needed to centre the PDF

subroutine plotthesky(bx10,bx20, by1,by2, raShift)
  use SUFR_kinds, only: double
  use SUFR_constants, only: homedir, pi2,r2d
  use SUFR_numerics, only: sne
  
  use analysemcmc_settings, only: fonttype,fontsize1d, mapProjection
  use general_data, only: raCentre
  
  implicit none
  real, intent(in) :: bx10,bx20, by1,by2, raShift
  
  integer, parameter :: ns=9110, nsn=80
  integer, allocatable :: c(:,:)
  integer :: i,j,nc,snr(nsn),plcst,plstar,spld,prslbl, status
  real(double), allocatable :: ra(:),dec(:)
  real(double) :: dx1,dx2,dy,ra1,dec1,drev2pi
  real :: bx1,bx2,vm(ns),x1,y1,x2,y2,constx(ns),consty(ns),r1,g1,b1,r4,g4,b4
  real :: schcon,sz1,schfac,schlbl,snlim,sllim,schmag,getmag,mag,x,y,mlim
  character, allocatable :: con(:)*(20), sn(:)*(10)
  character :: cn(ns)*(3),name*(10),snam(nsn)*(10),sni*(10),getsname*(10), bscdir*(99)
  
  allocate(c(ns,35), ra(ns),dec(ns), con(ns),sn(ns))
  
  bscdir = trim(homedir)//'/usr/lib'  ! Directory that contains bright-star catalogue and constellation data
  
  mlim = 6.            ! Magnitude limit for stars
  sllim = 2.5          ! Limit for labels
  snlim = 1.4          ! Limit for names
  fonttype = 2
  !schmag = 0.07       ! OK for white on black
  schmag = 0.12         ! Black on white
  schlbl = fontsize1d
  schfac = 1.
  schcon = 1.
  plstar = 1  ! 0-no, 1-yes no label, 2-symbol, 3-name, 4-name or symbol, 5-name and symbol
  plcst = 1   ! 0-no, 1-figures, 2-figures+abbreviations, 3-figures+names
  sz1 = 1.    ! CHECK Get rid of this variable?
  
  
  call pgqcr(1,r1,g1,b1)  ! Store colours
  call pgqcr(4,r4,g4,b4)
  !x = 1.0  ! White (for stars - black bg)
  !x = 0.0  ! Black (for stars - white bg)
  x = 0.5  ! Grey (for stars - white bg)
  call pgscr(1,x,x,x)  ! Star colour
  !x = 0.0  ! Black bg
  x = 0.5  ! White bg
  call pgscr(4,x,x,1.)    ! Blue (for constellations)
  
  bx1 = bx10
  bx2 = bx20
  if(bx1.gt.bx2) then
     x = bx1
     bx1 = bx2
     bx2 = x
  end if
  
  ! Read bright-star catalogue (BSC):
  open(unit=21,form='formatted',status='old',position='rewind',file=trim(bscdir)//'/bsc.dat', iostat=status)
  if(status.ne.0) then
     write(0,'(A)') '  * Warning: could not find bright-star catalogue in '//trim(bscdir)// &
          "/bsc.dat; I won't plot stars and constellations."
     return
  end if
  do i=1,ns
     !read(21,'(A10,1x,2F10.6,1x,2F7.3,I5,F6.2,F6.3,A2,A10)') name,ra(i),dec(i),pma,pmd,rv,vm(i),par,mult,var
     read(21,'(A10,1x,2F10.6,20x,F6.2)') name,ra(i),dec(i),vm(i)
     sn(i) = getsname(name)
     ra(i) = mod(ra(i)+raShift,pi2)-raShift
  end do
  close(21)
  
  ! Read constellation-figure data for BSC:
  open(unit=22,form='formatted',status='old',position='rewind',file=trim(bscdir)//'/bsc_const.dat', iostat=status)
  if(status.ne.0) then
     write(0,'(A)') "  * Warning: could not find constellation data; I won't plot constellations."
     plcst = 0
     nc = 0
  else
     do i=1,ns
        read(22,'(I4)',end=340,advance='no') c(i,1)
        do j=1,c(i,1)
           read(22,'(I5)',advance='no') c(i,j+1)
        end do
        read(22,'(1x,A3,A20)') cn(i),con(i)
        !Get mean star position to place const. name
        dx1 = 0.d0
        dx2 = 0.d0
        dy = 0.d0
        do j=2,c(i,1)
           dx1 = dx1 + sin(ra(c(i,j)))
           dx2 = dx2 + cos(ra(c(i,j)))
           dy = dy + dec(c(i,j))
        end do
        dx1 = (dx1 + sin(ra(c(i,j))))/real(c(i,1))
        dx2 = (dx2 + cos(ra(c(i,j))))/real(c(i,1))
        ra1 = drev2pi(atan2(dx1,dx2))
        dec1 = (dy + dec(c(i,j)))/real(c(i,1))
        !call eq2xy(ra1,dec1,l0,b0,x1,y1)
        !constx(i) = x1
        !consty(i) = y1
        !constx(i) = real(ra1*r2d)
        constx(i) = real((mod(ra1+raShift,pi2)-raShift)*r2d)
        consty(i) = real(dec1*r2d)
     end do
340  continue
     close(22)
     nc = i-1
  end if
  
  
  ! Read star names:
  open(unit=23,form='formatted',status='old',file=trim(bscdir)//'/bsc_names.dat', iostat=status)
  if(status.ne.0) then
     write(0,'(A)') "  * Warning: could not find star names; I won't use them."
     plstar = min(plstar,2)
  else
     do i=1,nsn
        read(23,'(I4,2x,A10)',end=350) snr(i),snam(i)
     end do
350  continue
     close(23)
  end if
  
  !! Read Milky Way data:
  !do f=1,5
  !   write(mwfname,'(A10,I1,A4)')'milkyway_s',f,'.dat'
  !   open(unit=24,form='formatted',status='old',file=trim(bscdir)//'data/'//mwfname)
  !   do i=1,mwn(f)
  !      read(24,'(F7.5,F9.5)')mwa(f,i),mwd(f,i)
  !      if(maptype.eq.1) call eq2az(mwa(f,i),mwd(f,i),agst)
  !      if(maptype.eq.2) call eq2ecl(mwa(f,i),mwd(f,i),eps)
  !   end do
  !end do
  !close(24)
  
  
  ! Plot constellation figures:
  if(plcst.gt.0) then
     !schcon = min(max(40./sz1,0.7),3.)
     call pgsch(schfac*schcon*schlbl)
     call pgscf(fonttype)
     call pgsci(4)
     call pgslw(2)
     do i=1,nc
        do j=2,c(i,1)
           !call eq2xy(ra(c(i,j)),dec(c(i,j)),l0,b0,x1,y1)
           !call eq2xy(ra(c(i,j+1)),dec(c(i,j+1)),l0,b0,x2,y2)
           x1 = real(ra(c(i,j))*r2d)
           y1 = real(dec(c(i,j))*r2d)
           x2 = real(ra(c(i,j+1))*r2d)
           y2 = real(dec(c(i,j+1))*r2d)
           
           if(mapProjection.ge.1) then
              x1 = mod(x1/15.-raCentre+12,24.)+raCentre-12.  ! d2h
              call project_skymap(x1,y1,raCentre,mapProjection)
              x1 = x1*15.  ! h2d
              
              x2 = mod(x2/15.-raCentre+12,24.)+raCentre-12.  ! d2h
              call project_skymap(x2,y2,raCentre,mapProjection)
              x2 = x2*15.  ! h2d
           end if
           
           if((x2-x1)**2+(y2-y1)**2.le.90.**2)  call pgline(2,(/x1,x2/),(/y1,y2/))  ! Not too far from centre and each other 
        end do
        if(constx(i).lt.bx1.or.constx(i).gt.bx2.or.consty(i).lt.by1.or.consty(i).gt.by2) cycle
        if(plcst.eq.2) call pgptxt(constx(i),consty(i),0.,0.5,cn(i))
        if(plcst.eq.3) call pgptxt(constx(i),consty(i),0.,0.5,con(i))
     end do
     call pgsch(schfac)
     call pgscf(fonttype)
  end if !if(plcst.gt.0) then
  
  
  ! Plot stars: BSC:
  spld = 0
  if(plstar.gt.0) then
     do i=1,ns
        if(vm(i).lt.mlim .and. sne(vm(i),0.)) then
           !call eq2xy(ra(i),dec(i),l0,b0,x,y)
           x = real(ra(i)*r2d)
           y = real(dec(i)*r2d)
           !if(x.lt.bx1.or.x.gt.bx2.or.y.lt.by1.or.y.gt.by2) cycle
           call pgsci(1)
           mag = getmag(vm(i),mlim)*schmag
           
           if(mapProjection.ge.1) then
              x = x/15.   ! d2h
              x = mod(x-raCentre+12,24.)+raCentre-12.
              call project_skymap(x,y,raCentre,mapProjection)
              x = x*15.  ! h2d
           end if
           call pgcirc(x,y,mag)
           
           !write(stdOut,'(3F10.3)')x,y,mag
           call pgsch(schfac*schlbl)
           sni = sn(i)
           !if(sni(1:1).eq.'\') call pgsch(schlbl*max(1.33,schfac))  !Greek letters need larger font
           if(sni(1:1).eq.char(92)) call pgsch(schlbl*max(1.33,schfac))  !Greek letters need larger font.
           !Char(92) is a \, but this way it doesn't mess up emacs' parentheses count
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
     if(plstar.ge.3)  then  ! Plot star proper names
        call pgsch(schfac*schlbl)
        do i=1,nsn
           if(vm(snr(i)).lt.max(snlim,1.4)) then   ! Regulus (1.35) will still be plotted
              x = real(ra(snr(i))*r2d)
              y = real(dec(snr(i))*r2d)
              if(x.lt.bx1.or.x.gt.bx2.or.y.lt.by1.or.y.gt.by2) cycle
              call pgtext(x+0.02*sz1,y-0.02*sz1,snam(i))
           end if
        end do
     end if !if(plstar.eq.3) then
  end if !if(plstar.gt.0) then
  
  
  ! Restore colours:
  call pgscr(1,r1,g1,b1)
  call pgscr(4,r4,g4,b4)
  
end subroutine plotthesky
!***********************************************************************************************************************************


!***********************************************************************************************************************************
!> \brief  Get star name from bsc info
!!
!! \param name  BSC star name

function getsname(name)
  use analysemcmc_settings, only: fonttype
  
  implicit none
  character, intent(in) :: name*(*)
  character :: getsname*(10),num*(3),grk*(3),gn*(1)
  
  num = name(1:3)
  grk = name(4:6)
  gn  = name(7:7)
  
  getsname = '          '
  if(grk.ne.'   ') then  !Greek letter
     if(fonttype.eq.2) then
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
     else
        if(grk.eq.'Alp') getsname = '\(0627)\u'//gn
        if(grk.eq.'Bet') getsname = '\(0628)\u'//gn
        if(grk.eq.'Gam') getsname = '\(0629)\u'//gn
        if(grk.eq.'Del') getsname = '\(0630)\u'//gn
        if(grk.eq.'Eps') getsname = '\(0631)\u'//gn
        if(grk.eq.'Zet') getsname = '\(0632)\u'//gn
        if(grk.eq.'Eta') getsname = '\(0633)\u'//gn
        if(grk.eq.'The') getsname = '\(0634)\u'//gn
        if(grk.eq.'Iot') getsname = '\(0635)\u'//gn
        if(grk.eq.'Kap') getsname = '\(0636)\u'//gn
        if(grk.eq.'Lam') getsname = '\(0637)\u'//gn
        if(grk.eq.'Mu ') getsname = '\(0638)\u'//gn
        if(grk.eq.'Nu ') getsname = '\(0639)\u'//gn
        if(grk.eq.'Xi ') getsname = '\(0640)\u'//gn
        if(grk.eq.'Omi') getsname = '\(0641)\u'//gn
        if(grk.eq.'Pi ') getsname = '\(0642)\u'//gn
        if(grk.eq.'Rho') getsname = '\(0643)\u'//gn
        if(grk.eq.'Sig') getsname = '\(0644)\u'//gn
        if(grk.eq.'Tau') getsname = '\(0645)\u'//gn
        if(grk.eq.'Ups') getsname = '\(0646)\u'//gn
        if(grk.eq.'Phi') getsname = '\(0647)\u'//gn
        if(grk.eq.'Chi') getsname = '\(0648)\u'//gn
        if(grk.eq.'Psi') getsname = '\(0649)\u'//gn
        if(grk.eq.'Ome') getsname = '\(0650)\u'//gn
     end if
  else  !Then number
     if(num(1:1).eq.' ') num = num(2:3)//' '
     if(num(1:1).eq.' ') num = num(2:3)//' '
     getsname = num//'       '
  end if
  
end function getsname
!***********************************************************************************************************************************


!***********************************************************************************************************************************
!> \brief  Determine size of stellar 'disc'
!!
!! \param m     Magnitude of the star
!! \param mlim  Limiting magnitude of the map

function getmag(m,mlim)
  real, intent(in) :: m,mlim
  real :: getmag,m1
  
  m1 = m
  if(m1.lt.-1.e-3) m1 = -sqrt(-m1)  ! Less excessive grow in diameter for the brightest objects
  getmag = max(mlim-m1+0.5,0.5)     ! Make sure the weakest stars are still plotted
  
end function getmag
!***********************************************************************************************************************************




!***********************************************************************************************************************************
!> \brief  Plot a projected image
!!
!! \param z     Binned data array
!!
!! \param nbx   Number of bins in the x-direction
!! \param nby   Number of bins in the y-direction
!! \param xb1   First bin to plot in the x-direction
!! \param xb2   Last bin to plot in the x-direction
!! \param yb1   First bin to plot in the y-direction
!! \param yb2   Last bin to plot in the y-direction 
!!
!! \param z1    Lowest array value, will appear in first colour (clr1)
!! \param z2    Highest array value, will appear in last colour (clr2)
!! \param clr1  First colour, use with lowest array valye (z1)
!! \param clr2  Last colour, use with lowest array valye (z1)
!!
!! \param tr
!! \param projection
!!
!! \note  Clone of pgimag, use projection if projection > 0

subroutine pgimag_project(z, nbx,nby, xb1,xb2, yb1,yb2, z1,z2, clr1,clr2, tr, projection)
  use SUFR_constants, only: rpi2
  use aM_constants, only: use_PLplot
  use general_data, only: raCentre
  
  implicit none
  integer, parameter :: nell=100
  integer, intent(in) :: nbx,nby, xb1,xb2, yb1,yb2, clr1,clr2, projection
  real, intent(in) :: z(nbx,nby), z1,z2, tr(6)
  
  real :: dz,dcdz
  real :: x,y,dx,dy,xs(5),ys(5),xell(nell),yell(nell),sch, ang
  integer :: i,ix,iy,dc,ci,lw
  character :: str*(99)
  
  
  call pgqch(sch)  ! Save current character height
  call pgsch(0.5*sch)
  
  dz = z2-z1
  dc = clr2-clr1
  dcdz = real(dc)/dz
  
  call pgbbuf()       ! Buffer output to speed up screen plotting
  dx = tr(2)/2.*1.05  ! Distance between pixel centres / 2 = half width of pixels
  dy = tr(6)/2.*1.05  ! Spaces between pixels seem to go away when multiplying with a factor between 1.02 and 1.04
  
  
  ! Loop over pixels (each dimension has one array row/column too many):
  do ix = xb1,xb2-1
     do iy = yb1,yb2-1
        
        !Get colour for this pixel:
        dz = z(ix,iy)-z1
        ci = min(clr1 + nint(dz*dcdz),clr2)
        if(ci.eq.clr1) cycle  ! Don't draw background pixels
        
        call pgsci(ci)
        
        ! Get central coordinates for this pixel:
        x = tr(1) + tr(2)*real(ix) + tr(3)*real(iy)
        y = tr(4) + tr(5)*real(ix) + tr(6)*real(iy)
        
        ! Get the coordinates of the four corners (projected rectangular pixel is not necessarily rectangular!):
        xs(1) = x-dx
        ys(1) = y-dy
        xs(2) = xs(1)
        ys(2) = y+dy
        xs(3) = x+dx
        ys(3) = ys(2)
        xs(4) = xs(3)
        ys(4) = ys(1)
        
        ! Do the projection:
        if(projection.ge.1) then
           do i=1,4
              call project_skymap(xs(i),ys(i),raCentre,projection)
           end do
        end if
        xs(5) = xs(1)
        ys(5) = ys(1)
        !Plot the pixel:
        call pgpoly(5,xs,ys)
        
     end do
  end do
  
  ! Draw lines on map:
  if(projection.eq.1) then
     
     ! Get data to plot ellipses:
     do i=1,nell
        x = real(i-1)/real(nell-1)*rpi2
        xell(i) = sin(x)
        yell(i) = cos(x)
     end do
     call pgsci(1)
     
     ! Angle under which to print text:
     ang = 0.
     if(use_PLplot) ang = 180.  ! Needed for sky map because RA decreases to the right
     
     ! Plot meridians:
     do i=-24,24,3  ! In hours
        call pgsci(14)
        if(i.eq.0.or.abs(i).eq.24) call pgsci(1) !Null-meridian in black
        if(real(i).gt.-raCentre-12.and.real(i).lt.-raCentre+12) then
           ! Plot line:
           x = -(raCentre+real(i))
           call pgline(nell/2+1,xell*x+raCentre,yell*90.)
           
           ! Print label:
           write(str,'(I2,A)')mod(48-i,24),'\uh\d'
           if(mod(48-i,24).lt.10) write(str,'(I1,A)')mod(48-i,24),'\uh\d'
           call pgptxt(x+raCentre-0.1, 2., ang, 0., trim(str))
        end if
     end do
     
     ! Plot lines of constant declination:
     do i=-90,90,15  !In degrees
        if(abs(i).eq.90) cycle
        call pgsci(14)
        if(i.eq.0) call pgsci(1)  ! Equator in black
        
        ! Get start and end point on line and project them:
        xs(1) = raCentre-12.
        xs(2) = raCentre+12.
        ys(1) = real(i)
        ys(2) = real(i)
        call project_skymap(xs(1),ys(1),raCentre,projection)
        call project_skymap(xs(2),ys(2),raCentre,projection)
        
        ! Plot line:
        call pgline(2,xs(1:2),ys(1:2))
        
        ! Print labels:
        if(i.gt.0) then
           write(str,'(A1,I2,A)')'+',i,'\(2218)'
           call pgptxt(xs(2)+0.2, ys(1), ang, 1., trim(str))
        else if(i.eq.0) then  ! Used to be in the <=0 case, seems to have caused segfaults when using PLplot and gfortran -O2 (?)
           write(str,'(I3,A)')i,'\(2218)'
           call pgptxt(xs(2)+0.4, ys(1)-2., ang, 1., trim(str))
        else
           write(str,'(I3,A)')i,'\(2218)'
           call pgptxt(xs(2)+0.4, ys(1)-2., ang, 1., trim(str))
        end if
     end do
     
     ! Overplot main lines:
     call pgsci(1)
     if(use_PLplot) then
        call pgmtxt('T',2.0,0.5,0.5,'+90\(2218)')                 ! NP
        call pgmtxt('B',2.0,0.5,0.5,'-90\(2218)')                 ! SP
        call pgmtxt('L',2.0,0.5,0.5,'0\(2218)')                   ! Equator
     else
        call pgptxt(raCentre,92.,0.,0.5,'+90\(2218)')             ! NP
        call pgptxt(raCentre,-95.,0.,0.5,'-90\(2218)')            ! SP
     end if
     call pgline(2,(/raCentre-12.,raCentre+12./),(/0.,0./))   ! Equator
     
     
     ! Plot null-meridian:
     do i=-24,24,24
        if(real(i).gt.-raCentre-12.and.real(i).lt.-raCentre+12) call pgline(nell/2+1,-(raCentre+real(i))*xell+raCentre,yell*90.)
     end do
     
     call pgqlw(lw)     !Save current line width
     call pgslw(lw*2)
     call pgline(nell,xell*12.+raCentre,yell*90.)             ! Outline
     call pgslw(lw)     !Restore line width
     
     
     
  end if  !if(projection.eq.1)
  
  call pgsch(sch)  ! Restore character height
  call pgebuf()      ! Release buffer
  
end subroutine pgimag_project
!***********************************************************************************************************************************




!***********************************************************************************************************************************
!> \brief  Project a sky map, using projection 'projection'
!!
!! \param x           X coordinate of object (I/O)
!! \param y           Y coordinate of object (I/O)
!! \param raCentre    Central RA of map
!! \param projection  Choice of projection:  1 - Mollweide
!!
!! \par
!! Projections:
!! - 1: Mollweide projection:
!!   - http://en.wikipedia.org/wiki/Mollweide_projection
!!   - Newton-Rapson scheme to solve equation:  2*theta + sin(2*theta) = pi*sin(y*rd2r)
!!   - Convergence is relatively fast, somewhat slower near poles

subroutine project_skymap(x,y,raCentre,projection)
  use SUFR_constants, only: stdErr, rd2r,rpi
  use SUFR_system, only: quit_program
  
  implicit none
  real, intent(inout) :: x,y
  real, intent(in) :: raCentre
  integer, intent(in) :: projection
  
  integer :: iter,maxIter
  real :: theta,siny,th2,dth2,delta
  
  
  if(projection.eq.1) then  ! Mollweide projection
     
     delta = 1.e-6        ! Radians
     maxIter = 100        ! 3 iterations typically suffice, need safety hatch anyway (e.g. when very close to/just beyond the pole)
     siny  = sin(y*rd2r)
     th2 = y*rd2r
     dth2 = 1.e30
     iter = 0
     
     do while(abs(dth2).gt.delta .and. iter.lt.maxIter)
        iter = iter + 1
        dth2 = -(th2 + sin(th2) - rpi*siny)/(1.+cos(th2))
        th2 = th2 + dth2
     end do
     
     theta = th2/2.
     
     ! Original projection:
     !x = 2*sqrt2/rpi * x * cos(theta)
     !y = sqrt(2) * sin(theta) * r2d
     
     ! Map it back to a 24hx180d plot:
     x = (x-raCentre) * cos(theta) + raCentre
     y = sin(theta)*90.
  else
     write(stdErr,'(A,I3)')'  ERROR:  Projection not defined:',projection
     call quit_program(' ')
  end if
  
end subroutine project_skymap
!***********************************************************************************************************************************


