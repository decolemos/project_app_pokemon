// ignore_for_file: public_member_api_docs, sort_constructors_first
class Evolution {
  String name;
  String? urlImg;
  String? trigger;
  int? minLevel;

  Evolution({
    required this.name,
    this.urlImg,
    this.trigger,
    this.minLevel,
  });
}
