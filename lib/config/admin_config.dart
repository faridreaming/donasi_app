const Set<String> kAdminEmails = {'admin@donasi.com'};

bool isAdminEmail(String? email) {
  if (email == null || email.trim().isEmpty) {
    return false;
  }

  return kAdminEmails.contains(email.trim().toLowerCase());
}
