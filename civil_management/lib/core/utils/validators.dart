void validateProjectId(String projectId) {
  if (projectId.trim().isEmpty ||
      projectId == '00000000-0000-0000-0000-000000000000') {
    throw Exception('Invalid projectId passed from UI');
  }
}
