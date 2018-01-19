About this container
---
This container runs a Plex media server instance. More about Plex can be found at:

  https://plex.tv


Building and Running with Docker Compose
---
Using the docker-compose.yml file included in this git repo, you can build the container
yourself (should you choose to).
*Note: this docker-compose files uses the `2.3` compose format, which requires Docker
Engine release `17.06.0+`.

```
# build container locally
$> docker-compose build plex

# run plex
$> docker-compose up -d plex

# (optional) check the plex logs
$> docker-compose logs -f plex
```


Building and Running with Docker Engine
---
Before building, there are a number of environment variables to ensure are correct
for your setup. Have a look through the `vars` file and update at will.

Once updated, simply execute the build then run scripts.

```
# build plex
$> ./build.sh

# run plex
$> ./run.sh
```


Updating Plex
---
This container is now semi-auto updating!  Every time the container is started it will check to
see that the latest build is installed.  To enable this feature PLEX_SERVER_VERSION needs to be
defined within `vars` as either 'public' or 'plexpass' with appropriate creds

```
PLEX_SERVER_VERSION=public
```
OR
```
PLEX_SERVER_VERSION=plexpass
PLEXPASS_USER="username"
PLEXPASS_PASS="password"
```
Now go ahead and restart the container, plex will be running the latest build.
```
$ docker restart plex
```


Test the container
---
You should be able to connect to the plex server just like normal, but here is a
quick test you can run to make sure it's listening:

```
$ curl -I http://localhost:32400/web/index.html
HTTP/1.1 200 OK
Cache-Control: no-cache
Accept-Ranges: bytes
Connection: Keep-Alive
Keep-Alive: timeout=20
Content-Length: 2502
Content-Type: text/html
X-Plex-Protocol: 1.0
```
