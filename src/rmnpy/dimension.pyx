# Dimension class for RMNpy
from .helpers cimport _ocstring_to_py, _siscalar_to_py
from .core cimport *

cdef class Dimension:
    """Represents a dimension in a multidimensional scientific dataset."""
    cdef DimensionRef _ref
    def __cinit__(self):
        self._ref = NULL
    def __dealloc__(self):
        if self._ref != NULL:
            OCRelease(self._ref)
            self._ref = NULL
    @staticmethod
    def create_linear(label=None, description=None, count=100, coordinates_offset=0.0, increment=1.0, unit="Hz"):
        dimension = Dimension()
        # Placeholder: actual implementation should call SILinearDimensionCreate
        return dimension
    @staticmethod
    def create_labeled(labels, label=None, description=None):
        dimension = Dimension()
        # Placeholder: actual implementation should call LabeledDimensionCreateWithCoordinateLabels
        return dimension
    @staticmethod
    def create_si(label=None, description=None, count=100, unit="Hz"):
        dimension = Dimension()
        # Placeholder: actual implementation should call SIDimensionCreate
        return dimension
    @staticmethod
    def create_monotonic(coordinates, label=None, description=None, unit="s"):
        dimension = Dimension()
        # Placeholder: actual implementation should call SIMonotonicDimensionCreate
        return dimension
    @property
    def label(self):
        if self._ref == NULL:
            return None
        cdef OCStringRef label = DimensionGetLabel(self._ref)
        if label == NULL:
            return None
        return _ocstring_to_py(label)
    @property
    def description(self):
        if self._ref == NULL:
            return None
        cdef OCStringRef desc = DimensionGetDescription(self._ref)
        if desc == NULL:
            return None
        return _ocstring_to_py(desc)
    @property
    def count(self):
        if self._ref == NULL:
            return 100
        count_val = DimensionGetCount(self._ref)
        return count_val if count_val > 0 else 100
    @property
    def type(self):
        if self._ref == NULL:
            return None
        cdef OCStringRef type_str = DimensionGetType(self._ref)
        if type_str == NULL:
            return None
        return _ocstring_to_py(type_str)
    @property
    def coordinates_offset(self):
        if self._ref == NULL:
            return None
        cdef SIScalarRef offset = SIDimensionGetCoordinatesOffset(<SIDimensionRef>self._ref)
        return _siscalar_to_py(offset)
    @property
    def increment(self):
        if self._ref == NULL:
            return None
        cdef SIScalarRef inc = SILinearDimensionGetIncrement(<SILinearDimensionRef>self._ref)
        return _siscalar_to_py(inc)
    def __str__(self):
        label = self.label or "unlabeled"
        count = self.count or 0
        dim_type = self.type or "unknown"
        return f"Dimension(label='{label}', type='{dim_type}', count={count})"
    def __repr__(self):
        return f"Dimension(_ref={{<long>self._ref}})"
