// Re-export the column-spelling constituents so consumers of `Shared<Element, B>` can name the
// wrapped buffer columns without separate imports (MemberImportVisibility).
@_exported public import Buffer_Primitive
@_exported public import Buffer_Linear_Primitive
@_exported public import Storage_Contiguous_Primitives
@_exported public import Memory_Heap_Primitives
@_exported public import Memory_Allocator_Primitive
@_exported public import Store_Protocol_Primitives
@_exported public import Buffer_Protocol_Primitives
@_exported public import Index_Primitives
