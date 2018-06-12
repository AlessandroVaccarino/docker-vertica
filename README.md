# HP Vertica Docker container

## What is HP Vertica Docker container project?
A complete installation of [HP Vertica Community Edition](https://www.vertica.com/) into a Docker container. Just run and enjoy.

### Run the container

To run your first Drill container, just type:

`docker run -p 5433:5433 -p 5444:5444 -p 5450:5450 -it -d vertica /etc/bootstrap.sh`

If you want to store DB data outside the container, map data path under your desired local folder. Eg:
`docker run -p 5433:5433 -p 5444:5444 -p 5450:5450 -v $(pwd)/data:/srv/vertica/db -it -d vertica /etc/bootstrap.sh`

When boots up, Vertica checks if DB and/or data are available:
- If DB is available, but there are no data under */srv/vertica/db,* DB is removed and another empty DB is created
- If DB is available and there are data under */srv/vertica/db*, the DB is started
- If DB is not available, and there are no data under */srv/vertica/db*, a new empty DB is created
- If DB is not available, but there are data uner */srv/vertica/db*, data are removed and an empty DB is created (I'm working on a "restore procedure", to attach data under a new DB, feel free to contribute)

It will download the latest version of HP Vertica Docker image available, create a container, start HP Vertica and expose web interface on port 5450.
So, after executed your container, go to `https://localhost:5450/`: you wil reach HP Vertica Management Console.

It'll also expose port 5433 to grant access via Client (vsql, JDBC, ODBC,...)

To learn how to use HP Vertica, please refer to [HP Vertica Official Documentation](https://my.vertica.com/hpe-vertica-idol-documentation/) page