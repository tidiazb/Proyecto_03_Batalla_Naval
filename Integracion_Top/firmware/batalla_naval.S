# Batalla Naval 8x8, RV32I de ciclo unico. Solo LW/SW: no LB/SB/MUL/DIV.
.option norvc
.option norelax
.equ STATE,   0x2200
.equ RXBUF,   0x2300
.equ SOUNDBUF,0x23c0
.equ TXBUF,   0x2400
.equ CMD,     0x22c0
# STATE: fase0,turno4,fila8,col12,orient16,colocados20/24,
# disparos28/32,hundidos36/40,impactos44/48,victorias52/56,
# rxlen60,rxdescartar64,txhead68,txtail72,soundhead84,soundtail88.
# CMD: id0,fila4,col8,orient12,resultado16,motivo20,actor24.
.macro ENTER
 addi sp,sp,-48
 sw ra,44(sp)
 sw s3,40(sp)
 sw s4,36(sp)
 sw s5,32(sp)
 sw s6,28(sp)
 sw s7,24(sp)
 sw s8,20(sp)
.endm
.macro LEAVE
 lw ra,44(sp)
 lw s3,40(sp)
 lw s4,36(sp)
 lw s5,32(sp)
 lw s6,28(sp)
 lw s7,24(sp)
 lw s8,20(sp)
 addi sp,sp,48
 ret
.endm
.section .text
.globl _start
_start:
 li sp,0x2ff0
 li s0,STATE
 li s1,0x10000
 li s2,0x11000
 sw zero,52(s0)
 sw zero,56(s0)
 sw zero,68(s0)
 sw zero,72(s0)
 jal ra,new_game
main_loop:
 jal ra,service_tx
 jal ra,service_sound
 jal ra,service_buttons
 jal ra,service_rx
 j main_loop

# Reinicio de partida: conserva victorias y mensajes completos en cola TX.
new_game:
 ENTER
 li t0,0x2000
 li t1,0x2200
ng_boards:
 sw zero,0(t0)
 addi t0,t0,4
 bltu t0,t1,ng_boards
 li t0,0
ng_state:
 add t1,s0,t0
 sw zero,0(t1)
 addi t0,t0,4
 li t2,52
 bltu t0,t2,ng_state
 sw zero,60(s0)
 sw zero,64(s0)
 sw zero,84(s0)
 sw zero,88(s0)
 li t0,0x2280
 li t1,0x2300
ng_scratch:
 sw zero,0(t0)
 addi t0,t0,4
 bltu t0,t1,ng_scratch
 li t0,24
 sw t0,0x40(s1)
 li t0,0x7f00
 sw t0,0x120(s1)
ng_drain:
 lw t0,0x40(s1)
 andi t0,t0,1
 beqz t0,ng_video
 li t0,0x100
 sw t0,0x40(s1)
 j ng_drain
ng_video:
 li t0,0
 li t1,300
 li t2,5
ng_clear:
 slli t3,t0,2
 add t3,s2,t3
 sw t2,0(t3)
 addi t0,t0,1
 bltu t0,t1,ng_clear
 sw zero,0x138(s1)
 jal ra,update_scores
 jal ra,render
 la a0,msg_new
 jal ra,putstr
 LEAVE

# FIFO software de 256 caracteres. TX_READY indica espacio, no fin de trama.
service_tx:
 lw t0,68(s0)
 lw t1,72(s0)
 beq t0,t1,tx_done
 lw t2,0x40(s1)
 andi t2,t2,2
 beqz t2,tx_done
 slli t2,t0,2
 li t3,TXBUF
 add t2,t2,t3
 lw t2,0(t2)
 sw t2,0x44(s1)
 addi t0,t0,1
 andi t0,t0,255
 sw t0,68(s0)
tx_done:
 ret
putc:
 ENTER
 mv s3,a0
pc_wait:
 lw t0,72(s0)
 addi t1,t0,1
 andi t1,t1,255
 lw t2,68(s0)
 bne t1,t2,pc_store
 jal ra,service_tx
 j pc_wait
pc_store:
 slli t2,t0,2
 li t3,TXBUF
 add t2,t2,t3
 sw s3,0(t2)
 sw t1,72(s0)
 LEAVE
