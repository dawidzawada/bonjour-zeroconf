package com.margelo.nitro.dawidzawada.bonjourzeroconf
  
import com.facebook.proguard.annotations.DoNotStrip

@DoNotStrip
class BonjourZeroconf : HybridBonjourZeroconfSpec() {
  override fun multiply(a: Double, b: Double): Double {
    return a * b
  }
}
