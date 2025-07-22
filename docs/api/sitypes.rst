SITypes Wrappers
================

The SITypes module provides Python wrappers for physical units, dimensions, and scalar quantities with automatic dimensional analysis and unit conversion. This system eliminates unit conversion errors and enables confident scientific computing with built-in dimensional safety.

.. currentmodule:: rmnpy.wrappers.sitypes

Overview
--------

**Never worry about unit conversions again.** The SITypes wrappers provide automatic unit tracking, conversion, and dimensional analysis for scientific computing:

* **Scalar**: The primary interface - combines values with units for safe arithmetic operations
* **Unit**: Represents and manipulates physical units (meter, kilogram, joule, etc.)  
* **Dimensionality**: Handles physical dimensions for advanced dimensional analysis

Key Benefits
~~~~~~~~~~~~

* **Eliminate Unit Errors**: Automatic dimensional checking prevents common calculation mistakes
* **Seamless Conversions**: Convert between any compatible units effortlessly
* **Scientific Accuracy**: Built on the internationally recognized SI system with precise physical constants
* **Intuitive API**: Natural syntax that reads like mathematical expressions
* **Complex Number Support**: Full support for complex quantities in engineering applications
* **Mathematical Functions**: Complete library of mathematical functions that work seamlessly with units
* **Chemical Database**: Built-in atomic weights, isotopic properties, and NMR parameters

Quick Start
-----------

**Get started immediately with our flexible API:**

.. code-block:: python

   from rmnpy.wrappers.sitypes import Scalar, Unit, Dimensionality
   
   # === Multiple Ways to Create the Same Quantity ===
   
   # Simple string expressions (most intuitive)
   energy = Scalar("100 J")           # 100 Joules
   power = Scalar("2.5 kW")           # 2.5 kilowatts
   
   # Separate value and unit (programmatic)
   distance = Scalar(50, "m")         # 50 meters  
   temperature = Scalar(273.15, "K")  # 273.15 Kelvin
   
   # Complex numbers for engineering
   impedance = Scalar(3+4j, "ohm")    # Complex impedance
   
   # === Automatic Unit Arithmetic ===
   
   time = Scalar("5 s")
   velocity = distance / time         # Result: 10 m/s (automatic units!)
   
   mass = Scalar("2 kg") 
   momentum = mass * velocity         # Result: 20 kg*m/s (automatic units!)
   
   # === Effortless Unit Conversions ===
   
   speed_ms = Scalar("100 m/s")
   speed_kmh = speed_ms.convert_to("km/h")     # Result: 360 km/h
   speed_mph = speed_ms.convert_to("mph")      # Result: 223.694 mph
   
   # === Dimensional Safety (Catches Errors) ===
   
   try:
       invalid = distance + time      # Error: Cannot add length + time!
   except Exception as e:
       print("Dimensional mismatch prevented an error!")
   
   # === Advanced: Work with Units and Dimensions ===
   
   # Build complex units programmatically
   newton = Unit("kg*m/s^2")         # Force unit
   joule = newton * Unit("m")         # Energy = Force × Distance
   
   # Dimensional analysis for physics
   force_dim = Dimensionality("M*L/T^2")      # Force dimension
   energy_dim = force_dim * Dimensionality("L")  # Energy dimension

Real-World Applications
-----------------------

**From Physics Labs to Engineering Design**

.. code-block:: python

   # === Physics Calculations ===
   
   # Kinetic energy calculation
   mass = Scalar("2 kg")
   velocity = Scalar("10 m/s") 
   kinetic_energy = 0.5 * mass * velocity**2   # Result: 100 J
   
   # Electromagnetic calculations
   current = Scalar("2 A")
   resistance = Scalar("5 ohm")
   power = current**2 * resistance             # Result: 20 W
   voltage = current * resistance              # Result: 10 V
   
   # === Engineering Applications ===
   
   # Fluid dynamics
   density = Scalar("1000 kg/m^3")
   flow_rate = Scalar("0.1 m^3/s")
   mass_flow = density * flow_rate             # Result: 100 kg/s
   
   # Thermal calculations  
   heat_capacity = Scalar("4186 J/(kg*K)")
   mass_water = Scalar("2 kg")
   temp_change = Scalar("50 K")
   energy_needed = heat_capacity * mass_water * temp_change  # Result: 418600 J
   
   # === Unit Conversions in Practice ===
   
   # Convert between measurement systems
   pressure_psi = Scalar("14.7 psi")
   pressure_pa = pressure_psi.convert_to("Pa")     # Result: 101353 Pa
   pressure_bar = pressure_psi.convert_to("bar")   # Result: 1.01353 bar
   
   # Energy unit conversions
   energy_cal = Scalar("1000 cal")
   energy_j = energy_cal.convert_to("J")           # Result: 4184 J
   energy_kwh = energy_j.convert_to("kWh")         # Result: 0.001162 kWh