# Cadenas empaquetadas en ROM; extraccion de byte por LW y desplazamiento.
putstr:
 ENTER
 mv s3,a0
ps_loop:
 andi t0,s3,-4
 lw t1,0(t0)
 andi t0,s3,3
 slli t0,t0,3
 srl a0,t1,t0
 andi a0,a0,255
 beqz a0,ps_done
 jal ra,putc
 addi s3,s3,1
 j ps_loop
ps_done:
 LEAVE
comma:
 li a0,44
 j putc
newline:
 li a0,10
 j putc
# Decimal sin extension M. Usado con valores 0..64.
putnum:
 ENTER
 mv s3,a0
 li s4,0
pn_tens:
 li t0,10
 bltu s3,t0,pn_digits
 addi s3,s3,-10
 addi s4,s4,1
 j pn_tens
pn_digits:
 beqz s4,pn_units
 addi a0,s4,48
 jal ra,putc
pn_units:
 addi a0,s3,48
 jal ra,putc
 LEAVE

# Cola de ocho sonidos: no bloquea botones ni UART durante el efecto.
queue_sound:
 lw t0,88(s0)
 addi t1,t0,1
 andi t1,t1,7
 lw t2,84(s0)
 beq t1,t2,qs_done
 slli t2,t0,2
 li t3,SOUNDBUF
 add t2,t2,t3
 sw a0,0(t2)
 sw t1,88(s0)
qs_done:
 ret
service_sound:
 lw t0,84(s0)
 lw t1,88(s0)
 beq t0,t1,ss_done
 lw t2,0x140(s1)
 andi t2,t2,1
 bnez t2,ss_done
 slli t2,t0,2
 li t3,SOUNDBUF
 add t2,t2,t3
 lw t2,0(t2)
 slli t2,t2,1
 ori t2,t2,1
 sw t2,0x140(s1)
 addi t0,t0,1
 andi t0,t0,7
 sw t0,84(s0)
ss_done:
 ret
update_scores:
 lw t0,52(s0)
 lw t1,56(s0)
 li t2,99
 bgeu t2,t0,us_j2
 mv t0,t2
us_j2:
 bgeu t2,t1,us_pack
 mv t1,t2
us_pack:
 slli t1,t1,8
 or t0,t0,t1
 sw t0,0x130(s1)
 ret

# Botones: eventos W1C (bits 14:8), prioridad RST, luego movimiento/SEL/OK.
service_buttons:
 ENTER
 lw t0,0x120(s1)
 srli s3,t0,8
 andi s3,s3,127
 beqz s3,sb_done
 slli t0,s3,8
 sw t0,0x120(s1)
 andi t0,s3,64
 beqz t0,sb_actions
 jal ra,new_game
 j sb_done
sb_actions:
 lw t0,0(s0)
 li t1,2
 beq t0,t1,sb_done
 lw s4,8(s0)
 lw s5,12(s0)
 andi t0,s3,1
 beqz t0,sb_down
 beqz s4,sb_down
 addi s4,s4,-1
sb_down:
 andi t0,s3,2
 beqz t0,sb_left
 li t1,7
 beq s4,t1,sb_left
 addi s4,s4,1
sb_left:
 andi t0,s3,4
 beqz t0,sb_right
 beqz s5,sb_right
 addi s5,s5,-1
sb_right:
 andi t0,s3,8
 beqz t0,sb_save
 li t1,7
 beq s5,t1,sb_save
 addi s5,s5,1
sb_save:
 sw s4,8(s0)
 sw s5,12(s0)
 lw t0,0(s0)
 bnez t0,sb_ok
 andi t0,s3,16
 beqz t0,sb_ok
 lw t0,16(s0)
 xori t0,t0,1
 sw t0,16(s0)
sb_ok:
 andi t0,s3,32
 beqz t0,sb_render
 li s6,CMD
 sw zero,24(s6)
 sw s4,4(s6)
 sw s5,8(s6)
 lw t0,0(s0)
 bnez t0,sb_fire
 lw t0,20(s0)
 li t1,3
 beq t0,t1,sb_render
 sw t0,0(s6)
 lw t0,16(s0)
 sw t0,12(s6)
 jal ra,place_ship
 beqz a0,sb_start
 li a0,4
 jal ra,queue_sound
 j sb_render
