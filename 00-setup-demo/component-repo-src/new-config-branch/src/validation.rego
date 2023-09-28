package main

deny[msg] {
  not input.serviceAccountName

  msg := "service account must be set"
}

deny[msg] {
  input.replicas != 3

  msg := "Replicas must equal 3"
}
