! ANALYSIS ALGORITHM
! DATE WRITTEN: JULY 21, 2020
! DATE UPDATED: OCTOBER 25, 2022
! PURPOSE: produces cross section of a gro structure file

! ########################################################################################################
!
! [ HOW TO USE]
!
! 1. fort files generated by cluster_nm.f should be present in current working directory
!        fort.5011-13
!        fort.5021-23
!        fort.5031-33
!        fort.5041-43
!        fort.5051-53
!
! 2. Compile algorithm
!          gfortran -o3 crosscutgro.f -o crosscut
!
! 3. Begin cutting
!          ./graphing < (cleaned trajectory file)
!
! ########################################################################################################                          
!
! [ SECTIONS ]
!
! I. READ STRUCTURE (GRO) FILE
!  
! II. DETERMINE CLUSTER SPAN
!  
! III. WRITING TOTAL ATOMS IN FIRST ROW 
!
! IV. WRITING COORDINATES OF ATOMS WITHIN CONDITIONS 
!
! IV.A. WITHIN LIMIT ALONG X AXIS (CUTS A Y-Z PLANE)
! IV.B. WITHIN LIMIT ALONG Y AXIS (CUTS AN X-Z PLANE)
! IV.C. WITHIN LIMIT ALONG Z AXIS (CUTS AN X-Y PLANE)
!
! V. WRITE PBC COORDINATES FOR EACH CUT STRUCTURE
!
! ########################################################################################################                          

	program crosscut

! [ USER-DEFINED VARIABLES ]

	implicit none
	integer tot,countmolX,i,molty(1:200000)
	integer ln,l(1:200000),countmolY
	integer countmolZ,ata,atb,atc
	integer t1,t2,clock_rate,clock_max
	double precision xx,yy,zz,largestX,cutpointX,smallestX,spanX
	double precision cutsetX
	double precision largestY,cutpointY,smallestY,spanY
	double precision cutsetY
	double precision largestZ,cutpointZ,smallestZ,spanZ
	double precision cutsetZ
	double precision e,f,g,SECONDS
	double precision x(1:200000,1:10,1:20),y(1:200000,1:10,1:20)
	double precision z(1:200000,1:10,1:20)
	character (len=1) at
	character (len=3) b
	character (len=4) atom
	character (len=21) spcf,spcg,spch,spci
   	
   	call system_clock (t1, clock_rate, clock_max)
   	
	write(*,*) " [C.a] (BRANCH TASK: crosscutgro.f)"
	write(*,*) " "

!-------I. READ STRUCTURE (GRO) FILE 

	read( 5,* ) tot           !feed a cleaned gro file, with total atoms on first row.
	ln = 0
	
	do i = 1,tot   
	 read( 5,* ) b , e , f , g 
	 
	  if ( b .eq. "SOL" ) then
	   molty(i) = 1    !molecule type   
	   ln = ln + 1     
	   l(i) = ln       !atom type
	   if ( ln .eq. 4 ) then
	    ln = 0
	   endif
	
	  elseif ( b .eq. "NON" ) then            
	   molty(i) = 2
	   ln = ln + 1
	   l(i) = ln
	   if ( ln .eq. 9 ) then
	    ln = 0
	   endif
	
	  elseif ( b .eq. "BUT" ) then
	   molty(i) = 3
	   ln = ln + 1
	   l(i) = ln
	   if ( ln .eq. 6 ) then
	    ln = 0
	   endif
	
	  elseif ( b .eq. "NH3" ) then
	   molty(i) = 4
	   ln = ln + 1
	   l(i) = ln
	   if ( ln .eq. 5 ) then
	    ln = 0
	   endif
	      
	  elseif ( b .eq. "MET" ) then
	   molty(i) = 5
	   ln = ln + 1
	   l(i) = ln
	   if ( ln .eq. 3 ) then
	    ln = 0
	   endif
	      
	  elseif ( b .eq. "ACT" ) then
	   molty(i) = 6
	   ln = ln + 1
	   l(i) = ln
	   if ( ln .eq. 5 ) then
	    ln = 0
	   endif
	
	  elseif ( b .eq. "OCT" ) then
	   molty(i) = 8
	   ln = ln + 1
	   l(i) = ln
	   if ( ln .eq. 10 ) then
	    ln = 0
	   endif
	  endif
	
	  x( i,molty(i),l(i) ) = e  !atom count, molec type, atom type
	  y( i,molty(i),l(i) ) = f
	  z( i,molty(i),l(i) ) = g

!-------II. DETERMINE CLUSTER SPAN

	  if ( i .eq. 1 ) then
	   largestX  = x(i,molty(i),l(i))
	   largestY  = y(i,molty(i),l(i))
	   largestZ  = z(i,molty(i),l(i))
	   smallestX = x(i,molty(i),l(i))
	   smallestY = y(i,molty(i),l(i))
	   smallestZ = z(i,molty(i),l(i))
	  else
	   if ( x(i,molty(i),l(i)) .gt. largestX ) then
	    largestX  = x(i,molty(i),l(i))
	   endif
	   if ( y(i,molty(i),l(i)) .gt. largestY ) then
	    largestY  = y(i,molty(i),l(i))
	   endif
	   if ( z(i,molty(i),l(i)) .gt. largestZ ) then
	    largestZ  = z(i,molty(i),l(i))
	   endif
	   if ( x(i,molty(i),l(i)) .lt. smallestX ) then
	    smallestX = x(i,molty(i),l(i))
	   endif
	   if ( y(i,molty(i),l(i)) .lt. smallestY ) then
	    smallestY = y(i,molty(i),l(i))
	   endif
	   if ( z(i,molty(i),l(i)) .lt. smallestZ ) then
	    smallestZ = z(i,molty(i),l(i))
	   endif
	  endif
	enddo
	
	spanX = largestX - smallestX
	spanY = largestY - smallestY
	spanZ = largestZ - smallestZ
	
	cutsetX = spanX/2d0
	cutsetY = spanY/2d0
	cutsetZ = spanZ/2d0
	
	cutpointX = smallestX + cutsetX 
	cutpointY = smallestY + cutsetY 
	cutpointZ = smallestZ + cutsetZ 
	

!-------III. WRITING TOTAL ATOMS IN FIRST ROW

	countmolX = 0
	countmolY = 0
	countmolZ = 0
	
	do i = 1,tot
	 if ( x(i,molty(i),l(i)) .lt. cutpointX ) then
	   countmolX = countmolX + 1      
	 endif
	 if ( y(i,molty(i),l(i)) .lt. cutpointY ) then
	   countmolY = countmolY + 1      
	 endif
	 if ( z(i,molty(i),l(i)) .lt. cutpointZ ) then
	   countmolZ = countmolZ + 1      
	 endif
	enddo

	write(60,*) 'unary alkanes'
	write(61,*) 'unary alkanes'
	write(62,*) 'unary alkanes'
	write(60,*) countmolX
	write(61,*) countmolY
	write(62,*) countmolZ

!-------IV. WRITING COORDINATES OF ATOMS WITHIN CONDITIONS 

	ata=0
	atb=0
	atc=0

   	spcf='(i5,a3,a7,i5,3f8.3)'
   	spcg='(i5,a3,a7,i5,3f8.3)'
   	spch='(i5,a4,a6,i5,3f8.3)'
   	spci='(i5,a3,a7,i5,3f8.3)'

