; playerState bitwise bool
; 00000000
; ||||||||
; |||||||-> isJumping
; ||||||--> isFalling
; |||||---> (empty)
; --------> (empty)

isJumping  = %00000001
isFalling  = %00000010
isGameOver = %00000001 ; for gameState

collisionram = $700


.segment "HEADER"

.byte "NES"
.byte $1A
.byte $02
.byte $01
.byte %00000000
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00, $00, $00, $00, $00

.segment "BSS"


.segment "ZEROPAGE"
gameState:              .res 1
playerXPos:             .res 1
playerYPos:             .res 1
cactus1XPos:            .res 1
cactus1YPos:            .res 1
cactus2XPos:            .res 1
cactus2YPos:            .res 1
cactusTmpX:             .res 1
cactusTmpY:             .res 1
playerState:            .res 1
playerJumpSpeed:        .res 1
playerFallSpeed:        .res 1
cactusMoveSpeed:        .res 1
collisionHandler:       .res 1
walkingAnimationState:  .res 1
walkingAnimationDelay:  .res 1
playerXCollisionIndex:  .res 1   
playerYCollisionIndex:  .res 1
cactusXCollisionIndex:  .res 1
cactusYCollisionIndex:  .res 1

.segment "STARTUP"


.segment "CODE"


Reset:
    sei 
    cld         
    ldx #$40
    stx $4017
    ldx #$FF
    txs 
    inx
    stx $2000
    stx $2001 
    stx $4010
:
    bit $2002
    bpl :-
    txa 

clearmem:
    sta $0000, x
    sta $0100, x
    sta $0300, x
    sta $0400, x
    sta $0500, x
    sta $0600, x
    sta $0700, x
    lda #$FE
    sta $0200, x
    lda #$00
    inx 
    bne clearmem 
:
    bit $2002
    bpl :-
    lda #$02
    sta $4014
    nop 
    lda #$3F
    sta $2006
    lda #$00
    sta $2006
    ldx #$00

loadpalettes:
    lda PaletteData, x
    sta $2007
    inx 
    cpx #$20
    bne loadpalettes

init:
    ldx #$00
initCollisionRam:
    lda CollisionMap, x
    sta collisionram, x
    inx
    cpx #$78
    bne initCollisionRam
    lda #$04
    sta cactusMoveSpeed
    lda #$03
    sta playerXPos
    lda #$A2
    sta playerYPos
    lda #$A2 
    sta cactus1XPos
    lda #$F1
    sta cactus2XPos
    lda #$AA
    sta cactus1YPos
    lda #$9F
    sta cactus2YPos 

enableNMI:
    cli 
    lda #%10010000
    sta $2000
    lda #%00011110
    sta $2001

Forever:
    jmp Forever

CheckCollide:
    txa 
    lsr 
    lsr 
    lsr 
    lsr 
    lsr 
    lsr 
    sta collisionHandler
    tya 
    lsr 
    lsr  
    lsr
    asl 
    asl 
    clc 
    adc collisionHandler
    tay 
    txa 
    lsr 
    lsr 
    lsr 
    and #%00000111
    tax 
    lda collisionram, y
    and BitMask, x
    rts 

checkCactusCollision:
    ldx #$00
    stx playerXCollisionIndex
    stx playerYCollisionIndex
    ldy #$00
checkCollisionY:
    ldx #$00
    stx playerXCollisionIndex
checkCollisionX:
    lda playerXPos
    clc 
    adc playerXCollisionIndex
    pha 
    lda cactusTmpX
    sta cactusXCollisionIndex
    pla 
    cmp cactusXCollisionIndex
    bne :+
    lda playerYPos 
    clc 
    adc playerYCollisionIndex
    pha 
    lda cactusTmpY
    sta cactusYCollisionIndex
    pla 
    cmp cactusYCollisionIndex
    bne :+
    lda gameState
    ora #isGameOver
    sta gameState
:
    inx 
    inc playerXCollisionIndex
    cpx #$18
    bne checkCollisionX
    iny 
    inc playerYCollisionIndex
    cpy #$18
    bne checkCollisionY
endCheckCollision:
    rts

jump:
    lda playerState
    ora #isJumping
    sta playerState
    lda #$0B
    sta playerJumpSpeed
    rts

adjustLegPosition:
    lda #$08
    clc 
    adc #$0C
    clc 
    adc #$0D
    rts

update:
    lda #$01
    sta $4016
    lda #$00
    sta $4016
    lda $4016
    and #%00000001 
    cmp #%00000001
    bne A_not_pressed
    lda playerState
    and #isJumping
    cmp #$00
    bne A_not_pressed
    lda playerState
    and #isFalling
    cmp #$00
    bne A_not_pressed
    jsr jump
