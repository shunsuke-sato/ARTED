!
!  Copyright 2016 ARTED developers
!
!  Licensed under the Apache License, Version 2.0 (the "License");
!  you may not use this file except in compliance with the License.
!  You may obtain a copy of the License at
!
!      http://www.apache.org/licenses/LICENSE-2.0
!
!  Unless required by applicable law or agreed to in writing, software
!  distributed under the License is distributed on an "AS IS" BASIS,
!  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
!  See the License for the specific language governing permissions and
!  limitations under the License.
!
!This file is "init.f90"
!This file conatain one soubroutine.
!SUBROUTINE init
!--------10--------20--------30--------40--------50--------60--------70--------80--------90--------100-------110-------120--------130
Subroutine init
  use Global_Variables
  implicit none
  integer :: i,n,ix,iy,iz,nx,ny,nz,ib,ik
  integer :: ixt,iyt,izt

  n=0
  do ix=0,NLx-1
  do iy=0,NLy-1
  do iz=0,NLz-1
    n=n+1
    Lx(n)=ix; Ly(n)=iy; Lz(n)=iz
    Lxyz(ix,iy,iz)=n
  enddo
  enddo
  enddo
  do i=1,NL
    do n=-Nd,Nd
      ifdx(n,i)=Lxyz(mod(Lx(i)+n+NLx,NLx),Ly(i),Lz(i))
      ifdy(n,i)=Lxyz(Lx(i),mod(Ly(i)+n+NLy,NLy),Lz(i))
      ifdz(n,i)=Lxyz(Lx(i),Ly(i),mod(Lz(i)+n+NLz,NLz))
    end do
  end do

  n=0
  do ix=-NLx/2,NLx/2-1
  do iy=-NLy/2,NLy/2-1
  do iz=-NLz/2,NLz/2-1
    n=n+1
    if(ix*ix+iy*iy+iz*iz == 0) nGzero=n
    Gx(n)=ix*bLx; Gy(n)=iy*bLy; Gz(n)=iz*bLz
  enddo
  enddo
  enddo

  n=0
  do nx=-NLx/2,NLx/2-1
  do ny=-NLy/2,NLy/2-1
  do nz=-NLz/2,NLz/2-1
    n=n+1
    nxyz(nx,ny,nz)=n
  enddo
  enddo
  enddo

  do ix=0,NLx-1
    do nx=-NLx/2,NLx/2-1
      eGx(nx,ix)=exp(zI*(2*Pi*ix*nx/dble(NLx)))
      eGxc(nx,ix)=conjg(eGx(nx,ix))
    end do
  end do
  do iy=0,NLy-1
    do ny=-NLy/2,NLy/2-1
      eGy(ny,iy)=exp(zI*(2*Pi*iy*ny/dble(NLy)))
      eGyc(ny,iy)=conjg(eGy(ny,iy))
    end do
  end do
  do iz=0,NLz-1
    do nz=-NLz/2,NLz/2-1
      eGz(nz,iz)=exp(zI*(2*Pi*iz*nz/dble(NLz)))
      eGzc(nz,iz)=conjg(eGz(nz,iz))
    end do
  end do

  Select case(Sym)
  case(1)
    n=0
    do ix=1,NKx
    do iy=1,NKy
    do iz=1,NKz
      n=n+1
      kAc(n,1)=-bLx/2+(ix-0.5d0)*bLx/NKx
      kAc(n,2)=-bLy/2+(iy-0.5d0)*bLy/NKy
      kAc(n,3)=-bLz/2+(iz-0.5d0)*bLz/NKz
      wk(n)=1.d0
    enddo
    enddo
    enddo
  case(4)
    n=0
    do ix=1,NKx/2
    do iy=1,NKy/2
    do iz=1,NKz
      n=n+1
      kAc(n,1)=-bLx/2+(ix-0.5d0)*bLx/NKx
      kAc(n,2)=-bLy/2+(iy-0.5d0)*bLy/NKy
      kAc(n,3)=-bLz/2+(iz-0.5d0)*bLz/NKz
      wk(n)=4.d0
    enddo
    enddo
    enddo
  case(8)
! assume NKx == NKy
    n=0
    do ix=1,NKx/2
    do iy=1,ix
    do iz=1,NKz
      n=n+1
      kAc(n,1)=-bLx/2+(ix-0.5d0)*bLx/NKx
      kAc(n,2)=-bLy/2+(iy-0.5d0)*bLy/NKy
      kAc(n,3)=-bLz/2+(iz-0.5d0)*bLz/NKz
      wk(n)=8.d0
      if(ix == iy) wk(n)=4.d0
    enddo
    enddo
    enddo
  end select

! yabana
  kAc0=kAc
! yabana

  do ib=1,NB
    occ(ib,1:NK)=2.d0/(NKx*NKy*NKz)*wk(1:NK)
  enddo
  if (NBoccmax < NB) occ(NBoccmax+1:NB,:)=0.d0
  Ne_tot=sum(occ)
  if (Myrank == 0) then
    write(*,*) 'Ne_tot',Ne_tot
  endif

! make ik-ib table ! sato
  i=0
  do ik=NK_s,NK_e
    do ib=1,NBoccmax
      i=i+1
      ik_table(i)=ik
      ib_table(i)=ib
    end do
  end do
!$acc enter data copyin(ik_table, ib_table)

! make symmetry table
  if(Sym == 1)then
  else if((Sym == 8).and.(crystal_structure == 'diamond')) then
!=== start diamond(8) ====================================================================
! f(r_new)=T_1*f(r_old+t); (r_new=T_1*r_old)
!      |+0 +1 +0|      |+0 -1 +0|      |+0 -1 +0|
!  R_1=|+1 +0 +0|  R_2=|-1 +0 +0|  R_3=|+1 +0 +0|
!      |+0 +0 +1|      |+0 +0 +1|      |+0 +0 +1|
! 
!      |+1/4|     |+1/2|
!    t=|+1/4|   a=|+1/2|
!      |+1/4|     |+ 0 |
!
!   T_1(R_1),T_2(R_2),T_3(R_3,t),T_4(a)
!


! 1. T_1
    do i=1,NL
      ix=Lx(i);iy=Ly(i);iz=Lz(i)
      ixt=iy;iyt=ix;izt=iz ! R_1
      itable_sym(1,i)=Lxyz(ixt,iyt,izt)
    end do
! 2. T_2
    do i=1,NL
      ix=Lx(i);iy=Ly(i);iz=Lz(i)
      ixt=-iy;iyt=-ix;izt=iz
      ixt=mod(ixt+2*NLx,NLx);iyt=mod(iyt+2*NLy,NLy);izt=mod(izt+2*NLz,NLz)
      itable_sym(2,i)=Lxyz(ixt,iyt,izt)
    end do
! 3. T_3
    do i=1,NL
      ix=Lx(i);iy=Ly(i);iz=Lz(i)
      ixt=-iy+NLx/4;iyt=ix+NLy/4;izt=iz+NLz/4 ! R_3
      ixt=mod(ixt+2*NLx,NLx);iyt=mod(iyt+2*NLy,NLy);izt=mod(izt+2*NLz,NLz)
      itable_sym(3,i)=Lxyz(ixt,iyt,izt)
    end do
! 4. T_4
    do i=1,NL
      ix=Lx(i);iy=Ly(i);iz=Lz(i)
      ixt=ix+NLx/2;iyt=iy+NLy/2;izt=iz
      ixt=mod(ixt+2*NLx,NLx);iyt=mod(iyt+2*NLy,NLy);izt=mod(izt+2*NLz,NLz)
      itable_sym(4,i)=Lxyz(ixt,iyt,izt)
    end do
! 5. T_3*T_3
    do i=1,NL
      ix=Lx(i);iy=Ly(i);iz=Lz(i)
      ixt=-iy+NLx/4;iyt=ix+NLy/4;izt=iz+NLz/4 ! T_3

      ix=ixt;iy=iyt;iz=izt
      ixt=-iy+NLx/4;iyt=ix+NLy/4;izt=iz+NLz/4 ! T_3
      ixt=mod(ixt+2*NLx,NLx);iyt=mod(iyt+2*NLy,NLy);izt=mod(izt+2*NLz,NLz)
      itable_sym(5,i)=Lxyz(ixt,iyt,izt)
    end do
!===  end  diamond(8) ====================================================================
  else if((Sym == 4).and.(crystal_structure == 'diamond')) then
