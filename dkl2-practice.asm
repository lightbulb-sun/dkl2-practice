INTRODUCE_LAG               equ     0

TOTAL_COLS                  equ     32
COLS                        equ     20
ROWS                        equ     18
VRAM_TILEMAP                equ     $9800
TILE_A                      equ     $a0
TILE_0                      equ     $ba
TILE_SPACE                  equ     $00
SELECT_ROM_BANK             equ     $2000
CUR_ROM_BANK                equ     $4000
MY_CODE_START               equ     $4400
MY_BANK                     equ     $20
TURN_ON_LCD                 equ     $3982
READ_JOYPAD_BUTTONS         equ     $3839
HELD_BUTTONS                equ     $dea1
NEW_BUTTONS                 equ     $dea2
CUR_WORLD                   equ     $ffae
CUR_LOCAL_LEVEL_ID          equ     $ffaf
CUR_GLOBAL_LEVEL_ID         equ     $ffa6
LCDC                        equ     $ff40
NR52                        equ     $ff26
OAM_BUFFER                  equ     $c000
SIZE_OAM                    equ     160
TRANSFER_OAM_BUFFER         equ     $ff80
BGP                         equ     $ff47
OBP0                        equ     $ff48
OBP1                        equ     $ff49
ATTRIBUTE_OBP0              equ     $00
ATTRIBUTE_OBP1              equ     $10
MENU_PALETTE_ACTIVE         equ     %11010000
MENU_PALETTE_INACTIVE       equ     %01000000
BIT_SPRITE_ENABLE           equ     1
BIT_8x16_SPRITES            equ     2
WAIT_FOR_LINE               equ     $35c2
LINE_VBLANK                 equ     $90
FREE_WRAM                   equ     $ddf0
WORLD_VRAM                  equ     $9800
LEVEL_VRAM                  equ     $9820
LEVEL_COLUMN_VRAM           equ     $98a8
LEVEL_COLUMN_MAX_LENGTH     equ     11
STAR_BARREL_VRAM            equ     $9a2f
NUM_WORLDS                  equ     7
NUM_CHARS                   equ     3
NUM_COLUMNS                 equ     3
CUR_NUM_LIVES               equ     $ffaa
NUM_LIVES                   equ     16
ERASE_MEM_IN_8_BYTE_CHUNKS  equ     $3949
CHAR_DIXIE_FLAG             equ     $ffac
CHAR_BOTH_FLAG              equ     $ffad

OWN_GFX_VRAM                equ     $8f00
OWN_GFX_TILES               equ     (OWN_GFX_VRAM >> 4) & $ff

TILE_VERSION                equ     OWN_GFX_TILES + 0
TILE_CURSOR                 equ     OWN_GFX_TILES + 2
VRAM_VERSION                equ     $9a32

IF FRAMECOUNTER == 1
VRAM_DIGITS                 equ     $8ba0
NUM_DIGITS                  equ     10
VRAM_LETTERS                equ     $8a00
NUM_LETTERS                 equ     6
TILE_0_INGAME               equ     $f0
VRAM_FRAME_COUNTER          equ     $9c00
IF LAGCOUNTER == 1
VRAM_LAG_COUNTER            equ     $9c03
ENDC
ENDC


MASK_BUTTON_A               equ     $01
MASK_BUTTON_B               equ     $02
MASK_BUTTON_SELECT          equ     $04
MASK_BUTTON_START           equ     $08
MASK_BUTTON_RIGHT           equ     $10
MASK_BUTTON_LEFT            equ     $20
MASK_BUTTON_UP              equ     $40
MASK_BUTTON_DOWN            equ     $80

BIT_BUTTON_A                equ     0
BIT_BUTTON_B                equ     1
BIT_BUTTON_SELECT           equ     2
BIT_BUTTON_START            equ     3
BIT_BUTTON_RIGHT            equ     4
BIT_BUTTON_LEFT             equ     5
BIT_BUTTON_UP               equ     6
BIT_BUTTON_DOWN             equ     7

