*-----------------------------------------------------------
* Title      : ag_Draw_Paddles
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------


;---
;Stack Offset Vals for Update
;---
P_UPDATE_POS_Y          EQU             0
P_UPDATE_WIDTH          EQU             4
P_UPDATE_HEIGHT         EQU             6
P_UPDATE_VELOCITY       EQU             8


;---
;Stack Offset Vals for Draw
;---
P_DRAW_POS_X            EQU             0
P_DRAW_POS_Y            EQU             4
P_DRAW_WIDTH            EQU             8
P_DRAW_HEIGHT           EQU             10
P_DRAW_FILL             EQU             12
P_DRAW_OUTLINE          EQU             16

;PLAYER_REG              REG             D1-D3


;d0 = Paddle Pos Y
;d1 = Paddle Width/Height High.W Low.W
;d2 = Paddle Velocity

ag_UpdatePlayer:

    movem.l ALL_REG,-(sp)  
    
    clr.l   d1
    clr.l   d6
    clr.l   d7
    
    move.l  #CHECK_INPUT,d0
    TRAP #15
    
    ;---
    ;Check if input is 0
    ;---
    cmp.b   #0,d1       
    BEQ     .ag_P_Exit
    
    move.l  #READ_CHAR,d0
    TRAP    #15
    
    ;---
    ;Checking if W pressed  
    ;---  
    cmp.b   #W_Key,d1
    BNE     .ag_CheckDown                   ;W is not being pressed
    
    move.l  P_UPDATE_POS_Y(sp),d6             ;Take Y Value
    
    sub.l   P_UPDATE_VELOCITY(sp),d6          ;Subtract velocity from position to go up (decrease)
    cmp.l   #0,d6
    BLE     .ag_At_Min_Y                   ;If less or equal to zero, we are at min height
    
    move.l  d6,P_UPDATE_POS_Y(sp)
    BRA     .ag_CheckDown
    
.ag_At_Min_Y
    move.l  #0,d6                               ;Set Y pos to 0
    move.l  d6,P_UPDATE_POS_Y(sp)               ;Save to stack
    
    
.ag_CheckDown    
    
    cmp.b   #S_Key,d1
    BNE     .ag_P_Exit                          ;If not holding S, Exit update                        
    
    move.l  P_UPDATE_POS_Y(sp),d6               ;Move PosY to d6    (Fixed point)
    add.l   P_UPDATE_VELOCITY(sp),d6            ;Add Velocty to d6 (Fixed Point)
    
    ;Check if + velocity is out of bounds for upper y
    clr.l   d7
    move.w  P_UPDATE_HEIGHT(sp),d7              
    asl.l   #8,d7                                   ;Height is not in fixed point                          
    add.l   d6,d7                                   ;Add height to get upper y from lower y
    
    cmp.l   #(OUTPUT_MAX_HEIGHT)<<8,d7                   ;Check if upper y will now be out of bounds
    BGE     .ag_At_Max_Y                            ;If greater or equal to max, branch to max Y
    
    move.l  d6,P_UPDATE_POS_Y(sp)                   ;Else, new pos is not out of bounds, so log it
    bra     .ag_P_Exit
    
.ag_At_Max_Y
    clr.l   d7
    move.l  #(OUTPUT_MAX_HEIGHT)<<8,d6
    move.w  P_UPDATE_HEIGHT(sp),d7
    asl.l   #8,d7
    sub.l   d7,d6                                   ;Set d6 max to max output height - paddle height
    move.l  d6,P_UPDATE_POS_Y(sp)
    
.ag_P_Exit
    movem.l (sp)+,ALL_REG
    rts
    
    
    
    
ag_UpdateEnemy
    
    movem.l ALL_REG,-(sp)
    
    clr.l   d1
    clr.l   d7
    clr.l   d6
    
    ;Get Pos Y and add velocity to get new Pos
    move.l  P_UPDATE_POS_Y(sp),d6
    add.l   P_UPDATE_VELOCITY(sp),d6
    
.ag_E_CheckMin    
    ;Check if at min y value
    cmp.l   #0,d6       
    BLE     .ag_E_At_Min_Y      ;If at or below min value, go to At Min
   
.ag_E_CheckMax    
    move.w  P_UPDATE_HEIGHT(sp),d7
    asl.l   #8,d7
    add.l   d6,d7                           ;Add Pos to Height to get Upper Y
    
    cmp.l   #(OUTPUT_MAX_HEIGHT)<<8,d7                ;Check if upper y will now be out of bounds
    BGE     .ag_E_At_Max_Y
    
    move.l  d6,P_UPDATE_POS_Y(sp)
    BRA     .ag_E_Exit
    
.ag_E_At_Min_Y
    move.l  #0,d6
    move.l  d6,P_UPDATE_POS_Y(sp)     ;Set pos y to 0 and assign to stack
    
    move.l  #0,d6
    sub.l   P_UPDATE_VELOCITY(sp),d6
    move.l  d6,P_UPDATE_VELOCITY(sp)
    BRA     .ag_E_Exit                       ;Branch to draw after velocity is inverted
     
.ag_E_At_Max_Y 
    
    move.l  #(OUTPUT_MAX_HEIGHT)<<8,d6
    
    ;Get Height and convert to fixed point
    clr.l   d7
    move.w  P_UPDATE_HEIGHT(sp),d7
    asl.l   #8,d7
    
    ;Set d6 max to max output height - paddle height
    sub.l   d7,d6                           
    move.l  d6,P_UPDATE_POS_Y(sp)
    
    ;Invert Velocity
    clr.l   d6                              ;set d6 to zero and use it to invert velocity
    sub.l   P_UPDATE_VELOCITY(sp),d6
    move.l  d6,P_UPDATE_VELOCITY(sp)
    
.ag_E_Exit
    movem.l (sp)+,ALL_REG
    rts
    
    
;d0 = Pos X
;d1 = Pos Y
;d2 = Paddle Width/Height Hi.W Low.W
;d3 = Fill Color
;d4 = Outline color

ag_DrawPaddle:
    
    movem.l ALL_REG,-(sp)
    
    move.l  P_DRAW_OUTLINE(sp),d1    
    move.l  #SET_PEN_COLOR,d0   
    TRAP    #15
    
    move.l  P_DRAW_FILL(sp),d1
    move.l  #SET_FILL_COLOR,d0
    TRAP    #15
    
    
    clr.l   d1
    clr.l   d2
    clr.l   d3
    clr.l   d4
    
    move.l  P_DRAW_POS_X(sp),d1     ;LeftX
    asr.l   #8,d1
    move.l  P_DRAW_POS_Y(sp),d4     ;LowerY  
    asr.l   #8,d4
    
    move.l  d1,d3
    add.w   P_DRAW_WIDTH(sp),d3     ;RightX
    
    move.l  d4,d2
    add.w   P_DRAW_HEIGHT(sp),d4    ;UpperY
    
    move.l  #DRAW_FRECT,d0
    TRAP #15
    
    movem.l (sp)+,ALL_REG
    rts
    

        






*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
