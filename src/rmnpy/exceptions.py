"""Custom exceptions for RMNpy."""


class RMNLibError(Exception):
    """Base exception for RMNLib operations.
    
    This is the base class for all RMNpy-specific exceptions.
    It is raised when the underlying RMNLib C library encounters
    an error that can be reported to Python.
    
    Attributes:
        message: Human-readable error description
        code: Optional error code from the C library
    """
    
    def __init__(self, message: str, code: int = None):
        super().__init__(message)
        self.message = message
        self.code = code
    
    def __str__(self) -> str:
        if self.code is not None:
            return f"RMNLib Error {self.code}: {self.message}"
        return f"RMNLib Error: {self.message}"


class RMNLibMemoryError(RMNLibError):
    """Memory allocation or management error.
    
    Raised when the RMNLib library fails to allocate memory
    or encounters memory management issues.
    """
    pass


class RMNLibValidationError(RMNLibError):
    """Data validation error.
    
    Raised when input data fails validation checks in the
    RMNLib library. This includes invalid dimensions, 
    incompatible units, or malformed data structures.
    """
    pass


class RMNLibIOError(RMNLibError):
    """File I/O error.
    
    Raised when file operations (reading/writing CSDM files)
    fail in the RMNLib library.
    """
    pass


class RMNLibTypeError(RMNLibError):
    """Type conversion or compatibility error.
    
    Raised when there's an issue converting between Python
    types and RMNLib C types, or when incompatible types
    are used together.
    """
    pass
