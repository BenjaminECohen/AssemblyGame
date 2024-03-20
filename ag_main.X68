*-----------------------------------------------------------
* Title      : Pong X68 EASY REmix
* Written by : Ben Cohen
* Date       : 10/4/2023
* Description: Do later
*-----------------------------------------------------------


ALL_REG                 REG             D0-D7/A0-A6

PLAYER_FILL_COLOR       EQU             $00FFFFFF
ENEMY_FILL_COLOR        EQU             $00a0607b
ENEMY_EDGE_COLOR        EQU             $00FFFFFF
PADDLE_OUTLINE          EQU             $00000000

SCOREBOARD_FILL_COLOR   EQU             $00825363
SCOREBOARD_EDGE_COLOR   EQU             $00FFFFFF

W_KEY                   EQU             $77
S_KEY                   EQU             $73


BALL_DIAMETER           EQU             20

DELAY_FRAME_VAL         EQU             1

COLOR_WHITE             EQU             $00FFFFFF
COLOR_RED               EQU             $000000FF

READ_CHAR               EQU             5
CHECK_INPUT             EQU             7
KEYBOARD_ECHO           EQU             12
DELAY_FRAME             EQU             23
PLAY_SOUND              EQU             73
SET_PEN_COLOR           EQU             80
SET_FILL_COLOR          EQU             81
DRAW_PIXEL              EQU             82
DRAW_FRECT              EQU             87
DRAW_FILLED_ELLIPSE     EQU             88
DOUBLE_BUFFER           EQU             92
BUFFER_PAINT            EQU             94

OUTPUT_MAX_WIDTH        EQU             640
OUTPUT_SCREEN_HEIGHT    EQU             480
OUTPUT_MAX_HEIGHT       EQU             420

BITMAP_BUFFER           EQU             $00010001

POINTS_TO_WIN           EQU             13

TIME                    EQU             8

;store d2.l (X,Y) Hi and Low words
;store d3.l timeSinceLastCall

    ORG    $10
    
 INCLUDE    ag_ScoreLED.x68   
 INCLUDE    ag_DrawBall.x68
 INCLUDE    ag_bitmap_draw.x68
 
 ;d1 - Player Pos
 ;d2 - widt high
 ;d3 - Absolute velocity long
 INCLUDE    ag_Draw_Paddles.x68
 

;d0 holds score pos 
ag_DrawScoreBG:
    movem.l     ALL_REG,-(sp)
    clr.l       d1
    clr.l       d2
    clr.l       d3
    clr.l       d4
    
    move.l      #SET_PEN_COLOR,d0
    move.l      #SCOREBOARD_FILL_COLOR,d1
    TRAP        #15
    
    move.l      #SET_FILL_COLOR,d0
    TRAP        #15
    
    move.l      (sp),d1
    move.w      d1,d2               ;Move Y to d2 (Upper)
    move.w      d1,d4               ;Move Y to d4 (Lower)
    swap        d1                  ;Make X val lower word
    move.w      d1,d3               ;Left X => Right X
    move.l      (LEDSize),d0
    add.w       d0,d4               ;Add to Lower Y LED height
    swap        d0
    add.w       d0,d3               ;Add to Right X LED Width
    add.w       d0,d3               ;Add another width for the second LED
    
    move.l      (LEDPadding),d0
    swap        d0
    add.w       d0,d3               ;Add Padding between LED

    move.l      #DRAW_FRECT,d0
    TRAP        #15       
    
    movem.l     (sp)+,ALL_REG
    rts

;d0 = value    
ag_AbsVal:
    movem.l     All_REG,-(sp)
    
    cmpi.l       #0,(sp)
    BLT         .av_Negative
    BRA         .av_Exit            ;If positive, thats good, no need to do anything
  
.av_Negative
    clr.l       d0                  ;Set to 0
    sub.l       (sp),d0             ; 0 - negative = positive
    move.l      d0,(sp)             ;Log new positive value
    
