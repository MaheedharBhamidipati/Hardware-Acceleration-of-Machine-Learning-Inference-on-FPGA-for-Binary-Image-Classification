module cnn_top(
    input logic [23:0] rgb_in,      // RGB input image
    output logic health_status      // Final classification output
);
    logic [7:0] grayscale, binary, resized;
    logic [15:0] feature_out, pooled_out;
    
    // Instantiate image preprocessing module
    image_preprocessing ip(
        .rgb_in(rgb_in),
        .grayscale_out(grayscale),
        .binary_out(binary),
        .resized_out(resized)
    );
    
    // Instantiate convolution module
    convolution conv(
        .pixel_in(resized),    // Assuming resizing gives 3x3 region
        .filter(3'b111),       // Example filter (simple)
        .feature_out(feature_out)
    );
    
    // Instantiate max pooling module
    max_pooling pool(
        .feature_in(feature_out),
        .pooled_out(pooled_out)
    );
    
    // Instantiate classification module
    classification classify(
        .pooled_in(pooled_out),
        .health_status(health_status)
    );
endmodule

