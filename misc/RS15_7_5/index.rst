.. title: RS(n,k) code for burst error-correction work out 
.. slug: RS15_7_5
.. date: 2017-04-22 22:46:19 UTC
.. tags: misc, mathjax, latex
.. category: math 
.. link: 
.. description: RS (n=15,k=9,d=7) code
.. type: text

This is a math workout problem that is the math part of my FPGA implementation of
another class of BCH code. The math workout of my earlier blog of a binary BCH code of 
:math:`(n,k,d)=(15,7,5)` is applicable to this class of code, the RS code
which is the non-binary version of BCH code. It will be based on the same
primitive polynomial :math:`h(x)=1+x+x^4` as the last exercise.

.. TEASER_END

Another important class of BCH codes is RS code. It is a *subfield subcode* of the 
binary BCH and has many practical real-life applications. Eventhough its digits in
code word are not binary, they have binary representation. This exercise is 
for :math:`RS(n=15,k=9,d=7)` code.

RS field algebra
------------------------

Most of everything algebra in binary BCH over :math:`GF(2)=\{0,1\}` applies to this code. RS
code generalized over :math:`GF(q)` where :math:`q` is power of prime. While the binary BCH, 
if :math:`\alpha` is a primitive elemement in the field :math:`GF(q=2)`, the binary BCH of 
:math:`2t` error-correction with :math:`g(x)=m_1(x)m_3(x)` as its generator polynomial 
will have :math:`\{\alpha,\alpha^2,\alpha^3,\alpha^4\}` as its roots. The RS code generalized
over :math:`GF(2^4)` will also have :math:`\{\alpha,\alpha^2,\alpha^3,\alpha^4\}` as its
roots with generator polynomial, :math:`g(x)=(\alpha+x)(\alpha^2+x)(\alpha^3+x)(\alpha^4+x)` where
the components are chosen fromt the field elements of :math:`GF(2^4)[x]` ie.. *subfield subcode*.

Some definition
================

A binary *Reed-Solomon* code, :math:`RS(2^r,d)` is a cyclic code over :math:`GF(2^r)` with generator polynomial
:math:`g(x)=(\alpha^{m+1}+x)(\alpha^{m+2}+x) \cdots (\alpha^{m+d-1}+x)` for some integer :math:`m`
and some primitive element :math:`\alpha` of :math:`GF(2^r)`.

:math:`RS(2^r,d)` code is defined as code having, 

a) :math:`n = 2^r -1`

b) :math:`k = 2^r - d, n-k = 2t`

c) :math:`codewords = 2^{rk}` 

RS code is a *q-ary* code and is also an *MDS* code (:math:`d=n-k+1`, *Singleton* bound). 
In summary, a :math:`t` error-correcting RS code over :math:`GF(q=2^r)`, 
having :math:`\alpha` as its primitive element has generator polynomial,

.. math::

        g(x) &= (x+\alpha)(x+\alpha^2) \cdots (x+\alpha^{2t}) \\
        &=g_0+g_1x+g_2x^2 + \cdots +g_{2t-1}x^{2t-1}+x^{2t}

.. Since the degree of of each minimal polynomial is :math:`m` or less, :math:`g(x)` has degree
.. at most :math:`mt = (n-k)`, its parity check digits.
.. Base on the theorem that the set of all roots of :math:`m_\alpha(x)` is 
.. :math:`\{\alpha,\alpha^2,\alpha^4,..,\alpha^{2t-1}\}`, the single error-correcting BCH codes
.. will have the generator polynomial, :math:`g(x) = m_{\alpha^1}(x)`. The two error-correcting codes
.. will have the generator polynomial, :math:`g(x) =  m_\alpha(x)m_{\alpha^3}(x)`.

The elements of :math:`GF(2^4)` based on :math:`p(x)=x^4+x+1` as generated in the old post
is again tabulated below,


=====   =================================  ============================
word     :math:`x^i\ mod\ (1+x+x^4)`            power of :math:`\alpha`
-----   ---------------------------------  ----------------------------

