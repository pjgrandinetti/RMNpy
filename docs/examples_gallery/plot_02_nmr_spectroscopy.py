"""
NMR Spectroscopy with RMNpy
============================

This example demonstrates how to use RMNpy for Nuclear Magnetic Resonance (NMR) spectroscopy applications.

Prerequisites
-------------
Make sure you have completed the basic usage tutorial first.
"""

# %%
# Import Required Modules
# -----------------------

from rmnpy import Dataset, Datum, Dimension, DependentVariable
from rmnpy.exceptions import RMNLibError, RMNLibMemoryError
import math

print("✓ RMNpy modules imported successfully")

# %%
# 1D NMR Spectrum Setup
# ---------------------
#
# Let's create a 1D NMR dataset with proper chemical shift axis:

# Create 1H NMR dataset
nmr_dataset = Dataset.create(
    title="1H NMR Spectrum of Benzene",
    description="400 MHz 1H NMR in deuterated chloroform at 298K"
)

print(f"NMR Dataset: {nmr_dataset}")
print(f"Title: {nmr_dataset.title}")
print(f"Description: {nmr_dataset.description}")

# %%
# Chemical Shift Dimension
# -------------------------
#
# The chemical shift axis is fundamental to NMR spectroscopy:

# Create chemical shift dimension
# Note: Chemical shift typically runs from high to low (decreasing)
chemical_shift = Dimension.create_linear(
    label="chemical_shift",
    description="1H chemical shift axis",
    count=512,
    start=10.0,      # Start at 10 ppm
    increment=-0.02, # Decrease by 0.02 ppm per point
    unit="ppm"
)

print(f"Chemical shift dimension: {chemical_shift}")
print(f"Label: {chemical_shift.label}")
print(f"Count: {chemical_shift.count}")

# Calculate and display the range
end_ppm = chemical_shift.coordinates_offset + (chemical_shift.count-1) * chemical_shift.increment
print(f"Range: {chemical_shift.coordinates_offset} to {end_ppm:.2f} ppm")

# %%
# Signal Variables
# ----------------
#
# NMR signals can be complex (real + imaginary components):

# Create real and imaginary signal components
real_signal = DependentVariable.create(
    name="real_component",
    description="Real part of NMR signal",
    unit="arbitrary_units"
)

imaginary_signal = DependentVariable.create(
    name="imaginary_component",
    description="Imaginary part of NMR signal",
    unit="arbitrary_units"
)

# Also create magnitude for display
magnitude_signal = DependentVariable.create(
    name="magnitude",
    description="Magnitude spectrum",
    unit="arbitrary_units"
)

print(f"Real signal: {real_signal}")
print(f"Imaginary signal: {imaginary_signal}")
print(f"Magnitude signal: {magnitude_signal}")

# %%
# Simulating Benzene NMR Spectrum
# --------------------------------
#
# Let's simulate a simple benzene spectrum with a peak at ~7.3 ppm:

def simulate_nmr_peak(chemical_shifts, peak_position, linewidth, intensity):
    """
    Simulate a Lorentzian NMR peak.
    
    Parameters
    ----------
    chemical_shifts : list
        Array of chemical shift values
    peak_position : float
        Chemical shift of peak center (ppm)
    linewidth : float
        Full width at half maximum (ppm)
    intensity : float
        Peak intensity
    """
    real_data = []
    imaginary_data = []
    
    for shift in chemical_shifts:
        # Lorentzian lineshape
        delta = shift - peak_position
        lorentzian = intensity / (1 + (2 * delta / linewidth) ** 2)
        
        # Add some phase and noise
        phase = 0.1  # Small phase error
        noise = 0.02 * (math.sin(shift * 100) + math.cos(shift * 150))
        
        real_part = lorentzian * math.cos(phase) + noise
        imag_part = lorentzian * math.sin(phase) + noise * 0.5
        
        real_data.append(real_part)
        imaginary_data.append(imag_part)
    
    return real_data, imaginary_data

# Generate chemical shift array
num_points = 512
start_ppm = 10.0
increment = -0.02

chemical_shifts = [start_ppm + i * increment for i in range(num_points)]

# Simulate benzene peak at 7.3 ppm
benzene_position = 7.3  # ppm
linewidth = 0.1  # ppm
intensity = 5.0

real_data, imag_data = simulate_nmr_peak(
    chemical_shifts, benzene_position, linewidth, intensity
)

print(f"Generated spectrum with {len(real_data)} points")
print(f"Chemical shift range: {chemical_shifts[0]:.1f} to {chemical_shifts[-1]:.1f} ppm")
print(f"Peak maximum at ~{benzene_position} ppm: {max(real_data):.2f}")

