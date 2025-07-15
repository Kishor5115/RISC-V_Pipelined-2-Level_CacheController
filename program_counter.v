module P_C(PCNext, PC, rst, clk, en);

input [31:0] PCNext;
input clk, rst;
input en;  // Added: Enable signal to control PC updates
output reg [31:0] PC;

always @(posedge clk)       
begin                    
    if(!rst)   
        PC <= 32'h00000000;
    else if(en)  // Only update PC when enabled
        PC <= PCNext;
    // If en is low, PC holds its current value
end

endmodule