sb_start:
 jal ra,check_start
 j sb_render
sb_fire:
 lw t0,4(s0)
 bnez t0,sb_render
 jal ra,fire_shot
 beqz a0,sb_render
 li a0,4
 jal ra,queue_sound
sb_render:
 jal ra,render
sb_done:
 LEAVE

# Recepcion incremental: 31 caracteres max, CR ignorado, LF ejecuta comando.
service_rx:
 ENTER
 lw t0,0x40(s1)
 andi t1,t0,8
 beqz t1,sr_avail
 li t1,8
 sw t1,0x40(s1)
 li t1,1
 sw t1,64(s0)
sr_avail:
 andi t0,t0,1
 beqz t0,sr_done
 lw s3,0x48(s1)
 li t0,0x100
 sw t0,0x40(s1)
 li t0,13
 beq s3,t0,sr_done
 li t0,10
 beq s3,t0,sr_line
 lw t0,64(s0)
 bnez t0,sr_done
 li t0,32
 bltu s3,t0,sr_bad
 li t0,127
 bgeu s3,t0,sr_bad
 lw t0,60(s0)
 li t1,31
 bgeu t0,t1,sr_bad
 slli t1,t0,2
 li t2,RXBUF
 add t1,t1,t2
 sw s3,0(t1)
 addi t0,t0,1
 sw t0,60(s0)
 j sr_done
sr_bad:
 li t0,1
 sw t0,64(s0)
 j sr_done
sr_line:
 lw t0,64(s0)
 bnez t0,sr_error
 jal ra,parse_command
 j sr_clear
sr_error:
 la a0,msg_bad
 jal ra,putstr
sr_clear:
 sw zero,60(s0)
 sw zero,64(s0)
sr_done:
 LEAVE
# Prefijo almacenado como palabras ASCII; retorna 1 si coincide.
match_prefix:
 lw t0,0(a1)
 beqz t0,mp_ok
 lw t1,0(a0)
 bne t0,t1,mp_bad
 addi a0,a0,4
 addi a1,a1,4
 j match_prefix
mp_ok:
 li a0,1
 ret
mp_bad:
 li a0,0
 ret
parse_command:
 ENTER
 li s3,RXBUF
 li s4,CMD
 li t0,1
 sw t0,24(s4)
 lw t0,60(s0)
 li t1,13
 beq t0,t1,parse_place
 li t1,8
 beq t0,t1,parse_fire
 j parse_bad
parse_place:
 mv a0,s3
 la a1,prefix_place
 jal ra,match_prefix
 beqz a0,parse_bad
 lw t0,28(s3)
 lw t1,36(s3)
 lw t2,44(s3)
 li t3,44
 bne t0,t3,parse_bad
 bne t1,t3,parse_bad
 bne t2,t3,parse_bad
 lw t0,24(s3)
 addi t0,t0,-48
 li t1,3
 bgeu t0,t1,parse_bad
 sw t0,0(s4)
 lw t0,32(s3)
 addi t0,t0,-48
 li t1,10
 bgeu t0,t1,parse_bad
 sw t0,4(s4)
 lw t0,40(s3)
 addi t0,t0,-48
 bgeu t0,t1,parse_bad
 sw t0,8(s4)
 lw t0,48(s3)
 li t1,72
 beq t0,t1,parse_h
 li t1,86
 bne t0,t1,parse_place_invalid
 li t0,1
 j parse_orient
parse_h:
 li t0,0
parse_orient:
 sw t0,12(s4)
 jal ra,place_ship
 sw a0,16(s4)
 j place_reply
parse_place_invalid:
 li t0,3
 sw t0,16(s4)
place_reply:
 la a0,msg_place
 jal ra,putstr
 lw a0,0(s4)
 jal ra,putnum
 lw t0,16(s4)
 beqz t0,place_ok
 la a0,msg_reject
 jal ra,putstr
 lw t0,16(s4)
 li t1,1
 beq t0,t1,place_bounds
 li t1,2
 beq t0,t1,place_overlap
 la a0,msg_invalid
 j place_reason
place_bounds:
 la a0,msg_bounds
 j place_reason
