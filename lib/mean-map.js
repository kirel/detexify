function(doc) {
  if (doc['couchrest-type'] == 'Detexify::Sample') {
    emit(doc.command, doc.feature_vector)
  }
}