0000     -                                  	 -

1000    1                              	        :math:`\alpha^0`

0100	:math:`x`                               :math:`\alpha^1`

0010	:math:`x^2`                             :math:`\alpha^2`

0001	:math:`x^3`                             :math:`\alpha^3`

1100	:math:`x^4 \equiv 1+x`                  :math:`\alpha^4`

0110	:math:`x^5 \equiv x+x^2`                :math:`\alpha^5`

0011	:math:`x^6 \equiv x^2+x^3`	        :math:`\alpha^6`

1101	:math:`x^7 \equiv 1+x+x^3`	        :math:`\alpha^7`

1010	:math:`x^8 \equiv 1+x^2`	        :math:`\alpha^8`

0101	:math:`x^9 \equiv x+x^3`	        :math:`\alpha^9`

1110	:math:`x^{10} \equiv 1+x+x^2`	        :math:`\alpha^{10}`

0111	:math:`x^{11} \equiv x+x^2+x^3`	        :math:`\alpha^{11}`

1111	:math:`x^{12} \equiv 1+x+x^2+x^3`       :math:`\alpha^{12}`

1011	:math:`x^{13} \equiv 1+x^2+x^3`	        :math:`\alpha^{13}`

1001	:math:`x^{14} \equiv 1+x^3`	        :math:`\alpha^{14}`

=====   =================================  ============================

Note that :math:`\alpha^{15} = \alpha^0 = 1`.
As usual, the table above can be easily generated with Octave/MATLAB,

.. code-block::

        > I=eye(15);I=I(15:-1:1,:);
        >> for i=1:15
        [q,r(i,:)]=deconv(I(i,:),[1 0 0 1 1]);
        end
        >> r=mod(r(:,12:15),2)
        r =

           0   0   0   1
           0   0   1   0
           0   1   0   0
           1   0   0   0
           ..
           1   0   0   1

where the result row vectors :math:`r` are the remainders from the polynomial division.

For :math:`RS(2^4,5)`,  the generator polynomial is,

.. math::
        
        g_5(x) &=(\alpha + x)(\alpha^2+x)(\alpha^3+x)(\alpha^4+x) \\
        &=x^4 + (\alpha^4 + \alpha^3 + \alpha^2 + \alpha)x^3 + 
        (\alpha^7 + \alpha^6 + \alpha^4 + \alpha^3)x^2 + 
        (\alpha^9 + \alpha^8 +\alpha^7 + \alpha^6)x + \alpha^{10}

By using the tabulated table above for the sum of power of :math:`\alpha`, the
generator polynomial can be simplied, for example, :math:`\alpha^4+\alpha^3+\alpha^2+\alpha
=1+x+x^3+x^2+x=1+x^2+x^3=\alpha^{13}`,

.. math::

        g_5(x) = x^4 + \alpha^{13}x^3 + \alpha^6 x^2 + \alpha^3 x + \alpha^{10}

The generator matrix,

.. math::

        G= \left [
        \begin{array}{cc}
        g(x) \\
        xg(x) \\
        \cdots \\
        x^{k-1}g(x) \\
        \end{array}
        \right] =
       
        \left [
        \begin{array}{cc}
	0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 1 & \alpha^{13} & \alpha^6 & \alpha^3 & \alpha^{10}  \\
	0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 1 & \alpha^{13} & \alpha^6 & \alpha^3 & \alpha^{10} & 0  \\
	\cdots \\
	1 & \alpha^{13} & \alpha^6 & \alpha^3 & \alpha^{10} & 0 & 0 & 0 & 0  & 0 & 0 & 0 & 0 & 0 & 0 \\
        \end{array}
        \right] 

