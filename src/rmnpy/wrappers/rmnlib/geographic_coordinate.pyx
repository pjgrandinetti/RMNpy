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
from rmnpy.helpers.octypes import (
    ocdict_create_from_pydict,
    ocdict_to_pydict,
)

# Import SITypes wrappers
from rmnpy.wrappers.sitypes.scalar cimport Scalar, convert_to_siscalar_ref
from rmnpy.wrappers.sitypes.scalar import Scalar


cdef class GeographicCoordinate:
    """
    Python wrapper for RMNLib GeographicCoordinate.

    A GeographicCoordinate represents a position on Earth with:
    - Latitude: degrees north (positive) or south (negative)
    - Longitude: degrees east (positive) or west (negative)
    - Altitude: optional elevation in meters above sea level
    - Application metadata: optional custom metadata dictionary

    All coordinate values are stored as SIScalar objects with proper units.
    """

    def __cinit__(self):
        """Initialize C-level attributes."""
        self._c_ref = NULL

    def __dealloc__(self):
        """Clean up C resources."""
        if self._c_ref != NULL:
            OCRelease(self._c_ref)

    @staticmethod
    cdef GeographicCoordinate _from_c_ref(GeographicCoordinateRef geo_ref):
        """Create GeographicCoordinate wrapper from C reference (internal use).

        Creates a copy of the coordinate reference, so caller retains ownership
        of their original reference and can safely release it.
        """
        cdef GeographicCoordinate result = GeographicCoordinate.__new__(GeographicCoordinate)
        if geo_ref == NULL:
            raise RMNError("Cannot create wrapper from NULL geographic coordinate reference")

        cdef GeographicCoordinateRef copied_ref = GeographicCoordinateCreateCopy(geo_ref)
        if copied_ref == NULL:
            raise RMNError("Failed to create copy of GeographicCoordinate")
        result._c_ref = copied_ref
        return result

    def __init__(self, latitude, longitude, altitude=None, metadata=None):
        """
        Create a new GeographicCoordinate.

        Parameters:
            latitude : Scalar or numeric
                Latitude in degrees (positive = north, negative = south)
            longitude : Scalar or numeric
                Longitude in degrees (positive = east, negative = west)
            altitude : Scalar or numeric, optional
                Altitude in meters above sea level (default: None)
            metadata : dict, optional
                Application-specific metadata dictionary (default: None)

        Raises:
            RMNError: If coordinate creation fails
            TypeError: If input parameters have incorrect types
        """
        if self._c_ref != NULL:
            return  # Already initialized by _from_c_ref

        cdef SIScalarRef lat_ref = NULL
        cdef SIScalarRef lon_ref = NULL
        cdef SIScalarRef alt_ref = NULL
        cdef OCDictionaryRef metadata_ref = NULL

        try:
            # Convert latitude
            lat_ref = convert_to_siscalar_ref(latitude)
            if lat_ref == NULL:
                raise RMNError("Failed to convert latitude to SIScalar")

            # Convert longitude
            lon_ref = convert_to_siscalar_ref(longitude)
            if lon_ref == NULL:
                raise RMNError("Failed to convert longitude to SIScalar")

            # Convert altitude if provided
            if altitude is not None:
                alt_ref = convert_to_siscalar_ref(altitude)
                if alt_ref == NULL:
                    raise RMNError("Failed to convert altitude to SIScalar")

            # Convert metadata if provided
            if metadata is not None:
                if not isinstance(metadata, dict):
                    raise TypeError("metadata must be a dictionary")
                metadata_ref = <OCDictionaryRef><uint64_t>ocdict_create_from_pydict(metadata)
                if metadata_ref == NULL:
                    raise RMNError("Failed to create metadata dictionary")

            # Create the geographic coordinate
            self._c_ref = GeographicCoordinateCreate(lat_ref, lon_ref, alt_ref, metadata_ref)
            if self._c_ref == NULL:
                raise RMNError("GeographicCoordinate creation failed")

        finally:
            # Note: lat_ref and lon_ref are references to converted scalars
            # We don't release them here as they may be borrowed from input objects
            if metadata_ref != NULL:
                OCRelease(<OCTypeRef>metadata_ref)

    @classmethod
    def from_dict(cls, data_dict):
        """
        Create GeographicCoordinate from dictionary representation.

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
                error_msg = "Unknown error"
                if err_ocstr != NULL:
                    from rmnpy.helpers.octypes import ocstring_to_pystring
                    error_msg = ocstring_to_pystring(<uint64_t>err_ocstr)
                raise RMNError(f"GeographicCoordinate creation from dictionary failed: {error_msg}")

            # Create wrapper from C reference
            return cls._from_c_ref(coord_ref)

        finally:
            # Clean up temporary references
            if dict_ref != NULL:
                OCRelease(<OCTypeRef>dict_ref)
            if err_ocstr != NULL:
                OCRelease(<OCTypeRef>err_ocstr)
            if coord_ref != NULL:
                OCRelease(<OCTypeRef>coord_ref)

    # Property accessors

    @property
    def latitude(self):
        """Get the latitude as a Scalar object."""
        if self._c_ref == NULL:
            raise ValueError("GeographicCoordinate not initialized")

        cdef SIScalarRef lat_ref = GeographicCoordinateGetLatitude(self._c_ref)
        if lat_ref == NULL:
            raise RMNError("Failed to get latitude")

        return Scalar._from_c_ref(lat_ref)

    @latitude.setter
    def latitude(self, value):
        """Set the latitude."""
        if self._c_ref == NULL:
            raise ValueError("GeographicCoordinate not initialized")

        cdef SIScalarRef lat_ref = NULL

        try:
            lat_ref = convert_to_siscalar_ref(value)
            if lat_ref == NULL:
                raise RMNError("Failed to convert latitude to SIScalar")

            if not GeographicCoordinateSetLatitude(self._c_ref, lat_ref):
                raise RMNError("Failed to set latitude")

        except Exception:
            raise

    @property
    def longitude(self):
        """Get the longitude as a Scalar object."""
        if self._c_ref == NULL:
            raise ValueError("GeographicCoordinate not initialized")

        cdef SIScalarRef lon_ref = GeographicCoordinateGetLongitude(self._c_ref)
        if lon_ref == NULL:
            raise RMNError("Failed to get longitude")

        return Scalar._from_c_ref(lon_ref)

    @longitude.setter
    def longitude(self, value):
        """Set the longitude."""
        if self._c_ref == NULL:
            raise ValueError("GeographicCoordinate not initialized")

        cdef SIScalarRef lon_ref = NULL

        try:
            lon_ref = convert_to_siscalar_ref(value)
            if lon_ref == NULL:
                raise RMNError("Failed to convert longitude to SIScalar")

            if not GeographicCoordinateSetLongitude(self._c_ref, lon_ref):
                raise RMNError("Failed to set longitude")

        except Exception:
            raise

    @property
    def altitude(self):
        """Get the altitude as a Scalar object, or None if not set."""
        if self._c_ref == NULL:
            raise ValueError("GeographicCoordinate not initialized")

        cdef SIScalarRef alt_ref = GeographicCoordinateGetAltitude(self._c_ref)
        if alt_ref == NULL:
            return None  # No altitude set

        return Scalar._from_c_ref(alt_ref)

    @altitude.setter
    def altitude(self, value):
        """Set the altitude, or None to clear it."""
        if self._c_ref == NULL:
            raise ValueError("GeographicCoordinate not initialized")

        cdef SIScalarRef alt_ref = NULL

        try:
            if value is None:
                # Setting altitude to None/NULL
                alt_ref = NULL
            else:
                alt_ref = convert_to_siscalar_ref(value)
                if alt_ref == NULL:
                    raise RMNError("Failed to convert altitude to SIScalar")

            if not GeographicCoordinateSetAltitude(self._c_ref, alt_ref):
                raise RMNError("Failed to set altitude")

        except Exception:
            raise

    @property
    def metadata(self):
        """Get the application metadata dictionary."""
        if self._c_ref == NULL:
            raise ValueError("GeographicCoordinate not initialized")

        cdef OCDictionaryRef metadata_ref = GeographicCoordinateGetApplicationMetaData(self._c_ref)
        if metadata_ref == NULL:
            return {}  # Return empty dict if no metadata

        return ocdict_to_pydict(<uint64_t>metadata_ref)

    @metadata.setter
    def metadata(self, value):
        """Set the application metadata dictionary."""
        if self._c_ref == NULL:
            raise ValueError("GeographicCoordinate not initialized")

        if not isinstance(value, dict):
            raise TypeError("metadata must be a dictionary")

        cdef OCDictionaryRef metadata_ref = NULL

        try:
            # Convert Python dictionary to OCDictionary
            metadata_ref = <OCDictionaryRef><uint64_t>ocdict_create_from_pydict(value)
            if metadata_ref == NULL:
                raise RMNError("Failed to create metadata dictionary")

            if not GeographicCoordinateSetApplicationMetaData(self._c_ref, metadata_ref):
                raise RMNError("Failed to set metadata")

        finally:
            if metadata_ref != NULL:
                OCRelease(<OCTypeRef>metadata_ref)

    # Serialization methods

    def to_dict(self):
        """
        Convert geographic coordinate to dictionary representation.

        Returns:
            dict: Dictionary representation of the coordinate

        Raises:
            RMNError: If conversion to dictionary fails
        """
        if self._c_ref == NULL:
            raise ValueError("GeographicCoordinate not initialized")

        cdef OCDictionaryRef dict_ref = GeographicCoordinateCopyAsDictionary(self._c_ref)
        if dict_ref == NULL:
            raise RMNError("Failed to convert geographic coordinate to dictionary")

        try:
            return ocdict_to_pydict(<uint64_t>dict_ref)
        finally:
            OCRelease(<OCTypeRef>dict_ref)

    def dict(self):
        """
        Alias for to_dict() for compatibility.

        Returns:
            dict: Dictionary representation of the coordinate
        """
        return self.to_dict()

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

    @property
    def summary(self):
        """
        Get a summary of the geographic coordinate.

        Returns:
            dict: Summary information about the coordinate
        """
        try:
            lat = self.latitude
            lon = self.longitude
            alt = self.altitude
            metadata = self.metadata

            return {
                'latitude': str(lat) if lat is not None else None,
                'longitude': str(lon) if lon is not None else None,
                'altitude': str(alt) if alt is not None else None,
                'has_metadata': len(metadata) > 0 if metadata else False,
                'metadata_keys': list(metadata.keys()) if metadata else []
            }
        except Exception as e:
            return {'error': f"Failed to generate summary: {str(e)}"}
