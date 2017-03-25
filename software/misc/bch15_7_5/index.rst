.. title: Binary BCH (15,7,5) work out 
.. slug: bch15_7_5
.. date: 2017-2-26 22:46:19 UTC
.. tags: misc, mathjax, latex
.. category: math 
.. link: 
.. description: Binary BCH (15,7,5) code
.. type: text

This is a math workout problem that is the math part of my FPGA implementation of forward 
error correction code (FEC). Build on my earlier blog of a Hamming cyclic code of 
:math:`(n,k,d)=(15,11,3)`, I will expand its capability to a binary
BCH :math:`(15,7,5), t=2`  code based on the same primitive polynomial :math:`h(x)=1+x+x^4`.

.. TEASER_END

One important class of cyclic codes is BCH codes. It is quite extensive and easy to decode and
because of that it is quite practical for its use in real-life application. By definition,
any :math:`r \ge 3, t \leq 2^{r-1}-1` there exists BCH error-correcting codes of length :math:`n=2^r -1`,
parity check length :math:`(n-k) \le rt`,  minimum distance :math:`d \ge 2t + 1` and
having dimension :math:`k \geq n-rt`.  The :math:`t=1` error-correcting BCH codes of length 
:math:`n=2^r-1` is a Hamming code (old post).

Some more field algebra
------------------------

The *minimal polynomial* of :math:`\alpha`, :math:`m_{\alpha}(x)` is the smallest polynomial in
:math:`K[x]` of smallest degree having :math:`\alpha` as a root, that is, if :math:`f(x)=a_0+
a_1x+a_2x^2+..+a_kx^k`, that is :math:`f(\alpha)=a_0+a_1\alpha+a_2\alpha^2+..+a_k\alpha^k = 0`

The order of nonzero element :math:`\alpha` in :math:`GF(2^r)` is the smallest positive :math:`m`
such that :math:`\alpha^m = 1`. If :math:`\alpha` is of order :math:`2^r-1` then it is a *primitive*
element. It not easy to find the primitive polynomial of higher degree. Luckily the hard part
of finding them has been done and tabulated for our use and this is what I will use for my
implementation.

If :math:`\alpha` has order :math:`m`, then :math:`\alpha` is a root of :math:`1+x^m`.
Relative to my previous post, defining :math:`\beta` as primitive element, :math:`\alpha=\beta^i`,
then :math:`\alpha^{2r-1}=(\beta^i)^{2r-1}= (\beta^{2r-1})^i = 1^i = 1`. :math:`\alpha` is therefore
a root of :math:`1+x^{2r-1}` and :math:`m_\alpha(x)` is a factor of :math:`1+x^{2r-1}`. In the last
post :math:`g(x) | (1+x^{15})`. :math:`g(x)` must be the least common multiple of 
:math:`m_i(x),m_2(x),..,m_{2t}(x)`. Taking the conjugate roots into account, the t-error-correcting 
BCH of code length :math:`n=2^r-1` has its generator :math:`g(x)` reduced to,

.. math::

        g(x) = LCM[m_1(x),m_3(x),\cdots,m_{2t-1}(x)]

Since the degree of of each minimal polynomial is :math:`m` or less, :math:`g(x)` has degree
at most :math:`mt = (n-k)`, its parity check digits.
Base on the theorem that the set of all roots of :math:`m_\alpha(x)` is 
:math:`\{\alpha,\alpha^2,\alpha^4,..,\alpha^{2t-1}\}`, the single error-correcting BCH codes
will have the generator polynomial, :math:`g(x) = m_{\alpha^1}(x)`. The two error-correcting codes
will have the generator polynomial, :math:`g(x) =  m_\alpha(x)m_{\alpha^3}(x)`.

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

Next is to get the generator polynomial by performing the calculation for minimal polynomials,
:math:`m_1(x)=p(x)` and :math:`m_3(x)`, that is the root based on 
:math:`\alpha` and :math:`\alpha^3`
because I need :math:`g(x)=m_1(x)m_3(x)` for this exercise. I can avoid the tedious calculation
by opting to use the tabulated generator polynomials of :math:`(n,k,d)` BCH code. For the
:math:`(15,7,5), t=2`, :math:`m_3(x)=x^4 + x^3 + x^2 + x +1`

.. math::
        
        g(x)=LCM[m_1(x)m_3(x)] \\
        = LCM[(x^4 + x + 1)(x^4 + x^3 + x^2 + x+ 1)] 

Using MATLAB/Octave's *conv* to multiply the polynomial,

.. code-block::

	m1=[1 0 0 1 1];
	m3=[1 1 1 1 1];
	gx=mod(conv(m1,m3),2);

.. math::

        g(x) = x^8 + x^7 + x^6 + x^4 + 1

