# Programa 4: ISA test Flushing
# Objetivo: probar flush por branch, jal y jalr.
# Los NOPs antes de los saltos evitan mezclar esta prueba con dependencias RAW.

addi x1, x0, 5        # x1 = 5
addi x2, x0, 5        # x2 = 5
addi x3, x0, 0        # x3 debe quedarse en 0 si el flush funciona

nop
nop
nop

beq x1, x2, branch_target
addi x3, x0, 99       # camino incorrecto
addi x3, x0, 100      # camino incorrecto

branch_target:
add x4, x1, x2        # x4 = 10

nop
nop
nop

sw x4, 16(x0)         # mem[16] = 10
sw x3, 20(x0)         # mem[20] = 0 si el flush funciono

jal x6, jal_target
addi x5, x0, 99       # camino incorrecto

jal_target:
addi x5, x0, 7        # x5 = 7

nop
nop
nop

sw x5, 24(x0)         # mem[24] = 7
sw x6, 28(x0)         # x6 = PC+4 del jal

addi x7, x0, 120      # direccion de jalr_target

nop
nop
nop

jalr x8, 0(x7)
addi x9, x0, 99       # camino incorrecto
addi x9, x0, 100      # camino incorrecto

jalr_target:
addi x9, x0, 8        # x9 = 8

nop
nop
nop

sw x9, 32(x0)         # mem[32] = 8
sw x8, 36(x0)         # x8 = PC+4 del jalr

end:
beq x0, x0, end
