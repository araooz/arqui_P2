.text
.globl _start

# matmul2x2_rv32i.s
# Multiplicación de matrices 2x2 usando solo RV32I.
# El .mem asociado está en halfwords de 16 bits.
# Resultado esperado: mem[32]=19, mem[36]=22, mem[40]=43, mem[44]=50.

_start:
  addi x5, x0, 0
  addi x6, x0, 16
  addi x7, x0, 32

  addi x8, x0, 1
  sw x8, 0(x5)
  addi x8, x0, 2
  sw x8, 4(x5)
  addi x8, x0, 3
  sw x8, 8(x5)
  addi x8, x0, 4
  sw x8, 12(x5)

  addi x8, x0, 5
  sw x8, 0(x6)
  addi x8, x0, 6
  sw x8, 4(x6)
  addi x8, x0, 7
  sw x8, 8(x6)
  addi x8, x0, 8
  sw x8, 12(x6)

  lw x10, 0(x5)
  lw x11, 0(x6)
  jal x1, mul_rep
  add x13, x12, x0
  lw x10, 4(x5)
  lw x11, 8(x6)
  jal x1, mul_rep
  add x13, x13, x12
  sw x13, 0(x7)

  lw x10, 0(x5)
  lw x11, 4(x6)
  jal x1, mul_rep
  add x13, x12, x0
  lw x10, 4(x5)
  lw x11, 12(x6)
  jal x1, mul_rep
  add x13, x13, x12
  sw x13, 4(x7)

  lw x10, 8(x5)
  lw x11, 0(x6)
  jal x1, mul_rep
  add x13, x12, x0
  lw x10, 12(x5)
  lw x11, 8(x6)
  jal x1, mul_rep
  add x13, x13, x12
  sw x13, 8(x7)

  lw x10, 8(x5)
  lw x11, 4(x6)
  jal x1, mul_rep
  add x13, x12, x0
  lw x10, 12(x5)
  lw x11, 12(x6)
  jal x1, mul_rep
  add x13, x13, x12
  sw x13, 12(x7)

end:
  beq x0, x0, end

mul_rep:
  addi x12, x0, 0
mul_loop:
  beq x11, x0, mul_done
  add x12, x12, x10
  addi x11, x11, -1
  jal x0, mul_loop
mul_done:
  jalr x0, 0(x1)
