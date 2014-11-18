INCLUDE Irvine32.inc
INCLUDE Macros.inc

   SZ equ 4	; number of floors
   sNum equ 16 ; 4 sensors per floor
   eNum equ 2	; 2 elevators
   
   elevator STRUC

      upPath BYTE SZ dup (?)
      dnPath BYTE SZ dup (?)
      dist SBYTE SZ dup (?)	; positive distance means it's below the floor, negative means above
      dirBit SBYTE ?		; -1 down, +1 up, 0 not moving
      loc BYTE ?
      door BYTE ?			; 0 is closed, 4 is open
      doorDir BYTE ?		; -1 is closing, 1 is opening, 0 is neither
      timer BYTE 0			; door timer

   elevator ENDS
   
.data
   
   windowRect  SMALL_RECT	<0, 0, 79, 50>	; for resizing the console window
   outHandle	HANDLE   0
   e1_button BYTE 0,0,0,0
   e2_button BYTE 0,0,0,0
   floor BYTE "Floor: ", 0
   elev1 elevator <,,,0,1,0,0,0>			; starts on bottom floor with doors closed
   elev2 elevator <,,,0,SZ,0,0,0>			; starts on top floor with doors closed
   sens1 WORD 0F000h
   sens2 WORD 000Fh
   eChoice BYTE ?
   FIRE_text BYTE "FIRE ALARM! (Press 'ESC' to end the alarm)              ", 0
   END_FIRE_text BYTE "Press `ESC' at any time to end program                   ", 0
   test1 BYTE "Elevator 1", 0
   test2 BYTE "Elevator 2", 0
   door BYTE "Doors: ", 0
   closing BYTE "closing", 0
   opening BYTE "opening", 0
   open BYTE "open   ", 0
   closed BYTE "closed ", 0
   dash1 BYTE "----------", 0
   dash2 BYTE "---------", 0
   dash3 BYTE "-------", 0
   direction BYTE "Direction: ", 0
   UP_ARROW BYTE 01Eh,"      ", 0
   DN_ARROW BYTE 01Fh,"      ", 0
   stopped BYTE "stopped", 0
   F1_UP BYTE 0
   F2_UP BYTE 0
   F2_DN BYTE 0
   F3_UP BYTE 0
   F3_DN BYTE 0
   F4_DN BYTE 0
   flr1 BYTE "Floor 1", 0
   flr2 BYTE "Floor 2", 0
   flr3 BYTE "Floor 3", 0
   flr4 BYTE "Floor 4", 0
   instr1 BYTE "Elevator 1 Buttons: '1' = 1, '2' = 2, '3' = 3, '4' = 4, 'c' = door close", 0
   e2button BYTE "Elevator 2 Buttons: '!' = 1, '@' = 2, '#' = 3, '$' = 4, 'C' = door close", 0
   instr2 BYTE "Floor 1 UP = 5   Floor 2 UP = 6 DN = ^   Floor 3 UP = 7 DN = &   Floor 4 DN = 8", 0
   instr3 BYTE "ALARM = 'F' or 'f'        ", 0
   
.code

