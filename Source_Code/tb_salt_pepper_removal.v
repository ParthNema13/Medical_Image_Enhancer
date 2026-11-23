// Testbench for Salt and Pepper Noise Removal

`timescale 1ns/1ps

module tb_salt_pepper_removal;

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
    wire done;
    wire [PIXEL_BITS-1:0] filtered_pixel;
    wire filtered_valid;
    wire [16:0] pixel_addr;
    
    // Instantiate the design under test
    salt_pepper_removal #(
        .WIDTH(WIDTH),
        .HEIGHT(HEIGHT),
        .PIXEL_BITS(PIXEL_BITS),
        .TOTAL_PIXELS(TOTAL_PIXELS)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .done(done),
        .filtered_pixel(filtered_pixel),
        .filtered_valid(filtered_valid),
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
        
        // Create VCD dump for waveform viewing
        $dumpfile("salt_pepper_removal.vcd");
        $dumpvars(0, tb_salt_pepper_removal);
        
        $display("===========================================");
        $display("Salt & Pepper Noise Removal");
        $display("Using 3x3 Median Filter");
        $display("===========================================");
        
        // Load input image with noise
        $display("\nLoading noisy input image...");
        dut.load_image("input_image.txt");
        
        // Reset
        #(CLK_PERIOD * 2);
        rst = 0;
        #(CLK_PERIOD * 2);
        
        // Start filtering
        $display("Starting noise removal processing...");
        start = 1;
        #CLK_PERIOD;
        start = 0;
        
        // Wait for processing to complete
        wait(done);
        $display("Noise removal completed!");
        
        // Save filtered image
        #(CLK_PERIOD * 100);
        dut.save_image("output_filtered.txt");
        
        // Calculate and display statistics
        display_statistics();
        
        // End simulation
        #(CLK_PERIOD * 100);
        $display("\n===========================================");
        $display("Processing completed successfully!");
        $display("===========================================");
        $display("\nOutput file: output_filtered.txt");
        $display("The median filter has removed salt & pepper noise");
        $finish;
    end
    
    // Task to display processing statistics
    task display_statistics;
        integer changed_pixels;
        integer i;
        begin
            changed_pixels = 0;
            
            // Count how many pixels changed
            for (i = 0; i < TOTAL_PIXELS; i = i + 1) begin
                if (dut.input_image[i] != dut.output_image[i])
                    changed_pixels = changed_pixels + 1;
            end
            
            $display("\n=== Processing Statistics ===");
            $display("Total pixels: %d", TOTAL_PIXELS);
            $display("Pixels modified: %d", changed_pixels);
            $display("Pixels unchanged: %d", TOTAL_PIXELS - changed_pixels);
            $display("Modification rate: %0.2f%%", (changed_pixels * 100.0) / TOTAL_PIXELS);
        end
    endtask
    
    // Monitor progress
    always @(posedge clk) begin
        if (filtered_valid && (pixel_addr % 10000 == 0)) begin
            $display("Progress: %d/%d pixels processed (%0.1f%%)", 
                     pixel_addr, TOTAL_PIXELS, (pixel_addr * 100.0) / TOTAL_PIXELS);
        end
    end
    
    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * TOTAL_PIXELS * 15);
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule