function(keys, values, rereduce) {
  var c = 0; // count
  var t = []; // totals vector
  var m = []; // mean vector
  var dim;
  if (!rereduce)
    dim = values[0].length;
  else
     dim = values[0].totals.length;
  // initialize t with zeros
  for(var k=0; k<dim; k++) {
    t[k] = 0;
  }
  if (!rereduce) {
    // values is array of feature vectors (arrays)
    for(var i in values) {
      vector = values[i];
      for(var j=0; j<dim; j++) {
        t[j] += vector[j];
      }
    }
    c = values.length;
  }
  else {
    // values is array of objects like in return
    for(var i in values) {
      vector = values[i].totals;
      for(var j=0; j<dim; j++) {
        t[j] += vector[j];        
      }
      c += values[i].count
    }
  }
  // compute mean vector
  for(var k=0; k<dim; k++) {
    m[k] = t[k]/c;
  }
  return {"mean":m, "totals":t, "count":c}
}