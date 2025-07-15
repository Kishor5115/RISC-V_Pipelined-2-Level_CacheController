`ifndef mux_v
`define mux_v
module  mux(a,b,c,sel);
input [31:0] a,b;
input sel;
output [31:0] c;
    
    assign c = sel ? b : a ;
 
endmodule

module mux_3_1(a,b,c,sel,d);
input [31:0] a,b,c;
input [1:0] sel;
output[31:0] d;
reg [31:0] y;
assign d=y;
always @(*)
    case(sel)
        2'b00 : y=a;
        2'b01 : y=b;
        2'b10 : y=c;
        default : y=31'h00000000; 
    endcase

endmodule
`endif

