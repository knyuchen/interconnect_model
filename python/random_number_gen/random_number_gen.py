from math import *
from random import *
io_file = open("./random.bin", "w+")
bit = 32

def generate_number (num):
   global bit
   global io_file
   for i in range(num):
      out = ''
      for j in range(bit):
         seed = random()
         if (seed < 0.5):
            out = out + '0'
         else:
            out = out + '1'
      io_file.write(out + '\n')


generate_number (64)
