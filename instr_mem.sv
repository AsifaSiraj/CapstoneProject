module instr_mem (
    input  logic [31:0] addr,
    output logic [31:0] inst
);
    logic [7:0] mem [0:63];

    initial begin
       
        // 0x00: addi x5,x0,0        -> 0x00000293
        mem[0]=8'h93;  mem[1]=8'h02;  mem[2]=8'h00;  mem[3]=8'h00;
        // 0x04: addi x6,x0,100      -> 0x06400313
        mem[4]=8'h13;  mem[5]=8'h03;  mem[6]=8'h40;  mem[7]=8'h06;
        // 0x08: sw   x6,0(x5)       -> 0x0062A023
        mem[8]=8'h23;  mem[9]=8'hA0;  mem[10]=8'h62; mem[11]=8'h00;
        // 0x0C: lw   x7,0(x5)       -> 0x0002A383
        mem[12]=8'h83; mem[13]=8'hA3; mem[14]=8'h02; mem[15]=8'h00;
        // 0x10: addi x5,x0,4        -> 0x00400293
        mem[16]=8'h93; mem[17]=8'h02; mem[18]=8'h40; mem[19]=8'h00;
        // 0x14: addi x6,x0,200      -> 0x0C800313
        mem[20]=8'h13; mem[21]=8'h03; mem[22]=8'h80; mem[23]=8'h0C;
        // 0x18: sw   x6,0(x5)       -> 0x0062A023
        mem[24]=8'h23; mem[25]=8'hA0; mem[26]=8'h62; mem[27]=8'h00;
        // 0x1C: lw   x7,0(x5)       -> 0x0002A383
        mem[28]=8'h83; mem[29]=8'hA3; mem[30]=8'h02; mem[31]=8'h00;

        // ----  LUI test ----
        // 0x20: lui x8, 0x12345     -> 0x12345437  (x8 = 0x12345000)
        mem[32]=8'h37; mem[33]=8'h54; mem[34]=8'h34; mem[35]=8'h12;

        // ----  JAL test (jumps forward, skipping next instruction) ----
        // 0x24: jal x9, 8           -> 0x008004EF  (x9 = pc+4 = 0x28; jump to 0x2C)
        mem[36]=8'hEF; mem[37]=8'h04; mem[38]=8'h80; mem[39]=8'h00;

        // 0x28: addi x10,x0,999     -> 0x3E700513  (MUST BE SKIPPED if JAL works)
        mem[40]=8'h13; mem[41]=8'h05; mem[42]=8'h70; mem[43]=8'h3E;

        // ----  MMIO test (jump target lands here) ----
        // 0x2C: lui x11, 0x80000    -> 0x800005B7  (x11 = 0x80000000, MMIO base)
        mem[44]=8'hB7; mem[45]=8'h05; mem[46]=8'h00; mem[47]=8'h80;
        // 0x30: sw x6,0(x11)        -> 0x0065A023  (write 200 to peripheral_reg_out)
        mem[48]=8'h23; mem[49]=8'hA0; mem[50]=8'h65; mem[51]=8'h00;
        // 0x34: lw x12,0(x11)       -> 0x0005A603  (read back from peripheral_reg_out)
        mem[52]=8'h03; mem[53]=8'hA6; mem[54]=8'h05; mem[55]=8'h00;

        // 0x38: beq x0,x0,0 (halt loop) -> 0x00000063
        mem[56]=8'h63; mem[57]=8'h00; mem[58]=8'h00; mem[59]=8'h00;
    end

    always_comb
        inst = {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]};
endmodule
