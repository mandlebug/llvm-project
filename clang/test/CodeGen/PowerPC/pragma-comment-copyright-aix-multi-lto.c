// REQUIRES: powerpc-registered-target, system-aix, clang
//
// This test verifies correct handling of `#pragma comment(copyright, ...)`
// on AIX for multiple Translation Units (TUs).
//
// Each TU defines one `#pragma comment(copyright, "...")` which should:
//   - Generate a unique read-only `__llvm_copyright` csect containing the string.
//   - Create a `.ref` directive from at least one function in that TU to the
//     corresponding copyright symbol.
//   - Preserve these copyright strings across LTO and ThinLTO linking.
//
// -----------------------------------------------------------------------------
//  Build WITHOUT LTO
// -----------------------------------------------------------------------------
// RUN: split-file %s %t
//
// RUN: %clang_cc1 -triple powerpc-ibm-aix -emit-llvm-bc %t/file1.c -o %t/file1.bc
// RUN: %clang_cc1 -triple powerpc-ibm-aix -emit-llvm-bc %t/file2.c -o %t/file2.bc
// RUN: %clang_cc1 -triple powerpc-ibm-aix -emit-llvm-bc %t/file3.c -o %t/file3.bc
// RUN: %clang_cc1 -triple powerpc-ibm-aix -emit-llvm-bc %t/main.c  -o %t/main.bc
//
// Compile each bitcode file to XCOFF object and link them together:
// RUN: %clang -c %t/file1.bc -o %t/file1.o
// RUN: %clang -c %t/file2.bc -o %t/file2.o
// RUN: %clang -c %t/file3.bc -o %t/file3.o
// RUN: %clang -c %t/main.bc  -o %t/main.o
// RUN: %clang %t/file1.o %t/file2.o %t/file3.o %t/main.o -o %t/nonlto.exe
//
// Verify assembly emission and linked outputs:
// RUN: llc -mtriple=powerpc-ibm-aix -filetype=asm %t/file1.bc -o - | FileCheck %s --check-prefix=CHECK-ASM
// RUN: /bin/strings -a %t/nonlto.exe | FileCheck %s --check-prefix=CHECK-STRINGS
// RUN: llvm-nm %t/nonlto.exe | FileCheck %s --check-prefix=CHECK-NM
// RUN: llvm-objdump -r %t/nonlto.exe | FileCheck %s --check-prefix=CHECK-OBJDUMP
//
// -----------------------------------------------------------------------------
//  Build WITH Full LTO
// -----------------------------------------------------------------------------
// RUN: %clang -flto %t/file1.bc %t/file2.bc %t/file3.bc %t/main.bc -o %t/lto.exe
// RUN: /bin/strings -a %t/lto.exe | FileCheck %s --check-prefix=CHECK-STRINGS
// RUN: llvm-nm %t/lto.exe | FileCheck %s --check-prefix=CHECK-NM
// RUN: llvm-objdump -r %t/lto.exe | FileCheck %s --check-prefix=CHECK-OBJDUMP
//
// -----------------------------------------------------------------------------
//  Build WITH ThinLTO
// -----------------------------------------------------------------------------
// RUN: %clang -flto=thin %t/file1.bc %t/file2.bc %t/file3.bc %t/main.bc -o %t/lto-thin.exe
// RUN: /bin/strings -a %t/lto-thin.exe | FileCheck %s --check-prefix=CHECK-STRINGS
// RUN: llvm-nm %t/lto-thin.exe | FileCheck %s --check-prefix=CHECK-NM
// RUN: llvm-objdump -r %t/lto-thin.exe | FileCheck %s --check-prefix=CHECK-OBJDUMP
//
// -----------------------------------------------------------------------------
//  Assembly Checks (for a single TU)
// -----------------------------------------------------------------------------
//
// Verify that the backend:
//   - Emits a `.ref` directive to tie the string to the TU
//   - Emits the string in a dedicated read-only csect
//
// CHECK-ASM:       .ref __aix_copyright_str
// CHECK-ASM:       .csect __llvm_copyright[RO],2
// CHECK-ASM-NEXT:  .lglobl __aix_copyright_str
// CHECK-ASM:       __aix_copyright_str
// CHECK-ASM:       .string "Copyright 2025 TU A"
//
// -----------------------------------------------------------------------------
//  Final Binary Checks
// -----------------------------------------------------------------------------
//
// Ensure all TUs’ copyright strings are preserved.
// CHECK-STRINGS-DAG: Copyright 2025 TU A
// CHECK-STRINGS-DAG: Copyright 2025 TU B
// CHECK-STRINGS-DAG: Copyright 2025 TU C
// CHECK-STRINGS-DAG: Copyright 2025 Main Program
//
// Check that the symbols are visible in the binary symbol table.
// CHECK-NM: t __aix_copyright_str
// CHECK-NM: t __llvm_copyright
//
// Ensure there’s a relocation record referencing the copyright symbol.
// CHECK-OBJDUMP-LABEL: RELOCATION RECORDS FOR [.text]
// CHECK-OBJDUMP: R_REF  __aix_copyright_str
//

//=== file1.c ===
//--- file1.c
#pragma comment(copyright, "Copyright 2025 TU A")
void func1(void) {}

//=== file2.c ===
//--- file2.c
#pragma comment(copyright, "Copyright 2025 TU B")
void func2(void) {}

//=== file3.c ===
//--- file3.c
#pragma comment(copyright, "Copyright 2025 TU C")
void func3(void) {}

//=== main.c ===
//--- main.c
#pragma comment(copyright, "Copyright 2025 Main Program")
void func1(void);
void func2(void);
void func3(void);
int main(void) {
  func1();
  func2();
  func3();
  return 0;
}
