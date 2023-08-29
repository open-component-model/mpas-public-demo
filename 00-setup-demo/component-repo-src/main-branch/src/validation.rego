package main

deny[msg] {
  not input.serviceAccountName

  msg := "service account must be set"
}