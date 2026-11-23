// Medical Image Enhancer with Contrast Stretching
// Image Size: 225x225 grayscale (8-bit pixels)

module image_enhancer #(
    parameter WIDTH = 256,
    parameter HEIGHT = 256,
    parameter PIXEL_BITS = 8,
    parameter TOTAL_PIXELS = WIDTH * HEIGHT
)(
    input wire clk,
    input wire rst,
    input wire start,
    output reg done,
    output reg [PIXEL_BITS-1:0] enhanced_pixel,
    output reg enhanced_valid,
    output reg [16:0] pixel_addr  // 17 bits for 50625 pixels
);

    // Memory for input and output images
    reg [PIXEL_BITS-1:0] input_image [0:TOTAL_PIXELS-1];
    reg [PIXEL_BITS-1:0] output_image [0:TOTAL_PIXELS-1];
    
    // Min/Max values
    reg [PIXEL_BITS-1:0] min_val;
    reg [PIXEL_BITS-1:0] max_val;
    
    // State machine
    localparam IDLE = 3'd0;
    localparam FIND_MINMAX = 3'd1;
    localparam STRETCH = 3'd2;
    localparam OUTPUT = 3'd3;
    localparam DONE = 3'd4;
    
    reg [2:0] state;
    reg [16:0] pixel_counter;
    
    // Contrast stretching calculation registers
    reg [PIXEL_BITS-1:0] current_pixel;
    reg [15:0] numerator;
    reg [PIXEL_BITS-1:0] denominator;
    reg [15:0] stretched_value;
    
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
    
    // Main processing logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            done <= 0;
            pixel_counter <= 0;
            min_val <= 8'hFF;
            max_val <= 8'h00;
            enhanced_valid <= 0;
            pixel_addr <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= FIND_MINMAX;
                        pixel_counter <= 0;
                        min_val <= 8'hFF;
                        max_val <= 8'h00;
                        done <= 0;
                    end
                end
                
                FIND_MINMAX: begin
                    if (pixel_counter < TOTAL_PIXELS) begin
                        current_pixel <= input_image[pixel_counter];
                        
                        // Find minimum
                        if (input_image[pixel_counter] < min_val)
                            min_val <= input_image[pixel_counter];
                        
                        // Find maximum
                        if (input_image[pixel_counter] > max_val)
                            max_val <= input_image[pixel_counter];
                        
                        pixel_counter <= pixel_counter + 1;
                    end else begin
                        state <= STRETCH;
                        pixel_counter <= 0;
                        $display("Min value: %d, Max value: %d", min_val, max_val);
                    end
                end
                
                STRETCH: begin
                    if (pixel_counter < TOTAL_PIXELS) begin
                        current_pixel = input_image[pixel_counter];
                        denominator = max_val - min_val;
                        
                        // Avoid division by zero
                        if (denominator == 0) begin
                            output_image[pixel_counter] <= current_pixel;
                        end else begin
                            // Contrast stretching: (pixel - min) * 255 / (max - min)
                            numerator = (current_pixel - min_val) * 255;
                            stretched_value = numerator / denominator;
                            output_image[pixel_counter] <= stretched_value[PIXEL_BITS-1:0];
                        end
                        
                        pixel_counter <= pixel_counter + 1;
                    end else begin
                        state <= OUTPUT;
                        pixel_counter <= 0;
                        $display("Contrast stretching completed");
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