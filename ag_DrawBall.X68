*-----------------------------------------------------------
* Title      : ag_DrawBall
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------


COLOR_WHITE             EQU             $00FFFFFF
COLOR_RED               EQU             $000000FF

BALL_FILL_COLOR         EQU             $00f3c7df
BALL_EDGE_COLOR         EQU             $00FFFFFF

;BALL_STACK_SIZE         EQU             8   ;in bytes

BALL_POSITION_X         EQU             0
BALL_POSITION_Y         EQU             4
BALL_VELOCITY_X         EQU             8
BALL_VELOCITY_Y         EQU             10
PLAYER_POS_X            EQU             12
PLAYER_POS_Y            EQU             16
ENEMY_POS_X             EQU             20
ENEMY_POS_Y             EQU             24
PADDLE_SIZE_X           EQU             28
PADDLE_SIZE_Y           EQU             30
PLAYER_SCORE            EQU             32
ENEMY_SCORE             EQU             36

SET_PEN_COLOR           EQU             80
SET_FILL_COLOR          EQU             81
DRAW_PIXEL              EQU             82
DRAW_FILLED_ELLIPSE     EQU             88

BALL_REG                REG             D0-D7/A0-A1
DRAW_BALL_REG           REG             D0-D1


ag_UpdateBall
    
    movem.l BALL_REG,-(sp)   
    
    clr.l   d0
    clr.l   d1
    clr.l   d2
    clr.l   d3
    clr.l   d4
    clr.l   d5

    
    move.l  BALL_POSITION_X(sp),d6           ;x Pos val
    move.l  BALL_POSITION_Y(sp),d7           ;y Pos val
    
    ;ADDING BALL VELOCITY
    move.w  BALL_VELOCITY_X(sp),d1
    move.w  BALL_VELOCITY_Y(sp),d2
    
    ;Extend the sign to a long
    ext.l   d1
    ext.l   d2
    
    add.l   d1,d6       ;add x velocity
    add.l   d2,d7       ;add y velocity
  

.ag_Check_Player
    
    cmp.b   #0,(IgnorePaddle)
    BNE     .ag_PaddleMiss
    
    ;Check if greater than right x of paddle
    clr.l   d5
    addi.l  #(BALL_DIAMETER)<<8,d5
    add.l   d6,d5
    
    move.l  PLAYER_POS_X(sp),d0

    cmp.l   d0,d5
    BLT     .ag_Check_Enemy
    
    ;Check if less than Upper Y
    move.l  PLAYER_POS_Y(sp),d0
    move.l  #(BALL_DIAMETER)<<8,d5      ;Get the lower y val of ball
    add.l   d7,d5                       ;Add player Y pos
    
    cmp.l   d0,d5
    BLT     .ag_PaddleMiss
    
    ;Check if Greater than lower Y
    clr.l   d1 
    move.w  PADDLE_SIZE_Y(sp),d1    ;Get paddle size
    asl.l   #8,d1                   ;Shift 8 to left for fixed point
    add.l   d1,d0                   ;add value to d0, player pos y
    cmp.l   d0,d7                   ;compare y
    BGT     .ag_PaddleMiss
    
    ;If pass all, we are inside the player, change velocity!  
    clr.l   d0
    sub.w   BALL_VELOCITY_X(sp),d0
    move.w  d0,BALL_VELOCITY_X(sp)
    
    move.l  PLAYER_POS_X(sp),d0
    sub.w   #(BALL_DIAMETER)<<8,d0
    move.l  d0,d6                       ;Set x pos to leftmost
    
    lea     HIT_SOUND,a1
    move.l  #0,d1
    move.l  #0,d2
    move.l  #PLAY_SOUND,d0
    TRAP    #15 
    
    BRA     .ag_SavePos
    
.ag_Check_Enemy  
    
    cmp.b   #0,(IgnorePaddle)           ;Check if paddles are to be ignored (0 = false, else = true)
    BNE     .ag_PaddleMiss
    
    ;Check if less than right x of paddle
    clr.l   d1
    move.l  ENEMY_POS_X(sp),d0
    move.w  PADDLE_SIZE_X(sp),d1
    asl.l   #8,d1
    add.l   d1,d0
    cmp.l   d0,d6
    BGT     .ag_EdgeCheck 

    ;Check if lower than Upper Y
    move.l  ENEMY_POS_Y(sp),d0
    move.l  #(BALL_DIAMETER)<<8,d5      ;Get the lower y val of ball
    add.l   d7,d5                       ;Add Enemy Y pos

    cmp.l   d0,d5
    BLT     .ag_PaddleMiss 
   
    ;Check if Greater than lower Y
    clr.l   d1 
    move.w  PADDLE_SIZE_Y(sp),d1        ;Get paddle size
    asl.l   #8,d1                       ;Shift 8 to left for fixed point
    add.l   d1,d0                       ;add value to d0, enemy pos y
    cmp.l   d0,d7                       ;compare y
    BGT     .ag_PaddleMiss
   
    ;If pass all, inverse velocity!        
    clr.l   d0
    sub.w   BALL_VELOCITY_X(sp),d0
    move.w  d0,BALL_VELOCITY_X(sp)
    
    move.l  ENEMY_POS_X(sp),d0
    clr.l   d1
    move.w  PADDLE_SIZE_X(sp),d1
    asl.l   #8,d1
    add.l   d1,d0 
    move.l  d0,d6
    
    lea     HIT_SOUND,a1
    move.l  #0,d1
    move.l  #0,d2
    move.l  #PLAY_SOUND,d0
    TRAP    #15 
    
    BRA     .ag_SavePos
    
    
