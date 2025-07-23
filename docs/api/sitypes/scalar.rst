Scalar
======

.. currentmodule:: rmnpy.wrappers.sitypes

.. autoclass:: Scalar
   :members:
   :undoc-members:
   :show-inheritance:

Overview
--------

The :class:`Scalar` class is the primary interface for working with physical quantities that have both a numerical value and a unit. It provides automatic dimensional analysis, unit conversion, and mathematical operations while maintaining dimensional safety.

Basic Usage
-----------

**Creating Scalar Objects**

.. code-block:: python

   from rmnpy.wrappers.sitypes import Scalar
   
   # Simple value with unit
   distance = Scalar("5.0 m")                    # 5 meters
   velocity = Scalar("25 m/s")                   # 25 meters per second  
   energy = Scalar("500 J")                      # 500 joules
   
   # Programmatic assignment (value, unit pairs)
   mass = Scalar(10.5, "kg")                     # 10.5 kilograms
   temperature = Scalar(273.15, "K")             # 273.15 Kelvin
   impedance = Scalar(3+4j, "Ω")                 # Complex impedance
   
   # Complex mathematical expressions (see SITypes overview for full details)
   kinetic_energy = Scalar("0.5 * 2 kg * (10 m/s)^2")  # 100 J
   larmor_freq = Scalar("γ_I[H1] * 9.4 T / (2 * π)")   # NMR frequency
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

Mathematical Functions on Scalar Objects
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Beyond expression-based calculations, you can also call mathematical functions directly on Scalar objects:

.. code-block:: python

   # Functions on existing Scalar objects
   angle = Scalar("1.57 rad")           # π/2 radians (90 degrees)
   sine_value = angle.sin()             # Dimensionless result
   
   # Logarithmic functions on Scalar objects
   ratio = Scalar("2.718")              # Dimensionless value
   log_value = ratio.ln()               # Natural logarithm
   
   # Square root preserves units
   area = Scalar("25.0 m^2")
   side_length = area.sqrt()            # 5.0 m
   
   # Complex number operations
   impedance = Scalar("3+4j Ω")
   magnitude = impedance.abs()          # 5.0 Ω
   phase = impedance.argument()         # Phase angle in radians

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