A_not_pressed:
    lda $4016
    and #%00000001
    cmp #%00000001 
    bne B_not_pressed
B_not_pressed:
    lda $4016
    and #%00000001
    cmp #%00000001
    bne Select_not_pressed
Select_not_pressed:
    lda $4016
    and #%00000001
    cmp #%00000001
    bne Start_not_pressed
Start_not_pressed:
    lda $4016
    and #%00000001
    cmp #%00000001
    bne Up_not_pressed
    lda playerState
    and #isJumping
    cmp #$00
    bne Up_not_pressed
    lda playerState
    and #isFalling
    cmp #$00
    bne Up_not_pressed
    jsr jump
Up_not_pressed:
    lda $4016
    and #%00000001
    cmp #%00000001
    bne Down_not_pressed
Down_not_pressed:
    lda $4016
    and #%00000001
    cmp #%00000001
    bne Left_not_pressed
Left_not_pressed:
    lda $4016
    and #%00000001
    cmp #%00000001
    bne Right_not_pressed
Right_not_pressed:
end_input:
    lda cactus1XPos
    sec 
    sbc cactusMoveSpeed
    sta cactus1XPos
    lda cactus2XPos 
    sec 
    sbc cactusMoveSpeed
    sta cactus2XPos
    inc walkingAnimationDelay
    lda walkingAnimationDelay
    cmp #$06
    bne :+
    lda #$00
    sta walkingAnimationDelay
:
    lda playerState
    and #isJumping
    cmp #$00
    bne setWalkingStateToZero
    lda playerState
    and #isFalling
    cmp #$00
    bne setWalkingStateToZero
    lda walkingAnimationDelay
    cmp #$05
    bne endWalkingAnimState     
    lda walkingAnimationState
    cmp #$01
    bne :+
    lda #$02
    sta walkingAnimationState
    jmp endWalkingAnimState
:   
    lda #$01
    sta walkingAnimationState
    jmp endWalkingAnimState
setWalkingStateToZero:
    lda #$00
    sta walkingAnimationState
endWalkingAnimState:

checkForJump:
    lda playerState
    and #isJumping
    cmp #$00
    beq :+
    lda playerYPos
    sec 
    sbc playerJumpSpeed
    sta playerYPos
    dec playerJumpSpeed
    lda playerJumpSpeed
    cmp #$00
    bne :+
    lda playerState
    eor #isJumping
    ora #isFalling
    sta playerState
    lda #$00
    sta playerFallSpeed
:
checkForFall:
    lda playerState
    and #isFalling
    cmp #$00
    beq :+
    lda playerYPos
    clc 
    adc playerFallSpeed
    sta playerYPos
    inc playerFallSpeed
    ldx playerXPos
    ldy playerYPos
    jsr CheckCollide
    beq :+
    lda playerState
    eor #isFalling
    sta playerState
:
    lda cactus1XPos
    sta cactusTmpX
    lda cactus1YPos
    sta cactusTmpY
    jsr checkCactusCollision
    lda cactus2XPos
    sta cactusTmpX
    lda cactus2YPos
    clc 
    adc #$08
    sta cactusTmpY
    jsr checkCactusCollision

    rts
    
draw:
    lda #$08
    clc 
    adc playerYPos
    sta $200
    lda #$00
    sta $201
    sta $202
    lda #$08
    clc 
    adc playerXPos
    sta $203
    lda #$08
    clc 
    adc playerYPos
    sta $204
    lda #$01
    sta $205
    lda #$00
    sta $206
    lda #$10
    clc 
    adc playerXPos
    sta $207
    lda #$08
    clc 
    adc playerYPos
    sta $208
    lda #$02
    sta $209
    lda #$00
    sta $20A
    lda #$18
    clc 
    adc playerXPos
    sta $20B
    lda #$08
    clc 
    adc playerYPos
    sta $20C
    lda #$03
    sta $20D
    lda #$00
    sta $20E
    lda #$20
    clc 
    adc playerXPos
    sta $20F
    lda #$10
    clc 
    adc playerYPos
    sta $210
    lda #$04
    clc 
    adc #$0C
    sta $211
    lda #$00
    sta $212
    lda #$08
    clc 
    adc playerXPos
    sta $213
    lda #$10
    clc 
    adc playerYPos
    sta $214
    lda #$05
    clc 
    adc #$0C
    sta $215
    lda #$00
    sta $216
    lda #$10
    clc 
    adc playerXPos
    sta $217
    lda #$10
    clc 
    adc playerYPos
    sta $218
    lda #$06
    clc 
    adc #$0C
    sta $219
    lda #$00
    sta $21A
    lda #$18
    clc 
    adc playerXPos
    sta $21B
    lda #$18
    clc 
    adc playerYPos
    sta $21C
    lda #$07
    clc 
    adc #$0C
    clc 
    adc #$0D
    sta $21D
    lda #$00
    sta $21E
    lda #$08
    clc 
    adc playerXPos
    sta $21F
    lda #$18
    clc 
    adc playerYPos
    sta $220
    lda walkingAnimationState
    cmp #$01
    beq setWalkingToWalking1
    cmp #$02
    beq setWalkingToWalking2
    jsr adjustLegPosition
    jmp :+
