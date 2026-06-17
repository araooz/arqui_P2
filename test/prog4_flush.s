# Preparamos registros para la comparación
addi x1, x0, 5      # PC=0:  x1 = 5
addi x2, x0, 5      # PC=4:  x2 = 5

# Salto condicional: Como 5 == 5, saltará 12 bytes adelante (PC = 8 + 12 = 20)
beq x1, x2, 12      # PC=8:  Branch Taken! (PCSrcE = 1, FlushD = 1, FlushE = 1)

# --- INSTRUCCIONES BASURA (Deben ser limpiadas por el Flush) ---
addi x3, x0, 99     # PC=12: x3 = 99 (Se convierte en NOP)
addi x3, x0, 100    # PC=16: x3 = 100 (Se convierte en NOP)

# --- TARGET DEL BRANCH ---
add x4, x1, x2      # PC=20: x4 = 5 + 5 = 10 (0xA)

# Guardamos el resultado (verás que mem[16] es 10, y x3 nunca fue 99 ni 100)
sw x4, 16(x0)       # PC=24: mem[16] = 10

# Loop infinito para terminar
end: beq x0, x0, 0  # PC=28