"""
Simple Data Visualization
==========================

A basic example of creating and plotting data.
"""

import numpy as np
import matplotlib.pyplot as plt

# Generate some example data
t = np.linspace(0, 2*np.pi, 100)
signal = np.cos(t) * np.exp(-t/5)

# Create a simple plot
plt.figure(figsize=(8, 4))
plt.plot(t, signal, 'b-', linewidth=2, label='Exponential decay')
plt.xlabel('Time')
plt.ylabel('Amplitude')
plt.title('Simple Signal Example')
plt.legend()
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.show()

print("Visualization example completed!")
