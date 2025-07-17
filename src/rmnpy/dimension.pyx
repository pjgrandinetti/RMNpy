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
    def create_linear(label=None, description=None, count=100, coordinates_offset=0.0, increment=1.0, unit="Hz"):
        """Create a linear dimension with evenly spaced coordinates."""
        cdef Dimension dimension = Dimension()
        # Placeholder implementation - would need proper API integration
        dimension._ref = NULL
        return dimension
    
    @staticmethod
    def create_monotonic(coordinates, label=None, description=None, unit="s"):
        """Create a monotonic dimension with explicitly specified coordinates."""
        cdef Dimension dimension = Dimension()
        # Placeholder implementation - would need proper API integration
        dimension._ref = NULL
        return dimension
    
    @staticmethod
    def create_labeled(labels, label=None, description=None):
        """Create a labeled dimension with string labels for each coordinate."""
        cdef Dimension dimension = Dimension()
        # Placeholder implementation - would need proper API integration
        dimension._ref = NULL
        return dimension
    
    @property
    def label(self):
        if self._ref == NULL:
            return None
        # Placeholder - would need DimensionGetLabel implementation
        return "placeholder_label"
    
    @property
    def description(self):
        if self._ref == NULL:
            return None
        # Placeholder - would need DimensionGetDescription implementation
        return "placeholder_description"
    
    @property
    def count(self):
        if self._ref == NULL:
            return 100
        # Placeholder - would need DimensionGetCount implementation
        return 100
    
    @property
    def type(self):
        if self._ref == NULL:
            return None
        # Placeholder - would need DimensionGetType implementation
        return "linear"
    
    def __str__(self):
        label = self.label or "unlabeled"
        count = self.count or 0
        dim_type = self.type or "unknown"
        return f"Dimension(label='{label}', type='{dim_type}', count={count})"
    def __repr__(self):
        return f"Dimension(_ref={{<long>self._ref}})"