!-------IV.A. WITHIN LIMIT ALONG X AXIS (CUTS A Y-Z PLANE)

	do i = 1,tot
	 if ( x(i,molty(i),l(i)) .lt. cutpointX ) then
	  if ( molty(i) .eq. 1 ) then
	   ata = ata + 1
	   if ( l(i) .eq. 1 ) then
	    atom = "  OW"
	   elseif ( l(i) .eq. 2 ) then
	    atom = " HW1"
	   elseif ( l(i) .eq. 3 ) then
	    atom = " HW2"
	   elseif ( l(i) .eq. 4 ) then
	    atom = "  MW"
	   endif 
	   write(60,spcf) ata,"SOL",atom,ata,x(i,molty(i),l(i)),
     &                    y(i,molty(i),l(i)),z(i,molty(i),l(i))
             
	  elseif ( molty(i) .eq. 2 ) then
	   ata = ata + 1
	   if ( l(i) .eq. 1 ) then
	    atom = "C09A"
	   elseif ( l(i) .eq. 2 ) then
	    atom = "C09B"
	   elseif ( l(i) .eq. 3 ) then
	    atom = "C09C"
	   elseif ( l(i) .eq. 4 ) then
	    atom = "C09D"
	   elseif ( l(i) .eq. 5 ) then
	    atom = "C09E"
	   elseif ( l(i) .eq. 6 ) then
	    atom = "C09F"
	   elseif ( l(i) .eq. 7 ) then
	    atom = "C09G"
	   elseif ( l(i) .eq. 8 ) then
	    atom = "C09H"
	   elseif ( l(i) .eq. 9 ) then
	    atom = "C09I"
	   endif
	   write(60,spcg) ata,"NON",atom,ata,x(i,molty(i),l(i)),
     &                    y(i,molty(i),l(i)),z(i,molty(i),l(i))

	  elseif ( molty(i) .eq. 3 ) then
	   ata = ata + 1
	   if ( l(i) .eq. 1 ) then
	    atom = " CAA"
	   elseif ( l(i) .eq. 2 ) then
	    atom = " CAB"
	   elseif ( l(i) .eq. 3 ) then
	    atom = " CAC"
	   elseif ( l(i) .eq. 4 ) then
	    atom = " CAD"
	   elseif ( l(i) .eq. 5 ) then
	    atom = " OAE"
	   elseif ( l(i) .eq. 6 ) then
	    atom = " HAJ"
	   endif
	   write(60,spch) ata,"BUTA",atom,ata,x(i,molty(i),l(i)),
     &                    y(i,molty(i),l(i)),z(i,molty(i),l(i))

	  elseif ( molty(i) .eq. 4 ) then
	   ata = ata + 1
	   if ( l(i) .eq. 1 ) then
	    atom = "  N1"
	   elseif ( l(i) .eq. 2 ) then
	    atom = "  H1"
	   elseif ( l(i) .eq. 3 ) then
	    atom = "  H2"
	   elseif ( l(i) .eq. 4 ) then
	    atom = "  H3"
	   elseif ( l(i) .eq. 5 ) then
	    atom = "  DN"
	   endif
	   write(60,spci) ata,"NH3",atom,ata,x(i,molty(i),l(i)),
     &                    y(i,molty(i),l(i)),z(i,molty(i),l(i))

	  elseif ( molty(i) .eq. 5 ) then
	   ata = ata + 1
	   if ( l(i) .eq. 1 ) then
	    atom = " CBA"
	   elseif ( l(i) .eq. 2 ) then
	    atom = " OBB"
	   elseif ( l(i) .eq. 3 ) then
	    atom = " HBC"
	   endif
	   write(60,spci) ata,"MET",atom,ata,x(i,molty(i),l(i)),
     &                    y(i,molty(i),l(i)),z(i,molty(i),l(i))

	  elseif ( molty(i) .eq. 6 ) then
	   ata = ata + 1
	   if ( l(i) .eq. 1 ) then
	    atom = " CQA"
	   elseif ( l(i) .eq. 2 ) then
	    atom = " CQB"
	   elseif ( l(i) .eq. 3 ) then
	    atom = " OQA"
	   elseif ( l(i) .eq. 4 ) then
	    atom = " OQB"
	   elseif ( l(i) .eq. 5 ) then
	    atom = " HQA"
	   endif
	   write(60,spci) ata,"ACT",atom,ata,x(i,molty(i),l(i)),
     &                    y(i,molty(i),l(i)),z(i,molty(i),l(i))

	  elseif ( molty(i) .eq. 8 ) then
	   ata = ata + 1
	   if ( l(i) .eq. 1 ) then
	    atom = " CAA"
	   elseif ( l(i) .eq. 2 ) then
	    atom = " CAB"
	   elseif ( l(i) .eq. 3 ) then
	    atom = " CAC"
	   elseif ( l(i) .eq. 4 ) then
	    atom = " CAD"
	   elseif ( l(i) .eq. 5 ) then
	    atom = " CAE"
	   elseif ( l(i) .eq. 6 ) then
	    atom = " CAF"
	   elseif ( l(i) .eq. 7 ) then
	    atom = " CAG"
	   elseif ( l(i) .eq. 8 ) then
	    atom = " CAH"
	   elseif ( l(i) .eq. 9 ) then
	    atom = " OAE"
	   elseif ( l(i) .eq. 10 ) then
	    atom = " HAJ"
	   endif
	   write(60,spch) ata,"OCTA",atom,ata,x(i,molty(i),l(i)),
     &                    y(i,molty(i),l(i)),z(i,molty(i),l(i))

	  endif
	 endif

