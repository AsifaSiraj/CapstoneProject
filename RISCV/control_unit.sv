module control_unit (
    output logic       jump,       
    output logic       branch,
    output logic       regwrite,
    output logic       memwrite,
    output logic       alu_src,
    output logic       result_src,
    output logic       lui_sel,    
    output logic [2:0] imm_src,    
    output logic [1:0] aluop,
    input  logic [6:0] opcode
);
    always_comb begin
        // safe defaults
        jump       = 1'b0;
        branch     = 1'b0;
        regwrite   = 1'b0;
        memwrite   = 1'b0;
        alu_src    = 1'b0;
        result_src = 1'b0;
        lui_sel    = 1'b0;
        imm_src    = 3'b000;
        aluop      = 2'b00;

        case (opcode)
            7'b0110011: begin // R-type
                regwrite = 1'b1;
                aluop    = 2'b10;
            end

            7'b0000011: begin // Load (lw)
                alu_src    = 1'b1;
                result_src = 1'b1;
                imm_src    = 3'b000; // I-type
                regwrite   = 1'b1;
                aluop      = 2'b00;
            end

            7'b0100011: begin // Store (sw)
                alu_src  = 1'b1;
                imm_src  = 3'b001; // S-type
                memwrite = 1'b1;
                aluop    = 2'b00;
            end

            7'b1100011: begin // Branch (BEQ/BNE/BLT/BGE)
                imm_src = 3'b010; // B-type
                branch  = 1'b1;
                aluop   = 2'b01;
            end

            7'b0010011: begin // I-type ALU (addi, etc.)
                alu_src  = 1'b1;
                imm_src  = 3'b000; // I-type
                regwrite = 1'b1;
                aluop    = 2'b10;
            end

            7'b1101111: begin // JAL
                jump     = 1'b1;
                imm_src  = 3'b011; // J-type
                regwrite = 1'b1;   // writes pc+4 (handled in risc_v.sv)
                aluop    = 2'b00;  // ALU result unused for JAL, safe default
            end

            7'b0110111: begin // LUI
                alu_src  = 1'b1;
                imm_src  = 3'b100; // U-type
                regwrite = 1'b1;
                lui_sel  = 1'b1;   // force ALU src-A = 0
                aluop    = 2'b00;  // ADD (0 + imm_U)
            end

            default: ; // all outputs remain safe defaults
        endcase
    end
endmodule
