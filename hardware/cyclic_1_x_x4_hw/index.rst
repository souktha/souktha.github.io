.. title: Simple Cyclic Hamming (15,11,3) FEC
.. slug: cyclic_1_x_x4_hw
.. date: 2016-12-22 00:17:42 UTC
.. tags: hardware, mathjax, latex
.. category: FPGA
.. link: 
.. description: 
.. type: text

This post is the implementation part of the my post on `simple cyclic Hamming code`_
where I did some math workout on this type of forward error-correction code (FEC). I am doing
it for fun since I think it is simple enough to implement it in FPGA. The generator
for this exercise is :math:`g(x)=1+x+x4` for an :math:`(n,k,d) \equiv (15,11,3)` code.

.. _simple cyclic Hamming code: http://souktha.github.io/misc/cyclic_1_x_x4
.. _link: `simple cyclic Hamming code`_ 


.. TEASER_END

Implementation
===============

If the data to be encoded is parallel data block, the encoded message can simply be done with
simple combinational logic based on the :math:`G` matrix, likewise for the decoder logic, but 
this is too boring. I choose to complicate this matter by assuming that the input data bits
to be encoded or decoded arrive serially, perhaps from a transceiver part of the circuit. This
way I can implement it with divider circuit and get myself frustrated with timing closure and 
everything else. Simple and elegant way is not always paid off. This is what I am going to do.

For this exercise, I am targeting the Xilinx Artix FPGA device. I create three verilog modules,

. Encoder for encoding 11-bit message to 15-bit message.

. Decoder for decoding the 15-bit receiving message. 

. Corrector is for correcting the error if syndrome indicates the error.

The encoder
-----------

The encoder takes a stream of 11-bit input message and encodes it to 15-bit messages in
systematic form. The input bit is clocked in bit-by-bit to the encoder whenever *enc_enable*
is asserted. On the completion of the encoding process, the *rdy* is asserted as an output
ready indicator so that the 15-bit encoded message can be read.

.. code-block:: verilog
   :linenos:

        /*(n,k,d) = (15,11,3) 
        input is serialized 11 bits, output is 15 bits*/
        
        module cyclic_1_x_x4_encode #(parameter IWIDTH=11, OWIDTH=15) (
            input clk,
            input enc_enable, //enable encoder
            output bsy, // state of encoder
            output rdy, // 1 when decoded data is ready for reading.
            input  ibit, //serialize input bit input code word
            output [OWIDTH-1:0] codeword
            );

            reg [OWIDTH-1:0] cw = 15'h0;
            reg [3:0] q, r; //quotient and remainder
            reg [5:0] count = 4'h0;

            reg busy = 1'b1;
            reg ready = 1'b0;
            wire fbypass;

            assign rdy = ready;
            assign bsy = busy;

            assign codeword = cw;

            initial begin
                q = 4'b0000;
                r = 4'b0000;
                end

            /*start bit counting process if busy*/
            always@(posedge clk)
                if ( !enc_enable )
                    count <= 5'h0;
                else begin
                if (count <= `NSHIFTS )
                    count <= count + 1'b1;
                else
                    count <= 5'h0;
                end

            assign fbypass = (count <= `KBITS);

            always@(posedge clk ) begin
                if ( enc_enable ) begin
                    if ( count == 5'h0  ) begin
                        busy <= #1 1'b0;
                        ready <= #1 1'b0;
                    end
                    else begin
                        if ( fbypass  ) begin
					/*pass through k bits of message*/
                            busy <= #1 1'b1;
                            ready <= #1 1'b0;
                            cw <= {cw[OWIDTH-2:0],ibit}; //left shift to MSB begin with 1st bit
                            end
                        else begin
                            cw <= {cw[OWIDTH-2:0],q[3]}; //concat parity bits to form coded word
                            if (count >= `NBITS) begin
                             busy <= #1 1'b0;
                             ready <= #1 1'b1;
                            end

                            end
                    end
                end
                else begin
                    cw <= 15'h0;
                    busy <= #1 1'b0;
                    ready <= #1 1'b0;
                    end
            end

            /*encoder for generator g(x) = 1 + x + x**4*/
            always@(posedge clk) begin
                if (enc_enable) begin
                    q[3] <=  q[2];
                    q[2] <=  q[1];
                    if ( fbypass )  begin
                        q[1] <=  q[3] ^ q[0] ^ ibit;
                        q[0] <=  ibit ^ q[3];
                    end 
                    else begin
                        q[1] <= q[0];
                        q[0] <= 1'b0;
                        end
                    if ( count == 5'h0 )
                        q <= 4'b0000;
                end
                else
                    q <= 4'b0000;

            end
        
        endmodule


The interface part of this module is between line 44-72. The divider circuit that forms the :math:`P_i` bits is between line 75-93.
The lines that forms the output coded word are at line 55 and 58. The sample simulation below shows one of the encoded message.
Any :math:`2^{11}` input message words can be encoded by this circuit and matches with the multiplication of the
:math:`G` matrix. This is how I know that the divider circuit works.

.. figure:: ../../images/hardware/encode_h1.jpg

        Fig1: encoded message 01h


The decoder and FEC 
-------------------

*to be completed*
