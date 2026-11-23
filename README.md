# Medical Image Enhancer | Verilog HDL

A hardware-based medical image enhancement system implemented using **Verilog HDL** and simulated using **Xilinx Vivado**.

The project implements three image processing techniques: 3×3 Median Filtering, Contrast Stretching, and Histogram Equalization. It also includes a configurable thresholding and histogram equalization module with multiple operating modes.

## Overview

Medical images such as MRI, CT scans, and X-rays may contain noise and poor contrast, making important image details difficult to distinguish.

This project explores hardware-based image enhancement by implementing image processing algorithms using Verilog HDL. The design uses finite state machines (FSMs), pixel memories, counters, and arithmetic operations to process grayscale images.
<img width="801" height="465" alt="image" src="https://github.com/user-attachments/assets/fac3358b-2b2c-45a6-bbca-ce11852bc71d" />

## Key Features

- **Salt-and-Pepper Noise Removal:** Removes impulse noise using a 3×3 median filter.
- **Contrast Stretching:** Improves image contrast using minimum and maximum pixel intensity values.
- **Histogram Equalization:** Enhances contrast using histogram and cumulative distribution function (CDF) calculations.
- **Binary Thresholding:** Converts grayscale images into binary images using a configurable threshold.
- **Multiple Enhancement Modes:** Supports thresholding, histogram equalization, and their combination.
- **Simulation Testbenches:** Includes dedicated Verilog testbenches for module verification.



## Implemented Algorithms

### 1. Salt-and-Pepper Noise Removal

Implemented in `salt_pepper_removal.v`.

The module uses a 3×3 median filter to remove salt-and-pepper noise.

**Working:**
1. Extracts a 3×3 neighborhood around each pixel.
2. Stores the nine pixel values in a window.
3. Sorts the values using the bubble sort algorithm.
4. Selects the fifth value (median).
5. Replaces the center pixel with the median value.

Border pixels are handled using border replication.

### 2. Contrast Stretching

Implemented in `image_enhancer.v`.

Contrast stretching improves image visibility by expanding the intensity range between the minimum and maximum pixel values.

**Implementation steps:**
1. Scans the input image to identify minimum and maximum pixel intensities.
2. Calculates the intensity range.
3. Applies linear normalization to every pixel.
4. Stores the enhanced image in output memory.

**Formula:**

`Enhanced Pixel = ((Pixel - Min) × 255) / (Max - Min)`

A zero-range condition is handled by retaining the original pixel value.

### 3. Histogram Equalization

Implemented in `image_enhancer_advanced.v`.

Histogram equalization enhances image contrast by redistributing pixel intensity values.

**Implementation steps:**
1. Initializes 256 histogram bins.
2. Calculates the frequency of each grayscale intensity.
3. Computes the Cumulative Distribution Function (CDF).
4. Identifies the minimum non-zero CDF value.
5. Calculates the equalized intensity for each pixel.

**Formula:**

`New Pixel = ((CDF[Pixel] - CDF_Min) × 255) / (Total Pixels - CDF_Min)`

The module uses a 256-bin histogram suitable for 8-bit grayscale images.

### 4. Binary Thresholding

Also implemented in `image_enhancer_advanced.v`.

Thresholding converts grayscale images into binary images using a user-defined threshold value.

**Logic:**
- If pixel intensity is greater than or equal to the threshold, the output becomes 255 (white).
- Otherwise, the output becomes 0 (black).

## Enhancement Modes

The advanced image enhancer supports three operating modes through its 2-bit `mode` input.

| Mode | Operation |
|---|---|
| `00` | Thresholding only |
| `01` | Histogram Equalization only |
| `10` | Thresholding followed by Histogram Equalization |

The threshold value is supplied through the `threshold_value` input.

## System Architecture

Each processing module uses an FSM-based architecture to control image processing.

The general processing sequence is:

1. **IDLE:** Waits for the start signal.
2. **Processing:** Executes the selected image enhancement algorithm.
3. **OUTPUT:** Streams processed pixels through the output interface.
4. **DONE:** Indicates completion of processing.

The modules use:
- Input and output image memories.
- Pixel counters and address generation.
- Clock and reset signals.
- Valid signals for output pixel transmission.
- Completion signals to indicate processing status.

## Technical Specifications

| Parameter | Implementation |
|---|---|
| Language | Verilog HDL |
| Simulation Tool | Xilinx Vivado |
| Image Type | Grayscale |
| Pixel Depth | 8 bits |
| Default Width | 256 pixels |
| Default Height | 256 pixels |
| Total Pixels | 65,536 |
| Histogram Bins | 256 |
| Median Filter | 3×3 |
| Sorting Algorithm | Bubble Sort |
| Control Architecture | Finite State Machine |

The image dimensions are configurable through Verilog parameters.

## Repository Structure

```text
Medical-Image-Enhancer/
│
├── Source_Code/
│   ├── image_enhancer.v
│   ├── image_enhancer_advanced.v
│   ├── salt_pepper_removal.v
│   ├── tb_image_enhancer.v
│   ├── tb_image_enhancer_advanced.v
│   └── tb_salt_pepper_removal.v
│
├── README.md
```

## Simulation and Execution

The project can be simulated using Xilinx Vivado.

**Steps:**

1. Create a new RTL project in Vivado.
2. Add the Verilog source files to the project.
3. Add the corresponding testbench files as simulation sources.
4. Provide the input grayscale image as `input_image.txt`.
5. Run behavioral simulation.
6. Observe the output pixels, processing status, and completion signals.
7. Save the processed image using the provided `save_image` task.

### Testbenches

| Testbench | Module Under Test |
|---|---|
| `tb_salt_pepper_removal.v` | Salt-and-pepper noise removal |
| `tb_image_enhancer.v` | Contrast stretching |
| `tb_image_enhancer_advanced.v` | Thresholding and histogram equalization |

The testbenches generate VCD waveform files and save processed pixel values into output text files.

## Applications

- Medical image preprocessing
- MRI and CT image enhancement
- X-ray image preprocessing
- Digital image processing systems
- Embedded image processing applications
- FPGA-based image processing research

**Disclaimer:** This project performs image enhancement and preprocessing. It is not a medical diagnostic system.

## Future Scope

- FPGA hardware implementation and validation.
- Pipelined image processing for higher throughput.
- Optimization of sorting and histogram computation.
- Integration of median filtering with the advanced enhancement pipeline.
- Support for additional image enhancement algorithms.


**Medical Image Enhancer | Digital Image Processing using Verilog HDL**
 