# %%
# Creating Data Points
# --------------------
#
# Convert our simulated data into RMNpy data points:

# Create data points for real component
real_data_points = []
for value in real_data:
    datum = Datum.create(response_value=value)
    real_data_points.append(datum)

# Create data points for imaginary component
imag_data_points = []
for value in imag_data:
    datum = Datum.create(response_value=value)
    imag_data_points.append(datum)

# Calculate magnitude data points
magnitude_data_points = []
for real_val, imag_val in zip(real_data, imag_data):
    magnitude = math.sqrt(real_val**2 + imag_val**2)
    datum = Datum.create(response_value=magnitude)
    magnitude_data_points.append(datum)

print(f"Created data points:")
print(f"  - Real: {len(real_data_points)} points")
print(f"  - Imaginary: {len(imag_data_points)} points")
print(f"  - Magnitude: {len(magnitude_data_points)} points")

# %%
# Finding Peak Information
# ------------------------
#
# Let's analyze our simulated spectrum to find the peak:

def find_peak_info(chemical_shifts, data_values):
    """Find the maximum peak in the spectrum."""
    max_value = max(data_values)
    max_index = data_values.index(max_value)
    peak_shift = chemical_shifts[max_index]
    
    return peak_shift, max_value, max_index

# Analyze the real component
peak_shift, peak_intensity, peak_index = find_peak_info(chemical_shifts, real_data)

print(f"Peak Analysis:")
print(f"  - Chemical shift: {peak_shift:.2f} ppm")
print(f"  - Intensity: {peak_intensity:.2f}")
print(f"  - Index: {peak_index}")

# Find signal-to-noise ratio
# Estimate noise from the baseline (first 50 points)
baseline_noise = sum(abs(val) for val in real_data[:50]) / 50
snr = peak_intensity / baseline_noise if baseline_noise > 0 else float('inf')

print(f"  - Baseline noise: {baseline_noise:.3f}")
print(f"  - Signal-to-noise ratio: {snr:.1f}")

# %%
# 2D NMR Experiment Setup
# ------------------------
#
# Now let's create a 2D NMR experiment (COSY - Correlation Spectroscopy):

# Create 2D COSY dataset
cosy_dataset = Dataset.create(
    title="2D COSY Experiment",
    description="1H-1H correlation spectroscopy of organic compound"
)

# F1 dimension (indirect)
f1_dimension = Dimension.create_linear(
    label="f1_chemical_shift",
    description="F1 chemical shift (indirect dimension)",
    count=128,
    start=10.0,
    increment=-0.08,  # Coarser resolution in F1
    unit="ppm"
)

# F2 dimension (direct)
f2_dimension = Dimension.create_linear(
    label="f2_chemical_shift",
    description="F2 chemical shift (direct dimension)", 
    count=256,
    start=10.0,
    increment=-0.04,  # Finer resolution in F2
    unit="ppm"
)

print(f"2D COSY Dataset: {cosy_dataset}")
print(f"F1 dimension: {f1_dimension.count} points, {f1_dimension.label}")
print(f"F2 dimension: {f2_dimension.count} points, {f2_dimension.label}")
print(f"Total data points: {f1_dimension.count * f2_dimension.count}")

# %%
# Multi-Nuclear NMR Setup
# -----------------------
#
# Different nuclei have different chemical shift ranges:

def create_nucleus_dimension(nucleus, count=512):
    """
    Create appropriate chemical shift dimension for different nuclei.
    """
    nucleus_params = {
        '1H': {'start': 15.0, 'increment': -0.03, 'description': '1H chemical shift'},
        '13C': {'start': 250.0, 'increment': -0.5, 'description': '13C chemical shift'},
        '31P': {'start': 200.0, 'increment': -0.8, 'description': '31P chemical shift'},
        '19F': {'start': 50.0, 'increment': -0.2, 'description': '19F chemical shift'},
    }
    
    if nucleus not in nucleus_params:
        raise ValueError(f"Nucleus {nucleus} not supported")
    
    params = nucleus_params[nucleus]
    
    dimension = Dimension.create_linear(
        label=f"{nucleus}_chemical_shift",
        description=params['description'],
        count=count,
        start=params['start'],
        increment=params['increment'],
        unit="ppm"
    )
    
    return dimension

# Create dimensions for different nuclei
nuclei = ['1H', '13C', '31P', '19F']

for nucleus in nuclei:
    dim = create_nucleus_dimension(nucleus)
    end_shift = dim.coordinates_offset + (dim.count - 1) * dim.increment
    print(f"{nucleus}: {dim.coordinates_offset} to {end_shift:.1f} ppm ({dim.count} points)")

