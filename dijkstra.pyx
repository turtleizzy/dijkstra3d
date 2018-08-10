"""
Cython binding for C++ dijkstra shortest path algorithm
applied to 3D images.

Author: William Silversmith
Affiliation: Seung Lab, Princeton Neuroscience Institute
Date: August 2018
"""

from libc.stdlib cimport calloc, free
from libc.stdint cimport (
  uint32_t, int8_t, int16_t, int32_t, int64_t
)
from cpython cimport array 
import array
import sys

from libcpp.vector cimport vector
cimport numpy as cnp
import numpy as np

__VERSION__ = '1.0.0'

SUPPORTED_PYTHON_VERSION = (sys.version_info[0] == 3)

cdef extern from "dijkstra3d.hpp" namespace "dijkstra":
  cdef vector[uint32_t] dijkstra3d[T](
    T* field, 
    int sx, int sy, int sz, 
    int source, int target
  )

def dijkstra(data, int source, int target):
  """
  Perform dijkstra's shortest path algorithm
  on a 3D image grid. Vertices are voxels and
  edges are the 26 nearest neighbors (except
  for the edges of the image where the number
  of edges is reduced).
  
  For given input voxels A and B, the edge
  weight from A to B is B and from B to A is
  A. All weights must be non-negative (incl. 
  negative zero).
  
  Parameters:
   Data: Input weights in a 2D or 3D numpy array. 
   source: 1D index of starting voxel
   target: 1D index of target voxel
  
  Returns: 1D numpy array containing indices of the path from
    source to target including source and target.
  """
  dims = len(data.shape)
  assert dims in (2,3)

  if dims == 2:
    data = data[:, :, np.newaxis]

  dtype = data.dtype
  if np.issubdtype(dtype, np.integer):
    assert np.issubdtype(dtype, np.signedinteger)

  if data.size == 0:
    return np.zeros(shape=(0,), dtype=np.uint32)

  cdef int8_t[:,:,:] arr_memview8
  cdef int16_t[:,:,:] arr_memview16
  cdef int32_t[:,:,:] arr_memview32
  cdef int64_t[:,:,:] arr_memview64
  cdef float[:,:,:] arr_memviewfloat
  cdef double[:,:,:] arr_memviewdouble

  cdef vector[uint32_t] output

  cdef int depth = data.shape[0]
  cdef int rows = data.shape[1]
  cdef int cols = data.shape[2]

  if dtype == np.float32:
    arr_memviewfloat = data
    output = dijkstra3d[float](
      &arr_memviewfloat[0,0,0],
      cols, rows, depth,
      source, target
    )
  elif dtype == np.float64:
    arr_memviewdouble = data
    output = dijkstra3d[double](
      &arr_memviewdouble[0,0,0],
      cols, rows, depth,
      source, target
    )
  elif dtype == np.int64:
    arr_memview64 = data
    output = dijkstra3d[int64_t](
      &arr_memview64[0,0,0],
      cols, rows, depth,
      source, target
    )
  elif dtype == np.int32:
    arr_memview32 = data
    output = dijkstra3d[int32_t](
      &arr_memview32[0,0,0],
      cols, rows, depth,
      source, target
    )
  elif dtype == np.int16:
    arr_memview16 = data
    output = dijkstra3d[int16_t](
      &arr_memview16[0,0,0],
      cols, rows, depth,
      source, target
    )
  elif dtype == np.int8:
    arr_memview8 = data
    output = dijkstra3d[int8_t](
      &arr_memview8[0,0,0],
      cols, rows, depth,
      source, target
    )
  else:
    raise TypeError("Type {} not currently supported.".format(dtype))

  cdef uint32_t* output_ptr = <uint32_t*>&output[0]
  cdef uint32_t[:] vec_view = <uint32_t[:output.size()]>output_ptr

  # This construct is required by python 2.
  # Python 3 can just do np.frombuffer(vec_view, ...)
  buf = bytearray(vec_view[:])
  return np.frombuffer(buf, dtype=np.uint32)
