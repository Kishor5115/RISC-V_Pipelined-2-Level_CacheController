module  instr_Mem(A,rst,Instr);
input [31:0] A;
input rst;
output  [31:0] Instr;
 
reg [31:0]  Mem [0:100000];    //  Creating memory to store instructions

assign Instr = (!rst) ?   32'h00000000    :   Mem[A[31:2]];    //  read data

initial
begin
$readmemh("instr_mem_file.hex",Mem);
end

endmodule