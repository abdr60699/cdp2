  
  class Inr{
  static String formatIndianNumber(String numberStr) {
    if (numberStr.isEmpty) return '';

    try {
      int number = int.parse(numberStr);

      if (number >= 10000000) {
        // 1 crore and above
        double crores = number / 10000000;
        return crores == crores.toInt()
            ? '${crores.toInt()} crore'
            : '${crores.toStringAsFixed(2)} crore';
      } else if (number >= 100000) {
        // 1 lakh and above
        double lakhs = number / 100000;
        return lakhs == lakhs.toInt()
            ? '${lakhs.toInt()} lac'
            : '${lakhs.toStringAsFixed(2)} lac';
      } else if (number >= 1000) {
        // 1 thousand and above
        double thousands = number / 1000;
        return thousands == thousands.toInt()
            ? '${thousands.toInt()} thousand'
            : '${thousands.toStringAsFixed(2)} thousand';
      } else {
        return number.toString();
      }
    } catch (e) {
      return '';
    }
  }
  }