ELEV_MOVE PROC

	PUSHAD

	.IF elev1.loc == 3                                    ; checking if the elevator has reached a floor it was called to by an up/dn button
	   .IF elev1.dirBit == 0                              ; if the elevator is already at that floor, the up/dn button is turned off
		 .IF F3_UP == 1                                  ; this .IF statement is for the third floor
		    mov elev1.doordir, 1
		    mov F3_UP, 0
		    mov elev1.dirBit, 1
		 .ELSEIF F3_DN == 1
		    mov elev1.doordir, 1
		    mov F3_DN, 0
		    mov elev1.dirBit, -1
		 .ENDIF
	   .ELSEIF elev1.dirBit == 1 && elev1.door > 0        ; forces the door to re-open if it's on floor 3 and the up button is pressed
		 .IF F3_UP == 1
		    mov elev1.doorDir, 1
		    mov F3_UP, 0
		 .ENDIF
	   .ELSEIF elev1.dirBit == -1 && elev1.door > 0       ; same but if the down button is pressed
		 .IF F3_DN == 1
		    mov elev1.doorDir, 1
		    mov F3_DN, 0
		 .ENDIF
	   .ENDIF
	.ELSEIF elev1.loc == 2                                ; floor 2's set of logic
	   .IF elev1.dirBit == 0
		 .IF F2_UP == 1
		    mov elev1.doordir, 1
		    mov F2_UP, 0
		    mov elev1.dirBit, 1
		 .ELSEIF F2_DN == 1
		    mov elev1.doordir, 1
		    mov F2_DN, 0
		    mov elev1.dirBit, -1
		 .ENDIF
	   .ELSEIF elev1.dirBit == 1 && elev1.door > 0        
		 .IF F2_UP == 1
		    mov elev1.doorDir, 1
		    mov F2_UP, 0
		 .ENDIF
	   .ELSEIF elev1.dirBit == -1 && elev1.door > 0
		 .IF F2_DN == 1
		    mov elev1.doorDir, 1
		    mov F2_DN, 0
		 .ENDIF
	   .ENDIF
	.ELSEIF elev1.loc == 4 && F4_DN == 1                  ; floors 1 and 4 are simpler since they only have a down and an up button, respectively
	   mov elev1.doorDir, 1
	   mov F4_DN, 0
	.ELSEIF elev1.loc == 1 && F1_UP == 1
	   mov elev1.doorDir, 1
	   mov F1_UP, 0   
	.ENDIF

	.IF elev2.loc == 3                                    ; this set of IF/ELSEIF statements is identical to the set above, except forelevator 2 instead of elevator 1
	   .IF elev2.dirBit == 0
		 .IF F3_UP == 1
		    mov elev2.doordir, 1
		    mov F3_UP, 0
		    mov elev2.dirBit, 1
		 .ELSEIF F3_DN == 1
		    mov elev2.doordir, 1
		    mov F3_DN, 0
		    mov elev2.dirBit, -1
		 .ENDIF
	   .ELSEIF elev2.dirBit == 1 && elev2.door > 0
		 .IF F3_UP == 1
		    mov elev2.doorDir, 1
		    mov F3_UP, 0
		 .ENDIF
	   .ELSEIF elev2.dirBit == -1 && elev2.door > 0
		 .IF F3_DN == 1
		    mov elev2.doorDir, 1
		    mov F3_DN, 0
		 .ENDIF
	   .ENDIF
	.ELSEIF elev2.loc == 2
	   .IF elev2.dirBit == 0
		 .IF F2_UP == 1
		    mov elev2.doordir, 1
		    mov F2_UP, 0
		    mov elev2.dirBit, 1
		 .ELSEIF F2_DN == 1
		    mov elev2.doordir, 1
		    mov F2_DN, 0
		    mov elev2.dirBit, -1
		 .ENDIF
	   .ELSEIF elev2.dirBit == 1 && elev2.door > 0
		 .IF F2_UP == 1
		    mov elev2.doorDir, 1
		    mov F2_UP, 0
		 .ENDIF
	   .ELSEIF elev2.dirBit == -1 && elev2.door > 0
		 .IF F2_DN == 1
		    mov elev2.doorDir, 1
		    mov F2_DN, 0
		 .ENDIF
	   .ENDIF
	.ELSEIF elev2.loc == 4 && F4_DN == 1
	   mov elev2.doorDir, 1
	   mov F4_DN, 0
	.ELSEIF elev2.loc == 1 && F1_UP == 1
	   mov elev2.doorDir, 1
	   mov F1_UP, 0   
	.ENDIF

	.IF (dword PTR elev1.dnPath) == 0 && (dword PTR elev1.upPath) == 0 && elev1.doorDir == 0 && elev1.door == 0 ;----------- checks if the 1st elevator has no destinations set
	   mov elev1.dirBit, 0
	.ENDIF

	.IF (dword PTR elev2.dnPath) == 0 && (dword PTR elev2.upPath) == 0 && elev2.doorDir == 0 && elev2.door == 0 ;----------- same as above except with 2nd elevator
	   mov elev2.dirBit, 0
	.ENDIF


	.IF elev1.upPath[0] == 1 && (dword PTR elev1.dnPath) == 0 && elev1.loc > 1       ;-------------------------------------------------------;
	   .IF elev1.dirBit == 0
	      mov elev1.dirBit, -1
	   .ENDIF
   
	.ELSEIF elev1.upPath[1] == 1 && (dword PTR elev1.dnPath) == 0 && elev1.loc > 2   ; This is the logic for setting the 1st elevator's direction.
	   .IF elev1.dirBit == 0
			mov elev1.dirBit, -1                                                          ; Basically, if the elevator has floors in one of its paths
	   .ENDIF															 ; and the other path is empty,
																	 ; then, based on the elevator's location, this procedure
	.ELSEIF elev1.upPath[1] == 1 && (dword PTR elev1.dnPath) == 0 && elev1.loc < 2   ; sets the elevator's direction
	   .IF elev1.dirBit == 0
	      mov elev1.dirBit, 1
	   .ENDIF
   
	.ELSEIF elev1.upPath[2] == 1 && (dword PTR elev1.dnPath) == 0 && elev1.loc > 3
	   .IF elev1.dirBit == 0
	      mov elev1.dirBit, -1
	   .ENDIF
   
	.ELSEIF elev1.upPath[2] == 1 && (dword PTR elev1.dnPath) == 0 && elev1.loc < 3
	   .IF elev1.dirBit == 0
	      mov elev1.dirBit, 1
	   .ENDIF
   
	.ELSEIF elev1.upPath[3] == 1 && (dword PTR elev1.dnPath) == 0 && elev1.loc < 4
	   .IF elev1.dirBit == 0
	      mov elev1.dirBit, 1
	   .ENDIF
   
	.ELSEIF elev1.dnPath[0] == 1 && (dword PTR elev1.upPath) == 0 && elev1.loc > 1
	   .IF elev1.dirBit == 0
	      mov elev1.dirBit, -1
	   .ENDIF
 
	.ELSEIF elev1.dnPath[1] == 1 && (dword PTR elev1.upPath) == 0 && elev1.loc > 2
	   .IF elev1.dirBit == 0
	      mov elev1.dirBit, -1
	   .ENDIF
   
	.ELSEIF elev1.dnPath[1] == 1 && (dword PTR elev1.upPath) == 0 && elev1.loc < 2
	   .IF elev1.dirBit == 0
	      mov elev1.dirBit, 1
	   .ENDIF
   
	.ELSEIF elev1.dnPath[2] == 1 && (dword PTR elev1.upPath) == 0 && elev1.loc > 3
	   .IF elev1.dirBit == 0
	      mov elev1.dirBit, -1
	   .ENDIF
   
	.ELSEIF elev1.dnPath[2] == 1 && (dword PTR elev1.upPath) == 0 && elev1.loc < 3
	   .IF elev1.dirBit == 0
	      mov elev1.dirBit, 1
	   .ENDIF

	.ELSEIF elev1.dnPath[3] == 1 && (dword PTR elev1.upPath) == 0 && elev1.loc < 4
	   .IF elev1.dirBit == 0
	      mov elev1.dirBit, 1
	   .ENDIF
	.ENDIF

	.IF elev2.upPath[0] == 1 && (dword PTR elev2.dnPath) == 0 && elev2.loc > 1                   ;--------------------------------------------------;
	   .IF elev2.dirBit == 0
	      mov elev2.dirBit, -1
	   .ENDIF                                                                      ; This is the same logic, but for elevator 2, so
																			   ; any comments here would be redundant
	.ELSEIF elev2.upPath[1] == 1 && (dword PTR elev2.dnPath) == 0 && elev2.loc > 2
	   .IF elev2.dirBit == 0
	      mov elev2.dirBit, -1
	   .ENDIF 
   
	.ELSEIF elev2.upPath[1] == 1 && (dword PTR elev2.dnPath) == 0 && elev2.loc < 2
	   .IF elev2.dirBit == 0
	      mov elev2.dirBit, 1
	   .ENDIF 
   
	.ELSEIF elev2.upPath[2] == 1 && (dword PTR elev2.dnPath) == 0 && elev2.loc > 3
	   .IF elev2.dirBit == 0
	      mov elev2.dirBit, 1
	   .ENDIF 
   
	.ELSEIF elev2.upPath[2] == 1 && (dword PTR elev2.dnPath) == 0 && elev2.loc < 3
	   .IF elev2.dirBit == 0
	      mov elev2.dirBit, 1
	   .ENDIF 
   
	.ELSEIF elev2.upPath[3] == 1 && (dword PTR elev2.dnPath) == 0 && elev2.loc < 4
	   .IF elev2.dirBit == 0
	      mov elev2.dirBit, 1
	   .ENDIF 
   
	.ELSEIF elev2.dnPath[0] == 1 && (dword PTR elev2.upPath) == 0 && elev2.loc > 1
	   .IF elev2.dirBit == 0
	      mov elev2.dirBit, -1
	   .ENDIF 
 
	.ELSEIF elev2.dnPath[1] == 1 && (dword PTR elev2.upPath) == 0 && elev2.loc > 2
	   .IF elev2.dirBit == 0
	      mov elev2.dirBit, -1
	   .ENDIF 
   
	.ELSEIF elev2.dnPath[1] == 1 && (dword PTR elev2.upPath) == 0 && elev2.loc < 2
	   .IF elev2.dirBit == 0
	      mov elev2.dirBit, 1
	   .ENDIF 
   
	.ELSEIF elev2.dnPath[2] == 1 && (dword PTR elev2.upPath) == 0 && elev2.loc > 3
	   .IF elev2.dirBit == 0
	      mov elev2.dirBit, -1
	   .ENDIF 
   
	.ELSEIF elev2.dnPath[2] == 1 && (dword PTR elev2.upPath) == 0 && elev2.loc < 3
	   .IF elev2.dirBit == 0
	      mov elev2.dirBit, 1
	   .ENDIF 

	.ELSEIF elev2.dnPath[3] == 1 && (dword PTR elev2.upPath) == 0 && elev2.loc < 4
	   .IF elev2.dirBit == 0
	      mov elev2.dirBit, 1
	   .ENDIF 
	.ENDIF

	.IF elev1.door == 0 && elev1.doorDir == 0       ; door closed and not opening
	   .IF elev1.dirBit == -1                       ; elevator 1 going down
		 .IF sens1 != 0F000h                       ; checks to make sure the elevator is not already on the first floor
		    shl sens1, 1                           ; moves the elevator one sensor down by shifting the block of four sensors 1 sensor down
		 .ENDIF
      
		 .IF sens1 == 00F0h                        ; checking the elevator is on floor 3
		    mov elev1.loc, 3
		    mov elev1.dist[3], 1                   ; these statements set the distance from the elevator to all floors
		    mov elev1.dist[2], 0                      
		    mov elev1.dist[1], -1
		    mov elev1.dist[0], -2
   
		    .IF elev1.dnPath[2] == 1               ; checks if the current floor is in the elevator's path
			  mov elev1.doorDir, 1                ; if it is, the elevator stops here, opens the doors, and removes
			  mov elev1.dnPath[2], 0              ; this floor from its path
			  mov F3_DN, 0
		    .ELSEIF elev1.upPath[2] == 1 && elev1.upPath[3] == 0 && elev1.dnPath[3] == 0   ; if elevator is going down to retrieve someone going up
			  mov elev1.doorDir, 1                                  ; from a lower floor
			  mov elev1.upPath[2], 0
			  mov F3_UP, 0
		    .ENDIF
		 .ELSEIF sens1 == 0F00h                           ; checks if the elevator is now at floor 2                            
		    mov elev1.loc, 2
		    mov elev1.dist[3], 2
		    mov elev1.dist[2], 1
		    mov elev1.dist[1], 0
		    mov elev1.dist[0], -1
         
		    .IF elev1.dnPath[1] == 1                      ; checking if floor is in path
			  mov elev1.doorDir, 1
			  mov elev1.dnPath[1], 0
			  mov F2_DN, 0
		    .ELSEIF elev1.upPath[1] == 1 && (word PTR elev1.upPath[2]) == 0  && (word PTR elev1.dnPath[2]) == 0  ; if elevator is going down to retrieve someone going up
			  mov elev1.doorDir, 1                                              ; from a lower level
			  mov elev1.upPath[1], 0
			  mov F2_UP, 0
		    .ENDIF
		 .ELSEIF sens1 == 0F000h                     ; checks if elevator is on the 1st floor
		    mov elev1.loc, 1
		    mov elev1.dist[3], 3
		    mov elev1.dist[2], 2
		    mov elev1.dist[1], 1
		    mov elev1.dist[0], 0
         
			  mov elev1.dirBit, 1				; sets the elevator direction to stopped
			  mov elev1.doorDir, 1                  ; starts opening the door
			  mov elev1.dnPath, 0                   ; removes the first floor from both the up and down paths
			  mov elev1.upPath, 0
			  mov F1_UP, 0   
		 .ENDIF
	   .ELSEIF elev1.dirBit == 1					; elevator 1 going up
		 .IF sens1 != 000Fh						; tests to make sure the elevator is not at the top floor yet
		    shr sens1, 1						; moves the elevator one sensor up
		 .ENDIF
      
		 .IF  sens1 == 00F0h                         ; checking if elevator is at floor 3   
		    mov elev1.loc, 3                         ; sets the elevator location
		    mov elev1.dist[3], 1                     ; once again this sets the distance from the elevator to each floor
		    mov elev1.dist[2], 0
		    mov elev1.dist[1], -1
		    mov elev1.dist[0], -2
         
		    .IF elev1.upPath[2] == 1                 ; if the current floor is in its path, elevator stops, opens doors
			  mov elev1.doorDir, 1                  ; and removes the floor from its path
			  mov elev1.upPath[2], 0
			  mov F3_UP, 0
		    .ELSEIF elev1.dnPath[2] == 1 && elev1.upPath[3] == 0 && elev1.dnPath[3] == 0  ; but sometimes the elevator has to go up to go back down
			  mov elev1.doorDir, 1
			  mov elev1.dnPath[2], 0
			  mov F3_DN, 0
		    .ENDIF
		 .ELSEIF sens1 == 0F00h                      ; elevator at 2nd floor?
		    mov elev1.loc, 2
		    mov elev1.dist[3], 2
		    mov elev1.dist[2], 1
		    mov elev1.dist[1], 0
		    mov elev1.dist[0], -1     
         
		    .IF elev1.upPath[1] == 1 
			  mov elev1.doorDir, 1
			  mov elev1.upPath[1], 0
			  mov F2_UP, 0
		    .ELSEIF elev1.dnPath[1] == 1 && (word PTR elev1.upPath[2]) == 0 && (word PTR elev1.dnPath[2]) == 0
			  mov elev1.doorDir, 1
			  mov elev1.dnPath[1], 0
			  mov F2_DN, 0
		    .ENDIF
		 .ELSEIF sens1 == 000Fh
		    mov elev1.loc, 4
		    mov elev1.dist[3], 0
		    mov elev1.dist[2], -1
		    mov elev1.dist[1], -2
		    mov elev1.dist[0], -3         
        
		    .IF elev1.upPath[3] == 1 || elev1.dnPath[3] == 1
			  mov elev1.dirBit, -1
			  mov elev1.doorDir, 1
			  mov elev1.upPath[3], 0
			  mov elev1.dnPath[3], 0
			  mov F4_DN, 0
		    .ENDIF
         
		 .ENDIF
      
	   .ENDIF
	.ELSEIF elev1.doorDir == 1					; door opening but not all the way open
         
		    .IF elev1.door == 4
			  mov elev1.doorDir, 0
		    .ENDIF
		    .IF elev1.door < 4
			  inc elev1.door
		    .ENDIF
         
	.ELSEIF elev1.doorDir == 0 && elev1.door == 4     ; door not moving and door open
		    .IF elev1.timer == 8                     ; This timer keeps the doors open for 4 seconds
			  mov elev1.timer, 0
			  mov elev1.doorDir, -1                 ; once the timer reaches 8 (8 * 500ms = 4 seconds), the doors start to close
		    .ELSE
			  inc elev1.timer
		    .ENDIF
	 .ENDIF
 
	.IF elev1.doorDir == -1                           ; door closing
		 .IF elev1.door != 0
		    dec elev1.door
		 .ELSE
		    mov elev1.doorDir, 0
		 .ENDIF
	.ENDIF

	.IF elev2.door == 0 && elev2.doorDir == 0		; door closed and not opening
	   .IF elev2.dirBit == -1					; elevator 2 going down
      
		 .IF sens2 != 0F000h
		    shl sens2, 1						; moves the elevator one sensor down
		 .ENDIF
                           
		 .IF sens2 == 00F0h						; checking if it needs to stop (this is the same logic as for elevator 1)
		    mov elev2.loc, 3
		    mov elev2.dist[3], 1
		    mov elev2.dist[2], 0
		    mov elev2.dist[1], -1
		    mov elev2.dist[0], -2
         
		    .IF elev2.dnPath[2] == 1 
			  mov elev2.doorDir, 1
			  mov elev2.dnPath[2], 0
			  mov F3_DN, 0
		    .ELSEIF elev2.upPath[2] == 1 && (word PTR elev2.dnPath[0]) == 0 && (word PTR elev2.upPath) == 0
			  mov elev2.doorDir, 1
			  mov elev2.upPath[2], 0
			  mov F3_UP, 0
		    .ENDIF
		 .ELSEIF sens2 == 0F00h
		    mov elev2.loc, 2
		    mov elev2.dist[3], 2
		    mov elev2.dist[2], 1
		    mov elev2.dist[1], 0
		    mov elev2.dist[0], -1
         
		    .IF elev2.dnPath[1] == 1 
			  mov elev2.doorDir, 1
			  mov elev2.dnPath[1], 0
			  mov F2_DN, 0
		    .ELSEIF elev2.upPath[1] == 1 && elev2.dnPath[0] == 0 && elev2.upPath == 0
			  mov elev2.doorDir, 1
			  mov elev2.upPath[1], 0
			  mov F2_UP, 0
		    .ENDIF
		 .ELSEIF sens2 == 0F000h
		    mov elev2.loc, 1
		    mov elev2.dist[3], 3
		    mov elev2.dist[2], 2
		    mov elev2.dist[1], 1
		    mov elev2.dist[0], 0
         
			  mov elev2.dirBit, 1
			  mov elev2.doorDir, 1
			  mov elev2.dnPath, 0
			  mov elev2.upPath, 0
			  mov F1_UP, 0
		 .ENDIF
	   .ELSEIF elev2.dirBit == 1				; elevator 2 going up
		 .IF sens2 != 000Fh
		    shr sens2, 1                        ; moves the elevator one sensor up
		 .ENDIF
                          
		 .IF  sens2 == 00F0h				; checking for stops
		    mov elev2.loc, 3                    ; sets the elevator location
         
		    mov elev2.dist[3], 1
		    mov elev2.dist[2], 0
		    mov elev2.dist[1], -1
		    mov elev2.dist[0], -2
		    .IF elev2.upPath[2] == 1
			  mov elev2.doorDir, 1
			  mov elev2.upPath[2], 0
			  mov F3_UP, 0
		    .ELSEIF elev2.dnPath[2] == 1 && elev2.upPath[3] == 0 && elev2.dnPath[3] == 0
			  mov elev2.doorDir, 1
			  mov elev2.dnPath[2], 0
			  mov F3_DN, 0            
		    .ENDIF
		 .ELSEIF sens2 == 0F00h
		    mov elev2.loc, 2
		    mov elev2.dist[3], 2
		    mov elev2.dist[2], 1
		    mov elev2.dist[1], 0
		    mov elev2.dist[0], -1
		    .IF elev2.upPath[1] == 1
			  mov elev2.doorDir, 1
			  mov elev2.upPath[1], 0
			  mov F2_UP, 0
		    .ELSEIF elev2.dnPath[1] == 1 && (word PTR elev2.upPath[2]) == 0 && (word PTR elev2.dnPath[2]) == 0
			  mov elev2.doorDir, 1
			  mov elev2.dnPath[1], 0
			  mov F2_DN, 0            
		    .ENDIF
		 .ELSEIF sens2 == 000Fh
		    mov elev2.loc, 4
		    mov elev2.dist[3], 0
		    mov elev2.dist[2], -1
		    mov elev2.dist[1], -2
		    mov elev2.dist[0], -3
			  mov F4_DN, 0
			  mov elev2.dirBit, -1
			  mov elev2.doorDir, 1
			  mov elev2.upPath[3], 0
			  mov elev2.dnPath[3], 0
		 .ENDIF
      
	   .ENDIF
	.ELSEIF elev2.doorDir == 1       ; door opening but not all the way open
		    .IF elev2.door < 4
			  inc elev2.door
		    .ENDIF
		    .IF elev2.door == 4
			  mov elev2.doorDir, 0
		    .ENDIF
	.ELSEIF elev2.doorDir == 0 && elev2.door == 4     ; door not moving and door open
		    .IF elev2.timer == 8
			  mov elev2.timer, 0
			  mov elev2.doorDir, -1
		    .ELSE
			  inc elev2.timer
		   .ENDIF
	.ENDIF
 
	.IF elev2.doorDir == -1                           ; door closing
		 .IF elev2.door != 0
		    dec elev2.door
		 .ELSE
		    mov elev2.doorDir, 0
		 .ENDIF
	.ENDIF

	   movzx edi, elev1.loc
	   dec edi

	   .IF e1_button[edi] == 1
		 .IF (sens1 == 0F000h || sens1 == 0F00H || sens1 == 0F0h || sens1 == 0Fh)
		    mov e1_button[edi], 0
		 .ENDIF
	   .ENDIF
   
	   movzx edi, elev2.loc
	   dec edi
	   .IF e2_button[edi] == 1
		 .IF (sens2 == 0F000h || sens2 == 0F00H || sens2 == 0F0h || sens2 == 0Fh)
		    mov e2_button[edi], 0
		 .ENDIF
	   .ENDIF
  
	call Printing                       ; putting this call here ensures it gets called during both normal and FIRE operation
   
	POPAD

	ret

