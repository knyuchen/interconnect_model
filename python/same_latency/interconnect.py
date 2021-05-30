import math

global io_file
io_file = open("./same_latency.sv", "w+")


def single_21cell (up_text, up_num, down_text, down_num, indi, up_pipe, down_pipe):
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

def single_11cell (up_text, up_num, down_text, down_num, up_pipe, down_pipe):
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

single_21cell ('sys', 2, 'cis', 4, 5, 1, 2) 
single_11cell ('sys', 3, 'cis', 5,    1, 2) 
