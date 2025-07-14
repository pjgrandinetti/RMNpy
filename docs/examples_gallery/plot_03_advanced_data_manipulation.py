"""
Advanced Data Manipulation with RMNpy
======================================

This example covers advanced techniques for working with scientific data using RMNpy.

Prerequisites
-------------
Complete the previous examples:
- Installation and Basic Usage
- NMR Spectroscopy
"""

# %%
# Import Required Modules
# -----------------------

from rmnpy import Dataset, Datum, Dimension, DependentVariable
from rmnpy.exceptions import RMNLibError, RMNLibMemoryError
import math
import random

print("✓ Modules imported successfully")

# %%
# Working with Large Datasets
# ----------------------------
#
# Learn how to efficiently handle large amounts of data:

def create_large_dataset(size=10000):
    """Create a large dataset efficiently."""
    print(f"Creating large dataset with {size} points...")
    
    # Create dataset
    large_dataset = Dataset.create(
        title=f"Large Scale Experiment ({size} points)",
        description="Demonstration of handling large data arrays"
    )
    
    # Create high-resolution dimension
    high_res_dim = Dimension.create_linear(
        label="high_resolution",
        description="High resolution measurement axis",
        count=size,
        start=0.0,
        increment=0.001,
        unit="arbitrary"
    )
    
    # Create variable
    signal_var = DependentVariable.create(
        name="high_res_signal",
        description="High resolution signal data",
        unit="counts"
    )
    
    print(f"✓ Dataset created: {large_dataset}")
    end_point = high_res_dim.start + (size-1)*high_res_dim.increment
    print(f"✓ Dimension: {size} points from {high_res_dim.start} to {end_point:.3f}")
    
    return large_dataset, high_res_dim, signal_var

# Create large dataset
large_ds, large_dim, large_var = create_large_dataset(5000)

print(f"\nMemory usage considerations:")
print(f"- Dataset object: lightweight container")
print(f"- Dimension: {large_dim.count} points definition")
print(f"- Variable: metadata only")
print(f"- Data points: created on-demand for efficiency")

# %%
# Batch Data Processing
# ---------------------
#
# Process data in batches for memory efficiency:

def process_data_in_batches(data_generator, batch_size=1000):
    """Process large amounts of data in manageable batches."""
    print(f"Processing data in batches of {batch_size}...")
    
    batch_results = []
    current_batch = []
    
    for i, value in enumerate(data_generator):
        current_batch.append(value)
        
        # Process batch when full
        if len(current_batch) >= batch_size:
            # Create data points for this batch
            batch_data_points = []
            for val in current_batch:
                datum = Datum.create(response_value=val)
                batch_data_points.append(datum)
            
            # Calculate batch statistics
            batch_stats = {
                'batch_number': len(batch_results) + 1,
                'size': len(current_batch),
                'min': min(current_batch),
                'max': max(current_batch),
                'mean': sum(current_batch) / len(current_batch),
                'data_points': batch_data_points
            }
            
            batch_results.append(batch_stats)
            print(f"  Batch {batch_stats['batch_number']}: {batch_stats['size']} points, "
                  f"range [{batch_stats['min']:.3f}, {batch_stats['max']:.3f}], "
                  f"mean {batch_stats['mean']:.3f}")
            
            # Clear batch for next iteration
            current_batch = []
    
    # Process remaining data
    if current_batch:
        batch_data_points = []
        for val in current_batch:
            datum = Datum.create(response_value=val)
            batch_data_points.append(datum)
        
        batch_stats = {
            'batch_number': len(batch_results) + 1,
            'size': len(current_batch),
            'min': min(current_batch),
            'max': max(current_batch),
            'mean': sum(current_batch) / len(current_batch),
            'data_points': batch_data_points
        }
        
        batch_results.append(batch_stats)
        print(f"  Final batch {batch_stats['batch_number']}: {batch_stats['size']} points")
    
    return batch_results

# Generate synthetic data
def synthetic_data_generator(n_points=3500):
    """Generate synthetic data with trends and noise."""
    for i in range(n_points):
        # Trend + periodic + noise
        trend = 0.001 * i
        periodic = 2.0 * math.sin(2 * math.pi * i / 100)
        noise = 0.5 * (random.random() - 0.5)
        yield trend + periodic + noise

# Process synthetic data in batches
batches = process_data_in_batches(synthetic_data_generator(), batch_size=500)

print(f"\n✓ Processed {len(batches)} batches")
total_points = sum(batch['size'] for batch in batches)
print(f"✓ Total data points: {total_points}")

# %%
# Multi-Dimensional Data Handling
# --------------------------------
#
# Work with complex multi-dimensional datasets:

def create_3d_dataset():
    """Create a 3D dataset (e.g., 3D NMR or imaging data)."""
    print("Creating 3D dataset...")
    
    # Main dataset
    dataset_3d = Dataset.create(
        title="3D Experiment",
        description="Three-dimensional scientific measurement"
    )
    
    # Three dimensions
    x_dim = Dimension.create_linear(
        label="x_axis",
        description="X spatial dimension",
        count=32,
        start=-10.0,
        increment=0.625,
        unit="mm"
    )
    
    y_dim = Dimension.create_linear(
        label="y_axis",
        description="Y spatial dimension",
        count=32,
        start=-10.0,
        increment=0.625,
        unit="mm"
    )
    
    z_dim = Dimension.create_linear(
        label="z_axis",
        description="Z spatial dimension",
        count=16,
        start=-5.0,
        increment=0.625,
        unit="mm"
    )
    
    # Data variable
    intensity_3d = DependentVariable.create(
        name="voxel_intensity",
        description="3D voxel intensity values",
        unit="arbitrary_units"
    )
    
    print(f"✓ 3D Dataset: {dataset_3d}")
    total_voxels = x_dim.count * y_dim.count * z_dim.count
    print(f"✓ Dimensions: {x_dim.count} × {y_dim.count} × {z_dim.count} = {total_voxels} voxels")
    
    x_extent = x_dim.count * abs(x_dim.increment)
    y_extent = y_dim.count * abs(y_dim.increment)
    z_extent = z_dim.count * abs(z_dim.increment)
    print(f"✓ Spatial extent: {x_extent:.1f} × {y_extent:.1f} × {z_extent:.1f} mm³")
    
    return {
        'dataset': dataset_3d,
        'x_dim': x_dim,
        'y_dim': y_dim,
        'z_dim': z_dim,
        'variable': intensity_3d
    }

# Create 3D dataset
data_3d = create_3d_dataset()

# Simulate 3D data with a spherical feature
def simulate_3d_sphere(center_x=0, center_y=0, center_z=0, radius=5.0, intensity=10.0):
    """Simulate a spherical feature in 3D space."""
    
    x_dim = data_3d['x_dim']
    y_dim = data_3d['y_dim']
    z_dim = data_3d['z_dim']
    
    voxel_data = []
    
    for k in range(z_dim.count):
        z = z_dim.start + k * z_dim.increment
        
        for j in range(y_dim.count):
            y = y_dim.start + j * y_dim.increment
            
            for i in range(x_dim.count):
                x = x_dim.start + i * x_dim.increment
                
                # Calculate distance from sphere center
                distance = math.sqrt((x - center_x)**2 + (y - center_y)**2 + (z - center_z)**2)
                
                # Gaussian falloff from sphere center
                if distance <= radius:
                    value = intensity * math.exp(-(distance / radius)**2)
                else:
                    value = 0.1 * random.random()  # Background noise
                
                datum = Datum.create(response_value=value)
                voxel_data.append({
                    'coordinates': (i, j, k),
                    'position': (x, y, z),
                    'value': value,
                    'datum': datum
                })
    
    return voxel_data

# Simulate 3D sphere data
sphere_data = simulate_3d_sphere(center_x=1.0, center_y=-2.0, center_z=0.5, radius=4.0)

