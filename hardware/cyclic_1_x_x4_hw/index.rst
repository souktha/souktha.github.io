.. title: Simple Cyclic Hamming (15,11,3) FEC
.. slug: cyclic_1_x_x4_hw
.. date: 2016-12-22 00:17:42 UTC
.. tags: hardware, mathjax, latex
.. category: FPGA
.. link: 
.. description: 
.. type: text

This post is the implementation part of the my post on "simple cyclic Hamming code"__

.. _code: output/misc/cyclic_1_x_x4

where I did some math workout on this type of forward error-correction code (FEC). I am doing
it for fun since I think it is simple enough to implement it in FPGA. The generator
for this exercise is :math:`g(x)=1+x+x4` for an :math:`(n,k,d) \equiv (15,11,3)` code.

.. TEASER_END
