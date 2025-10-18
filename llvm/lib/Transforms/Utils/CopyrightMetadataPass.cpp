//===-- CopyrightMetadataPass.cpp - Lower AIX copyright metadata ----------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This pass lowers module-level copyright metadata emitted by Clang:
//
//     !aix.copyright.comment = !{!"Copyright ..."}
//
// into concrete, translation-unit–local globals to ensure that copyright
// strings:
//
//   • survive all optimization and LTO pipelines,
//   • are not removed by linker garbage collection, and
//   • remain visible in the final XCOFF binary.
//
// For each module (translation unit), the pass performs the following:
//
//   1. Creates a null-terminated, internal constant string global
//      (`__aix_copyright_str`) containing the copyright text.
//
//   2. Marks the string in `llvm.used` so it cannot be dropped by
//      optimization or LTO.
//
//   3. Attaches `!implicit.ref` metadata referencing the string to every
//      defined function in the module. The PowerPC AIX backend recognizes
//      this metadata and emits a `.ref` directive from the function to the
//      string, creating a concrete relocation that prevents the linker from
//      discarding it.
//
//===----------------------------------------------------------------------===//


#include "llvm/Transforms/Utils/CopyrightMetadataPass.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Attributes.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/MDBuilder.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/Value.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/TargetParser/Triple.h"
#include "llvm/Transforms/Utils/ModuleUtils.h"

#define DEBUG_TYPE "copyright-metadata"

using namespace llvm;

namespace llvm {

static cl::opt<bool>
    DisableCopyrightMetadata("disable-copyright-metadata", cl::ReallyHidden,
                             cl::desc("Disable copyright metadata pass."),
                             cl::init(false));

static bool isAIXTriple(const Module &M) {
  return Triple(M.getTargetTriple()).isOSAIX();
}

PreservedAnalyses CopyrightMetadataPass::run(Module &M,
                                             ModuleAnalysisManager &AM) {
  if (DisableCopyrightMetadata || !isAIXTriple(M))
    return PreservedAnalyses::all();

  LLVMContext &Ctx = M.getContext();

  // Single-metadata: !aix.copyright.comment = !{!0}
  // Each operand node is expected to have one MDString operand.
  NamedMDNode *MD = M.getNamedMetadata("aix.copyright.comment");
  if (!MD || MD->getNumOperands() == 0)
    return PreservedAnalyses::all();

  // At this point we are guarateed that one TU contains a single copyright
  // metadata entry. Create TU-local string global for that metadata entry.
  MDNode *MdNode = MD->getOperand(0);
  if (!MdNode || MdNode->getNumOperands() == 0)
    return PreservedAnalyses::all();

  auto *MdString = dyn_cast_or_null<MDString>(MdNode->getOperand(0));
  if (!MdString)
    return PreservedAnalyses::all();

  StringRef Text = MdString->getString();
  if (Text.empty())
    return PreservedAnalyses::all();

  // 1. Create a single NULL-terminated string global
  Constant *StrInit = ConstantDataArray::getString(Ctx, Text, /*AddNull=*/true);

  // Internal, constant, TU-local — avoids duplicate symbol issues across TUs.
  auto *StrGV = new GlobalVariable(M, StrInit->getType(),
                                   /*isConstant=*/true,
                                   GlobalValue::InternalLinkage, StrInit,
                                   /*Name=*/"__aix_copyright_str");
  StrGV->setUnnamedAddr(GlobalValue::UnnamedAddr::Global);
  StrGV->setAlignment(Align(1));
  StrGV->setSection("__llvm_copyright");

  // 2. Ensure LLVM doesn't delete it (through all pipelines/LTO).
  appendToUsed(M, {StrGV});
  // appendToCompilerUsed(M, {StrGV});

  // 3. Attach !implicit ref to every defined function
  // Create a metadata node pointing to the copyright string:
  //   !N = !{ptr @__aix_copyright_str}
  Metadata *Ops[] = {ConstantAsMetadata::get(StrGV)};
  auto *ValMD = ValueAsMetadata::get(StrGV);
  MDNode *ImplicitRefMD = MDNode::get(Ctx, Ops);

  auto addImplicitRef = [&](Function &F) {
    if (F.isDeclaration())
      return;
    // Attach the implicit.ref metadata to the function
    F.setMetadata("implicit.ref", ImplicitRefMD);
    LLVM_DEBUG(dbgs() << "[copyright] attached implicit.ref to function:  "
                      << F.getName() << "\n");
  };

  for (Function &F : M)
    addImplicitRef(F);

  // Remove the original metadata since we've processed it
  // This prevents reprocessing if the pass runs multiple times
  MD->eraseFromParent();
  LLVM_DEBUG(dbgs() << "[copyright] created string and anchor for module\n");

  return PreservedAnalyses::all();
}

} // namespace llvm