This matches to the tabulated octal table value, :math:`(721)_8 =` 111_010_001 for this code.
I can verify that :math:`g(x) | (x^{15} + 1)` using Octave's *deconv* operation. This is to
confirm that any irreducible polynomial over GF(2) of degree :math:`m` divides :math:`X^{2^m-1}+1`.

.. graphviz::

        digraph gx {
        graph [label="polynomial g(x) divider", splines=ortho];
        node[shape=record];
         input [label="input",shape=none];
         gx1 [label="<x1> x|x2|x3|<x4> x4"];
         gx2 [label="<x5> x5|<x6> x6"];
         x7 [label="x7"];
         x8 [label="x8"];
         out [label="out"];

          E[label="",shape=point];
	  A[label="+",shape=circle];
	  B[label="+",shape=circle];
	  C[label="+",shape=circle];
	  D[label="+",shape=circle];
	  I[label="",shape=point];
	  H[label="",shape=point];
	  E1[label="",shape=point];
	  G[label="",shape=point];
	  F[label="",shape=point];
          {rank=same input->A->gx1->B->gx2;gx2->C->x7->D->x8->E->out}
          {rank=same; E1;F;G;H;I}
          I->A
          H->B;
          G->C;
          F->D;
          E->E1->F->G->H->I [constraint=false];
        }


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
        \alpha^{14} & (\alpha^3)^{14} \\
        \cdots & \cdots \\
        \alpha & \alpha^3  \\
        1 & 1 
        \end{array}
        \right] = 0 
        
The equation above is in the form,

.. math::

        UH^t = 0

       
where :math:`H^t` is the transpose of the parity check matrix. For this 
:math:`(15,7,5)` BCH code, it is

.. math::

        H^t = 
        \left[
        \begin{array}{cc}
        \alpha^{14} & (\alpha^3)^{14} \\
        \cdots & \cdots \\
        \alpha & \alpha^3  \\
        1 & 1 
        \end{array}
        \right]
	=\left[
        \begin{array}{cc}
	 1 0 0 1 & 1 1 1 1 \\
	 1 1 0 1 & 1 0 1 0 \\
	 1 1 1 1 & 1 1 0 0 \\
	 1 1 1 0 & 1 0 0 0 \\
	 0 1 1 1 & 0 0 0 1 \\
	 1 0 1 0 & 1 1 1 1 \\
	 0 1 0 1 & 1 0 1 0 \\
	 1 0 1 1 & 1 1 0 0 \\
	 1 1 0 0 & 1 0 0 0 \\
	 0 1 1 0 & 0 0 0 1  \\
	 0 0 1 1 & 1 1 1 1 \\
	 1 0 0 0 & 1 0 1 0 \\
	 0 1 0 0 & 1 1 0 0 \\
	 0 0 1 0 & 1 0 0 0 \\
	 0 0 0 1 & 0 0 0 1 \\
        \end{array}
	\right]

The power of :math:`(\alpha^3)^i` can be easily computed from power of :math:`\alpha`, for 
example, :math:`(\alpha^3)^9 = \alpha^{27} = \alpha^{15} \alpha^{12} = \alpha^{12}`

The generator is then obtained from the generator polynomial, :math:`g(x)`

.. math::

        G = 
        \left[
        \begin{array}{c|c}
         I_k &  P_{n-k} 
        \end{array}
        \right]
        =\left[
        \begin{array}{c|c}
        I_{7 \times 7} &  P_{7 \times 8} 
        \end{array}
        \right]
         =\left[
        \begin{array}{c|c}
	 1 0 0 0 0 0 0 & 1 1 1 0 1 0 0 0 \\
	 0 1 0 0 0 0 0 & 0 1 1 1 0 1 0 0 \\
	 0 0 1 0 0 0 0 & 0 0 1 1 1 0 1 0 \\
	 0 0 0 1 0 0 0 & 0 0 0 1 1 1 0 1 \\
	 0 0 0 0 1 0 0 & 1 1 1 0 0 1 1 0 \\
	 0 0 0 0 0 1 0 & 0 1 1 1 0 0 1 1 \\
	 0 0 0 0 0 0 1 & 1 1 0 1 0 0 0 1 \\
        \end{array}
        \right]
        
       
Because of the orthagonality between :math:`G` and :math:`H`, :math:`GH^t = 0`. The encoded
codeword of :math:`u` for this :math:`(n,k,d)=(15,7,5)` is,

.. math::
        u = vG

where :math:`v` is the 7-bit source code word to be encoded.

Performance of this (15,7,5) binary BCH code
---------------------------------------------

Weight distribution of this (15,7,5) code,

======   ====================
weight   number of code words
------   --------------------

 0       1
 5       18
 6       30
 7       15
 8       15
 9       30
 10      18
 15      1
======   ====================

