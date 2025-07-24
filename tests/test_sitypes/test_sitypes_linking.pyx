# cython: language_level=3
"""
Test SITypes API linking and basic functionality

This test validates that:
1. SITypes C library links correctly
2. SIDimensionality API declarations are valid
3. Basic SIDimensionality operations work
"""

from rmnpy._c_api.sitypes cimport *


def test_sitypes_linking():
    """Test that SITypes library links and basic type IDs are accessible."""
    print("=== SITypes Library Linking Test ===")

    try:
        # Test SITypes type ID access
        dim_type_id = SIDimensionalityGetTypeID()
        print(f"SIDimensionality TypeID: {dim_type_id}")

        unit_type_id = SIUnitGetTypeID()
        print(f"SIUnit TypeID: {unit_type_id}")

        quantity_type_id = SIQuantityGetTypeID()
        print(f"SIQuantity TypeID: {quantity_type_id}")

        scalar_type_id = SIScalarGetTypeID()
        print(f"SIScalar TypeID: {scalar_type_id}")

        print("✅ SITypes library linking successful")
        return True

    except Exception as e:
        print(f"❌ SITypes library linking failed: {e}")
        return False

def test_dimensionality_basic():
    """Test basic SIDimensionality creation and operations."""
    print("\n=== SIDimensionality Basic Test ===")

    try:
        # Create dimensionless
        cdef SIDimensionalityRef dimensionless = SIDimensionalityCreateDimensionless()
        if dimensionless == NULL:
            raise RuntimeError("Failed to create dimensionless")

        # Check if it's dimensionless
        cdef bint is_dimensionless = SIDimensionalityIsDimensionless(dimensionless)
        print(f"Dimensionless check: {is_dimensionless}")

        # Create basic dimensions
        cdef SIDimensionalityRef length = SIDimensionalityCreateLength()
        cdef SIDimensionalityRef mass = SIDimensionalityCreateMass()
        cdef SIDimensionalityRef time = SIDimensionalityCreateTime()

        if length == NULL or mass == NULL or time == NULL:
            raise RuntimeError("Failed to create basic dimensions")

        # Test dimensional algebra - create velocity (length/time)
        cdef SIDimensionalityRef velocity = SIDimensionalityDivide(length, time)
        if velocity == NULL:
            raise RuntimeError("Failed to create velocity dimension")

        # Test dimensional comparison
        cdef SIDimensionalityRef velocity2 = SIDimensionalityCreateVelocity()
        cdef bint velocities_equal = SIDimensionalityEqual(velocity, velocity2)
        print(f"Velocity dimensions equal: {velocities_equal}")

        # Clean up (OCTypes memory management)
        OCRelease(<const void*>dimensionless)
        OCRelease(<const void*>length)
        OCRelease(<const void*>mass)
        OCRelease(<const void*>time)
        OCRelease(<const void*>velocity)
        OCRelease(<const void*>velocity2)

        print("✅ SIDimensionality basic operations successful")
        return True

    except Exception as e:
        print(f"❌ SIDimensionality basic operations failed: {e}")
        return False

def test_dimension_components():
    """Test SIDimensionality component access."""
    print("\n=== SIDimensionality Components Test ===")

    try:
        # Create length dimension and check components
        cdef SIDimensionalityRef length = SIDimensionalityCreateLength()
        if length == NULL:
            raise RuntimeError("Failed to create length dimension")

        # Check that length has [1,0,0,0,0,0,0] components
        cdef int8_t length_component = SIDimensionalityGetComponent(length, kSIDimensionLength)
        cdef int8_t mass_component = SIDimensionalityGetComponent(length, kSIDimensionMass)
        cdef int8_t time_component = SIDimensionalityGetComponent(length, kSIDimensionTime)

        print(f"Length dimension components: L={length_component}, M={mass_component}, T={time_component}")

        if length_component != 1 or mass_component != 0 or time_component != 0:
            raise ValueError("Length dimension has incorrect components")

        # Test area (length^2)
        cdef SIDimensionalityRef area = SIDimensionalityCreateArea()
        cdef int8_t area_length_component = SIDimensionalityGetComponent(area, kSIDimensionLength)
        print(f"Area length component: {area_length_component}")

        if area_length_component != 2:
            raise ValueError("Area dimension has incorrect length component")

        # Clean up
        OCRelease(<const void*>length)
        OCRelease(<const void*>area)

        print("✅ SIDimensionality component access successful")
        return True

    except Exception as e:
        print(f"❌ SIDimensionality component access failed: {e}")
        return False

def run_all_tests():
    """Run all SITypes Phase 2A tests."""
    print("🧪 Running SITypes Phase 2A Tests")
    print("=" * 50)

    tests = [
        test_sitypes_linking,
        test_dimensionality_basic,
        test_dimension_components,
    ]

    passed = 0
    total = len(tests)

    for test in tests:
        if test():
            passed += 1

    print(f"\n📊 Results: {passed}/{total} tests passed")

    if passed == total:
        print("🎉 All SITypes Phase 2A tests PASSED!")
        return True
    else:
        print("⚠️ Some SITypes Phase 2A tests FAILED!")
        return False
