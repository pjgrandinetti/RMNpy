Scalar
======

.. currentmodule:: rmnpy.wrappers.sitypes

.. autoclass:: Scalar
   :members:
   :undoc-members:
   :show-inheritance:

Overview
--------

The :class:`Scalar` class combines a numerical value with a physical unit, enabling type-safe scientific computing with automatic dimensional analysis and unit conversion. This is the primary class for working with physical quantities.

Why Use Scalar?
---------------

**Eliminate Unit Conversion Errors Forever**

Traditional scientific computing is error-prone:

.. code-block:: python

   # Traditional approach (ERROR-PRONE!)
   distance_m = 1000      # meters? feet? who knows?
   time_s = 3600          # seconds? minutes? 
   speed = distance_m / time_s  # Units completely lost!

With Scalar, units are **tracked automatically**:

.. code-block:: python

   # Safe approach with Scalar
   distance = Scalar("1000 m")     # Clearly 1000 meters
   time = Scalar("1 h")            # Clearly 1 hour  
   speed = distance / time         # Result: 0.278 m/s (automatic!)
   
   # Convert to any compatible unit instantly
   speed_kmh = speed.convert_to("km/h")  # Result: 1.0 km/h
   speed_mph = speed.convert_to("mph")   # Result: 0.621 mph

**Key Benefits:**

* **Dimensional Safety**: Prevents adding incompatible quantities (length + time)
* **Automatic Unit Derivation**: Multiplication/division creates correct derived units
* **Effortless Conversions**: Convert between any compatible units instantly
* **Scientific Accuracy**: Built on precise SI definitions and constants
* **Complex Number Support**: Full support for engineering applications
* **Mathematical Functions**: Complete function library (trig, log, exp, roots) that preserves units
* **Chemical Database**: Built-in atomic weights, isotopic properties, and NMR parameters

Usage Examples
--------------

Creating Scalars
~~~~~~~~~~~~~~~~

The Scalar constructor offers **maximum flexibility** with intelligent argument handling:

.. code-block:: python

   from rmnpy.wrappers.sitypes import Scalar
   
   # === Single String Expressions (Most Intuitive) ===
   distance = Scalar("5.0 m")          # 5 meters
   velocity = Scalar("25 m/s")         # 25 meters per second  
   energy = Scalar("500 J")            # 500 joules
   power = Scalar("2.5 kW")            # 2.5 kilowatts
   
   # Complex units work seamlessly
   acceleration = Scalar("9.8 m/s^2")  # 9.8 m/s²
   pressure = Scalar("101.3 kPa")      # 101.3 kilopascals
   
   # === Single Numeric Values (Dimensionless) ===
   ratio = Scalar(0.75)                # 0.75 (dimensionless)
   count = Scalar(42)                  # 42 (dimensionless)
   
   # Complex numbers supported
   impedance = Scalar(3+4j)            # (3+4j) (dimensionless)
   
   # === Value and Unit Pairs (Programmatic) ===
   mass = Scalar(10.5, "kg")           # 10.5 kilograms
   temperature = Scalar(273.15, "K")   # 273.15 Kelvin
   current = Scalar(3+4j, "A")         # (3+4j) Amperes
   
   # String values work too
   distance_str = Scalar("100", "m")   # 100 meters
   
   # === Named Parameters (Most Explicit) ===
   unit_meter = Scalar(expression="m")                    # 1 meter
   force = Scalar(value=9.8, expression="kg*m/s^2")      # 9.8 Newtons
   mixed = Scalar(value=50, expression="mph")             # 50 mph
   
   # === Backward Compatibility ===
   legacy = Scalar.parse("273.15 K")   # Same as Scalar("273.15 K")

Scalar Arithmetic
~~~~~~~~~~~~~~~~~

.. code-block:: python

   # Basic arithmetic with dimensional checking
   distance = Scalar("100.0 m")
   time = Scalar("5.0 s")
   
   # Division creates new units automatically
   velocity = distance / time           # 20.0 m/s
   
   # Multiplication combines units
   area = distance * Scalar("50.0 m")   # 5000.0 m²
   volume = area * Scalar("2.0 m")      # 10000.0 m³
   
   # Addition/subtraction requires compatible units
   distance1 = Scalar("100.0 m")
   distance2 = Scalar("50.0 m") 
   total_distance = distance1 + distance2  # 150.0 m
   
   # Powers
   area_alt = distance ** 2             # 10000.0 m²
   cube_root = volume ** (1/3)          # 21.54... m

Unit Conversion
~~~~~~~~~~~~~~~

.. code-block:: python

   # Convert between compatible units
   velocity_ms = Scalar("10.0 m/s")               # 10 m/s
   velocity_kmh = velocity_ms.convert_to("km/h")  # 36.0 km/h
   
   # Convert with explicit target unit
   from rmnpy.wrappers.sitypes import Unit
   mph_unit, _ = Unit.parse("mph")
   velocity_mph = velocity_ms.convert_to(mph_unit)  # ~22.37 mph
   
   # Check if conversion is possible
   length = Scalar("5.0 m")
   time = Scalar("2.0 s")
   print(length.can_convert_to("ft"))   # True (length to length)
   print(length.can_convert_to("s"))    # False (length to time)

