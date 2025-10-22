; RUN: opt -passes=copyright-metadata -S %s -o - | FileCheck %s --check-prefixes=CHECK,CHECK-O0

; Verify that copyright-metadata is enabled by default on all opt pipelines.
; RUN: opt --O0 -S %s -o - | FileCheck %s --check-prefixes=CHECK,CHECK-O0
; RUN: opt --O1 -S %s -o - | FileCheck %s --check-prefixes=CHECK,CHECK-ON
; RUN: opt --O2 -S %s -o - | FileCheck %s --check-prefixes=CHECK,CHECK-ON
; RUN: opt --O3 -S %s -o - | FileCheck %s --check-prefixes=CHECK,CHECK-ON

; Verify that CopyrightMetadataPass lowers !aix.copyright.comment 
; into concrete, translation-unit–local globals.
;
; For each module (translation unit), the pass performs the following:
;
;   1. Creates a null-terminated, internal constant string global
;      (`__aix_copyright_str`) containing the copyright text.
;
;   2. Marks the string in `llvm.used` so it cannot be dropped by
;      optimization or LTO.
;
;   3. Attaches `!implicit.ref` metadata referencing the string to every
;      defined function in the module. The PowerPC AIX backend recognizes
;      this metadata and emits a `.ref` directive from the function to the
;      string, creating a concrete relocation that prevents the linker from
;      discarding it (as long as the referencing symbol is kept).

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
; CHECK: @__aix_copyright_str = internal unnamed_addr constant [24 x i8] c"@(#) Copyright IBM 2025\00", section "__aix_copyright", align 1
; Preservation in llvm.used sets
; CHECK-NEXT: @llvm.used = appending global [1 x ptr] [ptr @__aix_copyright_str], section "llvm.metadata"
; CHECK-NOT: ![[copyright:[0-9]+]] = !{!"@(#) Copyright IBM 2025"}

; Function has an implicit ref MD pointing at the string:
; CHECK-O0: define void @f0() !implicit.ref ![[MD:[0-9]+]]
; CHECK-ON: define void @f0() local_unnamed_addr #0 !implicit.ref ![[MD:[0-9]+]]
; CHECK-O0: define i32 @main() !implicit.ref ![[MD]]
; CHECK-ON: define noundef i32 @main() local_unnamed_addr #0 !implicit.ref ![[MD]]

; Verify metadata content
; CHECK-O0: ![[MD]] = !{ptr @__aix_copyright_str}
; CHECK-ON: ![[MD]] = !{ptr @__aix_copyright_str}