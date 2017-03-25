.. title: BCH, an example of linear cyclic code
.. slug: bch_1_x_x4
.. date: 2017-01-16 23:39:17 UTC
.. tags: misc, mathjax, latex
.. category: math 
.. link: 
.. description: BCH code based on g(x)=1+x**2+x**5
.. type: text

Building on my previous post on the simple Hamming linear cyclic code, I decide to push on for a little bit
more usefull class of cyclic code, the BCH code. This will not be based on the same generator polynomial,
:math:`h(x)=1+x+x^4` using the powers of :math:`\beta` as worked out in the last post since it is only 
a :math:`t=1` FEC. While it is possible to achieve :math:`t > 1`, but it comes with the expense
of information bits. For this workout problem I choose higher degree primitive polynomial.

.. TEASER_END

One important class of cyclic codes is BCH codes. It is quite extensive and easy to decode and
because of that it is quite practical for its use in real-life application. By definition,
any :math:`r \ge 3, t \leq 2^{r-1}-1` there exists BCH error-correcting codes of length :math:`n=2^r -1`,
parity check length :math:`(n-k) \le rt`,  minimum distance :math:`d \ge 2t + 1` and
having dimension :math:`k \geq n-rt`.  The :math:`t=1` error-correcting BCH codes of length 
:math:`n=2^r-1` is a Hamming code (old post).

I will use the *primitive* :math:`p(x)=x^5+x^2+1` as a basis for the :math:`(n,k,d) \equiv (31,16,7)` BCH codes.


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

I can generate the elements of :math:`GF(2^5)` based on :math:`p(x)=x^5+x^2+1` as
the primitive polynomial numerically using *deconv* of MATHLAB/Octave,

.. code-block::
   :linenos:
        
        >> n=31;
        >> I=eye(n);
        >> gx=[1 0 0 1 0 1];
        >> I=I(n:-1:1,:);
        >> for i=1:n [a,r(i,:)]=deconv(I(i,:),gx);end
        >> r=mod(r(:,27:31),2);

then tabulate the result,

======   =================================  ============================
word      :math:`x^i mod(x^5+x^2+1)`            Power of :math:`\alpha`
------   ---------------------------------  ----------------------------
00000       -                                   -
00001       1                                   :math:`\alpha^0`
00010       :math:`x`                           :math:`\alpha^1`    
00100       :math:`x^2`                         :math:`\alpha^2`
01000       :math:`x^3`                         :math:`\alpha^3`    
10000       :math:`x^4`                         :math:`\alpha^4`    
00101       :math:`x^2+1`                       :math:`\alpha^5`     
01010       :math:`x^3+x`                       :math:`\alpha^6`
10100       :math:`x^4+x^2`                     :math:`\alpha^7`
01101       :math:`x^3+x^2+1`                   :math:`\alpha^8`
11010       :math:`x^4+x^3+x`                   :math:`\alpha^9`
10001       :math:`x^4+1`                       :math:`\alpha^{10}`
00111       :math:`x^2+x+1`                     :math:`\alpha^{11}`
01110       :math:`x^3+x^2+x`                   :math:`\alpha^{12}`
11100       :math:`x^4+x^3+x^2`                 :math:`\alpha^{13}`
11101       :math:`x^4+x^3+x^2+1`               :math:`\alpha^{14}`
11111       :math:`x^4+x^3+x^2+x+1`             :math:`\alpha^{15}`
11011       :math:`x^4+x^3+x+1`                 :math:`\alpha^{16}`
10011       :math:`x^4+x+1`                     :math:`\alpha^{17}`
00011       :math:`x+1`                         :math:`\alpha^{18}`
00110       :math:`x^2+x`                       :math:`\alpha^{19}`
01100       :math:`x^3+x^2`                     :math:`\alpha^{20}`
11000       :math:`x^4+x^3`                     :math:`\alpha^{21}`
10101       :math:`x^4+x^2+1`                   :math:`\alpha^{22}`
01111       :math:`x^3+x^2+x+1`                 :math:`\alpha^{23}`
11110       :math:`x^4+x^3+x^2+x`               :math:`\alpha^{24}`
11001       :math:`x^4+x^3+1`                   :math:`\alpha^{25}`
10111       :math:`x^4+x^2+x+1`                 :math:`\alpha^{26}`
01011       :math:`x^3+x+1`                     :math:`\alpha^{27}`
10110       :math:`x^4+x^2+x`                   :math:`\alpha^{28}`
01001       :math:`x^3+1`                       :math:`\alpha^{29}`
10010       :math:`x^4+x`                       :math:`\alpha^{30}`
======   =================================  ============================