!=== start diamond(4) ====================================================================
! f(r_new)=T_1*f(r_old+t); (r_new=T_1*r_old)
!      |+0 +1 +0|      |+0 -1 +0|      |+0 -1 +0|
!  R_1=|+1 +0 +0|  R_2=|-1 +0 +0|  R_3=|+1 +0 +0|
!      |+0 +0 +1|      |+0 +0 +1|      |+0 +0 +1|
! 
!      |+1/4|     |+1/2|
!    t=|+1/4|   a=|+1/2|
!      |+1/4|     |+ 0 |
!
!   T_1(R_1),T_2(R_2),T_3(R_3,t),T_4(a)
!


! 1. T_3
    do i=1,NL
      ix=Lx(i);iy=Ly(i);iz=Lz(i)
      ixt=-iy+NLx/4;iyt=ix+NLy/4;izt=iz+NLz/4 ! R_3
      ixt=mod(ixt+2*NLx,NLx);iyt=mod(iyt+2*NLy,NLy);izt=mod(izt+2*NLz,NLz)
      itable_sym(1,i)=Lxyz(ixt,iyt,izt)
    end do
! 2. T_3*T_3
    do i=1,NL
      ix=Lx(i);iy=Ly(i);iz=Lz(i)
      ixt=-iy+NLx/4;iyt=ix+NLy/4;izt=iz+NLz/4 ! T_3

      ix=ixt;iy=iyt;iz=izt
      ixt=-iy+NLx/4;iyt=ix+NLy/4;izt=iz+NLz/4 ! T_3
      ixt=mod(ixt+2*NLx,NLx);iyt=mod(iyt+2*NLy,NLy);izt=mod(izt+2*NLz,NLz)
      itable_sym(2,i)=Lxyz(ixt,iyt,izt)
    end do
!===  end  diamond(4) ====================================================================
  else if((Sym == 8).and.(crystal_structure == 'tetragonal')) then
!=== start diamond(8) ====================================================================
! f(r_new)=T_1*f(r_old+t); (r_new=T_1*r_old)
!      |+0 +1 +0|      |+0 -1 +0|      |+0 -1 +0|
!  R_1=|+1 +0 +0|  R_2=|-1 +0 +0|  R_3=|+1 +0 +0|
!      |+0 +0 +1|      |+0 +0 +1|      |+0 +0 +1|
! 

!   T_1(R_1),T_2(R_2),T_3(R_3)


! 1. T_1
    do i=1,NL
      ix=Lx(i);iy=Ly(i);iz=Lz(i)
      ixt=iy;iyt=ix;izt=iz ! R_1
      itable_sym(1,i)=Lxyz(ixt,iyt,izt)
    end do
! 2. T_2
    do i=1,NL
      ix=Lx(i);iy=Ly(i);iz=Lz(i)
      ixt=-iy;iyt=-ix;izt=iz
      ixt=mod(ixt+2*NLx,NLx);iyt=mod(iyt+2*NLy,NLy);izt=mod(izt+2*NLz,NLz)
      itable_sym(2,i)=Lxyz(ixt,iyt,izt)
    end do
! 3. T_3
    do i=1,NL
      ix=Lx(i);iy=Ly(i);iz=Lz(i)
      ixt=-iy;iyt=ix;izt=iz ! R_3
      ixt=mod(ixt+2*NLx,NLx);iyt=mod(iyt+2*NLy,NLy);izt=mod(izt+2*NLz,NLz)
      itable_sym(3,i)=Lxyz(ixt,iyt,izt)
    end do
! 4. T_3*T_3
    do i=1,NL
      ix=Lx(i);iy=Ly(i);iz=Lz(i)
      ixt=-iy;iyt=ix;izt=iz ! T_3

      ix=ixt;iy=iyt;iz=izt
      ixt=-iy;iyt=ix;izt=iz ! T_3
      ixt=mod(ixt+2*NLx,NLx);iyt=mod(iyt+2*NLy,NLy);izt=mod(izt+2*NLz,NLz)
      itable_sym(4,i)=Lxyz(ixt,iyt,izt)
    end do
!===  end  diamond(8) ====================================================================
  else
    call err_finalize('preparation of symmetry table is faled')
  end if


  return
End Subroutine Init
!--------10--------20--------30--------40--------50--------60--------70--------80--------90--------100-------110-------120--------130