place_overlap:
 la a0,msg_overlap
place_reason:
 jal ra,putstr
 li a0,4
 jal ra,queue_sound
 j parse_render
place_ok:
 la a0,msg_ok
 jal ra,putstr
 jal ra,check_start
 j parse_render
parse_fire:
 mv a0,s3
 la a1,prefix_fire
 jal ra,match_prefix
 beqz a0,parse_bad
 lw t0,24(s3)
 li t1,44
 bne t0,t1,parse_bad
 lw t0,20(s3)
 addi t0,t0,-48
 li t1,8
 bgeu t0,t1,parse_bad
 sw t0,4(s4)
 lw t0,28(s3)
 addi t0,t0,-48
 bgeu t0,t1,parse_bad
 sw t0,8(s4)
 jal ra,fire_shot
 beqz a0,parse_render
 mv s5,a0
 la a0,msg_shot_reject
 jal ra,putstr
 jal ra,emit_coords
 li t0,1
 beq s5,t0,fire_repeat
 la a0,msg_not_turn
 j fire_reason
fire_repeat:
 la a0,msg_repeat
fire_reason:
 jal ra,putstr
 j parse_render
parse_bad:
 la a0,msg_bad
 jal ra,putstr
 j parse_done
parse_render:
 jal ra,render
parse_done:
 LEAVE

# Validacion atomica: primero todas las celdas, despues escritura completa.
place_ship:
 li t0,CMD
 lw t1,0(s0)
 bnez t1,pl_invalid
 lw t1,24(t0)
 slli t1,t1,2
 add t2,s0,t1
 lw t2,20(t2)
 lw t3,0(t0)
 bne t2,t3,pl_invalid
 li t2,3
 bgeu t3,t2,pl_invalid
 li t2,4
 sub t2,t2,t3
 lw t3,4(t0)
 lw t4,8(t0)
 li t5,8
 bgeu t3,t5,pl_bounds
 bgeu t4,t5,pl_bounds
 lw t6,12(t0)
 li a0,2
 bgeu t6,a0,pl_invalid
 beqz t6,pl_horiz
 add a0,t3,t2
 li a1,32
 j pl_extent
pl_horiz:
 add a0,t4,t2
 li a1,4
pl_extent:
 bltu t5,a0,pl_bounds
 slli t3,t3,3
 add t3,t3,t4
 slli t3,t3,2
 slli t1,t1,6
 li t4,0x2000
 add t4,t4,t1
 add t4,t4,t3
 mv a2,t4
 mv a3,t2
pl_validate:
 lw a0,0(a2)
 bnez a0,pl_overlap
 add a2,a2,a1
 addi a3,a3,-1
 bnez a3,pl_validate
 lw a0,0(t0)
 addi a0,a0,1
pl_write:
 sw a0,0(t4)
 add t4,t4,a1
 addi t2,t2,-1
 bnez t2,pl_write
 lw t1,24(t0)
 slli t1,t1,2
 add t1,s0,t1
 lw t2,20(t1)
 addi t2,t2,1
 sw t2,20(t1)
 li a0,0
 ret
pl_bounds:
 li a0,1
 ret
pl_overlap:
 li a0,2
 ret
pl_invalid:
 li a0,3
 ret
check_start:
 ENTER
 lw t0,0(s0)
 bnez t0,cs_done
 lw t0,20(s0)
 lw t1,24(s0)
 li t2,3
 bne t0,t2,cs_done
 bne t1,t2,cs_done
 li t0,1
 sw t0,0(s0)
 sw zero,4(s0)
 sw zero,8(s0)
 sw zero,12(s0)
 sw t0,0x138(s1)
 la a0,msg_battle
 jal ra,putstr
 jal ra,emit_turn
cs_done:
 LEAVE

