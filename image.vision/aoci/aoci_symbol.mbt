///|
/// # AOCI 符号坐标类型 AOCI Symbol Coordinate Types
///
/// 符号在代码库中的位置和元信息
/// 符号位置与元数据 Symbol position
// AOCI 符号语义索引 — 符号坐标类型
// SymbolCoord: 符号在代码库中的位置和元信息

///|
/// `#non_exhaustive` 表示未来可能添加新构造器
#derive(Eq, @debug.Debug)
#non_exhaustive
pub(all) enum SymbolKind {
  Function
  Method
  Type
  TypeAlias
  Enum
  Struct
}

///|
pub extend SymbolKind with Eq::{not_equal, equal}

///|
pub extend SymbolKind with @debug.Debug::{to_repr}

///|
pub fn SymbolKind::to_string(self : SymbolKind) -> String {
  match self {
    Function => "Function"
    Method => "Method"
    Type => "Type"
    TypeAlias => "TypeAlias"
    Enum => "Enum"
    Struct => "Struct"
  }
}

///|
#derive(Eq, @debug.Debug)
pub(all) struct SymbolCoord {
  pkg : String
  name : String
  kind : SymbolKind
  signature : String
  doc : String
  keywords : Array[String]
}

///|
pub extend SymbolCoord with Eq::{not_equal, equal}

///|
pub extend SymbolCoord with @debug.Debug::{to_repr}

///|
pub fn SymbolCoord::make(
  pkg~ : String,
  name~ : String,
  kind~ : SymbolKind,
  signature~ : String = "",
  doc~ : String = "",
  keywords~ : Array[String] = [],
) -> SymbolCoord {
  { pkg, name, kind, signature, doc, keywords, }
}

///|
pub fn SymbolCoord::full_name(self : SymbolCoord) -> String {
  self.pkg + "::" + self.name
}

///|
pub fn SymbolCoord::has_keyword(self : SymbolCoord, keyword : String) -> Bool {
  for kw in self.keywords {
    if kw == keyword {
      return true
    }
  }
  false
}

///|
pub fn SymbolCoord::estimated_tokens(self : SymbolCoord) -> Int32 {
  let name_tokens = self.name.length() / 4 + 1
  let sig_tokens = self.signature.length() / 4 + 1
  let doc_tokens = self.doc.length() / 4 + 1
  name_tokens + sig_tokens + doc_tokens + 10
}
