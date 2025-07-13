#ifndef SIDIMENSIONALITY_PRIVATE_H
#define SIDIMENSIONALITY_PRIVATE_H

#include "SILibrary.h"
#define BASE_DIMENSION_COUNT 7
// SIDimensionality Opaque Type
struct impl_SIDimensionality {
    OCBase base;
    // SIDimensionality Type attributes  - order of declaration is essential
    uint8_t num_exp[BASE_DIMENSION_COUNT];
    uint8_t den_exp[BASE_DIMENSION_COUNT];
    OCStringRef symbol;
};
SIDimensionalityRef SIDimensionalityCreate(const uint8_t *num_exp, const uint8_t *den_exp);
OCDictionaryRef SIDimensionalityCopyDictionary(SIDimensionalityRef dim);
SIDimensionalityRef SIDimensionalityFromDictionary(OCDictionaryRef dict, OCStringRef *error);
SIDimensionalityRef SIDimensionalityWithExponentArrays(const uint8_t *num_exp, const uint8_t *den_exp);
static SIDimensionalityRef SIDimensionalityWithExponents(uint8_t length_num_exp, uint8_t length_den_exp,
                                                         uint8_t mass_num_exp, uint8_t mass_den_exp,
                                                         uint8_t time_num_exp, uint8_t time_den_exp,
                                                         uint8_t current_num_exp, uint8_t current_den_exp,
                                                         uint8_t temperature_num_exp, uint8_t temperature_den_exp,
                                                         uint8_t amount_num_exp, uint8_t amount_den_exp,
                                                         uint8_t luminous_num_exp, uint8_t luminous_den_exp);
void cleanupDimensionalityLibraries(void);

#endif /* SIDIMENSIONALITY_PRIVATE_H */