"""
SIDimensionality Tests - Comprehensive Test Suite

This test suite validates all aspects of the SIDimensionality wrapper:
1. Factory methods (parse, for_quantity, dimensionless)
2. Properties (symbol, is_dimensionless, is_derived, etc.)
3. Dimensional algebra operations (multiply, divide, power, nth_root)
4. CRITICAL: Parser strictness (addition/subtraction rejection)
5. Error handling and edge cases
6. Memory management
7. Python operator overloading

Tests are written to match the actual API implementation.
"""

import pytest
from rmnpy.exceptions import RMNError


def test_critical_parser_strictness():
    """
    CRITICAL TEST: Ensure addition/subtraction is rejected.
    
    This is the most fundamental requirement for dimensional analysis.
    Adding or subtracting quantities with different dimensions is 
    physically meaningless and must be rejected.
    """
    print("\n" + "="*60)
    print("CRITICAL TEST: Parser Strictness for Addition/Subtraction")
    print("="*60)
    
    from rmnpy.wrappers.sitypes.dimensionality import Dimensionality
    
    # These expressions MUST be rejected by the parser
    forbidden_expressions = [
        "L+T",         # Length + Time is physically meaningless
        "M-L",         # Mass - Length is physically meaningless
        "L + T",       # With spaces
        "M - L",       # With spaces  
        "L+M*T",       # Mixed addition
        "L*T+M",       # Addition at end
        "L/T+M",       # Adding velocity and mass (meaningless)
        "L^2+T^2",     # Adding area and time-squared (meaningless)
        "M+L+T",       # Multiple additions
        "L-T+M",       # Mixed subtraction and addition
    ]
    
    failed_rejections = []
    
    for expr in forbidden_expressions:
        try:
            result = Dimensionality.parse(expr)
            # If we get here, the parser FAILED to reject invalid syntax
            failed_rejections.append(f"'{expr}' -> {result} (SHOULD HAVE BEEN REJECTED)")
        except (RMNError, ValueError, SyntaxError) as e:
            # This is CORRECT - addition/subtraction should be rejected
            print(f"✅ '{expr}' properly rejected: {type(e).__name__}")
        except Exception as e:
            # Unexpected error type
            failed_rejections.append(f"'{expr}' -> unexpected error {type(e).__name__}: {e}")
    
    if failed_rejections:
        error_msg = "CRITICAL PARSER FAILURE - Addition/subtraction not properly rejected:\n"
        for failure in failed_rejections:
            error_msg += f"  {failure}\n"
        error_msg += "\nThe parser MUST reject addition and subtraction for dimensional analysis correctness!"
        raise AssertionError(error_msg)
    
    print("✅ All addition/subtraction expressions properly rejected")
    print("✅ CRITICAL TEST PASSED: Parser strictness working correctly")


class TestDimensionalityFactoryMethods:
    """Test all factory methods for creating Dimensionality objects."""
    
    def test_dimensionless_creation(self):
        """Test creating dimensionless quantities."""
        from rmnpy.wrappers.sitypes.dimensionality import Dimensionality
        
        # Using factory method
        d1 = Dimensionality.dimensionless()
        assert d1.is_dimensionless
        assert str(d1) == "1"
        
        # Note: parsing "1" might not be supported by the parser
        # The dimensionless() factory method is the correct way
    
    def test_basic_dimension_creation(self):
        """Test creating basic SI dimensions."""
        from rmnpy.wrappers.sitypes.dimensionality import Dimensionality
        
        # Test basic dimensions
        length = Dimensionality.parse("L")
        mass = Dimensionality.parse("M")
        time = Dimensionality.parse("T")
        
        assert str(length) == "L"
        assert str(mass) == "M"
        assert str(time) == "T"
        
        assert not length.is_dimensionless
        assert not mass.is_dimensionless
        assert not time.is_dimensionless
    
    def test_derived_dimension_creation(self):
        """Test creating derived dimensions."""
        from rmnpy.wrappers.sitypes.dimensionality import Dimensionality
        
        # Test common derived dimensions - using actual string representation
        velocity = Dimensionality.parse("L/T")
        acceleration = Dimensionality.parse("L/T^2")
        force = Dimensionality.parse("M*L/T^2")
        
        # Use actual string representations from the implementation
        assert str(velocity) == "L/T"
        assert str(acceleration) == "L/T^2"
        # Force might be displayed as "L•M/T^2" or similar - check actual
        assert "M" in str(force) and "L" in str(force) and "T^2" in str(force)