..	0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 1 & \alpha^{13} & \alpha^6 & \alpha^3 & \alpha^{10}  \\
	0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 1 & \alpha^{13} & \alpha^6 & \alpha^3 & \alpha^{10} & 0  \\
	0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 1 & \alpha^{13} & \alpha^6 & \alpha^3 & \alpha^{10} & 0 & 0 \\
	0 & 0 & 0 & 0 & 0 & 0 & 0 & 1 & \alpha^{13} & \alpha^6 & \alpha^3 & \alpha^{10} & 0 & 0 & 0 \\
	0 & 0 & 0 & 0 & 0 & 0 & 1 & \alpha^{13} & \alpha^6 & \alpha^3 & \alpha^{10} & 0 & 0 & 0 & 0 \\
	0 & 0 & 0 & 0 & 0 & 1 & \alpha^{13} & \alpha^6 & \alpha^3 & \alpha^{10} & 0 & 0 & 0 & 0 & 0 \\
	0 & 0 & 0 & 0 & 1 & \alpha^{13} & \alpha^6 & \alpha^3 & \alpha^{10} & 0 & 0 & 0 & 0  & 0 & 0 \\
	0 & 0 & 0 & 1 & \alpha^{13} & \alpha^6 & \alpha^3 & \alpha^{10} & 0 & 0 & 0 & 0  & 0 & 0 & 0 \\
	0 & 0 & 1 & \alpha^{13} & \alpha^6 & \alpha^3 & \alpha^{10} & 0 & 0 & 0 & 0  & 0 & 0 & 0 & 0 \\
	0 & 1 & \alpha^{13} & \alpha^6 & \alpha^3 & \alpha^{10} & 0 & 0 & 0 & 0  & 0 & 0 & 0 & 0 & 0 \\
	1 & \alpha^{13} & \alpha^6 & \alpha^3 & \alpha^{10} & 0 & 0 & 0 & 0  & 0 & 0 & 0 & 0 & 0 & 0 \\
        \end{array}
..        0 & \alpha^{10} & \alpha^3 & \alpha^6 & \alpha^{13} & 1 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0  \\
..        0 & 0 & \alpha^{10} & \alpha^3 & \alpha^6 & \alpha^{13} & 1 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0  \\
..        0 & 0 & 0 & \alpha^{10} & \alpha^3 & \alpha^6 & \alpha^{13} & 1 & 0 & 0 & 0 & 0 & 0 & 0 & 0  \\
..        0 & 0 & 0 & 0 & \alpha^{10} & \alpha^3 & \alpha^6 & \alpha^{13} & 1 & 0 & 0 & 0 & 0 & 0 & 0 \\
..        0 & 0 & 0 & 0 & 0 & \alpha^{10} & \alpha^3 & \alpha^6 & \alpha^{13} & 1 & 0 & 0 & 0 & 0 & 0 \\
..        0 & 0 & 0 & 0 & 0 & 0 & \alpha^{10} & \alpha^3 & \alpha^6 & \alpha^{13} & 1 & 0 & 0 & 0 & 0 \\
..        0 & 0 & 0 & 0 & 0 & 0 & 0 & \alpha^{10} & \alpha^3 & \alpha^6 & \alpha^{13} & 1 & 0 & 0 & 0 \\
..        0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & \alpha^{10} & \alpha^3 & \alpha^6 & \alpha^{13} & 1 & 0 & 0 \\
..        0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & \alpha^{10} & \alpha^3 & \alpha^6 & \alpha^{13} & 1 & 0 \\
..        0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & \alpha^{10} & \alpha^3 & \alpha^6 & \alpha^{13} & 1  \\

..        \left [
..        \begin{array}{cc}
..        \alpha^{10} & \alpha^3 & \alpha^6 & \alpha^{13} & 1 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 \\
..        0 & \alpha^{10} & \alpha^3 & \alpha^6 & \alpha^{13} & 1 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0  \\
..        \cdots \\
..        0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & \alpha^{10} & \alpha^3 & \alpha^6 & \alpha^{13} & 1 & 0 \\
..        0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & \alpha^{10} & \alpha^3 & \alpha^6 & \alpha^{13} & 1  \\
..        \end{array}
..        \right] 

An 11-bit symbol input :math:`u=\alpha \alpha^2 0 1 \alpha^6 0 0 0 0 0 0` would be encoded by this generator matrix as,

.. math::

        v = uG = 0 0 0 0 0 0 \alpha^6 \alpha\ \alpha \alpha \alpha^{14} \alpha^7 \alpha^{13} \alpha^6 \alpha^{11}

Its corressponding polynomial,

.. math::

        v(x) = \alpha^{11}+\alpha^6x+\alpha^{13}x^2+\alpha^7x^3+\alpha^{14}x^4+ \alpha x^5+ \alpha x^6+ \alpha x^7+\alpha^6 x^8

For :math:`\alpha` as its root, by substituting :math:`x` with :math:`\alpha`, it should produce zero,

.. math::

        v(\alpha) &= \alpha^{11}+\alpha^7+1+\alpha^{10}+\alpha^3+\alpha^6+\alpha^7+\alpha^8+\alpha^{14} \\
                  &= \alpha^{11}+1+\alpha^{10}+\alpha^3+\alpha^6+\alpha^8+\alpha^{14} \\
                  &= 0

The binary representation of :math:`v, \hat{v}` code word would have lenght of :math:`r(2^r-1) = 60` bits, that is,
:math:`\hat{v}=` 0000 0000 ... 1100 1110  where each code symbol is mapped to its respective binary equivalent. It is
one the reasons that :math:`\hat{v}` performs well as *burst error correction code* where group of errors occur close
together. Clearly :math:`v` encoded this way, using :math:`G` matrix above is not in in systematic form;
however, encoding by polynomial division will produce the systematic form. This is similar to binary BCH. Let,

.. math::

        u(x) = a_0x + a_1x + a_2x^2 + \cdots + a_{k-1}x^{k-1}

be the message to be encoded. The :math:`2t` parity check digits of the remainder from the division by :math:`g(x)` would be,

.. math::

        r(x) = b_0x + b_1x + b_2x^2 + \cdots + a_{2t-1}x^{2t-1}

For :math:`u=\alpha \alpha^2 0 1 \alpha^6 0 0 0 0 0 0`, encoding in systematic form as :math:`\frac{x^4u(x)}{g(x)}` would be,

.. math::

        v(x) = \alpha x^{14} + \alpha^2 x^{13} + x^{11} + \alpha^6 x^{10} + \alpha^4 x^3 + \alpha^{11}x^2 + \alpha^8 x

where the lower degree up to :math:`n-k-1` of :math:`v(x)` are the parity symbol bits. Verify that :math:`v(\alpha)` obtained
this way is also zero,

.. math::

        v(\alpha) &= 1 + 1 + \alpha^{11} + \alpha + \alpha^7 + \alpha ^{13} + \alpha^9 \\
        &= \alpha^{11}+ \alpha + \alpha^7 + \alpha^{13} + \alpha^9 \\
        & = 0

For :math:`RS(2^4,7)`,  the generator polynomial is,

.. math::

        g_7(x) &=(\alpha + x)(\alpha^2+x)(\alpha^3+x)(\alpha^4+x)(\alpha^5+x)(\alpha^6+x) \\
             &= x^6 + (\alpha+\alpha^2+\alpha^3+\alpha^4+\alpha^5+\alpha^6)x^5 + (\alpha^3+\alpha^4+\alpha^7+\alpha^{10}+\alpha^{11})x^4 + \\
                & (\alpha^6+\alpha^7+\alpha^9+\alpha^{10}+\alpha^{11}+\alpha^{12}+\alpha^{14}+\alpha^0)x^3 + \\
                & (\alpha^{10}+\alpha^{11}+\alpha^{14}+\alpha^2+\alpha^3)x^2 + \\
                & (\alpha^0+\alpha+\alpha^2+\alpha^3+\alpha^4+\alpha^5)x + \alpha^6

Using the tabulated table above to reduce :math:`g_7(x)` to,

.. math::

        g_7(x)= x^6 + \alpha^{10}x^5 + \alpha^{14}x^4 + \alpha^4 x^3 + \alpha^6 x^2 + \alpha^9 x + \alpha^6


