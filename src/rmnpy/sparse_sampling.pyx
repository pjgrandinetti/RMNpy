# sparse_sampling.pyx - Cython wrapper for SparseSampling
from .core cimport *
from .helpers cimport _py_to_ocstring, _ocstring_to_py
import numpy as np
cimport numpy as cnp

cdef class SparseSampling:
    """SparseSampling represents non-uniform, non-Cartesian sampling layouts.
    
    This class is used for datasets where data values are only recorded at 
    explicitly listed vertices on a subgrid, common in NMR, tomography, 
    and compressed acquisition applications.
    """
    cdef SparseSamplingRef _ref

    def __cinit__(self):
        self._ref = NULL

    def __dealloc__(self):
        if self._ref is not NULL:
            OCRelease(self._ref)

    @staticmethod
    def create(dimension_indexes=None, sparse_grid_vertexes=None, 
               unsigned_integer_type="uint32", encoding="none", 
               description=None, metadata=None):
        """Create a new SparseSampling object.
        
        Args:
            dimension_indexes: List of dimension indices for sparse sampling
            sparse_grid_vertexes: List of vertex coordinates  
            unsigned_integer_type: Integer type for indexing ("uint8", "uint16", "uint32", "uint64")
            encoding: Encoding type ("none" or "base64")
            description: Optional description string
            metadata: Optional metadata dictionary
            
        Returns:
            SparseSampling: New SparseSampling instance
        """
        cdef SparseSampling sparse_sampling = SparseSampling()
        cdef OCStringRef error_str = NULL
        cdef OCIndexSetRef dim_indexes = NULL
        cdef OCArrayRef grid_vertexes = NULL
        cdef OCNumberType number_type
        cdef OCStringRef encoding_str = NULL
        cdef OCStringRef description_str = NULL
        cdef OCDictionaryRef metadata_dict = NULL
        
        try:
            # Convert unsigned integer type
            if unsigned_integer_type == "uint8":
                number_type = kOCNumberUInt8Type
            elif unsigned_integer_type == "uint16":
                number_type = kOCNumberUInt16Type
            elif unsigned_integer_type == "uint32":
                number_type = kOCNumberUInt32Type
            elif unsigned_integer_type == "uint64":
                number_type = kOCNumberUInt64Type
            else:
                raise ValueError(f"Invalid unsigned_integer_type: {unsigned_integer_type}")
            
            # Create encoding string
            encoding_str = _py_to_ocstring(encoding)
            if encoding_str is NULL:
                raise MemoryError("Failed to create encoding string")
            
            # Create description string if provided
            if description is not None:
                description_str = _py_to_ocstring(description)
                if description_str is NULL:
                    raise MemoryError("Failed to create description string")
            
            # For now, create with minimal parameters
            # TODO: Implement dimension_indexes and sparse_grid_vertexes conversion
            
            sparse_sampling._ref = SparseSamplingCreate(
                dim_indexes,           # dimension indexes (NULL for now)
                grid_vertexes,         # sparse grid vertexes (NULL for now)  
                number_type,           # unsigned integer type
                encoding_str,          # encoding
                description_str,       # description
                metadata_dict,         # metadata (NULL for now)
                &error_str
            )
            
            if sparse_sampling._ref is NULL:
                error_msg = "Failed to create SparseSampling"
                if error_str is not NULL:
                    error_msg = _ocstring_to_py(error_str)
                raise RuntimeError(error_msg)
                
            return sparse_sampling
            
        finally:
            # Clean up temporary objects
            if encoding_str is not NULL:
                OCRelease(encoding_str)
            if description_str is not NULL:
                OCRelease(description_str)
            if error_str is not NULL:
                OCRelease(error_str)

    @property  
    def description(self):
        """Get the description of this SparseSampling."""
        if self._ref is NULL:
            return None
        cdef OCStringRef desc_str = SparseSamplingGetDescription(self._ref)
        return _ocstring_to_py(desc_str)
    
    @description.setter
    def description(self, value):
        """Set the description of this SparseSampling."""
        if self._ref is NULL:
            raise RuntimeError("SparseSampling object is not initialized")
        cdef OCStringRef desc_str = NULL
        if value is not None:
            desc_str = _py_to_ocstring(value)
            if desc_str is NULL:
                raise MemoryError("Failed to create description string")
        try:
            if not SparseSamplingSetDescription(self._ref, desc_str):
                raise RuntimeError("Failed to set description")
        finally:
            if desc_str is not NULL:
                OCRelease(desc_str)

    @property
    def encoding(self):
        """Get the encoding type for sparse grid vertexes."""
        if self._ref is NULL:
            return None
        cdef OCStringRef encoding_str = SparseSamplingGetEncoding(self._ref)
        return _ocstring_to_py(encoding_str)
    
    @encoding.setter
    def encoding(self, value):
        """Set the encoding type for sparse grid vertexes."""
        if self._ref is NULL:
            raise RuntimeError("SparseSampling object is not initialized")
        cdef OCStringRef encoding_str = _py_to_ocstring(value)
        if encoding_str is NULL:
            raise MemoryError("Failed to create encoding string")
        try:
            if not SparseSamplingSetEncoding(self._ref, encoding_str):
                raise RuntimeError("Failed to set encoding")
        finally:
            OCRelease(encoding_str)

    @property
    def unsigned_integer_type(self):
        """Get the unsigned integer type used for indexing."""
        if self._ref is NULL:
            return None
        cdef OCNumberType number_type = SparseSamplingGetUnsignedIntegerType(self._ref)
        if number_type == kOCNumberUInt8Type:
            return "uint8"
        elif number_type == kOCNumberUInt16Type:
            return "uint16"
        elif number_type == kOCNumberUInt32Type:
            return "uint32"
        elif number_type == kOCNumberUInt64Type:
            return "uint64"
        else:
            return "unknown"
    
    @unsigned_integer_type.setter
    def unsigned_integer_type(self, value):
        """Set the unsigned integer type used for indexing."""
        if self._ref is NULL:
            raise RuntimeError("SparseSampling object is not initialized")
        cdef OCNumberType number_type
        if value == "uint8":
            number_type = kOCNumberUInt8Type
        elif value == "uint16":
            number_type = kOCNumberUInt16Type
        elif value == "uint32":
            number_type = kOCNumberUInt32Type
        elif value == "uint64":
            number_type = kOCNumberUInt64Type
        else:
            raise ValueError(f"Invalid unsigned_integer_type: {value}")
        
        if not SparseSamplingSetUnsignedIntegerType(self._ref, number_type):
            raise RuntimeError("Failed to set unsigned integer type")

    @property
    def dimension_indexes(self):
        """Get dimension indexes as a numpy array."""
        cdef OCIndexSetRef idx_set = SparseSamplingGetDimensionIndexes(self._ref)
        if idx_set == NULL:
            return None
        
        cdef uint64_t count = OCIndexSetGetCount(idx_set)
        if count == 0:
            return np.array([], dtype=np.int64)
        
        # Use direct pointer access to the internal array
        cdef OCIndex* ptr = OCIndexSetGetBytesPtr(idx_set)
        if ptr == NULL:
            return None
        
        # Create numpy array from the pointer
        cdef cnp.ndarray[cnp.int64_t, ndim=1] result = np.empty(count, dtype=np.int64)
        cdef uint64_t i
        for i in range(count):
            result[i] = ptr[i]
        
        return result
    
    @property  
    def sparse_grid_vertexes(self):
        """Get sparse grid vertexes information."""
        cdef OCArrayRef vertices = SparseSamplingGetSparseGridVertexes(self._ref)
        if vertices == NULL:
            return None
        
        cdef uint64_t count = OCArrayGetCount(vertices)
        return {"count": count, "type": "vertices"}

    @property
    def metadata(self):
        """Get metadata dictionary."""
        cdef OCDictionaryRef meta = SparseSamplingGetMetaData(self._ref)
        if meta == NULL:
            return None
        # For now, just return a placeholder since we'd need OCDictionary conversion
        return {"type": "metadata", "available": True}

    def validate(self):
        """Validate that this SparseSampling is well-formed.
        
        Returns:
            bool: True if valid, False otherwise
        """
        if self._ref is NULL:
            return False
        cdef OCStringRef error_str = NULL
        cdef bint is_valid = validateSparseSampling(self._ref, &error_str)
        if error_str is not NULL:
            OCRelease(error_str)
        return is_valid

    def __repr__(self):
        if self._ref is NULL:
            return "SparseSampling(uninitialized)"
        return f"SparseSampling(encoding='{self.encoding}', type='{self.unsigned_integer_type}')"
