.text
.align 2
.globl _start

_start:
    # --- INICIALIZACIÓN DE PUNTEROS (Instrucciones de 32 bits) ---
    addi x2, x0, 256      # x2 (sp) = 256 (32 bits)
    addi x8, x0, 128      # x8 (puntero base) = 128 (32 bits)
    addi x9, x0, 42       # x9 (dato a guardar) = 42 (32 bits)
    addi x15, x0, 0       # x15 = 0 (usado para probar beqz) (32 bits)

    # --- PRUEBAS DE MEMORIA COMPRIMIDA (16 bits) ---
    c.sw   x9, 4(x8)      # Memoria[128 + 4] = 42 (Usa rs1', rs2')
    c.lw   x10, 4(x8)     # x10 = Memoria[132] => x10 = 42
    
    c.swsp x10, 8(x2)     # Memoria[256 + 8] = 42 (Usa SP explícito)
    c.lwsp x11, 8(x2)     # x11 = Memoria[264] => x11 = 42

    # --- PRUEBAS DE BRANCHES (16 bits) ---
    c.beqz x15, salto_1   # x15 == 0, por lo tanto DEBE SALTAR
    addi   x11, x0, 99    # INSTRUCCIÓN TRAMPA (32 bits): No debe ejecutarse
salto_1:
    c.bnez x11, salto_2   # x11 == 42 (!= 0), por lo tanto DEBE SALTAR
    addi   x11, x0, 99    # INSTRUCCIÓN TRAMPA (32 bits): No debe ejecutarse
salto_2:

    # --- PRUEBAS DE JUMPS INCONDICIONALES (16 bits) ---
    c.j    salto_3        # Salto incondicional relativo
    addi   x11, x0, 99    # INSTRUCCIÓN TRAMPA (32 bits)
salto_3:

    c.jal  salto_4        # Salta y guarda PC de retorno en x1 (ra)
    # Al retornar, el flujo debe caer aquí:
    c.j    prueba_jalr    # Saltamos al final para no hacer un bucle infinito
    
salto_4:
    c.jr   x1             # Jump Register: Retorna a la dirección en x1

prueba_jalr:
    # Para probar jalr necesitamos cargar una dirección en un registro (32 bits)
    la     x14, fin_p2    # Pseudo-instrucción: se expande a auipc + addi (32 bits)
    c.jalr x14            # Jump and Link Register hacia fin_p2, guarda retorno en x1
    
    addi   x11, x0, 99    # INSTRUCCIÓN TRAMPA (32 bits)

fin_p2:
    addi x0, x0, 0        # NOP (32 bits)