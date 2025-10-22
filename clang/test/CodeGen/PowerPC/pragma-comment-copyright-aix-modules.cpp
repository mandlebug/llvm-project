// RUN: split-file %s %t

// Build the module interface to a PCM
// RUN: %clang_cc1 -std=c++20 -triple powerpc-ibm-aix \
// RUN:   -emit-module-interface %t/copymod.cppm -o %t/copymod.pcm

// verify that module interface emit copyright string when compiled to assembly
// RUN: %clang_cc1 -std=c++20 -triple powerpc-ibm-aix -S %t/copymod.cppm -o - \
// RUN:   | FileCheck %s --check-prefix=CHECK-MOD
// CHECK-MOD: .string "module me"

// Compile an importing TU that uses the prebuilt module and verify that it
// does NOT re-emit the module's copyright string.
// RUN: %clang_cc1 -std=c++20 -triple powerpc-ibm-aix \
// RUN:   -fprebuilt-module-path=%t -S %t/importmod.cc -o - \
// RUN:   | FileCheck %s
// CHECK-NOT: .string "module me"

//--- copymod.cppm
export module copymod;
#pragma comment(copyright, "module me")
export inline void f() {}

//--- importmod.cc
import copymod;
void g() { f(); }
