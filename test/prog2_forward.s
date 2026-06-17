# Inicializamos dos registros
addi x1, x0, 10     # PC=0:  x1 = 10 (0xA)
addi x2, x0, 20     # PC=4:  x2 = 20 (0x14)

# Dependencia: 'add' necesita x1 y x2 (Forwarding desde WB y MEM)
add x3, x1, x2      # PC=8:  x3 = 10 + 20 = 30 (0x1E)

# Dependencia: 'sub' necesita x3 (Forwarding directo desde EX/MEM a EX)
sub x4, x3, x1      # PC=12: x4 = 30 - 10 = 20 (0x14)

# Dependencia: 'sw' necesita x4 (Forwarding hacia el dato a escribir en memoria)
sw x4, 4(x0)        # PC=16: mem[4] = 20 (0x14)

# Loop infinito para terminar
end: beq x0, x0, 0  # PC=20