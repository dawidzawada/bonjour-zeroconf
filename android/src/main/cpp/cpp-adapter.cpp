#include <jni.h>
#include "dawidzawada_bonjourzeroconfOnLoad.hpp"

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* vm, void*) {
  return margelo::nitro::dawidzawada_bonjourzeroconf::initialize(vm);
}
