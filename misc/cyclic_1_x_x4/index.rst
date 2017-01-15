.. title: Simple Cyclic Hamming codes
.. slug: cyclic_1_x_x4
.. date: 2016-12-10 22:46:19 UTC
.. tags: misc, mathjax, latex
.. category: math 
.. link: 
.. description: Cyclic codes with min polyn 1+x+x**4
.. type: text

This is a math workout problem that accompanied my FPGA implementation of forward error correction code (FEC). I choose to
make a simple implementation of :math:`(n,k,d)=(15,11,1)` code using the primitive polynomial :math:`h(x)=1+x+x^4`. 
This FEC will have be able to correct 1 bit error based on its minimum distance of 3. It is simple because it can be worked 
out by hand and it would not take too long to implement in hardware.

.. TEASER_END

Some field algebra
----------------------------

A polynomial of degree :math:`n` is said to be *primitive* (over GF) if it is an *irreducible* polynomial that is not a 
divisor of :math:`1+x^m`, for any :math:`m < 2^n - 1`. Every finite field has a primitive element. In Galois
field (GF), :math:`GF(q)`, if :math:`a` is a non-zero element, it is a primitive if its order is :math:`q-1`.
An irreducible polynomial always divides :math:`1+x^m` for
:math:`m = 2^n - 1` (exact). For this exercise, :math:`h(x)=1+x+x^4`, does not divide :math:`(1+x^m)` for any
:math:`m < 2^4 -1 ( m < 15)`. It will divide :math:`(1+x^{15})` though (is a factor). I can use MATLAB to verify this,

.. code-block:: 

    >> h=[ 0 0 0 1];
    >> test=[1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
    >> [qr] = deconv(test,h);
    >> mod(r,2)
    >> s = 
     0 0 .... 0 

The remainder from the division over *Galois* field (GF) yields zeros vector from the MATHLAB operations.
Next is to construct the parity check matrix, :math:`H^t` over :math:`GF(2^r)`. From parity check matrix, the generator
matrix for the code can be found. First, let :math:`\beta` represents the code word corresponding to 
:math:`x mod h(x)` so that, :math:`\beta^i \equiv x^i mod h(x)`. This means that every non-zero can be represented 
by the power of :math:`\beta`, for example, :math:`\beta^5 \equiv x^5 mod (1+x+x^4) = x+x^2`. 
Verify it with MATHLAB operation,

.. code-block::

    >> beta5=[1 0 0 0 0 0];
    >> [q,r] = deconv(beta5,h);
    >> mod(r,2) 
    ans = 
        0 0 0 1 1 0

I need to generate all powers of :math:`\beta`, from :math:`\beta^0` to :math:`\beta^{14}`. I can use MATLAB 
operations to do that. 

.. FIXME

I can do it step-by-step
by first generate the matrix of 16 code words follows by modulo operation. MATHLAB's *dec2bin(0:2^{11}-1) - '0'*
is used to generate an arrary or matrix of base code words 0 to :math:`2^{11}`.

.. .. table:: power of :math:`\beta`

..        =====   =================================  ============================
..        word     :math:`x^i mod (1+x+x^4)`            power of :math:`beta`
..        -----   ---------------------------------  ----------------------------

..        1000    1                              	        :math:`\beta^0`

..        =====   =================================  ============================


=====   =================================  ============================
word     :math:`x^i mod (1+x+x^4)`            power of :math:`\beta`
-----   ---------------------------------  ----------------------------

1000    1                              	        :math:`\beta^0`

0100	:math:`x`                               :math:`\beta^1`

0010	:math:`x^2`                             :math:`\beta^2`

0001	:math:`x^3`                             :math:`\beta^3`

1100	:math:`x^4 \equiv 1+x`                  :math:`\beta^4`

0110	:math:`x^5 \equiv x+x^2`                :math:`\beta^5`

0011	:math:`x^6 \equiv x^2+x^3`	        :math:`\beta^6`

1101	:math:`x^7 \equiv 1+x+x^3`	        :math:`\beta^7`

1010	:math:`x^8 \equiv 1+x^2`	        :math:`\beta^8`

0101	:math:`x^9 \equiv x+x^3`	        :math:`\beta^9`

1110	:math:`x^{10} \equiv 1+x+x^2`	        :math:`\beta^{10}`

0111	:math:`x^{11} \equiv x+x^2+x^3`	        :math:`\beta^{11}`

1111	:math:`x^{12} \equiv 1+x+x^2+x^3`       :math:`\beta^{12}`

1011	:math:`x^{13} \equiv 1+x^2+x^3`	        :math:`\beta^{13}`

1001	:math:`x^{14} \equiv 1+x^3`	        :math:`\beta^{14}`

=====   =================================  ============================

Note that :math:`\beta^{15} = \beta^0 = 1` (Theorem 2.4 of [CIT003]_). This will give me the cyclic Hamming 
codes of length :math:`n = 2^r - 1` 
(15) base on the the degree of :math:`h(x)` where its parity check matrix is,


.. math::

        H^t = 
        \left[
        \begin{array}{cc}
        P_{15-4} \\
        \hline 
        I_4 
        \end{array}
        \right]
        =\left[
        \begin{array}{cc}
         \beta^{14} \\
         \beta^{13} \\
         . \\
         . \\
         \beta^0 \\
        \end{array}
        \right]
        =\left[
        \begin{array}{cc}
        1001 \\
        1101 \\
        .. \\
        1000 \\
        0100 \\
        0010 \\
        0001
        \end{array}
        \right]

If I sum row 1, 4 and 5 together (modulo 2), I get zeros. There is no two rows that forms
the third row or sum to zeros so it takes three or more to do that. By definition, it takes
:math:`d-1` rows of :math:`H^t` matrix to show linear independency; therefore, 
I can verify that its minimum distance is :math:`d-1=2 \Rightarrow d=3`.

The generator is then obtained from the parity check matrix,

.. math::

        G = 
        \left[
        \begin{array}{c|c}
         I_k &  P_{n-k} 
        \end{array}
        \right]
        =\left[
        \begin{array}{c|c}
        I_{11} &   (\beta^{14} .. \beta^4)^t
        \end{array}
        \right]
         =\left[
        \begin{array}{c|c}
        1 0 0 0 0 0 0 0 0 0 0 & 1 0 0 1 \\
        0 1 0 0 0 0 0 0 0 0 0 & 1 1 0 1 \\
        0 0 1 0 0 0 0 0 0 0 0 & 1 1 1 1 \\
        0 0 0 1 0 0 0 0 0 0 0 & 1 1 1 0 \\
        0 0 0 0 1 0 0 0 0 0 0 & 0 1 1 1 \\
        0 0 0 0 0 1 0 0 0 0 0 & 1 0 1 0 \\
        0 0 0 0 0 0 1 0 0 0 0 & 0 1 0 1 \\
        0 0 0 0 0 0 0 1 0 0 0 & 1 0 1 1 \\
        0 0 0 0 0 0 0 0 1 0 0 & 1 1 0 0 \\
        0 0 0 0 0 0 0 0 0 1 0 & 0 1 1 0 \\
        0 0 0 0 0 0 0 0 0 0 1 & 0 0 1 1 
        \end{array}
        \right]
        
..        1 0 0 0 0 0 0 0 0 0 0 & 1 1 0 0 \\
..        0 1 0 0 0 0 0 0 0 0 0 & 0 1 1 0 \\
..        0 0 1 0 0 0 0 0 0 0 0 & 0 0 1 1 \\
..        0 0 0 1 0 0 0 0 0 0 0 & 1 1 0 1 \\
..        0 0 0 0 1 0 0 0 0 0 0 & 1 0 1 0 \\
..        0 0 0 0 0 1 0 0 0 0 0 & 0 1 0 1 \\
..        0 0 0 0 0 0 1 0 0 0 0 & 1 1 1 0 \\
..        0 0 0 0 0 0 0 1 0 0 0 & 0 1 1 1 \\
..        0 0 0 0 0 0 0 0 1 0 0 & 1 1 1 1 \\
..        0 0 0 0 0 0 0 0 0 1 0 & 1 0 1 1 \\
..        0 0 0 0 0 0 0 0 0 0 1 & 1 0 0 1 
       
Because of the orthagonality between :math:`G` and :math:`H`, :math:`GH^t = 0`. The encoded
codeword of :math:`u` for this :math:`(n,k,d)=(15,11,3)` is,

.. math::
        u = vG

where :math:`v` is the 11-bit source code word to be encoded. I use MATLAB to create the matrices 
for the parity(11x4), parity check(15x4) and generator respectively(11x15).

.. code-block::

        >> p=[1 0 0 1;1 1 0 1;1 1 1 1;1 1 1 0;0 1 1 1;1 0 1 0;0 1 0 1;1 0 1 1;1 1 0 0 ;0 1 1 0;0 0 1 1];
        >> G=[eye(11) p];
        >> ht=vertcat(eye(4),p);
        >> mod(G*ht,2)

        ans =

             0     0     0     0
             0     0     0     0
             ..
             0     0     0     0

The error bit syndrome can then be computed for the FEC,

.. fixme: this is the same as I * Ht = Ht !?

.. math::
        s =
        \left[
        \begin{array}{cc}
        1 0 0 0 0 0 0 0 0 0 0 0 0 0 0   \\
        0 1 0 0 0 0 0 0 0 0 0 0 0 0 0  \\
        0 0 1 0 0 0 0 0 0 0 0 0 0 0 0  \\
        0 0 0 1 0 0 0 0 0 0 0 0 0 0 0  \\
        0 0 0 0 1 0 0 0 0 0 0 0 0 0 0  \\
        0 0 0 0 0 1 0 0 0 0 0 0 0 0 0  \\
        0 0 0 0 0 0 1 0 0 0 0 0 0 0 0  \\
        0 0 0 0 0 0 0 1 0 0 0 0 0 0 0  \\
        0 0 0 0 0 0 0 0 1 0 0 0 0 0 0  \\
        0 0 0 0 0 0 0 0 0 1 0 0 0 0 0   \\
        0 0 0 0 0 0 0 0 0 0 1 0 0 0 0  \\
        0 0 0 0 0 0 0 0 0 0 0 1 0 0 0  \\
        0 0 0 0 0 0 0 0 0 0 0 0 1 0 0  \\
        0 0 0 0 0 0 0 0 0 0 0 0 0 1 0  \\
        0 0 0 0 0 0 0 0 0 0 0 0 0 0 1  \\
        \end{array}
        \right]
        H^t

Obviously this is the same as :math:`H^t` since :math:`I_{15}H^t=H^t` where :math:`I_{15}` is
an identity matrix 15x15. Syndrome will
point to the corresponding row of :math:`I_{15}` for the correction. If the received code word, 
:math:`w` is received withou error then :math:`wH^t=0` otherwise, :math:`uH^t + eH^t = 0 + eH^t =s`
where :math:`s` is the syndrome. The row of :math:`H^t` corresponds to the row of :math:`I_{15}`.
The most likely code word with the closest distance would then be the corresponding row of
:math:`I_{15}` with matching syndrome plus the received code word :math:`w`. In general, the
*t-error correcting* code :math:`(n,k)` is capable of correctin :math:`2^{n-k}` pattern. In this 
exercise, there will be 16 correctable patterns and they are the patterns of the identity matrix.

Using MATLAB to generate the input words to be encoded for all :math:`2^{11}` possible values then
encoded it with the :math:`G` matrix following by 1 bit error simulation for error correction,

.. code-block::

        >> v=dec2bin(0:2^11-1)-'0';
        >> u=mod(v*G,2);
	>> mod(u(100,:)*ht,2)

	ans =

	    0     0     0     0

Simulate 1 bit error from one of the encoded words will result in syndrome of,
        
.. code-block::

	>> a=u(100,:);
	>> a(1)=1

	a =

	     1     0     0     0     1     1     0     0     0     1     1     1     0     0     0

	>> mod(a*Ht,2)

	ans =

	    1     0     0     1

This syndrome will correspond to the first row of :math:`I_{15}`, so the corrected code word would be,

.. code-block::

	>> mod(a(1:11) + I11(1,:),2)

	ans =

	     0     0     0     0     1     1     0     0     0     1     1

which is the same as the original unaltered test code word. This is also based on the fundamental
assumption that bit error occurs independently and that the most likely error pattern is the one
with the least weight. It is not always true in real life situation where errors can occur in
burst and the level of complexity to FEC this type of error will increase. For this block code,
the probability that the decoder commits the error is bounded by

.. math::

        Prob_{error message} \leq \sum_{j=2}^{15} \binom{15}{j} p^j ( 1 - p)^{15-j}

where :math:`p` is the transition probability of the channel, for example, if the reliability of
the BSC is one bit error for every ten millions bits then :math:`p = 10^{-7}`.

The next step is to implement this simple FEC in verilog HDL using shift registers for the encoder
and decoder following by synthesizing it into FPGA bitstream if the input data stream is the
serialized bits stream. If the input data is in parallel block format, the parity bits or the 
redundant bits :math:`P_i` can be calcuted from the 11 bit input word, :math:`v_{10}..v_0` based on G,

.. math::

        p_3 = v_{10} \oplus v_9 \oplus v_8 \oplus v_7 \oplus v_5 \oplus v_3 \oplus v_2

        p_2 = v_9 \oplus v_8 \oplus v_7 \oplus v_6 \oplus v_4 \oplus v_2 \oplus v_1

        p_2 = v_8 \oplus v_7 \oplus v_6 \oplus v_5 \oplus v_3 \oplus v_1 \oplus v_0

        p_0 = v_{10} \oplus v_9 \oplus v_8 \oplus v_6 \oplus v_4 \oplus v_3 \oplus v_0


to put the encoded data bits :math:`u` is in its systematic form where its row vector,

.. math::

        u = 
        \left[
        \begin{array}{c|c}
         v_{11} v_{10} .. v_0 &  p_3 .. p_0
        \end{array}
        \right]


The encoded words are the contatenation of the input word and the parity bits. The HDL implementation
of this FEC exercise is `Simple Cyclic Hamming FEC`_

.. _Simple Cyclic Hamming FEC: http://souktha.github.io/hardware/cyclic_1_x_x4_hw
.. _link: `Simple Cyclic Hamming FEC`_


There are many excellent text books and articles on this subject. Listed in the reference
are only a few that I have. For EE, [CIT003]_ is a very well known text book on this
subject.

Reference
===========
.. all the references books, articles etc

.. [CIT001] Digital Communications Fundamentals and Applications, 2nd Ed, Bernard Sklar.

.. [CIT002] Coding Theory The Essentials, D.G Hoffman, 1991.

.. [CIT003] Error Control Coding Fundamental And Applications, Shu Lin, Daniel J. Costello Jr, 1983