# Disparo: a0=0 valido,1 repetido,2 fuera de turno/fase.
fire_shot:
 ENTER
 li s3,CMD
 lw t0,0(s0)
 li t1,1
 bne t0,t1,fs_not_turn
 lw s4,24(s3)
 lw t0,4(s0)
 bne t0,s4,fs_not_turn
 lw t0,4(s3)
 lw t1,8(s3)
 li t2,8
 bgeu t0,t2,fs_not_turn
 bgeu t1,t2,fs_not_turn
 slli t0,t0,3
 add t0,t0,t1
 slli t0,t0,2
 xori t1,s4,1
 slli t1,t1,8
 li t2,0x2000
 add t1,t1,t2
 add s5,t1,t0
 lw s6,0(s5)
 andi t0,s6,256
 bnez t0,fs_repeat
 ori t0,s6,256
 sw t0,0(s5)
 slli s7,s4,2
 add s7,s0,s7
 lw t0,28(s7)
 addi t0,t0,1
 sw t0,28(s7)
 andi s6,s6,3
 sw zero,16(s3)
 li t0,-1
 sw t0,0(s3)
 beqz s6,fs_report
 addi s6,s6,-1
 sw s6,0(s3)
 li t0,1
 sw t0,16(s3)
 lw t0,44(s7)
 addi t0,t0,1
 sw t0,44(s7)
 xori t0,s4,1
 slli t0,t0,4
 li t1,0x2280
 add t0,t0,t1
 slli t1,s6,2
 add t0,t0,t1
 lw t1,0(t0)
 addi t1,t1,1
 sw t1,0(t0)
 li t2,4
 sub t2,t2,s6
 bne t1,t2,fs_report
 li t0,2
 sw t0,16(s3)
 lw t0,36(s7)
 addi t0,t0,1
 sw t0,36(s7)
fs_report:
 beqz s4,fs_incoming
 la a0,msg_shot
 j fs_prefix
fs_incoming:
 la a0,msg_incoming
fs_prefix:
 jal ra,putstr
 jal ra,emit_coords
 lw t0,16(s3)
 beqz t0,fs_miss_msg
 li t1,1
 beq t0,t1,fs_hit_msg
 la a0,msg_sunk
 jal ra,putstr
 lw a0,0(s3)
 jal ra,putnum
 jal ra,newline
 j fs_after_msg
fs_miss_msg:
 la a0,msg_miss
 jal ra,putstr
 j fs_after_msg
fs_hit_msg:
 la a0,msg_hit
 jal ra,putstr
fs_after_msg:
 lw t0,44(s7)
 li t1,9
 beq t0,t1,fs_win
 lw t0,16(s3)
 li a0,2
 beqz t0,fs_sound
 li a0,1
 li t1,1
 beq t0,t1,fs_sound
 li a0,3
fs_sound:
 jal ra,queue_sound
 xori t0,s4,1
 sw t0,4(s0)
 jal ra,emit_turn
 li a0,0
 j fs_exit
fs_win:
 li t0,2
 sw t0,0(s0)
 sw t0,0x138(s1)
 lw t0,52(s7)
 addi t0,t0,1
 sw t0,52(s7)
fs_score:
 jal ra,update_scores
 li a0,5
 jal ra,queue_sound
 la a0,msg_end
 jal ra,putstr
 mv a0,s4
 jal ra,emit_player
 jal ra,comma
 lw a0,28(s0)
 jal ra,putnum
 jal ra,comma
 lw a0,32(s0)
 jal ra,putnum
 jal ra,comma
 lw a0,36(s0)
 jal ra,putnum
 jal ra,comma
 lw a0,40(s0)
 jal ra,putnum
 jal ra,newline
 li a0,0
 j fs_exit
fs_repeat:
 li a0,1
 j fs_exit
fs_not_turn:
 li a0,2
fs_exit:
 LEAVE
emit_player:
 ENTER
 mv s3,a0
 li a0,80
 jal ra,putc
 addi a0,s3,49
 jal ra,putc
 LEAVE
emit_turn:
 ENTER
 la a0,msg_turn
 jal ra,putstr
 lw a0,4(s0)
 jal ra,emit_player
 jal ra,newline
 LEAVE
emit_coords:
 ENTER
 li s3,CMD
 lw a0,4(s3)
 jal ra,putnum
 jal ra,comma
 lw a0,8(s3)
 jal ra,putnum
 jal ra,comma
 LEAVE

# Vista J1: propio visible y rival oculto. Tile y*20+x, cada casilla32x32.
render:
 ENTER
 li s3,0
