module master (
input wire presetn,
input wire pclk,
input wire transfer,
input wire read,
input wire write,
input wire [8:0] apb_write_paddr,
input wire [7:0] apb_write_data,
input wire [8:0] apb_read_paddr,
input wire pready,
input wire pslverr,
input wire [7:0] prdata,
output reg psel1,
output reg psel2,
output reg penable,
output reg pwrite,
output reg [8:0] paddr,
output reg [7:0] pwdata,
output reg [7:0] apb_read_data_out
);

parameter IDLE = 2'b00;
parameter SETUP = 2'b01;
parameter ENABLE = 2'b10;
reg [1:0] state;
reg [1:0] next_state;

always @(posedge pclk or negedge presetn) begin
if (!presetn)
state <= IDLE;
else

state <= next_state;
end

always @(*) begin
case (state)
IDLE: begin
if (transfer)
next_state = SETUP;
else
next_state = IDLE;
end
SETUP: begin
next_state = ENABLE;
end
ENABLE: begin
if (pready)
next_state = (transfer) ? SETUP : IDLE;
else
next_state = ENABLE;
end
default: next_state = IDLE;
endcase
end

always @(*) begin

psel1 = 0;
psel2 = 0;
penable = 0;
pwrite = 0;
paddr = 9'b0;
pwdata = 8'b0;
case (state)
IDLE: begin

end
SETUP: begin
penable = 0;
if (read && !write) begin
paddr = apb_read_paddr;
psel1 = (apb_read_paddr[8] == 0);
psel2 = (apb_read_paddr[8] == 1);
pwrite = 0;
end
else if (write && !read) begin
paddr = apb_write_paddr;
psel1 = (apb_write_paddr[8] == 0);
psel2 = (apb_write_paddr[8] == 1);
pwrite = 1;
pwdata = apb_write_data;
end

end
ENABLE: begin
penable = 1;
if (pready) begin
if (read && !write) begin
apb_read_data_out = prdata;
end
end
end
endcase
end
endmodule
