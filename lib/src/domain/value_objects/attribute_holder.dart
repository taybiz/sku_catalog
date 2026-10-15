import '../entities/instance.dart';
import '../entities/locate.dart';
import '../entities/manufacturer.dart';

/// One record that holds trait values, as a uniqueness rule sees it.
///
/// Three kinds of record are holders: an *article* ([Instance]), the *place* it
/// sits at ([Locate]) and the *maker* of its model ([Manufacturer]). Those three
/// are the population a value marked `isUnique` is unique across — it may be held
/// by exactly one of them, whatever kind it is.
///
/// A SKU carries an `attributeValues` map like those three do, and is deliberately
/// not a holder: a value on a model describes the class, so it claims nothing.
///
/// Sealed on purpose: a rule that compares holders cannot forget a kind, because
/// a `switch` over this type must handle every one, and adding a fourth is a
/// compile error everywhere that reads it.
sealed class AttributeHolder {
  /// Const constructor for the sealed family.
  const AttributeHolder();

  /// The record's id.
  String get id;

  /// The name to show a person when a claim clashes.
  String get label;

  /// The values the record claims, keyed by attribute key.
  Map<String, dynamic> get values;

  /// The word a failure message calls this kind of record.
  String get kindName;

  /// Identifies the record across kinds.
  ///
  /// An article and a place may share an id, and a rule comparing holders has to
  /// exclude the one being written by *both* halves, so an id alone is not
  /// enough.
  String get key => '$kindName:$id';
}

/// An article of a SKU — one concrete instance.
final class ArticleHolder extends AttributeHolder {
  /// Wraps [instance] as the article claiming its own values.
  const ArticleHolder(this.instance);

  /// The article.
  final Instance instance;

  @override
  String get id => instance.meta.id;

  @override
  String get label => instance.name;

  @override
  Map<String, dynamic> get values => instance.attributeValues;

  @override
  String get kindName => 'instance';
}

/// A physical place — a room, a floor, a shelf.
final class PlaceHolder extends AttributeHolder {
  /// Wraps [locate] as the place claiming its own values.
  const PlaceHolder(this.locate);

  /// The place.
  final Locate locate;

  @override
  String get id => locate.meta.id;

  @override
  String get label => locate.name;

  @override
  Map<String, dynamic> get values => locate.attributeValues;

  @override
  String get kindName => 'place';
}

/// A manufacturer — the maker of an article's model.
final class MakerHolder extends AttributeHolder {
  /// Wraps [manufacturer] as the maker claiming its own values.
  const MakerHolder(this.manufacturer);

  /// The maker.
  final Manufacturer manufacturer;

  @override
  String get id => manufacturer.meta.id;

  @override
  String get label => manufacturer.name;

  @override
  Map<String, dynamic> get values => manufacturer.attributeValues;

  @override
  String get kindName => 'maker';
}
