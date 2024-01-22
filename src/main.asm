
.include "constants.inc" 
.include "header.inc"

.import reset_handler
.import draw_enemy
.import update_enemy
.import process_enemies

.segment "ZEROPAGE"
x_pos: .res 1
y_pos: .res 1
sleeping: .res 1

NUM_ENEMIES = 5

; enemy object pool
enemy_x_pos: .res NUM_ENEMIES
enemy_y_pos: .res NUM_ENEMIES
enemy_x_vels: .res NUM_ENEMIES
enemy_y_vels: .res NUM_ENEMIES
enemy_flags: .res NUM_ENEMIES 
; track entity number in use
; for various subroutines
current_enemy: .res 1
current_enemy_type: .res 1

; timer for spawning enemies
enemy_timer: .res 1

.exportzp x_pos, y_pos, enemy_x_pos, enemy_y_pos, enemy_x_vels, enemy_y_vels, enemy_flags, enemy_timer, current_enemy_type, current_enemy

.segment "CODE"
.proc irq_handler
  RTI
.endproc

.proc nmi_handler
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA
  LDA #$00

  ;;
  LDA #$00
  STA sleeping

  ; restore registers and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP

  RTI
.endproc

.proc move_square

  LDA y_pos
  STA $0200
  LDA #$01
  STA $0201
  LDA #$01
  STA $0202
  LDX x_pos
  INX
  STX x_pos
  STX $0203

  RTS
.endproc

.export main
.proc main
  LDX PPUSTATUS
  LDX #$3f
  STX PPUADDR
  LDX #$00
  STX PPUADDR

  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
  STA PPUCTRL
  LDA #%00011110  ; turn on screen
  STA PPUMASK

load_palettes:
  LDA palettes,X
  STA PPUDATA
  INX
  CPX #$20 ; there are 32 colours to load
  BNE load_palettes

  ;setup enemies
  ; set up enemy slots
  LDA #$00
  STA current_enemy
  STA current_enemy_type

  LDX #$00
xletter_data:
  LDA #$00 ; xletter
  STA enemy_flags,X
  LDA #$01
  STA enemy_y_vels,X
  INX
  CPX #$02
  BNE xletter_data
  ; X is now $03, no need to reset
yletter_data:
  LDA #$01 ; y letter
  STA enemy_flags,X
  LDA #$02
  STA enemy_y_vels,X
  INX
  CPX #$04
  BNE yletter_data

uletter_data:
  LDA #$02 ; u letter
  STA enemy_flags,X
  LDA #$03
  STA enemy_y_vels,X
  INX
  CPX #$05
  BNE uletter_data

  LDX #$00
  LDA #$10
setup_enemy_x:
  STA enemy_x_pos,X
  CLC
  ADC #$20
  INX
  CPX #NUM_ENEMIES
  BNE setup_enemy_x
  ;setup enemies

mainloop:

  JSR move_square
  JSR process_enemies

  	; Draw all enemies
	LDA #$00
	STA current_enemy
enemy_drawing:
	JSR draw_enemy
	INC current_enemy
	LDA current_enemy
	CMP #NUM_ENEMIES
	BNE enemy_drawing

  ;loop
  INC sleeping
sleep:
  LDA sleeping
  BNE sleep

  JMP mainloop
.endproc

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "CHR"
.incbin "gfx.chr"

.segment "RODATA"
palettes:
  ; background
  .byte $31, $12, $23, $27 ; skyblue,blue,purple,orange
  .byte $31, $2b, $3c, $39 ; skyblue,green,lightblue,mint
  .byte $31, $0c, $07, $13 ; skyblue,blue,brown,purple
  .byte $31, $19, $09, $29 ; skyblue,green,green,lightgreen

  ; sprites
  .byte $31, $2d, $10, $15 ; skyblue,grey,grey,pink
  .byte $31, $21, $23, $27 ; skyblue,blue,pink,orange
  .byte $31, $2a, $17, $01 ; skyblue,lightgreen,brown,darkblue
  .byte $31, $19, $09, $29 ; skyblue,green,green,lightgreen