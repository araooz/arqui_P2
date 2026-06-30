# Proyecto 2 - Testbenches finales

Este paquete incluye dos testbenches separados para la entrega final.

## Archivos

- `testbench_e1_final.v`
- `testbench_rvc_final.v`

Ambos instancian el módulo `top` con los puertos:

```verilog
.clk(clk),
.reset(reset),
.WriteData(WriteData),
.DataAdr(DataAdr),
.MemWrite(MemWrite)
```

Los nombres de los módulos de testbench son distintos para evitar conflictos si ambos archivos están en el proyecto al mismo tiempo:

```verilog
module testbench_e1_final();
module testbench_rvc_final();
```

En Vivado, seleccionar explícitamente cuál será el simulation top antes de correr la simulación.

## Testbench E1

`testbench_e1_final.v` ejecuta:

1. `prog1_nodep.mem`
2. `prog2_forward.mem`
3. `prog3_stall.mem`
4. `prog4_flush.mem`

Validaciones principales:

| Programa | Validación |
|---|---|
| `prog1_nodep.mem` | Stores esperados para instrucciones base sin dependencias |
| `prog2_forward.mem` | `mem[4] = 0x00000014` |
| `prog3_stall.mem` | `mem[12] = 0x000000c8` |
| `prog4_flush.mem` | `mem[20] = 0x00000000` |

Para `prog3_stall.mem`, el testbench inicializa:

```verilog
dut.dmem.RAM[2] = 32'd100;
```

Esto corresponde a la palabra en la dirección byte 8, usada por el `lw` del caso load-use. Si el programa también escribe explícitamente en `mem[8]`, el testbench lo registra como store opcional.

## Testbench RVC

`testbench_rvc_final.v` ejecuta:

1. `rvc_coverage.mem`
2. `matmul2x2_rv32i.mem`
3. `matmul2x2_rvc.mem`

Validaciones principales:

| Programa | Validación |
|---|---|
| `rvc_coverage.mem` | Cobertura de instrucciones comprimidas |
| `matmul2x2_rv32i.mem` | Multiplicación de matrices 2x2 en RV32I |
| `matmul2x2_rvc.mem` | Multiplicación de matrices 2x2 en RVC |

Resultado esperado del algoritmo:

```text
mem[32] = 19
mem[36] = 22
mem[40] = 43
mem[44] = 50
```

El testbench imprime el tiempo de cada store validado. Esto sirve para respaldar los rangos temporales usados en las capturas de waveform del informe.

## Formato de archivos .mem

La versión final del procesador usa una instruction memory organizada en halfwords de 16 bits.

Por lo tanto, todos los archivos `.mem` usados con estos testbenches deben estar en formato halfword:

```text
una línea = 16 bits = 4 dígitos hexadecimales
```

Una instrucción comprimida de 16 bits ocupa una línea.

Una instrucción RV32I de 32 bits ocupa dos líneas:

```text
halfword bajo primero
halfword alto después
```

Ejemplo:

```text
addi x1, x0, 5 = 0x00500093
```

Debe escribirse como:

```text
0093
0050
```

No usar archivos `.mem` antiguos de 32 bits directamente con la instruction memory final en halfwords.

## Nota sobre tiempos de waveform

`testbench_rvc_final.v` mantiene el orden usado para las capturas de RVC:

1. coverage
2. matmul RV32I
3. matmul RVC

No agregar programas antes de `rvc_coverage.mem` si se desea conservar los tiempos absolutos usados en el informe.

El store final de `matmul2x2_rvc.mem` debe ocurrir al final de la tercera fase, con:

```text
phase     = 3
MemWrite  = 1
DataAdr   = 0x0000002c
WriteData = 0x00000032
```

## Jerarquía usada por los testbenches

Los testbenches limpian memoria y registros usando estas rutas jerárquicas:

```verilog
dut.imem.RAM
dut.dmem.RAM
dut.rvpipe.dp.rf.rf
```

Si en la implementación local los nombres de instancia son distintos, actualizar esas rutas en las tareas `clear_state`.
