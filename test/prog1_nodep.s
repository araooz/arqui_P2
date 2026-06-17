# Inicializamos dos registros
addi x1, x0, 5      # PC=0:  x1 = 5
addi x2, x0, 7      # PC=4:  x2 = 7

# Insertamos 3 NOPs para asegurar que x1 y x2 lleguen a WB antes del 'add'
nop                 # PC=8
nop                 # PC=12
nop                 # PC=16

# Ejecutamos ALU sin dependencias RAW en progreso
add x3, x1, x2      # PC=20: x3 = 5 + 7 = 12 (0xC)

# Insertamos 3 NOPs para asegurar que x3 llegue a WB antes del 'sw'
nop                 # PC=24
nop                 # PC=28
nop                 # PC=32

# Guardamos en memoria
sw x3, 0(x0)        # PC=36: mem[0] = 12 (0xC)

# Loop infinito para terminar
end: beq x0, x0, 0  # PC=40