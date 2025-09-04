# cython: language_level=3
"""
RMNLib GeographicCoordinate wrapper.

Provides Python access to RMNLib GeographicCoordinate C API for managing
geographic locations with latitude, longitude, altitude, and metadata.
"""

from typing import Any, Dict, Optional, Union

from libc.stdint cimport uint64_t, uintptr_t

from rmnpy._c_api.octypes cimport *
from rmnpy._c_api.rmnlib cimport *
from rmnpy._c_api.sitypes cimport SIScalarRef

from rmnpy.exceptions import RMNError

from rmnpy.wrappers.base_wrapper cimport BaseWrapper, RMNLibWrapper

from rmnpy.helpers.octypes import (
    ocdict_create_from_pydict,
    ocdict_to_pydict,
    pydict_to_cjson_ptr,
)

# Import SITypes wrappers

from rmnpy.wrappers.sitypes.scalar cimport Scalar

from rmnpy.wrappers.sitypes.scalar import Scalar


# Helper function to convert Python types to SIScalarRef using Scalar.from_value
cdef SIScalarRef siscalar_ref_from_pytype(value) except NULL:
    """Convert Python value to SIScalarRef using Scalar.from_value."""
    if value is None:
        return NULL

    # Use Scalar.from_value to convert to Scalar object
    scalar_obj = Scalar.from_value(value)
    # Get the C reference and make a copy for the caller
    return <SIScalarRef>OCTypeDeepCopy((<Scalar>scalar_obj)._c_ref)


