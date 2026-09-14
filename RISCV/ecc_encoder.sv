module ecc_encoder (
    input  logic [31:0] data_in,
    output logic [38:0] codeword   // [37:0]=Hamming(38) bits, [38]=overall parity
);
    logic p1, p2, p4, p8, p16, p32;

    always_comb begin
        p1  = data_in[0]^data_in[1]^data_in[3]^data_in[4]^data_in[6]^data_in[8]^
              data_in[10]^data_in[11]^data_in[13]^data_in[15]^data_in[17]^data_in[19]^
              data_in[21]^data_in[23]^data_in[25]^data_in[26]^data_in[28]^data_in[30];

        p2  = data_in[0]^data_in[2]^data_in[3]^data_in[5]^data_in[6]^data_in[9]^
              data_in[10]^data_in[12]^data_in[13]^data_in[16]^data_in[17]^data_in[20]^
              data_in[21]^data_in[24]^data_in[25]^data_in[27]^data_in[28]^data_in[31];

        p4  = data_in[1]^data_in[2]^data_in[3]^data_in[7]^data_in[8]^data_in[9]^
              data_in[10]^data_in[14]^data_in[15]^data_in[16]^data_in[17]^data_in[22]^
              data_in[23]^data_in[24]^data_in[25]^data_in[29]^data_in[30]^data_in[31];

        p8  = data_in[4]^data_in[5]^data_in[6]^data_in[7]^data_in[8]^data_in[9]^
              data_in[10]^data_in[18]^data_in[19]^data_in[20]^data_in[21]^data_in[22]^
              data_in[23]^data_in[24]^data_in[25];

        p16 = data_in[11]^data_in[12]^data_in[13]^data_in[14]^data_in[15]^data_in[16]^
              data_in[17]^data_in[18]^data_in[19]^data_in[20]^data_in[21]^data_in[22]^
              data_in[23]^data_in[24]^data_in[25];

        p32 = data_in[26]^data_in[27]^data_in[28]^data_in[29]^data_in[30]^data_in[31];

        codeword[0]  = p1;          codeword[1]  = p2;
        codeword[2]  = data_in[0];  codeword[3]  = p4;
        codeword[4]  = data_in[1];  codeword[5]  = data_in[2];
        codeword[6]  = data_in[3];  codeword[7]  = p8;
        codeword[8]  = data_in[4];  codeword[9]  = data_in[5];
        codeword[10] = data_in[6];  codeword[11] = data_in[7];
        codeword[12] = data_in[8];  codeword[13] = data_in[9];
        codeword[14] = data_in[10]; codeword[15] = p16;
        codeword[16] = data_in[11]; codeword[17] = data_in[12];
        codeword[18] = data_in[13]; codeword[19] = data_in[14];
        codeword[20] = data_in[15]; codeword[21] = data_in[16];
        codeword[22] = data_in[17]; codeword[23] = data_in[18];
        codeword[24] = data_in[19]; codeword[25] = data_in[20];
        codeword[26] = data_in[21]; codeword[27] = data_in[22];
        codeword[28] = data_in[23]; codeword[29] = data_in[24];
        codeword[30] = data_in[25]; codeword[31] = p32;
        codeword[32] = data_in[26]; codeword[33] = data_in[27];
        codeword[34] = data_in[28]; codeword[35] = data_in[29];
        codeword[36] = data_in[30]; codeword[37] = data_in[31];

        codeword[38] = ^codeword[37:0];   // overall parity (SEC-DED)
    end
endmodule
