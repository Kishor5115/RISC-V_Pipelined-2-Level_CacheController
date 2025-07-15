`include "mux_4_1.v"

module WriteBack_cycle(clk,rst,RegwriteW,ResultSrcW,ALUResultW,ReadDataW,RdW,pc_plus4W,ResultW);

input clk,rst,RegwriteW;
input [1:0] ResultSrcW ;
input [4:0] RdW ;
input [31:0] ALUResultW,ReadDataW,pc_plus4W ;
output [31:0] ResultW ;




mux_4_1 mux_write
(
    .a(ALUResultW),
    .b(ReadDataW),
    .c(pc_plus4W),
    .d(),
    .sel(ResultSrcW),
    .y(ResultW)
);


endmodule