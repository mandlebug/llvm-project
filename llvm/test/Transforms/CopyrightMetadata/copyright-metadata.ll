; RUN: opt -passes=copyright-metadata -S %s -o - | FileCheck %s

; Verify the pass converts !aix.copyright.comment into:
;  - internal constant string global
;  - marks it in llvm.used and llvm.compiler.used
;  - creates an internal anchor function and registers it in llvm.global_ctors

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
!1 = !{!"@(#) Copyright IBM 2025"}


; ---- Globals--------------------------------------------
; CHECK: @__aix_copyright_str = internal unnamed_addr constant [24 x i8] c"@(#) Copyright IBM 2025\00", section "__llvm_copyright", align 1
; Preservation in used sets
; CHECK-NEXT: @llvm.used = appending global [1 x ptr] [ptr @__aix_copyright_str], section "llvm.metadata"
; CHECK-NOT: ![[copyright:[0-9]+]] = !{!"@(#) Copyright IBM 2025"}

; Function has an implicit ref MD pointing at the string:
; CHECK: define void @f0() !implicit.ref ![[MD:[0-9]+]]
; CHECK: define i32 @main() !implicit.ref ![[MD]]
; CHECK: ![[MD]] = !{ptr @__aix_copyright_str}