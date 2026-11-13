-- Names are unique, ignoring upper and lower case ("Basel" and "basel" count as the same name).
CREATE UNIQUE INDEX uk_users_name_lower ON users (LOWER(name));
