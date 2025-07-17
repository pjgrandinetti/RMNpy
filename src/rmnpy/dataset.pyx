# Dataset class for RMNpy
from .helpers cimport _py_to_ocstring, _ocstring_to_py, _py_list_to_ocarray
from .types import validate_string
from .exceptions import RMNLibError, RMNLibMemoryError, RMNLibValidationError
from .core cimport *
from .dimension cimport Dimension
from .dependent_variable cimport DependentVariable

cdef class Dataset:
    """Represents a scientific dataset with dimensions and dependent variables."""
    
    def __cinit__(self):
        self._ref = NULL
    def __dealloc__(self):
        if self._ref != NULL:
            OCRelease(self._ref)
    @staticmethod
    def create(dimensions=None, dependent_variables=None, dimension_precedence=None, 
               tags=None, description=None, title=None, metadata=None):
        """Create a new Dataset with comprehensive parameters.
        
        Args:
            dimensions: List of Dimension objects or None for scalar dataset
            dependent_variables: List of DependentVariable objects (required for non-empty dataset)
            dimension_precedence: List of integers specifying dimension order (optional)
            tags: List of string tags (optional)
            description: String description (optional)
            title: String title (optional)
            metadata: Dictionary of metadata (optional)
            
        Note:
            focus and previousFocus parameters are not exposed and are always set to NULL
        """
        cdef Dataset dataset = Dataset()
        cdef OCArrayRef c_dimensions = NULL
        cdef OCIndexArrayRef c_dimension_precedence = NULL
        cdef OCArrayRef c_dependent_variables = NULL
        cdef OCArrayRef c_tags = NULL
        cdef OCStringRef c_description = NULL
        cdef OCStringRef c_title = NULL
        cdef OCDictionaryRef c_metadata = NULL
        cdef OCStringRef error = NULL
        cdef void* dim_ptr
        cdef void* dep_var_ptr
        
        try:
            # Validate and convert string parameters
            title = validate_string(title, "title", allow_none=True)
            description = validate_string(description, "description", allow_none=True)
            
            if title is not None:
                c_title = _py_to_ocstring(title)
            if description is not None:
                c_description = _py_to_ocstring(description)
            
            # Convert tags to OCArray
            if tags is not None:
                try:
                    c_tags = _py_list_to_ocarray(tags)
                except Exception as e:
                    raise RMNLibValidationError(f"Invalid tags: {e}")
            
            # Convert dimensions to OCArray
            if dimensions is not None:
                try:
                    # Extract the C references from Dimension wrapper objects
                    c_dimensions = OCArrayCreateMutable(len(dimensions), &kOCTypeArrayCallBacks)
                    if c_dimensions == NULL:
                        raise RMNLibMemoryError("Failed to create dimensions array")
                    
                    for dim in dimensions:
                        # Get the _ref attribute using Python attribute access
                        dim_ref = getattr(dim, '_ref', None)
                        if dim_ref is None:
                            raise RMNLibValidationError(f"Invalid dimension: must be Dimension object with _ref attribute, got {type(dim)}")
                        
                        # Cast to void pointer for C API
                        dim_ptr = <void*><long>dim_ref
                        if dim_ptr == NULL:
                            raise RMNLibValidationError("Dimension object has null reference")
                        
                        # Retain the reference before adding to array
                        OCRetain(dim_ptr)
                        if not OCArrayAppendValue(<OCMutableArrayRef>c_dimensions, dim_ptr):
                            OCRelease(dim_ptr)  # Clean up on failure
                            raise RMNLibError("Failed to append dimension to array")
                except Exception as e:
                    if c_dimensions != NULL:
                        OCRelease(c_dimensions)
                    raise RMNLibValidationError(f"Invalid dimensions: {e}")
            
            # Convert dependent_variables to OCArray
            if dependent_variables is not None:
                try:
                    # Extract the C references from DependentVariable wrapper objects
                    c_dependent_variables = OCArrayCreateMutable(len(dependent_variables), &kOCTypeArrayCallBacks)
                    if c_dependent_variables == NULL:
                        raise RMNLibMemoryError("Failed to create dependent variables array")
                    
                    for dep_var in dependent_variables:
                        # Get the _ref attribute using Python attribute access
                        dep_var_ref = getattr(dep_var, '_ref', None)
                        if dep_var_ref is None:
                            raise RMNLibValidationError(f"Invalid dependent variable: must be DependentVariable object with _ref attribute, got {type(dep_var)}")
                        
                        # Cast to void pointer for C API
                        dep_var_ptr = <void*><long>dep_var_ref
                        if dep_var_ptr == NULL:
                            raise RMNLibValidationError("DependentVariable object has null reference")
                        
                        # Retain the reference before adding to array
                        OCRetain(dep_var_ptr)
                        if not OCArrayAppendValue(<OCMutableArrayRef>c_dependent_variables, dep_var_ptr):
                            OCRelease(dep_var_ptr)  # Clean up on failure
                            raise RMNLibError("Failed to append dependent variable to array")
                except Exception as e:
                    if c_dependent_variables != NULL:
                        OCRelease(c_dependent_variables)
                    raise RMNLibValidationError(f"Invalid dependent_variables: {e}")            # Convert dimension_precedence to OCIndexArray
            if dimension_precedence is not None:
                try:
                    # Estimate capacity based on number of elements
                    capacity = len(dimension_precedence) if hasattr(dimension_precedence, '__len__') else 10
                    c_dimension_precedence = OCIndexArrayCreateMutable(capacity)
                    if c_dimension_precedence == NULL:
                        raise RMNLibMemoryError("Failed to create dimension precedence array")
                    
                    for idx in dimension_precedence:
                        if not isinstance(idx, int):
                            raise RMNLibValidationError(f"Dimension precedence must be integers, got {type(idx)}")
                        if not OCIndexArrayAppendValue(c_dimension_precedence, idx):
                            raise RMNLibError("Failed to append to dimension precedence array")
                except Exception as e:
                    if c_dimension_precedence != NULL:
                        OCRelease(c_dimension_precedence)
                    raise RMNLibValidationError(f"Invalid dimension_precedence: {e}")
            
            # Handle focus and previous_focus (set to NULL as requested)
            # Skip focus and previous_focus parameters - always pass NULL
            
            # TODO: Handle metadata when OCDictionary conversion is available
            if metadata is not None:
                raise NotImplementedError("Metadata parameter not yet implemented - requires OCDictionary conversion")
            
            # Create the dataset with focus and previousFocus set to NULL
            dataset._ref = DatasetCreate(
                c_dimensions,           # dimensions
                c_dimension_precedence, # dimensionPrecedence  
                c_dependent_variables,  # dependentVariables
                c_tags,                 # tags
                c_description,          # description
                c_title,                # title
                NULL,                   # focus (ignored)
                NULL,                   # previousFocus (ignored)
                c_metadata,             # metaData
                &error                  # outError
            )
            
            if dataset._ref == NULL:
                if error != NULL:
                    error_msg = _ocstring_to_py(error)
                    OCRelease(error)
                    raise RMNLibError(f"Failed to create Dataset: {error_msg}")
                else:
                    raise RMNLibError("Failed to create Dataset: unknown error")
            
            return dataset
            
        finally:
            # Clean up all allocated C objects
            if c_title != NULL:
                OCRelease(c_title)
            if c_description != NULL:
                OCRelease(c_description)
            if c_tags != NULL:
                OCRelease(c_tags)
            if c_dimensions != NULL:
                OCRelease(c_dimensions)
            if c_dependent_variables != NULL:
                OCRelease(c_dependent_variables)
            if c_dimension_precedence != NULL:
                OCRelease(c_dimension_precedence)
    
    @staticmethod 
    @staticmethod
    def load_csdm(json_path, binary_dir=None):
        """Load a Dataset from CSDM (.csdf/.csdfe) files using actual RMNLib API."""
        cdef Dataset dataset = Dataset()
        cdef OCStringRef error = NULL
        
        json_path_bytes = json_path.encode('utf-8')
        cdef char* binary_dir_bytes = NULL
        if binary_dir is not None:
            binary_dir_temp = binary_dir.encode('utf-8')
            binary_dir_bytes = binary_dir_temp
        
        dataset._ref = DatasetCreateWithImport(json_path_bytes, binary_dir_bytes, &error)
        
        if dataset._ref == NULL:
            error_msg = "Failed to import CSDM file"
            if error != NULL:
                error_msg = _ocstring_to_py(error)
                OCRelease(error)
            raise RMNLibError(f"Failed to import CSDM file '{json_path}': {error_msg}")
        
        return dataset
        
        dataset._ref = DatasetCreateWithImport(json_path_bytes, binary_dir_bytes, &error)
        if dataset._ref == NULL:
            if error != NULL:
                error_msg = _ocstring_to_py(error)
                OCRelease(error)
                raise RMNLibError(f"Failed to import CSDM file: {error_msg}")
            else:
                raise RMNLibError("Failed to import CSDM file: unknown error")
        
        return dataset
    
    def save_csdm(self, json_path, binary_dir=None):
        """Save the Dataset to CSDM (.csdf/.csdfe) files."""
        if self._ref == NULL:
            raise RMNLibError("Cannot save null Dataset")
        
        cdef OCStringRef error = NULL
        json_path_bytes = json_path.encode('utf-8')
        binary_dir_bytes = binary_dir.encode('utf-8') if binary_dir else json_path.encode('utf-8')
        
        success = DatasetExport(self._ref, json_path_bytes, binary_dir_bytes, &error)
        if not success:
            if error != NULL:
                error_msg = _ocstring_to_py(error)
                OCRelease(error)
                raise RMNLibError(f"Failed to export Dataset: {error_msg}")
            else:
                raise RMNLibError("Failed to export Dataset: unknown error")
    @property
    def title(self):
        """Get the dataset title."""
        if self._ref == NULL:
            return None
        cdef OCStringRef title_ref = DatasetGetTitle(self._ref)
        return _ocstring_to_py(title_ref)
    
    @property
    def description(self):
        """Get the dataset description."""
        if self._ref == NULL:
            return None
        cdef OCStringRef desc_ref = DatasetGetDescription(self._ref)
        return _ocstring_to_py(desc_ref)
    
    @property
    def dimensions(self):
        """Get the list of dimensions."""
        if self._ref == NULL:
            return []
        cdef OCMutableArrayRef dims_ref = DatasetGetDimensions(self._ref)
        if dims_ref == NULL:
            return []
        
        # Convert OCArray to Python list of Dimension objects
        cdef uint64_t count = OCArrayGetCount(<OCArrayRef>dims_ref)
        if count == 0:
            return []
        
        cdef list result = []
        cdef uint64_t i
        cdef const void* dim_ptr
        cdef Dimension py_dimension
        
        for i in range(count):
            dim_ptr = OCArrayGetValueAtIndex(<OCArrayRef>dims_ref, i)
            if dim_ptr != NULL:
                # Create a new Dimension wrapper object
                py_dimension = Dimension()
                # Set the C reference (retain it since we're taking ownership)
                py_dimension._ref = <DimensionRef>dim_ptr
                OCRetain(py_dimension._ref)
                result.append(py_dimension)
        
        return result
    
    @property 
    def dependent_variables(self):
        """Get the list of dependent variables."""
        if self._ref == NULL:
            return []
        cdef OCMutableArrayRef dvs_ref = DatasetGetDependentVariables(self._ref)
        if dvs_ref == NULL:
            return []
        
        # Convert OCArray to Python list of DependentVariable objects
        cdef uint64_t count = OCArrayGetCount(<OCArrayRef>dvs_ref)
        if count == 0:
            return []
        
        cdef list result = []
        cdef uint64_t i
        cdef const void* dv_ptr
        cdef DependentVariable py_dep_var
        
        for i in range(count):
            dv_ptr = OCArrayGetValueAtIndex(<OCArrayRef>dvs_ref, i)
            if dv_ptr != NULL:
                # Create a new DependentVariable wrapper object
                py_dep_var = DependentVariable()
                # Set the C reference (retain it since we're taking ownership)
                py_dep_var._ref = <DependentVariableRef>dv_ptr
                OCRetain(py_dep_var._ref)
                result.append(py_dep_var)
        
        return result
    
    @property
    def dimension_precedence(self):
        """Get the dimension precedence ordering as a list of integers."""
        if self._ref == NULL:
            return None
        cdef OCMutableIndexArrayRef precedence_ref = DatasetGetDimensionPrecedence(self._ref)
        if precedence_ref == NULL:
            return None
        
        cdef uint64_t count = OCIndexArrayGetCount(<OCIndexArrayRef>precedence_ref)
        if count == 0:
            return []
        
        precedence = []
        cdef uint64_t i
        for i in range(count):
            precedence.append(OCIndexArrayGetValueAtIndex(<OCIndexArrayRef>precedence_ref, i))
        
        return precedence
    
    @dimension_precedence.setter
    def dimension_precedence(self, precedence):
        """Set the dimension precedence ordering."""
        if self._ref == NULL:
            raise RMNLibError("Cannot set dimension precedence on null Dataset")
        
        cdef OCMutableIndexArrayRef c_precedence = NULL
        try:
            if precedence is None:
                # Clear precedence
                if not DatasetSetDimensionPrecedence(self._ref, NULL):
                    raise RMNLibError("Failed to clear dimension precedence")
                return
            
                c_precedence = OCIndexArrayCreateMutable(len(precedence))
                if c_precedence == NULL:
                    raise RMNLibMemoryError("Failed to create dimension precedence array")
                
                for idx in precedence:
                    if not isinstance(idx, int):
                        raise RMNLibValidationError(f"Dimension precedence must be integers, got {type(idx)}")
                    if not OCIndexArrayAppendValue(<OCMutableIndexArrayRef>c_precedence, idx):
                        raise RMNLibError("Failed to append to dimension precedence array")
                
                if not DatasetSetDimensionPrecedence(self._ref, c_precedence):
                    raise RMNLibError("Failed to set dimension precedence")
        
        finally:
            if c_precedence != NULL:
                OCRelease(c_precedence)
    
    @property
    def tags(self):
        """Get the list of tags."""
        if self._ref == NULL:
            return []
        cdef OCMutableArrayRef tags_ref = DatasetGetTags(self._ref)
        if tags_ref == NULL:
            return []
        
        # Convert OCArray to Python list of strings
        cdef uint64_t count = OCArrayGetCount(<OCArrayRef>tags_ref)
        cdef list result = []
        cdef uint64_t i
        cdef const void* tag_ptr
        
        for i in range(count):
            tag_ptr = OCArrayGetValueAtIndex(<OCArrayRef>tags_ref, i)
            if tag_ptr != NULL:
                tag_str = _ocstring_to_py(<OCStringRef>tag_ptr)
                result.append(tag_str)
        
        return result
    
    @property
    def metadata(self):
        """Get the metadata dictionary."""
        if self._ref == NULL:
            return None
        cdef OCDictionaryRef meta_ref = DatasetGetMetaData(self._ref)
        if meta_ref == NULL:
            return None
        
        # For now, just return a placeholder since we'd need OCDictionary conversion
        return {"type": "metadata", "available": True}

    # Title and description setters
    @title.setter
    def title(self, new_title):
        """Set the dataset title."""
        if self._ref == NULL:
            raise RMNLibError("Cannot set title on null Dataset")
        
        cdef OCStringRef c_title = NULL
        try:
            new_title = validate_string(new_title, "title", allow_none=True)
            if new_title is not None:
                c_title = _py_to_ocstring(new_title)
            
            if not DatasetSetTitle(self._ref, c_title):
                raise RMNLibError("Failed to set title")
        
        finally:
            if c_title != NULL:
                OCRelease(c_title)
    
    @description.setter
    def description(self, new_description):
        """Set the dataset description."""
        if self._ref == NULL:
            raise RMNLibError("Cannot set description on null Dataset")
        
        cdef OCStringRef c_description = NULL
        try:
            new_description = validate_string(new_description, "description", allow_none=True)
            if new_description is not None:
                c_description = _py_to_ocstring(new_description)
            
            if not DatasetSetDescription(self._ref, c_description):
                raise RMNLibError("Failed to set description")
        
        finally:
            if c_description != NULL:
                OCRelease(c_description)
    
    def get_dependent_variable(self, index):
        """Get the dependent variable at the specified index."""
        if self._ref == NULL:
            raise RMNLibError("Cannot access dependent variable from null Dataset")
        
        cdef OCMutableArrayRef dvs_array = DatasetGetDependentVariables(self._ref)
        if dvs_array == NULL:
            raise RMNLibError("Failed to get dependent variables array")
        
        cdef uint64_t count = OCArrayGetCount(<OCArrayRef>dvs_array)
        if index < 0 or index >= count:
            raise IndexError(f"Dependent variable index {index} out of range [0, {count})")
        
        cdef const void* dv_ptr = OCArrayGetValueAtIndex(<OCArrayRef>dvs_array, index)
        if dv_ptr == NULL:
            return None
        
        # Create a proper DependentVariable wrapper object
        cdef DependentVariable py_dep_var = DependentVariable()
        py_dep_var._ref = <DependentVariableRef>dv_ptr
        OCRetain(py_dep_var._ref)
        return py_dep_var
    
    @property
    def dependent_variable_count(self):
        """Get the number of dependent variables."""
        if self._ref == NULL:
            return 0
        cdef OCMutableArrayRef dvs_array = DatasetGetDependentVariables(self._ref)
        if dvs_array == NULL:
            return 0
        return OCArrayGetCount(<OCArrayRef>dvs_array)

    def __str__(self):
        title = self.title or "Untitled"
        return f"Dataset(title='{title}')"
    def __repr__(self):
        return f"Dataset(_ref={{<long>self._ref}})"
