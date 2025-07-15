# Datum class for RMNpy
from .helpers cimport _py_to_siscalar, _siscalar_to_py
from .types import validate_positive_integer, validate_coordinates
from .exceptions import RMNLibError, RMNLibMemoryError, RMNLibValidationError
from .core cimport *

cdef class Datum:
    """Represents a single data point with response value and coordinates."""
    cdef DatumRef _ref
    def __cinit__(self):
        self._ref = NULL
    def __dealloc__(self):
        if self._ref != NULL:
            OCRelease(self._ref)
    @staticmethod
    def create(response_value, coordinates=None, dv_index=0, component_index=0, mem_offset=0, response_unit=None):
        cdef Datum datum = Datum()
        cdef SIScalarRef response_scalar = NULL
        cdef OCArrayRef coord_array = NULL
        cdef OCMutableArrayRef coord_mutable = NULL
        cdef SIScalarRef coord_scalar = NULL
        try:
            if not isinstance(response_value, (int, float)):
                raise RMNLibValidationError(f"response_value must be a number, got {type(response_value)}")
            dv_index = validate_positive_integer(dv_index + 1, "dv_index") - 1
            component_index = validate_positive_integer(component_index + 1, "component_index") - 1
            mem_offset = validate_positive_integer(mem_offset + 1, "mem_offset") - 1
            coordinates = validate_coordinates(coordinates, "coordinates")
            response_scalar = _py_to_siscalar(float(response_value), response_unit)
            if response_scalar == NULL:
                raise RMNLibMemoryError("Failed to create response scalar")
            if coordinates is not None:
                coord_mutable = OCArrayCreateMutable(len(coordinates), NULL)
                if coord_mutable == NULL:
                    raise RMNLibMemoryError("Failed to create coordinate array")
                try:
                    for coord_val in coordinates:
                        coord_scalar = _py_to_siscalar(float(coord_val))
                        if coord_scalar != NULL:
                            OCArrayAppendValue(coord_mutable, coord_scalar)
                    coord_array = <OCArrayRef>coord_mutable
                except Exception as e:
                    OCRelease(coord_mutable)
                    raise RMNLibValidationError(f"Invalid coordinates: {e}")
            datum._ref = DatumCreate(response_scalar, coord_array, dv_index, component_index, mem_offset)
            if datum._ref == NULL:
                raise RMNLibError("Failed to create Datum")
            return datum
        finally:
            if response_scalar != NULL:
                OCRelease(response_scalar)
            if coord_array != NULL:
                OCRelease(coord_array)
    @property
    def response_value(self):
        if self._ref == NULL:
            return None
        cdef SIScalarRef response = DatumCreateResponse(self._ref)
        return _siscalar_to_py(response)
    @property
    def coordinates(self):
        if self._ref == NULL:
            return None
        cdef OCIndex count = DatumCoordinatesCount(self._ref)
        if count == 0:
            return []
        coordinates = []
        cdef OCIndex i
        cdef SIScalarRef coord_scalar = NULL
        for i in range(count):
            coord_scalar = DatumGetCoordinateAtIndex(self._ref, i)
            if coord_scalar != NULL:
                coordinates.append(_siscalar_to_py(coord_scalar))
        return coordinates
    @property
    def component_index(self):
        if self._ref == NULL:
            return None
        return DatumGetComponentIndex(self._ref)
    @property
    def dependent_variable_index(self):
        if self._ref == NULL:
            return None
        return DatumGetDependentVariableIndex(self._ref)
    def __str__(self):
        response = self.response_value
        coords = self.coordinates
        if coords:
            coord_str = f", coords={coords}"
        else:
            coord_str = ""
        return f"Datum(response={response}{coord_str})"
    def __repr__(self):
        return f"Datum(_ref={{<long>self._ref}})"