CURSOR_TOP                  equ     8*7
CURSOR_WORLD_LEFT           equ     8
CURSOR_WORLD_TOP            equ     CURSOR_TOP
CURSOR_LEVEL_LEFT           equ     8*8
CURSOR_LEVEL_TOP            equ     CURSOR_TOP
CURSOR_CHAR_LEFT            equ     8*15
CURSOR_CHAR_TOP             equ     CURSOR_TOP

FIRST_BOOT_MAGIC            equ     $ab


SECTION "variables", WRAMX[FREE_WRAM], BANK[1]
first_boot:                 db
frame:                      db
lag_frames:                 db
selected_world:             db
selected_level:             db
selected_char:              db
cursor_world_x:             db
cursor_world_y:             db
cursor_level_x:             db
cursor_level_y:             db
cursor_char_x:              db
cursor_char_y:              db
active_cursor:              db
cur_num_levels:             db
star_barrel_flag:           db


SECTION "suppress_publisher_tiles", ROMX[$6236], BANK[5]
            nop
            nop
            nop
SECTION "suppress_publisher_tilemap", ROMX[$6244], BANK[5]
            nop
            nop
            nop
SECTION "return_early_from_publisher_logo", ROMX[$6259], BANK[5]
            ret

SECTION "menu_loader", ROM0[$0186]
            ld      a, MY_BANK
            ld      [SELECT_ROM_BANK], a
            jp      menu

SECTION "suppress_overworld", ROMX[$70b3], BANK[2]
            jp      $7168
SECTION "jump_over_overworld", ROMX[$7178], BANK[2]
            jr      $7199

SECTION "do_not_decrement_lives", ROM0[$037c]
            nop

SECTION "suppress_altering_of_both_characters_flag", ROM0[$01ec]
            nop
            nop

SECTION "change_star_barrel_flag_detection", ROM0[$0229]
            ld      a, [star_barrel_flag]
            and     a



IF FRAMECOUNTER == 1
SECTION "suppress_drawing_of_hearts1", ROM0[$1d0c]
            ld      a, 0
SECTION "suppress_drawing_of_hearts2", ROM0[$1d16]
            ld      a, 0
SECTION "original_vblank", ROM0[$3556]
            ld      a, MY_BANK
            ld      [SELECT_ROM_BANK], a
            jp      my_vblank
ENDC



IF LAGCOUNTER == 1
SECTION "lag_frame", ROM0[$0432]
            ld      a, MY_BANK
            ld      [SELECT_ROM_BANK], a
            jp      increase_lag_frames
ENDC


SECTION "my_code", ROMX[MY_CODE_START], BANK[MY_BANK]
menu::
            call    turn_off_sound
            call    init_variables
            call    clear_oam_buffer
            call    enable_sprites
            call    set_palettes
            call    load_tilemap
            call    load_own_graphics
            call    draw_version
            call    TURN_ON_LCD
.loop
            call    READ_JOYPAD_BUTTONS
            call    handle_buttons
            call    draw_cursors
            call    calculate_num_levels
            call    wait_for_vblank
            call    TRANSFER_OAM_BUFFER
            ld      a, [frame]
            inc     a
            ld      [frame], a
            and     1
            jr      nz, .odd
.even
            call    print_selected_world
            call    print_selected_level
            jr      .loop
.odd
            call    print_level_column
            call    print_star_barrel_status
            jr      .loop

turn_off_sound::
            xor     a
            ldh     [NR52], a
            ret

init_variables::
            ld      a, [first_boot]
            cp      FIRST_BOOT_MAGIC
            ret     z
            ld      a, FIRST_BOOT_MAGIC
            ld      [first_boot], a
            xor     a
            ld      [frame], a
            ld      [lag_frames], a
            ld      [selected_world], a
            ld      [selected_level], a
            ld      [selected_char], a
            ld      [active_cursor], a
            ld      a, NUM_LIVES
            ldh     [CUR_NUM_LIVES], a
            ld      a, 1
            ld      [star_barrel_flag], a

            ld      a, CURSOR_WORLD_LEFT
            ld      [cursor_world_x], a
            ld      a, CURSOR_WORLD_TOP
            ld      [cursor_world_y], a
            ld      a, CURSOR_LEVEL_LEFT
            ld      [cursor_level_x], a
            ld      a, CURSOR_LEVEL_TOP
            ld      [cursor_level_y], a
            ld      a, CURSOR_CHAR_LEFT
            ld      [cursor_char_x], a
            ld      a, CURSOR_CHAR_TOP
            ld      [cursor_char_y], a
            ld      a, [num_levels]
            ld      [cur_num_levels], a

            ret

load_own_graphics::
            ld      de, own_graphics
            ld      bc, (end_of_own_graphics - own_graphics)
            ld      hl, OWN_GFX_VRAM
            call    copy_from_de_to_hl_16bit
            ret

draw_version::
            ld      hl, VRAM_VERSION
            ld      a, TILE_VERSION
            ld      [hl+], a
            inc     a
            ld      [hl], a
            ret

clear_oam_buffer::
            ld      hl, OAM_BUFFER
            ld      d, (SIZE_OAM>>3)
            call    ERASE_MEM_IN_8_BYTE_CHUNKS
            ret

wait_for_vblank::
            ld      b, LINE_VBLANK
            call    WAIT_FOR_LINE
            ret

enable_sprites::
            ld      hl, LCDC
            set     BIT_SPRITE_ENABLE, [hl]
            res     BIT_8x16_SPRITES, [hl]
            ret

set_palettes::
            ld      a, MENU_PALETTE_ACTIVE
            ldh     [BGP], a
            ldh     [OBP0], a
            ld      a, MENU_PALETTE_INACTIVE
            ldh     [OBP1], a
            ret

load_tilemap::
            ld      hl, VRAM_TILEMAP
            ld      de, menu_tilemap
            ld      c, ROWS
.row_loop
            ld      b, COLS
            call    copy_from_de_to_hl
            push    bc
            ld      bc, TOTAL_COLS-COLS
            add     hl, bc
            pop     bc
            dec     c
            jr      nz, .row_loop
            ret

calculate_num_levels::
            ld      a, [selected_world]
            ld      hl, num_levels
            ld      b, 0
            ld      c, a
            add     hl, bc
            ld      a, [hl]
            ld      [cur_num_levels], a
            ret

calculate_cursor_positions::
.world
            ld      a, [selected_world]
            sla     a
            sla     a
            sla     a
            add     CURSOR_WORLD_TOP
            ld      [cursor_world_y], a
.level
            ld      a, [selected_level]
            sla     a
            sla     a
            sla     a
            add     CURSOR_LEVEL_TOP
            ld      [cursor_level_y], a
.character
            ld      a, [selected_char]
            sla     a
            sla     a
            sla     a
            add     CURSOR_CHAR_TOP
            ld      [cursor_char_y], a
            ret

draw_cursors::
            ld      a, [active_cursor]
            ld      c, a
            call    calculate_cursor_positions
            ld      hl, OAM_BUFFER
.world
            ld      a, [cursor_world_y]
            ld      [hl+], a
            ld      a, [cursor_world_x]
            ld      [hl+], a
            ld      a, TILE_CURSOR
            ld      [hl+], a
.if_world_active
            ld      a, 0
            cp      c
            jr      z, .world_active
.world_inactive
            ld      a, ATTRIBUTE_OBP1
            jr      .world_end
.world_active
            ld      a, ATTRIBUTE_OBP0
.world_end
            ld      [hl+], a
.level
            ld      a, [cursor_level_y]
            ld      [hl+], a
            ld      a, [cursor_level_x]
            ld      [hl+], a
            ld      a, TILE_CURSOR
            ld      [hl+], a
.if_level_active
            ld      a, 1
            cp      c
            jr      z, .level_active
.level_inactive
            ld      a, ATTRIBUTE_OBP1
            jr      .level_end
.level_active
            ld      a, ATTRIBUTE_OBP0
.level_end
            ld      [hl+], a
.char
            ld      a, [cursor_char_y]
            ld      [hl+], a
            ld      a, [cursor_char_x]
            ld      [hl+], a
            ld      a, TILE_CURSOR
            ld      [hl+], a
