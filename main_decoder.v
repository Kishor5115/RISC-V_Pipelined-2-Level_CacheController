module main_decoder(op, Zero, RegWrite, Memwrite, ResultSrc, branch, Jump, ALUSrc, ImmSrc, ALUop, PCSrc);
input [6:0] op;
input Zero;
output RegWrite, Memwrite, ALUSrc, PCSrc, branch, Jump;
output [1:0] ImmSrc, ResultSrc, ALUop;

assign RegWrite = (op == 7'b0110011) || // R-type arithmetic
                 (op == 7'b0010011) || // I-type arithmetic (addi, etc.)
                 (op == 7'b0000011) || // Load instructions
                 (op == 7'b1101111) || // JAL
                 (op == 7'b1100111) ||   // JALR\
                 (op == 7'b0111011) ; // CLZ (custom)

assign Memwrite = (op == 7'b0100011);  // Store instructions

assign ResultSrc = (op == 7'b0000011) ? 2'b01 : // Load
                   (op == 7'b1101111) ? 2'b10 : // JAL
                   (op == 7'b1100111) ? 2'b10 : // JALR
                   2'b00;

assign ALUSrc = (op == 7'b0000011) || // Load
                (op == 7'b0100011) || // Store
                (op == 7'b0010011);   // I-type arithmetic

assign branch = (op == 7'b1100011);   // Branch instructions

assign Jump = (op == 7'b1101111) ||   // JAL
              (op == 7'b1100111);     // JALR

assign ImmSrc = (op == 7'b0100011) ? 2'b01 : // Store
                (op == 7'b1100011) ? 2'b10 : // Branch
                (op == 7'b1101111) ? 2'b11 : // JAL
                (op == 7'b1100111) ? 2'b00 : // JALR
                2'b00;

assign ALUop = (op == 7'b0110011) ? 2'b10 : // R-type
               (op == 7'b0010011) ? 2'b10 : // I-type arithmetic
               (op == 7'b0000011) ? 2'b00 : // Load
               (op == 7'b0100011) ? 2'b00 : // Store
               (op == 7'b1100011) ? 2'b01 : // Branch
               (op == 7'b0111011) ? 2'b10 : // CLZ
               2'b00;

assign PCSrc = (Zero & branch) | Jump;

endmodule