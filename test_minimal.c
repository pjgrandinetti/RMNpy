/* test_minimal.c - Ultra-minimal C extension for Phase 1A testing
 * Goal: Test if C99 compilation works on all platforms
 */

#include <Python.h>
#include <complex.h>  // Test C99 complex.h support
#include <stddef.h>

/* Test function that uses C99 features */
static PyObject *test_c99_features(PyObject *self, PyObject *args) {
    int n = 10;

    /* Test C99 Variable Length Array (VLA) - this will fail on MSVC */
    double test_array[n];

    /* Test C99 complex numbers */
    double complex z = 1.0 + 2.0*I;
    double real_part = creal(z);
    double imag_part = cimag(z);

    /* Initialize the VLA */
    for (int i = 0; i < n; i++) {
        test_array[i] = (double)i + real_part;
    }

    /* Return a simple result */
    return PyFloat_FromDouble(test_array[5] + imag_part);
}

/* Test function to verify MinGW vs MSVC */
static PyObject *test_compiler_info(PyObject *self, PyObject *args) {
    const char *compiler_info;

#ifdef __GNUC__
    compiler_info = "GCC/MinGW";
#elif defined(_MSC_VER)
    compiler_info = "MSVC";
#else
    compiler_info = "Unknown";
#endif

    return PyUnicode_FromString(compiler_info);
}

/* Method definitions */
static PyMethodDef TestMethods[] = {
    {"test_c99_features", test_c99_features, METH_NOARGS,
     "Test C99 VLA and complex number support"},
    {"test_compiler_info", test_compiler_info, METH_NOARGS,
     "Return compiler information"},
    {NULL, NULL, 0, NULL}
};

/* Module definition */
static struct PyModuleDef testmodule = {
    PyModuleDef_HEAD_INIT,
    "_test_minimal",
    "Minimal test module for Phase 1A",
    -1,
    TestMethods
};

/* Module initialization */
PyMODINIT_FUNC PyInit__test_minimal(void) {
    return PyModule_Create(&testmodule);
}
