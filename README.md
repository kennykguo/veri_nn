## Neural Network in Verilog - MNIST Classifier Implementation on DE1-SoC
This project implements a fully functional neural network designed for classifying handwritten digits from the MNIST dataset. The network is written entirely in Verilog and deployed on an Altera DE1-SoC FPGA board. It integrates weights trained in PyTorch, which are quantized and imported into the hardware design.


## Features
### 4-Layer Neural Network:
Input: 784 features (28x28 image pixels).
Layers: Fully connected layers with ReLU activation.
Output: 10-class probability distribution (digits 0–9).

### State Machine:
Manages layer execution (matrix multiplication, ReLU, and argmax operations).
Implements an efficient pipeline for sequential processing of neural network layers.

### Visualization:
VGA output for displaying interactive drawing grids.
Allows users to draw test images and view the neural network's predictions in real time.

### User Interaction:
Push-button controls for navigating and drawing on a 28x28 grid.
Seven-segment display outputs for displaying classification results.



## System Architecture
### Neural Network Core:
Sequential execution of:
Matrix multiplication (fully connected layers).
ReLU activation functions.
Argmax for prediction.

### Memory Management:
Separate memory blocks for:
Input image data.
Weights of each layer.
Intermediate results for matrix multiplications and activations.

### Drawing Grid:
Users can draw digits on a 28x28 grid using arrow keys.
The drawn image is processed through the neural network for classification.


## Training and Deployment Workflow
### Training in PyTorch:
The neural network is first trained on the MNIST dataset in PyTorch.
Weights are quantized to 32-bit signed integers for compatibility with Verilog.
Weight Export:

### Quantized weights are exported to .mif (memory initialization file) format.
Imported into the FPGA's memory during synthesis.

### FPGA Implementation:
Verilog modules implement core operations (matrix multiplication, ReLU, and argmax).
Synthesis and deployment are performed using Intel Quartus Prime.


## Key Modules
Matrix Multiplication (matrix_multiply): Handles dot product calculations for each layer.
ReLU Activation (relu): Implements element-wise ReLU functionality.
Argmax (argmax): Determines the class with the highest probability.
VGA Interface: Generates VGA signals for grid visualization.

State Machine: Controls transitions between the neural network layers and interactive features.
![IMG-6039](https://github.com/user-attachments/assets/9da3ab0f-c722-4ceb-b870-c960879fdbf6)
![IMG-6038](https://github.com/user-attachments/assets/e5169470-aa72-4396-aa2e-7fa947112d5d)