cdef class GeographicCoordinate(RMNLibWrapper):
    """Python wrapper for RMNLib GeographicCoordinate objects.

    Represents a geographic location with latitude, longitude, optional altitude,
    and application-specific metadata. Coordinate values are stored as SIScalar
    objects with proper units.

    Examples:
        Create a basic coordinate:

        >>> coord = GeographicCoordinate(40.7128, -74.0060)  # NYC
        >>> coord.latitude.value  # degrees
        40.7128

        Include altitude:

        >>> coord = GeographicCoordinate(40.7128, -74.0060, altitude=10.0)
        >>> coord.altitude.value  # meters
        10.0

        Load from dictionary:

        >>> data = {"latitude": 40.7128, "longitude": -74.0060}
        >>> coord = GeographicCoordinate.from_dict(data)
    """

    @staticmethod
    def from_c_ref(uintptr_t geo_ref_ptr):
        """Create GeographicCoordinate wrapper from C reference pointer."""
        return <GeographicCoordinate>BaseWrapper._from_c_ref(GeographicCoordinate, <void*><GeographicCoordinateRef>geo_ref_ptr)

    def __init__(self, latitude, longitude, altitude=None, metadata=None):
        """Initialize GeographicCoordinate with latitude, longitude, and optional altitude.

        Args:
            latitude: Latitude in degrees (Scalar, string, or numeric)
            longitude: Longitude in degrees (Scalar, string, or numeric)
            altitude: Optional altitude in meters (Scalar, string, or numeric)
            metadata: Optional metadata dictionary
        """
        if self.is_valid():
            return  # Already initialized by BaseWrapper._from_c_ref

        cdef SIScalarRef lat_ref = NULL
        cdef SIScalarRef lon_ref = NULL
        cdef SIScalarRef alt_ref = NULL
        cdef OCDictionaryRef metadata_ref = NULL
        cdef GeographicCoordinateRef coord_ref = NULL
        cdef Scalar latitude_obj
        cdef Scalar longitude_obj
        cdef Scalar altitude_obj

        try:
            # Convert latitude
            latitude_obj = Scalar.from_value(latitude)
            lat_ref = (<SIScalarRef>latitude_obj._get_c_ref())
            if lat_ref == NULL:
                raise RMNError("Failed to convert latitude to SIScalar")

            # Convert longitude
            longitude_obj = Scalar.from_value(longitude)
            lon_ref = (<SIScalarRef>longitude_obj._get_c_ref())
            if lon_ref == NULL:
                raise RMNError("Failed to convert longitude to SIScalar")

            # Convert altitude if provided
            if altitude is not None:
                altitude_obj = Scalar.from_value(altitude)
                alt_ref = (<SIScalarRef>altitude_obj._get_c_ref())
                if alt_ref == NULL:
                    raise RMNError("Failed to convert altitude to SIScalar")

            # Convert metadata if provided
            if metadata is not None:
                if not isinstance(metadata, dict):
                    raise TypeError("metadata must be a dictionary")
                metadata_ref = <OCDictionaryRef><uintptr_t>ocdict_create_from_pydict(metadata)
                if metadata_ref == NULL:
                    raise RMNError("Failed to create metadata dictionary")

            # Create the geographic coordinate and set via base wrapper
            cdef OCStringRef err_ocstr = NULL
            coord_ref = GeographicCoordinateCreate(lat_ref, lon_ref, alt_ref, metadata_ref, &err_ocstr)
            if coord_ref == NULL:
                if err_ocstr != NULL:
                    err_msg = ocstring_to_pystring(err_ocstr)
                    OCRelease(err_ocstr)
                    raise RMNError(f"GeographicCoordinate creation failed: {err_msg}")
                else:
                    raise RMNError("GeographicCoordinate creation failed")
            self._set_c_ref(coord_ref)

        finally:
            # Note: lat_ref and lon_ref are references to converted scalars
            # We don't release them here as they may be borrowed from input objects
            if metadata_ref != NULL:
                OCRelease(<OCTypeRef>metadata_ref)

    @classmethod
    def from_dict(cls, data_dict):
        """Create GeographicCoordinate from dictionary.

        Args:
            data_dict: Dictionary containing coordinate data

        Returns:
            GeographicCoordinate: New coordinate instance
        """
        if not isinstance(data_dict, dict):
            raise TypeError("data_dict must be a dictionary")

        cdef OCStringRef err_ocstr = NULL
        cdef GeographicCoordinateRef coord_ref = NULL
        cdef uintptr_t json_ptr
        cdef cJSON* json_obj = NULL

        try:
            # Convert Python dict → cJSON → GeographicCoordinateRef
            json_ptr = pydict_to_cjson_ptr(data_dict)
            json_obj = <cJSON*>json_ptr

            coord_ref = GeographicCoordinateCreateFromJSON(json_obj, &err_ocstr)
            if coord_ref == NULL:
                from rmnpy.helpers.octypes import ocstring_to_pystring
                error_msg = ocstring_to_pystring(<uintptr_t>err_ocstr) if err_ocstr else "Unknown error"
                raise RMNError(f"GeographicCoordinate creation from dictionary failed: {error_msg}")

            return <GeographicCoordinate>BaseWrapper._from_c_ref(GeographicCoordinate, <void*>coord_ref)

        finally:
            if json_obj != NULL:
                cJSON_Delete(json_obj)
            if err_ocstr != NULL:
                OCRelease(<OCTypeRef>err_ocstr)
            if coord_ref != NULL:
                OCRelease(<OCTypeRef>coord_ref)

    @property
    def data_structure(self):
        """JSON serialized string of dimension object (csdmpy compatibility)."""
        import json
        return json.dumps(self.dict(), ensure_ascii=False, sort_keys=False, indent=2)

    @property
    def latitude(self):
        """Get the latitude as a Scalar object."""
        cdef SIScalarRef lat_ref = GeographicCoordinateGetLatitude(<GeographicCoordinateRef>self._c_ref)
        if lat_ref == NULL:
            raise RMNError("Failed to get latitude")

        return <Scalar>BaseWrapper._from_c_ref(Scalar, <void*>lat_ref)

    @latitude.setter
    def latitude(self, value):
        """Set the latitude."""
        cdef SIScalarRef lat_ref = NULL
        cdef Scalar latitude_obj

        try:
            latitude_obj = Scalar.from_value(value)
            lat_ref = (<SIScalarRef>latitude_obj._get_c_ref())
            if lat_ref == NULL:
                raise RMNError("Failed to convert latitude to SIScalar")

            if not GeographicCoordinateSetLatitude(<GeographicCoordinateRef>self._c_ref, lat_ref):
                raise RMNError("Failed to set latitude")

        except Exception:
            raise

    @property
    def longitude(self):
        """Get the longitude as a Scalar object."""
        cdef SIScalarRef lon_ref = GeographicCoordinateGetLongitude(<GeographicCoordinateRef>self._c_ref)
        if lon_ref == NULL:
            raise RMNError("Failed to get longitude")

        return <Scalar>BaseWrapper._from_c_ref(Scalar, <void*>lon_ref)

    @longitude.setter
    def longitude(self, value):
        """Set the longitude."""
        cdef SIScalarRef lon_ref = NULL
        cdef Scalar longitude_obj

        try:
            longitude_obj = Scalar.from_value(value)
            lon_ref = (<SIScalarRef>longitude_obj._get_c_ref())
            if lon_ref == NULL:
                raise RMNError("Failed to convert longitude to SIScalar")

            if not GeographicCoordinateSetLongitude(<GeographicCoordinateRef>self._c_ref, lon_ref):
                raise RMNError("Failed to set longitude")

        except Exception:
            raise

    @property
    def altitude(self):
        """Get the altitude as a Scalar object, or None if not set."""
        cdef SIScalarRef alt_ref = GeographicCoordinateGetAltitude(<GeographicCoordinateRef>self._c_ref)
        if alt_ref == NULL:
            return None

        return <Scalar>BaseWrapper._from_c_ref(Scalar, <void*>alt_ref)

    @altitude.setter
    def altitude(self, value):
        """Set the altitude, or None to clear it."""
        cdef SIScalarRef alt_ref = NULL
        cdef Scalar altitude_obj

        try:
            if value is None:
                # Setting altitude to None/NULL
                alt_ref = NULL
            else:
                altitude_obj = Scalar.from_value(value)
                alt_ref = (<SIScalarRef>altitude_obj._get_c_ref())
                if alt_ref == NULL:
                    raise RMNError("Failed to convert altitude to SIScalar")

            if not GeographicCoordinateSetAltitude(<GeographicCoordinateRef>self._c_ref, alt_ref):
                raise RMNError("Failed to set altitude")

        except Exception:
            raise

    def __repr__(self):
        """Return string representation of the geographic coordinate."""
        try:
            lat = self.latitude
            lon = self.longitude
            alt = self.altitude

            lat_str = f"{lat}" if lat is not None else "None"
            lon_str = f"{lon}" if lon is not None else "None"
            alt_str = f"{alt}" if alt is not None else "None"

            return f"GeographicCoordinate(latitude={lat_str}, longitude={lon_str}, altitude={alt_str})"
        except Exception:
            # Fallback if any property access fails
            return f"GeographicCoordinate(at {hex(id(self))})"

    def __str__(self):
        """Return string representation of the geographic coordinate."""
        return self.__repr__()