.if_char_active
            ld      a, 2
            cp      c
            jr      z, .char_active
.char_inactive
            ld      a, ATTRIBUTE_OBP1
            jr      .char_end
.char_active
            ld      a, ATTRIBUTE_OBP0
.char_end
            ld      [hl+], a
            ret

handle_buttons::
            ld      a, [NEW_BUTTONS]
            bit     BIT_BUTTON_START, a
            jp      nz, start_level

            ld      a, [NEW_BUTTONS]
            bit     BIT_BUTTON_UP, a
            call    nz, handle_up_press

            ld      a, [NEW_BUTTONS]
            bit     BIT_BUTTON_DOWN, a
            call    nz, handle_down_press

            ld      a, [NEW_BUTTONS]
            bit     BIT_BUTTON_LEFT, a
            call    nz, handle_left_press

            ld      a, [NEW_BUTTONS]
            bit     BIT_BUTTON_RIGHT, a
            call    nz, handle_right_press

            ld      a, [NEW_BUTTONS]
            bit     BIT_BUTTON_SELECT, a
            call    nz, handle_select_press

            ret

handle_select_press::
            ld      a, [star_barrel_flag]
            xor     1
            ld      [star_barrel_flag], a
            ret

handle_down_press::
.if_world
            ld      a, [active_cursor]
            and     a
            jr      nz, .if_level
.increase_world
            ld      a, [selected_world]
            inc     a
            cp      NUM_WORLDS
            jr      nz, .world_cont
.world_back_to_1
            xor     a
.world_cont
            ld      [selected_world], a
.reset_level
            xor     a
            ld      [selected_level], a
            ret
.if_level
            dec     a
            jr      nz, .increase_char
.increase_level
            ld      a, [selected_level]
            inc     a
            ld      hl, cur_num_levels
            cp      [hl]
            jr      nz, .level_cont
.level_back_to_1
            xor     a
.level_cont
            ld      [selected_level], a
            ret
.increase_char
            ld      a, [selected_char]
            inc     a
            cp      NUM_CHARS
            jr      nz, .char_cont
.char_back_to_1
            xor     a
.char_cont
            ld      [selected_char], a
            ret
            ret

handle_up_press::
.if_world
            ld      a, [active_cursor]
            and     a
            jr      nz, .if_level
.decrease_world
            ld      a, [selected_world]
            and     a
            jr      z, .world_back_to_last
            dec     a
            jr      .world_cont
.world_back_to_last
            ld      a, NUM_WORLDS-1
.world_cont
            ld      [selected_world], a
.reset_level
            xor     a
            ld      [selected_level], a
            ret
.if_level
            dec     a
            jr      nz, .decrease_char
.decrease_level
            ld      a, [selected_level]
            and     a
            jr      z, .level_back_to_last
            dec     a
            jr      .level_cont
.level_back_to_last
            ld      a, [cur_num_levels]
            dec     a
.level_cont
            ld      [selected_level], a
            ret
.decrease_char
            ld      a, [selected_char]
            and     a
            jr      z, .char_back_to_last
            dec     a
            jr      .char_cont
.char_back_to_last
            ld      a, NUM_CHARS-1
.char_cont
            ld      [selected_char], a
            ret
            ret

handle_right_press::
            ld      a, [active_cursor]
            inc     a
            cp      NUM_COLUMNS
            jr      nz, .end
            xor     a
.end
            ld      [active_cursor], a
            ret

handle_left_press::
            ld      a, [active_cursor]
            and     a
            jr      z, .back_to_last
            dec     a
            jr      .end
.back_to_last
            ld      a, NUM_COLUMNS-1
.end
            ld      [active_cursor], a
            ret

set_characters::
            ld      a, [selected_char]
            and     a
            jr      z, .diddy
            dec     a
            jr      z, .dixie
.both
            ld      a, 1
            ldh     [CHAR_BOTH_FLAG], a
            ret
.diddy
            ret
.dixie
            ld      a, 1
            ldh     [CHAR_DIXIE_FLAG], a
            ret