# %%
# Complete NMR Workflow Example
# ------------------------------
#
# Let's put everything together in a complete workflow:

def complete_nmr_workflow():
    """Demonstrate a complete NMR data processing workflow."""
    
    print("=== Complete NMR Workflow ===")
    
    # 1. Create experimental dataset
    experiment = Dataset.create(
        title="Caffeine Analysis",
        description="1H NMR of caffeine in DMSO-d6 at 298K"
    )
    print(f"1. Experiment: {experiment}")
    
    # 2. Set up acquisition parameters
    acquisition_dim = Dimension.create_linear(
        label="chemical_shift",
        description="1H chemical shift",
        count=1024,
        start=12.0,
        increment=-0.012,
        unit="ppm"
    )
    end_ppm = acquisition_dim.coordinates_offset + (acquisition_dim.count-1)*acquisition_dim.increment
    print(f"2. Acquisition: {acquisition_dim.count} points, {acquisition_dim.coordinates_offset} to {end_ppm:.1f} ppm")
    
    # 3. Create signal variables
    spectrum_real = DependentVariable.create(
        name="spectrum_real",
        description="Real spectrum after Fourier transform",
        unit="arbitrary_units"
    )
    print(f"3. Variables: spectrum components defined")
    
    # 4. Simulate caffeine signals
    # Caffeine has characteristic peaks at ~8.8, 8.0, and 3.4 ppm
    caffeine_peaks = [
        {'position': 8.8, 'intensity': 1.0, 'width': 0.05},  # Aromatic H
        {'position': 8.0, 'intensity': 1.0, 'width': 0.05},  # Aromatic H
        {'position': 3.4, 'intensity': 9.0, 'width': 0.08},  # N-CH3 groups
    ]
    
    # Generate chemical shift array
    shifts = [acquisition_dim.coordinates_offset + i * acquisition_dim.increment 
              for i in range(acquisition_dim.count)]
    
    # Simulate combined spectrum
    spectrum_data = [0.0] * len(shifts)
    
    for peak in caffeine_peaks:
        for i, shift in enumerate(shifts):
            delta = shift - peak['position']
            signal = peak['intensity'] / (1 + (2 * delta / peak['width']) ** 2)
            spectrum_data[i] += signal
    
    # Add baseline noise
    for i in range(len(spectrum_data)):
        noise = 0.01 * math.sin(shifts[i] * 50) * math.cos(shifts[i] * 30)
        spectrum_data[i] += noise
    
    print(f"4. Simulated caffeine spectrum with {len(caffeine_peaks)} peaks")
    
    # 5. Create data points
    spectrum_points = []
    for value in spectrum_data:
        datum = Datum.create(response_value=value)
        spectrum_points.append(datum)
    
    print(f"5. Created {len(spectrum_points)} spectrum data points")
    
    # 6. Analyze peaks
    peak_analysis = []
    for peak in caffeine_peaks:
        # Find closest data point to expected position
        closest_index = min(range(len(shifts)), 
                          key=lambda i: abs(shifts[i] - peak['position']))
        found_shift = shifts[closest_index]
        found_intensity = spectrum_data[closest_index]
        
        peak_analysis.append({
            'expected': peak['position'],
            'found': found_shift,
            'intensity': found_intensity
        })
    
    print(f"6. Peak Analysis:")
    for i, analysis in enumerate(peak_analysis):
        print(f"   Peak {i+1}: {analysis['found']:.2f} ppm (intensity: {analysis['intensity']:.2f})")
    
    return {
        'experiment': experiment,
        'dimension': acquisition_dim,
        'variable': spectrum_real,
        'data': spectrum_points,
        'analysis': peak_analysis
    }

# Run complete workflow
workflow_result = complete_nmr_workflow()

print("\n🎉 Complete NMR workflow demonstrated!")
print(f"Experiment: {workflow_result['experiment'].title}")
print(f"Data points: {len(workflow_result['data'])}")
print(f"Peaks found: {len(workflow_result['analysis'])}")

# %%
# Summary
# -------
#
# In this example, you learned how to use RMNpy for NMR spectroscopy:
#
# 1. **1D NMR Setup** - Creating datasets with chemical shift dimensions
# 2. **Signal Components** - Real, imaginary, and magnitude spectra
# 3. **Spectrum Simulation** - Generating realistic NMR data
# 4. **2D NMR** - Multi-dimensional experiments (COSY)
# 5. **Multi-Nuclear NMR** - Different nuclei with appropriate ranges
# 6. **Complete Workflow** - End-to-end NMR data processing
#
# Next Steps
# ----------
#
# - Try the Advanced Data Manipulation examples
# - Explore Data Export and Visualization techniques
# - Read about Error Handling Best Practices
