SITypes Wrappers
================

The SITypes module provides Python wrappers for physical units, dimensions, and scalar quantities with automatic dimensional analysis and unit conversion. This system eliminates unit conversion errors and enables confident scientific computing with built-in dimensional safety.

.. currentmodule:: rmnpy.wrappers.sitypes

Overview
--------

**Eliminate Unit Conversion Errors**

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
   * - ``𝛾_I[isotope]``
     - Gyromagnetic ratio of isotope (e.g., ``𝛾_I[H1]``, ``𝛾_I[C13]``)
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