ELEV_MOVE ENDP

ALARM PROC						   ; FIRE ALARM PROCEDURE ;

	mov dh, 0
	mov dl, 0
	call GotoXY

	mov edx, OFFSET FIRE_text			  ; prints the fire alarm message to the top of the screen
	call WriteString
	call Crlf

	mov edi, 0							; setting up array index
	   mov elev1.dnPath[edi], 1                  ; puts floor 1 in the down path of both elevators
	   mov elev1.dirBit, -1
	   mov elev2.dnPath[edi], 1                  ; and sets their directions to down
	   mov elev2.dirBit, -1

	FIRE_LOOP:                                   ; This loop clears all other floors from both elevators' paths
   
	   inc edi
	   cmp edi, sz
	   je END_FIRE_LOOP
	   mov elev1.upPath[edi], 0
	   mov elev1.dnPath[edi], 0
	   mov elev2.dnPath[edi], 0
	   mov elev2.upPath[edi], 0
	   jmp FIRE_LOOP
   
	END_FIRE_LOOP:                                ; This loop will keep the fire alarm going until the ESC key is pressed

	   mov eax, 500
	   .IF elev1.loc == 1
		 mov elev1.timer, 0                      ; This keeps the elevator doors from closing
	   .ENDIF
	   .IF elev2.loc == 1
		 mov elev2.timer, 0
	    .ENDIF
	   call Delay
	   call ReadKey                               ; reads in the most recent key from the buffer
	   .IF al == 1Bh                              ; hex code for the escape key
		 jmp FIRE_END
	   .ENDIF
	   call ELEV_MOVE
	   jmp END_FIRE_LOOP
   
	FIRE_END:                                    ; end of the fire alarm
		mov dh, 0
		mov dl, 0
		call GotoXY
		mov edx, OFFSET END_FIRE_text
		call WriteString
		call Crlf

	ret