setWalkingToWalking1:
    jsr adjustLegPosition
    clc 
    adc #$02
    jmp :+
setWalkingToWalking2:
    jsr adjustLegPosition
    clc 
    adc #$03
:
    sta $221
    lda #$00
    sta $222
    lda #$10
    clc 
    adc playerXPos
    sta $223
    lda #$18
    clc 
    adc playerYPos
    sta $224
    lda #$09
    clc 
    adc #$0C
    clc 
    adc #$0D
    sta $225
    lda #$00
    sta $226
    lda #$18
    clc 
    adc playerXPos
    sta $227
    lda #$08
    clc 
    adc cactus1YPos 
    sta $228
    lda #$04
    sta $229
    lda #$00
    sta $22A
    lda  #$08
    clc 
    adc cactus1XPos
    sta $22B
    lda #$08
    clc 
    adc cactus1YPos 
    sta $22C
    lda #$05
    sta $22D
    lda #$00
    sta $22E
    lda #$10
    clc 
    adc cactus1XPos
    sta $22F
    lda #$10
    clc 
    adc cactus1YPos 
    sta $230
    lda #$05
    clc 
    adc #$0F
    sta $231
    lda #$00
    sta $232
    lda  #$08
    clc 
    adc cactus1XPos
    sta $233
    lda #$10
    clc 
    adc cactus1YPos 
    sta $234
    lda #$05
    clc 
    adc #$10
    sta $235
    lda #$00
    sta $236
    lda #$10
    clc 
    adc cactus1XPos
    sta $237
    lda #$08
    clc 
    adc cactus2YPos 
    sta $238
    lda #$16
    sta $239
    lda #$00
    sta $23A
    lda #$08
    clc 
    adc cactus2XPos 
    sta $23B
    lda #$08
    clc 
    adc cactus2YPos
    sta $23C
    lda #$17
    sta $23D
    lda #$00
    sta $23E
    lda #$10
    clc 
    adc cactus2XPos
    sta $23F
    lda #$10
    clc
    adc cactus2YPos 
    sta $240
    lda #$26
    sta $241
    lda 00
    sta $242
    lda #$08
    clc 
    adc cactus2XPos 
    sta $243
    lda #$10
    clc 
    adc cactus2YPos 
    sta $244
    lda #$27
    sta $245
    lda #$00
    sta $246
    lda #$10
    clc 
    adc cactus2XPos 
    sta $247
    lda #$18
    clc 
    adc cactus2YPos 
    sta $248
    lda #$36
    sta $249
    lda #$00 
    sta $24A
    lda #$08
    clc 
    adc cactus2XPos
    sta $24B
    lda #$18
    clc 
    adc cactus2YPos 
    sta $24C
    lda #$37
    sta $24D
    lda #$00
    sta $24E
    lda #$10
    clc 
    adc cactus2XPos 
    sta $24F
    lda #$20
    clc 
    adc cactus2YPos 
    sta $250
    lda #$46
    sta $251
    lda #$00
    sta $252
    lda #$08
    clc 
    adc cactus2XPos
    sta $253
    lda #$20
    clc 
    adc cactus2YPos 
    sta $254
    lda #$47
    sta $255
    lda #$00
    sta $256
    lda #$10
    clc 
    adc cactus2XPos 
    sta $257
    rts 

NMI:
    lda #$00
    sta $2003
    lda #$02
    sta $4014
    lda gameState
    and #isGameOver
    cmp #$00
    bne :+
    jsr draw 
    jsr update
 :
    rti 
    
PaletteData:
.byte $30,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D
.byte $30,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D 

CollisionMap:
    .byte %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000
    .byte %11111111, %00000000, %00000000, %00000000
    .byte %11111111, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000, %00000000
    
BitMask:
    .byte %10000000
    .byte %01000000
    .byte %00100000
    .byte %00010000
    .byte %00001000
    .byte %00000100
    .byte %00000010
    .byte %00000001
    
.segment "VECTORS"
    .word NMI
    .word Reset
.segment "CHARS"
    .incbin "chrrom.chr"