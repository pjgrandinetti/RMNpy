# Dataset class for RMNpy
from .helpers cimport _py_to_ocstring, _ocstring_to_py, _py_list_to_ocarray
from .types import validate_string
from .exceptions import RMNLibError, RMNLibMemoryError, RMNLibValidationError
from .core cimport *

cdef class Dataset:
    """Represents a scientific dataset with dimensions and dependent variables."""
    cdef DatasetRef _ref
    def __cinit__(self):
        self._ref = NULL
    def __dealloc__(self):
        if self._ref != NULL:
            OCRelease(self._ref)
    @staticmethod
    def create(dimensions=None, dependent_variables=None, title=None, description=None, tags=None, metadata=None):
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
    @property
    def title(self):
        if self._ref == NULL:
            return None
        cdef OCStringRef title_ref = DatasetGetTitle(self._ref)
        return _ocstring_to_py(title_ref)
    @property
    def description(self):
        if self._ref == NULL:
            return None
        cdef OCStringRef desc_ref = DatasetGetDescription(self._ref)
        return _ocstring_to_py(desc_ref)
    def __str__(self):
        title = self.title or "Untitled"
        return f"Dataset(title='{title}')"
    def __repr__(self):
        return f"Dataset(_ref={{<long>self._ref}})"