rd_cells:
 li t0,0x2000
 slli t1,s3,2
 add t0,t0,t1
 lw t2,0(t0)
 andi t3,t2,3
 li s4,0
 beqz t3,rd_own_fire
 li s4,1
rd_own_fire:
 andi t2,t2,256
 beqz t2,rd_own_ready
 li s4,2
 beqz t3,rd_own_ready
 li s4,3
rd_own_ready:
 srli s5,s3,3
 andi s6,s3,7
 lw t0,0(s0)
 bnez t0,rd_own_write
 lw t0,20(s0)
 li t1,3
 beq t0,t1,rd_own_write
 lw t0,8(s0)
 bne t0,s5,rd_own_write
 lw t0,12(s0)
 bne t0,s6,rd_own_write
 ori s4,s4,8
rd_own_write:
 addi t0,s5,2
 slli t1,t0,4
 slli t0,t0,2
 add t0,t0,t1
 add t0,t0,s6
 addi t0,t0,1
 slli t0,t0,2
 add t0,s2,t0
 sw s4,0(t0)
 li t0,0x2100
 slli t1,s3,2
 add t0,t0,t1
 lw t2,0(t0)
 li s4,0
 andi t0,t2,256
 beqz t0,rd_rival_ready
 li s4,2
 andi t0,t2,3
 beqz t0,rd_rival_ready
 li s4,3
rd_rival_ready:
 lw t0,0(s0)
 li t1,1
 bne t0,t1,rd_rival_write
 lw t0,4(s0)
 bnez t0,rd_rival_write
 lw t0,8(s0)
 bne t0,s5,rd_rival_write
 lw t0,12(s0)
 bne t0,s6,rd_rival_write
 ori s4,s4,8
rd_rival_write:
 addi t0,s5,2
 slli t1,t0,4
 slli t0,t0,2
 add t0,t0,t1
 add t0,t0,s6
 addi t0,t0,11
 slli t0,t0,2
 add t0,s2,t0
 sw s4,0(t0)
 addi s3,s3,1
 li t0,64
 bltu s3,t0,rd_cells
# HUD: 11: fase/orientacion; 12: tres barcos J1; 13: tres barcos J2.
 lw t0,0(s0)
 addi t0,t0,1
 sw t0,884(s2)
 lw t0,16(s0)
 addi t0,t0,1
 sw t0,888(s2)
 lw t0,4(s0)
 addi t0,t0,1
 sw t0,892(s2)
 li t0,0
rd_hud:
 lw t1,20(s0)
 sltu t1,t0,t1
 addi t1,t1,5
 # valor 6 para colocado se transforma a gris=1
 li t2,6
 bne t1,t2,rd_hud1
 li t1,1
rd_hud1:
 slli t2,t0,2
 add t2,s2,t2
 sw t1,964(t2)
 lw t1,24(s0)
 sltu t1,t0,t1
 beqz t1,rd_hud2_empty
 li t1,1
 j rd_hud2
rd_hud2_empty:
 li t1,5
rd_hud2:
 sw t1,1044(t2)
 addi t0,t0,1
 li t1,3
 bltu t0,t1,rd_hud
 LEAVE

.section .rodata
.balign 4
prefix_place: .word 80,76,65,67,69,44,0
prefix_fire: .word 70,73,82,69,44,0
msg_new: .asciz "NEW\n"
msg_bad: .asciz "ERROR,BAD_FRAME\n"
msg_place: .asciz "PLACE,"
msg_reject: .asciz ",REJECT,"
msg_ok: .asciz ",OK\n"
msg_bounds: .asciz "OUT_OF_BOUNDS\n"
msg_overlap: .asciz "OVERLAP\n"
msg_invalid: .asciz "INVALID\n"
msg_battle: .asciz "BATTLE\n"
msg_turn: .asciz "TURN,"
msg_shot: .asciz "SHOT,"
msg_incoming: .asciz "INCOMING,"
msg_shot_reject: .asciz "SHOT_REJECT,"
msg_repeat: .asciz "REPEAT\n"
msg_not_turn: .asciz "NOT_TURN\n"
msg_hit: .asciz "HIT,-\n"
msg_miss: .asciz "MISS,-\n"
msg_sunk: .asciz "SUNK,"
msg_end: .asciz "END,"
.balign 4
