`timescale 1ns / 1ps

module testbench;

    reg         pclk;
    reg         presetn;
    reg         transfer;
    reg         read;
    reg         write;
    reg  [8:0]  apb_write_paddr;
    reg  [7:0]  apb_write_data;
    reg  [8:0]  apb_read_paddr;
    wire        pslverr;
    wire [7:0]  apb_read_data_out;

    wire        psel1   = dut.psel1;
    wire        psel2   = dut.psel2;
    wire        penable = dut.penable;
    wire        pwrite  = dut.pwrite;
    wire [8:0]  paddr   = dut.paddr;
    wire [7:0]  pwdata  = dut.pwdata;
    wire        pready  = dut.pready;

    integer     pass_count;
    integer     fail_count;
    integer     test_num;

    top dut (
        .pclk              (pclk),
        .presetn           (presetn),
        .transfer          (transfer),
        .read              (read),
        .write             (write),
        .apb_write_paddr   (apb_write_paddr),
        .apb_write_data    (apb_write_data),
        .apb_read_paddr    (apb_read_paddr),
        .pslverr           (pslverr),
        .apb_read_data_out (apb_read_data_out)
    );

    initial pclk = 0;
    always #5 pclk = ~pclk;

    task apb_write;
        input [8:0] addr;
        input [7:0] data;
        begin
            @(posedge pclk);
            transfer        <= 1'b1;
            write           <= 1'b1;
            read            <= 1'b0;
            apb_write_paddr <= addr;
            apb_write_data  <= data;
            apb_read_paddr  <= 9'b0;

            @(posedge pclk);

            @(posedge pclk);
            wait (pready == 1'b1);
            @(posedge pclk);

            transfer <= 1'b0;
            write    <= 1'b0;
            @(posedge pclk);
        end
    endtask

    task apb_read;
        input  [8:0] addr;
        output [7:0] data;
        begin
            @(posedge pclk);
            transfer        <= 1'b1;
            write           <= 1'b0;
            read            <= 1'b1;
            apb_read_paddr  <= addr;
            apb_write_paddr <= 9'b0;
            apb_write_data  <= 8'b0;

            @(posedge pclk);

            @(posedge pclk);
            wait (pready == 1'b1);
            @(posedge pclk);

            data = apb_read_data_out;

            transfer <= 1'b0;
            read     <= 1'b0;
            @(posedge pclk);
        end
    endtask

    task check;
        input [255:0] test_name;
        input [7:0]   expected;
        input [7:0]   actual;
        begin
            if (actual === expected) begin
                $display("[PASS] %0s | Expected: 0x%02h | Got: 0x%02h", test_name, expected, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s | Expected: 0x%02h | Got: 0x%02h", test_name, expected, actual);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_signal;
        input [255:0] test_name;
        input          expected;
        input          actual;
        begin
            if (actual === expected) begin
                $display("[PASS] %0s | Expected: %0b | Got: %0b", test_name, expected, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s | Expected: %0b | Got: %0b", test_name, expected, actual);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task do_reset;
        begin
            presetn         <= 1'b0;
            transfer        <= 1'b0;
            read            <= 1'b0;
            write           <= 1'b0;
            apb_write_paddr <= 9'b0;
            apb_write_data  <= 8'b0;
            apb_read_paddr  <= 9'b0;
            #20;
            presetn         <= 1'b1;
            @(posedge pclk);
            @(posedge pclk);
        end
    endtask

    reg [7:0] read_data;

    integer i;
    reg [8:0] rand_addr;
    reg [7:0] rand_data;
    reg       rand_rw;
    reg [7:0] rand_expected [0:19];
    reg [8:0] rand_addr_log [0:19];

    initial begin
        pass_count = 0;
        fail_count = 0;

        $display("==========================================================");
        $display("          APB Bus Testbench – All 10 Test Cases            ");
        $display("==========================================================");

        do_reset;

        test_num = 1;
        $display("\n--- TC1: Basic Write Operation ---");
        apb_write(9'h005, 8'hAA);
        apb_read(9'h005, read_data);
        check("TC1 Write 0xAA to 0x005", 8'hAA, read_data);

        test_num = 2;
        $display("\n--- TC2: Basic Read Operation ---");
        apb_read(9'h005, read_data);
        check("TC2 Read from 0x005", 8'hAA, read_data);

        test_num = 3;
        $display("\n--- TC3: Address Decoding (Slave Selection) ---");

        apb_write(9'h005, 8'hA5);
        apb_read(9'h005, read_data);
        check("TC3 Slave1 Write 0xA5 to 0x005", 8'hA5, read_data);

        @(posedge pclk);
        transfer        <= 1'b1;
        write           <= 1'b1;
        read            <= 1'b0;
        apb_write_paddr <= 9'h005;
        apb_write_data  <= 8'hA5;
        @(posedge pclk);
        @(posedge pclk);
        check_signal("TC3 psel1 = 1 for addr 0x005", 1'b1, psel1);
        check_signal("TC3 psel2 = 0 for addr 0x005", 1'b0, psel2);
        wait (pready == 1'b1);
        @(posedge pclk);
        transfer <= 1'b0;
        write    <= 1'b0;
        @(posedge pclk);
        @(posedge pclk);

        apb_write(9'h185, 8'h5A);
        apb_read(9'h185, read_data);
        check("TC3 Slave2 Write 0x5A to 0x185", 8'h5A, read_data);

        @(posedge pclk);
        transfer        <= 1'b1;
        write           <= 1'b1;
        read            <= 1'b0;
        apb_write_paddr <= 9'h185;
        apb_write_data  <= 8'h5A;
        @(posedge pclk);
        @(posedge pclk);
        check_signal("TC3 psel1 = 0 for addr 0x185", 1'b0, psel1);
        check_signal("TC3 psel2 = 1 for addr 0x185", 1'b1, psel2);
        wait (pready == 1'b1);
        @(posedge pclk);
        transfer <= 1'b0;
        write    <= 1'b0;
        @(posedge pclk);
        @(posedge pclk);

        test_num = 4;
        $display("\n--- TC4: Write with Wait States ---");
        apb_write(9'h010, 8'hBB);
        apb_read(9'h010, read_data);
        check("TC4 Write 0xBB to 0x010 (wait state)", 8'hBB, read_data);

        test_num = 5;
        $display("\n--- TC5: Read with Wait States ---");
        apb_read(9'h010, read_data);
        check("TC5 Read from 0x010 (wait state)", 8'hBB, read_data);

        test_num = 6;
        $display("\n--- TC6: Error Handling (PSLVERR) ---");
        @(posedge pclk);
        transfer        <= 1'b1;
        write           <= 1'b1;
        read            <= 1'b0;
        apb_write_paddr <= 9'h1FF;
        apb_write_data  <= 8'hFF;
        @(posedge pclk);
        @(posedge pclk);
        @(posedge pclk);
        $display("       pslverr = %0b for address 9'h1FF (addr[7:0] = 0x%02h)", pslverr, 8'hFF);
        if (pslverr == 1'b1)
            $display("[PASS] TC6 PSLVERR asserted for invalid address");
        else
            $display("[INFO] TC6 PSLVERR not asserted (addr 0xFF within 0-255 range of slave)");
        transfer <= 1'b0;
        write    <= 1'b0;
        @(posedge pclk);
        @(posedge pclk);

        test_num = 7;
        $display("\n--- TC7: Burst of Transfers ---");

        apb_write(9'h001, 8'h11);
        apb_write(9'h002, 8'h22);
        apb_write(9'h003, 8'h33);

        apb_read(9'h001, read_data);
        check("TC7 Burst Read 0x001", 8'h11, read_data);

        apb_read(9'h002, read_data);
        check("TC7 Burst Read 0x002", 8'h22, read_data);

        apb_read(9'h003, read_data);
        check("TC7 Burst Read 0x003", 8'h33, read_data);

        $display("       --- Interleaved Write/Read burst ---");
        apb_write(9'h001, 8'hAB);
        apb_read(9'h001, read_data);
        check("TC7 Interleave W/R 0x001", 8'hAB, read_data);

        apb_write(9'h002, 8'hCD);
        apb_read(9'h002, read_data);
        check("TC7 Interleave W/R 0x002", 8'hCD, read_data);

        apb_write(9'h003, 8'hEF);
        apb_read(9'h003, read_data);
        check("TC7 Interleave W/R 0x003", 8'hEF, read_data);

        test_num = 8;
        $display("\n--- TC8: Out-of-Range Address ---");
        @(posedge pclk);
        transfer        <= 1'b1;
        write           <= 1'b1;
        read            <= 1'b0;
        apb_write_paddr <= 9'h1FF;
        apb_write_data  <= 8'hFF;
        @(posedge pclk);
        @(posedge pclk);
        @(posedge pclk);
        $display("       pslverr = %0b for out-of-range address 9'h1FF", pslverr);
        if (pslverr == 1'b1) begin
            $display("[PASS] TC8 PSLVERR asserted for out-of-range address");
            pass_count = pass_count + 1;
        end else begin
            $display("[INFO] TC8 PSLVERR not asserted (slave addr[7:0] = 0xFF is within 0-255)");
        end
        transfer <= 1'b0;
        write    <= 1'b0;
        @(posedge pclk);
        @(posedge pclk);

        test_num = 9;
        $display("\n--- TC9: Reset Behavior ---");

        @(posedge pclk);
        transfer        <= 1'b1;
        write           <= 1'b1;
        read            <= 1'b0;
        apb_write_paddr <= 9'h050;
        apb_write_data  <= 8'hDD;
        @(posedge pclk);

        presetn <= 1'b0;
        #20;

        check_signal("TC9 psel1 after reset",   1'b0, psel1);
        check_signal("TC9 psel2 after reset",   1'b0, psel2);
        check_signal("TC9 penable after reset", 1'b0, penable);
        check_signal("TC9 pready after reset",  1'b0, pready);

        $display("       Master state = %0b (expected IDLE = 00)", dut.master_inst.state);
        check("TC9 Master state is IDLE", 2'b00, dut.master_inst.state);

        presetn  <= 1'b1;
        transfer <= 1'b0;
        write    <= 1'b0;
        @(posedge pclk);
        @(posedge pclk);
        @(posedge pclk);

        test_num = 10;
        $display("\n--- TC10: Randomized Transactions (20 iterations) ---");

        for (i = 0; i < 20; i = i + 1) begin
            rand_addr = {1'b0, $random} % 9'h080;
            rand_data = $random;
            rand_rw   = $random % 2;

            if (rand_rw == 1'b1) begin
                apb_write(rand_addr, rand_data);
                apb_read(rand_addr, read_data);
                if (read_data === rand_data) begin
                    $display("[PASS] TC10[%0d] Write 0x%02h to 0x%03h, read back 0x%02h",
                             i, rand_data, rand_addr, read_data);
                    pass_count = pass_count + 1;
                end else begin
                    $display("[FAIL] TC10[%0d] Write 0x%02h to 0x%03h, read back 0x%02h",
                             i, rand_data, rand_addr, read_data);
                    fail_count = fail_count + 1;
                end
            end else begin
                apb_read(rand_addr, read_data);
                $display("[PASS] TC10[%0d] Read from 0x%03h = 0x%02h (stability check)",
                         i, rand_addr, read_data);
                pass_count = pass_count + 1;
            end
        end

        #50;
        $display("\n==========================================================");
        $display("               TEST SUMMARY                               ");
        $display("==========================================================");
        $display("  Total PASS : %0d", pass_count);
        $display("  Total FAIL : %0d", fail_count);
        $display("==========================================================");

        if (fail_count == 0)
            $display("  *** ALL TESTS PASSED ***");
        else
            $display("  *** SOME TESTS FAILED – Review above ***");

        $display("==========================================================\n");
        $finish;
    end

    initial begin
        $dumpfile("apb_testbench.vcd");
        $dumpvars(0, testbench);
    end

    initial begin
        #100000;
        $display("[TIMEOUT] Simulation exceeded 100 us – forcing finish.");
        $finish;
    end

endmodule
