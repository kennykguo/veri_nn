# Neural Network in Verilog - MNIST Classifier Implementation on DE1-SoC

This project demonstrates a fully functional neural network implemented in Verilog to classify handwritten digits from the MNIST dataset. The design is deployed on an Altera DE1-SoC FPGA board, utilizing PyTorch-trained weights that are quantized and integrated into the hardware.

## Features

### Neural Network Architecture
- **Input Layer**: 784 neurons (28x28 image pixels)
- **Hidden Layers**: Fully connected with ReLU activation
- **Output Layer**: 10 neurons (digits 0-9)
- **Processing**: Pipeline-optimized state machine
- **Performance**: Real-time classification capabilities

### Interactive Interface
- VGA output with 28x28 drawing grid
- Push-button navigation and drawing controls
- Seven-segment display for classification results
- Real-time prediction feedback

## System Architecture

### Core Components
| Component | Description |
|-----------|-------------|
| Neural Core | Executes matrix multiplications, ReLU activation, and classification |
| Memory Units | Manages weights, input data, and intermediate results |
| Control Unit | Coordinates data flow and processing sequences |
| I/O Interface | Handles user input and result visualization |

## Implementation Workflow

### Training Process
1. Train network using PyTorch and MNIST dataset
2. Quantize weights to 32-bit signed integers
3. Convert to `.mif` format for FPGA memory

### FPGA Deployment
1. Implement core Verilog modules:
   - Matrix multiplication unit
   - ReLU activation module
   - Argmax classification logic
2. Synthesize using Intel Quartus Prime
3. Program DE1-SoC board

## Core Modules

### Processing Units
- `matrix_multiply`: Layer computation engine
- `relu`: Activation function implementation
- `argmax`: Classification decision logic

### Interface Controllers
- VGA signal generator
- Input processing state machine
- Display output controller

## Performance Metrics

| Metric | Value |
|--------|--------|
| Clock Frequency | XX MHz |
| Classification Time | XX ms |
| Resource Usage | XX% |
| Accuracy | XX% |

## Usage Instructions

1. Power on DE1-SoC board
2. Use push buttons to navigate grid
3. Draw digit using control interface
4. View classification on seven-segment display

## Future Enhancements

- [ ] Implement batch processing
- [ ] Add UART interface
- [ ] Optimize memory usage
- [ ] Enhance drawing interface