ALARM ENDP

ButtonPrint PROC             ; procedure for printing the elevator buttons

   mov bl, [edi]
   mov ecx, 1
   mov al, '|'
   call WriteChar

	BLOOP:                        ; loops through all 4 buttons
      
	   .IF bl == 0
		 mov eax, ecx
		 call writeDec
	   .ELSE
		 mov eax, BLACK + (WHITE * 16)       ; highlights the button if it has been pressed
		 call SetTextColor
		 mov eax, ecx
		 call writeDec
		 mov eax, WHITE + (BLACK * 16)       ; changes the text color back so the rest of the display is not affected
		 call SetTextColor
	   .ENDIF
   
	   mov al, '|'					; pipe to separate the buttons
	   call WriteChar
	   cmp cl, 4
	   je end_button
	   inc cl
	   inc edi
	   mov bl, [edi]
	   jmp BLOOP

	end_button:
		ret
   
ButtonPrint ENDP

DN_PRINT PROC                       ; procedure for printing each floor's down button after it has been pressed

	mov eax, BLACK + (WHITE * 16)
	call SetTextColor
	mov al, 1Fh
	call WriteChar
	mov eax, WHITE + (BLACK * 16)
	call SetTextColor

	ret

DN_PRINT ENDP

UP_PRINT PROC                       ; same as the down button procedure but for the up  button

	mov eax, BLACK + (WHITE * 16)
	call SetTextColor
	mov al, 1Eh
	call WriteChar
	mov eax, WHITE + (BLACK * 16)
	call SetTextColor

	ret
