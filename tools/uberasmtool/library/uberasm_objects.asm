; run in gamemode 13
incsrc "../../../shared/freeram.asm"


macro ObjectRoutine(object_number, routine)
    db <object_number>-$98 : dw <routine>
endmacro


routines:
.init
    %ObjectRoutine($9A, set_state_to_off)
    %ObjectRoutine($9B, block_duplication)
    %ObjectRoutine($9C, toggle_status_bar)
    %ObjectRoutine($9F, vanilla_turnaround)
..end

.main
    %ObjectRoutine($98, free_vertical_scroll)
    %ObjectRoutine($99, no_horizontal_scroll)
    %ObjectRoutine($9D, toggle_lr_scroll)
    %ObjectRoutine($9E, eight_frame_float)
    %ObjectRoutine($A0, enable_sfx_echo)
    %ObjectRoutine($B0, retry_instant)
    %ObjectRoutine($B1, retry_prompt)
    %ObjectRoutine($B2, retry_bottom_left)
    %ObjectRoutine($B3, retry_no_midway_powerup)
..end


init:
    lda $71
    cmp #$0A
    bne .not_castle_entrance
    rtl
.not_castle_entrance

    phb
    phk
    plb
    lda.b #routines_init&$FF
    sta $00
    lda.b #routines_init>>8
    sta $01
    rep #$10
    ldy.w #routines_init_end-routines_init-3
    jsr run_routines
    plb

.return
    rtl

main:
    lda $71
    cmp #$0A
    bne .not_castle_entrance
    rtl
.not_castle_entrance

    phb
    phk
    plb
    lda.b #routines_main&$FF
    sta $00
    lda.b #routines_main>>8
    sta $01
    rep #$10
    ldy.w #routines_main_end-routines_main-3
    jsr run_routines
    plb

.return
    rtl


; word routine table pointer in $00-$01
; table size - 3 (in bytes) in 16-bit Y (16-bit needed since 3 * 0x68 > 0xFF)
; clobbers: $02, $03, $04
run_routines:
    lda #$00
    xba             ; zero out high byte of A so we can transfer to 16-bit X later
.loop
    lda ($00),y     ; load current custom object number
    sta $02         ; cache in $02
    lsr #3          ; divide custom object number by 8 to get byte index into FreeRAM
    sta $03         ; cache in $03
    stz $04         ; zero out $04 so 16-bit X can load index later
    lda $02         ; restore custom object number from $02
    and #$07        ; modulo 8 to get bit index
    tax
    lda ..masks,x   ; load correct mask for the bit
    ldx $03         ; load byte index from $03-$04
    and !objectool_level_flags_freeram,x
    beq ..next      ; if bit not set skip the routine

    iny
    lda ($00),y
    sta $02
    iny
    lda ($00),y
    sta $03         ; otherwise, load word routine address into $02-$03

    phy             ; pushing current table index rather than caching in scratch so routines can use scratch
    sep #$10        ; ensuring routines get 8-bit everything
    ldx #$00
    jsr ($0002,x)   ; jump to object routine in $02-$03
    rep #$10        ; restore 16-bit X/Y
    ply             ; restore current table index

    dey #2          ; need to undo the two iny's from earlier

..next
    dey #3          ; move to next table entry
    bpl .loop
    sep #$10
    rts

..masks
    db 1,2,4,8,16,32,64,128


;---------------------------------------------------------------------
; Code to run for each object
; Object IDs correspond to patches/objectool/custom_object_code.asm
;---------------------------------------------------------------------

; Object 98
; Free vertical scrolling
free_vertical_scroll:
    lda #$01 : sta $1404|!addr
    rts

; Object 99
; lock horizontal scroll
no_horizontal_scroll:
    stz $1411|!addr
    rts

; Object 9A
; Set ON/OFF state to OFF
set_state_to_off:
    lda #$01 : sta $14AF|!addr
    rts

; Object 9B
; Toggle block duplication
block_duplication:
    lda #$01 : sta !toggle_block_duplication
    rts

; Object 9C
; Toggle status bar
toggle_status_bar:
    lda #$01 : sta !toggle_statusbar_freeram
    rts

; Object 9D
; Toggle l/r scroll
toggle_lr_scroll:
    lda #$01 : sta !toggle_lr_scroll_freeram
    rts

; Object 9E
; Enable eight frame float with cape
eight_frame_float:
    lda $15 : and #$80 : beq +
    lda #$08 : sta $14A5|!addr
    +
    rts

; Object 9F
; Toggle vanilla cape spin in air
vanilla_turnaround:
    lda #$01 : sta !toggle_vanilla_turnaround
    rts

; Object A0
; Enable Echo channel in inserted music
enable_sfx_echo:
    lda $1DFA|!addr : bne +
    lda #$06 : sta $1DFA|!addr
    +
    rts

; Object A1 (is skipped because of door)


; Object B0
; Use instant retry
retry_instant:
    lda #$03 : sta !retry_freeram+$11
    rts

; Object B1
; Use prompt retry
retry_prompt:
    lda #$02 : sta !retry_freeram+$11
    rts

; Object B2
; Display retry prompt in bottom left
retry_bottom_left:
    lda #$09 : sta !retry_freeram+$15
    lda #$d0 : sta !retry_freeram+$16
    rts

; Object B3
; No powerup from midways
retry_no_midway_powerup:
    lda #$00 : sta !retry_freeram+$10
    rts