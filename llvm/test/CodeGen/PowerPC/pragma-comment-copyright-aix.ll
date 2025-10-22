; REQUIRES: powerpc-registered-target, system-aix

; This test verify that the CopyrightMetadataPass and the PowerPC AIX backend
; correctly lower and preserve copyright metadata emitted by Clang
; from `#pragma comment(copyright, "...")`.

; Build IR with the pass:
; RUN: opt -passes=copyright-metadata %s -o %t.bc

; ---------------- 32-bit AIX ----------------
; RUN: llc -mtriple=powerpc-ibm-aix -filetype=obj -o %t32.o %t.bc
; RUN: llc -mtriple=powerpc-ibm-aix -filetype=asm %t.bc -o - | FileCheck %s --check-prefix=CHECK-ASM

; Verify that TU-local symbols and relocations reference the string.
; RUN: llvm-objdump -t %t32.o | FileCheck %s --check-prefix=CHECK-SYMS
; RUN: llvm-objdump -r %t32.o | FileCheck %s --check-prefix=CHECK-REL

; ---------------- 64-bit AIX ----------------
; RUN: llc -mtriple=powerpc64-ibm-aix -filetype=obj -o %t64.o %t.bc
; RUN: llc -mtriple=powerpc-ibm-aix -filetype=asm %t.bc -o - | FileCheck %s --check-prefix=CHECK-ASM
; RUN: llvm-objdump -t %t64.o | FileCheck %s --check-prefix=CHECK-SYMS
; RUN: llvm-objdump -r %t64.o | FileCheck %s --check-prefix=CHECK-REL

target triple = "powerpc-ibm-aix"

define void @f0() {
entry:
  ret void
}

define i32 @main() {
entry:
  ret i32 0
}

!llvm.module.flags = !{!0}
!0 = !{i32 1, !"wchar_size", i32 2}

!aix.copyright.comment = !{!1}
!1 = !{!"Copyright IBM"}

; ---------------- Assembly checks ----------------
; Verify that the backend:
;   - Emits a `.ref` directive for the string
;   - Emits the string in a dedicated read-only csect
;
; CHECK-ASM:       .ref __aix_copyright_str
; CHECK-ASM:       .csect __aix_copyright[RO],2
; CHECK-ASM-NEXT:  .lglobl __aix_copyright_str
; CHECK-ASM:       __aix_copyright_str
; CHECK-ASM:       .string "Copyright IBM"

; ---------------- Symbol table checks ----------------
; TU-local globals/functions should be present in the symbol table
; CHECK-SYMS: __aix_copyright_str

; ---------------- Relocation checks ----------------
; The object should contain a relocation in the text section
; that references the copyright string.
; CHECK-LABEL: RELOCATION RECORDS FOR [.text]
; CHECK-REL: __aix_copyright_str