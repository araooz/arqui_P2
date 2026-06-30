# Testbenches finales

Se incluyen dos testbenches separados:

| Testbench | Uso |
|---|---|
| `testbench_e1.v` | Ejecuta las pruebas de E1: programa sin dependencias y pruebas del Hazard Unit. |
| `testbench_rvc.v` | Ejecuta las pruebas de instrucciones comprimidas y la comparación RV32I/RVC. |

Para usar uno de ellos en Vivado, debe configurarse el módulo correspondiente como **simulation top**:

```verilog
testbench_e1_final
testbench_rvc_final
```

La separación se hizo para mantener las simulaciones en el mismo contexto usado durante el informe. Como E1 y RVC se desarrollaron y analizaron como entregas separadas, correrlas con testbenches independientes ayuda a conservar los tiempos de waveform usados en las capturas y explicaciones.

## Programas incluidos

| Programa | Qué valida |
|---|---|
| `prog1_nodep.mem` | Instrucciones base RV32I sin dependencias. |
| `prog2_forward.mem` | Forwarding ante dependencias de datos. |
| `prog3_stall.mem` | Stall por dependencia load-use. |
| `prog4_flush.mem` | Flush por branch, `jal` y `jalr`. |
| `rvc_coverage.mem` | Cobertura de instrucciones comprimidas implementadas. |
| `matmul2x2_rv32i.mem` | Multiplicación de matrices 2x2 usando RV32I. |
| `matmul2x2_rvc.mem` | Multiplicación de matrices 2x2 usando instrucciones comprimidas. |
