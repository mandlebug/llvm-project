; REQUIRES: powerpc-registered-target, system-aix

; Ensure the CopyrightMetadataPass (direct-byte variant) materializes
; a TU-local string and forces a text→data relocation via a tiny ctor,
; so the AIX/XCOFF linker keeps the string alive.

; Build IR with the pass:
; RUN: opt -passes=copyright-metadata %s -o %t.bc

; ---------------- 32-bit AIX ----------------
; RUN: llc -mtriple=powerpc-ibm-aix -filetype=obj -o %t32.o %t.bc
; RUN: llc -mtriple=powerpc-ibm-aix -filetype=asm %t.bc -o - | FileCheck %s --check-prefix=CHECK-ASM

; Symbol table should show our TU-local names (locals are listed with -t).
; RUN: llvm-objdump -t %t32.o | FileCheck %s --check-prefix=CHECK-SYMS

; Relocations should reference the string (due to the volatile byte load).
; RUN: llvm-objdump -r %t32.o | FileCheck %s --check-prefix=CHECK-REL

; ---------------- 64-bit AIX ----------------
; RUN: llc -mtriple=powerpc64-ibm-aix -filetype=obj -o %t64.o %t.bc
; RUN: llc -mtriple=powerpc-ibm-aix -filetype=asm %t.bc -o - | FileCheck %s --check-prefix=CHECK-ASM
; RUN: llvm-objdump -t %t64.o | FileCheck %s --check-prefix=CHECK-SYMS
; RUN: llvm-objdump -r %t64.o | FileCheck %s --check-prefix=CHECK-REL

target triple = "powerpc-ibm-aix"

define i32 @main() { entry: ret i32 0 }

!llvm.module.flags = !{!0}
!0 = !{i32 1, !"wchar_size", i32 2}
!aix.copyright.comment = !{!1}
!1 = !{!"Copyright IBM"}

; Assembly Checks (for a single TU)
; Verify that the backend:
;   - Emits a `.ref` directive to tie the string to the TU
;   - Emits the string in a dedicated read-only csect
;
; CHECK-ASM:       .ref __aix_copyright_str
; CHECK-ASM:       .csect __llvm_copyright[RO],2
; CHECK-ASM-NEXT:  .lglobl __aix_copyright_str
; CHECK-ASM:       __aix_copyright_str
; CHECK-ASM:       .string "Copyright IBM"

; TU-local globals/functions should be present in the symbol table
; CHECK-SYMS: __aix_copyright_str

; Relocation in the object should target the string (from the ctor’s volatile load)
; CHECK-LABEL: RELOCATION RECORDS FOR [.text]
; CHECK-REL: __aix_copyright_str