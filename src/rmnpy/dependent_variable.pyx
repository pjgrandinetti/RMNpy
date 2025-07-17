# DependentVariable class for RMNpy
from .exceptions import RMNLibError
from .core cimport *
from .helpers cimport _ocstring_to_py, _py_to_ocstring

cdef class DependentVariable:
    """Represents a dependent variable in a scientific dataset."""
    
    def __cinit__(self):
        self._ref = NULL
    def __dealloc__(self):
        if self._ref != NULL:
            OCRelease(self._ref)
            self._ref = NULL
    @staticmethod
    def create(name=None, description=None, unit=None):
        """Create a new dependent variable using the actual RMNLib API."""
        cdef DependentVariable dep_var = DependentVariable()
        cdef OCStringRef error = NULL
        cdef OCStringRef name_ref = NULL
        cdef OCStringRef desc_ref = NULL
        
        if name is not None:
            name_ref = _py_to_ocstring(name)
        if description is not None:
            desc_ref = _py_to_ocstring(description)
        
        # Create with minimal parameters using DependentVariableCreateDefault
        dep_var._ref = DependentVariableCreateDefault(
            _py_to_ocstring("scalar"),  # quantityType
            kOCNumberFloat64Type,       # elementType
            1,                          # size (must be > 0)
            &error                      # outError
        )
        
        if dep_var._ref == NULL:
            error_msg = "Failed to create DependentVariable"
            if error != NULL:
                error_msg = _ocstring_to_py(error)
                OCRelease(error)
            # Clean up temporary references
            if name_ref != NULL:
                OCRelease(name_ref)
            if desc_ref != NULL:
                OCRelease(desc_ref)
            raise RMNLibError(error_msg)
        
        # Set name and description after creation using real API functions
        if name is not None and name_ref != NULL:
            DependentVariableSetName(dep_var._ref, name_ref)
            OCRelease(name_ref)
        
        if description is not None and desc_ref != NULL:
            DependentVariableSetDescription(dep_var._ref, desc_ref)
            OCRelease(desc_ref)
        
        return dep_var
    
    @property
    def name(self):
        """Get the dependent variable name using the actual RMNLib API."""
        if self._ref == NULL:
            return None
        cdef OCStringRef name_ref = DependentVariableGetName(self._ref)
        return _ocstring_to_py(name_ref)
    
    @property
    def description(self):
        """Get the dependent variable description using the actual RMNLib API."""
        if self._ref == NULL:
            return None
        cdef OCStringRef desc_ref = DependentVariableGetDescription(self._ref)
        return _ocstring_to_py(desc_ref)
    
    @property
    def unit(self):
        """Get the dependent variable unit symbol by casting to SIQuantity."""
        if self._ref == NULL:
            return None
        
        # Cast DependentVariable to SIQuantity to access unit functions
        cdef SIQuantityRef quantity = <SIQuantityRef>self._ref
        cdef SIUnitRef unit_ref = SIQuantityGetUnit(quantity)
        if unit_ref == NULL:
            return "dimensionless"
        
        # Get the unit symbol
        cdef OCStringRef symbol_ref = SIUnitCopyRootSymbol(unit_ref)
        if symbol_ref == NULL:
            return "dimensionless"
        
        symbol = _ocstring_to_py(symbol_ref)
        OCRelease(symbol_ref)  # Release the copied string
        return symbol
    
    @property
    def data(self):
        """Get the dependent variable data as OCData."""
        if self._ref == NULL:
            return None
        # Placeholder - would need proper OCData wrapper implementation
        return None
    
    def set_data(self, data):
        """Set the dependent variable data."""
        if self._ref == NULL:
            raise RMNLibError("Cannot set data on null DependentVariable")
        # Would need to convert Python data to OCData
        # Placeholder implementation
        pass
    def __str__(self):
        name = self.name or "unnamed"
        unit = self.unit or "dimensionless"
        return f"DependentVariable(name='{name}', unit='{unit}')"
    def __repr__(self):
        return f"DependentVariable(_ref={{<long>self._ref}})"
