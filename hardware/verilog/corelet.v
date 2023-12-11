module corelet(clk, reset, xdata, inst, psum, out, pmem_in);
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
input [psum_bw*row-1 : 0] psum;
input [row*bw-1 : 0] xdata;
input [33:0] inst;
output [psum_bw*col-1 : 0] out;
output [psum_bw*col-1 : 0] pmem_in;


//l0 instance, severed as Input fifo
wire l0_wr, l0_rd;
wire [row*bw-1:0] l0_out;
wire l0_full; 
wire l0_ready;

//mac array, load weight into the array
wire [1 : 0] inst_w; 
wire [col-1 : 0] valid; //mac_array provide valid signal to ofifo wr, last row signal
wire [psum_bw*col-1 : 0] mac_out; // final row of psum to ofifo
wire [psum_bw*col-1 : 0] in_n_temp;

//ofifo instance
wire [col-1 : 0] ofifo_wr; 
wire [col*psum_bw-1 : 0] ofifo_in;
wire [col*psum_bw-1 : 0] ofifo_out;
wire ofifo_full;
wire ofifo_ready;
wire ofifo_valid;

//SFP instance
wire sfp_acc;
wire sfp_relu;
wire [psum_bw-1:0] sfp_thres;
wire [psum_bw*col-1 : 0] sfp_in;
wire [psum_bw*col-1 : 0] sfp_out;

assign l0_wr = inst[2];
assign l0_rd = inst[3];

assign out = sfp_out;
assign pmem_in = ofifo_out;

l0 #(.bw(bw), .row(row)) l0_instance(
    .clk(clk),
    .reset(reset),
    .wr(l0_wr),
    .rd(l0_rd),
    .in(xdata),
    .out(l0_out),
    .o_full(l0_full), 
    .o_ready(l0_ready)
);


assign inst_w = inst[1:0];
assign in_n_temp = 128'b0;

mac_array #(.bw(bw), .psum_bw(psum_bw), .col(col), .row(row)) mac_array_instance(
    .clk(clk),
    .reset(reset),
    .in_w(l0_out),
    .in_n(in_n_temp), 
    .inst_w(inst_w),
    .out_s(mac_out),
    .valid(valid)
);


assign ofifo_in = mac_out;
assign ofifo_rd = inst[6];
assign ofifo_wr = valid;

ofifo #(.bw(psum_bw), .col(col)) ofifo_instance(
    .clk(clk),
    .reset(reset),
    .wr(ofifo_wr),
    .rd(ofifo_rd),
    .in(ofifo_in),
    .o_full(ofifo_full),
    .o_ready(ofifo_ready),
    .o_valid(ofifo_valid),
    .out(ofifo_out)
);

genvar i;

assign sfp_in = psum;
assign sfp_acc = inst[33];
assign sfp_relu = 1'b0;
assign sfp_thres = 16'b0;

//SFP receive data from psum_mem
for (i=1; i < col+1 ; i=i+1) begin : col_num
    sfp #(.psum_bw(psum_bw), .bw(bw)) sfp_instance(
        .clk(clk),
        .reset(reset),
        .relu(sfp_relu),
        .acc(sfp_acc),
        .in(sfp_in[i*psum_bw-1 : (i-1)*psum_bw]), 
        .thres(sfp_thres),
        .out(sfp_out[i*psum_bw-1 : (i-1)*psum_bw])
    );
end

endmodule
