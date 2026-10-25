const List<String> _arabicDigits = [
  '٠',
  '١',
  '٢',
  '٣',
  '٤',
  '٥',
  '٦',
  '٧',
  '٨',
  '٩',
];

// 5 -> ٥
String toArabicDigits(Object value) {
  var text = value.toString();
  for (var i = 0; i < _arabicDigits.length; i++) {
    text = text.replaceAll('$i', _arabicDigits[i]);
  }
  return text;
}

// ٥ -> 5 (so Arabic keyboards do not break validation or saving)
String toLatinDigits(String value) {
  var text = value;
  for (var i = 0; i < _arabicDigits.length; i++) {
    text = text.replaceAll(_arabicDigits[i], '$i');
  }
  return text;
}

// 123456789 -> ••••••789
String maskNationalId(String id) {
  if (id.length <= 3) return id;
  return '•' * (id.length - 3) + id.substring(id.length - 3);
}

// Arabic label for the number of family members
String membersLabel(int count) {
  if (count == 1) return 'فرد واحد';
  if (count == 2) return 'فردان';
  if (count >= 3 && count <= 10) return '${toArabicDigits(count)} أفراد';
  return '${toArabicDigits(count)} فرداً';
}