UP_PRINT ENDP

SEV_SEG1 PROC                       ; prints a seven segment display based on a number passed into it using the dh register

   mov bx, dx
   call GotoXY
   mov al, ' '
   .IF ah == 1
      call WriteChar
      call WriteChar
      call WriteChar
      mov dx, bx
      inc dh
      call GoToXY
      call WriteChar
      call WriteChar
      mov al, '|'
      call WriteChar
      mov dx, bx
      add dh, 2      
      call GotoXY
      mov al, ' '
      call Writechar
      call WriteChar
      mov al, '|'
      call WriteChar
   .ELSEIF ah == 2
      call Writechar
      mov al, '_'
      call WriteChar
      mov al, ' '
      call WriteChar
      mov dx, bx
      inc dh
      call GotoXY
      call Writechar
      mov al, '_'
      call WriteChar
      mov al, '|'
      call WriteChar
      mov dx, bx
      add dh, 2
      call GotoXY
      call WriteChar
      mov al, '_'
      call Writechar
      mov al, ' '
      call WriteChar
   .ELSEIF ah == 3
      call WriteChar
      mov al, '_'
      call WriteChar
      mov dx, bx
      inc dh
      call GotoXY
      mov al, ' '
      call WriteChar
      mov al, '_'
      call Writechar
      mov al, '|'
      call WriteChar
      mov dx, bx
      add dh, 2
      call GotoXY
      mov al, ' '
      call Writechar
      mov al, '_'
      call Writechar
      mov al, '|'
      call WriteChar
   .ELSEIF ah == 4
      call writechar
      call writechar
      mov dx, bx
      inc dh
      call GotoXY
      mov al, '|'
      call Writechar
      mov al, '_'
      call Writechar
      mov al, '|'
      call Writechar
      mov dx, bx
      add dh, 2
      call GotoXY
      mov al, ' '
      call Writechar
      call Writechar
      mov al, '|'
      call Writechar
   .ENDIF
ret

SEV_SEG1 ENDP

WriteUp PROC      ; just a simple procedure for writing an up arrow
	mov al, 1Eh
	call WriteChar
	ret
WriteUp ENDP

WriteDn PROC      ; writes a down arrow
	mov al, 1Fh
	call WriteChar
	ret
WriteDn ENDP

WriteSpace PROC   ; writes a space
	mov al, ' '
	call WriteChar
	ret
WriteSpace ENDP

