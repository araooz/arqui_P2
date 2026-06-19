# Programa 1: ISA sin dependencias inmediatas
# Objetivo: probar instrucciones de ALU, inmediatos, memoria y lui sin depender del Hazard Unit.

addi x1, x0, 16       # x1 = 16
addi x2, x0, 4        # x2 = 4
lui  x3, 0x12345      # x3 = 0x12345000

nop
nop
nop

# Instrucciones tipo I sin dependencias inmediatas
addi x4,  x1, 3       # x4  = 19
slli x5,  x2, 2       # x5  = 16
xori x6,  x1, 10      # x6  = 26
srli x7,  x1, 1       # x7  = 8
srai x8,  x1, 2       # x8  = 4
ori  x9,  x2, 1       # x9  = 5
andi x10, x1, 15      # x10 = 0

nop
nop
nop

# Instrucciones tipo R sin dependencias inmediatas
add x11, x1, x2       # x11 = 20
sub x12, x1, x2       # x12 = 12
sll x13, x2, x2       # x13 = 64
xor x14, x1, x2       # x14 = 20
srl x15, x1, x2       # x15 = 1
sra x16, x1, x2       # x16 = 1
or  x17, x1, x2       # x17 = 20
and x18, x1, x2       # x18 = 0

nop
nop
nop

# Stores para verificar resultados intermedios
sw x11, 0(x0)
sw x12, 4(x0)
sw x13, 8(x0)
sw x14, 12(x0)
sw x15, 16(x0)
sw x16, 20(x0)
sw x17, 24(x0)
sw x18, 28(x0)
sw x3,  32(x0)

# Load sin dependencia inmediata
lw x19, 0(x0)

nop
nop
nop

sw x19, 36(x0)

end:
beq x0, x0, end
