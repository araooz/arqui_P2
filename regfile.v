module regfile(input  clk, 
               input  we3, 
               input  [ 4:0] a1, a2, a3, 
               input  [31:0] wd3, 
               output [31:0] rd1, rd2); 

  reg [31:0] rf[31:0]; 

  always @(posedge clk) begin 
    if (we3 && (a3 != 0)) rf[a3] <= wd3; 
  end
  
  assign rd1 = (a1 == 0) ? 32'b0 :
               ((we3 && (a1 == a3)) ? wd3 : rf[a1]);

  assign rd2 = (a2 == 0) ? 32'b0 :
               ((we3 && (a2 == a3)) ? wd3 : rf[a2]);
endmodule