arrow1 PROC       ; procedure for writing the direction arrow for elevator 1
	call GotoXY
	mov cx, 3
	.IF elev1.dirBit == -1     ; elevator going down
		jmp DN_LOOP1
	.ELSEIF elev1.dirBit == 0  ; elevator stationary
		jmp ST_LOOP1
	.ENDIF

	UP_LOOP1:                  ; loop for writing the up arrow
		mov bx, 5             ; arrow is 5 lines wide and 3 lines tall

		UP_LOOP1A:
		  .IF cx == 3    
		    .IF bx == 3
			  call WriteUp
		    .ELSE 
			  call WriteSpace
		    .ENDIF
		  .ELSEIF cx == 2
		    .IF bx != 5 && bx != 1
                call WriteUp
              .ELSE 
                call WriteSpace
              .ENDIF
            .ELSE
                call WriteUp
            .ENDIF
		 
		  dec bx
		  jnz UP_LOOP1A
   
	inc dh
     call GotoXY
     dec cx
     jnz UP_LOOP1

   jmp ENDARROW1

	DN_LOOP1:            ; writes the down arrow
		mov bx, 5   

		DN_LOOP1A:
            .IF cx == 1
		    .IF bx == 3
			  call WriteDn
		    .ELSE 
			  call WriteSpace
		    .ENDIF
		 .ELSEIF cx == 2
		    .IF bx != 5 && bx != 1
			  call WriteDn
		    .ELSE 
			  call WriteSpace
		    .ENDIF
		 .ELSE
		    call WriteDn
		 .ENDIF

		 dec bx
		 jnz DN_LOOP1A
   
	inc dh
	call GotoXY
	dec cx
	jnz DN_LOOP1
   
   jmp ENDARROW1
   
	ST_LOOP1:            ; overwrites the arrow with blank spaces

	   mov bx, 5
   
	   ST_LOOP1A:
      
		 call WriteSpace
		 dec bx
		 jnz ST_LOOP1A
   
	   inc dh
	   call GotoXY 
	   dec cx
	   jnz ST_LOOP1

	ENDARROW1:
		ret
arrow1 ENDP

arrow2 PROC          ; identical to the arrow1 proc but for elevator 2
	call GotoXY
	mov cx, 3
	.IF elev2.dirBit == -1
	   jmp DN_LOOP2
	.ELSEIF elev2.dirBit == 0
	   jmp ST_LOOP2
	.ENDIF

	UP_LOOP2:
	   mov bx, 5   

	   UP_LOOP2A:
      	 .IF cx == 3
		    .IF bx == 3
			  call WriteUp
		    .ELSE 
			  call WriteSpace
		    .ENDIF
		 .ELSEIF cx == 2
		    .IF bx != 5 && bx != 1
			  call WriteUp
		    .ELSE 
			  call WriteSpace
		    .ENDIF
		 .ELSE
		    call WriteUp
		 .ENDIF
      
		 dec bx
		 jnz UP_LOOP2A
   
	   inc dh
	   call GotoXY
	   dec cx
	   jnz UP_LOOP2
	jmp ENDarrow2

	DN_LOOP2:
	   mov bx, 5   
	
	   DN_LOOP2A:
     	 .IF cx == 1
		    .IF bx == 3
			  call WriteDn
		    .ELSE 
			  call WriteSpace
		    .ENDIF
		 .ELSEIF cx == 2
		    .IF bx != 5 && bx != 1
			  call WriteDn
		    .ELSE 
			  call WriteSpace
		    .ENDIF
		 .ELSE
		    call WriteDn
		 .ENDIF
      
		 dec bx
	      jnz DN_LOOP2A
	   
	   inc dh
	   call GotoXY
	   dec cx
	   jnz DN_LOOP2
   
	jmp ENDarrow2
   
	ST_LOOP2:

	   mov bx, 5
   
	   ST_LOOP2A:
      
		 call WriteSpace
		 dec bx
		 jnz ST_LOOP2A
   
	   inc dh
	   call GotoXY 
	   dec cx
	   jnz ST_LOOP2

	ENDarrow2:
		ret	
arrow2 ENDP

