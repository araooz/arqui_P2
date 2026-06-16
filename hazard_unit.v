module hazard_unit(input  [4:0] Rs1D, Rs2D,
                   input  [4:0] Rs1E, Rs2E,
                   input  [4:0] RdE, RdM, RdW,
                   input        RegWriteM, RegWriteW,
                   input  [1:0] ResultSrcE,
                   input        PCSrcE,
                   output       StallF, StallD,
                   output       FlushD, FlushE,
                   output reg [1:0] ForwardAE, ForwardBE);

  wire lwStall;

  always @* begin
    if ((Rs1E != 5'b0) && (Rs1E == RdM) && RegWriteM)
      ForwardAE = 2'b10;
    else if ((Rs1E != 5'b0) && (Rs1E == RdW) && RegWriteW)
      ForwardAE = 2'b01;
    else
      ForwardAE = 2'b00;

    if ((Rs2E != 5'b0) && (Rs2E == RdM) && RegWriteM)
      ForwardBE = 2'b10;
    else if ((Rs2E != 5'b0) && (Rs2E == RdW) && RegWriteW)
      ForwardBE = 2'b01;
    else
      ForwardBE = 2'b00;
  end

  assign lwStall = (ResultSrcE == 2'b01) &&
                   (RdE != 5'b0) &&
                   ((Rs1D == RdE) || (Rs2D == RdE));

  assign StallF = lwStall;
  assign StallD = lwStall;
  assign FlushD = PCSrcE;
  assign FlushE = lwStall || PCSrcE;
endmodule