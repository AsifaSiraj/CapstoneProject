module ecc_decoder (
    input  logic [38:0] codeword_in,
    output logic [31:0] data_out,
    output logic        single_err_corrected,
    output logic        double_err_detected
);
    logic [37:0] H;
    logic        overall_parity_recv;
    logic        recv_p1, recv_p2, recv_p4, recv_p8, recv_p16, recv_p32;
    logic [31:0] recv_d;
    logic        exp_p1, exp_p2, exp_p4, exp_p8, exp_p16, exp_p32;
    logic        s1, s2, s4, s8, s16, s32;
    logic [5:0]  syndrome;
    logic        overall_exp, parity_err;
    logic [31:0] corrected_d;

    always_comb begin
        H                   = codeword_in[37:0];
        overall_parity_recv = codeword_in[38];

        recv_p1 = H[0];  recv_p2 = H[1];  recv_p4 = H[3];
        recv_p8 = H[7];  recv_p16 = H[15]; recv_p32 = H[31];

        recv_d[0]=H[2];   recv_d[1]=H[4];   recv_d[2]=H[5];
        recv_d[3]=H[6];   recv_d[4]=H[8];   recv_d[5]=H[9];
        recv_d[6]=H[10];  recv_d[7]=H[11];  recv_d[8]=H[12];
        recv_d[9]=H[13];  recv_d[10]=H[14]; recv_d[11]=H[16];
        recv_d[12]=H[17]; recv_d[13]=H[18]; recv_d[14]=H[19];
        recv_d[15]=H[20]; recv_d[16]=H[21]; recv_d[17]=H[22];
        recv_d[18]=H[23]; recv_d[19]=H[24]; recv_d[20]=H[25];
        recv_d[21]=H[26]; recv_d[22]=H[27]; recv_d[23]=H[28];
        recv_d[24]=H[29]; recv_d[25]=H[30]; recv_d[26]=H[32];
        recv_d[27]=H[33]; recv_d[28]=H[34]; recv_d[29]=H[35];
        recv_d[30]=H[36]; recv_d[31]=H[37];

        exp_p1  = recv_d[0]^recv_d[1]^recv_d[3]^recv_d[4]^recv_d[6]^recv_d[8]^recv_d[10]^
                  recv_d[11]^recv_d[13]^recv_d[15]^recv_d[17]^recv_d[19]^recv_d[21]^recv_d[23]^
                  recv_d[25]^recv_d[26]^recv_d[28]^recv_d[30];
        exp_p2  = recv_d[0]^recv_d[2]^recv_d[3]^recv_d[5]^recv_d[6]^recv_d[9]^recv_d[10]^
                  recv_d[12]^recv_d[13]^recv_d[16]^recv_d[17]^recv_d[20]^recv_d[21]^recv_d[24]^
                  recv_d[25]^recv_d[27]^recv_d[28]^recv_d[31];
        exp_p4  = recv_d[1]^recv_d[2]^recv_d[3]^recv_d[7]^recv_d[8]^recv_d[9]^recv_d[10]^
                  recv_d[14]^recv_d[15]^recv_d[16]^recv_d[17]^recv_d[22]^recv_d[23]^recv_d[24]^
                  recv_d[25]^recv_d[29]^recv_d[30]^recv_d[31];
        exp_p8  = recv_d[4]^recv_d[5]^recv_d[6]^recv_d[7]^recv_d[8]^recv_d[9]^recv_d[10]^
                  recv_d[18]^recv_d[19]^recv_d[20]^recv_d[21]^recv_d[22]^recv_d[23]^recv_d[24]^recv_d[25];
        exp_p16 = recv_d[11]^recv_d[12]^recv_d[13]^recv_d[14]^recv_d[15]^recv_d[16]^recv_d[17]^
                  recv_d[18]^recv_d[19]^recv_d[20]^recv_d[21]^recv_d[22]^recv_d[23]^recv_d[24]^recv_d[25];
        exp_p32 = recv_d[26]^recv_d[27]^recv_d[28]^recv_d[29]^recv_d[30]^recv_d[31];

        s1  = exp_p1  ^ recv_p1;
        s2  = exp_p2  ^ recv_p2;
        s4  = exp_p4  ^ recv_p4;
        s8  = exp_p8  ^ recv_p8;
        s16 = exp_p16 ^ recv_p16;
        s32 = exp_p32 ^ recv_p32;
        syndrome = {s32, s16, s8, s4, s2, s1};

        overall_exp = ^H;
        parity_err  = overall_exp ^ overall_parity_recv;

        corrected_d          = recv_d;
        single_err_corrected = 1'b0;
        double_err_detected  = 1'b0;

        if (syndrome == 6'd0 && !parity_err) begin
            // no error
        end
        else if (syndrome == 6'd0 && parity_err) begin
            single_err_corrected = 1'b1;             // overall parity bit itself flipped
        end
        else if (syndrome != 6'd0 && parity_err) begin
            single_err_corrected = 1'b1;             // correctable single-bit error
            case (syndrome)
                6'd3 : corrected_d[0]  = ~recv_d[0];
                6'd5 : corrected_d[1]  = ~recv_d[1];
                6'd6 : corrected_d[2]  = ~recv_d[2];
                6'd7 : corrected_d[3]  = ~recv_d[3];
                6'd9 : corrected_d[4]  = ~recv_d[4];
                6'd10: corrected_d[5]  = ~recv_d[5];
                6'd11: corrected_d[6]  = ~recv_d[6];
                6'd12: corrected_d[7]  = ~recv_d[7];
                6'd13: corrected_d[8]  = ~recv_d[8];
                6'd14: corrected_d[9]  = ~recv_d[9];
                6'd15: corrected_d[10] = ~recv_d[10];
                6'd17: corrected_d[11] = ~recv_d[11];
                6'd18: corrected_d[12] = ~recv_d[12];
                6'd19: corrected_d[13] = ~recv_d[13];
                6'd20: corrected_d[14] = ~recv_d[14];
                6'd21: corrected_d[15] = ~recv_d[15];
                6'd22: corrected_d[16] = ~recv_d[16];
                6'd23: corrected_d[17] = ~recv_d[17];
                6'd24: corrected_d[18] = ~recv_d[18];
                6'd25: corrected_d[19] = ~recv_d[19];
                6'd26: corrected_d[20] = ~recv_d[20];
                6'd27: corrected_d[21] = ~recv_d[21];
                6'd28: corrected_d[22] = ~recv_d[22];
                6'd29: corrected_d[23] = ~recv_d[23];
                6'd30: corrected_d[24] = ~recv_d[24];
                6'd31: corrected_d[25] = ~recv_d[25];
                6'd33: corrected_d[26] = ~recv_d[26];
                6'd34: corrected_d[27] = ~recv_d[27];
                6'd35: corrected_d[28] = ~recv_d[28];
                6'd36: corrected_d[29] = ~recv_d[29];
                6'd37: corrected_d[30] = ~recv_d[30];
                6'd38: corrected_d[31] = ~recv_d[31];
                default: corrected_d = recv_d;       // error hit a parity bit -> data unaffected
            endcase
        end
        else begin
            double_err_detected = 1'b1;              // syndrome!=0 && !parity_err -> uncorrectable
            corrected_d = recv_d;
        end

        data_out = corrected_d;
    end
endmodule
