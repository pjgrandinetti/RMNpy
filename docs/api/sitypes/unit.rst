Unit
====

.. currentmodule:: rmnpy.wrappers.sitypes

.. autoclass:: Unit
   :members:
   :undoc-members:
   :show-inheritance:

Overview
--------

The :class:`Unit` class represents physical units and supports unit arithmetic, parsing, and conversion operations. Units form the foundation of the SITypes system, built from the seven SI base units and combinable into any derived unit.

**Enhanced API**: The Unit constructor now accepts simple string expressions directly, making unit creation more intuitive while maintaining full backward compatibility.

Usage Examples
--------------

Creating Units
~~~~~~~~~~~~~~

**Multiple approaches for maximum flexibility:**

.. code-block:: python

   from rmnpy.wrappers.sitypes import Unit
   
   # === Simple String Constructor (New Enhanced API) ===
   meter = Unit("m")                    # Meter unit
   velocity_unit = Unit("m/s")          # Velocity unit  
   force_unit = Unit("kg*m/s^2")        # Force unit (Newton)
   
   # Units with prefixes
   kilometer = Unit("km")               # Kilometer
   microsecond = Unit("μs")             # Microsecond
   
   # === Traditional Parse Method (Backward Compatible) ===
   meter_old, mult = Unit.parse("m")           # (Unit('m'), 1.0)
   velocity_old, mult = Unit.parse("m/s")      # (Unit('m/s'), 1.0) 
   force_old, mult = Unit.parse("kg*m/s^2")   # (Unit('kg*m/s^2'), 1.0)
   
   # Both approaches create identical units
   assert meter == meter_old
   assert velocity_unit == velocity_old

Unit Arithmetic
~~~~~~~~~~~~~~~

.. code-block:: python

   # Get base units
   meter, _ = Unit.parse("m")
   second, _ = Unit.parse("s")
   kilogram, _ = Unit.parse("kg")
   
   # Combine units
   area_unit = meter * meter               # m²
   volume_unit = area_unit * meter         # m³
   velocity_unit = meter / second          # m/s
   acceleration_unit = velocity_unit / second  # m/s²
   force_unit = kilogram * acceleration_unit   # kg*m/s²

Unit Properties
~~~~~~~~~~~~~~~

.. code-block:: python

   # Check unit properties
   velocity_unit, _ = Unit.parse("m/s")
   
   print(velocity_unit.symbol)             # "m/s"
   print(velocity_unit.name)               # Human-readable name
   print(velocity_unit.dimensionality)     # Associated Dimensionality object
   print(velocity_unit.is_dimensionless)   # False
   
   # Check SI base units
   meter, _ = Unit.parse("m")
   print(meter.is_si_base_unit)           # True

Factory Methods
~~~~~~~~~~~~~~~

.. code-block:: python

   # Create common units
   dimensionless = Unit.dimensionless()
   meter = Unit.for_quantity("length")    # SI base unit for length
   kilogram = Unit.for_quantity("mass")   # SI base unit for mass
   second = Unit.for_quantity("time")     # SI base unit for time

Conversion Operations
~~~~~~~~~~~~~~~~~~~~

.. code-block:: python

   # Units support conversion factor calculation
   # (Actual conversion is typically done at the Scalar level)
   
   meter, _ = Unit.parse("m")
   kilometer, _ = Unit.parse("km")
   
   # Check if units are compatible for conversion
   print(meter.dimensionality.is_compatible_with(kilometer.dimensionality))  # True

Class Reference
---------------

.. autoclass:: Unit
   :members:
   :special-members: __init__, __mul__, __truediv__, __pow__, __eq__, __str__
   :exclude-members: __weakref__