Note that :math:`\alpha^{31}=1`. 

.. graphviz::

        digraph m1 {
        graph [label="polynomial m1(x)", splines=ortho];
        0 [label="input", shape=none];
	1 [label="output",shape=none];
        a [label="x",shape=box];
        b [label="x2",shape=box];
        c [label="x3",shape=box];
        d [label="x4",shape=box];
        e [label="x5",shape=box];
        E[label="",shape=circle];
	  A[label="+",shape=doublecircle];
	  B[label="",shape=circle];
	  C[label="+",shape=doublecircle];
	  D[label="",shape=circle];
	  E1[label="",shape=circle];
        
        {rank=same; 0->A;};
        {rank=same; D;B;E1};
	D->B [constraint=false]
        D->C
        {rank=same;A->a->b->C->c->d->e->E};
	E->E1 [constraint=false];
	{rank=same;E->1};
	{rank=same;E1->D [constraint=false]};

        {B->A };
        }

The elements obtained above can also be calculated by hand, for example, :math:`\alpha^{25}`
can be obtained by first, set :math:`p(\alpha) = \alpha^5+\alpha^2+1=0` then solve for it 
using the table above,

.. math::
        
        \alpha^5+\alpha^2+1 = 0 \\
        \alpha^5 = \alpha^2+1 \\
        \alpha^{25}=(\alpha^5)^5 = (\alpha^2+1)^5 = (\alpha^2+1)^2(\alpha^2+1)^2(\alpha^2+1) \\
        \alpha^{25}=(\alpha^4+1)^2(\alpha^2+1) \\
                   =(\alpha^8+1)(\alpha^2+1) \\
                   =(\alpha^3\alpha^5+1)(\alpha^2+1) \\
                   =(\alpha^3(\alpha^2+1)+1)(\alpha^2+1) \\
                   =(\alpha^5+\alpha^3+1)(\alpha^2+1) \\
                   =\alpha^7+\alpha^3+(\alpha^2+1) \\
                   =\alpha^7+\alpha^5+\alpha^3 \\
                   = x^4+x^2+x^2+1+x^3 = x^4+x^3+1 \\


The result agrees with what is obtained numerically by MATLAB/Octave. I think it is fine just to
randomly verify the result for couple of elements after :math:`\alpha^5`.

Next is to get the generator polynomial by performing the calculation for minimal polynomials,
:math:`m_1(x)=p(x), m_3(x)` and :math:`m_5(x)`, that is the root based on 
:math:`\alpha, \alpha_3` and :math:`\alpha^5`
because I need :math:`g(x)=m_1(x)m_3(x)m_5(x)` for this exercise. I can avoid the tedious calculation
by opting to use the tabulated generator polynomials of :math:`(n,k,d)` BCH code. For the
:math:`(31,16,7), t=3`, :math:`m_3(x)=x^5+x^4+x^3+x^2+1`, and :math:`m_5(x)=x^5+x^4+x^2+x+1`.

.. math::
        
        g(x)=LCM[m_1(x)m_3(x)m_5(x)] \\
        = LCM[(x^5+x^2+1)(x^5+x^4+x^3+x^2+1)(x^5+x^4+x^2+x+1)] 

Using MATLAB/Octave's *conv* to multiply the polynomial,

.. math::

        g(x) = x^{15}+ x^{11}+x^{10}+x^9+ x^8+x^7+ x^5+x^3 + x^2+x+1

This matches to the tabulated octal table value, :math:`(107657)_8 = 001 000 111 110 101 111`.
I can verify that :math:`g(x) | (x^{31} + 1)` using Octave's *deconv* operation. This is to
confirm that any irreducible polynomial over GF(2) of degree :math:`m` divides :math:`X^{2^m-1}+1`.
        
