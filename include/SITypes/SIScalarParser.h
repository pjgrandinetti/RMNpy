//
//  SIScalarParser.h
//
//  Created by PhySy Ltd on 5/3/13.
//  Copyright (c) 2008-2014 PhySy Ltd. All rights reserved.
//

#ifndef SIScalarParser_h
#define SIScalarParser_h

#include "SILibrary.h"
#include "SIScalar.h"
#include "SIUnitParser.h"

typedef const struct impl_scalarNode * ScalarNodeRef;
typedef const struct impl_scalarValue * NumberRef;
typedef const struct impl_scalarNodeMathFunction * ScalarNodeMathFunctionRef;
typedef const struct impl_scalarNodeConstantFunction * ScalarNodeConstantFunctionRef;
typedef const struct impl_scalarNodeSymbol * ScalarNodeSymbolRef;
typedef const struct impl_scalarNodeAssignment * ScalarNodeAssignmentRef;
typedef const struct impl_symbol * SymbolRef;


typedef enum builtInMathFunctions {
    BM_reduce = 1,
    BM_sqrt,
    BM_cbrt,
    BM_qtrt,
    BM_erf,
    BM_erfc,
    BM_exp,
    BM_ln,
    BM_log,
    BM_acos,
    BM_acosh,
    BM_asin,
    BM_asinh,
    BM_atan,
    BM_atanh,
    BM_cos,
    BM_cosh,
    BM_sin,
    BM_sinh,
    BM_tan,
    BM_tanh,
    BM_conj,
    BM_creal,
    BM_cimag,
    BM_carg,
    BM_cabs
} builtInMathFunctions;

typedef enum builtInConstantFunctions {
    BC_AW = 1,
    BC_FW,
    BC_Isotope_Abundance,
    BC_Isotope_Spin,
    BC_Isotope_HalfLife,
    BC_Isotope_Gyromag,
    BC_Isotope_MagneticDipole,
    BC_Isotope_ElectricQuadrupole,
    BC_nmr
} builtInConstantFunctions;

extern OCStringRef scalarErrorString;

ScalarNodeRef ScalarNodeCreateInnerNode(int nodeType, ScalarNodeRef left, ScalarNodeRef right);
ScalarNodeRef ScalarNodeCreateNumberLeaf(SIScalarRef number);
ScalarNodeRef ScalarNodeCreateMathFunction(builtInMathFunctions funcType, ScalarNodeRef left);
ScalarNodeRef ScalarNodeCreateConstantFunction(builtInConstantFunctions funcType, OCMutableStringRef string);
ScalarNodeRef NodeCreateImaginaryUnitLeaf(SIScalarRef number);
SIScalarRef ScalarNodeEvaluate(ScalarNodeRef tree, OCStringRef *errorString);
SIScalarRef builtInMathFunction(ScalarNodeMathFunctionRef func, OCStringRef *errorString);
SIScalarRef builtInConstantFunction(ScalarNodeConstantFunctionRef func, OCStringRef *errorString);
bool ScalarNodeisLeaf(ScalarNodeRef node);
char ScalarNodeGetType(ScalarNodeRef node);
void ScalarNodeFree(ScalarNodeRef node);

SIUnitRef ConversionWithDefinedUnit(OCMutableStringRef mutString, double *unit_multiplier, OCStringRef *errorString);

#endif // SIScalarParser_h