set_level_id::
            ld      a, [selected_world]
            sla     a
            ld      d, 0
            ld      e, a
            ld      hl, level_id_table
            add     hl, de
            ld      a, [hl+]
            ld      c, a
            ld      b, [hl]
            ld      h, 0
            ld      a, [selected_level]
            ld      l, a
            add     hl, bc

            ld      a, [hl]
            ldh     [CUR_LOCAL_LEVEL_ID], a

            ld      a, [selected_world]
            inc     a
            cp      6
            jr      c, .cont
            jr      z, .turn_into_world7
.turn_into_world6
            dec     a
            jr      .cont
.turn_into_world7
            inc     a
.cont
            ldh     [CUR_WORLD], a
            ret

start_level::
            call    wait_for_vblank
            ld      hl, LCDC
            res     7, [hl]

            call    set_characters
            call    set_level_id
IF FRAMECOUNTER == 1
            call    copy_alnum
            xor     a
            ld      [frame], a
ENDC
            pop     hl

            jp      $0199

IF FRAMECOUNTER == 1
copy_alnum::
            ld      de, VRAM_DIGITS
            ld      hl, OWN_GFX_VRAM
            ld      b, $10*NUM_DIGITS
            call    copy_from_de_to_hl

            ld      de, VRAM_LETTERS
            ld      b, $10*NUM_LETTERS
            call    copy_from_de_to_hl

            ret
ENDC

copy_from_de_to_hl::
.loop
            ld      a, [de]
            ld      [hl+], a
            inc     de
            dec     b
            jr      nz, .loop
            ret

copy_from_de_to_hl_16bit::
.loop
            ld      a, [de]
            ld      [hl+], a
            inc     de
            dec     bc
            ld      a, b
            or      c
            jr      nz, .loop
            ret

overwrite_memory::
.loop
            ld      [hl+], a
            dec     b
            jr      nz, .loop
            ret

overwrite_memory_column::
.loop
            ld      [hl], a
            add     hl, de
            dec     b
            jr      nz, .loop
            ret

print_selected_world::
.erase_previous
            ld      a, TILE_SPACE
            ld      b, COLS
            ld      hl, WORLD_VRAM
            call    overwrite_memory
.calculate_pointer
            ld      hl, world_strings
            ld      a, [selected_world]
            sla     a
            ld      d, 0
            ld      e, a
            add     hl, de
            ld      a, [hl+]
            ld      e, a
            ld      a, [hl]
            ld      d, a
.print_current
            ld      hl, WORLD_VRAM
            ld      a, [de]
            inc     de
            ld      b, a
            call    copy_from_de_to_hl
            ret

print_selected_level::
.erase_previous
            ld      a, TILE_SPACE
            ld      b, COLS
            ld      hl, LEVEL_VRAM
            call    overwrite_memory
.calculate_first_pointer
            ld      hl, level_strings
            ld      a, [selected_world]
            sla     a
            ld      d, 0
            ld      e, a
            add     hl, de
            ld      a, [hl+]
            ld      c, a
            ld      a, [hl]
            ld      b, a
.calculate_second_pointer
            ld      a, [selected_level]
            sla     a
            ld      h, 0
            ld      l, a
            add     hl, bc
            ld      a, [hl+]
            ld      e, a
            ld      a, [hl]
            ld      d, a
.print_current
            ld      hl, LEVEL_VRAM
            ld      a, [de]
            inc     de
            ld      b, a
            call    copy_from_de_to_hl
            ret

print_level_column::
.erase_previous
            ld      a, TILE_SPACE
            ld      hl, LEVEL_COLUMN_VRAM
            ld      de, TOTAL_COLS
            ld      b, LEVEL_COLUMN_MAX_LENGTH
            push    bc
            push    de
            push    hl
            call    overwrite_memory_column
            pop     hl
            pop     de
            pop     bc
            inc     hl
            call    overwrite_memory_column
.print_current
            ld      a, [cur_num_levels]
            dec     a
            ld      b, a
            ld      a, 1
            ld      hl, LEVEL_COLUMN_VRAM
            ld      de, TOTAL_COLS