.av_Exit
    movem.l     (sp)+,ALL_REG
    rts


    ORG    $2000

    
START:                  ; first instruction of program

* Put program code here

   ;SAVE NECESSARY STACK DATA TO HAVE READY TO GO PARTITIONS

main_Start
    lea BitmapBG,a0
    jsr drawBMP                                 ;Draw full bitmap image
    
    lea     GAME_START_SOUND,a1
    move.l  #0,d1
    move.l  #0,d2
    move.l  #PLAY_SOUND,d0
    TRAP    #15
    
    move.l  #DOUBLE_BUFFER,d0                   ;Enable Double Buffer mode
    clr.l   d1
    move.b  #17,d1
    TRAP #15
    
    clr.l   d1
    move.l  #KEYBOARD_ECHO,d0                   ;Turn off keyboard echo
    TRAP #15
    
    
    
    move.l  #(OUTPUT_SCREEN_HEIGHT/2)<<8,(Ball_PositionY)
    move.l  #(OUTPUT_MAX_WIDTH/2)<<8,(Ball_PositionX)
    ;---
    ;Initialize Last Pos
    ;---
    move.l  (Player_PositionY),(Last_Player_PosY)
    
    move.l  (Enemy_PositionY),(Last_Enemy_PosY)
    
    move.l  (Ball_PositionX),(Last_Ball_PosX)
    move.l  (Ball_PositionY),(Last_Ball_PosY)
    
    ;---
    ;Draw Player Before Everything
    ;----
    
    move.l  Player_PositionX,d0
    move.l  Player_PositionY,d1
    move.l  Paddle_Size,d2
    move.l  #PLAYER_FILL_COLOR,d3
    move.l  #PADDLE_OUTLINE,d4
    
    jsr ag_DrawPaddle
    
    ;---
    ;Draw Score Area
    ;---
    move.l  #SET_FILL_COLOR,d0
    move.l  #SCOREBOARD_FILL_COLOR,d1
    TRAP    #15
    
    move.l  #SET_PEN_COLOR,d0
    move.l  #SCOREBOARD_EDGE_COLOR,d1
    TRAP    #15
    
    move.l  #DRAW_FRECT,d0
    move.l  #(-1),d1
    move.l  #OUTPUT_SCREEN_HEIGHT,d2
    move.l  #OUTPUT_MAX_WIDTH,d3
    move.l  #(OUTPUT_MAX_HEIGHT+1),d4
    TRAP    #15
    
    ;---
    ;Draw LEDs at start and set last Score and set Position
    ;---
    
    ;Set Player Pos LED
    move.l  #(OUTPUT_SCREEN_HEIGHT),d0
    move.l  (LEDPadding),d1
    move.l  (LEDSize),d2
    
    ;Get Y val
    sub.w   d1,d0                   ;Subtract y padding from screen height
    sub.w   d2,d0                   ;Subtract actual LED size from height
    
    ;Get X Val
    swap    d0
    move.w  #(OUTPUT_MAX_WIDTH),d0
    swap    d1
    swap    d2
    sub.w   d1,d0                   ;Subtract Padding only once for X val
    sub.w   d2,d0                   ;Subtract X size from Width
    
    ;Set Pos For Rightmost LED (of 2)
    sub.w   d1,d0                   ;Subtract Padding again In Between LEDs
    sub.w   d2,d0                   ;Subtract X size from Width
        
    ;We now have the position for
    swap    d0
    move.l  d0,(PlayerScorePos)
    move.l  (PlayerScore),(Last_PlayerScore)
    
    ;Set Enemy LED
    swap    d0                      ;Only need to edit the X val
    move.w  #0,d0
    add.w   d1,d0                   ;Add Padding Once
    swap    d0
    move.l  d0,(EnemyScorePos)
    
    move.l  (EnemyScore),(Last_EnemyScore)
    
    ;---
    ;Draw LEDs at 0
    ;---
    ;Draw Player Score 
    move.l  (PlayerScorePos),d1  
    move.l  (PlayerScore),d0
    move.l  (LEDSize),d2
    
    ;Draw 10s Digit   
    jsr     ag_DrawScoreLED
    
    ;Add offset to X
    move.l  (LEDSize),d3
    move.l  (LEDPadding),d4
    
    ;Get X values to lower Word
    swap    d1
    swap    d3
    swap    d4
    
    ;Add
    add.w   d3,d1
    add.w   d4,d1
    
    ;Swap back to X,Y format
    swap    d1
    jsr     ag_DrawScoreLED
    
    
    ;Draw Enemy Score 
    move.l  (EnemyScorePos),d1   
    move.l  (EnemyScore),d0
    move.l  (LEDSize),d2
     
    jsr     ag_DrawScoreLED
    
    ;Add offset to X
    move.l  (LEDSize),d3
    move.l  (LEDPadding),d4
    
    ;Get X values to lower Word
    swap    d1
    swap    d3
    swap    d4
    
    ;Add
    add.w   d3,d1
    add.w   d4,d1
    
    ;Swap back to X,Y format
    swap    d1
    jsr     ag_DrawScoreLED
    
