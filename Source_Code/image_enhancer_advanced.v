`timescale 1ns/1ps

// Medical Image Enhancer with Thresholding and Histogram Equalization
// Image Size: 225x225 grayscale (8-bit pixels)

module image_enhancer_advanced #(
    parameter WIDTH = 256,
    parameter HEIGHT = 256,
    parameter PIXEL_BITS = 8,
    parameter TOTAL_PIXELS = WIDTH * HEIGHT
)(
    input wire clk,
    input wire rst,
    input wire start,
    input wire [1:0] mode,  // 00: Threshold, 01: Hist Eq, 10: Both
    input wire [PIXEL_BITS-1:0] threshold_value,  // User-defined threshold
    output reg done,
    output reg [PIXEL_BITS-1:0] enhanced_pixel,
    output reg enhanced_valid,
    output reg [16:0] pixel_addr
);

    // Memory for input and output images
    reg [PIXEL_BITS-1:0] input_image [0:TOTAL_PIXELS-1];
    reg [PIXEL_BITS-1:0] output_image [0:TOTAL_PIXELS-1];
    reg [PIXEL_BITS-1:0] temp_image [0:TOTAL_PIXELS-1];
    
    // Histogram array (256 bins for 8-bit values)
    reg [16:0] histogram [0:255];  // 17 bits to hold up to 50625
    reg [31:0] cdf [0:255];        // Cumulative distribution function
    reg [31:0] cdf_min;
    
    // State machine
    localparam IDLE = 4'd0;
    localparam THRESHOLD = 4'd1;
    localparam BUILD_HIST = 4'd2;
    localparam BUILD_CDF = 4'd3;
    localparam HIST_EQ = 4'd4;
    localparam OUTPUT = 4'd5;
    localparam DONE = 4'd6;
    
    reg [3:0] state;
    reg [16:0] pixel_counter;
    reg [8:0] bin_counter;  // 0-255 for histogram bins
    
    // Working registers
    reg [PIXEL_BITS-1:0] current_pixel;
    reg [31:0] numerator;
    reg [31:0] equalized_value;
    
    // Task to load image from file
    task load_image;
        input [8*100:1] filename;
        integer file, i, scan_result;
        reg [PIXEL_BITS-1:0] pixel_data;
        begin
            file = $fopen(filename, "r");
            if (file == 0) begin
                $display("Error: Cannot open file %s", filename);
                $finish;
            end
            
            for (i = 0; i < TOTAL_PIXELS; i = i + 1) begin
                scan_result = $fscanf(file, "%h\n", pixel_data);
                if (scan_result != 1) begin
                    $display("Error reading pixel %d", i);
                    input_image[i] = 8'h00;
                end else begin
                    input_image[i] = pixel_data;
                end
            end
            $fclose(file);
            $display("Image loaded successfully: %d pixels", TOTAL_PIXELS);
        end
    endtask
    
    // Task to save enhanced image
    task save_image;
        input [8*100:1] filename;
        integer file, i;
        begin
            file = $fopen(filename, "w");
            if (file == 0) begin
                $display("Error: Cannot create file %s", filename);
            end else begin
                for (i = 0; i < TOTAL_PIXELS; i = i + 1) begin
                    $fwrite(file, "%h\n", output_image[i]);
                end
                $fclose(file);
                $display("Enhanced image saved to %s", filename);
            end
        end
    endtask
    
    // Initialize histogram
    integer k;
    task init_histogram;
        begin
            for (k = 0; k < 256; k = k + 1) begin
                histogram[k] = 0;
                cdf[k] = 0;
            end
            cdf_min = 0;
        end
    endtask
    
    // Initialize output image
    task init_output;
        integer m;
        begin
            for (m = 0; m < TOTAL_PIXELS; m = m + 1) begin
                output_image[m] = 8'h00;
                temp_image[m] = 8'h00;
            end
        end
    endtask
    
    // Main processing logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            done <= 0;
            pixel_counter <= 0;
            bin_counter <= 0;
            enhanced_valid <= 0;
            pixel_addr <= 0;
            cdf_min <= 0;
            init_histogram();
            init_output();
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        pixel_counter <= 0;
                        bin_counter <= 0;
                        done <= 0;
                        init_histogram();
                        init_output();
                        
                        // Decide first state based on mode
                        case (mode)
                            2'b00: state <= THRESHOLD;      // Threshold only
                            2'b01: state <= BUILD_HIST;     // Histogram Eq only
                            2'b10: state <= THRESHOLD;      // Both (threshold first)
                            default: state <= THRESHOLD;
                        endcase
                        
                        $display("Starting enhancement - Mode: %b, Threshold: %h", mode, threshold_value);
                    end
                end
                
                THRESHOLD: begin
                    if (pixel_counter < TOTAL_PIXELS) begin
                        current_pixel = input_image[pixel_counter];
                        
                        // Binary thresholding
                        if (current_pixel >= threshold_value)
                            temp_image[pixel_counter] <= 8'hFF;  // White
                        else
                            temp_image[pixel_counter] <= 8'h00;  // Black
                        
                        pixel_counter <= pixel_counter + 1;
                    end else begin
                        $display("Thresholding completed");
                        pixel_counter <= 0;
                        
                        // Decide next state based on mode
                        if (mode == 2'b00) begin
                            // Threshold only - copy to output
                            state <= OUTPUT;
                            for (k = 0; k < TOTAL_PIXELS; k = k + 1)
                                output_image[k] <= temp_image[k];
                        end else begin
                            // Continue to histogram equalization
                            state <= BUILD_HIST;
                        end
                    end
                end
                
                BUILD_HIST: begin
                    if (pixel_counter < TOTAL_PIXELS) begin
                        // Select input based on whether thresholding was done
                        if (mode == 2'b10)
                            current_pixel = temp_image[pixel_counter];  // After threshold
                        else
                            current_pixel = input_image[pixel_counter];  // Original
                        
                        // Build histogram
                        histogram[current_pixel] <= histogram[current_pixel] + 1;
                        pixel_counter <= pixel_counter + 1;
                    end else begin
                        $display("Histogram built");
                        state <= BUILD_CDF;
                        bin_counter <= 0;
                        cdf[0] <= histogram[0];
                    end
                end
                
                BUILD_CDF: begin
                    if (bin_counter < 255) begin
                        bin_counter <= bin_counter + 1;
                        cdf[bin_counter + 1] <= cdf[bin_counter] + histogram[bin_counter + 1];
                    end else begin
                        $display("CDF computed");
                        
                        // Find CDF minimum (first non-zero value)
                        for (k = 0; k < 256; k = k + 1) begin
                            if (cdf[k] > 0) begin
                                if (cdf_min == 0 || cdf[k] < cdf_min)
                                    cdf_min <= cdf[k];
                            end
                        end
                        
                        state <= HIST_EQ;
                        pixel_counter <= 0;
                        
                        // Debug output
                        $display("CDF_min = %d", cdf_min);
                    end
                end
                
                HIST_EQ: begin
                    if (pixel_counter < TOTAL_PIXELS) begin
                        // Select input based on whether thresholding was done
                        if (mode == 2'b10)
                            current_pixel = temp_image[pixel_counter];
                        else
                            current_pixel = input_image[pixel_counter];
                        
                        // Histogram equalization formula:
                        // new_pixel = ((cdf[pixel] - cdf_min) * 255) / (total_pixels - cdf_min)
                        if (cdf_min > 0 && (TOTAL_PIXELS - cdf_min) > 0) begin
                            numerator = (cdf[current_pixel] - cdf_min) * 255;
                            equalized_value = numerator / (TOTAL_PIXELS - cdf_min);
                            output_image[pixel_counter] <= equalized_value[PIXEL_BITS-1:0];
                        end else begin
                            // Fallback if something is wrong
                            output_image[pixel_counter] <= current_pixel;
                        end
                        
                        pixel_counter <= pixel_counter + 1;
                    end else begin
                        $display("Histogram equalization completed");
                        state <= OUTPUT;
                        pixel_counter <= 0;
                    end
                end
                
                OUTPUT: begin
                    if (pixel_counter < TOTAL_PIXELS) begin
                        enhanced_pixel <= output_image[pixel_counter];
                        pixel_addr <= pixel_counter;
                        enhanced_valid <= 1;
                        pixel_counter <= pixel_counter + 1;
                    end else begin
                        enhanced_valid <= 0;
                        state <= DONE;
                    end
                end
                
                DONE: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule