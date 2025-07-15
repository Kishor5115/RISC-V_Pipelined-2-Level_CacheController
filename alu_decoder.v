module alu_decoder(
    input [1:0] ALUop,
    input op5,
    input [2:0] funct3,
    input [6:0] funct7,
    output reg [3:0] ALUControl
);
    always @(*) begin
        case(ALUop)
            2'b00: // Load/Store/JALR - Always add
                ALUControl = 4'b0000; // ADD
            
            2'b01: // Branch instructions
                case(funct3)
                    3'b000: ALUControl = 4'b0001; // BEQ (SUB)
                    3'b001: ALUControl = 4'b0001; // BNE (SUB)
                    3'b100: ALUControl = 4'b0101; // BLT (SLT)
                    3'b101: ALUControl = 4'b0101; // BGE (SLT)
                    3'b110: ALUControl = 4'b0111; // BLTU (SLTU)
                    3'b111: ALUControl = 4'b0111; // BGEU (SLTU)
                    default: ALUControl = 4'b0000;
                endcase
            
            2'b10: // R-type and I-type ALU operations
                case(funct3)
                    3'b000: // ADD/SUB/ADDI
                        if (funct7[5] & op5) 
                            ALUControl = 4'b0001; // SUB
                        else 
                            ALUControl = 4'b0000; // ADD
                    
                    3'b001: ALUControl = 4'b1000; // SLL/SLLI - Shift Left Logical
                    3'b010: ALUControl = 4'b0101; // SLT/SLTI
                    3'b011: ALUControl = 4'b0111; // SLTU/SLTIU
                    3'b100: ALUControl = (funct7 == 7'b0000001) ? 4'b1110 : 4'b0000; // TZCNT or default
                    3'b101: // SRL/SRA/SRLI/SRAI
                        if (funct7[5])
                            ALUControl = 4'b1001; // SRA/SRAI - Shift Right Arithmetic
                        else
                            ALUControl = 4'b1010; // SRL/SRLI - Shift Right Logical
                    3'b110: ALUControl = 4'b0011; // OR/ORI
                    3'b111: ALUControl = 4'b0010; // AND/ANDI
                    default: ALUControl = 4'b0000;
                endcase
            
            2'b11: // LUI
                ALUControl = 4'b1011; // Pass immediate
            
            default: ALUControl = 4'b0000;
        endcase
    end
endmodule