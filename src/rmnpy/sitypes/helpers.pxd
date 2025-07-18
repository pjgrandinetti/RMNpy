# Cython declarations for SITypes helper functions

from ..core cimport SIScalarRef, SIUnitRef, SIDimensionalityRef
from .scalar cimport _get_scalar_ref

# Helper functions for SIScalar conversion
cdef SIScalarRef py_to_siscalar_ref(object value_or_expression) except NULL
cdef double siscalar_ref_to_py(SIScalarRef scalar_ref)
cdef object siscalar_ref_to_string(SIScalarRef scalar_ref)
cdef SIScalarRef _extract_scalar_ref(object scalar_obj)

# Future helper functions for other SITypes (Phase 2 & 3)
# cdef SIUnitRef py_to_siunit_ref(object unit_expression) except NULL
# cdef object siunit_ref_to_py(SIUnitRef unit_ref)
# cdef SIDimensionalityRef py_to_sidimensionality_ref(object dim_expression) except NULL
# cdef object sidimensionality_ref_to_py(SIDimensionalityRef dim_ref)
