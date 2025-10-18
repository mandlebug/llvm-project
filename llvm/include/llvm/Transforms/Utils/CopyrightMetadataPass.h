//===-- CopyrightMetadataPass.h - Lower AIX copyright metadata -*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// The CopyrightMetadataPass lowers the module-level metadata emitted by Clang
// for `#pragma comment(copyright, "...")` on AIX:
//
//     !aix.copyright.comment = !{!"Copyright ..."}
//
// into an internal constant string global that is preserved across all compiler
// and linker stages. Each translation unit produces one TU-local string symbol
// (`__aix_copyright_str`), and the pass attaches `!implicit.ref` metadata to
// defined functions referencing this symbol. The PowerPC AIX backend recognizes
// this metadata and emits `.ref` directives in the XCOFF assembly, ensuring the
// copyright strings:
//
//   • survive optimization and LTO,
//   • are not removed by linker garbage collection, and
//   • remain visible in the final binary.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_TRANSFORMS_UTILS_COPYRIGHTMETADATAPASS_H
#define LLVM_TRANSFORMS_UTILS_COPYRIGHTMETADATAPASS_H

#include "llvm/IR/PassManager.h"

namespace llvm {
class CopyrightMetadataPass : public PassInfoMixin<CopyrightMetadataPass> {
public:
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &AM);

  static bool isRequired() { return true; }
};


} // namespace llvm

#endif // LLVM_TRANSFORMS_UTILS_WYVERN_COPYRIGHTMETADATAPASS_H