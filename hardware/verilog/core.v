module core(clk, inst, ofifo_valid, D_xmem, sfp_out, reset);
//Only contain corelet and SRAM in this file
/*
inst_q[33] = acc_q;        inst_q[32] = CEN_pmem_q;
inst_q[31] = WEN_pmem_q;   inst_q[30:20] = A_pmem_q;
inst_q[19]   = CEN_xmem_q; inst_q[18]   = WEN_xmem_q;
inst_q[17:7] = A_xmem_q;   inst_q[6]   = ofifo_rd_q;
inst_q[5]   = ififo_wr_q;  inst_q[4]   = ififo_rd_q;
inst_q[3]   = l0_rd_q;     inst_q[2]   = l0_wr_q;
inst_q[1]   = execute_q;   inst_q[0]   = load_q; 
*/
parameter bw = 4;
parameter col = 8;
parameter row = 8;
parameter psum_bw = 16;

input clk, reset;
input [33:0] inst;
input [bw*row-1:0] D_xmem;

output [col*psum_bw-1:0] sfp_out;
output ofifo_valid;

wire [psum_bw*row-1 : 0] pmem_in;
wire [bw*row-1:0] xmem_out;
wire [psum_bw*col-1 : 0] psum_out;
wire [10:0] xmem_A;
wire [10:0] pmem_A;
wire WEN_xmem;
wire CEN_xmem;
wire WEN_pmem;
wire CEN_pmem;

genvar i;

//Instruction
assign xmem_A   = inst[17:7];
assign WEN_xmem = inst[18];
assign CEN_xmem = inst[19];
assign pmem_A   = inst[30:20];
assign WEN_pmem = inst[31];
assign CEN_pmem = inst[32];

//Corelet
corelet  #(.bw(bw), .psum_bw(psum_bw), .col(col), .row(row)) corelet_instance(
    .clk(clk),
    .reset(reset),
    .xdata(xmem_out),
    .psum(psum_out),
    .inst(inst),
    .out(sfp_out),
    .pmem_in(pmem_in)
);


//Activation & Weight SRAM
sram_32b_w2048 #(.num(2048)) xmem_sram(
    .CLK(clk),
    .WEN(WEN_xmem),
    .CEN(CEN_xmem),
    .D(D_xmem),
    .A(xmem_A),
    .Q(xmem_out)
);

//Psum SRAM
sram_128b_w2048 #(.num(2048)) pmem_sram(
    .CLK(clk),
    .WEN(WEN_pmem),
    .CEN(CEN_pmem),
    .D(pmem_in),
    .A(pmem_A),
    .Q(psum_out)
);

endmodule