.ag_PlayerScored
    move.b  #0,(IgnorePaddle)
    move.l  PLAYER_SCORE(sp),a0
    addi.l  #1,(a0)

    ;---
    ;Random Constrained reset
    ;---
    BRA     .ag_RandomSpawn
    
.ag_EnemyScored
    move.b  #0,(IgnorePaddle)
    move.l  ENEMY_SCORE(sp),a0
    addi.l  #1,(a0)

    ;--
    ;Reset ball
    ;--
    ;---
    ;Random Constrained reset
    ;---
    BRA     .ag_RandomSpawn

.ag_EdgeCheck      
.ag_Y_MAX
    cmpi.l   #(OUTPUT_MAX_HEIGHT-BALL_DIAMETER)<<8,d7
    BLT     .ag_Y_MIN
    clr.l   d0
    sub.w   BALL_VELOCITY_Y(sp),d0
    move.w  d0,BALL_VELOCITY_Y(sp)
    move.l  #(OUTPUT_MAX_HEIGHT-BALL_DIAMETER)<<8,d7
    BRA     .ag_SavePos
    
.ag_Y_MIN
    cmp.l   #0,d7
    BGT     .ag_SavePos
    clr.l   d0
    sub.w   BALL_VELOCITY_Y(sp),d0
    move.w  d0,BALL_VELOCITY_Y(sp)
    move.l  #0,d7
    
.ag_SavePos
    ;Save Position
    move.l  d6,BALL_POSITION_X(sp)
    move.l  d7,BALL_POSITION_Y(sp)
    movem.l (sp)+,BALL_REG
    rts
    
.ag_PaddleMiss 
    move.b  #1,(IgnorePaddle)
   
.ag_X_MAX
    cmpi.l   #(OUTPUT_MAX_WIDTH-BALL_DIAMETER)<<8,d6            ;right X minus max right
    BLT     .ag_X_MIN
    ;if greater than equal
    clr.l   d0
    sub.w   BALL_VELOCITY_X(sp),d0
    move.w  d0,BALL_VELOCITY_X(sp)
    move.l  #(OUTPUT_MAX_WIDTH-BALL_DIAMETER)<<8,d6
    BRA     .ag_EnemyScored
    
.ag_X_MIN
    cmp.l   #0,d6            ;left X minus comp 0    
    BGT     .ag_Y_MAX
    clr.l   d0
    sub.w   BALL_VELOCITY_X(sp),d0
    move.w  d0,BALL_VELOCITY_X(sp)
    move.l  #0,d6
    BRA     .ag_PlayerScored

.ag_RandomSpawn
    move.l  #TIME,d0            ;d1 holds time
    TRAP    #15
    
    ;X
    move.l  d1,d0
    
    move.l  #(OUTPUT_MAX_WIDTH/4),d1                ;Save portion of width
    
    divu.w  d1,d0                                   ;Divide time by width portion
    move.w  #0,d0                                   ;Set quotient to 0
    swap    d0                                      ;Get remainder
    add.w   #(3*OUTPUT_MAX_WIDTH/8),d0              ;Add width portion as offset
    asl.l   #8,d0                                   ;Convert to fixed point
    move.l  d0,d6                                   ;Move to x value
    
    ;Y
    move.l  #TIME,d0            ;d1 holds time
    TRAP    #15
    
    move.l  d1,d0
   
    move.l  #(OUTPUT_MAX_HEIGHT/2),d1               ;Save portion of height
    
    divu.w  d1,d0                                   ;Divide time by height portion
    move.w  #0,d0                                   ;set quotient to 0
    swap    d0                                      ;Get remainder to lower word
    add.w   #(OUTPUT_MAX_HEIGHT/4),d0               ;Add portion of height as offset
    asl.l   #8,d0                                   ;Convert to fixed point
    move.l  d0,d7                                   ;move to y value
    
    BRA     .ag_SavePos
    
    
    
;d0 = Ball Position X
;d1 = Ball Position Y    
ag_DrawBall:      

    movem.l DRAW_BALL_REG,-(sp)
    
    move.l  #SET_PEN_COLOR,d0
    move.l  #BALL_EDGE_COLOR,d1
    TRAP #15
    
    move.l  #SET_FILL_COLOR,d0
    move.l  #BALL_FILL_COLOR,d1
    TRAP #15
    
    move.l  0(sp),d1
    asr.l   #8,d1
    
    move.l  4(sp),d4
    asr.l   #8,d4

    move.l  d1,d3                       ;Move Left X to Right X
    add.l   #BALL_DIAMETER,d3           ;Add diameter to Right X
    
    move.l  d4,d2                       ;Move Lower Y to Upper Y       
    add.l   #BALL_DIAMETER,d2           ;Add diameter to Upper Y
    
    move.l  #DRAW_FILLED_ELLIPSE,d0
    TRAP #15
       
    movem.l (sp)+,DRAW_BALL_REG
    rts

IgnorePaddle    dc.b    $00
PadBytes        dc.b    3















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
