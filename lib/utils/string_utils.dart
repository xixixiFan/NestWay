String formatPhone(String phone) {
  if (phone.length >= 11) {
    return '${phone.substring(0, 3)} **** ${phone.substring(7)}';
  }
  return phone;
}
