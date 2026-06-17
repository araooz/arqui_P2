# Preparamos un dato en la memoria
addi x1, x0, 100    # PC=0:  x1 = 100 (0x64)
sw x1, 8(x0)        # PC=4:  mem[8] = 100

# Cargamos el dato y lo usamos INMEDIATAMENTE (provoca Stall de 1 ciclo)
lw x2, 8(x0)        # PC=8:  x2 = mem[8] = 100
add x3, x2, x1      # PC=12: x3 = 100 + 100 = 200 (0xC8). STALL OCURRE AQUÍ.

# Guardamos el resultado para verificarlo
sw x3, 12(x0)       # PC=16: mem[12] = 200 (0xC8)

# Loop infinito para terminar
end: beq x0, x0, 0  # PC=20