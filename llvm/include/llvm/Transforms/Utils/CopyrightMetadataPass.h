//===-- CopyrightMetadataPass.h - Lower AIX copyright metadata -*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
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

#endif // LLVM_TRANSFORMS_UTILS_COPYRIGHTMETADATAPASS_H