.text
.globl _start

# rvc_coverage.s
# Programa de cobertura: prueba una vez cada instrucción comprimida implementada.
# El .mem asociado está en halfwords de 16 bits.

_start:
# Grupo 1: ALU / inmediatos
  addi x5, x0, 0
  c.addi x5, 1
  addi x6, x0, 11
  c.add x5, x6
  sw x5, 0(x0)

  addi x8, x0, 20
  addi x9, x0, 6
  c.sub x8, x9
  sw x8, 4(x0)

  addi x8, x0, 12
  addi x9, x0, 10
  c.and x8, x9
  sw x8, 8(x0)

  addi x8, x0, 12
  addi x9, x0, 10
  c.or x8, x9
  sw x8, 12(x0)

  addi x8, x0, 12
  addi x9, x0, 10
  c.xor x8, x9
  sw x8, 16(x0)

  addi x10, x0, 3
  c.slli x10, 2
  sw x10, 20(x0)

  addi x8, x0, 32
  c.srli x8, 2
  sw x8, 24(x0)

  addi x8, x0, -16
  c.srai x8, 2
  sw x8, 28(x0)

  c.lui x11, 1
  sw x11, 32(x0)

  addi x8, x0, 13
  c.andi x8, 10
  sw x8, 36(x0)

# Grupo 2: memoria
  addi x8, x0, 0
  addi x9, x0, 123
  c.sw x9, 40(x8)
  c.lw x10, 40(x8)
  sw x10, 44(x0)

  addi x2, x0, 64
  addi x11, x0, 77
  c.swsp x11, 0(x2)
  c.lwsp x12, 0(x2)
  sw x12, 48(x0)

# Grupo 3: branches
  addi x8, x0, 0
  c.beqz x8, beqz_ok
  addi x13, x0, 99
  sw x13, 100(x0)
beqz_ok:
  addi x13, x0, 1
  sw x13, 52(x0)

  addi x9, x0, 5
  c.bnez x9, bnez_ok
  addi x14, x0, 99
  sw x14, 104(x0)
bnez_ok:
  addi x14, x0, 2
  sw x14, 56(x0)

# Grupo 4: jumps
  c.j j_ok
  addi x15, x0, 99
  sw x15, 108(x0)
j_ok:
  addi x15, x0, 3
  sw x15, 60(x0)

  c.jal jal_ok
  addi x5, x0, 99
  sw x5, 112(x0)
jal_ok:
  sw x1, 68(x0)
  addi x5, x0, 4
  sw x5, 72(x0)

  c.jal setup_jr
after_jr_target:
  addi x6, x0, 5
  sw x6, 76(x0)
  c.j after_jr_done
setup_jr:
  c.jr x1
  addi x6, x0, 99
  sw x6, 116(x0)
after_jr_done:

  c.jal setup_jalr
after_jalr_target:
  sw x1, 80(x0)
  addi x7, x0, 6
  sw x7, 84(x0)
  c.j after_jalr_done
setup_jalr:
  c.jalr x1
  addi x7, x0, 99
  sw x7, 120(x0)
after_jalr_done:

end:
  beq x0, x0, end
