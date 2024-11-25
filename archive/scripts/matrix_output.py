import numpy as np

# Input matrix (4x6)
input_matrix = np.array([
    [1, 2, 3, 4, 5, 6],
    [7, 8, 9, 10, 11, 12],
    [13, 14, 15, 16, 17, 18],
    [19, 20, 21, 22, 23, 24]
])

# Weight matrix (6x4)
weight_matrix = np.array([
    [1, 2, 3, 4],
    [5, 6, 7, 8],
    [9, 10, 11, 12],
    [13, 14, 15, 16],
    [17, 18, 19, 20],
    [21, 22, 23, 24]
])

# Calculate expected result
result = np.matmul(input_matrix, weight_matrix)
print("Expected output matrix (4x4):")
print(result)

# Verify each position
for i in range(4):
    for j in range(4):
        # Show calculation for each element
        element_sum = 0
        print(f"\nCalculating position [{i},{j}]:")
        for k in range(6):
            product = input_matrix[i,k] * weight_matrix[k,j]
            element_sum += product
            print(f"  {input_matrix[i,k]} * {weight_matrix[k,j]} = {product}")
        print(f"Sum = {element_sum}")