gameloop:        
    ;---
    ;Update Player Paddle
    ;---
    
    move.l  (Player_PositionY),d0
    move.l  (Paddle_Size),d1
    move.l  (Player_Velocity),d2
    
    jsr     ag_UpdatePlayer
    
    move.l  d0,(Player_PositionY)
    
    ;---
    ;Update Enemy Paddle
    ;---
    
    move.l  (Enemy_PositionY),d0
    move.l  (Paddle_Size),d1
    move.l  (Enemy_Velocity),d2
    
    jsr     ag_UpdateEnemy
    
    move.l  d0,(Enemy_PositionY)
    move.l  d2,(Enemy_Velocity)
    
    ;---
    ;Update Ball Position
    ;---
    move.l  (Ball_PositionX),d0
    move.l  (Ball_PositionY),d1
    move.l  (Ball_Velocity),d2
    move.l  (Player_PositionX),d3
    move.l  (Player_PositionY),d4
    move.l  (Enemy_PositionX),d5
    move.l  (Enemy_PositionY),d6
    move.l  (Paddle_Size),d7
    
    
    lea     PlayerScore,a0          ;Score Return Player
    lea     EnemyScore,a1           ;Score Return Player
    
    jsr ag_UpdateBall
    
    
    move.l  d0,(Ball_PositionX)                 ;Save Position X
    move.l  d1,(Ball_PositionY)                 ;Save Position Y
    move.l  d2,(Ball_Velocity)                 ;Save Velocity
       
       
    ;------------------------
    ;DRAW BITMAP FOR SECTIONS
    ;------------------------   
    ;---
    ;Check if we need to draw Bitmap for the ball
    ;---   
    
    ;Compare Ball curr Pos to Prev Pos, Same means no need to refresh bitmap
    move.l  (Ball_PositionX),d0
    move.l  (Last_Ball_PosX),d1
    asr.l   #8,d0
    asr.l   #8,d1
    cmp.l   d0,d1
    BNE     .main_BM_Ball                  ;If x isn't equal, then we need to redraw
    
    ;Check If Y isn't the same if X is the same
    move.l  (Ball_PositionY),d0
    move.l  (Last_Ball_PosY),d1
    asr.l   #8,d0
    asr.l   #8,d1
    cmp.l   d0,d1
    BEQ     .main_BM_Player            ;If they are equal, then both x and y are equal, dont draw ball
    
    ;---   
    ;Draw Bitmap For Ball
    ;---
.main_BM_Ball

    lea     BitmapBG,a0
    
    ;Chunk Offset
    ;Get Pos Values then take out of fixed point
    move.l  (Last_Ball_PosX),d0
    move.l  (Last_Ball_PosY),d1
    asr.l   #8,d0
    asr.l   #8,d1
    move.l  d0,d2
    swap    d2
    move.w  d1,d2
    
    ;Chunk W/H
    move.l  #BALL_DIAMETER,d3
    swap    d3
    move.w  #BALL_DIAMETER,d3
    add.l   #BITMAP_BUFFER,d3           ;little bit of bits for buffer
    
    ;Output Offset
    move.l  d2,d4
    
    jsr     DrawBMP
   
   
.main_BM_Player    
    ;---
    ;Check if we need to draw Bitmap for player
    ;---
    move.l   (Player_PositionY),d1
   
   ;Compare Player curr PosY to Prev Pos Y, Same means, dont draw
    move.l  d1,d2
    asr.l   #8,d2
    move.l  (Last_Player_PosY),d3
    asr.l   #8,d3
    cmp.l   d2,d3
    BEQ     .main_BM_Enemy  
    
    ;---
    ;Draw Bitmap for Player
    ;---
          
    sub.l   d3,d2       ;Have d2 hold the difference between the current and last
    cmp.l   #0,d2       ;Negative or positive?
    BLT     .p_NegDisp  ;Less than zero means negative Disp (paddle went upwards/negatively)

    ;Otherwise, paddle went downwards/positively (Use last pos as chunk start)
    move.l  (Paddle_Size),d3    ;Get chunk Size xxxx yyyy
    move.w  d2,d3               ;Move lower word of d2 to chunk size
    add.l   #BITMAP_BUFFER,d3
    
    ;Get Chunk Offset
    move.l  (Player_PositionX),d2
    move.l  (Last_Player_PosY),d1
    asr.l   #8,d2
    asr.l   #8,d1
    swap    d2
    move.w  d1,d2    

    ;Get Output Offset
    move.l  d2,d4                  
    BRA     .draw_BM_Player
        
.p_NegDisp              
    move.l  d2,d0       ;Prepare for getting abs value
        
    ;d0 now holds ChunkSizeY
    jsr     ag_AbsVal
    
    ;Set chunk size
    move.l  (Paddle_Size),d3    ;X value for paddle chunk size and move new Y value into lower half (y)        
    move.w  d0,d3               ;Get the Y displacement into lower.w d3
    add.l   #BITMAP_BUFFER,d3
    
    ;Paddle went upwards, so use current + paddle height as chunk offset
    move.l  (Player_PositionY),d2       ;Get Player Curr Y
    asr.l   #8,d2
    
    move.l  (Paddle_Size),d0            ;Get Paddle Size
    clr.l   d1
    move.w  d0,d1                       ;Grab only the height
    add.l   d1,d2                       ;Add Height + current
    
    move.l  (Player_PositionX),d0       ;Get Player Curr X
    asr.l   #8,d0
    swap    d0
    add.l   d0,d2                   ;X val stays the same, but current Y + height added to lower word
    
    ;Set Output offset
    move.l  d2,d4

.draw_BM_Player    
    lea     BitmapBG,a0
    
    jsr     DrawBMP
        
        

.main_BM_Enemy         
    ;---
    ;Check if we need to draw Bitmap for Enemy
    ;---
    move.l   (Enemy_PositionY),d1
   
    ;Compare Enemy curr PosY to Prev Pos Y, Same means, dont draw
    move.l  d1,d2
    asr.l   #8,d2
    move.l  (Last_Enemy_PosY),d3
    asr.l   #8,d3
    cmp.l   d2,d3
    BEQ     .main_DrawEntities    
  
    ;---
    ;Draw Bitmap for Enemy
    ;---
    sub.l   d3,d2       ;Have d2 hold the difference between the current and last
    cmp.l   #0,d2       ;Negative or positive?
    BLT     .e_NegDisp  ;Less than zero means negative Disp (paddle went upwards/negatively)

    ;Otherwise, paddle went downwards/positively (Use last pos as chunk start)
    move.l  (Paddle_Size),d3    ;Get chunk Size xxxx yyyy
    move.w  d2,d3               ;Move lower word of d2 to chunk size
    add.l   #BITMAP_BUFFER,d3
    
    ;Get Chunk Offset
    move.l  (Enemy_PositionX),d2
    move.l  (Last_Enemy_PosY),d1
    asr.l   #8,d2
    asr.l   #8,d1
    swap    d2
    move.w  d1,d2    

    ;Get Output Offset
    move.l  d2,d4                  
    BRA     .draw_BM_Enemy
        
.e_NegDisp              
    move.l  d2,d0       ;Prepare for getting abs value
        
    ;d0 now holds ChunkSizeY
    jsr     ag_AbsVal
    
    ;Set chunk size
    move.l  (Paddle_Size),d3    ;X value for paddle chunk size and move new Y value into lower half (y)        
    move.w  d0,d3               ;Get the Y displacement into lower.w d3
    add.l   #BITMAP_BUFFER,d3
    
    ;Paddle went upwards, so use current + paddle height as chunk offset
    move.l  (Enemy_PositionY),d2       ;Get Player Curr Y
    asr.l   #8,d2
    
    move.l  (Paddle_Size),d0            ;Get Paddle Size
    clr.l   d1
    move.w  d0,d1                       ;Grab only the height
    add.l   d1,d2                       ;Add Height + current
    
    move.l  (Enemy_PositionX),d0       ;Get Enemy Curr X
    asr.l   #8,d0
    swap    d0
    add.l   d0,d2                   ;X val stays the same, but current Y + height added to lower word
    
    ;Set Output offset
    move.l  d2,d4

.draw_BM_Enemy    
    lea     BitmapBG,a0
    
    jsr     DrawBMP  
    
    
    ;------------------------------------
    ;START OF DRAWING NON-BITMAP ENTITIES
    ;------------------------------------
.main_DrawEntities     
    ;---
    ;Draw Player Paddle
    ;---
.main_DrawPlayer    
    move.l  Player_PositionX,d0
    move.l  Player_PositionY,d1
    
    ;Compare Player curr PosY to Prev Pos Y, Same means, dont draw
    move.l  d1,d2
    asr.l   #8,d2
    move.l  (Last_Player_PosY),d3
    asr.l   #8,d3
    cmp.l   d2,d3
    ;BEQ     .main_DrawEnemy
    
    move.l  Paddle_Size,d2
    move.l  #PLAYER_FILL_COLOR,d3
    move.l  #ENEMY_FILL_COLOR,d4
    
    jsr ag_DrawPaddle
    
    move.l  d1,(Last_Player_PosY) 

              
    ;---
    ;Draw Enemy PAddle
    ;---
.main_DrawEnemy    
    move.l  Enemy_PositionX,d0
    move.l  Enemy_PositionY,d1
    
    ;Compare Enemy curr PosY to Prev Pos Y, Same means, dont draw
    move.l  d1,d2
    asr.l   #8,d2
    move.l  (Last_Enemy_PosY),d3
    asr.l   #8,d3
    cmp.l   d2,d3
    BEQ     .main_DrawLED

    move.l  Paddle_Size,d2
    move.l  #ENEMY_FILL_COLOR,d3
    move.l  #ENEMY_EDGE_COLOR,d4
    
    jsr ag_DrawPaddle
    
    move.l  d1,(Last_Enemy_PosY)

    ;---
    ;Draw Ball At Position
    ;---
.main_DrawBall 
    ;Compare Ball curr Pos to Prev Pos, Same means don't draw
    move.l  (Ball_PositionX),d0
    move.l  (Last_Ball_PosX),d1
    asr.l   #8,d0
    asr.l   #8,d1
    cmp.l   d0,d1
    BNE     .b_DrawBall                  ;If x isn't equal, then we need to redraw
    
    ;Check If Y isn't the same if X is the same
    move.l  (Ball_PositionY),d0
    move.l  (Last_Ball_PosY),d1
    asr.l   #8,d0
    asr.l   #8,d1
    cmp.l   d0,d1
    BEQ     .main_DrawPlayer            ;If they are equal, then both x and y are equal, dont draw ball
     
.b_DrawBall   
    move.l  (Ball_PositionX),d0
    move.l  (Ball_PositionY),d1
    jsr ag_DrawBall
    
    ;Update values
    move.l  (Ball_PositionX),(Last_Ball_PosX)
    move.l  (Ball_PositionY),(Last_Ball_PosY)
        
    
    ;---
    ;Draw LEDs
    ;---
.main_DrawLED       
    ;---
    ;Draw Player Score
    ;---
    
    ;Compare Curr Score to Last
    move.l  (PlayerScore),d0
    move.l  (Last_PlayerScore),d1
    cmp.l   d1,d0
    BLE     .b_CheckEnemyScore
    
    ;Draw Player LED
    move.l  (PlayerScorePos),d0  
    jsr     ag_DrawScoreBG
    
    move.l  d0,d1
    move.l  (PlayerScore),d0
    move.l  (LEDSize),d2
    
    ;Draw 10s digit
    divu.w  #10,d0   
    jsr     ag_DrawScoreLED
    
    ;Draw 1s digit    
    swap    d0
    
    ;Add offset to X
    move.l  (LEDSize),d3
    move.l  (LEDPadding),d4
    
    ;Get X values to lower Word
    swap    d1
    swap    d3
    swap    d4
    
    ;Add
    add.w   d3,d1
    add.w   d4,d1
    
    ;Swap back to X,Y format
    swap    d1
    jsr     ag_DrawScoreLED
    
    move.l  (PlayerScore),(Last_PlayerScore)
    
    ;Check If Game Over
    cmpi.l  #POINTS_TO_WIN,(PlayerScore)
    BGE     .main_PlayerWin
    
    lea     PLAYER_SCORESOUND,a1
    move.l  #0,d1
    move.l  #0,d2
    move.l  #PLAY_SOUND,d0
    TRAP    #15  


.b_CheckEnemyScore
    move.l  (EnemyScore),d0
    move.l  (Last_EnemyScore),d1
    cmp.l   d1,d0
    BLE     .main_LoopAgain

    ;Draw Enemy Score 
    move.l  (EnemyScorePos),d0  
    jsr     ag_DrawScoreBG
    
    move.l  d0,d1  
    move.l  (EnemyScore),d0
    move.l  (LEDSize),d2
    
    ;Draw 10s digit
    divu.w  #10,d0   
    jsr     ag_DrawScoreLED
    
    ;Draw 1s digit    
    swap    d0
    
    ;Add offset to X
    move.l  (LEDSize),d3
    move.l  (LEDPadding),d4
    
    ;Get X values to lower Word
    swap    d1
    swap    d3
    swap    d4
    
    ;Add
    add.w   d3,d1
    add.w   d4,d1
    
    ;Swap back to X,Y format
    swap    d1
    jsr     ag_DrawScoreLED
    
    move.l  (EnemyScore),(Last_EnemyScore)
    
    cmpi.l  #POINTS_TO_WIN,(EnemyScore)
    BGE     .main_PlayerLose 
    
    lea     ENEMY_SCORESOUND,a1
    move.l  #0,d1
    move.l  #0,d2
    move.l  #PLAY_SOUND,d0
    TRAP    #15  

.main_LoopAgain    
    
*    move.l  #DELAY_FRAME,d0
*    move.l  #DELAY_FRAME_VAL,d1
*    TRAP    #15
    
    move.l  #BUFFER_PAINT,d0
    clr.l   d1
    move.b  #17,d1
    TRAP    #15 
    
    
    
    bra gameloop


.main_PlayerWin


    lea     BitmapBG_Win,a0
    move.l  #$00A00126,d2
    move.l  #$01400040,d3
    move.l  d2,d4
    
    jsr     DrawBMP
    
    move.l  #BUFFER_PAINT,d0
    clr.l   d1
    move.b  #17,d1
    TRAP #15 

    lea     PLAYERWIN_SOUND,a1
    move.l  #0,d1
    move.l  #0,d2
    move.l  #PLAY_SOUND,d0
    TRAP    #15
    
    BRA     main_Endloop


.main_PlayerLose

    lea     BitmapBG_Lose,a0
    move.l  #$00910126,d2
    move.l  #$015E0040,d3
    move.l  d2,d4
    
    jsr     DrawBMP

    move.l  #BUFFER_PAINT,d0
    clr.l   d1
    move.b  #17,d1
    TRAP #15 
    
    lea     ENEMYWIN_SOUND,a1
    move.l  #0,d1
    move.l  #0,d2
    move.l  #PLAY_SOUND,d0
    TRAP    #15
    
    BRA     main_Endloop

main_EndLoop

    move.l  #CHECK_INPUT,d0
    TRAP #15
    
    move.l  #READ_CHAR,d0
    TRAP    #15

    cmp.b   (Restart_Key),d1
    BEQ     main_ResetGame

    BRA     main_Endloop
    
    

main_ResetGame
    move.l  #0,(PlayerScore)
    move.l  #0,(EnemyScore)
    
    move.l  #DOUBLE_BUFFER,d0
    clr.l   d1
    move.b  #16,d1
    TRAP #15
    
    clr.l   d0
    clr.l   d1
    clr.l   d2
    clr.l   d3
    clr.l   d4
    clr.l   d5
    clr.l   d6
    clr.l   d7
    

    BRA     main_Start
    SIMHALT             ; halt simulator
    
    
    
BitmapBG        INCBIN  "BitmapBG_base.bmp"
BitmapBG_Lose   INCBIN  "BitmapBG_lose.bmp"
BitmapBG_Win    INCBIN  "BitmapBG_win.bmp"

Player_PositionX    dc.l    $00026200
Player_PositionY    dc.l    $0000F000
Last_Player_PosX    dc.l    1
Last_Player_PosY    dc.l    1
Player_Velocity     dc.l    $00001800

Enemy_PositionX     dc.l    $00000F00
Enemy_PositionY     dc.l    $0000F000
Last_Enemy_PosX     dc.l    1
Last_Enemy_PosY     dc.l    1 
Enemy_Velocity      dc.l    $000001E0

Paddle_Size         dc.l    $000E0064
    
Ball_PositionX      dc.l    $000000F4
Ball_PositionY      dc.l    $000000F4
Last_Ball_PosX      dc.l    1
Last_Ball_PosY      dc.l    1
Ball_Velocity       dc.l    $02000200 ;$02000200

LEDSize             dc.l    $00140028
LEDPadding          dc.l    $000A000A

PlayerScorePos      dc.l    $0258000A
PlayerScore         dc.l    $00000000
Last_PlayerScore    dc.l    $00000000

EnemyScorePos       dc.l    $0014000A
EnemyScore          dc.l    $00000000
Last_EnemyScore     dc.l    $00000000

Restart_Key         dc.b    'r'
KEYPADDING          dc.b    1,2,3

GAME_START_SOUND    dc.b    'GameStart.wav',0
PLAYER_SCORESOUND   dc.b    'PlayerScore_Sound.wav',0
ENEMY_SCORESOUND    dc.b    'EnemyScore_Sound.wav',0
HIT_SOUND           dc.b    'PaddleHit2.wav',0
PLAYERWIN_SOUND     dc.b    'PlayerWin.wav',0
ENEMYWIN_SOUND      dc.b    'EnemyWin.wav',0


    END    START        ; last line of source























*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
