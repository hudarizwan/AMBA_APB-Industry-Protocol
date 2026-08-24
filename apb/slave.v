module slave (
input wire pclk,
input wire presetn,
input wire psel,
input wire penable,
input wire pwrite,
input wire [7:0] paddr,
input wire [7:0] pwdata,
output reg [7:0] prdata,
output reg pready,
output reg pslverr
);

reg [7:0] memory [255:0];

reg [7:0] addr_reg;

always @(posedge pclk or negedge presetn) begin
if (!presetn) begin
pready <= 1'b0;
pslverr <= 1'b0;
addr_reg <= 8'b0;
end else begin

pready <= 1'b0;
pslverr <= 1'b0;
if (psel) begin

if (!pwrite && penable) begin
if (paddr < 8'd256) begin
addr_reg <= paddr;
prdata <= memory[paddr];
pready <= 1'b1;

end else begin
pslverr <= 1'b1;
pready <= 1'b1;
end
end

if (pwrite && penable) begin
if (paddr < 8'd256) begin
memory[paddr] <= pwdata;
pready <= 1'b1;
end else begin
pslverr <= 1'b1;
pready <= 1'b1;
end
end
end
end
end
endmodule
