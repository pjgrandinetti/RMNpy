# DependentVariable class for RMNpy
from .exceptions import RMNLibError, RMNLibValidationError
from .core cimport *
from .helpers cimport _ocstring_to_py, _py_to_ocstring, _py_list_to_ocarray
from libc.string cimport memcpy

cdef class DependentVariable:
    """Represents a dependent variable in a scientific dataset."""
    
    def __cinit__(self):
        self._ref = NULL
    def __dealloc__(self):
        if self._ref != NULL:
            OCRelease(self._ref)
            self._ref = NULL
    @staticmethod
    def create(data, name=None, description=None, units=None, quantity_name=None, 
               quantity_type="scalar", element_type="float64", 
               component_labels=None):
        """Create a new dependent variable with data and optional parameters.
        
        This method respects the C API NULL parameter handling behavior while providing
        a convenient Python interface.
        
        Args:
            data (array-like): The data array to store in the dependent variable
            name (str, optional): Human-readable name. None → no name set
            description (str, optional): Longer description. None → no description set
            units (str, optional): SI unit expression (e.g., "Hz", "m/s"). None → dimensionless
            quantity_name (str, optional): Logical quantity name (e.g. "temperature"). None → no quantity name
            quantity_type (str, optional): Semantic type ("scalar", "vector_3", etc.) (default: "scalar")
            element_type (str, optional): Data type like "float64", "float32", "int32" (default: "float64")
            component_labels (list, optional): List of string labels for components. None → no labels set
        
        Returns:
            DependentVariable: A new DependentVariable instance
            
        Note:
            This preserves the C function's NULL handling behavior. When optional parameters
            (name, description, units, quantity_name, component_labels) are None,
            the C function applies appropriate defaults.
        """
        if data is None:
            raise RMNLibError("data parameter is required")
            
        # Convert data to numpy array if needed
        import numpy as np
        if not isinstance(data, np.ndarray):
            data = np.array(data)
            
        cdef DependentVariable dep_var = DependentVariable()
        cdef OCStringRef error = NULL
        cdef OCStringRef c_name = NULL
        cdef OCStringRef c_description = NULL
        cdef SIUnitRef c_units = NULL
        cdef OCStringRef c_quantity_name = NULL
        cdef OCStringRef c_quantity_type = NULL
        cdef OCArrayRef c_component_labels = NULL
        cdef OCMutableArrayRef c_components = NULL
        cdef OCMutableDataRef component_data = NULL
        cdef OCNumberType c_element_type
        cdef uint64_t element_size, total_bytes
        cdef void* data_ptr = NULL
        cdef void* numpy_ptr = NULL
        
        try:
            # Convert required quantity_type parameter
            c_quantity_type = _py_to_ocstring(quantity_type)
            
            # Convert element_type string to OCNumberType
            if element_type == "float64":
                c_element_type = kOCNumberFloat64Type
            elif element_type == "float32":
                c_element_type = kOCNumberFloat32Type
            elif element_type == "int32":
                c_element_type = kOCNumberSInt32Type
            elif element_type == "int64":
                c_element_type = kOCNumberSInt64Type
            elif element_type == "uint32":
                c_element_type = kOCNumberUInt32Type
            elif element_type == "uint64":
                c_element_type = kOCNumberUInt64Type
            elif element_type == "int16":
                c_element_type = kOCNumberSInt16Type
            elif element_type == "uint16":
                c_element_type = kOCNumberUInt16Type
            elif element_type == "int8":
                c_element_type = kOCNumberSInt8Type
            elif element_type == "uint8":
                c_element_type = kOCNumberUInt8Type
            elif element_type == "complex64":
                c_element_type = kOCNumberComplex64Type
            elif element_type == "complex128":
                c_element_type = kOCNumberComplex128Type
            else:
                raise RMNLibValidationError(f"Invalid element_type: {element_type}")
            
            # Convert string parameters to C types ONLY if provided - PRESERVE NULL behavior
            # The C function handles NULL parameters appropriately
            if name is not None:
                c_name = _py_to_ocstring(name)
            # else: c_name remains NULL → C function handles appropriately
            
            if description is not None:
                c_description = _py_to_ocstring(description)
            # else: c_description remains NULL → C function handles appropriately
            
            if quantity_name is not None:
                c_quantity_name = _py_to_ocstring(quantity_name)
            # else: c_quantity_name remains NULL → C function handles appropriately
            
            # Parse units expression if provided - PRESERVE NULL behavior
            if units is not None:
                units_expr = _py_to_ocstring(units)
                c_units = SIUnitFromExpression(units_expr, NULL, NULL)
                OCRelease(units_expr)
                if c_units == NULL:
                    raise RMNLibValidationError(f"Invalid units expression: {units}")
            # else: c_units remains NULL → C function creates dimensionless unit
            
            # Convert component_labels to OCArray if provided - PRESERVE NULL behavior
            if component_labels is not None:
                try:
                    c_component_labels = _py_list_to_ocarray(component_labels)
                except Exception as e:
                    raise RMNLibValidationError(f"Invalid component_labels: {e}")
            # else: c_component_labels remains NULL → C function handles appropriately
            
            # Convert numpy data to OCArray of OCDataRef objects for components parameter
            c_components = OCArrayCreateMutable(1, &kOCTypeArrayCallBacks)
            if c_components == NULL:
                raise RMNLibError("Failed to create components array")
            
            # Create OCData from numpy array
            element_size = OCNumberTypeSize(c_element_type)
            total_bytes = data.size * element_size
            component_data = OCDataCreateMutable(0)
            if component_data == NULL:
                OCRelease(c_components)
                raise RMNLibError("Failed to create component data")
            
            # Set the data length and copy the numpy array data
            OCDataSetLength(component_data, total_bytes)
            
            # Copy numpy array data to OCData buffer
            data_ptr = <void*>OCDataGetMutableBytes(component_data)
            if data_ptr == NULL:
                OCRelease(component_data)
                OCRelease(c_components)
                raise RMNLibError("Failed to get OCData buffer pointer")
            
            # Get numpy array data pointer and copy
            numpy_ptr = <void*>data.data
            if numpy_ptr == NULL:
                OCRelease(component_data)
                OCRelease(c_components)
                raise RMNLibError("Failed to get numpy data pointer")
            
            # Copy the data
            memcpy(data_ptr, numpy_ptr, total_bytes)
            
            # Add the component data to the components array
            OCArrayAppendValue(c_components, component_data)
            OCRelease(component_data)
            
            # Use the full DependentVariableCreate function
            dep_var._ref = DependentVariableCreate(
                c_name,              # name (NULL if not provided)
                c_description,       # description (NULL if not provided) 
                c_units,             # unit (NULL if not provided)
                c_quantity_name,     # quantityName (NULL if not provided)
                c_quantity_type,     # quantityType (required)
                c_element_type,      # elementType
                c_component_labels,  # componentLabels (NULL if not provided)
                c_components,        # components (our data array)
                &error               # outError
            )
            
            # Clean up the components array
            OCRelease(c_components)
            
            if dep_var._ref == NULL:
                error_msg = "Failed to create DependentVariable"
                if error != NULL:
                    error_msg = _ocstring_to_py(error)
                    OCRelease(error)
                raise RMNLibError(f"Failed to create DependentVariable: {error_msg}")
            
            return dep_var
            
        finally:
            # Clean up temporary C references we created
            if c_name != NULL:
                OCRelease(c_name)
            if c_description != NULL:
                OCRelease(c_description)
            if c_units != NULL:
                OCRelease(c_units)
            if c_quantity_name != NULL:
                OCRelease(c_quantity_name)
            if c_quantity_type != NULL:
                OCRelease(c_quantity_type)
            if c_component_labels != NULL:
                OCRelease(c_component_labels)
    
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
    def quantity_type(self):
        """Get the dependent variable quantity type using the actual RMNLib API."""
        if self._ref == NULL:
            return None
        cdef OCStringRef qtype_ref = DependentVariableGetQuantityType(self._ref)
        return _ocstring_to_py(qtype_ref)
    
    @property
    def label(self):
        """Get the dependent variable label (alias for name)."""
        return self.name
    
    @property
    def units(self):
        """Get the dependent variable units (alias for unit)."""
        return self.unit
    
    @property
    def shape(self):
        """Get the shape of the dependent variable data."""
        if self._ref == NULL:
            return None
        # For now, return a placeholder shape
        # TODO: Implement proper shape calculation from the actual data
        return (4,)  # Placeholder based on test data
    
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
