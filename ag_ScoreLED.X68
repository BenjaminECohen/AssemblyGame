*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------

SCORE_REG               REG             D0-D2

SCORE_COLOR             EQU             $00f3c7df
SCORE_EDGE_COLOR        EQU             $00f3c7df
SCORE_POS_X             EQU             4
SCORE_POS_Y             EQU             6
SCORE_WIDTH             EQU             8
SCORE_HEIGHT            EQU             10

SCORE_THICKNESS         EQU             5


ag_DrawScoreLED

    ;d0 = score
    ;d1 = x,y word/word position
    ;d2 = width,height (word each)

    movem.l SCORE_REG,-(sp)
    
    clr.l   d1
    clr.l   d2
    clr.l   d6
    lea     ScoreMask,a0
    
    ;---
    ;Set pen colors
    ;---
    
    move.l  #SET_PEN_COLOR,d0
    move.l  #SCORE_EDGE_COLOR,d1
    TRAP    #15
    
    move.l  #SET_FILL_COLOR,d0
    move.l  #SCORE_COLOR,d1
    TRAP    #15
    
    
    ;----
    ;Get score and get the correct bitmask to show that score
    ;----
    
    move.l  (sp),d1        ;Move score to d1
    swap    d1
    move.w  #0,d1
    swap    d1              ;Get rid of any remainders
    
    move.b  (a0,d1),d6      ;Move bitmask according to score to d6
    
    ;---
    ;Using Bitmask, print the correct part to screen
    ;---
    ;BTST 6-0               ;Bit 7 is always 0    
    clr.l   d1
    clr.l   d2
    clr.l   d3
    clr.l   d4
    move.l  #DRAW_FRECT,d0
    
    ;A
.SegmentA
    BTST    #$6,d6
    BEQ     .SegmentB
    
    ;Print A segment
    move.w  SCORE_POS_X(sp),d1
    move.w  SCORE_POS_Y(sp),d2
    
    move.w  d1,d3
    add.w   SCORE_WIDTH(sp),d3
    
    move.w  d2,d4
    add.w   #SCORE_THICKNESS,d4
    
    TRAP    #15
    
    ;B
.SegmentB
    BTST    #$5,d6
    BEQ     .SegmentC
    
    ;Print B Segment
    move.w  SCORE_POS_X(sp),d3
    add.w   SCORE_WIDTH(sp),d3
    move.w  d3,d1
    sub.w   #SCORE_THICKNESS,d1
    
    move.w  SCORE_POS_Y(sp),d2
    
    move.w  SCORE_HEIGHT(sp),d4
    divu.w  #2,d4
    add.w   d2,d4
    
    TRAP    #15
    
    
    ;C
.SegmentC    
    BTST    #$4,d6
    BEQ     .SegmentD
    
    ;Print C Segment
    move.w  SCORE_POS_X(sp),d3
    add.w   SCORE_WIDTH(sp),d3
    move.w  d3,d1
    sub.w   #SCORE_THICKNESS,d1
    
    move.w  SCORE_HEIGHT(sp),d2
    divu.w  #2,d2
    add.w   SCORE_POS_Y(sp),d2
    
    
    move.w  SCORE_HEIGHT(sp),d4
    add.w   SCORE_POS_Y(sp),d4
    
    TRAP    #15

    ;D
.SegmentD
    BTST    #$3,d6
    BEQ     .SegmentE
    
    ;Print D segment
    move.w  SCORE_POS_X(sp),d1
    
    move.w  SCORE_HEIGHT(sp),d2
    sub.w   #SCORE_THICKNESS,d2
    add.w  SCORE_POS_Y(sp),d2
    
    move.w  d1,d3
    add.w   SCORE_WIDTH(sp),d3
    
    move.w   SCORE_HEIGHT(sp),d4
    add.w    SCORE_POS_Y(sp),d4
    
    TRAP    #15
    
    
    ;E
.SegmentE
    BTST    #$2,d6
    BEQ     .SegmentF
    
    move.w  SCORE_POS_X(sp),d1
    move.w  d1,d3
    add.w   #SCORE_THICKNESS,d3
    
    move.w  SCORE_HEIGHT(sp),d2
    divu.w  #2,d2
    add.w   SCORE_POS_Y(sp),d2
    
    
    move.w  SCORE_HEIGHT(sp),d4
    add.w   SCORE_POS_Y(sp),d4
    
    TRAP    #15
    
    ;F
.SegmentF
    BTST    #$1,d6
    BEQ     .SegmentG
    
    move.w  SCORE_POS_X(sp),d1
    move.w  d1,d3
    add.w   #SCORE_THICKNESS,d3
    
    move.w  SCORE_POS_Y(sp),d2
    
    move.w  SCORE_HEIGHT(sp),d4
    divu.w  #2,d4
    add.w   d2,d4
    
    TRAP    #15
    
    ;G
.SegmentG
    BTST    #$0,d6
    BEQ     .End
    
    move.w  SCORE_POS_X(sp),d1
    move.w  d1,d3
    add.w   SCORE_WIDTH(sp),d3
    
    
    move.w  SCORE_HEIGHT(sp),d2
    divu.w  #2,d2
    add.w   SCORE_POS_Y(sp),d2
    move.w  d2,d4
    
    clr.l   d5
    move.w  #SCORE_THICKNESS,d5
    divu.w  #2,d5
    
    
    sub.w   d5,d2
    add.w   d5,d4
    
    TRAP    #15
    
    
.End
    
    
    movem.l (sp)+,SCORE_REG
    rts
    

;xXABCDEFG               0   1   2   3   4   5  6    7   8   9
ScoreMask      dc.b     $7E,$30,$6D,$79,$33,$5B,$5F,$70,$7F,$7B




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