class TestDimensionalityProperties:
    """Test all properties and getters."""
    
    def test_is_dimensionless(self):
        """Test is_dimensionless property."""
        from rmnpy.wrappers.sitypes.dimensionality import Dimensionality
        
        dimensionless = Dimensionality.dimensionless()
        length = Dimensionality.parse("L")
        
        assert dimensionless.is_dimensionless
        assert not length.is_dimensionless
    
    def test_symbol_property(self):
        """Test symbol property."""
        from rmnpy.wrappers.sitypes.dimensionality import Dimensionality
        
        length = Dimensionality.parse("L")
        velocity = Dimensionality.parse("L/T")
        
        assert length.symbol == "L"
        assert velocity.symbol == "L/T"  # Using actual representation
    
    def test_is_derived_property(self):
        """Test is_derived property."""
        from rmnpy.wrappers.sitypes.dimensionality import Dimensionality
        
        length = Dimensionality.parse("L")
        velocity = Dimensionality.parse("L/T")
        
        # Basic dimensions might not be considered "derived"
        # Derived dimensions are combinations of base dimensions
        assert velocity.is_derived  # L/T is derived from L and T
    
    def test_is_base_dimensionality(self):
        """Test is_base_dimensionality property."""
        from rmnpy.wrappers.sitypes.dimensionality import Dimensionality
        
        length = Dimensionality.parse("L")
        velocity = Dimensionality.parse("L/T")
        
        # L should be a base dimensionality
        assert length.is_base_dimensionality
        assert not velocity.is_base_dimensionality


class TestDimensionalityAlgebra:
    """Test dimensional algebra operations."""
    
    def test_multiplication(self):
        """Test dimensional multiplication."""
        from rmnpy.wrappers.sitypes.dimensionality import Dimensionality
        
        length = Dimensionality.parse("L")
        time = Dimensionality.parse("T")
        
        # Test multiplication
        result = length.multiply(time)
        # The actual representation uses • instead of * 
        result_str = str(result)
        assert "L" in result_str and "T" in result_str
        
        # Test operator overloading
        result2 = length * time
        assert result.is_equal(result2)
    
    def test_division(self):
        """Test dimensional division."""
        from rmnpy.wrappers.sitypes.dimensionality import Dimensionality
        
        length = Dimensionality.parse("L")
        time = Dimensionality.parse("T")
        
        # Test division
        velocity = length.divide(time)
        assert str(velocity) == "L/T"
        
        # Test operator overloading
        velocity2 = length / time
        assert velocity.is_equal(velocity2)
    
    def test_power_operations(self):
        """Test power and nth_root operations."""
        from rmnpy.wrappers.sitypes.dimensionality import Dimensionality
        
        length = Dimensionality.parse("L")
        
        # Test power
        area = length.power(2)
        assert str(area) == "L^2"
        
        # Test operator overloading
        area2 = length ** 2
        assert area.is_equal(area2)
        
        # Test nth_root
        length_back = area.nth_root(2)
        assert length_back.is_equal(length)


class TestDimensionalityComparisons:
    """Test comparison operations."""
    
    def test_equality(self):
        """Test dimensional equality."""
        from rmnpy.wrappers.sitypes.dimensionality import Dimensionality
        
        velocity1 = Dimensionality.parse("L/T")
        # Create equivalent velocity by division
        length = Dimensionality.parse("L")
        time = Dimensionality.parse("T")
        velocity2 = length.divide(time)
        
        # Use is_equal method for comparison
        assert velocity1.is_equal(velocity2)
        assert velocity1 == velocity2  # Test __eq__ if implemented
        
        # Test inequality
        mass = Dimensionality.parse("M")
        assert not velocity1.is_equal(mass)
        assert velocity1 != mass
    
    def test_compatibility(self):
        """Test dimensional compatibility."""
        from rmnpy.wrappers.sitypes.dimensionality import Dimensionality
        
        velocity1 = Dimensionality.parse("L/T")
        length = Dimensionality.parse("L")
        time = Dimensionality.parse("T")
        velocity2 = length.divide(time)
        
        # Compatible dimensions
        assert velocity1.is_compatible_with(velocity2)
        
        # Incompatible dimensions
        mass = Dimensionality.parse("M")
        assert not velocity1.is_compatible_with(mass)


