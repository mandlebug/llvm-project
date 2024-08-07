// RUN: rm -rf %t && split-file %s %t && cd %t
// RUN: %clang_cc1 -verify -emit-llvm -I%t -fno-common %s -o -
// RUN: %clang_cc1 -verify=none -emit-llvm -I%t -fcommon %s -o -

// none-no-diagnostics

//--- a.c
#include "a.h"
#include "b.h"

char also_fine;

int foo(int a) {
      return a + fine + also_fine;
}

int X = 1234;

struct S t;

//--- a.h
#ifndef A_H
#define A_H


int i; // expected-warning {{possible missing 'extern' on global variable definition in header}}
int j; // expected-warning {{possible missing 'extern' on global variable definition in header}}
static int k;

double d; // expected-warning {{possible missing 'extern' on global variable definition in header}}

struct S {
    int i, j, k;
};

struct S s; // expected-warning {{possible missing 'extern' on global variable definition in header}}
struct S v = { 1, 2, 3};

double PI = 3.14159;

double  __attribute__((weak)) e;

#endif

//--- b.h
#ifndef B_H
#define B_H

#include "a.h"

extern struct S DeclNotDef;
double E = 2.718;

char c; // expected-warning {{possible missing 'extern' on global variable definition in header}}
extern char c;

char fine = 'a';
char fine;  // no-warning expected - previous non-tentative definition takes precedence.

char also_fine = 'b';

#endif
