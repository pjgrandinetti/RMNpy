Dimensionality
==============

.. currentmodule:: rmnpy.wrappers.sitypes

.. autoclass:: Dimensionality
   :members:
   :undoc-members:
   :show-inheritance:

Overview
--------

The :class:`Dimensionality` class represents physical dimensionalities for advanced dimensional analysis. Built on the seven SI base dimensions, it enables validation of physical equations and dimensional consistency checking.

**Enhanced API**: Like Unit and Scalar, Dimensionality now supports simple string construction for improved usability.

**SI Base Dimensions:**

* **Length (L)**: meter [m]
* **Mass (M)**: kilogram [kg]
* **Time (T)**: second [s]
* **Current (I)**: ampere [A]
* **Temperature (K)**: kelvin [K]
* **Amount (N)**: mole [mol]
* **Luminous Intensity (J)**: candela [cd]

Usage Examples
--------------

Creating Dimensionalities
~~~~~~~~~~~~~~~~~~~~~~~~~

**Flexible construction approaches:**

.. code-block:: python

   from rmnpy.wrappers.sitypes import Dimensionality

   # === Simple String Constructor (Enhanced API) ===
   length = Dimensionality("L")           # Length dimension
   velocity = Dimensionality("L/T")       # Velocity dimension
   force = Dimensionality("M*L/T^2")      # Force dimension
   energy = Dimensionality("M*L^2/T^2")   # Energy dimension

   # === Traditional Parse Method (Backward Compatible) ===
   velocity_old = Dimensionality.parse("L/T")        # Same result
   force_old = Dimensionality.parse("M*L/T^2")       # Same result

   # Both approaches are equivalent
   assert velocity == velocity_old
   assert force == force_old

Dimensional Algebra
~~~~~~~~~~~~~~~~~~~

**Build complex dimensionalities through arithmetic operations:**

.. code-block:: python

   # === Fundamental Dimensions ===
   length = Dimensionality("L")         # Length
   mass = Dimensionality("M")           # Mass
   time = Dimensionality("T")           # Time

   # === Derived Dimensions Through Algebra ===
   area = length * length               # L² (area)
   volume = area * length               # L³ (volume)
   velocity = length / time             # L/T (velocity)
   acceleration = velocity / time       # L/T² (acceleration)
   force = mass * acceleration          # M*L/T² (force)
   energy = force * length              # M*L²/T² (energy)
   power = energy / time                # M*L²/T³ (power)
   pressure = force / area              # M/(L*T²) (pressure)

   # === Dimensional Analysis Applications ===

   # Validate physics equations
   kinetic_energy_dim = mass * velocity**2   # M*(L/T)² = M*L²/T²
   print(kinetic_energy_dim == energy)       # True - dimensionally consistent!

   # Check compatibility
   momentum_dim = mass * velocity            # M*L/T
   impulse_dim = force * time                # (M*L/T²)*T = M*L/T
   print(momentum_dim == impulse_dim)        # True - momentum = impulse!

Practical Dimensional Analysis
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Real-world validation of physical relationships:**

.. code-block:: python

   # === Verify Famous Physics Equations ===

   # Einstein's E = mc²
   c_dim = Dimensionality("L/T")        # Speed of light
   E_dim = mass * c_dim**2              # M*(L/T)² = M*L²/T²
   print(E_dim == energy)               # True - energy is correct!

   # Newton's F = ma
   F_calculated = mass * acceleration   # M * L/T² = M*L/T²
   print(F_calculated == force)         # True - force equation is valid!

   # Pressure formula P = F/A
   P_calculated = force / area          # (M*L/T²)/L² = M/(L*T²)
   print(P_calculated == pressure)      # True - pressure formula is valid!

   # === Engineering Applications ===

   # Fluid dynamics: Reynolds number should be dimensionless
   reynolds_dim = (velocity * length) / Dimensionality("L²/T")  # Should be dimensionless
   print(reynolds_dim.is_dimensionless) # True - Reynolds number is dimensionless!

   # Electrical: Power = Voltage × Current
   voltage_dim = Dimensionality("M*L²/(I*T³)")  # Voltage dimension
   current_dim = Dimensionality("I")            # Current dimension
   power_electrical = voltage_dim * current_dim # Should equal mechanical power
   print(power_electrical == power)             # True - electrical power = mechanical power!

Factory Methods
~~~~~~~~~~~~~~~

.. code-block:: python

   # Create common dimensionalities
   dimensionless = Dimensionality.dimensionless()
   length = Dimensionality.for_quantity("length")
   mass = Dimensionality.for_quantity("mass")
   time = Dimensionality.for_quantity("time")

Class Reference
---------------

.. autoclass:: Dimensionality
   :members:
   :special-members: __init__, __mul__, __truediv__, __pow__, __eq__, __str__
   :exclude-members: __weakref__