Printing PROC					  ; While a lot of code, the printing procedure is pretty simple
							  ; it uses call GotoXY to set the console coordinates for each printing
   mov dl, 30                        ; then it uses data from the floor buttons and the elevator structures
   mov dh, 7                         ; to print out the corresponding information
   call GotoXY
   
   mov edx, OFFSET flr4
   call WriteString
   mov dl, 30
   mov dh, 8
   call GotoXY
   mov edx, OFFSET dash3
   call WriteString
   
   mov dl, 15
   mov dh, 7
   call GotoXY
   
   mov edx, OFFSET test1
   call WriteString
  
   mov dl, 15
   mov dh, 8
   mov ah, elev1.loc
   call sev_seg1
   
   mov dl, 19
   mov dh, 8
   call arrow1
   
   mov dl, 15
   mov dh, 12
   call GotoXY
   
   mov edx, OFFSET test1
   call WriteString
   
   
   mov dl, 15
   mov dh, 13
   mov ah, elev1.loc
   call sev_seg1
   
   mov dl, 19
   mov dh, 13
   call arrow1
   
   mov dl, 15
   mov dh, 17
   call GotoXY
   
   mov edx, OFFSET test1
   call WriteString

   
   mov dl, 15
   mov dh, 18
   call sev_seg1
   
   mov dl, 19
   mov dh, 18
   call arrow1
   
   mov dl, 15
   mov dh, 22
   call GotoXY
   
   mov edx, OFFSET test1
   call WriteString
   
  
   
   mov dl, 15
   mov dh, 23
   mov ah, elev1.loc
   call sev_seg1
   
   mov dl, 19
   mov dh, 23
   call arrow1
   
   mov dl, 42
   mov dh, 7
   call GotoXY
   mov edx, OFFSET test2
   call WriteString

   mov dl, 42
   mov dh, 8
   mov ah, elev2.loc
   call sev_seg1
   
   mov dl, 46
   mov dh, 8
   call arrow2
   
   mov dl, 42
   mov dh, 12
   call GotoXY
   mov edx, OFFSET test2
   call WriteString
   
   
   mov dl, 42
   mov dh, 13
   mov ah, elev2.loc
   call sev_seg1
   
   mov dl, 46
   mov dh, 13
   call arrow2
   
   mov dl, 42
   mov dh, 17
   call GotoXY
   mov edx, OFFSET test2
   call WriteString
      
   mov dl, 42
   mov dh, 18
   mov ah, elev2.loc
   call sev_seg1
   
   mov dl, 46
   mov dh, 18
   call arrow2
   
   mov dl, 42
   mov dh, 22
   call GotoXY
   mov edx, OFFSET test2
   call WriteString
   
   mov dl, 42
   mov dh, 23
   mov ah, elev2.loc
   call sev_seg1
   
   mov dl, 46
   mov dh, 23
   call arrow2
   
   
   mov dl, 32
   mov dh, 9
   call GotoXY
   
   mov al, '|'
   call WriteChar
      
   .IF F4_DN == 1
      call DN_PRINT
   .ELSE
      mov al, 1Fh
      call WriteChar
   .ENDIF
   
   mov al, '|'
   call WriteChar
   
   mov dl, 32
   mov dh, 10
   call GotoXY
   
   mov al, '-'
   call WriteChar
   call WriteChar
   call WriteChar
   
   mov dl, 30
   mov dh, 12
   call GotoXY
   
   mov edx, OFFSET flr3
   call WriteString
   mov dl, 30
   mov dh, 13
   call GotoXY
   mov edx, OFFSET dash3
   call WriteString
   
   mov dl, 31
   mov dh, 14
   call GotoXY
   
   mov al, '|'
   call WriteChar
      
   .IF F3_UP == 1
      call UP_PRINT
   .ELSE
      mov al, 1Eh
      call WriteChar
   .ENDIF
   
   mov al, '|'
   call WriteChar
   
   .IF F3_DN == 1
      call DN_PRINT
   .Else
      mov al, 1Fh
      call WriteChar
   .ENDIF
   
   mov al, '|'
   call WriteChar
   
   mov dl, 31
   mov dh, 15
   call GotoXY
   
   mov al, '-'
   mov cx, 5
   dashloop1:
      call WriteChar
      dec cx
      jnz dashloop1
      
   mov dl, 30
   mov dh, 17
   call GotoXY
   
   mov edx, OFFSET flr2
   call WriteString
   mov dl, 30
   mov dh, 18
   call GotoXY
   mov edx, OFFSET dash3
   call WriteString
   
   mov dl, 31
   mov dh, 19
   call GotoXY
   
   mov al, '|'
   call WriteChar
      
   .IF F2_UP == 1
      call UP_PRINT
   .ELSE
      mov al, 1Eh
      call WriteChar
   .ENDIF
   
   mov al, '|'
   call WriteChar
   
   .IF F2_DN == 1
      call DN_PRINT
   .Else
      mov al, 1Fh
      call WriteChar
   .ENDIF
   
   mov al, '|'
   call WriteChar
   
   mov dl, 31
   mov dh, 20
   call GotoXY
   
   mov al, '-'
   mov cx, 5
   dashloop2:
      call WriteChar
      dec cx
      jnz dashloop2
   
   mov dl, 30
   mov dh, 22
   call GotoXY
   
   mov edx, OFFSET flr1
   call WriteString
   mov dl, 30
   mov dh, 23
   call GotoXY
   mov edx, OFFSET dash3
   call WriteString
   
   mov dl, 32
   mov dh, 24
   call GotoXY
   
   mov al, '|'
   call WriteChar
      
   .IF F1_UP == 1
      call UP_PRINT
   .ELSE
      mov al, 1Eh
      call WriteChar
   .ENDIF
   
   mov al, '|'
   call WriteChar
   
   mov dl, 32
   mov dh, 25
   call GotoXY
   
   mov al, '-'
   call WriteChar
   call WriteChar
   call WriteChar
   
   mov dl, 0
   mov dh, 27
   call GotoXY

   mov edx, OFFSET test1
   call WriteString
   
   mov dl, 0
   mov dh, 28
   call GotoXY
   
   mov edx, OFFSET dash1
   call WriteString
   
   mov dl, 44
   mov dh, 27
   call GotoXY
   
   mov edx, OFFSET test2
   call WriteString
   
   mov dl, 44
   mov dh, 28
   call GotoXY
   
   mov edx, OFFSET dash1
   call WriteString
   
   mov dh, 29
   mov dl, 0
   call GotoXY
   
   mov edx, OFFSET door
   call WriteString
   .IF elev1.door == 0
      mov edx, OFFSET closed
      call WriteString
   .ELSEIF elev1.door == 4
      mov edx, OFFSET open
      call WriteString
   .ELSEIF elev1.doorDir == 1
      mov edx, OFFSET opening
      call WriteString
   .ELSEIF elev1.doorDir == -1
      mov edx, OFFSET closing
      call WriteString
    .ENDIF
      
   mov dh, 29
   mov dl, 44
   call GotoXY
   
   mov edx, OFFSET door
   call WriteString
   .IF elev2.door == 0
      mov edx, OFFSET closed
      call WriteString
   .ELSEIF elev2.door == 4
      mov edx, OFFSET open
      call WriteString
   .ELSEIF elev2.doorDir == 1
      mov edx, OFFSET opening
      call WriteString
   .ELSEIF elev2.doorDir == -1
      mov edx, OFFSET closing
      call WriteString
   .ENDIF
   

   mov dh, 31
   mov dl, 0
   mov ah, elev1.loc
   call sev_seg1
   
   mov dh, 31
   mov dl, 4
   call arrow1
   
   mov dh, 35
   mov dl, 0
   call GotoXY
   mov edx, OFFSET dash2
   call WriteString
   
   mov dh, 36
   mov dl, 0
   call GotoXY
   mov edi, OFFSET e1_button
   call ButtonPrint
   
   mov dh, 37
   mov dl, 0
   call GotoXY
   mov edx, OFFSET dash2
   call WriteString
   
   mov dh, 31
   mov dl, 44
   mov ah, elev2.loc
   call sev_seg1
   
   mov dh, 31
   mov dl, 48
   call arrow2
   
   mov dh, 35
   mov dl, 44
   call GotoXY
   mov edx, OFFSET dash2
   call WriteString
   
   mov dh, 36
   mov dl, 44
   call GotoXY
   mov edi, OFFSET e2_button
   call ButtonPrint
   
   mov dh, 37
   mov dl, 44
   call GotoXY
   mov edx, OFFSET dash2
   call WriteString
     
ret

Printing ENDP