From table above, it is easy to see that its minimum distance from the zero code word is 5.
Base on the weight distribution, for the number of code words, :math:`A_j` having weight :math:`j` 
and bit error probailitity :math:`p`,the probability that it cannot detect the error is,

.. math::

        P_{notdetect} = \sum_{j=1}^{n} A_jp^j(1-p)^{n-j} \\
        P_{notdetect} = 18p^5(1-p)^{10} + 30p^6(1-p)^9 + \cdots + p^{15}

The term having the minimum weight would be the dominant term so if :math:`p=10^{-2}` or one 
percent of error, the probability that it cannot detect the error would come out to
be :math:`P_{notdetect} \approx 1.6279 \times 10^{-9}` ie.. less then one in a billion compare
to the uncoded word, :math:`P_{notdetect} \approx 6.5904 \times 10^{-2}`. Base on this :math:`p` value,
the coded word is 40 million times better when it comes to error detection.

For a block of :math:`n=15` bits, having :math:`j` errors, the probability of block error
or message error,

.. math:: 

        P_M = \sum_{j=3}^{15} \binom{15}{j}p^j(1-p)^{15-j} \\
        \approx \binom{15}{3}p^3(1-p)^{12}


Decoder and errors locator
--------------------------

From the row of :math:`H^t`, there are :math:`2^{15}` syndromes
and :math:`1+\binom{n}{1} + \binom{n}{2} = 121` 
correctable error patterns for this implementation.

If :math:`s_i:i=1,3` are the syndromes each having 4 bits and representing the columns of
the transpose parity check matrix, :math:`H^t`,

.. math::
        
        H^t =
        \left[
        \begin{array}{cc}
        1 & 1  \\
        \alpha & \alpha^3 \\
        \cdots & \cdots  \\
        \alpha^{14} & (\alpha^3)^{14}
        \end{array}
        \right]

and :math:`w` is the received coded word, then :math:`wH^t=[w(\alpha), w(\alpha^3)] = [s_1, s_3]` is
the syndrome of this code word. For a single bit error, :math:`e(x)=x^i`, the syndrome is :math:`wH^t=[(\alpha)^i,(\alpha^3)^i]`.
If there are two errors in the code word, :math:`e(x)=x^i+x^j, i\neq j`, the syndrome
becomes :math:`[s_1,s_3]=[(\alpha)^i+\alpha^j,(\alpha^3)^i+(\alpha^3)^j]`. The equations for
error-locating position,

.. math::

        s_1 = \alpha^i + \alpha^j \\
        s_3 = (\alpha^3)^i + (\alpha^3)^j

        
Substitute :math:`s_1 + \alpha^i = \alpha_j` into :math:`s_3`,

.. math::

        s_3 = \alpha^{3i} + (s_1 + \alpha^i)^3 = \alpha^{3i} + (s_1^2 + \alpha^{2i})(s_1 + \alpha^i) \\
            = s_1^3 + s_1 \alpha^{2i} + s_1^2 \alpha^i
            

Locating error bit position is to find which :math:`i` that makes 
:math:`s_1^3 + s_1 \alpha^{2i} + s_1^2 \alpha^i + s_3 = 0`. Higher :math:`t` leads
to more messy equations, for example, the :math:`t=3` will also have :math:`s_5` syndrome 
component. In addition to that, each of these syndrome components will have one extra bit
variable, ie.. :math:`s_1 = \alpha^i + \alpha^j + \alpha^l`. As you can see, the complexity
multiplies many folds. This is why I choose lower :math:`t` to
avoid putting myself into the deep hole that I cannot get out.

.. Eventually it will lead to system of equations to be solved for a polynomial :math:`x(s_i)`. It is
.. called the error-locator polynomial. This polynomial is dependent on error bit positions.

To test the error correction capability of this exercise I will use code word u(100) and
alter bit 12 and bit 13 to simulate error,

.. FIXME

.. code-block::

        v=dec2bin(0:2^7-1)-'0'; % input code word
        u=mod(v*G,2); % BCH coded word
        w=u(100,:);w(2)=0;w(3)=1; % alter bit 13,12 for error bits
        mod(w*h,2)

The error syndrome from *mod()* operation is :math:`S=\{0010,0110\}`. This corresponds to
:math:`S=\{\alpha,\alpha^5 \}` from the tabulated power of :math:`\alpha` above. The equation
for this syndrome is then,

.. math::

        \alpha^3 + \alpha^2 \alpha^i + \alpha \alpha^{2i} + \alpha^5 = 0
        
Using :math:`i=12`,

.. math:: 

        \alpha^3 + \alpha^2 \alpha^{12} + \alpha \alpha^{24} + \alpha^ 5 = 0 \\
        \alpha^3 + \alpha^{14} + \alpha^{10} + \alpha^5 = 0


