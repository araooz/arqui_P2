.text
.globl _start

# matmul2x2_rvc.s
# Multiplicación de matrices 2x2 usando instrucciones RVC donde es posible.
# El .mem asociado está en halfwords de 16 bits.
# Resultado esperado: mem[32]=19, mem[36]=22, mem[40]=43, mem[44]=50.

_start:
  addi x8, x0, 0
  addi x9, x0, 16
  addi x10, x0, 32

  addi x11, x0, 1
  c.sw x11, 0(x8)
  addi x11, x0, 2
  c.sw x11, 4(x8)
  addi x11, x0, 3
  c.sw x11, 8(x8)
  addi x11, x0, 4
  c.sw x11, 12(x8)

  addi x11, x0, 5
  c.sw x11, 0(x9)
  addi x11, x0, 6
  c.sw x11, 4(x9)
  addi x11, x0, 7
  c.sw x11, 8(x9)
  addi x11, x0, 8
  c.sw x11, 12(x9)

  c.lw x12, 0(x8)
  c.lw x13, 0(x9)
  c.jal mul_rep_rvc
  addi x15, x14, 0
  c.lw x12, 4(x8)
  c.lw x13, 8(x9)
  c.jal mul_rep_rvc
  c.add x15, x14
  c.sw x15, 0(x10)

  c.lw x12, 0(x8)
  c.lw x13, 4(x9)
  c.jal mul_rep_rvc
  addi x15, x14, 0
  c.lw x12, 4(x8)
  c.lw x13, 12(x9)
  c.jal mul_rep_rvc
  c.add x15, x14
  c.sw x15, 4(x10)

  c.lw x12, 8(x8)
  c.lw x13, 0(x9)
  c.jal mul_rep_rvc
  addi x15, x14, 0
  c.lw x12, 12(x8)
  c.lw x13, 8(x9)
  c.jal mul_rep_rvc
  c.add x15, x14
  c.sw x15, 8(x10)

  c.lw x12, 8(x8)
  c.lw x13, 4(x9)
  c.jal mul_rep_rvc
  addi x15, x14, 0
  c.lw x12, 12(x8)
  c.lw x13, 12(x9)
  c.jal mul_rep_rvc
  c.add x15, x14
  c.sw x15, 12(x10)

end:
  c.j end

mul_rep_rvc:
  addi x14, x0, 0
mul_loop_rvc:
  c.beqz x13, mul_done_rvc
  c.add x14, x12
  c.addi x13, -1
  c.j mul_loop_rvc
mul_done_rvc:
  c.jr x1