.. example with graph
.. graphviz::

        digraph m3 {
        graph [label="polynomial m3(x)", splines=ortho];
        0 [label="input", shape=none];
	1 [label="output",shape=none];
        a [label="x",shape=box];
        b [label="x2",shape=box];
        c [label="x3",shape=box];
        d [label="x4",shape=box];
        e [label="x5",shape=box];
        E[label="",shape=circle];
	  A[label="+",shape=doublecircle];
	  B[label="",shape=circle];
	  C[label="+",shape=doublecircle];
	  D[label="",shape=circle];
	  I[label="",shape=circle];
	  H[label="",shape=circle];
	  E1[label="",shape=circle];
	  G[label="+",shape=doublecircle];
	  F[label="+",shape=doublecircle];
        
        {rank=same; 0->A;};
        {rank=same; D;B;E1;H;I};
	D->B [constraint=false]
        D->C
        {rank=same;A->a->b->C->c->G->d->F->e->E};
	E->E1 [constraint=false];
	{rank=same;E->1};
	{rank=same;E1->H->I->D [constraint=false]};
        H->F 
        I->G 
        {B->A };
        }

.. graphviz::

        digraph m5 {
        graph [label="polynomial m5(x)", splines=ortho];
        0 [label="input", shape=none];
	1 [label="output",shape=none];
        a [label="x",shape=box];
        b [label="x2",shape=box];
        c [label="x3",shape=box];
        d [label="x4",shape=box];
        e [label="x5",shape=box];
        E[label="",shape=circle];
	  A[label="+",shape=doublecircle];
	  B[label="",shape=circle];
	  C[label="+",shape=doublecircle];
	  D[label="",shape=circle];
	  I[label="+",shape=doublecircle];
	  H[label="",shape=circle];
	  E1[label="",shape=circle];
	  G[label="+",shape=doublecircle];
	  F[label="",shape=circle];
        
        {rank=same; 0->A;};
        {rank=same; D;B;E1;H;F};
	D->B [constraint=false]
        D->C
        {rank=same;A->a->C->b->G->c->d->I->e->E};
	E->E1 [constraint=false];
	{rank=same;E->1};
	{rank=same;E1->H->F->D [constraint=false]};
        H->I 
        F->G 
        {B->A };
        }

By definition, a t-error-correcting BCH code of lengt :math:`2^m-1` having a binary *n-tuple* 
:math:`u(X)=u_0+u_1+\cdots+u_{n-1}` is a code word iff :math:`u(X)` has :math:`\alpha,\alpha^2,
\cdots,\alpha^{2t}` as roots, that is,

.. math::

        u(\alpha^i) = u_o + u_1(\alpha^i) + u_2(\alpha^{2i}) + \cdots + u_{n-1}(\alpha^{(n-1)i}) = 0

and for this exercise,         

.. math::

        u(\alpha) = u_o + u_1(\alpha) + u_2(\alpha^2) + \cdots + u_{n-1}(\alpha^{30}) = 0  \\
        u(\alpha^3) = u_o + u_1(\alpha^3) + u_2(\alpha^{6}) + \cdots + u_{n-1}(\alpha^{90}) = 0 \\
        u(\alpha^5) = u_o + u_1(\alpha^5) + u_2(\alpha^{10}) + \cdots + u_{n-1}(\alpha^{150}) = 0

note that the power of :math:`\alpha` will wrap on this finite field, for example, 
:math:`\alpha^{35} = \alpha^{31} \alpha^4 = \alpha^{4}`. Put it in matrix form,

.. math::

        (u_0 u_1 \cdots u_{n-1})  
        \left [
        \begin{array}{cc}
        1 & 1 & 1 \\
        \alpha & \alpha^3 & \alpha^5 \\
        \cdots & \cdots & \cdots \\
        \alpha^{30} & (\alpha^3)^{30} & (\alpha^5)^{30}
        \end{array}
        \right] = 0 
        
The equation above is in the form,

.. math::

        UH^t = 0

.. According the parity-check matrix will be something like this,

.. .. math:: 

..        H^t =
..        \left[
..        \begin{array}{cc}
..        1 & 1 & 1 \\
..        \alpha & \alpha^3 & \alpha^5 \\
..        \cdots & \cdots & \cdots \\
..        \alpha^{30} & (\alpha^3)^{30} & (\alpha^5)^{30}
..        \end{array}
..        \right]

..        H = 
..        \left[
..        \begin{array}{cc}
..        1 & \alpha & \alpha^2 & \cdots & \alpha^{30} \\
..        1 & \alpha^3 & \alpha^6 & \cdots & (\alpha^3)^{30} \\
..        1 & \alpha^5 & \alpha^{10} & \cdots & (\alpha^5)^{30} \\
..        \end{array}
..        \right]

