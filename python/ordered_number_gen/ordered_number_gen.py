from math import *
from random import *
io_file = open("./ordered.bin", "w+")
bit = 32

def dec_to_bin (num, bits):
   out = ''
   if num < 0:
      num = 2**bits + num
   for i in range(int(bits)):
      current = bits-i-1
      div = 2**current
      bi = int(num/div)
      num = num%div
      out = out+str(bi)
   return out
def generate_number (num):
   global bit
   global io_file
   for i in range(num):
      binary = dec_to_bin(i, bit)
      io_file.write(binary + '\n')


generate_number (64)