Practical Applications
~~~~~~~~~~~~~~~~~~~~~~

**Real-world examples showing the power of automatic unit handling:**

.. code-block:: python

   # === Physics Laboratory ===
   
   # Kinetic energy calculation
   mass = Scalar("2.5 kg")
   velocity = Scalar("15 m/s")
   kinetic_energy = 0.5 * mass * velocity**2
   print(kinetic_energy)                    # 281.25 J (automatic units!)
   
   # Convert to other energy units
   energy_cal = kinetic_energy.convert_to("cal")   # 67.2 cal
   energy_kwh = kinetic_energy.convert_to("kWh")   # 7.81e-05 kWh
   
   # === Engineering Design ===
   
   # Electrical power calculation
   voltage = Scalar("120 V")
   current = Scalar("5 A")  
   power = voltage * current               # 600 W (automatic units!)
   
   # Convert power units
   power_hp = power.convert_to("hp")       # 0.805 hp
   power_btuh = power.convert_to("Btu/h")  # 2047 Btu/h
   
   # === Fluid Mechanics ===
   
   # Flow rate calculation
   area = Scalar("0.5 m^2")
   velocity_fluid = Scalar("2 m/s")
   volume_flow = area * velocity_fluid     # 1.0 m^3/s
   
   # Convert flow units
   flow_gpm = volume_flow.convert_to("gal/min")  # 15850 gal/min
   flow_lps = volume_flow.convert_to("L/s")      # 1000 L/s
   
   # === Chemistry ===
   
   # Concentration and amount calculations  
   molarity = Scalar("0.1 mol/L")
   volume = Scalar("500 mL")
   moles = molarity * volume               # 0.05 mol (automatic units!)
   
   # Gas law calculations
   pressure = Scalar("1 atm")
   volume_gas = Scalar("22.4 L") 
   temperature = Scalar("273.15 K")
   # PV = nRT calculations with automatic unit checking

Scalar Properties
~~~~~~~~~~~~~~~~~

.. code-block:: python

   velocity = Scalar("25.0 m/s")
   
   # Access components
   print(velocity.value)                # 25.0
   print(velocity.unit)                 # Unit('m/s')
   print(velocity.dimensionality)       # Dimensionality('L/T')
   
   # String representations
   print(str(velocity))                 # "25.0 m/s"
   print(repr(velocity))                # "Scalar('25.0 m/s')"
   
   # Check properties
   print(velocity.is_dimensionless)     # False
   print(velocity.is_zero)              # False

Dimensional Analysis
~~~~~~~~~~~~~~~~~~~~

.. code-block:: python

   # Automatic dimensional checking prevents errors
   mass = Scalar("5.0 kg")
   acceleration = Scalar("9.8 m/s^2")
   force = mass * acceleration          # 49.0 kg*m/s² (Newtons)
   
   # Error handling for incompatible operations
   try:
       invalid = mass + acceleration    # Error: can't add mass + acceleration
   except RMNError as e:
       print(f"Dimensional error: {e}")
   
   # Complex calculations maintain dimensional integrity
   velocity = Scalar("10.0 m/s")
   kinetic_energy = 0.5 * mass * velocity ** 2  # 0.5 * kg * (m/s)² = kg*m²/s² (Joules)

Mathematical Functions
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: python

   import math
   
   # Trigonometric functions require dimensionless arguments
   angle = Scalar("1.57 rad")           # π/2 radians (90 degrees)
   sine_value = angle.sin()             # Dimensionless result
   
   # Logarithmic functions
   ratio = Scalar("2.718 1")            # Dimensionless (note: "1" for dimensionless)
   log_value = ratio.ln()               # Natural logarithm
   
   # Square root
   area = Scalar("25.0 m^2")
   side_length = area.sqrt()            # 5.0 m

Error Handling
~~~~~~~~~~~~~~

.. code-block:: python

   from rmnpy.exceptions import RMNError
   
   try:
       # Dimensional mismatch
       length = Scalar("5.0 m")
       time = Scalar("2.0 s")
       invalid = length + time          # Error: L + T
   except RMNError as e:
       print(f"Cannot add length and time: {e}")
   
   try:
       # Invalid unit conversion
       length = Scalar("10.0 m")
       invalid = length.convert_to("kg")  # Error: length to mass
   except RMNError as e:
       print(f"Invalid conversion: {e}")
   
   try:
       # Invalid expression format
       invalid = Scalar("not a valid expression")
   except ValueError as e:
       print(f"Parsing error: {e}")

Class Reference
---------------

.. autoclass:: Scalar
   :members:
   :special-members: __init__, __add__, __sub__, __mul__, __truediv__, __pow__, __eq__, __str__, __repr__
   :exclude-members: __weakref__