To verify that this ic correct, substitute :math:`x` by any of its roots will yield zero, for example,
:math:`g(\alpha^2) = 0`.
This is the generator for RS code having :math:`t=3, n=15, k=9`, but can be shortened without compromising its error
correcting capability which is quite usual in practice and I will shorten it for my implementation.

Encoder
-------

.. graphviz::

        digraph gx {
        graph [label="g_7(x) encoder", splines=ortho];
        node[shape=record];
         input [label="input",shape=none];
         parity [label="parity", shape=none];
         pout [label="pout", shape=point];
         b0 [label="b0"];
         b1 [label="b1"];
         b2 [label="b2"];
         b3 [label="b3"];
         b4 [label="b4"];
         b5 [label="b5"];
         //s0[label="",shape=point];
         s1[label="+",shape=circle];
         s2[label="+",shape=circle];
         s3[label="+",shape=circle];
         s4[label="+",shape=circle];
         s5[label="+",shape=circle];
         s6[label="+",shape=circle];
         subgraph coeff {
         rank=same;
         rankdir=LR;
	 g0[label="a6",shape=circle];
	 g1[label="a9",shape=circle];
	 g2[label="a6",shape=circle];
	 g3[label="a4",shape=circle];
	 g4[label="a14",shape=circle];
	 g5[label="a10",shape=circle];
	 g6[label="1",shape=circle];
         } 
         subgraph top {
		rank=same;
	        top [label="gate"];
		t5 [shape=point];t4 [shape=point];
                t3 [shape=point];t2 [shape=point]; 
                t1 [shape=point] ;t0 [shape=point];
         }
	 {rankdir=LR rank=same b0->s1->b1->s2->b2->s3->b3->s4->b4->s5->b5->pout->s6} //[rank=same];         
	g6->top
	{
	constraint=false;
	g0->b0 //[constraint=false];
	g1->s1 //[constraint=false];
	g2->s2 //[constraint=false];
	g3->s3 //constraint=false];
	g4->s4
	g5->s5 //[constraint=false];
	s6->g6 //[constraint=false];
	}
	{rank=same rankdir=LR g0 g1 g2 g3 g4 g5 g6}
	t5->g5 [rank=same]
	t4->g4 [rank=same]
	t3->g3 [rank=same]
	t2->g2 [rank=same]
	t1->g1 [rank=same]
	t0->g0 [rank=same]
	top->t5 [constraint=false ]
	t5->t4 [constraint=false ]
	t4->t3 [constraint=false ]
	t3->t2 [constraint=false ]
	t2->t1 [constraint=false ]
	t1->t0 [constraint=false ]
        input->s6
        pout->parity
        }

Each :math:`a_i` represents an *n-tuples* :math:`\alpha^i` coefficient of the multiplier and 
each of :math:`b_i` represents the symbol shift register at each stage. It is worth noting that, 
unlike the binary BCH, none of the coefficients of :math:`g(x)` can be zero. The encoder block
can also be used for decoding this RS code as well.

For :math:`u=0 0 0 0 \alpha \alpha^2 0 1 \alpha^6`, encoding in systematic form as :math:`\frac{x^6u(x)}{g(x)}` would yield,
:math:`v = 0 0 0 0 \alpha \alpha^2 0 1 \alpha^6 \alpha^6 \alpha 1 \alpha^6 \alpha^9 \alpha^5` or in polynomial form,

.. math:: 

        v(x) = \alpha x^{10} + \alpha^2 x^9 + x^7 + \alpha^6 x^6 + \alpha^6 x^5 + \alpha  x^4 + x^3 + \alpha^6x^2 + \alpha^9 x + \alpha^5 

or v = 0000.. _0000_0010_0100_0000_0001_1100_1100_0010_0001_1100_1010_0110.

For a hexadecimal value of 0x2badbeef, :math:`u=\alpha \alpha^7 \alpha^9 \alpha^{13} \alpha^7 \alpha^{11} \alpha^{11} \alpha^{12}`, the encoded
parity portion will be, :math:`p=\alpha^{13} \alpha^{12} \alpha^8 \alpha^7 0 \alpha^5`. The output is the concatenated
32-bit input and 24-bit parity check bits ie.. 0x2badbeef_df5b06. 


