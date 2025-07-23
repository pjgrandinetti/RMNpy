SITypes Wrappers
================

The SITypes module provides Python wrappers for physical units, dimensions, and scalar quantities with automatic dimensional analysis and unit conversion. This system eliminates unit conversion errors and enables confident scientific computing with built-in dimensional safety.

.. currentmodule:: rmnpy.wrappers.sitypes

Overview
--------

**Eliminate Unit Conversion Errors Forever**

The :class:`Scalar` class combines a numerical value with a physical unit, enabling type-safe scientific computing with automatic dimensional analysis and unit conversion. This is the primary class for working with physical quantities.

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
   speed = distance / time         # Units calculated automatically!
   print(speed)                    
   # Output: 277.778 m/s
   
   # Convert to any compatible unit instantly
   speed_kmh = speed.convert_to("km/h")  
   print(speed_kmh)                
   # Output: 1000.0 km/h
   
   speed_mph = speed.convert_to("mph")   
   print(speed_mph)                
   # Output: 621.371 mph

Key Benefits
~~~~~~~~~~~~

* **Dimensional Safety**: Prevents adding incompatible quantities (length + time)
* **Automatic Unit Derivation**: Multiplication/division creates correct derived units
* **Effortless Conversions**: Convert between any compatible units instantly
* **Scientific Accuracy**: Built on precise SI definitions and constants
* **Complex Number Support**: Full support for engineering applications
* **Mathematical Functions**: Complete function library (trig, log, exp, roots) that preserves units
* **Chemical Database**: Built-in atomic weights, isotopic properties, and NMR parameters

Quick Start
-----------

**Creating Scalars with Mathematical Expressions**

The most powerful feature of Scalar is its ability to **evaluate complex mathematical expressions** with units. You don't just assign values - you can perform complete calculations within the constructor:

.. code-block:: python

   from rmnpy.wrappers.sitypes import Scalar, Unit, Dimensionality
   
   # === Complex Mathematical Expressions ===
   
   # Physics calculations with automatic unit derivation
   kinetic_energy = Scalar("0.5 * 2 kg * (10 m/s)^2")          # Result: 100 J
   potential_energy = Scalar("2 kg * 9.8 m/s^2 * 5 m")         # Result: 98 J
   total_energy = Scalar("100 J + 98 J")                       # Result: 198 J
   
   # Chemistry calculations with built-in constants
   molar_mass_water = Scalar("aw[H] * 2 + aw[O]")              # Atomic weights
   moles_from_mass = Scalar("18 g / fw[H2O]")                  # Formula weight
   concentration = Scalar("0.1 mol / 1 L")                     # Molarity
   
   # Engineering with mathematical functions
   ac_power = Scalar("120 V * 5 A * cos(30°)")                 # AC power factor
   resonance_freq = Scalar("1 / (2 * π * sqrt(10e-6 H * 100e-9 F))")  # LC circuit
   exponential_decay = Scalar("100 Bq * exp(-ln(2) * 5 s / 12.3 s)")   # Radioactive decay
   
   # NMR calculations with nuclear properties
   larmor_freq = Scalar("γ_I[H1] * 9.4 T / (2 * π)")          # ¹H Larmor frequency
   chemical_shift = Scalar("γ_I[C13] * 9.4 T * 75e-6")         # ¹³C chemical shift
   
   # === Simple Value Assignment (When No Calculation Needed) ===
   
   # Basic quantities
   distance = Scalar("5.0 m")                    # 5 meters
   velocity = Scalar("25 m/s")                   # 25 meters per second  
   energy = Scalar("500 J")                      # 500 joules
   
   # Programmatic assignment (value, unit pairs)
   mass = Scalar(10.5, "kg")                     # 10.5 kilograms
   temperature = Scalar(273.15, "K")             # 273.15 Kelvin
   impedance = Scalar(3+4j, "Ω")                 # Complex impedance
   
   # === Automatic Unit Arithmetic ===
   
   time = Scalar("5 s")
   velocity = distance / time         # Result: 1 m/s (automatic units!)
   
   mass = Scalar("2 kg") 
   momentum = mass * velocity         # Result: 2 kg*m/s (automatic units!)
   
   # === Effortless Unit Conversions ===
   
   speed_ms = Scalar("100 m/s")
   speed_kmh = speed_ms.convert_to("km/h")     # Result: 360 km/h
   speed_mph = speed_ms.convert_to("mph")      # Result: 223.694 mph
   
   # === Dimensional Safety (Catches Errors) ===
   
   try:
       invalid = distance + time      # Error: Cannot add length + time!
   except Exception as e:
       print("Dimensional mismatch prevented an error!")

Available Mathematical Functions
--------------------------------

The following mathematical functions can be used within Scalar expressions. These functions enable complex scientific calculations while maintaining dimensional analysis:

**Trigonometric Functions**

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - Function
     - Description
   * - ``sin(x)``
     - Sine of x (x in radians or degrees with °)
   * - ``cos(x)``
     - Cosine of x (x in radians or degrees with °)
   * - ``tan(x)``
     - Tangent of x (x in radians or degrees with °)
   * - ``asin(x)``
     - Inverse sine of x (returns radians)
   * - ``acos(x)``
     - Inverse cosine of x (returns radians)
   * - ``atan(x)``
     - Inverse tangent of x (returns radians)

**Hyperbolic Functions**

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - Function
     - Description
   * - ``sinh(x)``
     - Hyperbolic sine of x
   * - ``cosh(x)``
     - Hyperbolic cosine of x
   * - ``tanh(x)``
     - Hyperbolic tangent of x
   * - ``asinh(x)``
     - Inverse hyperbolic sine of x
   * - ``acosh(x)``
     - Inverse hyperbolic cosine of x
   * - ``atanh(x)``
     - Inverse hyperbolic tangent of x

**Exponential and Logarithmic Functions**

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - Function
     - Description
   * - ``exp(x)``
     - Exponential function (e^x)
   * - ``ln(x)``
     - Natural logarithm (base e)
   * - ``log(x)``
     - Base 10 logarithm
   * - ``log2(x)``
     - Base 2 logarithm

**Root Functions**

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - Function
     - Description
   * - ``sqrt(x)``
     - Square root of x
   * - ``cbrt(x)``
     - Cube root of x
   * - ``qurt(x)``
     - Quartic (fourth) root of x

**Complex Number Functions**

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - Function
     - Description
   * - ``conj(x)``
     - Complex conjugate of x
   * - ``creal(x)``
     - Real part of complex number x
   * - ``cimag(x)``
     - Imaginary part of complex number x
   * - ``carg(x)``
     - Argument (phase angle) of complex number x

Chemical and Physical Constants
-------------------------------

**Built-in database of atomic, isotopic, and NMR properties accessible in string expressions:**

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Function
     - Description
   * - ``aw[element]``
     - Atomic weight of element (e.g., ``aw[C]``, ``aw[H]``)
   * - ``fw[formula]``
     - Formula weight of chemical compound (e.g., ``fw[H2O]``, ``fw[CH4]``)
   * - ``abundance[isotope]``
     - Natural abundance of isotope (e.g., ``abundance[C13]``)

**Nuclear Magnetic Resonance (NMR) Properties**

.. list-table::
   :header-rows: 1
   :widths: 25 75

   * - Function
     - Description
   * - ``γ_I[isotope]``
     - Gyromagnetic ratio of isotope (e.g., ``γ_I[H1]``, ``γ_I[C13]``)
   * - ``μ_I[isotope]``
     - Nuclear magnetic dipole moment (e.g., ``μ_I[H1]``)
   * - ``Q_I[isotope]``
     - Nuclear electric quadrupole moment (e.g., ``Q_I[N14]``)
   * - ``nmr[isotope]``
     - Reduced gyromagnetic ratio for NMR (e.g., ``nmr[H1]``)
   * - ``spin[isotope]``
     - Nuclear spin quantum number (e.g., ``spin[H1]``)

**Mathematical Constants**

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - Constant
     - Description
   * - ``π`` or ``pi``
     - Pi (3.14159...)
   * - ``e``
     - Euler's number (2.71828...)

**Physical Constants**

SITypes includes a comprehensive database of fundamental physical constants. Simply use the suggested symbol in string expressions - no need to remember values or units:

.. list-table::
   :header-rows: 1
   :widths: 15 25 60

   * - Symbol
     - Constant
     - Value in Coherent Derived SI Units
   * - ``N_A``
     - Avogadro constant
     - 6.022140857E+23 (1/mol)
   * - ``mu_B``
     - Bohr magneton
     - 9.274009992054043E-24 m²·A
   * - ``k_B``
     - Boltzmann constant
     - 1.38064852E-23 m²·kg/(s²·K)
   * - ``Z_0``
     - Characteristic impedance of vacuum
     - 376.7303134617707 m²·kg/(s³·A²)
   * - ``lambda_C``
     - Compton wavelength
     - 2.42631023609262E-12 m
   * - ``epsilon_0``
     - Electric constant
     - 8.854187817620413E-12 s⁴·A²/(m³·kg)
   * - ``g_e``
     - Electron g factor
     - -2.00231930436182 m²·A/(m²·A)
   * - ``mu_e``
     - Electron magnetic moment
     - -9.28476462E-24 m²·A
   * - ``m_e``
     - Electron mass
     - 9.10938356E-31 kg
   * - ``q_e``
     - Elementary charge
     - 1.6021766208E-19 s·A
   * - ``alpha``
     - Fine structure constant
     - 0.007297352566206478 m⁵·kg·s⁴·A²/(m⁵·kg·s⁴·A²)
   * - ``R``
     - Gas constant
     - 8.314459861448581 m²·kg/(s²·K·mol)
   * - ``G_N``
     - Newton gravitational constant
     - 6.67408E-11 m³/(kg·s²)
   * - ``g_0``
     - Gravity acceleration
     - 9.80665 m/s²
   * - ``mu_0``
     - Magnetic constant
     - 1.256637061435917E-06 m·kg/(s²·A²)
   * - ``phi_0``
     - Magnetic flux quantum
     - 2.067833831170082E-15 m²·kg/(s²·A)
   * - ``g_mu``
     - Muon g factor
     - -2.0023318418 m²·A/(m²·A)
   * - ``mu_mu``
     - Muon magnetic moment
     - -4.49044826E-26 m²·A
   * - ``m_mu``
     - Muon mass
     - 1.883531594E-28 kg
   * - ``g_n``
     - Neutron g factor
     - -3.82608545 m²·A/(m²·A)
   * - ``mu_n``
     - Neutron magnetic moment
     - -9.662365E-27 m²·A
   * - ``m_n``
     - Neutron mass
     - 1.674927471E-27 kg
   * - ``mu_N``
     - Nuclear magneton
     - 5.050783698211084E-27 m²·A
   * - ``h_P``
     - Planck constant
     - 6.62607004E-34 m²·kg/s
   * - ``g_p``
     - Proton g factor
     - 5.585694702 m²·A/(m²·A)
   * - ``mu_p``
     - Proton magnetic moment
     - 1.4106067873E-26 m²·A
   * - ``m_p``
     - Proton mass
     - 1.672621898E-27 kg
   * - ``hbar``
     - Reduced Planck constant
     - 1.054571800139113E-34 m³·kg/(m·s)
   * - ``R_inf``
     - Rydberg constant
     - 10973731.5705508 (1/m)
   * - ``c_0``
     - Speed of light
     - 299792458 m/s
   * - ``sigma``
     - Stefan-Boltzmann constant
     - 5.670367E-08 m²·kg/(m²·s³·K⁴)
   * - ``b_lambda``
     - Wien wavelength displacement constant
     - 0.0028977729 m·K

**Usage Examples:**

.. code-block:: python

   # Use any physical constant directly in expressions
   kinetic_energy = Scalar("0.5 * m_e * (c_0 * 0.1)^2")  # Relativistic energy
   gas_pressure = Scalar("0.1 mol * R * 298 K / 0.001 m^3")  # Ideal gas law
   bohr_radius = Scalar("hbar^2 / (m_e * q_e^2 * k_e)")  # Atomic physics
   
   # No need to remember: R = 8.314 J/(mol·K) - just use "R"!
   # No need to remember: c = 299792458 m/s - just use "c_0"!

**Unit Operations**

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - Function
     - Description
   * - ``reduce(x)``
     - Simplify derived units to their most basic form

Real-World Applications
-----------------------

**From Physics Labs to Engineering Design**

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
   
   # === NMR Calculations ===
   
   # Larmor frequency calculation
   larmor_H1 = Scalar("γ_I[H1] * 9.4 T / (2 * π)")      # ¹H Larmor frequency at 9.4T
   larmor_C13 = Scalar("γ_I[C13] * 9.4 T / (2 * π)")    # ¹³C Larmor frequency at 9.4T
   
   # Chemical shift calculation
   ppm_shift = Scalar("γ_I[H1] * 9.4 T * 2.5e-6")      # 2.5 ppm shift frequency
   
   # === Example Usage ===
   
   # Trigonometric calculations
   phase_shift = Scalar("sin(45°) * 100 V")                    # 70.7 V
   impedance_z = Scalar("50 Ω * exp(1j * 30°)")               # Complex impedance
   
   # Chemical calculations
   water_mass = Scalar("5 mol * fw[H2O]")                      # 90.075 g
   carbon_ratio = Scalar("abundance[C13] / abundance[C12]")    # Isotope ratio
   
   # Complex engineering
   transmission = Scalar("sqrt(50 Ω / (50 Ω + 1j * 2 * π * 1e6 Hz * 1e-6 H))")
   decay_curve = Scalar("100 * exp(-ln(2) * 5 s / 12.26 s)")  # Radioactive decay

Classes
-------

.. toctree::
   :maxdepth: 2
   
   sitypes/scalar
   sitypes/unit  
   sitypes/dimensionality

Module Reference
----------------

The detailed API documentation for each class is available in the following pages:

* :doc:`sitypes/scalar` - Scalar class with units and dimensional analysis
* :doc:`sitypes/unit` - Unit class for physical units  
* :doc:`sitypes/dimensionality` - Dimensionality class for dimensional analysis
   :undoc-members:
   :show-inheritance:
