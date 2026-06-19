# Programa 3: ISA test Stalling
# Objetivo: aislar el caso load-use. Los NOPs evitan que el fallo se mezcle con forwarding.

addi x1, x0, 100      # x1 = 100

nop
nop
nop

sw x1, 8(x0)          # mem[8] = 100

nop
nop
nop

# Hazard load-use intencional
lw  x2, 8(x0)         # x2 = mem[8] = 100
add x3, x2, x1        # x3 = 200; requiere stall de 1 ciclo

nop
nop
nop

sw x3, 12(x0)         # mem[12] = 200

end:
beq x0, x0, end