Mathematical Functions with Units
---------------------------------

**SITypes supports mathematical functions within string expressions for Scalar creation:**

.. code-block:: python

   from rmnpy.wrappers.sitypes import Scalar
   
   # === Trigonometric Functions in String Expressions ===
   
   # Functions can be used directly in expressions
   result1 = Scalar("sin(45 °)")          # Sine of 45 degrees
   result2 = Scalar("cos(π/4)")           # Cosine of π/4 radians
   result3 = Scalar("tan(30 °)")          # Tangent of 30 degrees
   
   # Inverse trigonometric functions
   result4 = Scalar("asin(0.5)")          # Arcsine of 0.5
   result5 = Scalar("acos(0.707)")        # Arccosine of 0.707
   result6 = Scalar("atan(1.0)")          # Arctangent of 1.0
   
   # === Exponential and Logarithmic Functions ===
   
   # Exponential functions
   exp_result = Scalar("exp(2.0)")        # e^2.0
   power_result = Scalar("2^3")           # 2^3 = 8
   
   # Logarithmic functions
   ln_result = Scalar("ln(2.718)")        # Natural logarithm
   log_result = Scalar("log10(100)")      # Base 10 logarithm
   log2_result = Scalar("log2(8)")        # Base 2 logarithm
   
   # === Root Functions ===
   
   # Square root and other roots
   sqrt_result = Scalar("sqrt(25) m")     # Square root with units
   cbrt_result = Scalar("cbrt(27) m")     # Cube root with units
   qurt_result = Scalar("qurt(16) m")     # Quartic (fourth) root with units
   
   # === Hyperbolic Functions ===
   
   sinh_result = Scalar("sinh(1.0)")      # Hyperbolic sine
   cosh_result = Scalar("cosh(1.0)")      # Hyperbolic cosine
   tanh_result = Scalar("tanh(1.0)")      # Hyperbolic tangent
   
   # Inverse hyperbolic functions
   asinh_result = Scalar("asinh(1.175)")  # Inverse hyperbolic sine
   acosh_result = Scalar("acosh(1.543)")  # Inverse hyperbolic cosine
   atanh_result = Scalar("atanh(0.5)")    # Inverse hyperbolic tangent
   
   # === Complex Mathematical Expressions ===
   
   # Combine functions with arithmetic
   complex_expr = Scalar("sin(45 °) * cos(30 °) * 10 N")
   
   # Functions with physical quantities
   kinetic = Scalar("0.5 * 2 kg * (10 m/s)^2")  # Kinetic energy formula
   
   # Use constants like π and e
   circle_area = Scalar("π * (5 m)^2")          # Area of circle

Chemical and Physical Constants
-------------------------------

**Built-in database of atomic, isotopic, and NMR properties accessible in string expressions:**