print(f"\n✓ Generated {len(sphere_data)} 3D data points")
print(f"✓ Sphere center: (1.0, -2.0, 0.5) mm")
print(f"✓ Sphere radius: 4.0 mm")

# Find maximum intensity voxel
max_voxel = max(sphere_data, key=lambda v: v['value'])
print(f"✓ Maximum intensity: {max_voxel['value']:.2f} at {max_voxel['position']}")

# %%
# Time Series Data Analysis
# --------------------------
#
# Handle time-dependent measurements:

def create_time_series_experiment():
    """Create a time-series experiment (e.g., kinetics study)."""
    print("Creating time series experiment...")
    
    # Time series dataset
    kinetics_dataset = Dataset.create(
        title="Chemical Kinetics Study",
        description="Time-resolved measurement of reaction progress"
    )
    
    # Time dimension
    time_dim = Dimension.create_linear(
        label="time",
        description="Reaction time",
        count=100,
        start=0.0,
        increment=30.0,  # 30 seconds per point
        unit="s"
    )
    
    # Concentration variables
    reactant_conc = DependentVariable.create(
        name="reactant_concentration",
        description="Reactant concentration",
        unit="mol/L"
    )
    
    product_conc = DependentVariable.create(
        name="product_concentration", 
        description="Product concentration",
        unit="mol/L"
    )
    
    print(f"✓ Kinetics dataset: {kinetics_dataset}")
    end_time = time_dim.start + (time_dim.count-1)*time_dim.increment
    print(f"✓ Time range: {time_dim.start} to {end_time:.0f} seconds")
    print(f"✓ Sampling interval: {time_dim.increment:.0f} seconds")
    
    return {
        'dataset': kinetics_dataset,
        'time_dim': time_dim,
        'reactant_var': reactant_conc,
        'product_var': product_conc
    }

def simulate_first_order_kinetics(initial_conc=1.0, rate_constant=0.01):
    """
    Simulate first-order reaction kinetics: A → B
    [A] = [A]₀ * exp(-kt)
    [B] = [A]₀ * (1 - exp(-kt))
    """
    kinetics = create_time_series_experiment()
    time_dim = kinetics['time_dim']
    
    print(f"\nSimulating first-order kinetics...")
    print(f"Initial concentration: {initial_conc:.2f} mol/L")
    print(f"Rate constant: {rate_constant:.4f} s⁻¹")
    
    reactant_data = []
    product_data = []
    time_points = []
    
    for i in range(time_dim.count):
        time = time_dim.start + i * time_dim.increment
        time_points.append(time)
        
        # First-order kinetics equations
        reactant_conc = initial_conc * math.exp(-rate_constant * time)
        product_conc = initial_conc * (1 - math.exp(-rate_constant * time))
        
        # Add experimental noise
        noise_level = 0.02
        reactant_noise = reactant_conc + noise_level * (random.random() - 0.5)
        product_noise = product_conc + noise_level * (random.random() - 0.5)
        
        # Create data points
        reactant_datum = Datum.create(response_value=max(0, reactant_noise))
        product_datum = Datum.create(response_value=max(0, product_noise))
        
        reactant_data.append({
            'time': time,
            'concentration': reactant_noise,
            'datum': reactant_datum
        })
        
        product_data.append({
            'time': time,
            'concentration': product_noise,
            'datum': product_datum
        })
    
    return {
        'kinetics': kinetics,
        'reactant_data': reactant_data,
        'product_data': product_data,
        'time_points': time_points
    }

# Simulate kinetics experiment
kinetics_result = simulate_first_order_kinetics(initial_conc=2.0, rate_constant=0.008)

# Analyze half-life
half_life = math.log(2) / 0.008  # t₁/₂ = ln(2)/k
print(f"\n✓ Theoretical half-life: {half_life:.1f} seconds")

