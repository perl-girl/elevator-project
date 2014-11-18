UP MACRO fNum, elev1, elev2
	
	LOCAL endup

	   pushad
	   mov eax, fNum
	   .IF elev1.loc == al && elev1.dirBit == 0 ; checks if 1st elevator is already at the floor and idle
		 mov elev1.doorDir, 1
		 .IF al == 1
		    mov F1_UP, 0
		 .ELSEIF al == 2
		    mov F2_UP, 0
		 .ELSEIF al == 3
		    mov F3_UP, 0
		 .ENDIF
		 mov elev1.dirBit, 1
		 jmp endup
	   .ELSEIF elev2.loc == al && elev2.dirBit == 0 ; checks if 2nd elevator is at the floor and idle if 1st isn't
		mov elev2.doorDir, 1
		.IF al == 1
		    mov F1_UP, 0
		    mov elev2.dirBit, 1
		 .ELSEIF al == 2
		    mov F2_UP, 0
		 .ELSEIF al == 3
		    mov F3_UP, 0
		 .ENDIF
		 mov elev2.dirBit, 1
		 jmp endup
	   .ENDIF
	   mov edi, fNum ; loads floor number into edi
	   dec edi  ; initializes array index
   
	   .IF elev1.dirBit > 0 && elev2.dirBit < 1 ; if elevator 1 is going up and elevator 2 isn't
		 .IF elev1.dist[edi] < 0 ; checks if elevator 1 is already above the floor
		    mov elev2.upPath[edi], 1 ; if it is, then puts the floor in elevator 2's path
		 .ELSE
		    mov elev1.upPath[edi], 1 ; if it isn't, then puts the floor in elevator 1's path
		 .ENDIF
	   .ELSEIF elev1.dirBit < 1 && elev2.dirBit > 0 ; checks if elev 1 is not going up and elev 2 is
		 .IF elev2.dist[edi] < 0
		    mov elev1.upPath[edi], 1
		 .ELSE
		    mov elev2.upPath[edi], 1
		 .ENDIF
	   .ELSEIF elev1.dirBit != 1 && elev2.dirBit != 1 ; if both elevators are either idle or going down
		 mov al, elev2.dist
		 .IF elev1.dist < al               ; puts the floor in the path of the elevator which should be closest
		    mov elev2.upPath[edi], 1
		 .ELSE
		    mov elev1.upPath[edi], 1
		 .ENDIF
	   .ELSEIF elev1.dirBit > 0 && elev2.dirBit > 0 ; if both elevators are going up
		 .IF elev1.dist[edi] > 0 && elev2.dist[edi] > 0 ; checks if they're both below the calling floor
		    mov al, elev2.dist[edi]
		    .IF elev1.dist[edi] > al ; puts floor in path of nearest elevator
			  mov elev2.upPath[edi], 1
		    .ELSE
			  mov elev1.upPath[edi], 1
		    .ENDIF
		 .ELSEIF elev1.dist[edi] > 0 && elev2.dist[edi] < 0 ; if only one elevator is below 
		    mov elev1.upPath[edi], 1
		 .ELSEIF elev2.dist[edi] > 0 && elev1.dist[edi] < 0 ; then that elevator has the floor put in its path
		    mov elev2.upPath[edi], 1
		 .ELSE
		    mov al, elev2.dist
		    .IF elev1.dist < al ; but if both elevators are above the floor, then whichever one 
								  ; is furthest from the bottom floor (i.e. the one which will start going down
								  ; soonest and thus back up soonest) has the floor put in its up path
			  mov elev1.upPath[edi], 1
		    .ELSE
			  mov elev2.upPath[edi], 1
		    .ENDIF
		 .ENDIF
	   .ENDIF

	   endup:
		popad   
ENDM

DOWN MACRO fNum, elev1, elev2

	LOCAL endDn
   
	   pushAD
	   mov eax, fNum
	   mov edi, fNum
	   dec edi
	   .IF elev1.loc == al && elev1.dirBit == 0 ; checks if 1st elevator is already at the floor and idle
		 mov elev1.doorDir, 1
		 .IF al == 4
		    mov F4_DN, 0            ;------------- THESE STATEMENTS TURN OFF THE BUTTONS AT THEIR RESPECTIVE FLOORS
		 .ELSEIF al == 3
		    mov F3_DN, 0
		 .ELSEIF al == 2
		    mov F2_DN, 0
		 .ENDIF
		 mov elev1.dirBit, -1
		 jmp endDn
	   .ELSEIF elev2.loc == al && elev2.dirBit == 0 ; checks if 2nd elevator is at the floor and idle if 1st isn't
		 mov elev2.doorDir, 1
		 .IF al == 4
		    mov F4_DN, 0
		 .ELSEIF al == 3
		    mov F3_DN, 0
		 .ELSEIF al == 2
		    mov F2_DN, 0
		 .ENDIF
		 mov elev2.dirBit, -1
		 jmp endDn
	   .ENDIF
   
	   .IF elev1.dirBit < 0 && elev2.dirBit > -1 ; if elevator 1 is going down and elevator 2 isn't
		 .IF elev1.dist[edi] > 0 ; checks if elevator 1 is already below the floor
		    mov elev2.dnPath[edi], 1; if it is, then puts the floor in elevator 2's path
		 .ELSE
		    mov elev1.dnPath[edi], 1 ; if it isn't, then puts the floor in elevator 1's path
		 .ENDIF
	   .ELSEIF elev1.dirBit > -1 && elev2.dirBit < 0 ; checks if elev 1 is not going up and elev 2 is
		 .IF elev2.dist[edi] > 0
		    mov elev1.dnPath[edi], 1
		 .ELSE
		    mov elev2.dnPath[edi], 1
		 .ENDIF
	   .ELSEIF elev1.dirBit > -1 && elev2.dirBit > -1 ; if both elevators are either idle or going up
		 mov al, elev2.dist
		 .IF elev1.dist > al               ; puts the floor in the path of the elevator which should be closest
		    mov elev2.dnPath[edi], 1
		 .ELSE
		    mov elev1.dnPath[edi], 1
		 .ENDIF
	   .ELSEIF elev1.dirBit < 0 && elev2.dirBit < 0 ; if both elevators are going down
		 .IF elev1.dist[edi] < 0 && elev2.dist[edi] < 0 ; checks if they're both above the calling floor
		    mov al, elev2.dist[edi]
		    .IF elev1.dist[edi] < al ; puts floor in path of nearest elevator
			  mov elev2.dnPath[edi], 1
		    .ELSE
			  mov elev1.dnPath[edi], 1
		    .ENDIF
		 .ELSEIF elev1.dist[edi] < 0 && elev2.dist[edi] > 0 ; if only one elevator is below 
		    mov elev1.dnPath[edi], 1
		 .ELSEIF elev2.dist[edi] < 0 && elev1.dist[edi] > 0 ; then that elevator has the floor put in its path
		    mov elev2.dnPath[edi], 1
		 .ELSE
		    mov al, elev2.dist
		    .IF elev1.dist > al ; but if both elevators are below the floor, then whichever one 
								  ; is furthest from the top floor (i.e. the one which will start going up
								  ; soonest and thus back down soonest) has the floor put in its down path
			  mov elev1.dnPath[edi], 1
		    .ELSE
			  mov elev2.dnPath[edi], 1
		    .ENDIF
		 .ENDIF
	   .ENDIF
      
	   endDn:
		popad

ENDM


