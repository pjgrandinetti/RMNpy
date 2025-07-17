# Dataset class for RMNpy
from .helpers cimport _py_to_ocstring, _ocstring_to_py, _py_list_to_ocarray
from .types import validate_string
from .exceptions import RMNLibError, RMNLibMemoryError, RMNLibValidationError
from .core cimport *

cdef class Dataset:
    """Represents a scientific dataset with dimensions and dependent variables."""
    
    def __cinit__(self):
        self._ref = NULL
    def __dealloc__(self):
        if self._ref != NULL:
            OCRelease(self._ref)
    @staticmethod
    def create(dimensions=None, dependent_variables=None, title=None, description=None, tags=None, metadata=None):
        """Create a new Dataset with the specified properties."""
        cdef Dataset dataset = Dataset()
        cdef OCStringRef c_title = NULL
        cdef OCStringRef c_description = NULL
        cdef OCArrayRef c_tags = NULL
        cdef OCStringRef error = NULL
        
        try:
            title = validate_string(title, "title", allow_none=True)
            description = validate_string(description, "description", allow_none=True)
            
            if title is not None:
                c_title = _py_to_ocstring(title)
            if description is not None:
                c_description = _py_to_ocstring(description)
            if tags is not None:
                try:
                    c_tags = _py_list_to_ocarray(tags)
                except Exception as e:
                    raise RMNLibValidationError(f"Invalid tags: {e}")
            
            dataset._ref = DatasetCreate(
                NULL, NULL, NULL, c_tags, c_description, c_title, NULL, NULL, NULL, &error)
            
            if dataset._ref == NULL:
                if error != NULL:
                    error_msg = _ocstring_to_py(error)
                    OCRelease(error)
                    raise RMNLibError(f"Failed to create Dataset: {error_msg}")
                else:
                    raise RMNLibError("Failed to create Dataset: unknown error")
            
            return dataset
            
        finally:
            if c_title != NULL:
                OCRelease(c_title)
            if c_description != NULL:
                OCRelease(c_description)
            if c_tags != NULL:
                OCRelease(c_tags)
    
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
        
        # Convert OCArray to Python list - placeholder for now
        # Would need proper Dimension wrapper integration
        return []
    
    @property 
    def dependent_variables(self):
        """Get the list of dependent variables."""
        if self._ref == NULL:
            return []
        cdef OCMutableArrayRef dvs_ref = DatasetGetDependentVariables(self._ref)
        if dvs_ref == NULL:
            return []
        
        # Convert OCArray to Python list - placeholder for now
        # Would need proper DependentVariable wrapper integration
        return []
    
    @property
    def dependent_variable_count(self):
        """Get the number of dependent variables."""
        if self._ref == NULL:
            return 0
        cdef OCMutableArrayRef dvs_array = DatasetGetDependentVariables(self._ref)
        if dvs_array == NULL:
            return 0
        return OCArrayGetCount(<OCArrayRef>dvs_array)
    
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
        
        # For now return a simple placeholder - would need proper DependentVariable wrapper
        return f"DependentVariable<{<long>dv_ptr}>"
    def __str__(self):
        title = self.title or "Untitled"
        return f"Dataset(title='{title}')"
    def __repr__(self):
        return f"Dataset(_ref={{<long>self._ref}})"
