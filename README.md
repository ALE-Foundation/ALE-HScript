# ALE HScript

ALE HScript is a rewrite of HScript (more specifically, [RuleScript](https://github.com/Kriptel/RuleScript/tree/dev)) designed to support type declarations, fix design and performance issues in RuleScript, and improve its usability (which is usually somewhat complex)

At the moment, it supports essentially the same types as RuleScript (except for enums and abstract classes, though these will likely be added later), addresses some parity issues with Haxe (particularly regarding setters and access to null variables), and provides default support for static variables that function similarly to those in Haxe (exclusive to module classes)

The project borrows some of RuleScript’s code for macros, so part of the credit goes to [Kriptel](https://github.com/Kriptel), who was also an inspiration