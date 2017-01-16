.. title: BCH, an example of linear cyclic code
.. slug: bch_1_x_x4
.. date: 2017-01-08 23:39:17 UTC
.. tags: misc, mathjax, latex
.. category: math 
.. link: 
.. description: BCH code based on g(x)=1+x+x**4
.. type: text

Building on my last post on the simple Hamming linear cyclic code, I decide to push on for a little bit
more usefull class of cyclic code, the BCH code. This will be based on the same generator polynomial,
:math:`h(x)=1+x+x^4` using the powers of :math:`\beta` as worked out in the last post.

.. TEASER_END

One important class of cyclic codes is BCH codes. It is quite extensive and easy to decode and
because of that it is quite practical for its use in real-life application. By definition,
any :math:`r \ge 3, t \leq 2^{r-1}-1` there exists BCH error-correcting codes of length :math:`n=2^r -1`,
parity check length :math:`(n-k) \le rt`,  minimum distance :math:`d \ge 2t + 1` and
having dimension :math:`k \geq n-rt`. 

Some more field algebra
------------------------

The *minimal polynomial* of :math:`\alpha`, :math:`m_{\alpha}(x)` is the smallest polynomial in
:math:`K[x]` of smallest degree having :math:`\alpha` as a root, that is, if :math:`f(x)=a_0+
a_1x+a_2x^2+..+a_kx^k`, then :math:`f(\alpha)=a_0+a_1\alpha+a_2\alpha^2+..+a_k\alpha^k = 0`

The order of nonzero element :math:`\alpha` in :math:`GF(2^r)` is the smallest positive :math:`m`
such that :math:`\alpha^m = 1`. If :math:`\alpha` is of order :math:`2^r-1` then it is a *primitive*
element. If :math:`\alpha` has order :math:`m`, then :math:`\alpha` is a root of :math:`1+x^m`.
Relative to my previous post, defining :math:`\beta` as primitive element, :math:`\alpha=\beta^i`,
then :math:`\alpha^{2r-1}=(\beta^i)^{2r-1}= (\beta^{2r-1})^i = 1^i = 1`. :math:`\alpha` is therefore
a root of :math:`1+x^{2r-1}` and :math:`m_\alpha(x)` is a factor of :math:`1+x^{2r-1}`. This 
explains :math:`g(x) | (1+x^{15})` in the last post.

Base on the theorem that the set of all roots of :math:`m_\alpha(x)` is 
:math:`\{\alpha,\alpha^2,\alpha^4,..,\alpha^{2r-1}\}`, the single error-correcting BCH codes
will have the generator polynomial, :math:`g(x) = m_\alpha(x)`. The two error-correcting codes
will have the generator polynomial, :math:`g(x) =  m_\alpha(x)m_{\alpha^3}(x)`.