main PROC

	mov eax, WHITE + (BLACK * 16)
	call SetTextColor
	call clrscr
	INVOKE   GetStdHandle,                       ; preparation for resizing console window
		    STD_OUTPUT_HANDLE
         
	mov outHandle, eax

	INVOKE   SetConsoleWindowInfo,               ; console window resizing            
			 outHandle,
			 TRUE,
			 ADDR windowRect
	
	mov esi, 0	; initialize pointer index
	mov cl, 0		; initialize counter

	dloop1:		; loop to set distance array for elev1

	   inc cl
	   cmp cl, sz
	   je eloop1
	   inc esi
	   mov elev1.dist[esi], cl
	   jmp dloop1

	eloop1:

	mov esi, 0 ; initialize pointer index
	mov cl, -4 ; initialize counter

	dloop2:	 ; loop to set distance array for elev2

	   inc cl
	   jz eloop2      ; exit loop
	   mov elev2.dist[esi], cl
	   inc esi   
	   jmp dloop2

	eloop2:

		cLoop:
		mov dx, 0
		call GotoXY
		mov edx, OFFSET END_FIRE_text       ; this set of WriteString's and GotoXY's prints out the basic information for the program
		call WriteString                    ; e.g. the keyboard shortcuts
		mov dh, 2
		mov dl, 0
		call GotoXY
		mov edx, OFFSET instr1
		call WriteString
		mov dh, 3
		mov dl, 0
		call GotoXY
		mov edx, OFFSET e2button
		call WriteString
		mov dh, 1
		mov dl, 0
		call GotoXY
		mov edx, OFFSET instr2
		call WriteString
		mov dh, 4
		mov dl, 0
		call GotoXY
		mov edx, OFFSET instr3
		call WriteString
		mov eax, 500
		call Delay
		call ReadKey   ; reads the latest key from the key buffer
		jz next
		jnz hextest

	hextest:

		.IF al == 1Bh                    ; if ESC key is pressed, program jumps to end of program "endElev"
		   jmp endElev
		.ENDIF

		.IF al == 'F' || al == 'f'       ; F or f key starts the fire alarm
		   jmp FIRE
		.ENDIF

		.IF al == 'c'                             ; door close button
			 mov elev1.timer, 0
			 mov elev1.doorDir, -1
		.ENDIF

		.IF al == 'C'
			 mov elev2.timer, 0
			 mov elev2.doorDir, -1
		.ENDIF

		.IF al == '1'                             ; the IF and ELSEIF statments here choose what to do with various key presses
		   .IF sens1 != 0F000h
			 mov elev1.dnPath[0],1
			 mov e1_button[0], 1
			 .IF elev1.dirBit == 0               ; and this bit of logic sets the elevator's direction if the elevator is currently not moving
			    mov elev1.dirBit, -1
			 .ENDIF
		   .ELSEIF elev1.loc == 1
			 mov elev1.doorDir, 1
		   .ENDIF
   
		.ELSEIF al == '2'
		   .IF sens1 > 0F00h 
			 mov e1_button[1], 1
			 mov elev1.upPath[+1],1
			 .IF elev1.dirBit == 0
			    mov elev1.dirBit, 1
			 .ENDIF
		   .ELSEIF sens1 < 0F00h
			 mov e1_button[1], 1
			 mov elev1.dnPath[+1], 1
			 .IF elev1.dirBit == 0
			    mov elev1.dirBit, -1
			 .ENDIF
		   .ELSE
			 .IF elev1.dirBit == 0
			    mov elev1.doorDir, 1
			 .ENDIF
		   .ENDIF
   
		.ELSEIF al == '3'
		   .IF sens1 > 0F0h
			 mov e1_button[2], 1
			 mov elev1.upPath[+2],1
			 .IF elev1.dirBit == 0
			    mov elev1.dirBit, 1
			 .ENDIF
		   .ELSEIF sens1 < 0F0h
			 mov e1_button[2], 1
			 mov elev1.dnPath[+2], 1
			 .IF elev1.dirBit == 0
			    mov elev1.dirBit, -1
			 .ENDIF
		   .ELSE
			 .IF elev1.dirBit == 0
			    mov elev1.doorDir, 1
			 .ENDIF
		   .ENDIF
   
		.ELSEIF al == '4'
		   .IF sens1 != 000Fh
			 mov e1_button[3], 1
			 mov elev1.upPath[+3], 1
			 .IF elev1.dirBit == 0
			    mov elev1.dirBit, 1
			 .ENDIF
		   .ELSEIF elev1.loc == 4
			 mov elev1.doorDir, 1
		   .ENDIF
		.ELSEIF al =='!'
		   .IF sens2 != 0F000h
			 mov e2_button[0], 1
			 mov elev2.dnPath[0],1
			 .IF elev2.dirBit == 0
			    mov elev2.dirBit, -1
			 .ENDIF
		   .ELSE
			 mov elev2.doorDir, 1
		   .ENDIF
		.ELSEIF al == '@'

		   .IF sens2 > 0F00h
			 mov e2_button[1], 1
			 mov elev2.upPath[+1],1
			 .IF elev2.dirBit == 0
			    mov elev2.dirBit, 1
			 .ENDIF
		   .ELSEIF sens2 < 0F00h 
			 mov e2_button[1], 1
			 mov elev2.dnPath[+1], 1
			 .IF elev2.dirBit == 0
			    mov elev2.dirBit, -1
			 .ENDIF
		   .ELSE
			 .IF elev2.dirBit == 0
			    mov elev2.doorDir, 1
			 .ENDIF
		   .ENDIF
   
		.ELSEIF al == '#'
		   .IF sens2 > 0F0h
			 mov e2_button[2], 1
			 mov elev2.upPath[+2],1
			 .IF elev2.dirBit == 0
			    mov elev2.dirBit, 1
			 .ENDIF
		   .ELSEIF sens2 < 0F0h  
			 mov e2_button[2], 1
			 mov elev2.dnPath[+2], 1
			 .IF elev2.dirBit == 0
			    mov elev2.dirBit, -1
			 .ENDIF
		   .ELSE
			 .IF elev2.dirBit == 0
			    mov elev2.doorDir, 1
			 .ENDIF
		   .ENDIF
   
		.ELSEIF al == '$'
		   .IF sens2 != 000Fh
			 mov e2_button[3], 1
			 mov elev2.upPath[+3], 1
			 .IF elev2.dirBit == 0
			    mov elev2.dirBit, 1
			 .ENDIF
		   .ELSEIF elev2.loc == 4
			 mov elev2.doorDir, 1
		   .ENDIF

		.ELSEIF al == '5'
   		   mov F1_UP, 1
		   UP 1, elev1, elev2
   
		.ELSEIF al == '6'
   		   mov F2_UP, 1
		   UP 2, elev1, elev2

		.ELSEIF al == '7'
   		   mov F3_UP, 1
		   UP 3, elev1, elev2

		.ELSEIF al == '8'
   		   mov F4_DN, 1
		   DOWN 4, elev1, elev2
   
		.ELSEIF al == '&'
		   mov F3_DN, 1
		   DOWN 3, elev1, elev2
   
		.ELSEIF al == '^'
		   mov F2_DN, 1
		   DOWN 2, elev1, elev2
 
		.ENDIF

	next:
		call ELEV_MOVE
		jmp cLoop		; unconditional jump back to beginning of program

	FIRE:
		call ALARM
		jmp cLoop

	endElev:		; end of program after ESC key is read
		exit
main ENDP
END main