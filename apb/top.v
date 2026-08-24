module top (
input wire pclk,
input wire presetn,
input wire transfer,
input wire read,
input wire write,
input wire [8:0] apb_write_paddr,
input wire [7:0] apb_write_data,
input wire [8:0] apb_read_paddr,
output wire pslverr,
output wire [7:0] apb_read_data_out
);

wire penable;
wire pwrite;
wire [8:0] paddr;
wire [7:0] pwdata;
wire [7:0] prdata1, prdata2;
wire pready1, pready2, pready;
wire psel1, psel2;

master master_inst (
.presetn(presetn),
.pclk(pclk),
.transfer(transfer),
.read(read),
.write(write),
.apb_write_paddr(apb_write_paddr),
.apb_read_paddr(apb_read_paddr),
.apb_write_data(apb_write_data),
.pready(pready),
.pslverr(pslverr),
.prdata(prdata1 | prdata2),
.psel1(psel1),
.psel2(psel2),
.penable(penable),
.paddr(paddr),
.pwrite(pwrite),
.pwdata(pwdata),
.apb_read_data_out(apb_read_data_out)
);

slave slave1_inst (
.pclk(pclk),
.presetn(presetn),
.psel(psel1),
.penable(penable),
.pwrite(pwrite),
.paddr(paddr[7:0]),
.pwdata(pwdata),
.prdata(prdata1),
.pready(pready1),
.pslverr(pslverr)
);

slave slave2_inst (
.pclk(pclk),
.presetn(presetn),
.psel(psel2),
.penable(penable),
.pwrite(pwrite),
.paddr(paddr[7:0]),
.pwdata(pwdata),
.prdata(prdata2),
.pready(pready2),
.pslverr(pslverr)
);

assign pready = (psel1 && pready1) || (psel2 && pready2);
endmodule
