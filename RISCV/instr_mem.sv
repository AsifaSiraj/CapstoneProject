module instr_mem (
    input  logic [31:0] addr,
    output logic [31:0] inst
);
    logic [7:0] mem [0:255];

    initial begin
        // Program generated/verified by the project assembler toolset.
        // 0x00: lui  x5,0x80000       ; x5 = 0x80000000 (MMIO base)
        mem[0]=8'hb7;  mem[1]=8'h02;  mem[2]=8'h00;  mem[3]=8'h80;
        // 0x04: addi x6,x0,200
        mem[4]=8'h13;  mem[5]=8'h03;  mem[6]=8'h80;  mem[7]=8'h0c;
        // 0x08: sw   x6,0(x5)         ; MMIO_TRACE = 200
        mem[8]=8'h23;  mem[9]=8'ha0;  mem[10]=8'h62; mem[11]=8'h00;
        // 0x0C: lw   x7,0(x5)         ; read MMIO_TRACE
        mem[12]=8'h83; mem[13]=8'ha3; mem[14]=8'h02; mem[15]=8'h00;
        // 0x10: addi x6,x0,100
        mem[16]=8'h13; mem[17]=8'h03; mem[18]=8'h40; mem[19]=8'h06;
        // 0x14: sw   x6,0(x0)         ; ECC RAM MEM[0] = 100
        mem[20]=8'h23; mem[21]=8'h20; mem[22]=8'h60; mem[23]=8'h00;
        // 0x18: lw   x7,0(x0)         ; ECC RAM read (single/double fault window)
        mem[24]=8'h83; mem[25]=8'h23; mem[26]=8'h00; mem[27]=8'h00;
        // 0x1C: addi x6,x0,50
        mem[28]=8'h13; mem[29]=8'h03; mem[30]=8'h20; mem[31]=8'h03;
        // 0x20: sw   x6,4(x0)         ; ECC RAM MEM[4] = 50
        mem[32]=8'h23; mem[33]=8'h22; mem[34]=8'h60; mem[35]=8'h00;
        // 0x24: lw   x7,4(x0)         ; ECC RAM read
        mem[36]=8'h83; mem[37]=8'h23; mem[38]=8'h40; mem[39]=8'h00;
        // 0x28: addi x6,x0,8          ; PWM period
        mem[40]=8'h13; mem[41]=8'h03; mem[42]=8'h80; mem[43]=8'h00;
        // 0x2C: sw   x6,0x14(x5)      ; PWM_PERIOD = 8
        mem[44]=8'h23; mem[45]=8'haa; mem[46]=8'h62; mem[47]=8'h00;
        // 0x30: addi x6,x0,3          ; PWM duty
        mem[48]=8'h13; mem[49]=8'h03; mem[50]=8'h30; mem[51]=8'h00;
        // 0x34: sw   x6,0x18(x5)      ; PWM_DUTY = 3
        mem[52]=8'h23; mem[53]=8'hac; mem[54]=8'h62; mem[55]=8'h00;
        // 0x38: addi x6,x0,1
        mem[56]=8'h13; mem[57]=8'h03; mem[58]=8'h10; mem[59]=8'h00;
        // 0x3C: sw   x6,0x1C(x5)      ; PWM_CTRL.EN = 1
        mem[60]=8'h23; mem[61]=8'hae; mem[62]=8'h62; mem[63]=8'h00;
        // 0x40: addi x6,x0,1
        mem[64]=8'h13; mem[65]=8'h03; mem[66]=8'h10; mem[67]=8'h00;
        // 0x44: sw   x6,0x20(x5)      ; RPM_CTRL.EN = 1 (early -> period settles)
        mem[68]=8'h23; mem[69]=8'ha0; mem[70]=8'h62; mem[71]=8'h02;
        // 0x48: addi x6,x0,0xAA       ; SPI TX byte
        mem[72]=8'h13; mem[73]=8'h03; mem[74]=8'ha0; mem[75]=8'h0a;
        // 0x4C: sw   x6,0x04(x5)      ; SPI_TXD = 0xAA
        mem[76]=8'h23; mem[77]=8'ha2; mem[78]=8'h62; mem[79]=8'h00;
        // 0x50: addi x6,x0,1
        mem[80]=8'h13; mem[81]=8'h03; mem[82]=8'h10; mem[83]=8'h00;
        // 0x54: sw   x6,0x08(x5)      ; SPI_CTRL.START
        mem[84]=8'h23; mem[85]=8'ha4; mem[86]=8'h62; mem[87]=8'h00;
        // 0x58: lw   x7,0x0C(x5)      ; SPI_STAT (poll)
        mem[88]=8'h83; mem[89]=8'ha3; mem[90]=8'hc2; mem[91]=8'h00;
        // 0x5C: addi x8,x0,2
        mem[92]=8'h13; mem[93]=8'h04; mem[94]=8'h20; mem[95]=8'h00;
        // 0x60: and  x7,x7,x8         ; mask DONE
        mem[96]=8'hb3; mem[97]=8'hf3; mem[98]=8'h83; mem[99]=8'h00;
        // 0x64: beq  x7,x0,-12        ; loop while DONE==0
        mem[100]=8'he3; mem[101]=8'h8a; mem[102]=8'h03; mem[103]=8'hfe;
        // 0x68: lw   x8,0x10(x5)      ; SPI_RXD (==0xAA loopback)
        mem[104]=8'h03; mem[105]=8'ha4; mem[106]=8'h02; mem[107]=8'h01;
        // 0x6C-0xA8: profile = {1,2,...,8}
        mem[108]=8'h13; mem[109]=8'h03; mem[110]=8'h10; mem[111]=8'h00;
        mem[112]=8'h23; mem[113]=8'ha8; mem[114]=8'h62; mem[115]=8'h02;
        mem[116]=8'h13; mem[117]=8'h03; mem[118]=8'h20; mem[119]=8'h00;
        mem[120]=8'h23; mem[121]=8'haa; mem[122]=8'h62; mem[123]=8'h02;
        mem[124]=8'h13; mem[125]=8'h03; mem[126]=8'h30; mem[127]=8'h00;
        mem[128]=8'h23; mem[129]=8'hac; mem[130]=8'h62; mem[131]=8'h02;
        mem[132]=8'h13; mem[133]=8'h03; mem[134]=8'h40; mem[135]=8'h00;
        mem[136]=8'h23; mem[137]=8'hae; mem[138]=8'h62; mem[139]=8'h02;
        mem[140]=8'h13; mem[141]=8'h03; mem[142]=8'h50; mem[143]=8'h00;
        mem[144]=8'h23; mem[145]=8'ha0; mem[146]=8'h62; mem[147]=8'h04;
        mem[148]=8'h13; mem[149]=8'h03; mem[150]=8'h60; mem[151]=8'h00;
        mem[152]=8'h23; mem[153]=8'ha2; mem[154]=8'h62; mem[155]=8'h04;
        mem[156]=8'h13; mem[157]=8'h03; mem[158]=8'h70; mem[159]=8'h00;
        mem[160]=8'h23; mem[161]=8'ha4; mem[162]=8'h62; mem[163]=8'h04;
        mem[164]=8'h13; mem[165]=8'h03; mem[166]=8'h80; mem[167]=8'h00;
        mem[168]=8'h23; mem[169]=8'ha6; mem[170]=8'h62; mem[171]=8'h04;
        // 0xAC: addi x6,x0,1
        mem[172]=8'h13; mem[173]=8'h03; mem[174]=8'h10; mem[175]=8'h00;
        // 0xB0: sw   x6,0x2C(x5)      ; PROFILE_CTRL.LOAD
        mem[176]=8'h23; mem[177]=8'ha6; mem[178]=8'h62; mem[179]=8'h02;
        // 0xB4: lw   x7,0x50(x5)      ; PROFILE_STAT (LOADED=1)
        mem[180]=8'h83; mem[181]=8'ha3; mem[182]=8'h02; mem[183]=8'h05;
        // 0xB8: lw   x7,0x28(x5)      ; RPM_STAT (poll)
        mem[184]=8'h83; mem[185]=8'ha3; mem[186]=8'h82; mem[187]=8'h02;
        // 0xBC: addi x8,x0,1
        mem[188]=8'h13; mem[189]=8'h04; mem[190]=8'h10; mem[191]=8'h00;
        // 0xC0: and  x7,x7,x8         ; mask VALID
        mem[192]=8'hb3; mem[193]=8'hf3; mem[194]=8'h83; mem[195]=8'h00;
        // 0xC4: beq  x7,x0,-12        ; loop while VALID==0
        mem[196]=8'he3; mem[197]=8'h8a; mem[198]=8'h03; mem[199]=8'hfe;
        // 0xC8: lw   x8,0x24(x5)      ; RPM_PERIOD
        mem[200]=8'h03; mem[201]=8'ha4; mem[202]=8'h42; mem[203]=8'h02;
        // 0xCC: addi x6,x0,1
        mem[204]=8'h13; mem[205]=8'h03; mem[206]=8'h10; mem[207]=8'h00;
        // 0xD0: sw   x6,0x54(x5)      ; FS_CTRL.WDT_EN = 1
        mem[208]=8'h23; mem[209]=8'haa; mem[210]=8'h62; mem[211]=8'h04;
        // 0xD4: lw   x7,0x58(x5)      ; FS_STAT
        mem[212]=8'h83; mem[213]=8'ha3; mem[214]=8'h82; mem[215]=8'h05;
        // 0xD8: beq x0,x0,0           ; halt loop
        mem[216]=8'h63; mem[217]=8'h00; mem[218]=8'h00; mem[219]=8'h00;
    end

    always_comb
        inst = {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]};
endmodule