/* test_minimal.c - Ultra-minimal C extension for Phase 1A testing
 * Goal: Test if basic C compilation works on all platforms
 * Note: Removed complex.h to avoid Windows MinGW issues
 */

#include <Python.h>

/* Test function that uses C99 Variable Length Arrays but not complex.h */
static PyObject *test_c99_features(PyObject *self, PyObject *args) {
    int n = 10;

    /* Test C99 Variable Length Array (VLA) - this will fail on MSVC */
    double test_array[n];

    /* Initialize the VLA with simple arithmetic */
    for (int i = 0; i < n; i++) {
        test_array[i] = (double)i * 2.0;
    }

    /* Return a simple result */
    return PyFloat_FromDouble(test_array[5]);
}

/* Test function to verify MinGW vs MSVC */
static PyObject *test_compiler_check(PyObject *self, PyObject *args) {
#ifdef __MINGW32__
    return PyUnicode_FromString("MinGW");
#elif defined(_MSC_VER)
    return PyUnicode_FromString("MSVC");
#else
    return PyUnicode_FromString("Other");
#endif
}

/* Module method definitions */
static PyMethodDef test_methods[] = {
    {"test_c99_features", test_c99_features, METH_NOARGS, "Test C99 VLA support"},
    {"test_compiler_check", test_compiler_check, METH_NOARGS, "Check which compiler is being used"},
    {NULL, NULL, 0, NULL}  /* Sentinel */
};

/* Module definition */
static struct PyModuleDef test_module = {
    PyModuleDef_HEAD_INIT,
    "_test_minimal",        /* name of module */
    "Ultra-minimal test module for Phase 1A",  /* module documentation */
    -1,                     /* size of per-interpreter state of the module */
    test_methods
};

/* Module initialization function */
PyMODINIT_FUNC PyInit__test_minimal(void) {
    return PyModule_Create(&test_module);
}
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
