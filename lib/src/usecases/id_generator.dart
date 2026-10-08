/// Mints the id for a new entity — the catalog's one seam for identity.
///
/// **An id is opaque.** The catalog stores, returns and compares an id, and
/// nothing in `lib/` parses it, sorts on it, or does arithmetic on it. That is
/// what lets a consumer choose the shape: a UUID, a prefixed sequence
/// (`DEV-0007`), an int-backed string, or the string form of a class of their
/// own. The only constraint is stability — whatever an adapter stores must come
/// back unchanged.
///
/// The default (newMeta with no generator) is a random UUID v4. Pass one to the
/// use cases that mint ids internally — DuplicateSku, DuplicateInstance,
/// AddSkuComponent, UpdateSkuComponent. A create use case takes a fully formed
/// entity, so you already pick the id shape there.
typedef IdGenerator = String Function();
