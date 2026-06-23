.text
.align 2
.globl _start

_start:
    # --- INICIALIZACIÓN (Instrucciones de 32 bits) ---
    addi x8, x0, 10       # x8 = 10 (32 bits)
    addi x9, x0, 20       # x9 = 20 (32 bits)

    # --- PRUEBAS ARITMÉTICAS (16 bits) ---
    c.addi x8, 5          # x8 = x8 + 5  => x8 = 15
    c.add  x8, x9         # x8 = x8 + x9 => x8 = 35

    addi x10, x0, 5       # x10 = 5 (32 bits)
    c.sub  x8, x10        # x8 = x8 - x10 => x8 = 30 (Usa rs1', rs2')

    # --- PRUEBAS LÓGICAS (16 bits) ---
    addi x11, x0, 31      # x11 = 31 [0x1F] (32 bits)
    c.and  x8, x11        # x8 = 30 & 31 => x8 = 30 

    addi x12, x0, 1       # x12 = 1 (32 bits)
    c.or   x8, x12        # x8 = 30 | 1  => x8 = 31

    addi x13, x0, 15      # x13 = 15 [0x0F] (32 bits)
    c.xor  x8, x13        # x8 = 31 ^ 15 => x8 = 16

    # --- PRUEBAS DE DESPLAZAMIENTO Y LUI (16 bits) ---
    c.slli x8, 2          # x8 = 16 << 2 => x8 = 64
    c.srli x8, 1          # x8 = 64 >> 1 => x8 = 32 (Despl. lógico)
    c.srai x8, 2          # x8 = 32 >> 2 => x8 = 8  (Despl. aritmético)

    c.lui  x14, 4         # x14 = 4 << 12 => x14 = 16384 [0x4000]

fin_p1:
    addi x0, x0, 0        # NOP (32 bits)