note :math:`(\alpha^i)^0 = 1`. The transpose of the parity-check matric, :math:`H` is a 31x15 matrix.
It will follow that if :math:`U=(u_0,u_1,\cdots,u_{31})` is a code word, then :math:`UH^t = 0`.
:math:`\alpha^3 \equiv x^i mod(m_3(x))` and so on.

Each column of power of :math:`\alpha` is arranged below for :math:`H^t` parity check matrix. It
is not important as to whether to go for head first or bottom first as long as it stays consistent.
The matrix below has the highest power of :math:`\alpha` at its top row.

.. math::

         H^t=
        \left[
        \begin{array}{cc}
        1   0   0   1   0& 1 0 1 1 0 & 1 0 1 1 1 \\
        0   1   0   0   1& 1 1 0 0 1 & 1 1 0 0 0 \\
        1   0   1   1   0& 1 0 1 0 1 & 1 1 0 1 1 \\
        0   1   0   1   1& 0 0 1 1 0 & 0 0 1 1 1 \\
        1   0   1   1   1& 1 1 0 1 1 & 0 1 0 1 0 \\
        1   1   0   0   1& 1 1 1 0 0 & 0 0 0 1 0 \\
        1   1   1   1   0& 1 0 0 0 1 & 0 1 0 1 1 \\
        0   1   1   1   1& 1 0 1 0 0 & 1 0 1 0 1 \\
        1   0   1   0   1& 1 0 0 0 0 & 1 0 0 1 1 \\
        1   1   0   0   0& 0 0 0 1 0 & 0 1 1 1 0 \\
        0   1   1   0   0& 0 1 0 0 1 & 1 0 1 0 0 \\
        0   0   1   1   0& 1 0 1 1 1 & 0 0 1 0 0 \\
        0   0   0   1   1& 0 1 1 1 1 & 1 0 1 1 0 \\
        1   0   0   1   1& 0 1 1 0 0 & 0 1 1 1 1 \\
        1   1   0   1   1& 1 0 0 1 1 & 0 0 0 1 1 \\
        1   1   1   1   1& 1 1 1 0 1 & 1 1 1 0 0 \\
        1   1   1   0   1& 0 0 1 1 1 & 0 1 1 0 1 \\
        1   1   1   0   0& 0 1 1 0 1 & 0 1 0 0 0 \\
        0   1   1   1   0& 0 0 1 0 1 & 0 1 0 0 1 \\
        0   0   1   1   1& 0 0 1 0 0 & 1 1 1 1 0 \\
        1   0   0   0   1& 1 0 0 1 0 & 0 0 1 1 0 \\
        1   1   0   1   0& 0 1 0 1 1 & 1 1 1 0 1 \\
        0   1   1   0   1& 1 1 1 1 0 & 1 1 0 1 0 \\
        1   0   1   0   0& 1 1 0 0 0 & 1 0 0 0 0 \\
        0   1   0   1   0& 0 0 0 1 1 & 1 0 0 1 0 \\
        0   0   1   0   1& 1 1 1 1 1 & 1 1 0 0 1 \\
        1   0   0   0   0& 0 1 1 1 0 & 0 1 1 0 0 \\
        0   1   0   0   0& 1 1 0 1 0 & 1 1 1 1 1 \\
        0   0   1   0   0& 0 1 0 1 0 & 1 0 0 0 1 \\
        0   0   0   1   0& 0 1 0 0 0 & 0 0 1 0 1 \\
        0   0   0   0   1& 0 0 0 0 1 & 0 0 0 0 1 
        \end{array}
        \right]

MATLAB/Octave is used to generate the power of :math:`\alpha` above,

.. code-block::
   :linenos:

        % minimum polynomials
        m1=[1 0 0 1 0 1];
        m3=[1 1 1 1 0 1];
        m5=[1 1 0 1 1 1];
        % generator poly
        gx=mod(conv(conv(m1,m3),m5),2);
        % will produce gx=[1 0 0 0 1 1 1 1 1 0 1 0 1 1 1 1];
        for i=1:n
        	 j=mod(3*i,31);
        	 l=mod(5*i,31);
        	 if j==0
        		j=31;
        	 end
        	 if l == 0
        		l=31;
        	 end
        	 R3(i,:)=r1(j,:);
        	 R5(i,:)=r1(l,:);
        end
 
 