!-------IV.B. WITHIN LIMIT ALONG Y AXIS (CUTS AN X-Z PLANE)

	 if ( y(i,molty(i),l(i)) .lt. cutpointY ) then
	  if ( molty(i) .eq. 1 ) then
	   atb = atb + 1
	   if ( l(i) .eq. 1 ) then
	    atom = "  OW"
	   elseif ( l(i) .eq. 2 ) then
	    atom = " HW1"
	   elseif ( l(i) .eq. 3 ) then
	    atom = " HW2"
	   elseif ( l(i) .eq. 4 ) then
	    atom = "  MW"
	   endif 
	   write(61,spcf) atb,"SOL",atom,atb,x(i,molty(i),l(i)),
     &                    y(i,molty(i),l(i)),z(i,molty(i),l(i))
             
	  elseif ( molty(i) .eq. 2 ) then
	   atb = atb + 1
	   if ( l(i) .eq. 1 ) then
	    atom = "C09A"
	   elseif ( l(i) .eq. 2 ) then
	    atom = "C09B"
	   elseif ( l(i) .eq. 3 ) then
	    atom = "C09C"
	   elseif ( l(i) .eq. 4 ) then
	    atom = "C09D"
	   elseif ( l(i) .eq. 5 ) then
	    atom = "C09E"
	   elseif ( l(i) .eq. 6 ) then
	    atom = "C09F"
	   elseif ( l(i) .eq. 7 ) then
	    atom = "C09G"
	   elseif ( l(i) .eq. 8 ) then
	    atom = "C09H"
	   elseif ( l(i) .eq. 9 ) then
	    atom = "C09I"
	   endif
	   write(61,spcg) atb,"NON",atom,atb,x(i,molty(i),l(i)),
     &                    y(i,molty(i),l(i)),z(i,molty(i),l(i))

	  elseif ( molty(i) .eq. 3 ) then
	   atb = atb + 1
	   if ( l(i) .eq. 1 ) then
	    atom = " CAA"
	   elseif ( l(i) .eq. 2 ) then
	    atom = " CAB"
	   elseif ( l(i) .eq. 3 ) then
	    atom = " CAC"
	   elseif ( l(i) .eq. 4 ) then
	    atom = " CAD"
	   elseif ( l(i) .eq. 5 ) then
	    atom = " OAE"
	   elseif ( l(i) .eq. 6 ) then
	    atom = " HAJ"
	   endif
	   write(61,spch) atb,"BUTA",atom,atb,x(i,molty(i),l(i)),
     &                    y(i,molty(i),l(i)),z(i,molty(i),l(i))

	  elseif ( molty(i) .eq. 4 ) then
	   atb = atb + 1
	   if ( l(i) .eq. 1 ) then
	    atom = "  N1"
	   elseif ( l(i) .eq. 2 ) then
	    atom = "  H1"
	   elseif ( l(i) .eq. 3 ) then
	    atom = "  H2"
	   elseif ( l(i) .eq. 4 ) then
	    atom = "  H3"
	   elseif ( l(i) .eq. 5 ) then
	    atom = "  DN"
	   endif
	   write(61,spci) atb,"NH3",atom,atb,x(i,molty(i),l(i)),
     &                    y(i,molty(i),l(i)),z(i,molty(i),l(i))

	  elseif ( molty(i) .eq. 5 ) then
	   atb = atb + 1
	   if ( l(i) .eq. 1 ) then
	    atom = " CBA"
	   elseif ( l(i) .eq. 2 ) then
	    atom = " OBB"
	   elseif ( l(i) .eq. 3 ) then
	    atom = " HBC"
	   endif
	   write(61,spci) atb,"MET",atom,atb,x(i,molty(i),l(i)),
     &                    y(i,molty(i),l(i)),z(i,molty(i),l(i))

	  elseif ( molty(i) .eq. 6 ) then
	   atb = atb + 1
	   if ( l(i) .eq. 1 ) then
	    atom = " CQA"
	   elseif ( l(i) .eq. 2 ) then
	    atom = " CQB"
	   elseif ( l(i) .eq. 3 ) then
	    atom = " OQA"
	   elseif ( l(i) .eq. 4 ) then
	    atom = " OQB"
	   elseif ( l(i) .eq. 5 ) then
	    atom = " HQA"
	   endif
	   write(61,spci) atb,"ACT",atom,atb,x(i,molty(i),l(i)),
     &                    y(i,molty(i),l(i)),z(i,molty(i),l(i))

	  elseif ( molty(i) .eq. 8 ) then
	   atb = atb + 1
	   if ( l(i) .eq. 1 ) then
	    atom = " CAA"
	   elseif ( l(i) .eq. 2 ) then
	    atom = " CAB"
	   elseif ( l(i) .eq. 3 ) then
	    atom = " CAC"
	   elseif ( l(i) .eq. 4 ) then
	    atom = " CAD"
	   elseif ( l(i) .eq. 5 ) then
	    atom = " CAE"
	   elseif ( l(i) .eq. 6 ) then
	    atom = " CAF"
	   elseif ( l(i) .eq. 7 ) then
	    atom = " CAG"
	   elseif ( l(i) .eq. 8 ) then
	    atom = " CAH"
	   elseif ( l(i) .eq. 9 ) then
	    atom = " OAE"
	   elseif ( l(i) .eq. 10 ) then
	    atom = " HAJ"
	   endif
	   write(61,spch) atb,"OCTA",atom,atb,x(i,molty(i),l(i)),
     &                    y(i,molty(i),l(i)),z(i,molty(i),l(i))

	  endif
	 endif