.. code-block:: python

   # === Atomic Properties in Expressions ===
   
   # Atomic weights (aw function with square brackets)
   carbon_aw = Scalar("aw[C]")               # Atomic weight of carbon (with units)
   hydrogen_aw = Scalar("aw[H]")             # Atomic weight of hydrogen (with units)
   
   # Isotopic atomic weights
   carbon13_aw = Scalar("aw[C13]")           # Atomic weight of ¹³C isotope (with units)
   oxygen16_aw = Scalar("aw[O16]")           # Atomic weight of ¹⁶O isotope (with units)
   
   # Formula weights (fw function)  
   water_fw = Scalar("fw[H2O]")              # Formula weight of water (with units)
   methane_fw = Scalar("fw[CH4]")            # Formula weight of methane (with units)
   
   # Calculate molar quantities
   water_moles = Scalar("18 g / fw[H2O]")    # Moles from mass
   
   # === Isotopic Properties ===
   
   # Isotopic abundances (abundance function with square brackets)
   c13_fraction = Scalar("abundance[C13]")         # Natural abundance of ¹³C
   b10_fraction = Scalar("abundance[B10]")         # Natural abundance of ¹⁰B
   enriched_sample = Scalar("0.1 mol * abundance[C13]")  # Amount of ¹³C
   
   # === NMR Parameters ===
   
   # Note: The exact syntax for NMR functions (γ_I, μ_I, etc.) may vary
   # These examples show the general pattern - check SITypes documentation for exact syntax
   
   # Gyromagnetic ratios in NMR calculations
   h_frequency = Scalar("γ_I[H1] * 1.5 T")      # ¹H angular frequency at 1.5 Tesla
   c_frequency = Scalar("γ_I[C13] * 1.5 T")     # ¹³C angular frequency at 1.5 Tesla
   
   # Nuclear magnetic moments
   h_energy = Scalar("μ_I[H1] * 1.5 T")         # ¹H interaction energy
   
   # NMR reduced gyromagnetic ratios
   h_nmr_freq = Scalar("nmr[H1] * 1.5 T")       # ¹H NMR frequency
   c_nmr_freq = Scalar("nmr[C13] * 1.5 T")      # ¹³C NMR frequency
   
   # Nuclear spins in quantum calculations
   h_levels = Scalar("2 * spin[H1] + 1")        # Number of spin levels for ¹H
   n_levels = Scalar("2 * spin[N14] + 1")       # Number of spin levels for ¹⁴N
   
   # Electric quadrupole calculations
   quad_interaction = Scalar("Q_I[N14] * 1e6 V/m^2")  # Quadrupole interaction

Advanced Mathematical Operations
-------------------------------

**Specialized functions and unit operations in expressions:**

.. code-block:: python

   # === Unit Reduction Function ===
   
   # The reduce() function simplifies complex derived units
   simplified = Scalar("reduce(kg*m^2*s^-2)")     # Simplifies to "J" (joules)
   energy_form = Scalar("reduce(N*m)")            # Simplifies to "J" (joules)
   
   # === Complex Expressions with Multiple Functions ===
   
   # Combine mathematical functions with physical constants
   resonance_freq = Scalar("γ_I[H1] * 1.5 T / (2 * π)")
   
   # Calculate decay with exponential
   decay_amount = Scalar("100 Bq * exp(-ln(2) * 5 s / 10 s)")  # Half-life decay
   
   # Oscillatory behavior
   amplitude = Scalar("10 V * sin(2 * π * 60 Hz * 0.01 s)")
   
   # === Constants Available in Expressions ===
   
   # Mathematical constants
   circle_circumference = Scalar("2 * π * 5 m")       # Using π
   euler_calculation = Scalar("e^2")                   # Using e (Euler's number)
   
   # Physical constants (examples)
   planck_energy = Scalar("h_P * c / (500e-9 m)")         # Photon energy (if h, c available)
   
   # === Practical NMR Examples ===
   
   # Larmor frequency calculation
   larmor_H1 = Scalar("γ_I[H1] * 9.4 T / (2 * π)")      # ¹H Larmor frequency at 9.4T
   larmor_C13 = Scalar("γ_I[C13] * 9.4 T / (2 * π)")    # ¹³C Larmor frequency at 9.4T
   
   # Chemical shift calculation
   ppm_shift = Scalar("γ_I[H1] * 9.4 T * 2.5e-6")      # 2.5 ppm shift frequency
   
   # Quadrupole interaction
   quad_freq = Scalar("3 * Q_I[N14] * 1e6 V/m^2 / (2 * spin[N14] * (2 * spin[N14] - 1))")

Classes
-------

.. toctree::
   :maxdepth: 2
   
   sitypes/scalar
   sitypes/unit  
   sitypes/dimensionality

Module Reference
----------------

.. automodule:: rmnpy.wrappers.sitypes.scalar
   :members:
   :undoc-members:
   :show-inheritance:

.. automodule:: rmnpy.wrappers.sitypes.unit
   :members:
   :undoc-members:
   :show-inheritance:

.. automodule:: rmnpy.wrappers.sitypes.dimensionality
   :members:
   :undoc-members:
   :show-inheritance:
