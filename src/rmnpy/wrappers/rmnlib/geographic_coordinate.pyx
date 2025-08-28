# cython: language_level=3
"""
RMNLib GeographicCoordinate wrapper

This module provides a Python wrapper around the RMNLib GeographicCoordinate C API.
GeographicCoordinate represents a geographic location with latitude, longitude,
optional altitude, and application-specific metadata.

Geographic coordinates use SI Scalars for precise representation of physical
measurements with proper units and dimensional analysis.
"""

from typing import Dict, Optional, Union

from rmnpy._c_api.octypes cimport *
from rmnpy._c_api.rmnlib cimport *
from rmnpy._c_api.sitypes cimport SIScalarRef

from rmnpy.exceptions import RMNError
from rmnpy.wrappers.base_wrapper cimport BaseWrapper, RMNLibWrapper
from rmnpy.helpers.octypes import (
    ocdict_create_from_pydict,
    ocdict_to_pydict,
)

# Import SITypes wrappers
from rmnpy.wrappers.sitypes.scalar cimport Scalar, create_siscalar_from_pytype
from rmnpy.wrappers.sitypes.scalar import Scalar


cdef class GeographicCoordinate(RMNLibWrapper):
    """
    Python wrapper for RMNLib GeographicCoordinate.

    A GeographicCoordinate represents a position on Earth with:
    - Latitude: degrees north (positive) or south (negative)
    - Longitude: degrees east (positive) or west (negative)
    - Altitude: optional elevation in meters above sea level
    - Application metadata: optional custom metadata dictionary

    All coordinate values are stored as SIScalar objects with proper units.
    """

    # No _from_c_ref method needed - use BaseWrapper._from_c_ref directly!

    @staticmethod
    def from_c_ref(uint64_t geo_ref_ptr):
        """Create GeographicCoordinate wrapper from C reference pointer (Python-accessible)."""
        return <GeographicCoordinate>BaseWrapper._from_c_ref(GeographicCoordinate, <void*><GeographicCoordinateRef>geo_ref_ptr)

    def __init__(self, latitude, longitude, altitude=None, metadata=None):
        """
        Create a new GeographicCoordinate.

        Parameters:
            latitude : Scalar, String, or numeric
                Latitude in degrees (positive = north, negative = south)
            longitude : Scalar, String, or numeric
                Longitude in degrees (positive = east, negative = west)
            altitude : Scalar, String, or numeric, optional
                Altitude in meters above sea level (default: None)
            metadata : dict, optional
                Application-specific metadata dictionary (default: None)

        Raises:
            RMNError: If coordinate creation fails
            TypeError: If input parameters have incorrect types
        """
        if self.is_valid():
            return  # Already initialized by BaseWrapper._from_c_ref

        cdef SIScalarRef lat_ref = NULL
        cdef SIScalarRef lon_ref = NULL
        cdef SIScalarRef alt_ref = NULL
        cdef OCDictionaryRef metadata_ref = NULL
        cdef GeographicCoordinateRef coord_ref = NULL

        try:
            # Convert latitude
            lat_ref = create_siscalar_from_pytype(latitude)
            if lat_ref == NULL:
                raise RMNError("Failed to convert latitude to SIScalar")

            # Convert longitude
            lon_ref = create_siscalar_from_pytype(longitude)
            if lon_ref == NULL:
                raise RMNError("Failed to convert longitude to SIScalar")

            # Convert altitude if provided
            if altitude is not None:
                alt_ref = create_siscalar_from_pytype(altitude)
                if alt_ref == NULL:
                    raise RMNError("Failed to convert altitude to SIScalar")

            # Convert metadata if provided
            if metadata is not None:
                if not isinstance(metadata, dict):
                    raise TypeError("metadata must be a dictionary")
                metadata_ref = <OCDictionaryRef><uint64_t>ocdict_create_from_pydict(metadata)
                if metadata_ref == NULL:
                    raise RMNError("Failed to create metadata dictionary")

            # Create the geographic coordinate and set via base wrapper
            coord_ref = GeographicCoordinateCreate(lat_ref, lon_ref, alt_ref, metadata_ref)
            if coord_ref == NULL:
                raise RMNError("GeographicCoordinate creation failed")
            self._set_c_ref(coord_ref)

        finally:
            # Note: lat_ref and lon_ref are references to converted scalars
            # We don't release them here as they may be borrowed from input objects
            if metadata_ref != NULL:
                OCRelease(<OCTypeRef>metadata_ref)

    @classmethod
    def from_dict(cls, data_dict):
        """Create GeographicCoordinate from dictionary representation.

        Parameters:
            data_dict : dict
                Dictionary containing coordinate data

        Returns:
            GeographicCoordinate: New coordinate instance

        Raises:
            RMNError: If coordinate creation from dictionary fails
            TypeError: If data_dict is not a dictionary
        """
        if not isinstance(data_dict, dict):
            raise TypeError("data_dict must be a dictionary")

        cdef OCDictionaryRef dict_ref = NULL
        cdef OCStringRef err_ocstr = NULL
        cdef GeographicCoordinateRef coord_ref = NULL

        try:
            # Convert Python dictionary to OCDictionary
            dict_ref = <OCDictionaryRef><uint64_t>ocdict_create_from_pydict(data_dict)
            if dict_ref == NULL:
                raise RMNError("Failed to convert dictionary to OCDictionary")

            # Create coordinate from dictionary
            coord_ref = GeographicCoordinateCreateFromDictionary(dict_ref, &err_ocstr)
            if coord_ref == NULL:
                from rmnpy.helpers.octypes import ocstring_to_pystring
                error_msg = ocstring_to_pystring(<uint64_t>err_ocstr) if err_ocstr else "Unknown error"
                raise RMNError(f"GeographicCoordinate creation from dictionary failed: {error_msg}")

            # Create wrapper from C reference using universal BaseWrapper method
            return <GeographicCoordinate>BaseWrapper._from_c_ref(GeographicCoordinate, <void*>coord_ref)

        finally:
            # Clean up temporary references
            if dict_ref != NULL:
                OCRelease(<OCTypeRef>dict_ref)
            if err_ocstr != NULL:
                OCRelease(<OCTypeRef>err_ocstr)
            if coord_ref != NULL:
                OCRelease(<OCTypeRef>coord_ref)

    @property
    def data_structure(self):
        """JSON serialized string of dimension object (csdmpy compatibility)."""
        import json
        return json.dumps(self.to_dict(), ensure_ascii=False, sort_keys=False, indent=2)

    # Property accessors

    @property
    def latitude(self):
        """Get the latitude as a Scalar object."""
        self._validate_initialized()

        cdef SIScalarRef lat_ref = GeographicCoordinateGetLatitude(<GeographicCoordinateRef>self._c_ref)
        if lat_ref == NULL:
            raise RMNError("Failed to get latitude")

        return <Scalar>BaseWrapper._from_c_ref(Scalar, <void*>lat_ref)

    @latitude.setter
    def latitude(self, value):
        """Set the latitude."""
        self._validate_initialized()

        cdef SIScalarRef lat_ref = NULL

        try:
            lat_ref = create_siscalar_from_pytype(value)
            if lat_ref == NULL:
                raise RMNError("Failed to convert latitude to SIScalar")

            if not GeographicCoordinateSetLatitude(<GeographicCoordinateRef>self._c_ref, lat_ref):
                raise RMNError("Failed to set latitude")

        except Exception:
            raise

    @property
    def longitude(self):
        """Get the longitude as a Scalar object."""
        self._validate_initialized()

        cdef SIScalarRef lon_ref = GeographicCoordinateGetLongitude(<GeographicCoordinateRef>self._c_ref)
        if lon_ref == NULL:
            raise RMNError("Failed to get longitude")

        return <Scalar>BaseWrapper._from_c_ref(Scalar, <void*>lon_ref)

    @longitude.setter
    def longitude(self, value):
        """Set the longitude."""
        self._validate_initialized()

        cdef SIScalarRef lon_ref = NULL

        try:
            lon_ref = create_siscalar_from_pytype(value)
            if lon_ref == NULL:
                raise RMNError("Failed to convert longitude to SIScalar")

            if not GeographicCoordinateSetLongitude(<GeographicCoordinateRef>self._c_ref, lon_ref):
                raise RMNError("Failed to set longitude")

        except Exception:
            raise

    @property
    def altitude(self):
        """Get the altitude as a Scalar object, or None if not set."""
        self._validate_initialized()

        cdef SIScalarRef alt_ref = GeographicCoordinateGetAltitude(<GeographicCoordinateRef>self._c_ref)
        if alt_ref == NULL:
            return None  # No altitude set

        return <Scalar>BaseWrapper._from_c_ref(Scalar, <void*>alt_ref)

    @altitude.setter
    def altitude(self, value):
        """Set the altitude, or None to clear it."""
        self._validate_initialized()

        cdef SIScalarRef alt_ref = NULL

        try:
            if value is None:
                # Setting altitude to None/NULL
                alt_ref = NULL
            else:
                alt_ref = create_siscalar_from_pytype(value)
                if alt_ref == NULL:
                    raise RMNError("Failed to convert altitude to SIScalar")

            if not GeographicCoordinateSetAltitude(<GeographicCoordinateRef>self._c_ref, alt_ref):
                raise RMNError("Failed to set altitude")

        except Exception:
            raise

    @property
    def metadata(self):
        """Get the application metadata dictionary."""
        self._validate_initialized()

        cdef OCDictionaryRef metadata_ref = GeographicCoordinateGetApplicationMetaData(<GeographicCoordinateRef>self._c_ref)
        if metadata_ref == NULL:
            return {}  # Return empty dict if no metadata

        return ocdict_to_pydict(<uint64_t>metadata_ref)

    @metadata.setter
    def metadata(self, value):
        """Set the application metadata dictionary."""
        self._validate_initialized()

        if not isinstance(value, dict):
            raise TypeError("metadata must be a dictionary")

        cdef OCDictionaryRef metadata_ref = NULL

        try:
            # Convert Python dictionary to OCDictionary
            metadata_ref = <OCDictionaryRef><uint64_t>ocdict_create_from_pydict(value)
            if metadata_ref == NULL:
                raise RMNError("Failed to create metadata dictionary")

            if not GeographicCoordinateSetApplicationMetaData(<GeographicCoordinateRef>self._c_ref, metadata_ref):
                raise RMNError("Failed to set metadata")

        finally:
            if metadata_ref != NULL:
                OCRelease(<OCTypeRef>metadata_ref)

    def copy(self):
        """Create a copy of this GeographicCoordinate using universal copying."""
        # BaseWrapper.copy_c_ref() already handles validation and copying via OCTypeDeepCopy
        cdef void* copied_ref = self.copy_c_ref()
        return <GeographicCoordinate>BaseWrapper._from_c_ref(GeographicCoordinate, copied_ref)

    # Universal dictionary serialization is inherited from BaseWrapper via OCTypeCopyJSON
    # Custom serialization methods are no longer needed!

    def dict(self):
        """
        Alias for to_dict() for compatibility.

        Returns:
            dict: Dictionary representation of the coordinate
        """
        return self.to_dict()

    # Comparison is handled by universal OCTypeEqual in BaseWrapper

    # Utility methods

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
