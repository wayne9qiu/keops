
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Example of keops reduction using the generic syntax. This example corresponds
to the one described in the documentation file generic_syntax.md
"""

import os.path
import sys
sys.path.append(os.path.dirname(os.path.abspath(__file__)) + (os.path.sep + '..')*2)

import torch
from torch.autograd import Variable, grad

import time

from pykeops.torch.generic_sum import GenericSum

# this example computes the following tensor operation :
# inputs :
#   p   : a scalar (antered as a 1x1 tensor)
#   a   : a 1000x1 tensor, with entries denoted a_j 
#   x   : a 1500x3 tensor, with entries denoted x_i^u
#   y   : a 1000x3 tensor, with entries denoted y_j^u
# output :
#   c   : a 1500x3 tensor, with entries denoted c_i^u, such that
#   c_i^u = sum_j (p-y_j)^2 exp(a_i^u+b_j^u)


aliases = ["p=Pm(0,1)","a=Vy(1,1)","x=Vx(2,3)","y=Vy(3,3)"]
formula = "Square(p-a)*Exp(x+y)"
signature   =   [ (3, 0), (1, 2), (1, 1), (3, 0), (3, 1) ]
sum_index = 0       # 0 means summation over j, 1 means over i 

p = Variable(torch.randn(1,1), requires_grad=True)
a = Variable(torch.randn(1000,1), requires_grad=True)
x = Variable(torch.randn(1500,3), requires_grad=True)
y = Variable(torch.randn(1000,3), requires_grad=True)

start = time.time()
c = GenericSum.apply("auto",aliases,formula,signature,sum_index,p,a,x,y)

print("time to compute c on cpu : ",round(time.time()-start,2)," seconds")
print("c =",c)


# testing the gradient : we take the gradient with respect to y. In fact since 
# c is not scalar valued, "gradient" means in fact the adjoint of the differential
# operator, which is a linear operation that takes as input a new tensor with same
# size as c and outputs a tensor with same size as y

# new variable of size 1500x3 used as input of the gradient
e = Variable(torch.randn(1500,3), requires_grad=True)
# call to the gradient
start = time.time()
d = grad(c,y,e)[0]
# remark : grad(c,y,e) alone outputs a length 1 tuple, hence the need for [0] at the end.

print("time to compute d on cpu : ",round(time.time()-start,2)," seconds")
print("grad(c,y,e)=",d)


# same operations performed on the Gpu. (this will of course only work if you have a Gpu)

# first transfer data on gpu
p,a,x,y,e = p.cuda(), a.cuda(), x.cuda(), y.cuda(), e.cuda()
# then call the operations
start = time.time()
c = GenericSum.apply("auto",aliases,formula,signature,sum_index,p,a,x,y)
print("time to compute c on gpu : ",round(time.time()-start,2)," seconds")
print("c =",c)
d = grad(c,y,e)[0]
print("time to compute d on gpu : ",round(time.time()-start,2)," seconds")
print("grad(c,y,e)=",d)
