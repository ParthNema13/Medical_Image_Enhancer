// Testbench for Medical Image Enhancer with Histogram Equalization

`timescale 1ns/1ps

module tb_image_enhancer_advanced;

    // Parameters
    parameter WIDTH = 256;
    parameter HEIGHT = 256;
    parameter PIXEL_BITS = 8;
    parameter TOTAL_PIXELS = WIDTH * HEIGHT;
    parameter CLK_PERIOD = 10;
    
    // Signals
    reg clk;
    reg rst;
    reg start;
    reg [1:0] mode;
    reg [PIXEL_BITS-1:0] threshold_value;
    wire done;
    wire [PIXEL_BITS-1:0] enhanced_pixel;
    wire enhanced_valid;
    wire [16:0] pixel_addr;
    
    // Instantiate the design under test
    image_enhancer_advanced #(
        .WIDTH(WIDTH),
        .HEIGHT(HEIGHT),
        .PIXEL_BITS(PIXEL_BITS),
        .TOTAL_PIXELS(TOTAL_PIXELS)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .mode(mode),
        .threshold_value(threshold_value),
        .done(done),
        .enhanced_pixel(enhanced_pixel),
        .enhanced_valid(enhanced_valid),
        .pixel_addr(pixel_addr)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test sequence
    initial begin
        // Initialize signals
        rst = 1;
        start = 0;
        mode = 2'b01;  // Histogram equalization mode
        threshold_value = 8'h00;  // Not used for histogram equalization
        
        // Create VCD dump for waveform viewing
        $dumpfile("image_enhancer_advanced.vcd");
        $dumpvars(0, tb_image_enhancer_advanced);
        
        // Load input image
        $display("===========================================");
        $display("Medical Image Enhancement - Histogram Equalization");
        $display("===========================================");
        $display("Loading input image...");
        dut.load_image("input_image.txt");
        
        // Reset
        #(CLK_PERIOD * 2);
        rst = 0;
        #(CLK_PERIOD * 2);
        
        // ===== Histogram Equalization Test =====
        $display("\n--- Running Histogram Equalization ---");
        mode = 2'b01;
        start = 1;
        #CLK_PERIOD;
        start = 0;
        wait(done);
        #(CLK_PERIOD * 100);
        dut.save_image("output_histeq.txt");
        $display("Histogram equalization output saved\n");
        
        // Display histogram statistics
        $display("\n=== Histogram Statistics ===");
        display_histogram_stats();
        
        // End simulation
        #(CLK_PERIOD * 100);
        $display("\n===========================================");
        $display("Histogram equalization completed successfully!");
        $display("===========================================");
        $display("\nOutput file generated:");
        $display("  - output_histeq.txt");
        $finish;
    end
    
    // Task to display histogram statistics
    task display_histogram_stats;
        integer i, nonzero_bins;
        reg [16:0] max_count;
        reg [7:0] max_bin;
        begin
            nonzero_bins = 0;
            max_count = 0;
            max_bin = 0;
            
            for (i = 0; i < 256; i = i + 1) begin
                if (dut.histogram[i] > 0) begin
                    nonzero_bins = nonzero_bins + 1;
                    if (dut.histogram[i] > max_count) begin
                        max_count = dut.histogram[i];
                        max_bin = i;
                    end
                end
            end
            
            $display("Non-zero bins: %d / 256", nonzero_bins);
            $display("Most frequent value: %h (count: %d)", max_bin, max_count);
            $display("CDF min: %d", dut.cdf_min);
            $display("Total pixels: %d", TOTAL_PIXELS);
        end
    endtask
    
    // Monitor progress
    reg [16:0] last_addr;
    initial begin
        last_addr = 0;
        forever begin
            @(posedge clk);
            if (enhanced_valid && (pixel_addr % 10000 == 0)) begin
                $display("Progress: %d/%d pixels processed", pixel_addr, TOTAL_PIXELS);
            end
        end
    end
    
    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * TOTAL_PIXELS * 20);
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule