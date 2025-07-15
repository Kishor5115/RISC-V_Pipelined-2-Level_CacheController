module mux_4_1(a,b,c,d,sel,y);

input [31:0] a,b,c,d ;
input [1:0] sel ;
output [31:0] y ;
reg [31:0] mux_out ;

assign y = mux_out ;
always @(*)
    case(sel)
        2'b00 : mux_out=a ;
        2'b01 : mux_out=b ;
        2'b10 : mux_out=c ;
        2'b11 : mux_out=d ;
        default : mux_out=0;

    endcase
endmodule