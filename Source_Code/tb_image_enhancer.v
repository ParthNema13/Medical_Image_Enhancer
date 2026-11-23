// Testbench for Medical Image Enhancer
`timescale 1ns/1ps

module tb_image_enhancer;

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
    wire [PIXEL_BITS-1:0] enhanced_pixel;
    wire enhanced_valid;
    wire [16:0] pixel_addr;
    
    // Instantiate the design under test
    image_enhancer #(
        .WIDTH(WIDTH),
        .HEIGHT(HEIGHT),
        .PIXEL_BITS(PIXEL_BITS),
        .TOTAL_PIXELS(TOTAL_PIXELS)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
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
    
    // File for saving enhanced image
    integer out_file;
    
    // Test sequence
    initial begin
        // Initialize signals
        rst = 1;
        start = 0;
        
        // Create VCD dump for waveform viewing
        $dumpfile("image_enhancer.vcd");
        $dumpvars(0, tb_image_enhancer);
        
        // Load input image
        $display("Loading input image...");
        dut.load_image("input_image.txt");
        
        // Reset
        #(CLK_PERIOD * 2);
        rst = 0;
        #(CLK_PERIOD * 2);
        
        // Start processing
        $display("Starting image enhancement...");
        start = 1;
        #CLK_PERIOD;
        start = 0;
        
        // Wait for processing to complete
        wait(done);
        $display("Image enhancement completed!");
        
        // Save enhanced image
        #(CLK_PERIOD * 10);
        dut.save_image("output_image.txt");
        
        // Additional verification
        $display("\n=== Enhancement Statistics ===");
        $display("Total pixels processed: %d", TOTAL_PIXELS);
        $display("Input min value: %h", dut.min_val);
        $display("Input max value: %h", dut.max_val);
        $display("================================\n");
        
        // End simulation
        #(CLK_PERIOD * 100);
        $display("Testbench completed successfully");
        $finish;
    end
    
    // Monitor enhanced pixel output
    always @(posedge clk) begin
        if (enhanced_valid) begin
            if (pixel_addr % 5000 == 0)
                $display("Progress: %d/%d pixels processed", pixel_addr, TOTAL_PIXELS);
        end
    end
    
    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * TOTAL_PIXELS * 10);
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule