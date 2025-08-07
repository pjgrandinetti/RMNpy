# cython: language_level=3
"""
RMNLib Dimension wrapper providing csdmpy-compatible API

This module provides Python wrappers for RMNLib's RMNDimension class
with an API designed to be compatible with csdmpy.Dimension.
"""

from typing import Any, Dict, List, Optional, Union

import numpy as np

from ..._c_api cimport rmnlib


cdef class Dimension:
    """
    RMNLib Dimension wrapper with csdmpy-compatible API

    This class wraps RMNLib's RMNDimension to provide a Python interface
    compatible with csdmpy.Dimension for seamless user migration.

    Attributes:
        type: The dimension subtype ('linear', 'monotonic', 'labeled')
        description: Brief description of the dimension
        application: Application metadata dictionary
        coordinates: Coordinates along the dimension
        coords: Alias for coordinates attribute
        absolute_coordinates: Absolute coordinates along the dimension
        count: Number of coordinates along the dimension
        increment: Increment along linear dimensions
        coordinates_offset: Offset for zero of indexes array
        origin_offset: Origin offset along the dimension
        complex_fft: True if coordinates ordered as complex FFT output
        quantity_name: Quantity name for physical quantities
        label: Label associated with the dimension
        labels: List of labels for labeled dimensions
        period: Period of the dimension
        axis_label: Formatted string for axis display
        data_structure: JSON serialized dimension description
    """

    cdef rmnlib.RMNDimension* _c_dimension
    cdef dict _application
    cdef str _description
    cdef str _label
    cdef bint _owns_memory

    def __init__(self, *args, **kwargs):
        """
        Create a new Dimension instance.

        Parameters:
            *args: Positional arguments (dimension dictionary if provided)
            **kwargs: Keyword arguments for dimension properties

        Example:
            >>> # From dictionary
            >>> dim_dict = {
            ...     "type": "linear",
            ...     "description": "frequency dimension",
            ...     "increment": "100 Hz",
            ...     "count": 256,
            ...     "coordinates_offset": "0 Hz",
            ...     "origin_offset": "0 Hz"
            ... }
            >>> dim = Dimension(dim_dict)

            >>> # From keyword arguments
            >>> dim = Dimension(
            ...     type="linear",
            ...     description="frequency dimension",
            ...     increment="100 Hz",
            ...     count=256
            ... )
        """
        self._c_dimension = NULL
        self._application = {}
        self._description = ""
        self._label = ""
        self._owns_memory = True

        # Parse input arguments
        params = {}
        if args:
            if len(args) == 1 and isinstance(args[0], dict):
                params.update(args[0])
            else:
                raise ValueError("Single positional argument must be a dictionary")
        params.update(kwargs)

        # Create dimension based on type
        dim_type = params.get('type', 'linear').lower()
        if dim_type == 'linear':
            self._create_linear_dimension(params)
        elif dim_type == 'monotonic':
            self._create_monotonic_dimension(params)
        elif dim_type == 'labeled':
            self._create_labeled_dimension(params)
        else:
            raise ValueError(f"Unknown dimension type: {dim_type}")

        # Set additional properties
        self._description = params.get('description', '')
        self._label = params.get('label', '')
        if 'application' in params:
            self._application = dict(params['application'])

    def __dealloc__(self):
        """Clean up C resources."""
        if self._c_dimension != NULL and self._owns_memory:
            rmnlib.RMNDimension_destroy(self._c_dimension)

    @staticmethod
    cdef Dimension _from_c_dimension(rmnlib.RMNDimension* c_dim, bint owns_memory=False):
        """Create Python wrapper from existing C dimension."""
        cdef Dimension dim = Dimension.__new__(Dimension)
        dim._c_dimension = c_dim
        dim._owns_memory = owns_memory
        dim._application = {}
        dim._description = ""
        dim._label = ""
        return dim

    cdef void _create_linear_dimension(self, dict params):
        """Create linear dimension from parameters."""
        cdef int count = params.get('count', 1)
        cdef double increment_val = 1.0
        cdef double offset_val = 0.0
        cdef double origin_val = 0.0

        # Parse increment (simplified - would need full unit parsing)
        increment_str = params.get('increment', '1.0')
        if isinstance(increment_str, str):
            # Extract numeric part (simplified parsing)
            import re
            match = re.match(r'([0-9.-]+)', increment_str)
            if match:
                increment_val = float(match.group(1))

        # Parse offsets similarly
        offset_str = params.get('coordinates_offset', '0.0')
        if isinstance(offset_str, str):
            match = re.match(r'([0-9.-]+)', offset_str)
            if match:
                offset_val = float(match.group(1))

        origin_str = params.get('origin_offset', '0.0')
        if isinstance(origin_str, str):
            match = re.match(r'([0-9.-]+)', origin_str)
            if match:
                origin_val = float(match.group(1))

        # Create C dimension
        self._c_dimension = rmnlib.RMNDimension_createLinear(
            count, increment_val, offset_val, origin_val
        )

        # Set complex_fft if specified
        if params.get('complex_fft', False):
            rmnlib.RMNDimension_setComplexFFT(self._c_dimension, True)

    cdef void _create_monotonic_dimension(self, dict params):
        """Create monotonic dimension from parameters."""
        coordinates = params.get('coordinates', [])
        if not coordinates:
            raise ValueError("Monotonic dimension requires coordinates")

        # Convert coordinates to numpy array
        coords_array = np.asarray(coordinates, dtype=np.float64)
        cdef int count = len(coords_array)
        cdef double[:] coords_view = coords_array

        self._c_dimension = rmnlib.RMNDimension_createMonotonic(
            count, &coords_view[0]
        )

    cdef void _create_labeled_dimension(self, dict params):
        """Create labeled dimension from parameters."""
        labels = params.get('labels', [])
        if not labels:
            raise ValueError("Labeled dimension requires labels")

        cdef int count = len(labels)
        # Convert labels to C strings (simplified)
        label_strings = [str(label).encode('utf-8') for label in labels]

        # Create C dimension with labels
        self._c_dimension = rmnlib.RMNDimension_createLabeled(count)
        for i, label_bytes in enumerate(label_strings):
            rmnlib.RMNDimension_setLabel(self._c_dimension, i, label_bytes)

    @property
    def type(self) -> str:
        """The dimension subtype ('linear', 'monotonic', 'labeled')."""
        if self._c_dimension == NULL:
            return "linear"

        cdef int dim_type = rmnlib.RMNDimension_getType(self._c_dimension)
        if dim_type == 0:  # LINEAR
            return "linear"
        elif dim_type == 1:  # MONOTONIC
            return "monotonic"
        elif dim_type == 2:  # LABELED
            return "labeled"
        else:
            return "unknown"

    @property
    def description(self) -> str:
        """Brief description of the dimension object."""
        return self._description

    @description.setter
    def description(self, value: str):
        """Set dimension description."""
        if not isinstance(value, str):
            raise TypeError("Description must be a string")
        self._description = value

    @property
    def application(self) -> Optional[Dict[str, Any]]:
        """Application metadata dictionary of the dimension object."""
        return self._application if self._application else None

    @application.setter
    def application(self, value: Dict[str, Any]):
        """Set application metadata dictionary."""
        if not isinstance(value, dict):
            raise TypeError("Application must be a dictionary")
        self._application = dict(value)

    @property
    def coordinates(self) -> np.ndarray:
        """Coordinates along the dimension."""
        if self._c_dimension == NULL:
            return np.array([])

        cdef int count = rmnlib.RMNDimension_getCount(self._c_dimension)
        if self.type == "labeled":
            # Return labels as string array
            labels = []
            for i in range(count):
                label_ptr = rmnlib.RMNDimension_getLabel(self._c_dimension, i)
                if label_ptr != NULL:
                    labels.append(label_ptr.decode('utf-8'))
                else:
                    labels.append("")
            return np.array(labels)
        else:
            # Return numeric coordinates
            coords = np.zeros(count, dtype=np.float64)
            cdef double[:] coords_view = coords
            rmnlib.RMNDimension_getCoordinates(self._c_dimension, &coords_view[0])

            # Handle complex FFT ordering if needed
            if (self.type == "linear" and
                rmnlib.RMNDimension_isComplexFFT(self._c_dimension)):
                # Reorder for complex FFT
                coords = np.fft.fftshift(coords)

            return coords

    @property
    def coords(self) -> np.ndarray:
        """Alias for the coordinates attribute."""
        return self.coordinates

    @property
    def absolute_coordinates(self) -> np.ndarray:
        """Absolute coordinates along the dimension."""
        if self.type == "labeled":
            raise AttributeError("absolute_coordinates not valid for labeled dimensions")

        coords = self.coordinates
        origin = self.origin_offset
        if origin != 0.0:
            coords = coords + origin
        return coords

    @property
    def count(self) -> int:
        """Number of coordinates along the dimension."""
        if self._c_dimension == NULL:
            return 0
        return rmnlib.RMNDimension_getCount(self._c_dimension)

    @count.setter
    def count(self, value: int):
        """Set number of coordinates."""
        if not isinstance(value, int) or value < 1:
            raise TypeError("Count must be a positive integer")

        if self._c_dimension != NULL:
            rmnlib.RMNDimension_setCount(self._c_dimension, value)

    @property
    def increment(self) -> float:
        """Increment along a linear dimension."""
        if self.type != "linear":
            raise AttributeError("increment only valid for linear dimensions")

        if self._c_dimension == NULL:
            return 1.0
        return rmnlib.RMNDimension_getIncrement(self._c_dimension)

    @increment.setter
    def increment(self, value: Union[str, float]):
        """Set increment for linear dimension."""
        if self.type != "linear":
            raise AttributeError("increment only valid for linear dimensions")

        # Parse numeric value from string if needed
        if isinstance(value, str):
            import re
            match = re.match(r'([0-9.-]+)', value)
            if match:
                numeric_value = float(match.group(1))
            else:
                raise ValueError(f"Cannot parse increment from: {value}")
        else:
            numeric_value = float(value)

        if self._c_dimension != NULL:
            rmnlib.RMNDimension_setIncrement(self._c_dimension, numeric_value)

    @property
    def coordinates_offset(self) -> float:
        """Offset corresponding to zero of indexes array."""
        if self.type == "labeled":
            raise AttributeError("coordinates_offset not valid for labeled dimensions")

        if self._c_dimension == NULL:
            return 0.0
        return rmnlib.RMNDimension_getCoordinatesOffset(self._c_dimension)

    @coordinates_offset.setter
    def coordinates_offset(self, value: Union[str, float]):
        """Set coordinates offset."""
        if self.type == "labeled":
            raise AttributeError("coordinates_offset not valid for labeled dimensions")

        # Parse numeric value from string if needed
        if isinstance(value, str):
            import re
            match = re.match(r'([0-9.-]+)', value)
            if match:
                numeric_value = float(match.group(1))
            else:
                raise ValueError(f"Cannot parse offset from: {value}")
        else:
            numeric_value = float(value)

        if self._c_dimension != NULL:
            rmnlib.RMNDimension_setCoordinatesOffset(self._c_dimension, numeric_value)

    @property
    def origin_offset(self) -> float:
        """Origin offset along the dimension."""
        if self.type == "labeled":
            raise AttributeError("origin_offset not valid for labeled dimensions")

        if self._c_dimension == NULL:
            return 0.0
        return rmnlib.RMNDimension_getOriginOffset(self._c_dimension)

    @origin_offset.setter
    def origin_offset(self, value: Union[str, float]):
        """Set origin offset."""
        if self.type == "labeled":
            raise AttributeError("origin_offset not valid for labeled dimensions")

        # Parse numeric value from string if needed
        if isinstance(value, str):
            import re
            match = re.match(r'([0-9.-]+)', value)
            if match:
                numeric_value = float(match.group(1))
            else:
                raise ValueError(f"Cannot parse offset from: {value}")
        else:
            numeric_value = float(value)

        if self._c_dimension != NULL:
            rmnlib.RMNDimension_setOriginOffset(self._c_dimension, numeric_value)

    @property
    def complex_fft(self) -> bool:
        """True if coordinates ordered as complex FFT output."""
        if self.type != "linear":
            raise AttributeError("complex_fft only valid for linear dimensions")

        if self._c_dimension == NULL:
            return False
        return rmnlib.RMNDimension_isComplexFFT(self._c_dimension)

    @complex_fft.setter
    def complex_fft(self, value: bool):
        """Set complex FFT ordering flag."""
        if self.type != "linear":
            raise AttributeError("complex_fft only valid for linear dimensions")

        if not isinstance(value, bool):
            raise TypeError("complex_fft must be a boolean")

        if self._c_dimension != NULL:
            rmnlib.RMNDimension_setComplexFFT(self._c_dimension, value)

    @property
    def quantity_name(self) -> str:
        """Quantity name for physical quantities specifying dimension."""
        if self.type == "labeled":
            raise AttributeError("quantity_name not valid for labeled dimensions")

        # This would typically come from unit analysis
        # For now return a placeholder
        return "frequency"  # or appropriate quantity based on units

    @property
    def label(self) -> str:
        """Label associated with the dimension."""
        return self._label

    @label.setter
    def label(self, value: str):
        """Set dimension label."""
        if not isinstance(value, str):
            raise TypeError("Label must be a string")
        self._label = value

    @property
    def labels(self) -> np.ndarray:
        """Ordered list of labels along labeled dimension."""
        if self.type != "labeled":
            raise AttributeError("labels only valid for labeled dimensions")
        return self.coordinates  # coordinates returns labels for labeled dims

    @property
    def period(self) -> float:
        """Period of the dimension."""
        if self.type == "labeled":
            raise AttributeError("period not valid for labeled dimensions")

        if self._c_dimension == NULL:
            return float('inf')

        period_val = rmnlib.RMNDimension_getPeriod(self._c_dimension)
        return period_val if period_val > 0 else float('inf')

    @period.setter
    def period(self, value: Union[str, float]):
        """Set dimension period."""
        if self.type == "labeled":
            raise AttributeError("period not valid for labeled dimensions")

        # Handle special infinity cases
        if isinstance(value, str):
            value_lower = value.lower()
            if any(inf_str in value_lower for inf_str in ['inf', '∞', '1/0']):
                numeric_value = float('inf')
            else:
                # Parse numeric value
                import re
                match = re.match(r'([0-9.-]+)', value)
                if match:
                    numeric_value = float(match.group(1))
                else:
                    raise ValueError(f"Cannot parse period from: {value}")
        else:
            numeric_value = float(value)

        if self._c_dimension != NULL:
            # Use -1 to represent infinity in C
            c_period = -1.0 if numeric_value == float('inf') else numeric_value
            rmnlib.RMNDimension_setPeriod(self._c_dimension, c_period)

    @property
    def axis_label(self) -> str:
        """Formatted string for displaying label along dimension axis."""
        if self.type == "labeled":
            return self.label if self.label else "unlabeled"

        # For quantitative dimensions, return "label / (unit)" format
        label_part = self.label if self.label else self.quantity_name
        # Would need proper unit formatting here
        return f"{label_part} / (Hz)"  # placeholder unit

    @property
    def data_structure(self) -> str:
        """JSON serialized string describing the Dimension instance."""
        import json

        data = {
            "type": self.type,
            "count": self.count
        }

        if self.description:
            data["description"] = self.description
        if self.label:
            data["label"] = self.label
        if self._application:
            data["application"] = self._application

        if self.type == "linear":
            data["increment"] = f"{self.increment} Hz"  # would format with actual units
            data["coordinates_offset"] = f"{self.coordinates_offset} Hz"
            data["origin_offset"] = f"{self.origin_offset} Hz"
            data["complex_fft"] = self.complex_fft
            data["period"] = "∞ Hz" if self.period == float('inf') else f"{self.period} Hz"
        elif self.type == "monotonic":
            data["coordinates_offset"] = f"{self.coordinates_offset} Hz"
            data["origin_offset"] = f"{self.origin_offset} Hz"
        elif self.type == "labeled":
            data["labels"] = self.labels.tolist()

        return json.dumps(data, indent=2)

    def to(self, unit: str = '', equivalencies=None, update_attrs: bool = False):
        """
        Convert coordinates to specified unit.

        Parameters:
            unit: Target unit string
            equivalencies: Unit equivalencies (not implemented)
            update_attrs: Update attribute units if equivalencies is None

        Raises:
            AttributeError: For labeled dimensions
            NotImplementedError: Unit conversion not yet implemented
        """
        if self.type == "labeled":
            raise AttributeError("Unit conversion not valid for labeled dimensions")

        # Unit conversion would be implemented here using SITypes
        raise NotImplementedError("Unit conversion not yet implemented")

    def dict(self) -> Dict[str, Any]:
        """Return Dimension object as a python dictionary."""
        result = {
            "type": self.type,
            "count": self.count
        }

        if self.description:
            result["description"] = self.description
        if self.label:
            result["label"] = self.label
        if self._application:
            result["application"] = self._application

        if self.type == "linear":
            result["increment"] = f"{self.increment} Hz"  # would use actual units
            result["coordinates_offset"] = f"{self.coordinates_offset} Hz"
            result["origin_offset"] = f"{self.origin_offset} Hz"
            if self.complex_fft:
                result["complex_fft"] = True
            if self.period != float('inf'):
                result["period"] = f"{self.period} Hz"
        elif self.type == "monotonic":
            result["coordinates_offset"] = f"{self.coordinates_offset} Hz"
            result["origin_offset"] = f"{self.origin_offset} Hz"
            if self.period != float('inf'):
                result["period"] = f"{self.period} Hz"
        elif self.type == "labeled":
            result["labels"] = self.labels.tolist()

        return result

    def to_dict(self) -> Dict[str, Any]:
        """Alias to the dict() method."""
        return self.dict()

    def is_quantitative(self) -> bool:
        """Return True if the dimension is quantitative (linear or monotonic)."""
        return self.type in ("linear", "monotonic")

    def copy(self):
        """Return a copy of the Dimension object."""
        # Create new dimension with same parameters
        if self.type == "labeled":
            params = {
                "type": self.type,
                "labels": self.labels.tolist()
            }
        else:
            params = {
                "type": self.type,
                "count": self.count
            }
            if self.type == "linear":
                params.update({
                    "increment": self.increment,
                    "coordinates_offset": self.coordinates_offset,
                    "origin_offset": self.origin_offset,
                    "complex_fft": self.complex_fft
                })
                if self.period != float('inf'):
                    params["period"] = self.period
            elif self.type == "monotonic":
                params.update({
                    "coordinates": self.coordinates,
                    "coordinates_offset": self.coordinates_offset,
                    "origin_offset": self.origin_offset
                })
                if self.period != float('inf'):
                    params["period"] = self.period

        # Add common properties
        if self.description:
            params["description"] = self.description
        if self.label:
            params["label"] = self.label
        if self._application:
            params["application"] = self._application

        return Dimension(params)

    def reciprocal_coordinates(self) -> np.ndarray:
        """Return reciprocal coordinates assuming Nyquist-Shannon theorem."""
        if self.type == "labeled":
            raise AttributeError("reciprocal_coordinates not valid for labeled dimensions")

        coords = self.coordinates
        # Simple reciprocal calculation (would be more sophisticated)
        if len(coords) > 1:
            spacing = coords[1] - coords[0] if self.type == "linear" else np.mean(np.diff(coords))
            if spacing != 0:
                return 1.0 / (len(coords) * spacing) * np.arange(len(coords))
        return np.array([])

    def reciprocal_increment(self) -> float:
        """Return reciprocal increment assuming Nyquist-Shannon theorem."""
        if self.type != "linear":
            raise AttributeError("reciprocal_increment only valid for linear dimensions")

        if self.increment != 0:
            return 1.0 / (self.count * self.increment)
        return 0.0
