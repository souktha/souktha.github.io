/* 
  **
  ** bch15_7_5_decode.v
  **
  ** I originally wrote this verilog HDL as part of my BCH (15,7,5) blog post.
  **
  ** Copyright 2017 Soukthavy Sopha (soukthavy@yahoo.com)
  **
  ** This software is licensed under the terms of the GNU General
  ** Public License (GPL). Please see the file COPYING for details.
  **
  **
  

  **  Binary BCH (n,k,d)=(15,7,5) decoder

  **  Primitive p(x) = 1 + x +x^4  =m_1(x), m_3(x)=x^4+x^3+x^2+x+1 for
  **  generator g(x)=x^8 + x^7 + x^6 + x^4 + 1

*/
`timescale 100ps / 10ps 

`define NBITS	4'hf
`define KBITS	4'h7
`define PBITS 	`NBITS - `KBITS
`define CODEDBITS `KBITS + `PBITS


`define OUTPUT_HOLD_TIME 4'h2 
`define BITS_PLUS_HOLD_TIME `CODEDBITS + `OUTPUT_HOLD_TIME 
`define NSHIFTS `NBITS + `OUTPUT_HOLD_TIME 

/*
*  Decode (15,7,5) binary BCH 
*/
module bch15_7_5_decode #(parameter IWIDTH=15, OWIDTH=7) (
    input clk,
    input dec_enable, //enable decoder
    input  ibit, //serialize input bit input code word

    output bsy, // state of decoder
    output rdy, // 1 when decoded data is ready for reading.
    output err, // error if undecodable

    output [OWIDTH-1:0] outw //7 bit output decoded word
    );

    wire [7:0] r;
    reg ierr = 1'b0; //error bit in input
	reg [IWIDTH-1:0] cw, quotient;
    wire [IWIDTH-1:0] bit_correction;
    reg [IWIDTH-1:0] correction;

    reg [4:0] count = 5'h0;

    reg [2:0] current,next;

    parameter IDLE=3'b000, DECODING=3'b001, DOUT=3'b011;
	parameter DHOLD=3'b111, UNCORRECTABLE=3'b100;
    

    reg busy = 1'b0;
    reg ready = 1'b0;

    wire [3:0] sweight;
    wire divider_en ;
	wire [7:0] si;
    
    wire sready;

    reg calc_synd_en;
    reg [4:0] jpos;
    wire [4:0] pos;

    assign rdy = ready | sready;
    assign bsy = busy;
    assign err = ierr;

    assign outw = cw[IWIDTH-1:`PBITS] ^ bit_correction[IWIDTH-1:`PBITS];

    initial begin
		quotient = 15'h0;
		cw = 15'h0;
        calc_synd_en = 1'b0;
        jpos = 5'h0;
        end

	always@(current , dec_enable, count, r )
		if ( !dec_enable ) begin
			next <= IDLE;
			busy <= #1 1'b0;
			ready <= #1 1'b0;
			calc_synd_en <= 1'b0;
            ierr <= #1 1'b0;
		end
		else begin
            busy <= #1 1'b1;
			case (current)
				IDLE: begin
					next <= DECODING;
					end
				DECODING: begin
                    if (count >= `NBITS ) begin
                        if ( sweight <= 4'h2 ) begin
                            calc_synd_en <= 1'b1; 
                            next <= DOUT;
                            jpos <= count - 5'h10;  //latch
                            end
                        else if (count == 5'h18 ) begin
                            next <= UNCORRECTABLE;
                            end
                        end

					end //case
				DOUT: begin
					busy <= #1 1'b0;
					ready <= #1 1'b1;
                    jpos <= 5'h0;
					next <= DHOLD;
					end
				DHOLD: begin
					next <= IDLE;
					ready <= #1 1'b0;
                    ierr <= #1 1'b0;
					end
				UNCORRECTABLE: begin
					next <= DHOLD;
                    busy <= #1 1'b0;
                    ready <= #1 1'b1;
                    ierr <= #1 1'b1;
					end
				default: begin
                    next <= DHOLD;
                    busy <= #1 1'b0;
                    ierr <= #1 1'b1;
                    end
			endcase
			end

    /* start 5 bit count process if enable */
    always@(posedge clk)
	if (!dec_enable ) begin
		count <= 5'h0;
		current <= IDLE;
		end
	else begin
        count <= count + 1'b1;
		current <= next;
	end

    assign divider_en = busy;

    always@(posedge clk)
        if (dec_enable && busy ) begin
            /* need to hold after 15 bits shifted in */
            if ( count < 5'h10 ) //`NBITS )
             cw <= {cw[IWIDTH-2:0],ibit};
        end

    modulo_gx syndrome (
        .clk(clk),
        .enable(divider_en),
        .ibit(ibit),
        .weight(sweight),
        .remainder(r)
        );

	assign pos = jpos;

	wire enable_estimate_error_bits;

	assign enable_estimate_error_bits = ((sweight <= 4'h2) & ( count >= `NBITS) ) ? 1'b1:1'b0;

	compute_error_cw likely_bits_err (
		.clk(clk),
		.enable(enable_estimate_error_bits),
		.syndrome(r),
        .weight(sweight),
		.pos(pos),
        .rdy(sready),
		.err_bits(bit_correction)
		);

endmodule

module compute_error_cw (
	input clk,
	input enable,
	input [7:0] syndrome,
	input [4:0] pos,
    input [3:0] weight,
	output rdy,
	output [14:0] err_bits
	);

	reg [22:0] bit_err;
	reg [14:0] R; //for division of 1+x**n
	reg [7:0] ibit;

	reg [2:0] count;

	reg ready;

	initial begin
		bit_err = 23'h0;
		R = 15'h0;
		count = 3'h0;
		ready = 1'b0;
		end

	assign err_bits = bit_err[14:0]; /* error bits are lower 15 bits */
    assign rdy = ready;

	always@(syndrome, pos, enable) begin
        if ( !ready ) begin
		bit_err = syndrome << (5'h0f  - pos);
		R  = bit_err[14:0];
        end
		end

	/* cannot be more than 8 shifts */
	always@(posedge clk) begin
		if ( enable )
			count <= count + 1'b1;
		else begin
			count <= 3'h0;
			end
	end
	/* Divide by 1+x**15.
     Divide only if degree of the computed syndrome Si is >= 15.
     */
	always@(posedge clk)
        if (enable) begin
		ready <= 1'b0;
        /* Divide if degree is >= 15 */
		if ( bit_err[22:15] ) begin
			R[0] <= R[14] ^ ibit;
			R[1] <= R[0];
			R[2] <= R[1];
			R[3] <= R[2];
			R[4] <= R[3];
			R[5] <= R[4];
			R[6] <= R[5];
			R[7] <= R[6];
			R[8] <= R[7];
			R[9] <= R[8];
			R[10] <= R[9];
			R[11] <= R[10];
			R[12] <= R[11];
			R[13] <= R[12];
			R[14] <= R[13];
        
			ibit <= {ibit[6:0],1'b0};
            if (weight <= 4'h2 )
                ready <= 1'b1;
		end
		else 
			ready <= 1'b1;
        end
        else
            ready <= 1'b0;

endmodule
/* serialize input modulo g(x) */
module modulo_gx #(parameter IWIDTH=15, OWIDTH=8) (
    input clk,
    input enable, //enable divider
    input  ibit, /* serialize input code word */
    output [3:0] weight,
    output [OWIDTH-1:0] remainder //remainder output
);
    reg [OWIDTH-1:0] r; 
	reg [IWIDTH-1:0] cw;

    assign remainder  = r;

    initial begin
        r = 8'h0;
    end
    assign weight = r[0] + r[1] + r[2] + r[3] + r[4] + r[5] + r[6] + r[7];

    /* divider g(x)=x^8 + x^7 + x^6 + x^4 + 1 */
    always@(posedge clk) begin
	if (enable ) begin
		r[7] <=  r[6] ^ r[7];
		r[6] <=  r[5] ^ r[7];
		r[5] <=  r[4];
		r[4] <=  r[3] ^ r[7];
		r[3] <=  r[2];
		r[2] <=  r[1];
        r[1] <=  r[0];

		r[0] <=  ibit ^ r[7];
    end
    else 
        r <=  8'h0;
    end

endmodule 

