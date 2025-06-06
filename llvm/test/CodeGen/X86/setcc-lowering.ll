; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=x86_64-unknown-unknown -mattr=+avx  < %s | FileCheck %s --check-prefixes=AVX,AVX1
; RUN: llc -mtriple=x86_64-unknown-unknown -mattr=+avx2 < %s | FileCheck %s --check-prefixes=AVX,AVX2
; RUN: llc -mtriple=i386-unknown-linux-gnu -mcpu=knl < %s   | FileCheck %s --check-prefixes=AVX,KNL-32


; Verify that we don't crash during codegen due to a wrong lowering
; of a setcc node with illegal operand types and return type.

define <8 x i16> @pr25080(<8 x i32> %a) nounwind {
; AVX1-LABEL: pr25080:
; AVX1:       # %bb.0: # %entry
; AVX1-NEXT:    vextractf128 $1, %ymm0, %xmm0
; AVX1-NEXT:    vpand {{\.?LCPI[0-9]+_[0-9]+}}+16(%rip), %xmm0, %xmm0
; AVX1-NEXT:    vpxor %xmm1, %xmm1, %xmm1
; AVX1-NEXT:    vpcmpeqd %xmm1, %xmm0, %xmm0
; AVX1-NEXT:    vpackssdw %xmm0, %xmm0, %xmm0
; AVX1-NEXT:    vpor {{\.?LCPI[0-9]+_[0-9]+}}(%rip), %xmm0, %xmm0
; AVX1-NEXT:    vzeroupper
; AVX1-NEXT:    retq
;
; AVX2-LABEL: pr25080:
; AVX2:       # %bb.0: # %entry
; AVX2-NEXT:    vpbroadcastd {{.*#+}} xmm1 = [8388607,8388607,8388607,8388607]
; AVX2-NEXT:    vextracti128 $1, %ymm0, %xmm0
; AVX2-NEXT:    vpand %xmm1, %xmm0, %xmm0
; AVX2-NEXT:    vpxor %xmm1, %xmm1, %xmm1
; AVX2-NEXT:    vpcmpeqd %xmm1, %xmm0, %xmm0
; AVX2-NEXT:    vpackssdw %xmm0, %xmm0, %xmm0
; AVX2-NEXT:    vpor {{\.?LCPI[0-9]+_[0-9]+}}(%rip), %xmm0, %xmm0
; AVX2-NEXT:    vzeroupper
; AVX2-NEXT:    retq
;
; KNL-32-LABEL: pr25080:
; KNL-32:       # %bb.0: # %entry
; KNL-32-NEXT:    # kill: def $ymm0 killed $ymm0 def $zmm0
; KNL-32-NEXT:    vptestnmd {{\.?LCPI[0-9]+_[0-9]+}}{1to16}, %zmm0, %k0
; KNL-32-NEXT:    movb $15, %al
; KNL-32-NEXT:    kmovw %eax, %k1
; KNL-32-NEXT:    korw %k1, %k0, %k1
; KNL-32-NEXT:    vpternlogd {{.*#+}} zmm0 {%k1} {z} = -1
; KNL-32-NEXT:    vpmovdw %zmm0, %ymm0
; KNL-32-NEXT:    # kill: def $xmm0 killed $xmm0 killed $ymm0
; KNL-32-NEXT:    retl
entry:
  %0 = trunc <8 x i32> %a to <8 x i23>
  %1 = icmp eq <8 x i23> %0, zeroinitializer
  %2 = or <8 x i1> %1, <i1 true, i1 true, i1 true, i1 true, i1 false, i1 false, i1 false, i1 false>
  %3 = sext <8 x i1> %2 to <8 x i16>
  ret <8 x i16> %3
}

define void @pr26232(i64 %a, <16 x i1> %b) nounwind {
; AVX1-LABEL: pr26232:
; AVX1:       # %bb.0: # %allocas
; AVX1-NEXT:    vpxor %xmm1, %xmm1, %xmm1
; AVX1-NEXT:    .p2align 4
; AVX1-NEXT:  .LBB1_1: # %for_loop599
; AVX1-NEXT:    # =>This Inner Loop Header: Depth=1
; AVX1-NEXT:    cmpq $65536, %rdi # imm = 0x10000
; AVX1-NEXT:    setl %al
; AVX1-NEXT:    vmovd %eax, %xmm2
; AVX1-NEXT:    vpshufb %xmm1, %xmm2, %xmm2
; AVX1-NEXT:    vpand %xmm0, %xmm2, %xmm2
; AVX1-NEXT:    vpsllw $7, %xmm2, %xmm2
; AVX1-NEXT:    vpmovmskb %xmm2, %eax
; AVX1-NEXT:    testl %eax, %eax
; AVX1-NEXT:    jne .LBB1_1
; AVX1-NEXT:  # %bb.2: # %for_exit600
; AVX1-NEXT:    retq
;
; AVX2-LABEL: pr26232:
; AVX2:       # %bb.0: # %allocas
; AVX2-NEXT:    .p2align 4
; AVX2-NEXT:  .LBB1_1: # %for_loop599
; AVX2-NEXT:    # =>This Inner Loop Header: Depth=1
; AVX2-NEXT:    cmpq $65536, %rdi # imm = 0x10000
; AVX2-NEXT:    setl %al
; AVX2-NEXT:    vmovd %eax, %xmm1
; AVX2-NEXT:    vpbroadcastb %xmm1, %xmm1
; AVX2-NEXT:    vpand %xmm0, %xmm1, %xmm1
; AVX2-NEXT:    vpsllw $7, %xmm1, %xmm1
; AVX2-NEXT:    vpmovmskb %xmm1, %eax
; AVX2-NEXT:    testl %eax, %eax
; AVX2-NEXT:    jne .LBB1_1
; AVX2-NEXT:  # %bb.2: # %for_exit600
; AVX2-NEXT:    retq
;
; KNL-32-LABEL: pr26232:
; KNL-32:       # %bb.0: # %allocas
; KNL-32-NEXT:    vpmovsxbd %xmm0, %zmm0
; KNL-32-NEXT:    vpslld $31, %zmm0, %zmm0
; KNL-32-NEXT:    vptestmd %zmm0, %zmm0, %k0
; KNL-32-NEXT:    movl {{[0-9]+}}(%esp), %eax
; KNL-32-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; KNL-32-NEXT:    .p2align 4
; KNL-32-NEXT:  .LBB1_1: # %for_loop599
; KNL-32-NEXT:    # =>This Inner Loop Header: Depth=1
; KNL-32-NEXT:    cmpl $65536, %ecx # imm = 0x10000
; KNL-32-NEXT:    movl %eax, %edx
; KNL-32-NEXT:    sbbl $0, %edx
; KNL-32-NEXT:    setl %dl
; KNL-32-NEXT:    movzbl %dl, %edx
; KNL-32-NEXT:    negl %edx
; KNL-32-NEXT:    kmovw %edx, %k1
; KNL-32-NEXT:    kandw %k0, %k1, %k1
; KNL-32-NEXT:    kortestw %k1, %k1
; KNL-32-NEXT:    jne .LBB1_1
; KNL-32-NEXT:  # %bb.2: # %for_exit600
; KNL-32-NEXT:    retl
allocas:
  br label %for_test11.preheader

for_test11.preheader:                             ; preds = %for_test11.preheader, %allocas
  br i1 undef, label %for_loop599, label %for_test11.preheader

for_loop599:                                      ; preds = %for_loop599, %for_test11.preheader
  %less_i_load605_ = icmp slt i64 %a, 65536
  %less_i_load605__broadcast_init = insertelement <16 x i1> undef, i1 %less_i_load605_, i32 0
  %less_i_load605__broadcast = shufflevector <16 x i1> %less_i_load605__broadcast_init, <16 x i1> undef, <16 x i32> zeroinitializer
  %"oldMask&test607" = and <16 x i1> %less_i_load605__broadcast, %b
  %intmask.i894 = bitcast <16 x i1> %"oldMask&test607" to i16
  %res.i895 = icmp eq i16 %intmask.i894, 0
  br i1 %res.i895, label %for_exit600, label %for_loop599

for_exit600:                                      ; preds = %for_loop599
  ret void
}

define <4 x i32> @pcmpgt(<4 x i8> %x) nounwind {
; AVX-LABEL: pcmpgt:
; AVX:       # %bb.0:
; AVX-NEXT:    vpmovzxbd {{.*#+}} xmm0 = xmm0[0],zero,zero,zero,xmm0[1],zero,zero,zero,xmm0[2],zero,zero,zero,xmm0[3],zero,zero,zero
; AVX-NEXT:    vpxor %xmm1, %xmm1, %xmm1
; AVX-NEXT:    vpcmpgtd %xmm1, %xmm0, %xmm0
; AVX-NEXT:    ret{{[l|q]}}
  %zext = zext <4 x i8> %x to <4 x i32>
  %icmp = icmp ne <4 x i32> %zext, zeroinitializer
  %sext = sext <4 x i1> %icmp to <4 x i32>
  ret <4 x i32> %sext
}
