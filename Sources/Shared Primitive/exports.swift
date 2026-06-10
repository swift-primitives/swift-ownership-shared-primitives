// exports.swift
// Shared Primitive declares `Shared<Element, B>` (the CoW column combinator) + its Box.
// Per the exports-narrowing ruling (audit #9, 2026-06-10), nothing is re-exported:
// consumers SPELL their wrapped column by importing the column-vocabulary modules
// explicitly (Buffer/Storage/Memory/Index).