The parity check is not in systematic form. 

.. .. math::

..        H = 
..        \left[
..        \begin{array}{cc|c}
..        P_{k,n-k}^t &  I_{n-k} 
..        \end{array}
..        \right]
..        =\left [
..        \begin{array}{c|c}
..	 1     1     0     0     1     0     0     0     0     1     1     1     1     0     0     0     & 1000 0000 0000 000 \\
..	 0     1     1     0     0     1     0     0     0     0     1     1     1     1     0     0     & 0100 0000 0000 000 \\
..	 0     0     1     1     0     0     1     0     0     0     0     1     1     1     1     0     & 0010 0000 0000 000 \\
..	 0     0     0     1     1     0     0     1     0     0     0     0     1     1     1     1     & 0001 0000 0000 000 \\
..	 1     1     0     0     0     1     0     0     1     1     1     1     1     1     1     1     & 0000 1000 0000 000 \\
..	 1     0     1     0     1     0     1     0     0     0     0     0     0     1     1     1     & 0000 0100 0000 000 \\
..	 1     0     0     1     1     1     0     1     0     1     1     1     1     0     1     1     & 0000 0010 0000 000 \\
..	 1     0     0     0     0     1     1     0     1     1     0     0     0     1     0     1     & 0000 0001 0000 000 \\
..	 1     0     0     0     1     0     1     1     0     0     0     1     1     0     1     0     & 0000 0000 1000 000 \\
..	 0     1     0     0     0     1     0     1     1     0     0     0     1     1     0     1     & 0000 0000 0100 000 \\
..	 1     1     1     0     1     0     1     0     1     0     1     1     1     1     1     0     & 0000 0000 0010 000 \\
..	 0     1     1     1     0     1     0     1     0     1     0     1     1     1     1     1     & 0000 0000 0001 000 \\
..	 1     1     1     1     0     0     1     0     1     1     0     1     0     1     1     1     & 0000 0000 0000 100 \\
..	 1     0     1     1     0     0     0     1     0     0     0     1     0     0     1     1     & 0000 0000 0000 010 \\
..	 1     0     0     1     0     0     0     0     1     1     1     1     0     0     0     1     & 0000 0000 0000 001 \\
..        \end{array}
..        \right]

Likewise the generator matrix can be obtained from the generator polynomial, :math:`g(x)`,

.. math::

        G = 
        \left[
        \begin{array}{cc}
        I_{k} &  P_{k,n-k} 
        \end{array}
        \right]
        =\left[
        \begin{array}{c|c}
	     1000000000000000&100011111010111 \\
	     0100000000000000&110010000111100 \\
	     0010000000000000&011001000011110 \\
	     0001000000000000&001100100001111 \\
	     0000100000000000&100101101010000 \\
	     0000010000000000&010010110101000 \\
	     0000001000000000&001001011010100 \\
	     0000000100000000&000100101101010 \\
	     0000000010000000&000010010110101 \\
	     0000000001000000&100010110001101 \\
	     0000000000100000&110010100010001 \\
	     0000000000010000&111010101011111 \\
	     0000000000001000&111110101111000 \\
	     0000000000000100&011111010111100 \\
	     0000000000000010&001111101011110 \\
	     0000000000000001&000111110101111 
        \end{array}
        \right ]

since :math:`G \perp H`, :math:`GH^t = 0`. The parity check matrix
obtained this way can be easily implemented in hardware using the
shift registers for error detection. 

.. code-block::

        for i=1:n [a,r(i,:)]= deconv(I(i,:),gx);end
        r=r(:,17:31);r=mod(r,2);
        p=r(1:16,:); %partity bits
        % generator matrix
        G=[eye(16) p];
        mod(G*h,2) %  zeros

Decoder and errors locator
==========================

From the row of :math:`H`, there are :math:`2^{15}` syndromes
and :math:`1+\binom{n}{1} + \binom{n}{2} + \binom{n}{3} = 4992` 
correctable error patterns for this implementation.

If :math:`\psi_i:i=1,3,5` are the syndromes each having 5 bits and representing the columns of
the transpose parity check matrix, :math:`H^t`,

