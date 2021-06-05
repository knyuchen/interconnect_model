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
   return (num_of_21 + num_of_11)


def single_pyramid (num, text, indi, up_pipe, down_pipe):
   num_of_row = math.ceil(math.log2(num))
   current_down_num = 0
   next_num = num
   current_up_num = num
   current_indi = indi
   #bottom up
   for i in range (num_of_row):
      next_num = single_row (next_num, text, current_up_num, text, current_down_num, current_indi, up_pipe[i], down_pipe[i])     
      current_down_num = current_up_num
      current_up_num = current_up_num + next_num
      current_indi = current_indi + 1
   return current_down_num

def find_num (num):
   final = num #top & bottom
   while (num > 1):
      num = math.ceil(num/2)
      final = final + num
   return final

def intermediate_logic (num, logic, name):
   for i in range (num):
      io_file.write('   ' + logic + '   ' + name + '_' + str (i) + ';\n')
   io_file.write('\n\n')  

def module_header (num, up_name, down_name):
    io_file.write('module sl_interconnect_' + str(num) +' (')
    io_file.write('\n')
    io_file.write('   input     SL_REQ   ' + up_name + '_req,\n')
    io_file.write('   output    SL_RES   ' + up_name + '_res,\n')
    for i in range (num) :
        io_file.write('   output    SL_REQ   ' + down_name + '_req_' + str(i) + ',\n')
        io_file.write('   input     SL_RES   ' + down_name + '_res_' + str(i) + ',\n')
    io_file.write('   input   clk,')
    io_file.write('\n')
    io_file.write('   input   rst_n')
    io_file.write('\n')
    io_file.write(');')

    io_file.write('\n')
    io_file.write('\n')
def module_finish():
    io_file.write('endmodule\n')
def inter_name (total, num, up_name, down_name, inter_name):
    io_file.write('assign  ' + up_name + '_res = ' + inter_name + '_res_' + str (total-1) + ';\n')
    io_file.write('assign  ' + inter_name + '_req_' + str(total-1) + ' = ' + up_name + '_req;\n')
    for i in range (num):
        io_file.write('assign  ' + down_name + '_req_' + str(i) +' = ' + inter_name + '_req_' + str(i) + ';\n')
        io_file.write('assign  ' + inter_name + '_res_' + str(i) +' = ' + down_name + '_res_' + str(i) + ';\n')
    io_file.write('\n')

def interconnect_module (num, up_name, down_name, indi, up, down):
    module_header (num, up_name, down_name)
    total = find_num(num)
    intermediate_logic (num, 'SL_REQ', 'inter_req')
    intermediate_logic (num, 'SL_RES', 'inter_res')
    inter_name(total, num, up_name, down_name, 'inter')        
    single_pyramid(num, 'inter', indi, up, down)
    module_finish()

up = [1, 1, 2, 2]
down = [2, 2, 1, 1]
#print(find_num (10))
#intermediate_logic (10, 'pp', 'qq')
#single_pyramid (10, 'sys', 5, up, down)

interconnect_module (4, 'host', 'slave', 12, up, down)

