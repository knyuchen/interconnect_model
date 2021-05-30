import math

global io_file
io_file = open("./same_latency.sv", "w+")


def single_21_cell (up_text, up_num, down_text, down_num, indi, up_pipe, down_pipe):
   io_file.write('   sl21_cell #(\n')
   io_file.write('      .INDI('+str(indi)+'),\n')   
   io_file.write('      .UP_PIPE('+str(up_pipe)+'),\n')   
   io_file.write('      .DOWN_PIPE('+str(down_pipe)+'),\n')   
   io_file.write('   )\n')
   io_file.write('   sl21_' + up_text +'_'+ str(up_num)+'_' + down_text+'_' + str(down_num) + '(\n')
   io_file.write('      .req_up(req_'+up_text+'_'+str(up_num)+'),\n')
   io_file.write('      .res_up(res_'+up_text+'_'+str(up_num)+'),\n')
   io_file.write('      .req_down0(req_'+down_text+'_'+str(down_num)+'),\n')
   io_file.write('      .res_down0(res_'+down_text+'_'+str(down_num)+'),\n')
   io_file.write('      .req_down1(req_'+down_text+'_'+str(down_num+1)+'),\n')
   io_file.write('      .res_down1(res_'+down_text+'_'+str(down_num+1)+'),\n')
   io_file.write('      .*\n')
   io_file.write('   );\n\n')

def single_11_cell (up_text, up_num, down_text, down_num, up_pipe, down_pipe):
   io_file.write('   sl11_cell #(\n')
   io_file.write('      .UP_PIPE('+str(up_pipe)+'),\n')   
   io_file.write('      .DOWN_PIPE('+str(down_pipe)+'),\n')   
   io_file.write('   )\n')
   io_file.write('   sl11_' + up_text +'_'+ str(up_num)+'_' + down_text+'_' + str(down_num) + '(\n')
   io_file.write('      .req_up(req_'+up_text+'_'+str(up_num)+'),\n')
   io_file.write('      .res_up(res_'+up_text+'_'+str(up_num)+'),\n')
   io_file.write('      .req_down(req_'+down_text+'_'+str(down_num)+'),\n')
   io_file.write('      .res_down(res_'+down_text+'_'+str(down_num)+'),\n')
   io_file.write('      .*\n')
   io_file.write('   );\n\n')

def single_row (num, up_text, up_num, down_text, down_num, indi, up_pipe, down_pipe):
   num_of_21 = int(num/2)
   num_of_11 = num%2
   for i in range (num_of_21):
      single_21_cell (up_text, up_num+i, down_text, down_num+2*i, indi, up_pipe, down_pipe)
   if num_of_11 != 0:
      single_11_cell (up_text, up_num+num_of_21, down_text, down_num+num-1, up_pipe, down_pipe)
   io_file.write('\n\n')

single_row (10, 'sys', 2, 'cis', 4, 5, 1, 2) 
