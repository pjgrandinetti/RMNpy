#!/usr/bin/env python3
"""Debug SIUnit symbol issues"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from rmnpy.sitypes.unit import SIUnit

def debug_unit_symbols():
    print("=== SIUnit Symbol Debug ===\n")
    
    # Test 1: Basic unit creation
    print("1. Basic unit creation:")
    try:
        kg, _ = SIUnit.from_expression("kg")
        m, _ = SIUnit.from_expression("m")
        s, _ = SIUnit.from_expression("s")
        
        print(f"   kg symbol: '{kg.symbol}' (len={len(kg.symbol)})")
        print(f"   m symbol: '{m.symbol}' (len={len(m.symbol)})")
        print(f"   s symbol: '{s.symbol}' (len={len(s.symbol)})")
        
    except Exception as e:
        print(f"   ❌ Failed: {e}")
        return
    
    # Test 2: Simple multiplication
    print("\n2. Simple multiplication:")
    try:
        result = m * s
        print(f"   m * s symbol: '{result.symbol}' (len={len(result.symbol)})")
        print(f"   m * s __str__: '{str(result)}'")
        
    except Exception as e:
        print(f"   ❌ Failed: {e}")
    
    # Test 3: Debug the expression parsing
    print("\n3. Expression parsing:")
    try:
        # Try creating units via expression directly
        ms, _ = SIUnit.from_expression("m*s")
        print(f"   Direct m*s symbol: '{ms.symbol}' (len={len(ms.symbol)})")
        
        # Try alternate expression
        ms2, _ = SIUnit.from_expression("(m)*(s)")
        print(f"   Direct (m)*(s) symbol: '{ms2.symbol}' (len={len(ms2.symbol)})")
        
        # Try simple multiplication expression
        ms3, _ = SIUnit.from_expression("m s")
        print(f"   Direct 'm s' symbol: '{ms3.symbol}' (len={len(ms3.symbol)})")
        
    except Exception as e:
        print(f"   ❌ Failed: {e}")
    
    # Test 4: Test power expression
    print("\n4. Power expression:")
    try:
        s2 = s ** 2
        print(f"   s^2 symbol: '{s2.symbol}' (len={len(s2.symbol)})")
        
        # Direct creation
        s2_direct, _ = SIUnit.from_expression("s^2")
        print(f"   Direct s^2 symbol: '{s2_direct.symbol}' (len={len(s2_direct.symbol)})")
        
    except Exception as e:
        print(f"   ❌ Failed: {e}")

if __name__ == "__main__":
    debug_unit_symbols()