.. math::
        
        H^t =
        \left[
        \begin{array}{cc}
        1 & 1 & 1 \\
        \alpha & \alpha^3 & \alpha^5 \\
        \cdots & \cdots & \cdots \\
        \alpha^{30} & (\alpha^3)^{30} & (\alpha^5)^{30}
        \end{array}
        \right]

and :math:`w` is the received coded word, then :math:`wH^t=[w(\alpha), w(\alpha^3), w(\alpha^5)] = [\psi_1, \psi_3, \psi_5]` is
the syndrome of this code word. For a single bit error, :math:`e(x)=x^i`, the syndrome is :math:`wH^t=[(\alpha)^i,(\alpha^3)^i,(\alpha^5)^i]`.
If there are two errors in the code word, :math:`e(x)=x^i+x^j, i\neq j`, the syndrome
becomes :math:`[\psi_1,\psi_3,\psi_5]=[(\alpha)^i+\alpha^j,(\alpha^3)^i+(\alpha^3)^j,(\alpha^5)^i+(\alpha^5)^j]`.
Eventually it will lead to system of equations to be solved for a polynomial :math:`x(\psi_i)`. It is
called the error-locator polynomial. This polynomial is dependent on error bit positions.

To test the error correction capability of this exercise,

.. code-block::

        v=dec2bin(0:2^16-1)-'0'; % input code word
        u=mod(v*G,2); % BCH coded word

        >> mod(u(1000,:)*h,2)

        ans =

         0 0 0 0 0 0 0 0 0 0 0 0 0 0 0

Suppose that a received coded word, :math:`w` has one bit error, say bit 14,

.. code-block::

        w=u(1000,:); % a coded word 
        w(14)=0; %was 1, set to 0 to simulate error

        >> mod(w*h,2)
        ans =
           1 0 0 1 1 0 1 1 0 0 0 1 1 1 1

The output from :math:`wH^t` produces the syndrome identical to row 14 of :math:`H^t`. The corrected
code word is then :math:`w+I(14)`, where :math:`I(14)` is the 14th row of the identity matrix.
Now what happens if two bit errors, say another bit at bit 0,

.. code-block::

        w(1)=1; % was 0, set to 1 as error. Now we have bit0,14 as error bits
        >> mod(w*h,2)
        ans =
           0 0 0 0 1 1 1 0 1 0 1 1 0 0 0
        >> mod(h(1,:)+h(14,:),2)
        ans =
           0 0 0 0 1 1 1 0 1 0 1 1 0 0 0

         
Evidently the syndrome is the same as :math:`H^t(14)+H^t(1)`, sum of first and 14th row. The 
corrected bits are then :math:`I(14)+I(1)`, 1st and 14th row of :math:`I` matrix.
This can go on up to 3-bits error, but how do I know which bit or bits are in error ? The 
possibility is binomial sum as stated earlier because error can be any number of bits and
at any positions. Locating the error positions is the hardest part of the implementation.

.. Some reformulation is needed for practical implementation.
.. Suppose that the received code word :math:`W(x)` from the transmitted code word, :math:`U(x)`,

.. .. math::

..        U(x)=u_0+u_1x+u_2x^2+ \cdots + u_{n-1}x^{n-1} \\
..        W(x) = U(x) + e (x) 

.. The syndrome from :math:`W(x)` is therefore,

.. .. math::

..         rH^T = (U + e)H^T = UH^T + eH^T = 0 + eH^T = S(s_1, s_2, \cdots, s_{2t})

.. Syndrome of :math:`2t` tuple depends only on error bits. For this implementation, I will
.. have :math:`S(s_1,s_2,\cdots,s_6)`

While there are several algorithms for error locating, they are not always efficient for
hardware implementation. I tried out some algorithms on paper and pencil that work well, but
I have no idea how to translate it into hardware. I will leave those to the experts. One
possible algorithm that I like is this, let :math:`w(x)` be the received code word where
:math:`w(x)=u(x)+e(x)`. :math:`u(x)` and :math:`e(x)` are the transmitted code word and
error respectively.

. Calculate syndrome :math:`s(x) = w(x) mod g(x)`
. For :math:`i \ge 0`, calculate :math:`s_i(x)=x^i mod g(x)` until :math:`s_j(x)` is found 
where weight of :math:`s_j(x) \le t`. 
. Once :math:`s_i(x)` is located, :math:`e(x)=x^{n-j} mod (x^n + 1)` are the most likely
error bits.