!-------IV.C. WITHIN LIMIT ALONG Z AXIS (CUTS AN X-Y PLANE)

	 if ( z(i,molty(i),l(i)) .lt. cutpointZ ) then
	  if ( molty(i) .eq. 1 ) then
	   atc = atc + 1
	   if ( l(i) .eq. 1 ) then
	    atom = "  OW"
	   elseif ( l(i) .eq. 2 ) then
	    atom = " HW1"
	   elseif ( l(i) .eq. 3 ) then
	    atom = " HW2"
	   elseif ( l(i) .eq. 4 ) then
	    atom = "  MW"
	   endif 
	   write(62,spcf) atc,"SOL",atom,atc,x(i,molty(i),l(i)),
     &                    y(i,molty(i),l(i)),z(i,molty(i),l(i))
             
	  elseif ( molty(i) .eq. 2 ) then
	   atc = atc + 1
	   if ( l(i) .eq. 1 ) then
	    atom = "C09A"
	   elseif ( l(i) .eq. 2 ) then
	    atom = "C09B"
	   elseif ( l(i) .eq. 3 ) then
	    atom = "C09C"
	   elseif ( l(i) .eq. 4 ) then
	    atom = "C09D"
	   elseif ( l(i) .eq. 5 ) then
	    atom = "C09E"
	   elseif ( l(i) .eq. 6 ) then
	    atom = "C09F"
	   elseif ( l(i) .eq. 7 ) then
	    atom = "C09G"
	   elseif ( l(i) .eq. 8 ) then
	    atom = "C09H"
	   elseif ( l(i) .eq. 9 ) then
	    atom = "C09I"
	   endif
	   write(62,spcg) atc,"NON",atom,atc,x(i,molty(i),l(i)),
     &                    y(i,molty(i),l(i)),z(i,molty(i),l(i))

	  elseif ( molty(i) .eq. 3 ) then
	   atc = atc + 1
	   if ( l(i) .eq. 1 ) then
	    atom = " CAA"
	   elseif ( l(i) .eq. 2 ) then
	    atom = " CAB"
	   elseif ( l(i) .eq. 3 ) then
	    atom = " CAC"
	   elseif ( l(i) .eq. 4 ) then
	    atom = " CAD"
	   elseif ( l(i) .eq. 5 ) then
	    atom = " OAE"
	   elseif ( l(i) .eq. 6 ) then
	    atom = " HAJ"
	   endif
	   write(62,spch) atc,"BUTA",atom,atc,x(i,molty(i),l(i)),
     &                    y(i,molty(i),l(i)),z(i,molty(i),l(i))

	  elseif ( molty(i) .eq. 4 ) then
	   atc = atc + 1
	   if ( l(i) .eq. 1 ) then
	    atom = "  N1"
	   elseif ( l(i) .eq. 2 ) then
	    atom = "  H1"
	   elseif ( l(i) .eq. 3 ) then
	    atom = "  H2"
	   elseif ( l(i) .eq. 4 ) then
	    atom = "  H3"
	   elseif ( l(i) .eq. 5 ) then
	    atom = "  DN"
	   endif
	   write(62,spci) atc,"NH3",atom,atc,x(i,molty(i),l(i)),
     &                    y(i,molty(i),l(i)),z(i,molty(i),l(i))

	  elseif ( molty(i) .eq. 5 ) then
	   atc = atc + 1
	   if ( l(i) .eq. 1 ) then
	    atom = " CBA"
	   elseif ( l(i) .eq. 2 ) then
	    atom = " OBB"
	   elseif ( l(i) .eq. 3 ) then
	    atom = " HBC"
	   endif
	   write(62,spci) atc,"MET",atom,atc,x(i,molty(i),l(i)),
     &                    y(i,molty(i),l(i)),z(i,molty(i),l(i))

	  elseif ( molty(i) .eq. 6 ) then
	   atc = atc + 1
	   if ( l(i) .eq. 1 ) then
	    atom = " CQA"
	   elseif ( l(i) .eq. 2 ) then
	    atom = " CQB"
	   elseif ( l(i) .eq. 3 ) then
	    atom = " OQA"
	   elseif ( l(i) .eq. 4 ) then
	    atom = " OQB"
	   elseif ( l(i) .eq. 5 ) then
	    atom = " HQA"
	   endif
	   write(62,spci) atc,"ACT",atom,atc,x(i,molty(i),l(i)),
     &                    y(i,molty(i),l(i)),z(i,molty(i),l(i))

	  elseif ( molty(i) .eq. 8 ) then
	   atc = atc + 1
	   if ( l(i) .eq. 1 ) then
	    atom = " CAA"
	   elseif ( l(i) .eq. 2 ) then
	    atom = " CAB"
	   elseif ( l(i) .eq. 3 ) then
	    atom = " CAC"
	   elseif ( l(i) .eq. 4 ) then
	    atom = " CAD"
	   elseif ( l(i) .eq. 5 ) then
	    atom = " CAE"
	   elseif ( l(i) .eq. 6 ) then
	    atom = " CAF"
	   elseif ( l(i) .eq. 7 ) then
	    atom = " CAG"
	   elseif ( l(i) .eq. 8 ) then
	    atom = " CAH"
	   elseif ( l(i) .eq. 9 ) then
	    atom = " OAE"
	   elseif ( l(i) .eq. 10 ) then
	    atom = " HAJ"
	   endif
	   write(62,spch) atc,"OCTA",atom,atc,x(i,molty(i),l(i)),
     &                    y(i,molty(i),l(i)),z(i,molty(i),l(i))

	  endif
	 endif
	enddo
	

!-------V. WRITE PBC COORDINATES FOR EACH CUT STRUCTURE

   	write(60,'(a30)') "10.00000  10.00000  10.00000"
   	write(61,'(a30)') "10.00000  10.00000  10.00000"
   	write(62,'(a30)') "10.00000  10.00000  10.00000"

! ########################################################################################################

c   	call system_clock (t2, clock_rate, clock_max) 
c   	
c	SECONDS=real(t2-t1)/real(clock_rate)
c   	write(*,*) " "
c	write(*,'(a21,i3,a10,f7.3,a10)')'      (TIME ELAPSED:',
c     &                          INT(SECONDS/60),'MINUTE/S ',
c     &                          MOD(SECONDS,60d0),'SECOND/S)'
c   	write(*,*) " "

	end
