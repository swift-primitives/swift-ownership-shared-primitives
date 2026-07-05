// exports.swift
// Ownership Shared Primitive declares `Ownership.Shared<Element, B>` (the CoW column combinator) — a thin adapter
// over `Ownership.Box` (swift-ownership-primitives), which owns the box, the uniqueness gate,
// and the drain-box rule ([MEM-SAFE-028]).
// Per the exports-narrowing ruling (audit #9, 2026-06-10), the column vocabulary is NOT
// re-exported: consumers SPELL their wrapped column by importing the column-vocabulary
// modules explicitly (Buffer/Storage/Memory/Index).
// The BASE NAMESPACE module is the one sanctioned re-export: this module declares
// `extension Ownership { public struct Shared … }` (M8 re-home), so — per the
// extension-module convention every Ownership-extension target follows (e.g.
// "Ownership Immutable Primitives", "Ownership Box Primitives") — it re-exports
// `Ownership_Primitive` so consumers can spell the nest `Ownership.Shared`.

@_exported public import Ownership_Primitive