Multiplication of :math:`GF(2^4)` elements
-------------------------------------------

For some :math:`\beta=[\beta_0 \beta_1 \beta_2 \beta_3 ]`, multiplied by some element of 
:math:`GF(2^4)`, for example,

.. math::
 
        \beta \alpha = [\beta_3 \,  \beta_2 \, \beta_1 \, \beta_0 ]
         \left [
        \begin{array}{cc}
        0 & 0 & 1 & 1 \\
        1 & 0 & 0 & 0 \\
        0 & 1 & 0 & 0 \\
        0 & 0 & 1 & 0 \\
        \end{array}
        \right] = [\beta_2 \,  \beta_1 \,  (\beta_0+\beta_3) \,  \beta_3] 

If :math:`\beta = \alpha^6 = \{1 1 0 0\}`, the product, :math:`\alpha^6 \alpha = \{1 0 1 1\} = \alpha^7`. 
In general,

.. math::

        \beta \alpha^p = [\beta_0 \,  \beta_1 \, \beta_2 \, \beta_3 ]
         \left [
        \begin{array}{cc}
        \alpha^p \\
        \alpha^{p+1} \\
        \alpha^{p+2} \\
        \alpha^{p+3} \\
        \end{array}
        \right] = [c_0 \, c_1 \, c_2 \, c_3]

.. :math:`c_i  = \sum_{j=0}^{3} \alpha_i^{p+j} \beta_j`        

For :math:`g_7(x)`, the multiplication circuit by its coefficients can be formed as follow,

.. math::

        \beta \alpha^4 &= [\beta_3 \beta_2 \beta_1 \beta_0]
        \left [
        \begin{array}{cc}
        1 & 0 & 1 & 1 \\
        1 & 1 & 0 & 0 \\
        0 & 1 & 1 & 0 \\
        0 & 0 & 1 & 1 \\
        \end{array}
        \right] \\
        & = [(\beta_3+\beta_2)  (\beta_2+\beta_1)  (\beta_3+\beta_1+\beta_0)  (\beta_3+\beta_0)] \\
        \\
        \beta \alpha^6 &= [(\beta_3+\beta_1+\beta_0)  (\beta_2+\beta_0)  (\beta_3+\beta_1)  (\beta_2+\beta_1)] \\
        \beta \alpha^9 &= [(\beta_3+\beta_2+\beta_0)  (\beta_3+\beta_2+\beta_1)  (\beta_3+\beta_2+\beta_1+\beta_0)  (\beta_3+\beta_1)] \\
        \beta \alpha^{10} &= [(\beta_3+\beta_2+\beta_1)  (\beta_3+\beta_2+\beta_1+\beta_0)  (\beta_2+\beta_1+\beta_0)  (\beta_3+\beta_2+\beta_0)] \\
        \beta \alpha^{14} &= [\beta_0  \beta_3  \beta_2  (\beta_1+\beta_0)] 

So if :math:`\beta = \alpha^2` is multiplied by :math:`\alpha^9`, I can use the formula above to 
achieve the desired mutiplication result by simple modulo sum,

.. math::

        \beta \alpha^9 = [ 0 1 0 0 ] \alpha^9 &= [ (0+1+0) (0+1+0) (0+1+0+0) (0+0) ] mod(2) \\
        &= [1 1 1 0] \\
        &= \alpha^{11}

For Verilog, all of these coefficient multiplications can be a modeled by the simple modules
that can be instantiated as the components of the RS encoder.

.. The element of :math:`GF(2^4)` can be formed by its basis that span these elements. There
       are many bases, 840 in all, but I can use this basis, :math:`B=\{ \alpha^5, \alpha^8, \alpha^{13},\alpha^{14} \}`.
        This basis is obtained by eliminating the linearly dependent component of its elements.

.. ====================      ===================================================
.. :math:`\alpha^i`           :math:`\alpha^5 \alpha^8 \alpha^{13} \alpha^{14}`
.. --------------------      ---------------------------------------------------
.. :math:`\alpha^0`                0 1 1 1
        :math:`\alpha^1`                1 0 1 1
        :math:`\alpha^2`                0 0 1 1
        :math:`\alpha^3`                0 1 1 0
        :math:`\alpha^4`                1 1 0 0
        :math:`\alpha^5`                1 0 0 0
        :math:`\alpha^6`                0 1 0 1
        :math:`\alpha^7`                1 0 1 0
        :math:`\alpha^8`                0 1 0 0
        :math:`\alpha^9`                1 1 0 1
        :math:`\alpha^{10}`             1 1 1 1
        :math:`\alpha^{11}`             1 1 1 0
        :math:`\alpha^{12}`             1 0 0 1
        :math:`\alpha^{13}`             0 0 1 0
        :math:`\alpha^{14}`             0 0 0 1
        ====================      ===================================================

By definition, a t-error-correcting BCH code of lengt :math:`2^m-1` having a binary *n-tuple* 
:math:`u(X)=u_0+u_1+\cdots+u_{n-1}` is a code word iff :math:`u(X)` has :math:`\alpha,\alpha^2,
\cdots,\alpha^{2t}` as roots, that is,

.. math::

        u(\alpha^i) = u_o + u_1(\alpha^i) + u_2(\alpha^{2i}) + \cdots + u_{n-1}(\alpha^{(n-1)i}) = 0

and for this exercise,         

.. math::

        u(\alpha) = u_o + u_1(\alpha) + u_2(\alpha^2) + \cdots + u_{n-1}(\alpha^{14}) = 0  \\
        u(\alpha^3) = u_o + u_1(\alpha^3) + u_2(\alpha^{6}) + \cdots + u_{n-1}(\alpha^{42}) = 0 \\
..        u(\alpha^5) = u_o + u_1(\alpha^5) + u_2(\alpha^{10}) + \cdots + u_{n-1}(\alpha^{150}) = 0

note that the power of :math:`\alpha` will wrap on this finite field, for example, 
:math:`\alpha^{18} = \alpha^{15} \alpha^3 = \alpha^{3}`. Put it in matrix form,

.. math::

        ( u_{n-1} \cdots u_1 u_0)  
        \left [
        \begin{array}{cc}
        \alpha^{14} & (\alpha^2)^{14} \cdots & (\alpha^6)^{14} \\
        \cdots & \cdots &  \cdots \\
        \alpha & \alpha^2  \cdots & \alpha^6  \\
        1 & 1  \cdots & 1 
        \end{array}
        \right] = 0 
        
The equation above is in the form,

.. math::

        UH^t = 0

       
Burst error-correcting capability
---------------------------------

The burst length :math:`l` is defined as a vector whose zero components are confined to
:math:`l` consecutive positions, for example, the zero code vector of length 9 would be
something like this ..0_1110_1110_1000_0000. 

For this RS code workout, it is capable of correction the burst lenght, :math:`l\ge9` because
for :math:`RS(2^r,2t+1), l \ge r(t-1)+1` .
My implementation will show that it can indeed forward-error-correcting
such burst error. The length here is binary bit length, but it is confined within three symbols
of this q-ary code which is also its limit, twelve bits.
 
Decoder and errors locator
--------------------------

I will reuse the same algorithm that I used before and it will work just as well for
this RS workout exercise. The only exception is that I that I am dealing with the
4-tuple symbols, not plain binary bits. 

Let :math:`w(x)` be the received code word where
:math:`w(x)=u(x)+e(x)`. :math:`u(x)` and :math:`e(x)` are the transmitted code word and
error respectively.

. Calculate syndrome :math:`s(x) = w(x)\ mod\ g(x)`

. For :math:`i \ge 0`, calculate :math:`s_i(x)=x^i s(x)\ mod\ g(x)` until :math:`s_j(x)` is found 
with :math:`degree(s_j(x))) \le l-1`. I can instead use the weight of the symbols, :math:`weight(s_j(x)) \le 2t`.
This should work as well.

. Once :math:`s_j(x)` is located, :math:`e(x)=x^{n-j}s_j(x)\ mod\ (x^n + 1)` are the most likely
error symbols .

Every algorithm is iterative as far as division is involved. The iteration for this one is at most :math:`2t` because
if there are :math:`\nu \le t` error positions, the iteration is :math:`\nu + t`.

Again, assume the transmitted code word is as shown in the encoder section
( v = 0000_0000_0000_0010__0100_0000_0001_1100__1100_0010_0001_1100_1010_0110 or h0002_401C ), but with
three symbols error in the message area of code,h0AC2_421c,

.. math::

        w(x) = \underline{\alpha^9 x^{12} + \alpha^6 x^{11}} + \alpha x^{10} + \alpha^2 x^9 + \underline{\alpha x^8} +  x^7 + \alpha^6 x^6 + \alpha^6 x^5 + \alpha  x^4 + x^3 + \alpha^6x^2 + \alpha^9 x + \alpha^5 

The computed syndrome is h76_0523, or in polynomial form,

.. math::

        s(x)= w(x)\ mod\ g(x) = \alpha^{10}x^5 +\alpha^5 x^4 + \alpha^8 x^2 + \alpha x^2 + \alpha^4 \\
        s_1(x) = x s(x)\ mod\ g(x) = \alpha^4 x^4 + \alpha^6 x^3 + \alpha \\

weight of :math:`s_1(x) \le t` is reached, :math:`j=1`.

.. .. math::
        s(x) = x^{15-3}s_1(x)\ mod\ ( x^{15} + 1) \\
        = x^{13} + x^{12}
        
The most likely code word is therefore, :math:`w(x)` plus the shifted value of :math:`s_1(x)`. In this
example, it corrects 3 symbols or 12 binary bits for a 36 bits encoded codeword (plus partity check bits)
. I will shorten it to 32 bits when implementating this RS code without impairing its FEC capability.

.. How to detect an uncorrectable code word ? For this implementation, if the iteration
 exceed 4, then declare error. I experiment with larger than :math:`t` errors and I
 find out that the process just go on an on withouth reaching minimum weight.
 Any solution for any algorithm needs to take into account that there is the possibility that there
 may be fewer errors than the maximum correctble errors. 

.. For fun and for speed I will have an HDL implementation of this algorithm when time 
 permits and I will update this post with the link to it.

.. The encoded words are the contatenation of the input word and the parity bits. The HDL implementation
.. of this FEC exercise is `Simple Cyclic Hamming FEC`_

.. .. _Simple Cyclic Hamming FEC: http://souktha.github.io/hardware/cyclic_1_x_x4_hw
.. .. _link: `Simple Cyclic Hamming FEC`_

Summary
-------

RS code is one class of powerful forward-error-correcting code and it has wide variety
of applications such as those found in communication systems and in data storage subsystems.
Knowing the basic mathematic behind it, one can implement RS code of any :math:`GF(2^r)` field.
Math is everything and everything is math. *It is generally recognized that it is dangerous
to apply any part of science without undertanding what is behing 
the theory* (Richard W. Hamming).

There are many excellent text books and articles on this subject. Listed in the reference
are only a few that I have. For EE, [CIT003]_ is a very well known text book on this
subject.

The HDL implementation of this FEC exercise is `RS burst error FEC`_

.. _RS burst error FEC: http://souktha.github.io/hardware/rs15_7_hw
.. _link: `RS burst error FEC`_


Reference
----------

.. all the references books, articles etc

.. [CIT001] Digital Communications Fundamentals and Applications, 2nd Ed, Bernard Sklar.

.. [CIT002] Coding Theory The Essentials, D.G Hoffman, 1991.

.. [CIT003] Error Control Coding Fundamental And Applications, Shu Lin, Daniel J. Costello Jr, 1983
