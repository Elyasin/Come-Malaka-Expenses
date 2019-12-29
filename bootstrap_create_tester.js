use come_malaka_test
db.createUser(
  {
    user: "tester",
    pwd: "tester",
    roles: [ { role: "readWrite", db: "come_malaka_test" } ]
  }
)