# Find experimental half-life
initial_conc = kinetics_result['reactant_data'][0]['concentration']
target_conc = initial_conc / 2

for data_point in kinetics_result['reactant_data']:
    if data_point['concentration'] <= target_conc:
        experimental_half_life = data_point['time']
        print(f"✓ Experimental half-life: ~{experimental_half_life:.0f} seconds")
        break

print(f"✓ Generated {len(kinetics_result['reactant_data'])} time points")
final_reactant = kinetics_result['reactant_data'][-1]['concentration']
final_product = kinetics_result['product_data'][-1]['concentration']
print(f"✓ Final reactant concentration: {final_reactant:.3f} mol/L")
print(f"✓ Final product concentration: {final_product:.3f} mol/L")

# %%
# Statistical Analysis of Data
# ----------------------------
#
# Perform statistical analysis on datasets:

def statistical_analysis(data_points, label="Dataset"):
    """Perform comprehensive statistical analysis on data points."""
    print(f"\n=== Statistical Analysis: {label} ===")
    
    if not data_points:
        print("No data points provided")
        return
    
    # Extract values
    if hasattr(data_points[0], 'concentration'):
        values = [dp.concentration for dp in data_points]
    elif hasattr(data_points[0], 'value'):
        values = [dp.value for dp in data_points]
    elif isinstance(data_points[0], dict) and 'concentration' in data_points[0]:
        values = [dp['concentration'] for dp in data_points]
    elif isinstance(data_points[0], dict) and 'value' in data_points[0]:
        values = [dp['value'] for dp in data_points]
    else:
        print("Could not extract values from data points")
        return
    
    n = len(values)
    
    # Basic statistics
    min_val = min(values)
    max_val = max(values)
    mean_val = sum(values) / n
    
    # Variance and standard deviation
    variance = sum((x - mean_val)**2 for x in values) / (n - 1) if n > 1 else 0
    std_dev = math.sqrt(variance)
    
    # Median
    sorted_values = sorted(values)
    if n % 2 == 0:
        median = (sorted_values[n//2 - 1] + sorted_values[n//2]) / 2
    else:
        median = sorted_values[n//2]
    
    # Quartiles
    q1_idx = n // 4
    q3_idx = 3 * n // 4
    q1 = sorted_values[q1_idx] if q1_idx < n else sorted_values[-1]
    q3 = sorted_values[q3_idx] if q3_idx < n else sorted_values[-1]
    iqr = q3 - q1
    
    # Coefficient of variation
    cv = (std_dev / mean_val * 100) if mean_val != 0 else 0
    
    # Outlier detection (simple IQR method)
    lower_bound = q1 - 1.5 * iqr
    upper_bound = q3 + 1.5 * iqr
    outliers = [v for v in values if v < lower_bound or v > upper_bound]
    
    print(f"Sample size: {n}")
    print(f"Mean: {mean_val:.4f}")
    print(f"Median: {median:.4f}")
    print(f"Standard deviation: {std_dev:.4f}")
    print(f"Coefficient of variation: {cv:.2f}%")
    print(f"Range: [{min_val:.4f}, {max_val:.4f}]")
    print(f"Quartiles: Q1={q1:.4f}, Q3={q3:.4f}, IQR={iqr:.4f}")
    print(f"Outliers: {len(outliers)} detected")
    
    return {
        'n': n,
        'mean': mean_val,
        'median': median,
        'std_dev': std_dev,
        'variance': variance,
        'min': min_val,
        'max': max_val,
        'q1': q1,
        'q3': q3,
        'iqr': iqr,
        'cv': cv,
        'outliers': outliers
    }

# Analyze kinetics data
reactant_stats = statistical_analysis(
    kinetics_result['reactant_data'], 
    "Reactant Concentration"
)

product_stats = statistical_analysis(
    kinetics_result['product_data'], 
    "Product Concentration"
)

# Analyze 3D sphere data
sphere_stats = statistical_analysis(
    sphere_data,
    "3D Sphere Intensity"
)

# %%
# Memory Management Best Practices
# --------------------------------
#
# Learn efficient memory usage patterns:

def demonstrate_memory_efficiency():
    """Demonstrate memory-efficient practices with RMNpy."""
    print("=== Memory Management Best Practices ===")
    
    # 1. Lazy data generation
    def data_generator(n):
        """Generate data on-demand instead of storing all in memory."""
        for i in range(n):
            value = math.sin(2 * math.pi * i / 100) + 0.1 * random.random()
            yield Datum.create(response_value=value)
    
    print("\n1. Lazy Data Generation:")
    print("   ✓ Generate data points on-demand")
    print("   ✓ Process data in chunks")
    print("   ✓ Avoid storing large arrays")
    
    # 2. Efficient object reuse
    print("\n2. Object Reuse:")
    
    # Create reusable dimension template
    standard_dim = Dimension.create_linear(
        label="standard_axis",
        description="Standard measurement axis",
        count=1000,
        start=0.0,
        increment=0.001,
        unit="s"
    )
    
    # Create reusable variable template
    standard_var = DependentVariable.create(
        name="standard_signal",
        description="Standard signal measurement",
        unit="V"
    )
    
    print("   ✓ Reuse dimension and variable objects")
    print("   ✓ Create template objects once")
    
    # 3. Memory-conscious data processing
    print("\n3. Memory-Conscious Processing:")
    
    def process_large_dataset_efficiently(size=10000, chunk_size=1000):
        """Process large dataset in memory-efficient chunks."""
        
        processed_chunks = 0
        total_sum = 0.0
        total_count = 0
        
        for chunk_start in range(0, size, chunk_size):
            chunk_end = min(chunk_start + chunk_size, size)
            chunk_data = []
            
            # Process one chunk
            for i in range(chunk_start, chunk_end):
                value = math.sin(2 * math.pi * i / 1000) + 0.05 * random.random()
                datum = Datum.create(response_value=value)
                chunk_data.append(value)
            
            # Calculate chunk statistics
            chunk_sum = sum(chunk_data)
            total_sum += chunk_sum
            total_count += len(chunk_data)
            
            processed_chunks += 1
            
            # Clear chunk data from memory
            del chunk_data
        
        average = total_sum / total_count if total_count > 0 else 0
        
        return {
            'processed_chunks': processed_chunks,
            'total_points': total_count,
            'average_value': average
        }
    
    # Process large dataset efficiently
    result = process_large_dataset_efficiently(size=25000, chunk_size=2500)
    
    print(f"   ✓ Processed {result['total_points']} points in {result['processed_chunks']} chunks")
    print(f"   ✓ Average value: {result['average_value']:.4f}")
    print(f"   ✓ Memory usage: constant (chunk-based processing)")
    
    print("\n=== Memory Management Summary ===")
    print("✓ Use lazy data generation")
    print("✓ Process data in chunks")
    print("✓ Reuse template objects")
    print("✓ Clean up temporary data")
    print("✓ Handle errors gracefully")

# Demonstrate memory management
demonstrate_memory_efficiency()

# %%
# Summary
# -------
#
# This example covered advanced RMNpy techniques:
#
# 1. **Large Dataset Handling** - Efficient creation and management
# 2. **Batch Processing** - Memory-efficient data processing
# 3. **Multi-Dimensional Data** - 3D datasets and spatial analysis
# 4. **Time Series Analysis** - Kinetics and time-dependent studies
# 5. **Statistical Analysis** - Comprehensive data statistics
# 6. **Memory Management** - Best practices for efficiency
#
# Key Takeaways
# -------------
#
# - **Scalability**: RMNpy handles datasets from small experiments to large-scale studies
# - **Flexibility**: Support for 1D, 2D, 3D, and time series data
# - **Efficiency**: Memory-conscious processing for large datasets
# - **Analysis**: Built-in support for statistical analysis and filtering
# - **Safety**: Proper error handling and resource management
