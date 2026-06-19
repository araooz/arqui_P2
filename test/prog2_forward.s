# Programa 2: ISA test Forwarding
# Objetivo: forzar dependencias RAW ALU-ALU y ALU-store.

addi x1, x0, 10       # x1 = 10
addi x2, x0, 20       # x2 = 20

# add depende de x1/x2 producidos por instrucciones anteriores
add x3, x1, x2        # x3 = 30

# sub depende inmediatamente de x3
sub x4, x3, x1        # x4 = 20

# store depende inmediatamente de x4
sw x4, 4(x0)          # mem[4] = 20

end:
beq x0, x0, end