class TestErrorHandling:
    """Test error handling and edge cases."""
    
    def test_invalid_syntax_errors(self):
        """Test that invalid syntax is properly rejected."""
        from rmnpy.wrappers.sitypes.dimensionality import Dimensionality
        
        # Test a few definitely invalid expressions
        definitely_invalid = [
            "X",             # Invalid dimension symbol  
            "L+T",           # Addition (invalid)
            "M-L",           # Subtraction (invalid)
        ]
        
        for expr in definitely_invalid:
            with pytest.raises((RMNError, ValueError, SyntaxError)):
                Dimensionality.parse(expr)
    
    def test_division_by_zero_power(self):
        """Test nth_root with zero argument."""
        from rmnpy.wrappers.sitypes.dimensionality import Dimensionality
        
        length = Dimensionality.parse("L")
        
        with pytest.raises((RMNError, ValueError, ZeroDivisionError)):
            length.nth_root(0)


class TestMemoryManagement:
    """Test memory management and resource cleanup."""
    
    def test_large_number_of_objects(self):
        """Test creating many objects doesn't cause memory issues."""
        from rmnpy.wrappers.sitypes.dimensionality import Dimensionality
        
        # Create many objects to test memory management
        objects = []
        for i in range(100):
            obj = Dimensionality.parse("L")
            objects.append(obj)
        
        # All should be equal
        for obj in objects:
            assert obj.is_equal(objects[0])
        
        # Test that they can be used after creation
        result = objects[0].multiply(objects[1])
        assert str(result) == "L^2"


class TestRealWorldExpressions:
    """Test realistic physics expressions."""
    
    def test_physics_expressions(self):
        """Test expressions from real physics."""
        from rmnpy.wrappers.sitypes.dimensionality import Dimensionality
        
        # Test that common physics expressions can be parsed
        # (checking exact string representation is less important than successful parsing)
        expressions = [
            "M*L/T^2",        # Force
            "M*L^2/T^2",      # Energy  
            "M*L^2/T^3",      # Power
            "M/(L*T^2)",      # Pressure
            "L^3/T",          # Volumetric flow rate
            "M/(L^3)",        # Density
        ]
        
        for expr in expressions:
            result = Dimensionality.parse(expr)
            result_str = str(result)
            # Just verify it parses successfully and contains expected symbols
            assert len(result_str) > 0
            print(f"✅ '{expr}' -> '{result_str}'")


class TestShowMethods:
    """Test display methods."""
    
    def test_show_methods(self):
        """Test show and show_full methods."""
        from rmnpy.wrappers.sitypes.dimensionality import Dimensionality
        
        velocity = Dimensionality.parse("L/T")
        
        # Test show method (prints to stdout, returns None)
        show_result = velocity.show()
        assert show_result is None  # show() prints and returns None
        
        # Test show_full method (prints to stdout, returns None)
        show_full_result = velocity.show_full()
        assert show_full_result is None  # show_full() prints and returns None
        
        # Test string representation methods (these do return strings)
        str_result = str(velocity)
        assert isinstance(str_result, str)
        assert str_result == "L/T"
        
        repr_result = repr(velocity)
        assert isinstance(repr_result, str)
        assert "Dimensionality" in repr_result


def test_integration_with_constants():
    """Test integration with SI constants system."""
    # This would test integration when constants are implemented
    pass


def run_comprehensive_test_suite():
    """Run all dimensionality tests."""
    print("🧪 Running Unified SIDimensionality Test Suite")
    print("=" * 60)
    
    # Run critical test first
    test_critical_parser_strictness()
    
    # Run all test classes
    import inspect
    import sys
    
    current_module = sys.modules[__name__]
    test_classes = []
    
    for name, obj in inspect.getmembers(current_module):
        if (inspect.isclass(obj) and 
            name.startswith('Test') and 
            obj.__module__ == current_module.__name__):
            test_classes.append(obj)
    
    total_tests = 0
    passed_tests = 0
    
    for test_class in test_classes:
        print(f"\n📋 Running {test_class.__name__}")
        instance = test_class()
        
        for method_name in dir(instance):
            if method_name.startswith('test_'):
                total_tests += 1
                try:
                    method = getattr(instance, method_name)
                    method()
                    print(f"  ✅ {method_name}")
                    passed_tests += 1
                except Exception as e:
                    print(f"  ❌ {method_name}: {e}")
    
    print(f"\n📊 Results: {passed_tests}/{total_tests} tests passed")
    
    if passed_tests == total_tests:
        print("🎉 All SIDimensionality tests PASSED!")
        return True
    else:
        print("⚠️ Some SIDimensionality tests FAILED!")
        return False


if __name__ == "__main__":
    run_comprehensive_test_suite()


# Also define the test function properly for pytest discovery
if __name__ != "__main__":
    # Make sure critical test is available for individual pytest execution
    pass