Substitute the values for power of :math:`\alpha`,

.. math:: 

        1000 + 1001 + 0111 + 0110 = 0000

This agrees with what is simulated for bit 12. Bit position 13 will produce the same
result. This is known as *Chien search* algorithm.

The output from :math:`wH^t` produces the syndrome identical to sum of two :math:`H^t` rows, 
row two and row three. The corrected code word is the sum of the received code word
and the rows of the :math:`I` matrix correspond to the parity check matrix.

Another algorithm is by formulating syndrome based on the minimal polynomials, instead of
the generator polynomial. The syndrome components for this exercise using this algorithm would be, 
:math:`S=\{s_1,s_2,s_3,s_4\}` where :math:`s_1, s_2, s_4` is obtained from :math:`m_1(x)`
and :math:`s_3` is obtained from :math:`m_3(x)` ( :math:`s_2` and :math:`s_4` are the power
of :math:`s_1`).  From this, the *error locating* polynomial
is formed. From this polynomial, the *connection* polynomial is then formed and
tranfer to the frequency domain system of equation, the *key* equation 
ie.. :math:`\sum_{j=0}^{t} \Lambda_j E_{k-j}=0`.

While there are several algorithms for error locating, they are not easy for
hardware implementation. They work well on pencil and paper, yet I am still
trying to figure out how to translate it into hardware. One
possible algorithm that I like is this, let :math:`w(x)` be the received code word where
:math:`w(x)=u(x)+e(x)`. :math:`u(x)` and :math:`e(x)` are the transmitted code word and
error respectively.

. Calculate syndrome :math:`s(x) = w(x)\ mod\ g(x)`

. For :math:`i \ge 0`, calculate :math:`s_i(x)=x^i s(x)\ mod\ g(x)` until :math:`s_j(x)` is found 
where weight of :math:`s_j(x) \le t`. 

. Once :math:`s_j(x)` is located, :math:`e(x)=x^{n-j}s_j(x)\ mod\ (x^n + 1)` are the most likely
error bits.

Every algorithm is iterative. The iteration for this one is at most :math:`2t` because
if there are :math:`\nu \le t` error positions, the iteration is :math:`\nu + t`.

Again, assume the transmitted code word :math:`u(100)=110\_0011\_0011\_1110`

.. math::

        u(x)=x^{14}+x^{13}+x^9+x^8+x^5+x^4+x^3+x^2+x

that is received having 2 bits error at bit 12 and bit 11, :math:`101\_0011\_ 0011\_1110`

.. math::
 
        u(x)=x^{14}+x^{12}+x^9+x^8+x^5+x^4+x^3+x^2+x

The computed syndrome is,

.. math::

        s(x)= w(x)\ mod\ g(x) = x^6 + x^3 + x^2 +x \\
        s_1(x) = x s(x)\ mod\ g(x) = x^7 + x^4 + x^3 + x^2 \\
        s_2(x) = x^2 s(x)\ mod\ g(x) = \cdots \\
        s_3 (x) = x^3 s(x)\ mod\ g(x) = x + 1

weight of :math:`s_3(x) \le t` is reached, so :math:`j=3`,

.. math::

        s(x) = x^{15-3}s_3(x)\ mod\ ( x^{15} + 1) \\
        = x^{13} + x^{12}
        
The most likely code word is therefore, :math:`w(x)+s(x)`. This algorithm gives me both
bit positions. :math:`s_i(x)` are the shifted version of :math:`s_{i-1}(x)` modulo of
generator. I think I can reuse the circuit for these operations.

How to detect an uncorrectable code word ? For this implementation, if the iteration
exceed 4, then declare error. I experiment with larger than :math:`t` errors and I
find out that the process just go on an on withouth reaching minimum weight.
Any solution for any algorithm needs to take into account that there is the possibility that there
may be fewer errors than the maximum correctble errors. 

For fun and for speed I will have an HDL implementation of this algorithm when time 
permits and I will update this post with the link to it.

.. The encoded words are the contatenation of the input word and the parity bits. The HDL implementation
.. of this FEC exercise is `Simple Cyclic Hamming FEC`_

.. .. _Simple Cyclic Hamming FEC: http://souktha.github.io/hardware/cyclic_1_x_x4_hw
.. .. _link: `Simple Cyclic Hamming FEC`_


There are many excellent text books and articles on this subject. Listed in the reference
are only a few that I have. For EE, [CIT003]_ is a very well known text book on this
subject.

Reference
----------

.. all the references books, articles etc

.. [CIT001] Digital Communications Fundamentals and Applications, 2nd Ed, Bernard Sklar.

.. [CIT002] Coding Theory The Essentials, D.G Hoffman, 1991.

.. [CIT003] Error Control Coding Fundamental And Applications, Shu Lin, Daniel J. Costello Jr, 1983
