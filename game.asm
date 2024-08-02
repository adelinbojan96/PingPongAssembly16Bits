STACK SEGMENT PARA STACK 
    DB 64 DUP (' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'
    ; defining the variables needed
    WIN_WIDTH DW 140h ; 320 pixels
    WIN_HEIGHT DW 0C8h ; 200 pixels
    WIN_BOUNDS DW 6 ; variable used to check collisions early

    TIME_AUX DB 0 ; auxiliary variable used when checking if the time has changed
    
    TEXT_FIRST_PLAYER_POINTS DB '0', '$'
    TEXT_SECOND_PLAYER_POINTS DB '0', '$'

    BALL_ORIGINAL_X DW 0A0h
    BALL_ORIGINAL_Y DW 64h

    BALL_X DW 0A0h ; X position (column) of the ball
    BALL_Y DW 64h ; Y position (line) of the ball
    BALL_SIZE DW 06h ; size of the ball in pixels (3x3)
    BALL_VELOCITY_X DW 03h  
    BALL_VELOCITY_Y DW 05h  

    PADDLE_UPPER_X DW 0A0h ; centered horizontally
    PADDLE_UPPER_Y DW 0Ah  ; near the top
    PADDLE_UPPER_POINTS DB 0 ; current points of the first player (player one)

    PADDLE_LOWER_X DW 0A0h ; centered horizontally
    PADDLE_LOWER_Y DW 0B8h ; near the bottom (0C8h - 0Ah - 10h paddle height)
    PADDLE_LOWER_POINTS DB 0 ; current points of the second player 

    PADDLE_WIDTH DW 2Eh
    PADDLE_HEIGHT DW 05h
    PADDLE_VELOCITY DW 12h
DATA ENDS

CODE SEGMENT PARA 'CODE'

MAIN PROC FAR 
    ASSUME CS: CODE, DS: DATA, SS: STACK
    PUSH DS ; Push DS segment to stack
    XOR AX, AX ; Clear AX register
    PUSH AX ; Push AX to stack
    MOV AX, DATA ; Load DATA segment address to AX
    MOV DS, AX ; Load DS with DATA segment address
    POP AX ; Pop top of stack to AX
    POP AX ; Pop top of stack to AX again

    CALL CLEAR_SCREEN

CHECK_TIME: 
    MOV AH, 2Ch ; get system time
    INT 21h ; CH -> HOUR, CL -> MINUTES, DH -> SECONDS, DL -> 1/100 SECONDS

    CMP DL, TIME_AUX ; the current time equal to the previous one (TIME_AUX)?
    JE CHECK_TIME ; if yes, check again

    MOV TIME_AUX, DL ; update the time

    CALL CLEAR_SCREEN
    CALL MOVE_BALL
    CALL DRAW_BALL

    CALL MOVE_PADDLES
    CALL DRAW_PADDLES

    CALL DRAW_UI ; Add this line to draw the player's points
            
    JMP CHECK_TIME ; check the time again after execution

    RET 
MAIN ENDP


MOVE_BALL PROC NEAR
    MOV AX, BALL_VELOCITY_Y
    ADD BALL_Y, AX
    MOV AX, WIN_BOUNDS
    CMP BALL_Y, AX ; BALL_Y < WIN_BOUNDS => COLLIDED
    JL GIVE_POINT_TO_SECOND_PLAYER 

    MOV AX, WIN_HEIGHT
    SUB AX, BALL_SIZE
    SUB AX, WIN_BOUNDS
    CMP BALL_Y, AX ; BALL_Y > WIN_HEIGHT - BALL_SIZE => COLLIDED
    JG GIVE_POINT_TO_FIRST_PLAYER
    JMP MOVE_BALL_HORIZONTALLY

GIVE_POINT_TO_FIRST_PLAYER:
    INC PADDLE_UPPER_POINTS
    MOV AL, PADDLE_UPPER_POINTS
    ADD AL, 30h ; convert to ASCII
    MOV TEXT_FIRST_PLAYER_POINTS, AL ; update the display text

    CALL RESET_BALL_POSITION
    CMP PADDLE_UPPER_POINTS, 0Ah
    JGE GAME_OVER ; if the player has 10 or more => game is restarting. 
    RET

GIVE_POINT_TO_SECOND_PLAYER:
    INC PADDLE_LOWER_POINTS
    MOV AL, PADDLE_LOWER_POINTS
    ADD AL, 30h ; convert to ASCII
    MOV TEXT_SECOND_PLAYER_POINTS, AL ; update the display text

    CALL RESET_BALL_POSITION
    CMP PADDLE_LOWER_POINTS, 0Ah               
    JGE GAME_OVER
    RET

GAME_OVER:      ; someone has reached 10 points
    ; restart first player's points
    MOV PADDLE_UPPER_POINTS, 00h
    MOV AL, PADDLE_UPPER_POINTS
    ADD AL, 30h ; convert to ASCII '0'
    MOV TEXT_FIRST_PLAYER_POINTS, AL

    ; restart second player's points
    MOV PADDLE_LOWER_POINTS, 00h
    MOV AL, PADDLE_LOWER_POINTS
    ADD AL, 30h ; convert to ASCII '0'
    MOV TEXT_SECOND_PLAYER_POINTS, AL

    ; ensure ball is reset as well
    CALL RESET_BALL_POSITION
    RET

MOVE_BALL_HORIZONTALLY:    
    MOV AX, BALL_VELOCITY_X
    ADD BALL_X, AX ; move the ball horizontally

    MOV AX, WIN_BOUNDS
    CMP BALL_X, AX
    JL REV_VELOCITY_X

    MOV AX, WIN_WIDTH
    SUB AX, BALL_SIZE
    SUB AX, WIN_BOUNDS
    CMP BALL_X, AX 
    JG REV_VELOCITY_X

    ; check collision with the lower paddle
    MOV AX, BALL_Y
    ADD AX, BALL_SIZE
    CMP AX, PADDLE_LOWER_Y 
    JNG CHECK_COLLISION_WITH_UPPER_PADDLE

    MOV AX, PADDLE_LOWER_Y
    ADD AX, PADDLE_HEIGHT 
    CMP BALL_Y, AX
    JNL CHECK_COLLISION_WITH_UPPER_PADDLE

    MOV AX, BALL_X
    ADD AX, BALL_SIZE 
    CMP AX, PADDLE_LOWER_X
    JNG CHECK_COLLISION_WITH_UPPER_PADDLE
        
    MOV AX, PADDLE_LOWER_X 
    ADD AX, PADDLE_WIDTH 
    CMP BALL_X, AX 
    JNL CHECK_COLLISION_WITH_UPPER_PADDLE

    ; if reached here, the ball is colliding with the lower paddle
    JMP REV_VELOCITY_Y

CHECK_COLLISION_WITH_UPPER_PADDLE:
    ; check collision with the upper paddle
    MOV AX, BALL_Y 
    ADD AX, BALL_SIZE 
    CMP AX, PADDLE_UPPER_Y   
    JNG EXIT_COLLISION 

    MOV AX, PADDLE_UPPER_Y 
    ADD AX, PADDLE_HEIGHT 
    CMP BALL_Y, AX 
    JNL EXIT_COLLISION 

    MOV AX, BALL_X
    ADD AX, BALL_SIZE 
    CMP AX, PADDLE_UPPER_X
    JNG EXIT_COLLISION
            
    MOV AX, PADDLE_UPPER_X 
    ADD AX, PADDLE_WIDTH 
    CMP BALL_X, AX 
    JNL EXIT_COLLISION

    JMP REV_VELOCITY_Y

REV_VELOCITY_X: 
    NEG BALL_VELOCITY_X ; reverse the ball horizontal velocity 
    RET

REV_VELOCITY_Y: 
    NEG BALL_VELOCITY_Y ; reverse the ball vertical velocity
    RET

EXIT_COLLISION:
    RET   
MOVE_BALL ENDP 

MOVE_PADDLES PROC NEAR 
    ; upper paddle
    MOV AH, 01h
    INT 16h
    JZ CHECK_LOWER_PADDLE_MOVEMENT ; no key pressed, check lower paddle

    MOV AH, 00h 
    INT 16h 

    ; if 'a' or 'A' move left
    CMP AL, 61h 
    JE MOVE_UPPER_PADDLE_LEFT
    CMP AL, 41h
    JE MOVE_UPPER_PADDLE_LEFT
    ; if 'd' or 'D' move right
    CMP AL, 64h
    JE MOVE_UPPER_PADDLE_RIGHT
    CMP AL, 44h ; 'D'
    JE MOVE_UPPER_PADDLE_RIGHT
    JMP CHECK_LOWER_PADDLE_MOVEMENT

MOVE_UPPER_PADDLE_LEFT:
    MOV AX, PADDLE_VELOCITY
    SUB PADDLE_UPPER_X, AX

    MOV AX, WIN_BOUNDS
    CMP PADDLE_UPPER_X, AX
    JL FIX_PADDLE_UPPER_LEFT_POSITION
    JMP CHECK_LOWER_PADDLE_MOVEMENT
            
FIX_PADDLE_UPPER_LEFT_POSITION:
    MOV PADDLE_UPPER_X, AX
    JMP CHECK_LOWER_PADDLE_MOVEMENT

MOVE_UPPER_PADDLE_RIGHT:
    MOV AX, PADDLE_VELOCITY
    ADD PADDLE_UPPER_X, AX  
    MOV AX, WIN_WIDTH 
    SUB AX, WIN_BOUNDS
    SUB AX, PADDLE_WIDTH
    CMP PADDLE_UPPER_X, AX 
    JG FIX_PADDLE_UPPER_RIGHT_POSITION
    JMP CHECK_LOWER_PADDLE_MOVEMENT

FIX_PADDLE_UPPER_RIGHT_POSITION:
    MOV PADDLE_UPPER_X, AX                      
    JMP CHECK_LOWER_PADDLE_MOVEMENT

    ; Lower paddle
CHECK_LOWER_PADDLE_MOVEMENT:
    MOV AH, 01h 
    INT 16h
    JZ EXIT_MOVEMENT 

    MOV AH, 00h 
    INT 16h 
    ; If '4' move left
    CMP AL, 34h
    JE MOVE_LOWER_PADDLE_LEFT
    ; If '6' move right
    CMP AL, 36h 
    JE MOVE_LOWER_PADDLE_RIGHT
    JMP EXIT_MOVEMENT 
        
MOVE_LOWER_PADDLE_LEFT: 
    MOV AX, PADDLE_VELOCITY
    SUB PADDLE_LOWER_X, AX

    MOV AX, WIN_BOUNDS 
    CMP PADDLE_LOWER_X, AX        
    JL FIX_PADDLE_LOWER_LEFT_POSITION 
    JMP EXIT_MOVEMENT

FIX_PADDLE_LOWER_LEFT_POSITION:
    MOV PADDLE_LOWER_X, AX                    
    JMP EXIT_MOVEMENT

MOVE_LOWER_PADDLE_RIGHT:
    MOV AX, PADDLE_VELOCITY
    ADD PADDLE_LOWER_X, AX  
    MOV AX, WIN_WIDTH 
    SUB AX, WIN_BOUNDS
    SUB AX, PADDLE_WIDTH
    CMP PADDLE_LOWER_X, AX 
    JG FIX_PADDLE_LOWER_RIGHT_POSITION
    JMP CHECK_LOWER_PADDLE_MOVEMENT

FIX_PADDLE_LOWER_RIGHT_POSITION:
    MOV PADDLE_LOWER_X, AX                      
    JMP EXIT_MOVEMENT    

EXIT_MOVEMENT:
    RET 
MOVE_PADDLES ENDP

RESET_BALL_POSITION PROC NEAR
    MOV AX, BALL_ORIGINAL_X
    MOV BALL_X, AX
    MOV AX, BALL_ORIGINAL_Y
    MOV BALL_Y, AX
    RET
RESET_BALL_POSITION ENDP

CLEAR_SCREEN PROC NEAR 
    MOV AH, 00h ; set to video mode configuration
    MOV AL, 13h ; choose the video mode
    INT 10h ; cxecute the configuration

    MOV AH, 0Bh ; set the configuration 
    MOV BH, 00h ; to the background caller
    MOV BL, 0Eh ; background color: light yellow
    INT 10h ; execute the configuration
    RET
CLEAR_SCREEN ENDP 

DRAW_BALL PROC NEAR 
    MOV CX, BALL_X ; set the initial column (X)
    MOV DX, BALL_Y ; set the initial line (Y)

    MOV SI, BALL_SIZE ; outer loop counter (rows)
    DEC SI ; decrement to adjust for zero-based counting

DRAW_BALL_VERTICAL:
    MOV DI, BALL_SIZE ; inner loop counter (columns)
    DEC DI ; decrement to adjust for zero-based counting

DRAW_BALL_HORIZONTAL:
    MOV AH, 0Ch ; set the configuration to writing a pixel
    MOV AL, 01h ; choose blue as color
    MOV BH, 00h ; set the page number
    INT 10h ; execute the configuration

    INC CX ; increment CX
    DEC DI
    JNS DRAW_BALL_HORIZONTAL ; repeat for BALL_SIZE

    MOV CX, BALL_X ; reset CX to the initial column
    INC DX ; advance one line

    DEC SI
    JNS DRAW_BALL_VERTICAL ; repeat for BALL_SIZE

    RET 
DRAW_BALL ENDP


DRAW_PADDLES PROC NEAR
    ; draw upper paddle
    MOV CX, PADDLE_UPPER_X 
    MOV DX, PADDLE_UPPER_Y
        
DRAW_PADDLE_UPPER_VERTICAL:
    MOV AH, 0Ch ; set the configuration to writing a pixel
    MOV AL, 01h ; choose blue as color
    MOV BH, 00h ; set the page number
    INT 10h ; execute the configuration
        
    INC CX ; increment CX
    MOV AX, CX        
    SUB AX, PADDLE_UPPER_X
    CMP AX, PADDLE_WIDTH
    JNG DRAW_PADDLE_UPPER_VERTICAL

    MOV CX, PADDLE_UPPER_X 
    INC DX
            
    MOV AX, DX  
    SUB AX, PADDLE_UPPER_Y
    CMP AX, PADDLE_HEIGHT
    JNG DRAW_PADDLE_UPPER_VERTICAL 

    ; draw lower paddle
    MOV CX, PADDLE_LOWER_X
    MOV DX, PADDLE_LOWER_Y
        
DRAW_PADDLE_LOWER_VERTICAL:
    MOV AH, 0Ch ; set the configuration to writing a pixel
    MOV AL, 01h ; choose blue as color
    MOV BH, 00h ; set the page number
    INT 10h ; execute the configuration
        
    INC CX ; increment CX
    MOV AX, CX        
    SUB AX, PADDLE_LOWER_X
    CMP AX, PADDLE_WIDTH
    JNG DRAW_PADDLE_LOWER_VERTICAL

    MOV CX, PADDLE_LOWER_X 
    INC DX
            
    MOV AX, DX  
    SUB AX, PADDLE_LOWER_Y
    CMP AX, PADDLE_HEIGHT
    JNG DRAW_PADDLE_LOWER_VERTICAL     
    RET 
DRAW_PADDLES ENDP 

DRAW_UI PROC NEAR 
    ; Draw the points of text of the first player
    MOV AH, 02h ; set cursor position 
    MOV BH, 00h ; set page number         
    MOV DH, 04h ; set row 
    MOV DL, 06h ; set column 
    INT 10h     ; 

    MOV AH, 09h ; write to standard output
    LEA DX, TEXT_FIRST_PLAYER_POINTS ; give DX a pointer to the string
    INT 21h                          ; print the string

    ; Draw the points of text of the second player
    MOV AH, 02h ; set cursor position 
    MOV BH, 00h ; set page number         
    MOV DH, 04h ; set row 
    MOV DL, 70h ; set column
    INT 10h     ; 

    MOV AH, 09h ; write to standard output
    LEA DX, TEXT_SECOND_PLAYER_POINTS ; give DX a pointer to the string
    INT 21h                          ; print the string

    RET 
DRAW_UI ENDP

  
CODE ENDS
END
