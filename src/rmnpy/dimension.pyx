# Dimension class for RMNpy
from .helpers cimport _ocstring_to_py, _siscalar_to_py, _py_to_ocstring
from .core cimport *
from .exceptions import RMNLibError

cdef class Dimension:
    """Represents a dimension in a multidimensional scientific dataset."""
    
    def __cinit__(self):
        self._ref = NULL
    def __dealloc__(self):
        if self._ref != NULL:
            OCRelease(self._ref)
            self._ref = NULL
    
    @staticmethod
    def create_linear(label=None, description=None, metadata=None, quantity=None, offset=None, origin=None, 
                     period=None, periodic=False, scaling=None, count=100, increment=None, fft=False, reciprocal=None):
        """Create a linear dimension with evenly spaced coordinates.
        
        This method exactly matches the C API SILinearDimensionCreate function, including its
        sophisticated NULL parameter handling behavior.
        
        Args:
            label (str, optional): Dimension label. NULL → no label set
            description (str, optional): Description of the dimension. NULL → no description set  
            metadata (dict, optional): Custom metadata dictionary. NULL → no metadata set
            quantity (str, optional): Physical quantity name. NULL → derived from increment's dimensionality
            offset (SIScalar, optional): Starting offset scalar. NULL → creates zero scalar in increment's unit
            origin (SIScalar, optional): Origin offset scalar. NULL → creates zero scalar in increment's unit
            period (SIScalar, optional): Period scalar. NULL → creates zero scalar in increment's unit
            periodic (bool): Whether this is a periodic dimension (primitive, cannot be NULL)
            scaling (int, optional): Dimension scaling type (0=none, 1=NMR). NULL → kDimensionScalingNone
            count (int): Number of points (must be ≥2, primitive, cannot be NULL)
            increment (SIScalar, REQUIRED): Spacing between points. Must be real-valued SIScalar
            fft (bool): Whether this dimension is optimized for FFT (primitive, cannot be NULL)
            reciprocal (Dimension, optional): Reciprocal dimension. NULL → no reciprocal dimension set
        
        Returns:
            Dimension: A new linear Dimension instance
            
        Note:
            This preserves the C function's NULL handling behavior. When scalar parameters
            (offset, origin, period) are None/NULL, the C function creates appropriate default
            zero scalars in the increment's unit via impl_validateOrDefaultScalar().
        """
        cdef Dimension dimension = Dimension()
        cdef OCStringRef error = NULL
        cdef OCStringRef c_label = NULL
        cdef OCStringRef c_description = NULL
        cdef OCStringRef c_quantity = NULL
        cdef OCDictionaryRef c_metadata = NULL
        cdef SIDimensionRef c_reciprocal = NULL
        cdef dimensionScaling c_scaling = kDimensionScalingNone
        cdef SIScalarRef c_offset = NULL
        cdef SIScalarRef c_origin = NULL
        cdef SIScalarRef c_period = NULL
        cdef SIScalarRef c_increment = NULL
        
        try:
            # Validate required parameters first (matching C function logic)
            if increment is None:
                raise RMNLibError("increment parameter is required and must be a SIScalar")
            if count < 2:
                raise RMNLibError("count must be ≥2")
                
            # Convert string parameters to C types (these can be NULL)
            if label is not None:
                c_label = _py_to_ocstring(label)
            if description is not None:
                c_description = _py_to_ocstring(description)
            if quantity is not None:
                c_quantity = _py_to_ocstring(quantity)
                
            # Convert metadata dictionary if provided (advanced feature, skip for now)
            if metadata is not None:
                # TODO: Implement metadata dictionary conversion
                # For now, we'll skip this advanced feature
                pass
            
            # Get reciprocal dimension reference if provided
            if reciprocal is not None:
                if not isinstance(reciprocal, Dimension):
                    raise RMNLibError("reciprocal must be a Dimension instance")
                c_reciprocal = <SIDimensionRef>reciprocal._ref
                
            # Handle scaling parameter (enum with default)
            if scaling is not None:
                c_scaling = <dimensionScaling>scaling
                
            # Handle scalar parameters - PRESERVE NULL behavior from C function
            # The C function's impl_validateOrDefaultScalar creates appropriate defaults
            # when these are NULL, so we pass NULL rather than creating our own defaults
            if offset is not None:
                c_offset = <SIScalarRef>offset._ref
            # else: c_offset remains NULL → C function creates zero scalar in increment's unit
            
            if origin is not None:
                c_origin = <SIScalarRef>origin._ref
            # else: c_origin remains NULL → C function creates zero scalar in increment's unit
            
            if period is not None:
                c_period = <SIScalarRef>period._ref
            # else: c_period remains NULL → C function creates zero scalar in increment's unit
            
            # increment is required - get its C reference
            c_increment = <SIScalarRef>increment._ref
            
            # Create the linear dimension using the exact C API
            dimension._ref = <DimensionRef>SILinearDimensionCreate(
                c_label,              # label
                c_description,        # description
                c_metadata,           # metadata (NULL for now)
                c_quantity,           # quantityName
                c_offset,             # offset
                c_origin,             # origin
                c_period,             # period
                periodic,             # periodic
                c_scaling,            # scaling
                count,                # count
                c_increment,          # increment (required)
                fft,                  # fft
                c_reciprocal,         # reciprocal
                &error                # outError
            )
            
            if dimension._ref == NULL:
                error_msg = "Failed to create linear dimension"
                if error != NULL:
                    error_msg = _ocstring_to_py(error)
                    OCRelease(error)
                raise RMNLibError(f"Failed to create linear dimension: {error_msg}")
            
            return dimension
            
        finally:
            # Clean up temporary C references we created
            if c_label != NULL:
                OCRelease(c_label)
            if c_description != NULL:
                OCRelease(c_description)
            if c_quantity != NULL:
                OCRelease(c_quantity)
            # Note: c_metadata, c_reciprocal, and scalar references (c_offset, c_origin, 
            # c_period, c_increment) are not owned by us - they point to user-provided 
            # objects or remain NULL. The C function handles all scalar memory management
            # including creating/releasing temporary scalars for NULL parameters.
    
    @staticmethod
    def create_monotonic(coordinates, label=None, description=None, quantity=None,
                        offset=None, origin=None, period=None, periodic=False,
                        scaling=0, reciprocal=None):
        """Create a monotonic dimension with explicitly specified coordinates.
        
        This method exactly matches the C API SIMonotonicDimensionCreate function, including its
        sophisticated NULL parameter handling. The C function uses impl_validateOrDefaultScalar
        to create appropriate default scalars when offset/origin/period are NULL.
        
        Args:
            coordinates: List of SIScalar objects for coordinate values (≥2 required)
            label: Optional axis name
            description: Optional description  
            quantity: Physical quantity name (if None, derived from first coordinate)
            offset: SIScalar offset (if None, C function creates zero default)
            origin: SIScalar origin (if None, C function creates zero default)
            period: SIScalar period (if None, C function handles appropriately)
            periodic: Whether dimension wraps around
            scaling: Scaling type (0=none, 1=NMR)
            reciprocal: Reciprocal dimension for FFT operations
        """
        if not coordinates or len(coordinates) < 2:
            raise ValueError("SIMonotonicDimensionCreate: need ≥2 coordinates")
            
        cdef Dimension dimension = Dimension()
        cdef OCStringRef c_label = NULL
        cdef OCStringRef c_description = NULL
        cdef OCStringRef c_quantity = NULL
        cdef SIScalarRef c_offset = NULL
        cdef SIScalarRef c_origin = NULL
        cdef SIScalarRef c_period = NULL
        cdef SIDimensionRef c_reciprocal = NULL
        cdef OCArrayRef c_coordinates = NULL
        cdef OCStringRef error = NULL
        cdef dimensionScaling c_scaling = kDimensionScalingNone
        
        try:
            # Convert string parameters to C strings (only if provided)
            if label is not None:
                c_label = _py_to_ocstring(label)
            if description is not None:
                c_description = _py_to_ocstring(description)
            if quantity is not None:
                c_quantity = _py_to_ocstring(quantity)
                
            # Convert metadata dictionary if provided (advanced feature, skip for now)
            # For now, we'll skip this advanced feature and pass NULL
            
            # Get reciprocal dimension reference if provided
            if reciprocal is not None:
                if not isinstance(reciprocal, Dimension):
                    raise RMNLibError("reciprocal must be a Dimension instance")
                c_reciprocal = <SIDimensionRef>reciprocal._ref
                
            # Handle scaling parameter (enum with default)
            if scaling is not None:
                c_scaling = <dimensionScaling>scaling
                
            # Handle scalar parameters - PRESERVE NULL behavior from C function
            # The C function's impl_validateOrDefaultScalar creates appropriate defaults
            # when these are NULL, so we pass NULL rather than creating our own defaults
            if offset is not None:
                c_offset = <SIScalarRef>offset._ref
            # else: c_offset remains NULL → C function creates zero scalar in first coordinate's unit
            
            if origin is not None:
                c_origin = <SIScalarRef>origin._ref
            # else: c_origin remains NULL → C function creates zero scalar in first coordinate's unit
            
            if period is not None:
                c_period = <SIScalarRef>period._ref
            # else: c_period remains NULL → C function creates zero scalar in first coordinate's unit
            
            # Convert coordinates list to OCArray
            c_coordinates = OCArrayCreateMutable(len(coordinates), &kOCTypeArrayCallBacks)
            if not c_coordinates:
                raise MemoryError("Failed to create coordinates array")
                
            for coord in coordinates:
                if not hasattr(coord, '_ref') or coord._ref is None:
                    raise ValueError("All coordinates must be SIScalar objects")
                OCArrayAppendValue(c_coordinates, <const void*>coord._ref)

            # Create the monotonic dimension using the exact C API
            dimension._ref = <DimensionRef>SIMonotonicDimensionCreate(
                c_label,            # label
                c_description,      # description
                NULL,               # metadata (TODO: implement metadata conversion)
                c_quantity,         # quantity
                c_offset,           # offset
                c_origin,           # origin
                c_period,           # period
                periodic,           # periodic
                c_scaling,          # scaling
                c_coordinates,      # coordinates
                c_reciprocal,       # reciprocal
                &error              # outError
            )
            
            if error:
                error_msg = _ocstring_to_py(error)
                raise RMNLibError(f"SIMonotonicDimensionCreate failed: {error_msg}")
                
            if not dimension._ref:
                raise RMNLibError("SIMonotonicDimensionCreate returned NULL")
                
            return dimension
            
        finally:
            # Cleanup temporary C objects - following same pattern as create_linear
            if c_label:
                OCRelease(c_label)
            if c_description:
                OCRelease(c_description)
            if c_quantity:
                OCRelease(c_quantity)
            if c_coordinates:
                OCRelease(c_coordinates)
            if error:
                OCRelease(error)
            # Note: c_offset, c_origin, c_period, c_reciprocal are borrowed references
            # (either NULL or pointing to user objects) - the C function handles creating
            # c_offset, c_origin, c_period) are not owned by us - they point to user-provided 
            # objects or remain NULL. The C function handles all scalar memory management
            # including creating/releasing temporary scalars for NULL parameters.
    
    @staticmethod
    def create_si_dimension(quantity, label=None, description=None, metadata=None,
                           offset=None, origin=None, period=None, periodic=False, scaling=0):
        """Create a basic SI dimension with quantity, offset, origin, and period.
        
        This method exactly matches the C API SIDimensionCreate function, including its
        sophisticated NULL parameter handling. The C function uses impl_validateOrDefaultScalar
        to create appropriate default scalars when offset/origin/period are NULL.
        
        This is the fundamental SI dimension type, often used as reciprocal dimensions
        for more complex dimension types (linear, monotonic).
        
        Args:
            quantity (str, REQUIRED): Physical quantity name (e.g., "time", "frequency")
            label (str, optional): Dimension label. NULL → no label set
            description (str, optional): Description of the dimension. NULL → no description set
            metadata (dict, optional): Custom metadata dictionary. NULL → no metadata set
            offset (SIScalar, optional): Offset scalar. NULL → creates zero scalar in dimensionless unit
            origin (SIScalar, optional): Origin scalar. NULL → creates zero scalar in dimensionless unit  
            period (SIScalar, optional): Period scalar. NULL → creates zero scalar in dimensionless unit
            periodic (bool): Whether this is a periodic dimension (primitive, cannot be NULL)
            scaling (int): Dimension scaling type (0=none, 1=NMR). Default is kDimensionScalingNone
        
        Returns:
            Dimension: A new SI Dimension instance
            
        Note:
            This preserves the C function's NULL handling behavior. When scalar parameters
            (offset, origin, period) are None/NULL, the C function creates appropriate default
            scalars via impl_validateOrDefaultScalar().
        """
        if not quantity:
            raise RMNLibError("quantity parameter is required for SIDimensionCreate")
            
        cdef Dimension dimension = Dimension()
        cdef OCStringRef error = NULL
        cdef OCStringRef c_label = NULL
        cdef OCStringRef c_description = NULL
        cdef OCStringRef c_quantity = NULL
        cdef OCDictionaryRef c_metadata = NULL
        cdef dimensionScaling c_scaling = kDimensionScalingNone
        cdef SIScalarRef c_offset = NULL
        cdef SIScalarRef c_origin = NULL
        cdef SIScalarRef c_period = NULL
        
        try:
            # Convert required quantity parameter
            c_quantity = _py_to_ocstring(quantity)
            
            # Convert string parameters to C types (these can be NULL)
            if label is not None:
                c_label = _py_to_ocstring(label)
            if description is not None:
                c_description = _py_to_ocstring(description)
                
            # Convert metadata dictionary if provided (advanced feature, skip for now)
            if metadata is not None:
                # TODO: Implement metadata dictionary conversion
                # For now, we'll skip this advanced feature
                pass
                
            # Handle scaling parameter (enum with default)
            if scaling is not None:
                c_scaling = <dimensionScaling>scaling
                
            # Handle scalar parameters - PRESERVE NULL behavior from C function
            # The C function's impl_validateOrDefaultScalar creates appropriate defaults
            # when these are NULL, so we pass NULL rather than creating our own defaults
            if offset is not None:
                c_offset = <SIScalarRef>offset._ref
            # else: c_offset remains NULL → C function creates zero scalar in dimensionless unit
            
            if origin is not None:
                c_origin = <SIScalarRef>origin._ref
            # else: c_origin remains NULL → C function creates zero scalar in dimensionless unit
            
            if period is not None:
                c_period = <SIScalarRef>period._ref
            # else: c_period remains NULL → C function creates zero scalar in dimensionless unit
            
            # Create the SI dimension using the exact C API
            dimension._ref = <DimensionRef>SIDimensionCreate(
                c_label,              # label
                c_description,        # description
                c_metadata,           # metadata (NULL for now)
                c_quantity,           # quantityName (required)
                c_offset,             # offset
                c_origin,             # origin
                c_period,             # period
                periodic,             # periodic
                c_scaling,            # scaling
                &error                # outError
            )
            
            if dimension._ref == NULL:
                error_msg = "Failed to create SI dimension"
                if error != NULL:
                    error_msg = _ocstring_to_py(error)
                    OCRelease(error)
                raise RMNLibError(f"Failed to create SI dimension: {error_msg}")
            
            return dimension
            
        finally:
            # Clean up temporary C references we created
            if c_label != NULL:
                OCRelease(c_label)
            if c_description != NULL:
                OCRelease(c_description)
            if c_quantity != NULL:
                OCRelease(c_quantity)
            # Note: c_metadata and scalar references (c_offset, c_origin, c_period)
            # are not owned by us - they point to user-provided objects or remain NULL.
            # The C function handles all scalar memory management including creating/releasing
            # temporary scalars for NULL parameters.
    
    @staticmethod
    def create_labeled(labels, label=None, description=None, metadata=None):
        """Create a labeled dimension with string labels for each coordinate.
        
        This method wraps the C API LabeledDimensionCreate and 
        LabeledDimensionCreateWithCoordinateLabels functions. If only labels are provided,
        it uses the simpler CreateWithCoordinateLabels function. If additional parameters
        are provided, it uses the full LabeledDimensionCreate function.
        
        Args:
            labels (list): List of string labels for coordinates (≥2 required)
            label (str, optional): Dimension label. NULL → no label set
            description (str, optional): Description of the dimension. NULL → no description set
            metadata (dict, optional): Custom metadata dictionary. NULL → no metadata set
        
        Returns:
            Dimension: A new labeled Dimension instance
            
        Note:
            This creates a dimension where coordinates are identified by string labels
            rather than numeric values. This is useful for categorical data or
            discrete coordinate systems.
        """
        if not labels or len(labels) < 2:
            raise ValueError("LabeledDimensionCreate: need ≥2 coordinate labels")
            
        cdef Dimension dimension = Dimension()
        cdef OCStringRef error = NULL
        cdef OCStringRef c_label = NULL
        cdef OCStringRef c_description = NULL
        cdef OCDictionaryRef c_metadata = NULL
        cdef OCArrayRef c_labels = NULL
        
        try:
            # Convert coordinate labels list to OCArray
            c_labels = OCArrayCreateMutable(len(labels), &kOCTypeArrayCallBacks)
            if not c_labels:
                raise MemoryError("Failed to create coordinate labels array")
                
            for label_str in labels:
                if not isinstance(label_str, str):
                    raise ValueError("All coordinate labels must be strings")
                c_str_ref = _py_to_ocstring(label_str)
                OCArrayAppendValue(c_labels, <const void*>c_str_ref)
                # Note: we don't release c_str_ref here as it's now owned by the array
            
            # If only labels are provided, use the simpler function
            if label is None and description is None and metadata is None:
                dimension._ref = <DimensionRef>LabeledDimensionCreateWithCoordinateLabels(c_labels)
                
                if dimension._ref == NULL:
                    raise RMNLibError("Failed to create labeled dimension with coordinate labels")
            else:
                # Use the full function with optional parameters
                # Convert string parameters to C types (these can be NULL)
                if label is not None:
                    c_label = _py_to_ocstring(label)
                if description is not None:
                    c_description = _py_to_ocstring(description)
                    
                # Convert metadata dictionary if provided (advanced feature, skip for now)
                if metadata is not None:
                    # TODO: Implement metadata dictionary conversion
                    # For now, we'll skip this advanced feature
                    pass
                
                # Create the labeled dimension using the full C API
                dimension._ref = <DimensionRef>LabeledDimensionCreate(
                    c_label,              # label
                    c_description,        # description
                    c_metadata,           # metadata (NULL for now)
                    c_labels,             # coordinateLabels (required)
                    &error                # outError
                )
                
                if dimension._ref == NULL:
                    error_msg = "Failed to create labeled dimension"
                    if error != NULL:
                        error_msg = _ocstring_to_py(error)
                        OCRelease(error)
                    raise RMNLibError(f"Failed to create labeled dimension: {error_msg}")
            
            return dimension
            
        finally:
            # Clean up temporary C references we created
            if c_label != NULL:
                OCRelease(c_label)
            if c_description != NULL:
                OCRelease(c_description)
            if c_labels != NULL:
                OCRelease(c_labels)
            # Note: c_metadata is not owned by us - it points to user-provided objects
            # or remains NULL. The C function handles all memory management.
    
    @property
    def label(self):
        if self._ref == NULL:
            return None
        cdef OCStringRef label_ref = DimensionGetLabel(self._ref)
        return _ocstring_to_py(label_ref)
    
    @property
    def description(self):
        if self._ref == NULL:
            return None
        cdef OCStringRef desc_ref = DimensionGetDescription(self._ref)
        return _ocstring_to_py(desc_ref)
    
    @property
    def count(self):
        if self._ref == NULL:
            return 0
        return DimensionGetCount(self._ref)
    
    @property
    def type(self):
        if self._ref == NULL:
            return None
        # Check the actual type using OCGetTypeID
        cdef OCTypeID type_id = OCGetTypeID(self._ref)
        cdef OCTypeID linear_type_id = SILinearDimensionGetTypeID()
        cdef OCTypeID labeled_type_id = LabeledDimensionGetTypeID()
        if type_id == linear_type_id:
            return "linear"
        elif type_id == labeled_type_id:
            return "labeled"
        # Add other types as needed
        return "dimension"
    
    def __str__(self):
        label = self.label or "unlabeled"
        count = self.count or 0
        dim_type = self.type or "unknown"
        return f"Dimension(label='{label}', type='{dim_type}', count={count})"
    def __repr__(self):
        return f"Dimension(_ref={{<long>self._ref}})"
