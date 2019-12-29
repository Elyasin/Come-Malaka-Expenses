use admin;
db.createUser(
  {
      user: "admin",
          pwd: "admin",
              roles: [ { role: "userAdminAnyDatabase", db: "admin" }, "readWriteAnyDatabase" ]
  }
);

db.auth("admin", "admin");
use come_malaka_test;
db.createUser(
  {
      user: "tester",
          pwd: "tester",
              roles: [ { role: "dbAdmin", db: "come_malaka_test" }, "readWrite" ]
  }
);

