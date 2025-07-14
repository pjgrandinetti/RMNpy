# Exceptions API Reference

## rmnpy.exceptions

Complete documentation for RMNpy exception handling.

```{eval-rst}
.. automodule:: rmnpy.exceptions
   :members:
   :undoc-members:
   :show-inheritance:
```

## Exception Hierarchy

RMNpy provides a comprehensive exception hierarchy for robust error handling:

```
RMNLibError
├── RMNLibMemoryError
└── RMNLibValidationError
```

## RMNLibError

```{eval-rst}
.. autoclass:: rmnpy.exceptions.RMNLibError
   :members:
   :undoc-members:
   :show-inheritance:
```

Base exception class for all RMNLib-related errors.

**Attributes:**
- `message`: Error message string

**Usage:**
```python
from rmnpy.exceptions import RMNLibError

try:
    # RMNpy operations
    pass
except RMNLibError as e:
    print(f"RMNLib error: {e}")
```

## RMNLibMemoryError

```{eval-rst}
.. autoclass:: rmnpy.exceptions.RMNLibMemoryError
   :members:
   :undoc-members:
   :show-inheritance:
```

Exception raised for memory allocation and management errors.

**Inherits from:** `RMNLibError`

**Common causes:**
- Failed memory allocation
- Memory corruption
- Resource exhaustion

**Usage:**
```python
from rmnpy.exceptions import RMNLibMemoryError

try:
    # Operations that might cause memory issues
    dataset = Dataset.create()
except RMNLibMemoryError as e:
    print(f"Memory error: {e}")
    # Handle memory issues
```

## RMNLibValidationError

```{eval-rst}
.. autoclass:: rmnpy.exceptions.RMNLibValidationError
   :members:
   :undoc-members:
   :show-inheritance:
```

Exception raised for input validation and constraint violations.

**Inherits from:** `RMNLibError`

**Common causes:**
- Invalid parameter values
- Constraint violations
- Type mismatches
- Range errors

**Usage:**
```python
from rmnpy.exceptions import RMNLibValidationError

try:
    # Operations with user input
    dimension = Dimension.create_linear(count=-1)  # Invalid count
except RMNLibValidationError as e:
    print(f"Validation error: {e}")
    # Handle invalid input
```

## Error Handling Patterns

### Basic Error Handling

```python
from rmnpy import Dataset
from rmnpy.exceptions import RMNLibError

try:
    dataset = Dataset.create(title="My Analysis")
    # Work with dataset
except RMNLibError as e:
    print(f"Error: {e}")
```

### Specific Error Handling

```python
from rmnpy import Dataset, Dimension
from rmnpy.exceptions import RMNLibError, RMNLibMemoryError, RMNLibValidationError

try:
    dataset = Dataset.create()
    dimension = Dimension.create_linear(label="freq", count=256)
    
except RMNLibMemoryError as e:
    print(f"Memory error: {e}")
    # Handle memory issues - maybe reduce data size
    
except RMNLibValidationError as e:
    print(f"Validation error: {e}")
    # Handle input errors - check parameters
    
except RMNLibError as e:
    print(f"General RMNLib error: {e}")
    # Handle other RMNLib errors
```

### Error Recovery

```python
from rmnpy import Dataset
from rmnpy.exceptions import RMNLibMemoryError

def create_dataset_with_retry(title, max_retries=3):
    """Create dataset with automatic retry on memory errors."""
    
    for attempt in range(max_retries):
        try:
            return Dataset.create(title=title)
            
        except RMNLibMemoryError as e:
            if attempt < max_retries - 1:
                print(f"Memory error on attempt {attempt + 1}, retrying...")
                continue
            else:
                print(f"Failed after {max_retries} attempts: {e}")
                raise
```

### Logging Errors

```python
import logging
from rmnpy import Dataset
from rmnpy.exceptions import RMNLibError

logger = logging.getLogger(__name__)

def create_dataset_safely(title):
    """Create dataset with proper error logging."""
    
    try:
        dataset = Dataset.create(title=title)
        logger.info(f"Successfully created dataset: {title}")
        return dataset
        
    except RMNLibError as e:
        logger.error(f"Failed to create dataset '{title}': {e}")
        raise
```

## Best Practices

### Always Use Specific Exceptions

```python
# Good: Handle specific exception types
try:
    dimension = Dimension.create_linear(count=256)
except RMNLibValidationError as e:
    # Handle validation errors specifically
    pass
except RMNLibMemoryError as e:
    # Handle memory errors specifically
    pass

# Avoid: Catching all exceptions
try:
    dimension = Dimension.create_linear(count=256)
except Exception as e:
    # Too broad - might hide other issues
    pass
```

### Provide Meaningful Error Messages

```python
from rmnpy.exceptions import RMNLibValidationError

def validate_count(count):
    """Validate dimension count parameter."""
    if count <= 0:
        raise RMNLibValidationError(f"Count must be positive, got {count}")
    if count > 100000:
        raise RMNLibValidationError(f"Count too large (max 100000), got {count}")
```

### Clean Up Resources on Error

```python
from rmnpy import Dataset, Dimension
from rmnpy.exceptions import RMNLibError

def process_data():
    """Process data with proper cleanup."""
    dataset = None
    dimension = None
    
    try:
        dataset = Dataset.create(title="Processing")
        dimension = Dimension.create_linear(count=256)
        
        # Process data
        return process_dataset(dataset, dimension)
        
    except RMNLibError as e:
        print(f"Processing failed: {e}")
        raise
        
    finally:
        # Cleanup happens automatically in RMNpy
        # But you can be explicit if needed
        if dataset:
            del dataset
        if dimension:
            del dimension
```

## Debugging Tips

### Enable Detailed Error Information

```python
import logging

# Enable debug logging
logging.basicConfig(level=logging.DEBUG)

# RMNpy will provide more detailed error information
```

### Check Error Messages

```python
from rmnpy.exceptions import RMNLibError

try:
    # Some operation
    pass
except RMNLibError as e:
    # Print full error details
    print(f"Error type: {type(e).__name__}")
    print(f"Error message: {e}")
    print(f"Error args: {e.args}")
```

### Use Context for Better Errors

```python
from rmnpy import Dataset
from rmnpy.exceptions import RMNLibError

def create_analysis_dataset(sample_name):
    """Create dataset with context in error messages."""
    try:
        return Dataset.create(title=f"Analysis of {sample_name}")
    except RMNLibError as e:
        raise RMNLibError(f"Failed to create dataset for sample '{sample_name}': {e}") from e
```

## See Also

- [Core API](core.md): Main RMNpy classes and their exceptions
- [User Guide](../user_guide/index.md): Comprehensive error handling guide
- [Examples](../examples/index.md): Real-world error handling examples
