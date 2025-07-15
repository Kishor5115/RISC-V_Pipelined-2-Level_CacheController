module Sign_Extend(in,imm_ext,ImmSrc);

input [31:0] in;
output [31:0] imm_ext;
input [1:0] ImmSrc;
 
assign imm_ext= (ImmSrc==2'b01)  ? {{{20{in[31]}}},{in[31:25],in[11:7]}}  :  // S type
                (ImmSrc==2'b00)  ? {{20{in[31]}},in[31:20]} :  // I type
                (ImmSrc==2'b10)  ? {{20{in[31]}},in[7],in[30:25],in[11:8]}:  // B type
                {{12{in[31]}},in[19:12],in[20],in[30:21],1'b0} ;  // j type
                

endmodule