.loop
            ld      c, a
            cp      10
            jr      c, .below_10
.at_least_10
            inc     hl
            add     TILE_0-10
            ld      [hl], a
            dec     hl
            ld      a, TILE_0+1
            ld      [hl], a
            jr      .cont
.below_10
            add     TILE_0
            ld      [hl], a
.cont
            add     hl, de
            ld      a, c
            inc     a
            dec     b
            jr      nz, .loop
.boss
            ld      a, TILE_A + "B" - "A"
            ld      [hl], a
            ret

print_star_barrel_status::
            ld      hl, STAR_BARREL_VRAM
            ld      a, [star_barrel_flag]
            and     a
            jr      z, .yes
.no
            ld      a, TILE_A+"N"-"A"
            ld      [hl+], a
            ld      a, TILE_A+"O"-"A"
            ld      [hl+], a
            ld      a, TILE_SPACE
            ld      [hl+], a
            ret
.yes
            ld      a, TILE_A+"Y"-"A"
            ld      [hl+], a
            ld      a, TILE_A+"E"-"A"
            ld      [hl+], a
            ld      a, TILE_A+"S"-"A"
            ld      [hl+], a
            ret

            

menu_tilemap::
            incbin  "menu.tilemap"

include "strings.asm"

level_id_table::
            dw      level_ids_world1, level_ids_world2, level_ids_world3
            dw      level_ids_world4, level_ids_world5, level_ids_world6
            dw      level_ids_world7
level_ids_world1::
            db      $00, $01, $02, $04, $05, $07
level_ids_world2::
            db      $00, $01, $02, $04, $05, $07, $08, $09, $0a, $0b, $0c
level_ids_world3::
            db      $00, $02, $03, $04, $05, $07, $08, $09
level_ids_world4::
            db      $00, $01, $02, $04, $06, $07
level_ids_world5::
            db      $00, $01, $03, $04, $05, $07, $08
level_ids_world6::
            db      $00, $03
level_ids_world7::
            db      $01, $03, $04, $05, $06, $07

own_graphics::
version_gfx::
            incbin  "gfx/version.2bpp"
cursor_gfx::
            incbin  "gfx/cursor.2bpp"
end_of_own_graphics::




IF FRAMECOUNTER == 1
my_vblank::
            ld      a, [frame]
            inc     a
            ld      [frame], a
            ld      b, a
            swap    a
            and     $0f
            add     TILE_0_INGAME
            ld      [VRAM_FRAME_COUNTER+0], a
            ld      a, b
            and     $0f
            add     TILE_0_INGAME
            ld      [VRAM_FRAME_COUNTER+1], a
IF LAGCOUNTER == 1
            ld      a, [lag_frames]
            ld      b, a
            swap    a
            and     $0f
            add     TILE_0_INGAME
            ld      [VRAM_LAG_COUNTER+0], a
            ld      a, b
            and     $0f
            add     TILE_0_INGAME
            ld      [VRAM_LAG_COUNTER+1], a
ENDC

            ; replace original instructions
            ld      a, [$deae]
            ld      l, a
            ld      a, [$deaf]
            ld      h, a
            jp      $355e
ENDC

IF LAGCOUNTER == 1
increase_lag_frames::
            ld      hl, lag_frames
            inc     [hl]

            ; replace original instructions
            ldh     a, [$ff44]
            cp      $20
            jr      c, .cont
            cp      $91
            jr      nc, .cont
            ld      b, $91
            jp      $043e
.cont
            jp      $0441
ENDC


IF INTRODUCE_LAG == 1
busy_loop::
            ld      bc, $2000
.loop
            dec     bc
            ld      a, b
            or      c
            jr      nz, .loop

            ; replace original instructions
            xor     a
            ld      hl, $c300
            ld      [hl+], a
            ld      a, h
            ld      [$deb0], a
            ld      a, l
            ld      [$deb1], a
            ret


SECTION "busy_loop", ROM0[$3456]
            ld      a, $20
            ld      [SELECT_ROM_BANK], a
            call    busy_loop
            ld      a, $20
            ld      [SELECT_ROM_BANK], a
ENDC
